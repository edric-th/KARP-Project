import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/constants/app_colors.dart';

enum _Sender { ai, user }

class _Message {
  final _Sender sender;
  final String? text;
  final List<_Chip>? chips;
  final _LiveQueueData? liveQueue;
  final _DoctorCardData? doctorCard;
  final _DirectionData? directions;
  final DateTime time;
  final bool typing;

  const _Message({
    required this.sender,
    this.text,
    this.chips,
    this.liveQueue,
    this.doctorCard,
    this.directions,
    required this.time,
    this.typing = false,
  });
}

class _Chip {
  final String label;
  final IconData? icon;
  const _Chip(this.label, [this.icon]);
}

class _LiveQueueData {
  final String nowServing;
  final String yourToken;
  final int ahead;
  final String estWait;
  final int percentPositioned;
  const _LiveQueueData({
    required this.nowServing,
    required this.yourToken,
    required this.ahead,
    required this.estWait,
    required this.percentPositioned,
  });
}

class _DoctorCardData {
  final String name;
  final String specialty;
  final String room;
  final double rating;
  final int experience;
  final String status;
  const _DoctorCardData({
    required this.name,
    required this.specialty,
    required this.room,
    required this.rating,
    required this.experience,
    required this.status,
  });
}

class _DirectionData {
  final String to;
  final List<String> steps;
  const _DirectionData({required this.to, required this.steps});
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
            "Hello there 👋\nI'm your MeroPalo Queue Assistant. I can track your token, guide you to your doctor's room, or summarise your visit. What can I help with?",
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

    _inputCtrl.clear();
    _appendMessage(
      _Message(sender: _Sender.user, text: text, time: DateTime.now()),
    );
    setState(() {
      _showQuickReplies = false;
      _currentQuickReplies = [];
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    _appendTyping();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    _removeTyping();
    final reply = _replyFor(text);
    _appendMessage(reply);

    setState(() {
      _currentQuickReplies = _suggestionsFor(text);
      _showQuickReplies = _currentQuickReplies.isNotEmpty;
    });
    _scrollToBottom();
  }

  _Message _replyFor(String userText) {
    final t = userText.toLowerCase();
    final now = DateTime.now();

    if (t.contains('wait') ||
        t.contains('how long') ||
        t.contains('token') ||
        t.contains('queue')) {
      return _Message(
        sender: _Sender.ai,
        text: "You're 5 tokens away — about 15 minutes. Here's a live view:",
        liveQueue: const _LiveQueueData(
          nowServing: '042',
          yourToken: '047',
          ahead: 5,
          estWait: '~15 min',
          percentPositioned: 82,
        ),
        time: now,
      );
    }
    if (t.contains('doctor') ||
        t.contains('specialist') ||
        t.contains('profile')) {
      return _Message(
        sender: _Sender.ai,
        text: "Here's a quick profile of your attending doctor:",
        doctorCard: const _DoctorCardData(
          name: 'Dr. Sharma',
          specialty: 'Consulting Cardiologist',
          room: 'Room 101 • Main Clinic Wing',
          rating: 4.8,
          experience: 12,
          status: 'Active Now',
        ),
        time: now,
      );
    }
    if (t.contains('where') ||
        t.contains('direction') ||
        t.contains('room') ||
        t.contains('how do i get') ||
        t.contains('go ')) {
      return _Message(
        sender: _Sender.ai,
        text: 'Take the following route to reach Room 101:',
        directions: const _DirectionData(
          to: 'Cardiology • Room 101',
          steps: [
            'Enter through Main Lobby — go straight past reception.',
            'Take the elevators on your right to the 1st floor.',
            'Turn left, follow the green corridor to Block C.',
            'Room 101 is the second door on your right.',
          ],
        ),
        time: now,
      );
    }
    if (t.contains('amenit') ||
        t.contains('cafe') ||
        t.contains('wifi') ||
        t.contains('rest') ||
        t.contains('food')) {
      return _Message(
        sender: _Sender.ai,
        text:
            "🍽 Cafeteria — Ground floor, next to Pharmacy.\n🚻 Restrooms — Every floor near the elevators.\n📶 Free Wi-Fi: MeroPalo-Guest (password not required).",
        time: now,
      );
    }
    if (t.contains('notify') ||
        t.contains('alert') ||
        t.contains('remind') ||
        t.contains('close')) {
      return _Message(
        sender: _Sender.ai,
        text:
            "Done ✅ — I'll send a push notification when there are 2 tokens ahead of you, plus a final reminder when you're next.",
        time: now,
      );
    }
    if (t.contains('cancel') || t.contains('reschedule') || t.contains('leave')) {
      return _Message(
        sender: _Sender.ai,
        text:
            "I can release your token without a cancellation fee since you haven't been served. Want me to go ahead and reschedule for tomorrow's first slot?",
        time: now,
      );
    }
    if (t.contains('thanks') || t.contains('thank')) {
      return _Message(
        sender: _Sender.ai,
        text: 'Happy to help 💚 — I\'ll keep watching your queue in the background.',
        time: now,
      );
    }
    return _Message(
      sender: _Sender.ai,
      text:
          "I'm not sure I caught that. I can help with wait times, your doctor's profile, directions inside the hospital, amenities, or notifications. Try one of the chips below!",
      time: now,
    );
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
                _sendUserMessage('📎 Photo attached');
              },
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.description_outlined,
              label: 'Upload Document',
              subtitle: 'PDF reports or insurance card',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('📄 Document attached');
              },
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.mic_none_rounded,
              label: 'Voice Message',
              subtitle: 'Describe your symptom verbally',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('🎤 Voice note attached');
              },
            ),
            const SizedBox(height: 8),
            _AttachmentOption(
              icon: Icons.location_on_outlined,
              label: 'Share Location',
              subtitle: 'Let the assistant find the nearest entrance',
              onTap: () {
                Navigator.pop(ctx);
                _sendUserMessage('📍 Location shared');
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
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
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
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            _AiAvatar(),
            const SizedBox(width: 10),
          ],
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
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 14,
      ),
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
      children.add(_AiTextBubble(text: message.text!));
    }
    if (message.liveQueue != null) {
      children.add(const SizedBox(height: 8));
      children.add(_LiveQueueCard(data: message.liveQueue!));
    }
    if (message.doctorCard != null) {
      children.add(const SizedBox(height: 8));
      children.add(_DoctorCard(data: message.doctorCard!));
    }
    if (message.directions != null) {
      children.add(const SizedBox(height: 8));
      children.add(_DirectionsCard(data: message.directions!));
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
  const _AiTextBubble({required this.text});
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
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
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
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              final scale = 0.6 + 0.6 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
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

// ─── LIVE QUEUE CARD ───────────────────────────────────────────────────────

class _LiveQueueCard extends StatelessWidget {
  final _LiveQueueData data;
  const _LiveQueueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'LIVE QUEUE UPDATE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _smallLabel('NOW SERVING'),
                          const SizedBox(height: 4),
                          Text(
                            data.nowServing,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _smallLabel('YOUR TOKEN'),
                        const SizedBox(height: 4),
                        Text(
                          data.yourToken,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEAF6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.cardGreenMedium,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ahead of You',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${data.ahead} People',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Est. Wait',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            data.estWait,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _smallLabel('PROGRESS'),
                    const Spacer(),
                    Text(
                      '${data.percentPositioned}% POSITIONED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: data.percentPositioned / 100,
                    backgroundColor: AppColors.cardGreenLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.7,
        ),
      );
}

// ─── DOCTOR CARD (in-chat) ────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final _DoctorCardData data;
  const _DoctorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardGreenMedium,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      data.specialty,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardGreenMedium,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(
                Icons.star_rounded,
                data.rating.toStringAsFixed(1),
                'Rating',
                const Color(0xFFE4A24A),
              ),
              const SizedBox(width: 14),
              _miniStat(
                Icons.work_outline_rounded,
                '${data.experience} yrs',
                'Experience',
                AppColors.primary,
              ),
              const SizedBox(width: 14),
              Flexible(
                child: _miniStat(
                  Icons.meeting_room_outlined,
                  data.room.split(' • ').first,
                  data.room.split(' • ').last,
                  AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─── DIRECTIONS CARD ──────────────────────────────────────────────────────

class _DirectionsCard extends StatelessWidget {
  final _DirectionData data;
  const _DirectionsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardGreenMedium,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route to',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      data.to,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...data.steps.asMap().entries.map((e) {
            final last = e.key == data.steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Column(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!last)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: AppColors.cardGreenBorder,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
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
                child: const Icon(
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
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
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
