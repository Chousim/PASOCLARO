import 'package:flutter/material.dart';
import '../../../../data/repositories/offline_guides_data.dart';
import '../../../../domain/models/pasoclaro_models.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pasoclaro_widgets.dart';

/// Stitch-faithful 390x844 conversational voice-and-text assistant screen.
/// Zero profile avatars, zero emojis, zero horizontal overflow.
class AssistantView extends StatefulWidget {
  const AssistantView({
    super.key,
    required this.appState,
    required this.category,
    required this.onOpenScanner,
    required this.onOpenChecklist,
    this.autoStartVoice = false,
  });

  final PasoClaroAppState appState;
  final TramiteCategory category;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenChecklist;
  final bool autoStartVoice;

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;
  bool _isListening = false;
  bool _isThinking = false;
  String? _speakingMessageId;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(
      OfflineGuidesData.initialConversation(widget.category),
    );
    if (widget.autoStartVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _toggleVoiceInput();
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    widget.appState.voiceService.stopListening();
    widget.appState.stopSpeaking();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendUserMessage(String rawText, {bool wasVoice = false}) async {
    final text = rawText.trim();
    if (text.isEmpty || _isThinking) return;

    _textController.clear();
    final nowLabel = wasVoice ? 'Ahora · Por voz' : 'Ahora';
    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text,
      timestampLabel: nowLabel,
      wasVoice: wasVoice,
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _scrollToBottom();

    final completedDocs = widget.appState.activeGuide.items
        .where((item) => item.isCompleted)
        .map((item) => item.titleSpanish)
        .toList();

    final reply = await widget.appState.repository.askAssistant(
      prompt: text,
      profile: widget.appState.profile,
      language: widget.appState.language,
      category: widget.category,
      completedDocs: completedDocs,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(reply);
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _handleQuickReply(String reply) {
    final normalized = reply.toLowerCase();
    if (normalized.contains('lista')) {
      widget.onOpenChecklist();
      return;
    }
    if (normalized.contains('escanear')) {
      widget.onOpenScanner();
      return;
    }
    _sendUserMessage(reply);
  }

  Future<void> _toggleSpeakMessage(ChatMessage message) async {
    if (_speakingMessageId == message.id) {
      await widget.appState.stopSpeaking();
      if (mounted) {
        setState(() => _speakingMessageId = null);
      }
      return;
    }

    final buffer = StringBuffer(message.text);
    for (final bullet in message.bulletRequirements) {
      buffer.write(' ${bullet.title}: ${bullet.detail}.');
    }
    if (message.followUpQuestion != null) {
      buffer.write(' ${message.followUpQuestion!}');
    }

    setState(() => _speakingMessageId = message.id);
    await widget.appState.speakSpanish(buffer.toString());
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await widget.appState.voiceService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    String latestRecognized = '';
    setState(() => _isListening = true);

    final started = await widget.appState.voiceService.startListening(
      onResult: (recognizedText) {
        latestRecognized = recognizedText;
        if (!mounted) return;
        setState(() {
          _textController.text = recognizedText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      },
      onDone: () {
        if (!mounted) return;
        final finalPrompt = latestRecognized.trim();
        setState(() => _isListening = false);
        if (finalPrompt.isNotEmpty) {
          _sendUserMessage(finalPrompt, wasVoice: true);
        }
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.charcoalInk,
          content: Text(
            'El micrófono no está disponible aquí. Puedes escribir tu duda abajo.',
            style: AppTheme.body(14, color: AppColors.purePaper),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final seniorMode = widget.appState.isSeniorMode;
        final slowVoice = widget.appState.slowVoice;

        return Scaffold(
          backgroundColor: AppColors.canvasAlabaster,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _AssistantHeader(
                  title: widget.category.assistantTitle,
                  slowVoice: slowVoice,
                  seniorMode: seniorMode,
                  onBack: () => Navigator.maybePop(context),
                  onToggleSlowVoice: widget.appState.toggleSlowVoice,
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      for (final message in _messages) ...[
                        if (message.isUser)
                          _UserBubble(
                            message: message,
                            seniorMode: seniorMode,
                          )
                        else
                          _AssistantCard(
                            message: message,
                            seniorMode: seniorMode,
                            isSpeaking: _speakingMessageId == message.id,
                            onSpeak: () => _toggleSpeakMessage(message),
                            onQuickReply: _handleQuickReply,
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (_isThinking) ...[
                        _ThinkingBubble(seniorMode: seniorMode),
                        const SizedBox(height: 16),
                      ],
                      _ReassuranceNotice(seniorMode: seniorMode),
                    ],
                  ),
                ),
                _ComposerBar(
                  controller: _textController,
                  isListening: _isListening,
                  seniorMode: seniorMode,
                  onOpenScanner: widget.onOpenScanner,
                  onSend: () => _sendUserMessage(_textController.text),
                  onToggleVoice: _toggleVoiceInput,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.title,
    required this.slowVoice,
    required this.seniorMode,
    required this.onBack,
    required this.onToggleSlowVoice,
  });

  final String title;
  final bool slowVoice;
  final bool seniorMode;
  final VoidCallback onBack;
  final VoidCallback onToggleSlowVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.purePaper,
        border: Border(
          bottom: BorderSide(color: AppColors.whisperBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.charcoalInk,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: AppTheme.heading(
                seniorMode ? 19 : 18,
                weight: FontWeight.w600,
                color: AppColors.charcoalInk,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: slowVoice ? AppColors.agaveMist : AppColors.softStone,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onToggleSlowVoice,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: slowVoice
                        ? AppColors.agaveJade
                        : AppColors.whisperBorder,
                    width: slowVoice && seniorMode ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_outlined,
                      size: 16,
                      color: slowVoice
                          ? AppColors.agaveJade
                          : AppColors.graphiteSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Voz pausada',
                      maxLines: 1,
                      softWrap: false,
                      style: AppTheme.body(
                        12.5,
                        weight: FontWeight.w600,
                        color: slowVoice
                            ? AppColors.agaveDeep
                            : AppColors.graphiteSecondary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({
    required this.message,
    required this.seniorMode,
  });

  final ChatMessage message;
  final bool seniorMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.agaveMist,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
              border: Border.all(
                color: seniorMode
                    ? AppColors.agaveDeep
                    : AppColors.agaveJade.withValues(alpha: 0.2),
                width: seniorMode ? 1.5 : 1,
              ),
            ),
            child: Text(
              message.text,
              style: AppTheme.body(
                seniorMode ? 18 : 15,
                weight: FontWeight.w500,
                color: AppColors.charcoalInk,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.wasVoice) ...[
                const Icon(
                  Icons.mic_none_rounded,
                  size: 13,
                  color: AppColors.mutedMeta,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                message.timestampLabel,
                style: AppTheme.mono(
                  11,
                  weight: FontWeight.w500,
                  color: AppColors.mutedMeta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.message,
    required this.seniorMode,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onQuickReply,
  });

  final ChatMessage message;
  final bool seniorMode;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final ValueChanged<String> onQuickReply;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      highContrast: seniorMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (message.officialTag != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.agaveMist,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: AppColors.agaveJade,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              message.officialTag!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.mono(
                                11,
                                weight: FontWeight.w600,
                                color: AppColors.agaveDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 8),
              Text(
                message.timestampLabel,
                style: AppTheme.mono(
                  11,
                  weight: FontWeight.w500,
                  color: AppColors.mutedMeta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.text,
            style: AppTheme.body(
              seniorMode ? 18.5 : 15.5,
              color: AppColors.charcoalInk,
              height: 1.5,
            ),
          ),
          if (message.bulletRequirements.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < message.bulletRequirements.length; i++) ...[
              _RequirementBulletRow(
                bullet: message.bulletRequirements[i],
                seniorMode: seniorMode,
              ),
              if (i < message.bulletRequirements.length - 1)
                const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 14),
          Material(
            color: isSpeaking ? AppColors.agaveJade : AppColors.agaveMist,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onSpeak,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      size: 18,
                      color: isSpeaking
                          ? AppColors.purePaper
                          : AppColors.agaveJade,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isSpeaking
                            ? 'Detener lectura'
                            : (message.audioDurationLabel ??
                                'Escuchar respuesta'),
                        style: AppTheme.body(
                          seniorMode ? 15.5 : 13.5,
                          weight: FontWeight.w600,
                          color: isSpeaking
                              ? AppColors.purePaper
                              : AppColors.agaveDeep,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.followUpQuestion != null ||
              message.quickReplies.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: AppColors.whisperBorder,
                height: 1,
                thickness: 1,
              ),
            ),
          ],
          if (message.followUpQuestion != null) ...[
            Text(
              'PASO SIGUIENTE',
              style: AppTheme.mono(
                11,
                weight: FontWeight.w600,
                color: AppColors.agaveJade,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.followUpQuestion!,
              style: AppTheme.heading(
                seniorMode ? 18 : 15.5,
                weight: FontWeight.w600,
                color: AppColors.charcoalInk,
                height: 1.3,
              ),
            ),
          ],
          if (message.quickReplies.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < message.quickReplies.length; i++) ...[
              _QuickReplyButton(
                label: message.quickReplies[i],
                isPrimary: message.quickReplies[i]
                    .toLowerCase()
                    .contains('lista'),
                seniorMode: seniorMode,
                onTap: () => onQuickReply(message.quickReplies[i]),
              ),
              if (i < message.quickReplies.length - 1)
                const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _RequirementBulletRow extends StatelessWidget {
  const _RequirementBulletRow({
    required this.bullet,
    required this.seniorMode,
  });

  final ChatRequirementBullet bullet;
  final bool seniorMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: seniorMode ? AppColors.strongBorder : AppColors.whisperBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bullet.title,
            style: AppTheme.heading(
              seniorMode ? 16.5 : 14.5,
              weight: FontWeight.w600,
              color: AppColors.charcoalInk,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bullet.detail,
            style: AppTheme.body(
              seniorMode ? 15.5 : 13.5,
              color: AppColors.graphiteSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyButton extends StatelessWidget {
  const _QuickReplyButton({
    required this.label,
    required this.isPrimary,
    required this.seniorMode,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final bool seniorMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.agaveJade : AppColors.purePaper;
    final fgColor = isPrimary ? AppColors.purePaper : AppColors.charcoalInk;
    final borderColor = isPrimary
        ? AppColors.agaveJade
        : (seniorMode ? AppColors.charcoalInk : AppColors.strongBorder);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: seniorMode ? 54 : 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: seniorMode ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.body(
                    seniorMode ? 17 : 15,
                    weight: FontWeight.w600,
                    color: fgColor,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: isPrimary ? AppColors.purePaper : AppColors.agaveJade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.seniorMode});

  final bool seniorMode;

  @override
  Widget build(BuildContext context) {
    return PasoClaroCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      highContrast: seniorMode,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.agaveJade,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Preparando respuesta clara...',
            style: AppTheme.body(
              seniorMode ? 16 : 14,
              color: AppColors.graphiteSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReassuranceNotice extends StatelessWidget {
  const _ReassuranceNotice({required this.seniorMode});

  final bool seniorMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: seniorMode ? AppColors.strongBorder : AppColors.whisperBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: AppColors.agaveJade,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Servicio público gratuito — Nunca te solicitarán pagos por turnos de atención médica.',
              style: AppTheme.body(
                seniorMode ? 15 : 13,
                weight: FontWeight.w500,
                color: AppColors.graphiteSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.isListening,
    required this.seniorMode,
    required this.onOpenScanner,
    required this.onSend,
    required this.onToggleVoice,
  });

  final TextEditingController controller;
  final bool isListening;
  final bool seniorMode;
  final VoidCallback onOpenScanner;
  final VoidCallback onSend;
  final VoidCallback onToggleVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.purePaper,
        border: Border(
          top: BorderSide(color: AppColors.whisperBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Tooltip(
                message: 'Escanear documento',
                child: Material(
                  color: AppColors.softStone,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onOpenScanner,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: seniorMode
                              ? AppColors.charcoalInk
                              : AppColors.whisperBorder,
                          width: seniorMode ? 1.5 : 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 21,
                        color: AppColors.charcoalInk,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: AppTheme.body(
                    seniorMode ? 16.5 : 15,
                    color: AppColors.charcoalInk,
                    height: 1.25,
                  ),
                  decoration: InputDecoration(
                    hintText: isListening
                        ? 'Escuchando tu voz...'
                        : 'Escribe tu duda...',
                    hintStyle: AppTheme.body(
                      seniorMode ? 15.5 : 14.5,
                      color: AppColors.mutedMeta,
                    ),
                    filled: true,
                    fillColor: AppColors.softStone,
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: seniorMode
                            ? AppColors.charcoalInk
                            : AppColors.whisperBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: seniorMode
                            ? AppColors.charcoalInk
                            : AppColors.whisperBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.agaveJade,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: onSend,
                      tooltip: 'Enviar mensaje',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: AppColors.agaveJade,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: isListening ? 'Detener micrófono' : 'Hablar por voz',
                child: Material(
                  color: isListening
                      ? AppColors.agaveDeep
                      : AppColors.agaveJade,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onToggleVoice,
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isListening
                            ? Border.all(
                                color: AppColors.agaveMist,
                                width: 3,
                              )
                            : null,
                      ),
                      child: Icon(
                        isListening
                            ? Icons.stop_rounded
                            : Icons.mic_none_rounded,
                        color: AppColors.purePaper,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
