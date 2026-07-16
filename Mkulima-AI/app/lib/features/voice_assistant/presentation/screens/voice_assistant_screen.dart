import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/voice_assistant_provider.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  void _send() {
    final text = _textController.text;
    _textController.clear();
    ref.read(voiceAssistantProvider.notifier).sendText(text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceAssistantProvider);
    final controller = ref.read(voiceAssistantProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        actions: [
          PopupMenuButton<SupportedLanguage>(
            initialValue: state.language,
            onSelected: controller.setLanguage,
            itemBuilder: (context) => AppConstants.supportedLanguages
                .map((l) => PopupMenuItem(value: l, child: Text(l.label)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(state.language.label),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyState(onSuggestionTap: (s) {
                    _textController.text = s;
                    _send();
                  })
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.spaceMd),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) => _MessageBubble(message: state.messages[i]),
                  ),
          ),
          if (state.isThinking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Mkulima AI is thinking…', style: TextStyle(color: AppColors.textSecondary)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceSm),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      state.isListening ? Icons.mic : Icons.mic_none,
                      color: state.isListening ? AppColors.danger : AppColors.primary,
                    ),
                    onPressed: () {
                      // speech_to_text integration point: startListening() /
                      // stopListening() would populate _textController with
                      // recognized speech in the farmer's selected language.
                      controller.toggleListening();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: 'Ask about your crops...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestionTap;
  const _EmptyState({required this.onSuggestionTap});

  static const _suggestions = [
    'Why are my banana leaves turning yellow?',
    'Will it rain this week?',
    'Where can I sell my beans for the best price?',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_outlined, size: 56, color: AppColors.primary),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Ask Mkulima AI anything', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.spaceMd),
            ..._suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => onSuggestionTap(s),
                  child: Text(s, textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final VoiceMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }
}
