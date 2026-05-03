import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

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
      final data = await ApiService.fetchMoodData(widget.username, days: _selectedDays);
      List<MoodPoint> moodPoints = [];

      if (data["mood_trend"] != null) {
        moodPoints = (data["mood_trend"] as List)
            .map((e) => MoodPoint(DateTime.parse(e["date"]), (e["score"] as num).toDouble()))
            .toList();
      }

      if (mounted) {
        setState(() {
          _moodData = data;
          _moodPoints = moodPoints;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildFilterChips() {
    final options = [
      {"label": "7 Days", "value": 7},
      {"label": "30 Days", "value": 30},
      {"label": "All Time", "value": 0},
    ];

    return Wrap(
      spacing: 12,
      children: options.map((opt) {
        final isSelected = _selectedDays == opt["value"];
        return ChoiceChip(
          label: Text(opt["label"] as String, style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )),
          selected: isSelected,
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          onSelected: (selected) {
            if (selected && _selectedDays != opt["value"]) {
              setState(() => _selectedDays = opt["value"] as int);
              _fetchMood();
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    if (_moodPoints.isEmpty) {
      return Center(child: Text("Not enough data to graph.", style: GoogleFonts.inter(color: Colors.black54)));
    }

    final baseTime = _moodPoints.first.date.millisecondsSinceEpoch.toDouble();
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      height: 300,
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.2,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.black.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return const Text(''); // simple line for now, date logic can go here
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _moodPoints.map((e) {
                return FlSpot((e.date.millisecondsSinceEpoch.toDouble() - baseTime) / 86400000, e.score);
              }).toList(),
              isCurved: true,
              color: primaryColor,
              barWidth: 4,
              dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: primaryColor, strokeWidth: 2, strokeColor: Colors.white)),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.0)],
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

  Widget _buildEmotionBreakdown() {
    final totals = _moodData?["totals"] as Map<String, dynamic>? ?? {};
    if (totals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Emotion Breakdown", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: totals.entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.key.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text(e.value.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mental Wellness", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 32),
                  Text("Your Mood Trend", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildChart(),
                  const SizedBox(height: 32),
                  _buildEmotionBreakdown(),
                ],
              ),
            ),
    );
  }
}