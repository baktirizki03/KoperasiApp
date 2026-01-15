import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'anggota_list_screen.dart';
import 'pinjaman_list_screen.dart';
import 'simpanan_verifikasi_screen.dart';

class KaryawanDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Dashboard Karyawan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildMenuCard(
            context,
            title: 'Kelola Data Anggota',
            subtitle: 'Tambah, edit, atau hapus data anggota',
            icon: Icons.people_rounded,
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (ctx) => AnggotaListScreen()));
            },
            delay: 100,
          ),
          _buildMenuCard(
            context,
            title: 'Manajemen Pinjaman',
            subtitle: 'Verifikasi pengajuan pinjaman anggota',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFE67E22), // Orange for Loans/Money
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (ctx) => PinjamanListScreen()));
            },
            delay: 200,
          ),
          _buildMenuCard(
            context,
            title: 'Verifikasi Simpanan',
            subtitle: 'Setujui setoran dari anggota',
            icon: Icons.account_balance_wallet_rounded,
            color: Theme.of(context).colorScheme.secondary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => SimpananVerifikasiScreen()),
              );
            },
            delay: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX();
  }
}
