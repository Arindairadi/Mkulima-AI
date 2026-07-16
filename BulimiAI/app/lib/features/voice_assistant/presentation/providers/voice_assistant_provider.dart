import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final SupportedLanguage language;

  const VoiceAssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isThinking = false,
    this.language = const SupportedLanguage(code: 'en-UG', label: 'English'),
  });

  VoiceAssistantState copyWith({
    List<VoiceMessage>? messages,
    bool? isListening,
    bool? isThinking,
    SupportedLanguage? language,
  }) {
    return VoiceAssistantState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isThinking: isThinking ?? this.isThinking,
      language: language ?? this.language,
    );
  }
}

/// Drives the AI Voice Farming Assistant (Section 5 of the brief).
///
/// `sendText()` calls the Mkulima AI backend (bulimi_ai_backend/) (`POST /api/v1/voice-assistant/ask`),
/// which forwards the question to Gemini along with the farmer's selected
/// language and gets back real, context-aware farming advice. If the
/// request fails (no connectivity, backend down), it falls back to a
/// simple local canned reply rather than leaving the chat hanging.
///
/// `speech_to_text` / `flutter_tts` (already in pubspec.yaml) still need to
/// be wired into `startListening()`/replies here for actual voice
/// input/output — this provider currently only handles the text pipeline.
class VoiceAssistantController extends StateNotifier<VoiceAssistantState> {
  final Ref _ref;
  VoiceAssistantController(this._ref) : super(const VoiceAssistantState());

  void setLanguage(SupportedLanguage lang) => state = state.copyWith(language: lang);

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(
      messages: [...state.messages, VoiceMessage(text, isUser: true)],
      isThinking: true,
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
  }

  void toggleListening() => state = state.copyWith(isListening: !state.isListening);

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
}

final voiceAssistantProvider =
    StateNotifierProvider.autoDispose<VoiceAssistantController, VoiceAssistantState>(
  (ref) => VoiceAssistantController(ref),
);
