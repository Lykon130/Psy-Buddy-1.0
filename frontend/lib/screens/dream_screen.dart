import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dream_entry.dart';
import '../services/api_service.dart';
import '../providers/mood_provider.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_bottom_nav.dart';

class DreamScreen extends StatefulWidget {
  final String username;
  const DreamScreen({super.key, required this.username});

  @override
  State<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends State<DreamScreen> {
  List<DreamEntry> entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final data = await ApiService.fetchDreamEntries(widget.username);
      if (mounted) setState(() { entries = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy': case 'amusement': case 'excitement':
      case 'optimism': case 'surprise': case 'gratitude':
        return const Color(0xFFF59E0B);
      case 'admiration': case 'approval': case 'pride':
        return const Color(0xFF10B981);
      case 'caring': case 'love': case 'sadness': case 'grief':
        return const Color(0xFF3B82F6);
      case 'anger': case 'annoyance': case 'disgust':
        return const Color(0xFFEF4444);
      case 'fear': case 'nervousness': case 'embarrassment':
        return const Color(0xFF8B5CF6);
      case 'confusion':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showAddEntryBottomSheet() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surfaceColor = isDark ? const Color(0xFF16161F) : Colors.white;
        final borderColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
        final textPrimary = isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
        final textSecondary = isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
        final textTertiary = isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: borderColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('New Dream',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 4),
              Text('Describe your dream',
                style: GoogleFonts.inter(fontSize: 14, color: textSecondary)),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Title of your dream',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w600, color: textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
              Divider(color: borderColor, height: 24),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  style: GoogleFonts.lora(
                    fontSize: 16, height: 1.7, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'What did you dream about?',
                    hintStyle: GoogleFonts.lora(
                      fontSize: 16, height: 1.7, color: textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (titleController.text.trim().isEmpty ||
                      contentController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _loading = true);
                  try {
                    final entry = await ApiService.addDreamEntry(
                      widget.username,
                      titleController.text.trim(),
                      contentController.text.trim(),
                    );
                    if (context.mounted && entry.emotion != null) {
                      Provider.of<MoodProvider>(context, listen: false)
                          .setEmotion(entry.emotion!);
                    }
                    setState(() { entries.insert(0, entry); _loading = false; });
                  } catch (e) {
                    if (mounted) setState(() => _loading = false);
                  }
                },
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
                    child: Text('Save Dream',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryCard(DreamEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final textPrimary = isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary = isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final textTertiary = isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);
    final emotion = entry.emotion ?? 'neutral';
    final emotionColor = _getEmotionColor(emotion);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [BoxShadow(
                color: const Color(0xFF6B5EE8).withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(entry.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(emotion.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: emotionColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_formatDate(entry.timestamp),
            style: GoogleFonts.inter(fontSize: 12, color: textTertiary)),
          const SizedBox(height: 14),
          Text(
            entry.content.length > 200
                ? '${entry.content.substring(0, 200)}...'
                : entry.content,
            style: GoogleFonts.lora(fontSize: 15, height: 1.7, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);
    final surfaceColor = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final textPrimary = isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary = isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final textTertiary = isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);
    final primary = isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);

    return Scaffold(
      backgroundColor: isDesktop ? surfaceColor : bgColor,
      appBar: AppBar(
        backgroundColor: isDesktop ? surfaceColor : bgColor,
        elevation: 0,
        title: Text('Dream Journal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary)),
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: Icon(Icons.menu, color: textSecondary, size: 22),
                onPressed: () => Scaffold.of(context).openDrawer()),
        actions: [
          if (entries.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2760)
                    : const Color(0xFFEDE9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${entries.length} dreams',
                style: GoogleFonts.inter(
                  fontSize: 12, color: primary, fontWeight: FontWeight.w500)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2))
          : entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E2A)
                              : const Color(0xFFF0F0F8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.nights_stay_outlined,
                            size: 36, color: textTertiary),
                      ),
                      const SizedBox(height: 20),
                      Text('No dreams recorded yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w600,
                          color: textPrimary)),
                      const SizedBox(height: 8),
                      Text('Your dream journal awaits',
                        style: GoogleFonts.inter(
                          fontSize: 15, color: textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _buildEntryCard(entries[i]),
                ),
      floatingActionButton: GestureDetector(
        onTap: _showAddEntryBottomSheet,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C6EF8), Color(0xFF5B8AF5)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C6EF8).withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Record',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);
    final borderColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppSidebar(
        isDesktop: false,
        currentRoute: '/dreams',
        username: widget.username,
        primaryColor: primaryColor,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth <= 800
            ? AppBottomNav(currentRoute: '/dreams', username: widget.username)
            : const SizedBox.shrink(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Row(
              children: [
                SizedBox(
                  width: 280,
                  child: AppSidebar(
                    isDesktop: true,
                    currentRoute: '/dreams',
                    username: widget.username,
                    primaryColor: primaryColor,
                  ),
                ),
                VerticalDivider(width: 1, color: borderColor, thickness: 1),
                Expanded(child: _buildContent(true)),
              ],
            );
          }
          return _buildContent(false);
        },
      ),
    );
  }
}
