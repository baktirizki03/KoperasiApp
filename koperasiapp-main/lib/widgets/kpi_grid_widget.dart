import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class KpiGridWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final int crossAxisCount;

  const KpiGridWidget({super.key, required this.data, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard(
          context,
          'Total Simpanan',
          formatter.format(double.parse(data['total_simpanan'].toString())),
          Icons.account_balance_wallet_rounded,
          Theme.of(context).colorScheme.secondary, // Green for Simpanan
        ),
        _buildKpiCard(
          context,
          'Pinjaman Aktif',
          formatter.format(
            double.parse(data['total_pinjaman_aktif'].toString()),
          ),
          Icons.monetization_on_rounded,
          Colors.red,
        ),
        _buildKpiCard(
          context,
          'Total Anggota',
          data['total_anggota'].toString(),
          Icons.people_rounded,
          Theme.of(context).colorScheme.primary, // Blue for Anggota
        ),
        _buildKpiCard(
          context,
          'Pengajuan Baru',
          data['pengajuan_pinjaman_pending'].toString(),
          Icons.hourglass_top_rounded,
          Colors.orange,
        ),
        _buildKpiCard(
          context,
          'Angsuran Aktif',
          (data['total_angsuran_aktif'] ?? '0').toString(),
          Icons.calendar_today_rounded,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
