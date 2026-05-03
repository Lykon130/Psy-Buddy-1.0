import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/chat_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/dream_screen.dart';
import '../screens/mood_chart_screen.dart';

class AppSidebar extends StatelessWidget {
  final bool isDesktop;
  final String currentRoute;
  final String username;
  final Color primaryColor;
  final VoidCallback? onNewChat;
  final List<Map<String, dynamic>>? chatSessions;
  final String? activeSessionId;
  final Function(String)? onLoadSession;

  const AppSidebar({
    super.key,
    this.isDesktop = false,
    required this.currentRoute,
    required this.username,
    required this.primaryColor,
    this.onNewChat,
    this.chatSessions,
    this.activeSessionId,
    this.onLoadSession,
  });

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String title, required String route, required Widget destination}) {
    final isActive = currentRoute == route;
    return InkWell(
      onTap: () {
        if (!isDesktop) Navigator.pop(context);
        if (!isActive) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.black54),
            const SizedBox(width: 16),
            Text(title, style: GoogleFonts.inter(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? primaryColor : Colors.black87,
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: isDesktop ? 0 : 16,
      backgroundColor: isDesktop ? Colors.transparent : Colors.white,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            if (!isDesktop) const SizedBox(height: 48),
            if (isDesktop) const SizedBox(height: 24),
            
            // Branding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PsyBuddy',
                  style: GoogleFonts.greatVibes(
                    fontSize: 32,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  _buildNavItem(context, icon: Icons.chat_bubble_outline, title: 'Chat', route: '/chat', destination: ChatScreen(username: username)),
                  const SizedBox(height: 8),
                  _buildNavItem(context, icon: Icons.menu_book, title: 'Journal', route: '/journal', destination: JournalScreen(username: username)),
                  const SizedBox(height: 8),
                  _buildNavItem(context, icon: Icons.nights_stay_outlined, title: 'Dreams', route: '/dreams', destination: DreamScreen(username: username)),
                  const SizedBox(height: 8),
                  _buildNavItem(context, icon: Icons.bar_chart, title: 'Mood Chart', route: '/mood', destination: MoodScreen(username: username)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(indent: 24, endIndent: 24),

            // Optional Chat specific actions
            if (currentRoute == '/chat' && onNewChat != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: InkWell(
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    onNewChat!();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text("New Chat", style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold)),
                      ]
                    )
                  )
                )
              ),
              
              if (chatSessions != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Recent Chats", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: chatSessions!.length,
                    itemBuilder: (context, index) {
                      final session = chatSessions![index];
                      final isActive = session['session_id'] == activeSessionId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.history, color: isActive ? primaryColor : Colors.black38, size: 18),
                          title: Text(session['title']?.isNotEmpty == true ? session['title'] : 'Untitled Session', 
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
                          selected: isActive,
                          onTap: () {
                            if (!isDesktop) Navigator.pop(context);
                            if (onLoadSession != null) onLoadSession!(session['session_id']);
                          },
                        ),
                      );
                    }
                  )
                ),
              ] else ...[
                const Spacer(),
              ]
            ] else ...[
              const Spacer(),
            ],

            Padding(
               padding: const EdgeInsets.all(16),
               child: InkWell(
                 onTap: () {},
                 child: Container(
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.grey[300]!),
                     borderRadius: BorderRadius.circular(12.0),
                   ),
                   padding: const EdgeInsets.all(12),
                   child: Row(
                     children: [
                       const Icon(Icons.settings_outlined, color: Colors.black54),
                       const SizedBox(width: 12),
                       Text("Settings", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                     ]
                   )
                 )
               )
            ),
            const SizedBox(height: 16),
          ]
        )
      )
    );
  }
}
