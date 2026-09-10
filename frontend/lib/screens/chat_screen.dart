import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../providers/mood_provider.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_bottom_nav.dart';

class PersonaConfig {
  final String id;
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final String assetPath;

  const PersonaConfig({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.assetPath,
  });
}

const Map<String, PersonaConfig> personas = {
  'friend': PersonaConfig(
    id: 'friend',
    name: 'The Friend',
    primaryColor: Color(0xFFF59E0B),
    backgroundColor: Color(0xFF2D2200),
    assetPath: 'assets/images/friend.png',
  ),
  'coach': PersonaConfig(
    id: 'coach',
    name: 'The Coach',
    primaryColor: Color(0xFF10B981),
    backgroundColor: Color(0xFF00261A),
    assetPath: 'assets/images/coach.png',
  ),
  'empath': PersonaConfig(
    id: 'empath',
    name: 'The Empath',
    primaryColor: Color(0xFF7C6EF8),
    backgroundColor: Color(0xFF1A1740),
    assetPath: 'assets/images/empath.png',
  ),
};

// Light bg tints per persona
const Map<String, Color> _personaBgLight = {
  'friend': Color(0xFFFEF3C7),
  'coach': Color(0xFFD1FAE5),
  'empath': Color(0xFFEDE9FE),
};

class ChatScreen extends StatefulWidget {
  final String username;
  final String persona;

  const ChatScreen({
    super.key,
    required this.username,
    this.persona = 'empath',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> sessions = [];
  String? activeSessionId;
  List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  late String currentPersona;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    currentPersona = widget.persona;
    if (!personas.containsKey(currentPersona)) currentPersona = 'empath';

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _loadSessions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  Future<void> _loadSessions() async {
    try {
      final data = await ApiService.fetchChatSessions(widget.username);
      if (mounted) setState(() => sessions = data);
    } catch (e) {
      _showError('Failed to load sessions');
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    try {
      final msgs =
          await ApiService.fetchSessionMessages(widget.username, sessionId);
      if (mounted) {
        setState(() {
          activeSessionId = sessionId;
          messages = msgs;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to load messages');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || isLoading) return;
    final userMessage = _controller.text.trim();

    setState(() {
      messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'user',
        message: userMessage,
        timestamp: DateTime.now(),
        isUser: true,
      ));
      _controller.clear();
      isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService.sendChatMessage(
        username: widget.username,
        message: userMessage,
        persona: currentPersona,
        sessionId: activeSessionId,
      );

      if (res.containsKey('emotion') && res['emotion'] != null) {
        if (mounted) {
          Provider.of<MoodProvider>(context, listen: false)
              .setEmotion(res['emotion'] as String);
        }
      }

      if (mounted) {
        setState(() {
          if (res.containsKey('session_id')) {
            activeSessionId = res['session_id'];
          }
          // Crisis Safety Core may override the persona server-side (forces
          // Empath) — reflect that in the UI so the reply reads coherently.
          final responsePersona = res['persona']?.toString();
          if (responsePersona != null && personas.containsKey(responsePersona)) {
            currentPersona = responsePersona;
          }
          messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: 'assistant',
            message: res['reply'] ?? '',
            timestamp: DateTime.now(),
            isUser: false,
          ));
        });
        _scrollToBottom();
        _loadSessions();
      }
    } catch (e) {
      _showError('Failed to send message');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewSession() {
    setState(() {
      activeSessionId = null;
      messages = [];
    });
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  Widget _buildEmptyState(bool isDark) {
    final personaConfig = personas[currentPersona]!;
    final textPrimary =
        isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: personaConfig.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: personaConfig.primaryColor.withOpacity(0.35),
                    blurRadius: 32,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  personaConfig.id[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'How are you feeling today?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to listen as ${personaConfig.name}.",
            style: GoogleFonts.inter(fontSize: 15, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaTabs(bool isDark) {
    final surfaceVar =
        isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F8);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);

    return Container(
      decoration: BoxDecoration(
        color: surfaceVar,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: personas.entries.map((entry) {
          final isActive = currentPersona == entry.key;
          final pColor = entry.value.primaryColor;
          return GestureDetector(
            onTap: () => setState(() => currentPersona = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? pColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.value.id[0].toUpperCase() +
                    entry.value.id.substring(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSidebar({bool isDesktop = false}) {
    final personaConfig = personas[currentPersona]!;
    return AppSidebar(
      isDesktop: isDesktop,
      currentRoute: '/chat',
      username: widget.username,
      primaryColor: personaConfig.primaryColor,
      onNewChat: _startNewSession,
      chatSessions: sessions,
      activeSessionId: activeSessionId,
      onLoadSession: _loadMessages,
    );
  }

  Widget _buildChatArea({required bool isDesktop}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVar =
        isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F8);
    final borderColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final textPrimary =
        isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final textTertiary =
        isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);
    final personaConfig = personas[currentPersona]!;
    final personaBg = isDark
        ? personaConfig.backgroundColor
        : (_personaBgLight[currentPersona] ?? const Color(0xFFEDE9FE));

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 14 : 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF16161F)
                : Colors.white,
            border: Border(
                bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              if (!isDesktop)
                IconButton(
                  icon:
                      Icon(Icons.menu, color: textSecondary, size: 22),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!isDesktop) const SizedBox(width: 8),
              _buildPersonaTabs(isDark),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: textSecondary, size: 22),
                onPressed: _startNewSession,
                tooltip: 'New chat',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.isUser;
                    final maxW =
                        MediaQuery.of(context).size.width * 0.72;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 4, left: 4, right: 4),
                            child: Text(
                              isUser
                                  ? 'You'
                                  : personaConfig.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isUser
                                    ? textTertiary
                                    : personaConfig.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: maxW),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isUser ? surfaceVar : personaBg,
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    const Radius.circular(18),
                                topRight:
                                    const Radius.circular(18),
                                bottomLeft: isUser
                                    ? const Radius.circular(18)
                                    : const Radius.circular(4),
                                bottomRight: isUser
                                    ? const Radius.circular(4)
                                    : const Radius.circular(18),
                              ),
                              border: isUser
                                  ? Border.all(color: borderColor)
                                  : null,
                            ),
                            child: Text(
                              msg.message,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                height: 1.5,
                                color: isUser
                                    ? textPrimary
                                    : personaConfig.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4),
                            child: Text(
                              _formatTime(msg.timestamp),
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: textTertiary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Typing indicator
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: personaConfig.primaryColor,
                        shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: personaConfig.primaryColor
                            .withOpacity(0.6),
                        shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: personaConfig.primaryColor
                            .withOpacity(0.3),
                        shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(
                  '${personaConfig.name} is thinking...',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        // Input area
        Padding(
          padding: const EdgeInsets.only(
              left: 16, right: 16, bottom: 20, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceVar,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization:
                        TextCapitalization.sentences,
                    maxLines: null,
                    style: GoogleFonts.inter(
                        fontSize: 15, color: textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Message ${personaConfig.name}...',
                      hintStyle: GoogleFonts.inter(
                          color: textTertiary),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isLoading ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isLoading
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFF7C6EF8),
                                Color(0xFF5B8AF5)
                              ],
                            ),
                      color: isLoading
                          ? (isDark
                              ? const Color(0xFF2A2A3A)
                              : const Color(0xFFE4E4EF))
                          : null,
                    ),
                    child: Icon(Icons.arrow_upward,
                        color: isLoading
                            ? textTertiary
                            : Colors.white,
                        size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);
    final surfaceColor =
        isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: _buildSidebar(isDesktop: false),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth <= 800
            ? AppBottomNav(
                currentRoute: '/chat', username: widget.username)
            : const SizedBox.shrink(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Container(
              color: bgColor,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: _buildSidebar(isDesktop: true),
                  ),
                  VerticalDivider(
                      width: 1, color: borderColor, thickness: 1),
                  Expanded(
                    child: Container(
                      color: surfaceColor,
                      child: _buildChatArea(isDesktop: true),
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(
            color: surfaceColor,
            child: _buildChatArea(isDesktop: false),
          );
        },
      ),
    );
  }
}
