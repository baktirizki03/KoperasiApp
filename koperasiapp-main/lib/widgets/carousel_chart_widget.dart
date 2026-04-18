import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CarouselChartWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<dynamic> simpananList;
  final List<dynamic> pinjamanList;
  final List<dynamic> anggotaList;

  const CarouselChartWidget({
    super.key,
    required this.data,
    required this.simpananList,
    required this.pinjamanList,
    required this.anggotaList,
  });

  @override
  State<CarouselChartWidget> createState() => _CarouselChartWidgetState();
}

class _CarouselChartWidgetState extends State<CarouselChartWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 320, // Height for chart cards
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: [
              _buildPortfolioChart(),
              _buildTrendChart(),
              _buildGrowthChart(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 1. Portfolio Chart (Pie) - Existing Logic
  // --- Chart Card Wrapper ---
  Widget _buildCard(String title, Widget chart, List<Widget> legend, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3436),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              const Icon(Icons.analytics_outlined, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: chart),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: legend,
          ),
        ],
      ),
    );
  }

  // 1. Portfolio Chart (Donut)
  Widget _buildPortfolioChart() {
    final double totalSimpanan = double.tryParse(widget.data['total_simpanan'].toString()) ?? 0.0;
    final double totalPinjaman = double.tryParse(widget.data['total_pinjaman_aktif'].toString()) ?? 0.0;
    final double total = totalSimpanan + totalPinjaman;

    if (total == 0) {
      return _buildCard('Portfolio Aset', const Center(child: Text('Belum ada data')), []);
    }

    return _buildCard(
      'Komposisi Dana',
      subtitle: 'Distribusi Simpanan & Pinjaman',
      Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF0D47A1),
                  value: totalSimpanan,
                  title: '${(totalSimpanan / total * 100).toStringAsFixed(0)}%',
                  radius: 20,
                  titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10),
                ),
                PieChartSectionData(
                  color: const Color(0xFFE67E22),
                  value: totalPinjaman,
                  title: '${(totalPinjaman / total * 100).toStringAsFixed(0)}%',
                  radius: 20,
                  titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TOTAL', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  NumberFormat.compactCurrency(locale: 'id', symbol: '').format(total),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0D47A1)),
                ),
              ],
            ),
          ),
        ],
      ),
      [
        _buildLegend(const Color(0xFF0D47A1), 'Simpanan'),
        _buildLegend(const Color(0xFFE67E22), 'Pinjaman'),
      ],
    );
  }

  // 2. Trend Chart (Premium Line)
  Widget _buildTrendChart() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      DateTime nextMonth = DateTime(now.year, now.month - i + 1, 1);

      double simpananMonth = 0;
      for (var s in widget.simpananList) {
        DateTime? date = DateTime.tryParse(s['tanggal'] ?? s['created_at'] ?? '');
        if (date != null && date.isAfter(month) && date.isBefore(nextMonth)) {
          double amount = double.tryParse((s['nominal'] ?? '0').toString()) ?? 0;
          if ((s['tipe'] ?? '').toLowerCase() == 'kredit') simpananMonth += amount;
        }
      }

      double pinjamanMonth = 0;
      for (var p in widget.pinjamanList) {
        DateTime? date = DateTime.tryParse(p['created_at'] ?? '');
        if (date != null && date.isAfter(month) && date.isBefore(nextMonth)) {
          double amount = double.tryParse((p['nominal'] ?? '0').toString()) ?? 0;
          pinjamanMonth += amount;
        }
      }

      double totalMonth = simpananMonth + pinjamanMonth;
      spots.add(FlSpot((5 - i).toDouble(), totalMonth));
      if (totalMonth > maxY) maxY = totalMonth;
    }

    if (maxY == 0) maxY = 100;

    return _buildCard(
      'Tren Aktivitas',
      subtitle: 'Volume Transaksi 6 Bulan Terakhir',
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1, dashArray: [5, 5]),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index <= 5) {
                    DateTime month = DateTime(now.year, now.month - (5 - index), 1);
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(DateFormat('MMM').format(month), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF0D47A1),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: const Color(0xFF0D47A1)),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [const Color(0xFF0D47A1).withOpacity(0.15), const Color(0xFF0D47A1).withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF0D47A1),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp ').format(spot.y),
                    GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
      [_buildLegend(const Color(0xFF0D47A1), 'Total Volume')],
    );
  }

  // 3. Growth Chart (Premium Bar)
  Widget _buildGrowthChart() {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      DateTime nextMonth = DateTime(now.year, now.month - i + 1, 1);

      int newMembers = widget.anggotaList.where((m) {
        DateTime? date = DateTime.tryParse(m['created_at'] ?? '');
        return date != null && date.isAfter(month) && date.isBefore(nextMonth);
      }).length;

      if (newMembers > maxY) maxY = newMembers.toDouble();

      barGroups.add(
        BarChartGroupData(
          x: 5 - i,
          barRods: [
            BarChartRodData(
              toY: newMembers.toDouble(),
              gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF81C784)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY == 0 ? 5 : maxY + 2,
                color: const Color(0xFFF1F5FF),
              ),
            ),
          ],
        ),
      );
    }

    return _buildCard(
      'Pertumbuhan',
      subtitle: 'Anggota Baru 6 Bulan Terakhir',
      BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index <= 5) {
                    DateTime month = DateTime(now.year, now.month - (5 - index), 1);
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(DateFormat('MMM').format(month), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          maxY: maxY == 0 ? 5 : maxY + 2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF2E7D32),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} Anggota',
                  GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
      [_buildLegend(const Color(0xFF2E7D32), 'Anggota Baru')],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
