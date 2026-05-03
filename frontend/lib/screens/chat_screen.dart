import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../providers/mood_provider.dart';
import '../widgets/app_sidebar.dart';

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
    primaryColor: Color(0xFFF9A826), 
    backgroundColor: Color(0xFFFDEAD2), 
    assetPath: 'assets/images/friend.png',
  ),
  'coach': PersonaConfig(
    id: 'coach',
    name: 'The Coach',
    primaryColor: Color(0xFF22C55E), 
    backgroundColor: Color(0xFFDDF5E9),
    assetPath: 'assets/images/coach.png',
  ),
  'empath': PersonaConfig(
    id: 'empath',
    name: 'The Empath',
    primaryColor: Color(0xFF0EA5E9), 
    backgroundColor: Color(0xFFD6F0FA),
    assetPath: 'assets/images/empath.png',
  ),
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

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
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
    
    // Ensure the initial persona is valid, fallback to empath
    if (!personas.containsKey(currentPersona)) {
      currentPersona = 'empath';
    }

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  Future<void> _loadSessions() async {
    try {
      final data = await ApiService.fetchChatSessions(widget.username);
      if (mounted) setState(() => sessions = data);
    } catch (e) {
      _showError("Failed to load sessions");
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    try {
      final msgs = await ApiService.fetchSessionMessages(widget.username, sessionId);
      if (mounted) {
        setState(() {
          activeSessionId = sessionId;
          messages = msgs;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError("Failed to load messages");
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || isLoading) return;
    final userMessage = _controller.text.trim();

    setState(() {
      messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: "user",
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
          Provider.of<MoodProvider>(context, listen: false).setEmotion(res['emotion'] as String);
        }
      }

      if (mounted) {
        setState(() {
          if (res.containsKey('session_id')) {
            activeSessionId = res['session_id'];
          }
          messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: "assistant",
            message: res['reply'] ?? '',
            timestamp: DateTime.now(),
            isUser: false,
          ));
        });
        _scrollToBottom();
        _loadSessions();
      }
    } catch (e) {
      print(e);
      _showError("Failed to send message");
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

  void _cyclePersona() {
    final keys = personas.keys.toList();
    final currentIndex = keys.indexOf(currentPersona);
    final nextIndex = (currentIndex + 1) % keys.length;
    setState(() {
      currentPersona = keys[nextIndex];
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  Widget _buildEmptyState() {
    final personaConfig = personas[currentPersona]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: personaConfig.primaryColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: personaConfig.primaryColor.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: Text(
                personaConfig.id.toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "How are you feeling today?",
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "I'm here to listen and help as ${personaConfig.name}.",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
          ),
        ],
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
    final personaConfig = personas[currentPersona]!;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: isDesktop ? 24.0 : 48.0).copyWith(bottom: 16.0),
          child: Row(
            children: [
              if (!isDesktop) ...[
                 IconButton(
                   icon: const Icon(Icons.menu, size: 28), 
                   onPressed: () => Scaffold.of(context).openDrawer(),
                 ),
                 const Spacer(),
              ] else ...[
                 const Spacer(),
              ],
              InkWell(
                onTap: _cyclePersona,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    personaConfig.name,
                    style: GoogleFonts.dancingScript(
                      fontSize: 36,
                      color: personaConfig.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ]
          )
        ),
        
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.isUser;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.white : personaConfig.backgroundColor,
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                                bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                              ),
                              border: isUser ? Border.all(color: Colors.grey.shade300) : null,
                            ),
                            child: Text(
                              msg.message,
                              style: GoogleFonts.inter(
                                color: isUser ? Colors.black87 : personaConfig.primaryColor,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_formatTime(msg.timestamp), style: GoogleFonts.inter(fontSize: 10, color: Colors.black45)),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(width: 24),
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: personaConfig.primaryColor)),
                const SizedBox(width: 12),
                Text("${personaConfig.name} is typing...", style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 32.0, top: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    decoration: InputDecoration(
                       hintText: "Message ${personaConfig.name}...",
                       border: InputBorder.none,
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       hintStyle: GoogleFonts.inter(color: Colors.black38),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  )
                ),
                InkWell(
                  onTap: isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLoading ? Colors.grey : personaConfig.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 24),
                  )
                )
              ]
            )
          )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktopContext = MediaQuery.of(context).size.width > 800;
    final personaConfig = personas[currentPersona]!;

    return Scaffold(
      backgroundColor: isDesktopContext ? personaConfig.primaryColor : Colors.white,
      drawer: isDesktopContext ? null : _buildSidebar(isDesktop: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Container(
              color: personaConfig.primaryColor,
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: _buildSidebar(isDesktop: true),
                    ),
                    VerticalDivider(width: 1, color: Colors.grey[200], thickness: 1),
                    Expanded(
                      child: _buildChatArea(isDesktop: true),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return _buildChatArea(isDesktop: false);
          }
        },
      ),
    );
  }
}
