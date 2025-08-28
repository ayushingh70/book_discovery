

// Not well maintained as planned, So please consider to redesign this screen //

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // --- Demo data ---
  final Map<String, double> _genre = const {
    'Fiction': 38,
    'Non-fiction': 26,
    'Romance': 14,
    'Sci-fi': 8,
    'Thriller': 7,
    'History': 4,
    'Biography': 3,
  };

  final List<_Point> _trend = const [
    _Point(2021, 1200),
    _Point(2022, 3400),
    _Point(2023, 2800),
    _Point(2024, 4200),
    _Point(2025, 4800),
  ];

  final List<_Bar> _sales = const [
    _Bar('Q1', 12.0),
    _Bar('Q2', 18.5),
    _Bar('Q3', 16.0),
    _Bar('Q4', 22.0),
  ];

  String get _firstName {
    final u = FirebaseAuth.instance.currentUser;
    final dn = (u?.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn.split(' ').first;
    final em = (u?.email ?? '').trim();
    if (em.contains('@')) return em.split('@').first;
    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final h = MediaQuery.of(context).size.height;

    // Size of blue header
    final double headerTotalH = h * 0.10;
    final double headerContentH = h * 0.10;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: CustomScrollView(
          slivers: [
            // --- Pinned blue header (never covered) ---
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF3D5CFF),
              elevation: 0,
              expandedHeight: headerTotalH + pad.top,
              collapsedHeight: headerTotalH + pad.top,
              flexibleSpace: SafeArea(
                bottom: false,
                child: Container(
                  color: const Color(0xFF3D5CFF),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: SizedBox(
                    height: headerContentH - 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, $_firstName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Let's start learning",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFE9EAFE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/avatar.png',
                            width: 36,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Small spacer to create the “float into blue” look ---
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // --- Genre (Demo) ---
            SliverToBoxAdapter(
              child: _CardPage(
                tight: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Genre distribution (Demo)'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.25,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 42,
                                startDegreeOffset: -90,
                                sections: _pieSections(_genre),
                                pieTouchData: PieTouchData(enabled: false),
                              ),
                              duration: const Duration(milliseconds: 550),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _Legend(keys: _genre.keys.toList()),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // --- Publishing Trend (Demo) ---
            SliverToBoxAdapter(
              child: _CardPage(
                tight: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Book Publishing Trend (Demo)'),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minX: 2021,
                          maxX: 2025,
                          minY: 0,
                          maxY: 5200,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1000,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: const Color(0x332D3DF7),
                              dashArray: [6, 6],
                              strokeWidth: 1.2,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                interval: 1000,
                                getTitlesWidget: (v, _) => Text(
                                  '${v ~/ 1000}k',
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 11),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (v, _) => Text(
                                  v.toInt().toString(),
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 11),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              barWidth: 3,
                              color: const Color(0xFF3D5CFF),
                              dotData: FlDotData(show: false),
                              spots: _trend
                                  .map((p) =>
                                  FlSpot(p.year.toDouble(), p.value.toDouble()))
                                  .toList(),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: const [
                                    Color(0xFF3D5CFF),
                                    Color(0xFF3D5CFF),
                                  ].map((c) => c.withOpacity(0.10)).toList(),
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          borderData: FlBorderData(show: false),
                        ),
                        duration: const Duration(milliseconds: 520),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // --- Sales (Demo) ---
            SliverToBoxAdapter(
              child: _CardPage(
                tight: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Sales Overview (Demo)'),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            _sales.length,
                                (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: _sales[i].value,
                                  width: 16,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF3D5CFF),
                                      const Color(0xFF3D5CFF).withOpacity(0.75),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _sales[v.toInt()].label,
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        duration: const Duration(milliseconds: 500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // --- Promo ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/ads3.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _pieSections(Map<String, double> data) {
    final rnd = Random(7);
    final colors = List<Color>.generate(
      data.length,
          (_) => Color.lerp(const Color(0xFF3D5CFF), Colors.teal, rnd.nextDouble())!
          .withOpacity(0.9),
    );
    final total = data.values.fold<double>(0, (a, b) => a + b);
    final keys = data.keys.toList();

    return List.generate(keys.length, (i) {
      final k = keys[i];
      final v = data[k]!;
      return PieChartSectionData(
        color: colors[i],
        value: v,
        radius: 48,
        title: '${((v / total) * 100).round()}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      );
    });
  }
}

// --- Small widgets ---

class _CardPage extends StatelessWidget {
  const _CardPage({required this.child, this.tight = false});
  final Widget child;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    // Slightly narrower + 3D + grey edge
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tight ? 20 : 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9FAFF), Color(0xFFF0F4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E4EF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143D5CFF),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: Color(0xFF1F1F39),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.keys});
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final rnd = Random(7);
    final colors = List<Color>.generate(
      keys.length,
          (_) => Color.lerp(const Color(0xFF3D5CFF), Colors.teal, rnd.nextDouble())!
          .withOpacity(0.9),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(keys.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                BoxDecoration(color: colors[i], shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                keys[i],
                style:
                const TextStyle(color: Color(0xFF1F1F39), fontSize: 12.5),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// --- Simple data holders ---

class _Point {
  final int year;
  final int value;
  const _Point(this.year, this.value);
}

class _Bar {
  final String label;
  final double value;
  const _Bar(this.label, this.value);
}