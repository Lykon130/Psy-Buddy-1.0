import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../services/api_service.dart';
import '../providers/mood_provider.dart';
import '../widgets/app_sidebar.dart';

class JournalScreen extends StatefulWidget {
  final String username;
  const JournalScreen({super.key, required this.username});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final data = await ApiService.fetchJournalEntries(widget.username);
      if (mounted) {
        setState(() {
          entries = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddEntryBottomSheet() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dear Diary...", style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: titleController,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Title of your entry",
                hintStyle: GoogleFonts.inter(color: Colors.black38),
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                style: GoogleFonts.lora(fontSize: 18, height: 1.6),
                decoration: InputDecoration(
                  hintText: "Write your thoughts here...",
                  hintStyle: GoogleFonts.lora(color: Colors.black38),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                  Navigator.pop(context);
                  setState(() => _loading = true);
                  try {
                    final entry = await ApiService.addJournalEntry(
                      widget.username,
                      titleController.text.trim(),
                      contentController.text.trim(),
                    );
                    
                    if (context.mounted) {
                      Provider.of<MoodProvider>(context, listen: false).setEmotion(entry.emotion);
                    }

                    setState(() {
                       entries.insert(0, entry);
                       _loading = false;
                    });
                  } catch (e) {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF9A826), Color(0xFF22C55E), Color(0xFF0EA5E9)],
                    ),
                  ),
                  child: Text("Save Entry", style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(entry.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9A826), Color(0xFF22C55E), Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.emotion.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${entry.timestamp.toLocal()}".split(' ')[0],
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 16),
          Text(
            entry.content,
            style: GoogleFonts.lora(fontSize: 16, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("My Journal", style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF9A826), Color(0xFF22C55E), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : entries.isEmpty
              ? Center(child: Text("No entries yet. Start writing!", style: GoogleFonts.lora(fontSize: 18, color: Colors.black45)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _buildEntryCard(entries[i]),
                ),
      floatingActionButton: InkWell(
        onTap: _showAddEntryBottomSheet,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFF9A826), Color(0xFF22C55E), Color(0xFF0EA5E9)],
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, color: Colors.white),
              const SizedBox(width: 8),
              Text("Write", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktopContext = MediaQuery.of(context).size.width > 800;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDesktopContext ? primaryColor : Colors.white,
      drawer: isDesktopContext ? null : AppSidebar(
        isDesktop: false,
        currentRoute: '/journal',
        username: widget.username,
        primaryColor: primaryColor,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Container(
              color: primaryColor,
              padding: const EdgeInsets.all(24.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: AppSidebar(
                        isDesktop: true,
                        currentRoute: '/journal',
                        username: widget.username,
                        primaryColor: primaryColor,
                      ),
                    ),
                    VerticalDivider(width: 1, color: Colors.grey[200], thickness: 1),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return _buildContent();
          }
        },
      ),
    );
  }
}
