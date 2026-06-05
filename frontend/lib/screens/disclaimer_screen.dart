import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import 'journal_screen.dart';
import 'dream_screen.dart';

class DisclaimerScreen extends StatefulWidget {
  final String username;
  const DisclaimerScreen({super.key, required this.username});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  String selectedPersona = 'empath';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);
    final surfaceColor =
        isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final textPrimary =
        isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final primary =
        isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);

    final personas = [
      {'id': 'empath', 'label': 'Empath', 'color': const Color(0xFF7C6EF8)},
      {'id': 'coach', 'label': 'Coach', 'color': const Color(0xFF10B981)},
      {'id': 'friend', 'label': 'Friend', 'color': const Color(0xFFF59E0B)},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Before You Begin',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_outlined,
                            size: 36, color: primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Important Disclaimer',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'This app is not a substitute for professional medical advice.\n\n'
                          'Always seek the advice of a physician or qualified health provider with any questions you may have regarding a medical condition.\n\n'
                          'By proceeding, you acknowledge that you understand and agree to these terms.',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              color: textSecondary,
                              height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose your companion',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: personas
                            .map((p) {
                              final isSelected = selectedPersona == p['id'];
                              final color = p['color'] as Color;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => selectedPersona = p['id'] as String),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(
                                              isDark ? 0.2 : 0.1)
                                          : surfaceColor,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : borderColor,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.person_outline,
                                            color: isSelected
                                                ? color
                                                : textSecondary,
                                            size: 24),
                                        const SizedBox(height: 6),
                                        Text(
                                          p['label'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? color
                                                : textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                        username: widget.username, persona: selectedPersona),
                  ),
                ),
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C6EF8), Color(0xFF5B8AF5), Color(0xFF4ECDC4)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'I Understand, Start Chat',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  JournalScreen(username: widget.username))),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text('Journal',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textPrimary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DreamScreen(username: widget.username))),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text('Dreams',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textPrimary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
