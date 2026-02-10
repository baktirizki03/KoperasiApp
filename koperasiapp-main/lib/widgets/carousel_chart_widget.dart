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
  Widget _buildCard(String title, Widget chart, List<Widget> legend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: chart),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: legend),
        ],
      ),
    );
  }

  Widget _buildPortfolioChart() {
    final double totalSimpanan =
        double.tryParse(widget.data['total_simpanan'].toString()) ?? 0.0;
    final double totalPinjaman =
        double.tryParse(widget.data['total_pinjaman_aktif'].toString()) ?? 0.0;
    final double total = totalSimpanan + totalPinjaman;

    if (total == 0) {
      return _buildCard(
        'Portfolio Aset',
        Center(child: Text('Belum ada data')),
        [],
      );
    }

    return _buildCard(
      'Komposisi Aset (Simpanan vs Pinjaman)',
      PieChart(
        PieChartData(
          sectionsSpace: 5,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: const Color(0xFF6A11CB),
              value: totalSimpanan,
              title: '${(totalSimpanan / total * 100).toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            PieChartSectionData(
              color: const Color(0xFFFF512F),
              value: totalPinjaman,
              title: '${(totalPinjaman / total * 100).toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      [
        _buildLegend(const Color(0xFF6A11CB), 'Simpanan'),
        const SizedBox(width: 16),
        _buildLegend(const Color(0xFFFF512F), 'Pinjaman'),
      ],
    );
  }

  // 2. Trend Chart (Line) - Simulated/Aggregated
  Widget _buildTrendChart() {
    // Aggregate data per month for the last 6 months
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      DateTime nextMonth = DateTime(now.year, now.month - i + 1, 1);

      // Calculate total transaction volume in this month
      // Simpanan
      double simpananMonth = 0;
      for (var s in widget.simpananList) {
        DateTime? date = DateTime.tryParse(
          s['tanggal'] ?? s['created_at'] ?? '',
        );
        if (date != null && date.isAfter(month) && date.isBefore(nextMonth)) {
          double amount =
              double.tryParse((s['nominal'] ?? '0').toString()) ?? 0;
          if ((s['tipe'] ?? '').toLowerCase() == 'kredit')
            simpananMonth += amount;
        }
      }

      // Pinjaman (as Outflow or Asset Growth? Let's use Asset Growth (Disbursed Loans))
      double pinjamanMonth = 0;
      for (var p in widget.pinjamanList) {
        DateTime? date = DateTime.tryParse(p['created_at'] ?? '');
        if (date != null && date.isAfter(month) && date.isBefore(nextMonth)) {
          double amount =
              double.tryParse((p['nominal'] ?? '0').toString()) ?? 0;
          pinjamanMonth += amount;
        }
      }

      double totalMonth = simpananMonth + pinjamanMonth; // Activity Volume
      spots.add(FlSpot((5 - i).toDouble(), totalMonth));
      if (totalMonth > maxY) maxY = totalMonth;
    }

    if (maxY == 0) maxY = 100;

    return _buildCard(
      'Tren Aktivitas Keuangan (6 Bulan)',
      LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index <= 5) {
                    DateTime month = DateTime(
                      now.year,
                      now.month - (5 - index),
                      1,
                    );
                    return Text(
                      DateFormat('MMM').format(month),
                      style: const TextStyle(fontSize: 10),
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
              color: Colors.blueAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
      [_buildLegend(Colors.blueAccent, 'Volume Transaksi')],
    );
  }

  // 3. Growth Chart (Bar) - Member Growth
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
              color: Colors.teal,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY == 0 ? 5 : maxY + 2,
                color: Colors.teal.withOpacity(0.05),
              ),
            ),
          ],
        ),
      );
    }

    return _buildCard(
      'Pertumbuhan Anggota (6 Bulan)',
      BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index <= 5) {
                    DateTime month = DateTime(
                      now.year,
                      now.month - (5 - index),
                      1,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM').format(month),
                        style: const TextStyle(fontSize: 10),
                      ),
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
        ),
      ),
      [_buildLegend(Colors.teal, 'Anggota Baru')],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12),
        ),
      ],
    );
  }
}
