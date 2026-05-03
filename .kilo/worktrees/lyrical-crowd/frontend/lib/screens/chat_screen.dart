import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../providers/mood_provider.dart';
import 'login_screen.dart';
import 'mood_chart_screen.dart';

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

      // Handle emotion state global change
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Chat History", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _startNewSession();
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isActive = session['session_id'] == activeSessionId;
                return ListTile(
                  selected: isActive,
                  selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  title: Text(
                    session['title']?.isNotEmpty == true ? session['title'] : 'Untitled Session',
                    style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _loadMessages(session['session_id']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: ClipOval(
              child: Image.network(
                'https://previews.123rf.com/images/alfazetchronicles/alfazetchronicles2302/alfazetchronicles230207934/198560181-abstract-image-of-circle-with-energy-of-the-universe-and-cosmic-collision-generative-ai.jpg',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
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
            "I'm here to listen and help.",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.isUser;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isUser ? Theme.of(context).primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                          ),
                          boxShadow: isUser ? [] : [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Text(
                          msg.message,
                          style: GoogleFonts.inter(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
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
                const SizedBox(width: 16),
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)),
                const SizedBox(width: 12),
                Text("PsyBuddy is thinking...", style: GoogleFonts.inter(color: Colors.black54)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.inter(color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: isLoading ? null : _sendMessage,
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
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text("PsyBuddy"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.show_chart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoodScreen(username: widget.username)))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ],
      ),
      body: _buildChatArea(),
    );
  }
}
