import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_bottom_nav.dart';

class MoodPoint {
  final DateTime date;
  final double score;
  MoodPoint(this.date, this.score);
}

class MoodScreen extends StatefulWidget {
  final String username;
  const MoodScreen({super.key, required this.username});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int _selectedDays = 7;
  bool _loading = false;
  Map<String, dynamic>? _moodData;
  List<MoodPoint> _moodPoints = [];

  @override
  void initState() {
    super.initState();
    _fetchMood();
  }

  Future<void> _fetchMood() async {
    setState(() => _loading = true);
    try {
      final data =
          await ApiService.fetchMoodData(widget.username, days: _selectedDays);
      List<MoodPoint> moodPoints = [];
      if (data['mood_trend'] != null) {
        moodPoints = (data['mood_trend'] as List)
            .map((e) => MoodPoint(
                  DateTime.parse(e['date']),
                  (e['score'] as num).toDouble(),
                ))
            .toList();
      }
      if (mounted) {
        setState(() {
          _moodData = data;
          _moodPoints = moodPoints;
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

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy': case 'amusement': case 'excitement': case 'optimism':
        return const Color(0xFFF59E0B);
      case 'admiration': case 'approval': case 'pride':
        return const Color(0xFF10B981);
      case 'caring': case 'love': case 'sadness': case 'grief':
        return const Color(0xFF3B82F6);
      case 'anger': case 'annoyance': case 'disgust':
        return const Color(0xFFEF4444);
      case 'fear': case 'nervousness':
        return const Color(0xFF8B5CF6);
      case 'confusion':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color primary,
      Color surfaceColor, Color borderColor, Color textPrimary,
      Color textSecondary) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: primary),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSegments(bool isDark, Color surfaceVar, Color surfaceColor,
      Color textPrimary, Color textTertiary, Color borderColor) {
    final options = [
      {'label': '7 Days', 'value': 7},
      {'label': '30 Days', 'value': 30},
      {'label': 'All Time', 'value': 0},
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceVar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _selectedDays == opt['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedDays != opt['value']) {
                  setState(() => _selectedDays = opt['value'] as int);
                  _fetchMood();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? surfaceColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                              color: const Color(0xFF6B5EE8).withOpacity(0.08),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    opt['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? textPrimary : textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(Color primary, Color surfaceColor, Color borderColor,
      Color textTertiary) {
    if (_moodPoints.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 40, color: textTertiary),
              const SizedBox(height: 12),
              Text('Not enough data yet',
                  style: GoogleFonts.inter(
                      fontSize: 15, color: textTertiary)),
            ],
          ),
        ),
      );
    }

    final baseTime =
        _moodPoints.first.date.millisecondsSinceEpoch.toDouble();

    return Container(
      height: 240,
      padding: const EdgeInsets.only(right: 20, top: 24, bottom: 12, left: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.2,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: borderColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _moodPoints
                  .map((e) => FlSpot(
                        (e.date.millisecondsSinceEpoch.toDouble() -
                                baseTime) /
                            86400000,
                        e.score,
                      ))
                  .toList(),
              isCurved: true,
              color: primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: primary,
                  strokeWidth: 2,
                  strokeColor: surfaceColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(0.18),
                    primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBreakdown(bool isDark, Color primary, Color surfaceColor,
      Color borderColor, Color textPrimary, Color textSecondary) {
    final totals = _moodData?['totals'] as Map<String, dynamic>? ?? {};
    if (totals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emotion Breakdown',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: totals.entries.map((e) {
            final eColor = _getEmotionColor(e.key);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: eColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(e.key,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          fontSize: 13)),
                  const SizedBox(width: 12),
                  Text(e.value.toString(),
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: primary)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);
    final surfaceColor = isDark ? const Color(0xFF16161F) : Colors.white;
    final surfaceVar = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F8);
    final borderColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final textPrimary = isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary = isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final textTertiary = isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);
    final primary = isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);

    // Compute stats
    final totals = _moodData?['totals'] as Map<String, dynamic>? ?? {};
    final totalCount = totals.values.fold<int>(0, (a, b) => a + (b as int));
    final dominantEmotion = totals.isEmpty
        ? '—'
        : (totals.entries
            .reduce((a, b) => (a.value as int) >= (b.value as int) ? a : b)
            .key);
    final avgScore = _moodPoints.isEmpty
        ? 0.0
        : _moodPoints.map((p) => p.score).reduce((a, b) => a + b) /
            _moodPoints.length;

    return Scaffold(
      backgroundColor: isDesktop ? surfaceColor : bgColor,
      appBar: AppBar(
        backgroundColor: isDesktop ? surfaceColor : bgColor,
        elevation: 0,
        title: Text('Mood Insights',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _buildStatCard(
                          'Total', '$totalCount',
                          Icons.bar_chart_outlined, primary,
                          surfaceColor, borderColor, textPrimary, textSecondary),
                      const SizedBox(width: 12),
                      _buildStatCard(
                          'Dominant',
                          dominantEmotion.length > 8
                              ? '${dominantEmotion.substring(0, 7)}…'
                              : dominantEmotion,
                          Icons.emoji_emotions_outlined, primary,
                          surfaceColor, borderColor, textPrimary, textSecondary),
                      const SizedBox(width: 12),
                      _buildStatCard(
                          'Avg Score',
                          '${(avgScore * 100).toStringAsFixed(0)}%',
                          Icons.trending_up_outlined, primary,
                          surfaceColor, borderColor, textPrimary, textSecondary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Filter segments
                  _buildFilterSegments(
                      isDark, surfaceVar, surfaceColor,
                      textPrimary, textTertiary, borderColor),
                  const SizedBox(height: 24),
                  Text('Mood Trend',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const SizedBox(height: 16),
                  _buildChart(primary, surfaceColor, borderColor, textTertiary),
                  const SizedBox(height: 32),
                  _buildEmotionBreakdown(isDark, primary, surfaceColor,
                      borderColor, textPrimary, textSecondary),
                  const SizedBox(height: 40),
                ],
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
        currentRoute: '/mood',
        username: widget.username,
        primaryColor: primaryColor,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth <= 800
            ? AppBottomNav(currentRoute: '/mood', username: widget.username)
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
                    currentRoute: '/mood',
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
