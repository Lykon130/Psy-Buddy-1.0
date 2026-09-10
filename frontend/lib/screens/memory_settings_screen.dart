import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_bottom_nav.dart';

class MemorySettingsScreen extends StatefulWidget {
  final String username;
  const MemorySettingsScreen({super.key, required this.username});

  @override
  State<MemorySettingsScreen> createState() => _MemorySettingsScreenState();
}

class _MemorySettingsScreenState extends State<MemorySettingsScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _facts = [];
  Map<String, dynamic>? _identityProfile;

  @override
  void initState() {
    super.initState();
    _fetchFacts();
    _fetchIdentityProfile();
  }

  Future<void> _fetchIdentityProfile() async {
    try {
      final profile = await ApiService.fetchIdentityProfile(widget.username);
      if (mounted) setState(() => _identityProfile = profile);
    } catch (_) {
      // Identity profile is a nice-to-have summary; fail silently rather
      // than blocking the rest of the Memory & Privacy screen.
    }
  }

  Future<void> _fetchFacts() async {
    setState(() => _loading = true);
    try {
      final facts = await ApiService.fetchMemoryFacts(widget.username);
      if (mounted) setState(() => _facts = facts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteFact(Map<String, dynamic> fact) async {
    final id = fact['id'].toString();
    setState(() => _facts.removeWhere((f) => f['id'].toString() == id));
    try {
      await ApiService.deleteMemoryFact(widget.username, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      _fetchFacts();
    }
  }

  Future<void> _editFact(Map<String, dynamic> fact) async {
    final id = fact['id'].toString();
    final controller =
        TextEditingController(text: fact['fact_text']?.toString() ?? '');

    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit memory'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newText == null ||
        newText.isEmpty ||
        newText == fact['fact_text']?.toString()) {
      return;
    }

    final previousText = fact['fact_text'];
    setState(() {
      final index = _facts.indexWhere((f) => f['id'].toString() == id);
      if (index != -1) _facts[index]['fact_text'] = newText;
    });
    try {
      await ApiService.updateMemoryFact(widget.username, id, newText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() {
        final index = _facts.indexWhere((f) => f['id'].toString() == id);
        if (index != -1) _facts[index]['fact_text'] = previousText;
      });
    }
  }

  bool get _hasIdentityProfile {
    final p = _identityProfile;
    if (p == null) return false;
    final topics = (p['topics_to_avoid'] as List?) ?? [];
    final coping = (p['coping_preferences'] as List?) ?? [];
    return (p['communication_style'] != null) ||
        (p['default_persona_preference'] != null) ||
        topics.isNotEmpty ||
        coping.isNotEmpty;
  }

  List<Widget> _buildIdentityRows(Color textPrimary, Color textSecondary) {
    final p = _identityProfile!;
    final rows = <MapEntry<String, String>>[];

    if (p['communication_style'] != null) {
      rows.add(MapEntry('Communication style', p['communication_style'].toString()));
    }
    if (p['default_persona_preference'] != null) {
      rows.add(MapEntry('Preferred persona', p['default_persona_preference'].toString()));
    }
    final topics = ((p['topics_to_avoid'] as List?) ?? []).cast<dynamic>();
    if (topics.isNotEmpty) {
      rows.add(MapEntry('Topics to avoid', topics.join(', ')));
    }
    final coping = ((p['coping_preferences'] as List?) ?? []).cast<dynamic>();
    if (coping.isNotEmpty) {
      rows.add(MapEntry('Coping preferences', coping.join(', ')));
    }

    return [
      for (int i = 0; i < rows.length; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(rows[i].key,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary)),
              ),
              Expanded(
                child: Text(rows[i].value,
                    style: GoogleFonts.inter(fontSize: 13, color: textPrimary)),
              ),
            ],
          ),
        ),
    ];
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
        title: Text('Memory & Privacy',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: Icon(Icons.menu, color: textSecondary, size: 22),
                onPressed: () => Scaffold.of(context).openDrawer()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _fetchFacts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.privacy_tip_outlined,
                              size: 20, color: primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PsyBuddy remembers a small set of facts you share '
                              'in chat — like preferences, goals, or things you\'re '
                              'working through — so conversations feel continuous. '
                              'You can review and delete anything below at any time.',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_hasIdentityProfile) ...[
                      Text('About you',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildIdentityRows(textPrimary, textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text('What PsyBuddy remembers',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                    const SizedBox(height: 12),
                    if (_facts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text('Nothing remembered yet',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: textTertiary)),
                        ),
                      )
                    else
                      ..._facts.map((fact) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fact['fact_text']?.toString() ?? '',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: textPrimary,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (fact['category']?.toString() ?? 'other')
                                          .toUpperCase(),
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          letterSpacing: 0.6,
                                          color: textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 20),
                                color: textTertiary,
                                tooltip: 'Edit',
                                onPressed: () => _editFact(fact),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                color: textTertiary,
                                tooltip: 'Forget this',
                                onPressed: () => _deleteFact(fact),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 40),
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
        currentRoute: '/memory',
        username: widget.username,
        primaryColor: primaryColor,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth <= 800
            ? AppBottomNav(currentRoute: '/memory', username: widget.username)
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
                    currentRoute: '/memory',
                    username: widget.username,
                    primaryColor: primaryColor,
                  ),
                ),
                VerticalDivider(
                    width: 1, color: borderColor, thickness: 1),
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
