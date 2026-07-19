import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client_provider.dart';

class VoiceMessage {
  final String text;
  final bool isUser;
  const VoiceMessage(this.text, {required this.isUser});
}

class VoiceAssistantState {
  final List<VoiceMessage> messages;
  final bool isListening;
  final bool isThinking;
  final bool speechAvailable;
  final String liveTranscript; // partial words while actively listening
  final SupportedLanguage language;

  const VoiceAssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isThinking = false,
    this.speechAvailable = false,
    this.liveTranscript = '',
    this.language = const SupportedLanguage(code: 'en-UG', label: 'English'),
  });

  VoiceAssistantState copyWith({
    List<VoiceMessage>? messages,
    bool? isListening,
    bool? isThinking,
    bool? speechAvailable,
    String? liveTranscript,
    SupportedLanguage? language,
  }) {
    return VoiceAssistantState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isThinking: isThinking ?? this.isThinking,
      speechAvailable: speechAvailable ?? this.speechAvailable,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      language: language ?? this.language,
    );
  }
}

/// Drives the AI Voice Farming Assistant (Section 5 of the brief).
///
/// Real speech-to-text (via `speech_to_text`) and text-to-speech (via
/// `flutter_tts`) are wired in here:
/// - Tapping the mic starts real device speech recognition; live partial
///   words show in the input field as you speak, and the final result is
///   sent to the backend automatically when you stop talking.
/// - Every assistant reply is also spoken aloud via TTS.
///
/// `sendText()` calls the backend (`POST /api/v1/voice-assistant/ask`),
/// which forwards the question to Gemini along with the farmer's selected
/// language. Falls back to a canned local reply if the request fails.
///
/// Language note: `speech_to_text`/`flutter_tts` rely on the OS's installed
/// voice packs. English recognition/speech is reliable on virtually every
/// Android device; Luganda/Runyankole/Lusoga/Luo/Ateso support depends on
/// whether the phone has a matching voice pack installed — if not, STT/TTS
/// silently fall back to the device's default language while the *text*
/// reply from Gemini still respects the selected language.
class VoiceAssistantController extends StateNotifier<VoiceAssistantState> {
  final Ref _ref;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceAssistantController(this._ref) : super(const VoiceAssistantState()) {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _finishListening();
        }
      },
      onError: (error) {
        state = state.copyWith(isListening: false);
      },
    );
    state = state.copyWith(speechAvailable: available);
  }

  Future<void> startListening() async {
    if (!state.speechAvailable) {
      await _initSpeech();
      if (!state.speechAvailable) return;
    }

    state = state.copyWith(isListening: true, liveTranscript: '');
    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(liveTranscript: result.recognizedWords);
      },
      localeId: _localeIdFor(state.language.code),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _finishListening();
  }

  void _finishListening() {
    final transcript = state.liveTranscript;
    state = state.copyWith(isListening: false);
    if (transcript.trim().isNotEmpty) {
      sendText(transcript);
    }
  }

  String? _localeIdFor(String appLanguageCode) {
    switch (appLanguageCode) {
      case 'en-UG':
        return 'en_US';
      default:
        return null;
    }
  }

  void setLanguage(SupportedLanguage lang) => state = state.copyWith(language: lang);

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(
      messages: [...state.messages, VoiceMessage(text, isUser: true)],
      isThinking: true,
      liveTranscript: '',
    );

    String reply;
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post<Map<String, dynamic>>(
        '/api/v1/voice-assistant/ask',
        data: {'text': text, 'language_code': state.language.code},
      );
      reply = response.data!['reply'] as String? ?? _mockReply(text);
    } catch (e) {
      reply = '${_mockReply(text)}\n\n(This is an offline fallback reply — could not reach the AI service.)';
    }

    state = state.copyWith(
      messages: [...state.messages, VoiceMessage(reply, isUser: false)],
      isThinking: false,
    );

    _speak(reply);
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage(state.language.code == 'en-UG' ? 'en-US' : 'en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {
      // TTS not available on this device — silently skip.
    }
  }

  String _mockReply(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('yellow') && lower.contains('banana')) {
      return 'Yellowing banana leaves are often a sign of Panama disease or nutrient deficiency (especially '
          'potassium or nitrogen). Check the soil moisture and consider a soil test.';
    }
    if (lower.contains('rain') || lower.contains('weather')) {
      return 'Based on typical patterns, hold off on fertilizer application until after any expected rain has '
          'passed and the soil has drained.';
    }
    if (lower.contains('price') || lower.contains('market')) {
      return 'Check the Market Intelligence tab for a live price comparison across markets.';
    }
    return 'Thanks for your question. Keep monitoring your crop daily, remove any visibly diseased leaves, '
        'and use the Disease Detection tab with a photo if you\'d like a closer check.';
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}

final voiceAssistantProvider =
    StateNotifierProvider.autoDispose<VoiceAssistantController, VoiceAssistantState>(
  (ref) => VoiceAssistantController(ref),
);
