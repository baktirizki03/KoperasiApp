import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class FinancialChartWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  const FinancialChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double totalSimpanan =
        double.tryParse(data['total_simpanan'].toString()) ?? 0.0;
    final double totalPinjaman =
        double.tryParse(data['total_pinjaman_aktif'].toString()) ?? 0.0;
    final double total = totalSimpanan + totalPinjaman;

    // Hindari pembagian dengan nol
    if (total == 0) return const SizedBox.shrink();

    return Container(
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
            'Statistik Kategori',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 5,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    color: Theme.of(context).colorScheme.secondary,
                    value: totalSimpanan,
                    title:
                        '${(totalSimpanan / total * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: totalPinjaman,
                    title:
                        '${(totalPinjaman / total * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(
                Theme.of(context).colorScheme.secondary,
                'Total Simpanan',
              ),
              const SizedBox(width: 20),
              _buildLegend(Colors.red, 'Pinjaman Aktif'),
            ],
          ),
        ],
      ),
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
        Text(text, style: GoogleFonts.poppins(color: Colors.grey[700])),
      ],
    );
  }
}
