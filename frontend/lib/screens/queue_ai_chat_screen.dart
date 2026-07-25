import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/chat_service.dart';

enum _Sender { ai, user }

class _Message {
  final _Sender sender;
  final String? text;
  final List<_Chip>? chips;
  final DateTime time;
  final bool typing;
  final bool isEmergency;

  const _Message({
    required this.sender,
    this.text,
    this.chips,
    required this.time,
    this.typing = false,
    this.isEmergency = false,
  });
}

class _Chip {
  final String label;
  final IconData? icon;
  const _Chip(this.label, [this.icon]);
}

class QueueAiChatScreen extends StatefulWidget {
  const QueueAiChatScreen({super.key});

  @override
  State<QueueAiChatScreen> createState() => _QueueAiChatScreenState();
}

class _QueueAiChatScreenState extends State<QueueAiChatScreen> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  final List<_Message> _messages = [];
  bool _showQuickReplies = true;
  List<String> _currentQuickReplies = _defaultQuickReplies;

  static const _defaultQuickReplies = [
    'How long is the wait?',
    "Doctor's profile",
    'Where do I go?',
    'Notify me when close',
  ];

  @override
  void initState() {
    super.initState();
    _messages.addAll(_initialMessages());
    _inputCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  List<_Message> _initialMessages() {
    final now = DateTime.now();
    return [
      _Message(
        sender: _Sender.ai,
        text:
            "Hello there!\nI'm your MeroPalo Queue Assistant. I can track your token, guide you to your doctor's room, or summarise your visit. What can I help with?",
        chips: const [
          _Chip('Wait Time', Icons.access_time_rounded),
          _Chip('Token Status', Icons.confirmation_number_outlined),
          _Chip('Doctor Info', Icons.medical_information_outlined),
        ],
        time: now,
      ),
    ];
  }

  // ─── SCROLL & TYPING HELPERS ───────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _appendMessage(_Message m) {
    setState(() => _messages.add(m));
    _scrollToBottom();
  }

  void _appendTyping() {
    _appendMessage(
      _Message(sender: _Sender.ai, typing: true, time: DateTime.now()),
    );
  }

  void _removeTyping() {
    setState(() {
      _messages.removeWhere((m) => m.typing);
    });
  }

  // ─── SEND & REPLY ──────────────────────────────────────────────────────

  Future<void> _sendUserMessage(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;

    // Resolve the service before awaiting (no BuildContext across the gap).
    final chat = context.read<ChatService>();
    _inputCtrl.clear();
    _appendMessage(
      _Message(sender: _Sender.user, text: text, time: DateTime.now()),
    );
    setState(() {
      _showQuickReplies = false;
      _currentQuickReplies = [];
    });
    _appendTyping();
    _scrollToBottom();

    try {
      final reply = await chat.query(text);
      if (!mounted) return;
      _removeTyping();
      _appendMessage(_Message(
        sender: _Sender.ai,
        text: reply.response,
        isEmergency: reply.isEmergency,
        time: DateTime.now(),
      ));
    } catch (e) {
      if (!mounted) return;
      _removeTyping();
      _appendMessage(_Message(
        sender: _Sender.ai,
        text: e is ApiException
            ? e.message
            : "I couldn't reach the assistant right now. Please try again.",
        time: DateTime.now(),
      ));
    }

    if (!mounted) return;
    setState(() {
      _currentQuickReplies = _suggestionsFor(text);
      _showQuickReplies = _currentQuickReplies.isNotEmpty;
    });
    _scrollToBottom();
  }

  List<String> _suggestionsFor(String userText) {
    final t = userText.toLowerCase();
    if (t.contains('wait') || t.contains('token') || t.contains('queue')) {
      return ['Notify me when close', 'Where do I go?', 'Cancel my token'];
    }
    if (t.contains('doctor') || t.contains('profile')) {
      return ['Where is the room?', 'Show wait time', 'About the clinic'];
    }
    if (t.contains('where') || t.contains('room') || t.contains('direction')) {
      return ['Show on map', 'Nearby amenities', 'How long is the wait?'];
    }
    return _defaultQuickReplies;
  }

  // ─── ATTACHMENT MENU ──────────────────────────────────────────────────

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share with Assistant',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _AttachmentOption(
              icon: Icons.image_outlined,
              label: 'Upload Photo',
              subtitle: 'Share a prescription, lab report or symptom photo',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('Photo attached');
              },
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.description_outlined,
              label: 'Upload Document',
              subtitle: 'PDF reports or insurance card',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('Document attached');
              },
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.mic_none_rounded,
              label: 'Voice Message',
              subtitle: 'Describe your symptom verbally',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('Voice note attached');
              },
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.location_on_outlined,
              label: 'Share Location',
              subtitle: 'Let the assistant find the nearest entrance',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('Location shared');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SheetTile(
              icon: Icons.refresh_rounded,
              label: 'New conversation',
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _messages
                    ..clear()
                    ..addAll(_initialMessages());
                  _showQuickReplies = true;
                  _currentQuickReplies = _defaultQuickReplies;
                });
              },
            ),
            _SheetTile(
              icon: Icons.translate_rounded,
              label: 'Change language',
              onTap: () => Navigator.pop(ctx),
            ),
            _SheetTile(
              icon: Icons.report_outlined,
              label: 'Report a problem',
              onTap: () => Navigator.pop(ctx),
            ),
            _SheetTile(
              icon: Icons.support_agent_rounded,
              label: 'Talk to a human',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _GreenHeader(
            onRefresh: () {
              setState(() {
                _messages
                  ..clear()
                  ..addAll(_initialMessages());
                _showQuickReplies = true;
                _currentQuickReplies = _defaultQuickReplies;
              });
            },
            onMore: _showOptionsMenu,
          ),
          _OnlineStrip(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) return _DateChip(time: DateTime.now());
                return _MessageBubble(message: _messages[i - 1]);
              },
            ),
          ),
          if (_showQuickReplies && _currentQuickReplies.isNotEmpty)
            _QuickReplies(
              suggestions: _currentQuickReplies,
              onTap: _sendUserMessage,
            ),
          _InputBar(
            controller: _inputCtrl,
            focusNode: _inputFocus,
            onSend: () => _sendUserMessage(_inputCtrl.text),
            onAttach: _showAttachmentMenu,
            hasText: _inputCtrl.text.trim().isNotEmpty,
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ────────────────────────────────────────────────────────────────

class _GreenHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onMore;
  const _GreenHeader({required this.onRefresh, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 18),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Queue Assistant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI POWERED',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onMore,
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ONLINE STRIP ──────────────────────────────────────────────────────────

class _OnlineStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.cardGreenLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online — Ready to help',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATE CHIP ─────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final DateTime time;
  const _DateChip({required this.time});

  @override
  Widget build(BuildContext context) {
    final label = 'TODAY, ${DateFormat('h:mm a').format(time)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E4F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF584C8E),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MESSAGE BUBBLE ────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isAi = message.sender == _Sender.ai;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isAi) ...[_AiAvatar(), const SizedBox(width: 10)],
          Flexible(
            child: isAi
                ? _AiContent(message: message)
                : _UserBubble(message: message),
          ),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
    );
  }
}

class _AiContent extends StatelessWidget {
  final _Message message;
  const _AiContent({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.typing) return const _TypingIndicator();

    final children = <Widget>[];
    if (message.text != null) {
      children.add(_AiTextBubble(
        text: message.text!,
        isEmergency: message.isEmergency,
      ));
    }
    if (message.chips != null) {
      children.add(const SizedBox(height: 10));
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: message.chips!
              .map(
                (c) => _SuggestionChip(
                  label: c.label,
                  icon: c.icon,
                  primary: false,
                  onTap: () {},
                ),
              )
              .toList(),
        ),
      );
    }
    children.add(const SizedBox(height: 4));
    children.add(_TimestampLabel(time: message.time, alignEnd: false));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _AiTextBubble extends StatelessWidget {
  final String text;
  final bool isEmergency;
  const _AiTextBubble({required this.text, this.isEmergency = false});
  @override
  Widget build(BuildContext context) {
    final accent = isEmergency ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isEmergency ? const Color(0xFFFDECEC) : const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmergency)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    'EMERGENCY',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final _Message message;
  const _UserBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: AppColors.primaryShadow,
          ),
          child: Text(
            message.text ?? '',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _TimestampLabel(time: message.time, alignEnd: true, delivered: true),
      ],
    );
  }
}

class _TimestampLabel extends StatelessWidget {
  final DateTime time;
  final bool alignEnd;
  final bool delivered;
  const _TimestampLabel({
    required this.time,
    required this.alignEnd,
    this.delivered = false,
  });

  @override
  Widget build(BuildContext context) {
    final str = DateFormat('h:mm a').format(time);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Text(
          str,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        if (delivered) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.done_all_rounded,
            size: 12,
            color: AppColors.primary,
          ),
        ],
      ],
    );
  }
}

// ─── TYPING INDICATOR ──────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + (i * 0.2)) % 1.0;
              final scale =
                  0.6 + 0.6 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── SUGGESTION CHIP / QUICK REPLIES ───────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback onTap;
  const _SuggestionChip({
    required this.label,
    this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary ? AppColors.primary : AppColors.border,
            width: primary ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _QuickReplies({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SuggestionChip(
                    label: s,
                    primary: true,
                    onTap: () => onTap(s),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}


// ─── ATTACHMENT / SHEET TILES ─────────────────────────────────────────────

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardGreenMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── INPUT BAR ─────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool hasText;
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onAttach,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9E4F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message Queue Assistant…',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: GestureDetector(
                key: ValueKey(hasText),
                onTap: hasText ? onSend : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: hasText ? AppColors.primaryGradient : null,
                    color: hasText ? null : const Color(0xFFE9E4F5),
                    shape: BoxShape.circle,
                    boxShadow: hasText ? AppColors.primaryShadow : [],
                  ),
                  child: Icon(
                    hasText ? Icons.send_rounded : Icons.mic_none_rounded,
                    color: hasText ? Colors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
