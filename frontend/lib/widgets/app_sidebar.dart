import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/dream_screen.dart';
import '../screens/mood_chart_screen.dart';
import '../screens/memory_settings_screen.dart';
import '../screens/growth_timeline_screen.dart';

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

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Widget destination,
  }) {
    final isActive = currentRoute == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final activeBg =
        isDark ? const Color(0xFF1E1A40) : const Color(0xFFEDE9FE);
    final activePrimary =
        isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);

    return InkWell(
      onTap: () {
        if (!isDesktop) Navigator.pop(context);
        if (!isActive) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isActive ? activePrimary : textSecondary),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? textPrimary : textSecondary,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: activePrimary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? const Color(0xFF16161F) : Colors.white;
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
    final primary =
        isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);

    final content = Container(
      color: surfaceColor,
      child: Column(
        children: [
          SizedBox(
              height: isDesktop
                  ? 24
                  : 48 + MediaQuery.of(context).padding.top),
          // Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C6EF8), Color(0xFF4ECDC4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'P',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PsyBuddy',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Nav items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildNavItem(context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat',
                    route: '/chat',
                    destination: ChatScreen(username: username)),
                const SizedBox(height: 4),
                _buildNavItem(context,
                    icon: Icons.auto_stories_outlined,
                    title: 'Journal',
                    route: '/journal',
                    destination: JournalScreen(username: username)),
                const SizedBox(height: 4),
                _buildNavItem(context,
                    icon: Icons.nights_stay_outlined,
                    title: 'Dreams',
                    route: '/dreams',
                    destination: DreamScreen(username: username)),
                const SizedBox(height: 4),
                _buildNavItem(context,
                    icon: Icons.insights_outlined,
                    title: 'Insights',
                    route: '/mood',
                    destination: MoodScreen(username: username)),
                const SizedBox(height: 4),
                _buildNavItem(context,
                    icon: Icons.flag_outlined,
                    title: 'Growth Timeline',
                    route: '/growth',
                    destination: GrowthTimelineScreen(username: username)),
                const SizedBox(height: 4),
                _buildNavItem(context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Memory & Privacy',
                    route: '/memory',
                    destination: MemorySettingsScreen(username: username)),
              ],
            ),
          ),
          // Chat-specific section
          if (currentRoute == '/chat' && onNewChat != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: borderColor, height: 1),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  onNewChat!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2760).withOpacity(0.6)
                        : const Color(0xFFEDE9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF3D3580)
                            : const Color(0xFFD4D0FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add,
                          color: Color(0xFF7C6EF8), size: 18),
                      const SizedBox(width: 10),
                      Text('New Chat',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF7C6EF8),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (chatSessions != null && chatSessions!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('RECENT',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textTertiary,
                          letterSpacing: 0.8)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: chatSessions!.length,
                  itemBuilder: (context, index) {
                    final session = chatSessions![index];
                    final isActive =
                        session['session_id'] == activeSessionId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark
                                ? const Color(0xFF1E1A40)
                                : const Color(0xFFEDE9FE))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.chat_bubble_outline,
                            size: 16,
                            color: isActive
                                ? primary
                                : textTertiary),
                        title: Text(
                          session['title']?.isNotEmpty == true
                              ? session['title']
                              : 'New conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isActive
                                ? textPrimary
                                : textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        onTap: () {
                          if (!isDesktop) Navigator.pop(context);
                          if (onLoadSession != null) {
                            onLoadSession!(session['session_id']);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
          ] else
            const Spacer(),
          // Bottom: user info + theme toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: surfaceVar, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        username,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textPrimary,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          size: 20),
                      color: textSecondary,
                      onPressed: () {
                        Provider.of<ThemeProvider>(context,
                                listen: false)
                            .toggleTheme();
                      },
                      tooltip:
                          isDark ? 'Switch to Light' : 'Switch to Dark',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    return Drawer(
      elevation: isDesktop ? 0 : 16,
      backgroundColor: surfaceColor,
      child: content,
    );
  }
}
