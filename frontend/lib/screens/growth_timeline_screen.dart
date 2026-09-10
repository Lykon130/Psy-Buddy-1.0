import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_bottom_nav.dart';

class GrowthTimelineScreen extends StatefulWidget {
  final String username;
  const GrowthTimelineScreen({super.key, required this.username});

  @override
  State<GrowthTimelineScreen> createState() => _GrowthTimelineScreenState();
}

class _GrowthTimelineScreenState extends State<GrowthTimelineScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final all = await ApiService.fetchGoals(widget.username, includeDrafts: true);
      if (mounted) {
        setState(() {
          _goals = all.where((g) => g['confirmed'] == true).toList();
          _drafts = all.where((g) => g['confirmed'] != true).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDraft(Map<String, dynamic> draft) async {
    final id = draft['id'].toString();
    setState(() {
      _drafts.removeWhere((d) => d['id'].toString() == id);
      _goals.insert(0, {...draft, 'confirmed': true});
    });
    try {
      await ApiService.updateGoal(widget.username, id, {'confirmed': true});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      _fetchAll();
    }
  }

  Future<void> _dismissDraft(Map<String, dynamic> draft) async {
    final id = draft['id'].toString();
    setState(() => _drafts.removeWhere((d) => d['id'].toString() == id));
    try {
      await ApiService.deleteGoal(widget.username, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      _fetchAll();
    }
  }

  Future<void> _addGoal() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true || titleController.text.trim().isEmpty) return;

    try {
      final created = await ApiService.createGoal(
        widget.username,
        titleController.text.trim(),
        descController.text.trim().isEmpty ? null : descController.text.trim(),
      );
      if (mounted) setState(() => _goals.insert(0, {...created, 'milestones': []}));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMilestone(Map<String, dynamic> goal) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add milestone'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;

    try {
      final milestone = await ApiService.addMilestone(widget.username, goal['id'].toString(), text);
      if (mounted) {
        setState(() {
          final index = _goals.indexWhere((g) => g['id'] == goal['id']);
          if (index != -1) {
            (_goals[index]['milestones'] as List).add(milestone);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleMilestone(Map<String, dynamic> goal, Map<String, dynamic> milestone) async {
    if (milestone['achieved_at'] != null) return;
    final id = milestone['id'].toString();
    setState(() => milestone['achieved_at'] = DateTime.now().toIso8601String());
    try {
      await ApiService.markMilestoneAchieved(widget.username, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => milestone['achieved_at'] = null);
    }
  }

  Future<void> _archiveGoal(Map<String, dynamic> goal) async {
    final id = goal['id'].toString();
    setState(() => _goals.removeWhere((g) => g['id'].toString() == id));
    try {
      await ApiService.updateGoal(widget.username, id, {'status': 'archived'});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      _fetchAll();
    }
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
        title: Text('Growth Timeline',
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
          IconButton(
            icon: Icon(Icons.add, color: primary),
            tooltip: 'New goal',
            onPressed: _addGoal,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _fetchAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_drafts.isNotEmpty) ...[
                      Text('Noticed in conversation',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'PsyBuddy picked these up from chat. Add them to your timeline, or dismiss.',
                        style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ..._drafts.map((draft) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(draft['title']?.toString() ?? '',
                                      style: GoogleFonts.inter(fontSize: 14, color: textPrimary)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, size: 20),
                                  color: primary,
                                  tooltip: 'Add to timeline',
                                  onPressed: () => _confirmDraft(draft),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: textTertiary,
                                  tooltip: 'Dismiss',
                                  onPressed: () => _dismissDraft(draft),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],
                    Text('Goals',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 12),
                    if (_goals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text('No goals yet — tap + to add one',
                              style: GoogleFonts.inter(fontSize: 14, color: textTertiary)),
                        ),
                      )
                    else
                      ..._goals.map((goal) {
                        final milestones =
                            List<Map<String, dynamic>>.from(goal['milestones'] ?? []);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(goal['title']?.toString() ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary)),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 18, color: textTertiary),
                                    onSelected: (value) {
                                      if (value == 'archive') _archiveGoal(goal);
                                      if (value == 'milestone') _addMilestone(goal);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'milestone', child: Text('Add milestone')),
                                      PopupMenuItem(value: 'archive', child: Text('Archive')),
                                    ],
                                  ),
                                ],
                              ),
                              if ((goal['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(goal['description'].toString(),
                                    style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
                              ],
                              if (milestones.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ...milestones.map((m) {
                                  final achieved = m['achieved_at'] != null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: InkWell(
                                      onTap: () => _toggleMilestone(goal, m),
                                      child: Row(
                                        children: [
                                          Icon(
                                            achieved
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            size: 16,
                                            color: achieved ? primary : textTertiary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              m['description']?.toString() ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: achieved ? textTertiary : textPrimary,
                                                decoration: achieved
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
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
        currentRoute: '/growth',
        username: widget.username,
        primaryColor: primaryColor,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth <= 800
            ? AppBottomNav(currentRoute: '/growth', username: widget.username)
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
                    currentRoute: '/growth',
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
