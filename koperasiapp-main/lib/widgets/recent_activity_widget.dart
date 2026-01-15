import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class RecentActivityWidget extends StatelessWidget {
  final List activities;
  const RecentActivityWidget({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
            'Aktivitas Terakhir',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Belum ada aktivitas baru.',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ),
            ),
          ListView.builder(
            itemCount: activities.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final activity = activities[index] as Map<String, dynamic>;
              bool isPinjaman = activity.containsKey('tenor_cicilan');

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPinjaman ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPinjaman ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isPinjaman ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                title: Text(
                  isPinjaman ? 'Pinjaman Disetujui' : 'Simpanan Masuk',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  activity['anggota']?['nama_lengkap'] ?? 'Nama tidak ada',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Text(
                  formatter.format(
                    double.parse(activity['nominal'].toString()),
                  ),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isPinjaman ? Colors.red : Colors.green[700],
                    fontSize: 13,
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideX();
            },
          ),
        ],
      ),
    );
  }
}
