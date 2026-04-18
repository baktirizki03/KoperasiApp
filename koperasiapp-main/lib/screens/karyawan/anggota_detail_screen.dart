import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../widgets/secure_image_widget.dart';

class AnggotaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> anggota;

  const AnggotaDetailScreen({super.key, required this.anggota});

  @override
  _AnggotaDetailScreenState createState() => _AnggotaDetailScreenState();
}

class _AnggotaDetailScreenState extends State<AnggotaDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final anggota = widget.anggota;
    final apiService = ApiService();
    
    // Resolve KTP URL
    String ktpUrl = anggota['ktp_path'] ?? '';
    if (ktpUrl.isNotEmpty && !ktpUrl.startsWith('http')) {
      ktpUrl = "${apiService.storageUrl}/$ktpUrl";
    }

    // Resolve Profile Photo URL
    String fotoProfileUrl = anggota['foto_profile_path'] ?? '';
    if (fotoProfileUrl.isNotEmpty && !fotoProfileUrl.startsWith('http')) {
      fotoProfileUrl = "${apiService.storageUrl}/$fotoProfileUrl";
    }

    final bool isVerified = anggota['is_ktp_verified'] == 1 || 
                           anggota['is_ktp_verified'] == true || 
                           anggota['is_ktp_verified'].toString() == '1' || 
                           anggota['is_ktp_verified'].toString() == 'true';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PREMIUM PROFILE HEADER ---
            _buildHeader(context, anggota, fotoProfileUrl),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // --- STATUS CARD ---
                  _buildStatusCard(anggota, isVerified, ktpUrl)
                      .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // --- PERSONAL INFO CARD ---
                  _buildSectionCard(
                    title: 'Informasi Pribadi',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildDetailRow('Asal TPS', anggota['asal_tps']),
                      _buildDetailRow('TTL', '${anggota['tempat_lahir']}, ${anggota['tanggal_lahir']}'),
                      _buildDetailRow('Jenis Kelamin', anggota['jenis_kelamin']),
                      _buildDetailRow('Agama', anggota['agama']),
                      _buildDetailRow('Pernikahan', anggota['status_pernikahan']),
                      _buildDetailRow('Pendidikan', anggota['pendidikan']),
                      _buildDetailRow('Pekerjaan', anggota['pekerjaan']),
                      _buildDetailRow('Ibu Kandung', anggota['nama_ibu_kandung']),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // --- CONTACT CARD ---
                  _buildSectionCard(
                    title: 'Kontak & Alamat',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      _buildDetailRow('Email', anggota['user']?['email']),
                      _buildDetailRow('No. Telepon', anggota['no_telepon']),
                      _buildDetailRow('Alamat', anggota['domisili']),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> anggota, String fotoUrl) {
    return Stack(
      children: [
        // Background Gradient
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Custom Top Nav
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('Detail Anggota', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Avatar
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: fotoUrl.isNotEmpty
                        ? ClipOval(
                            child: SecureImageWidget(
                              imageUrl: anggota['foto_profile_path'],
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (anggota['nama_lengkap'] != null && anggota['nama_lengkap'].isNotEmpty
                            ? Text(
                                anggota['nama_lengkap'][0].toUpperCase(),
                                style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : const Icon(Icons.person, size: 50, color: Color.fromARGB(255, 255, 255, 255))),
                  ),
                ),
              ).animate().scale(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                anggota['nama_lengkap'] ?? 'No Name',
                style: GoogleFonts.poppins(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'No Anggota: ${anggota['nomor_anggota'] ?? '-'}',
                style: GoogleFonts.poppins(color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> anggota, bool isVerified, String ktpUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Akun', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isVerified ? Icons.check_circle : Icons.hourglass_top, size: 16, color: isVerified ? Colors.green : Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          isVerified ? 'TERVERIFIKASI' : 'PENDING',
                          style: GoogleFonts.poppins(color: isVerified ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (ktpUrl.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showKtpDialog(context, ktpUrl),
                  icon: const Icon(Icons.dock_rounded, size: 18),
                  label: Text('Lihat KTP', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
            ],
          ),
          if (isVerified && (anggota['verified_by_name'] != null || anggota['verified_by'] != null))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Colors.blueGrey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diverifikasi oleh: ${anggota['verified_by_name'] ?? anggota['verified_by']?['role']?.toString().toUpperCase() ?? '-'}',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[600], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2D3436), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showKtpDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Foto KTP', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: const Color(0xFF0D47A1),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              automaticallyImplyLeading: false,
            ),
            InteractiveViewer(
              child: SecureImageWidget(imageUrl: url, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
