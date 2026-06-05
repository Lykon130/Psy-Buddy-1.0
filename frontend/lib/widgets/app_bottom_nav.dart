import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/chat_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/dream_screen.dart';
import '../screens/mood_chart_screen.dart';

class AppBottomNav extends StatelessWidget {
  final String currentRoute;
  final String username;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final primary = isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);
    final inactive = isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);

    final items = [
      {
        'route': '/chat',
        'icon': Icons.chat_bubble_outline_rounded,
        'activeIcon': Icons.chat_bubble_rounded,
        'label': 'Chat',
      },
      {
        'route': '/journal',
        'icon': Icons.auto_stories_outlined,
        'activeIcon': Icons.auto_stories,
        'label': 'Journal',
      },
      {
        'route': '/dreams',
        'icon': Icons.nights_stay_outlined,
        'activeIcon': Icons.nights_stay,
        'label': 'Dreams',
      },
      {
        'route': '/mood',
        'icon': Icons.insights_outlined,
        'activeIcon': Icons.insights,
        'label': 'Insights',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = currentRoute == item['route'];
              return GestureDetector(
                onTap: () {
                  if (isActive) return;
                  Widget destination;
                  switch (item['route']) {
                    case '/chat':
                      destination = ChatScreen(username: username);
                      break;
                    case '/journal':
                      destination = JournalScreen(username: username);
                      break;
                    case '/dreams':
                      destination = DreamScreen(username: username);
                      break;
                    case '/mood':
                      destination = MoodScreen(username: username);
                      break;
                    default:
                      return;
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => destination),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? primary.withOpacity(isDark ? 0.15 : 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        size: 22,
                        color: isActive ? primary : inactive,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? primary : inactive,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
