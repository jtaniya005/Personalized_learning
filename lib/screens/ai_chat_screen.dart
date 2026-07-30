import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../models/mock_data.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

/// Steps of Buddy's proactive opening sequence — the mentor speaks
/// first, instead of waiting for the student to ask something.
enum _IntroStep { none, typingFirst, firstShown, typingCheckIn, checkInShown }

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;
  _IntroStep intro = _IntroStep.none;
  String chatLanguage = 'English';

  final List<ChatMessage> messages = [];

  final List<String> suggestions = const [
    "What's today's plan?",
    'Motivate me',
    "What's my weak area?",
    'Am I exam-ready?',
  ];

  @override
  void initState() {
    super.initState();
    _runIntroSequence();
  }

  Future<void> _runIntroSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => intro = _IntroStep.typingFirst);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => intro = _IntroStep.firstShown);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => intro = _IntroStep.typingCheckIn);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => intro = _IntroStep.checkInShown);
    _scrollToBottom();
  }

  void _send(String text, {String? replyOverride}) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add(ChatMessage(text, true));
      controller.clear();
      isTyping = true;
    });
    _scrollToBottom();
    // Mock reply — wire this to LangGraph/RAG backend later. The real
    // backend should reason over student history, not just this message.
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        isTyping = false;
        messages.add(ChatMessage(
          replyOverride ??
              "Good choice! Let's go step by step — first we'll revise the "
                  "basic identities, then move to practice questions. Ready?",
          false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
          child: Row(
            children: [
              const _BreathingAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buddy', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(tr(context, 'buddy_mentor'),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
              // Chat-only language switch — lets a student mix languages
              // with Buddy without changing the whole app's language.
              PopupMenuButton<String>(
                initialValue: chatLanguage,
                onSelected: (v) => setState(() => chatLanguage = v),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate_rounded,
                        size: 18, color: AppColors.inkSoft),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 18, color: AppColors.inkSoft),
                  ],
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'English', child: Text('English')),
                  PopupMenuItem(value: 'Hindi', child: Text('हिंदी')),
                  PopupMenuItem(value: 'Hinglish', child: Text('Hinglish')),
                ],
              ),
            ],
          ),
        ),
        Divider(color: AppColors.rule, height: 1),

        // ── Messages ──
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            children: [
              // Buddy's opening observation — sent without being asked.
              if (intro == _IntroStep.typingFirst) const _TypingBubble(),
              if (intro.index >= _IntroStep.firstShown.index)
                const _Bubble(
                  message: ChatMessage(
                    "Hey! I noticed you left Trigonometry half-done "
                    "yesterday, and Science has been skipped for 3 days. "
                    "Everything okay? 🙂",
                    false,
                  ),
                ),
              if (intro == _IntroStep.typingCheckIn) const _TypingBubble(),
              if (intro.index >= _IntroStep.checkInShown.index)
                _CheckInCard(
                  onAccept: () => _send(
                    "Yes, let's start with Trigonometry",
                    replyOverride:
                        "Great! We'll revise the basic identities first, "
                        "then go straight into practice. Ready when you are.",
                  ),
                  onLater: () => _send(
                    "I'll do it a bit later",
                    replyOverride:
                        "No rush at all. Whenever you're ready, just say "
                        "the word — I'll be here. 🙂",
                  ),
                ),

              // Regular back-and-forth after the opening.
              ...messages.map((m) => _Bubble(message: m)),
              if (isTyping) const _TypingBubble(),
            ],
          ),
        ),

        // ── Suggestion chips ──
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _send(suggestions[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paperCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Text(suggestions[i],
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Input bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: tr(context, 'chat_input_hint'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _send(controller.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.ink, Color(0xFF34424C)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_upward_rounded,
                      color: AppColors.paper),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mentor's structured check-in — not a chat bubble, but a card with a
/// concrete plan and two actions. This is the difference between a
/// doubt-solver (waits to be asked) and a mentor (proposes next step).
class _CheckInCard extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onLater;

  const _CheckInCard({required this.onAccept, required this.onLater});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: NotebookCard(
        holeCount: 4,
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, size: 16, color: AppColors.coral),
                const SizedBox(width: 6),
                Text(tr(context, 'todays_plan_card'), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 10),
            Text('Trigonometry — revise the basics?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('~30 min · worth 8-10 marks most years',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.marigold,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(tr(context, 'lets_start')),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onLater,
                  child: Text(tr(context, 'later'),
                      style: TextStyle(color: AppColors.inkSoft)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Buddy's avatar gently "breathes" — a slow scale loop that reads as
/// alive without being distracting, echoing a friend waiting to chat.
class _BreathingAvatar extends StatefulWidget {
  const _BreathingAvatar();

  @override
  State<_BreathingAvatar> createState() => _BreathingAvatarState();
}

class _BreathingAvatarState extends State<_BreathingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.marigold, AppColors.coral],
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('🙂', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.ink : AppColors.paperCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.rule),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? AppColors.paper : AppColors.ink,
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// Three bouncing dots shown while Buddy is "typing" a reply.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paperCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.rule),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (controller.value - i * 0.2) % 1.0;
                final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(0, -4 * bounce),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.inkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
