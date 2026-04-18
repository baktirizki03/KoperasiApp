import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:koperasiapp/screens/nasabah/profile_edit_screen.dart';
import '../common/change_password_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/secure_image_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late Future<Map<String, dynamic>> _profileFuture;
  Map<String, dynamic>? _anggotaData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = _apiService.getMyProfile().then((data) {
        _anggotaData = data['anggota'];
        return data;
      });
    });
  }

  Future<void> _pickAndUploadKtp() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengunggah KTP...')));
        final bytes = await image.readAsBytes();
        await _apiService.uploadKtp(bytes, image.name);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KTP berhasil diunggah!'), backgroundColor: Colors.green));
        _loadProfile();
      } catch (e) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: Text('Data profil tidak ditemukan.'));

          final user = snapshot.data!;
          final anggota = user['anggota'];
          final bool isKtpUploaded = anggota != null && anggota['ktp_path'] != null;
          final val = anggota?['is_ktp_verified'];
          final bool isKtpVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';
          final bool isProfileComplete = anggota != null && (anggota['nama_lengkap'] != null && anggota['nama_lengkap'].isNotEmpty);

          return RefreshIndicator(
            onRefresh: () async => _loadProfile(),
            child: CustomScrollView(
              slivers: [
                _buildSliverHeader(user, anggota),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isProfileComplete) _buildNotificationBanner('Profil Belum Lengkap', 'Silakan lengkapi data diri Anda.', Colors.orange, Icons.edit_rounded, onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(anggota: anggota ?? {})));
                        }),
                        if (isProfileComplete && !isKtpUploaded) _buildNotificationBanner('KTP Belum Diunggah', 'Unggah foto KTP Anda untuk proses verifikasi.', Colors.red, Icons.upload_file_rounded, onPressed: _pickAndUploadKtp),
                        if (isKtpUploaded && !isKtpVerified) _buildNotificationBanner('Menunggu Verifikasi', 'KTP Anda sedang dalam proses verifikasi oleh admin.', const Color(0xFF0D47A1), Icons.hourglass_top_rounded),
                        if (isKtpVerified) _buildNotificationBanner('Akun Telah Terverifikasi', 'Data diri dan KTP Anda telah berhasil diverifikasi.', Colors.green, Icons.check_circle_rounded),
                        
                        const SizedBox(height: 16),
                        _buildInfoSection('Informasi Pribadi', [
                          _buildProfileRow(Icons.cake_rounded, 'TTL', '${anggota?['tempat_lahir'] ?? '-'}, ${anggota?['tanggal_lahir'] ?? '-'}'),
                          _buildProfileRow(Icons.wc_rounded, 'Jenis Kelamin', (anggota?['jenis_kelamin'] ?? '-').toString().toUpperCase()),
                          _buildProfileRow(Icons.mosque_rounded, 'Agama', anggota?['agama'] ?? '-'),
                          _buildProfileRow(Icons.school_rounded, 'Pendidikan', anggota?['pendidikan'] ?? '-'),
                          _buildProfileRow(Icons.favorite_rounded, 'Status Pernikahan', anggota?['status_pernikahan'] ?? '-'),
                          _buildProfileRow(Icons.family_restroom_rounded, 'Ibu Kandung', anggota?['nama_ibu_kandung'] ?? '-'),
                        ]),
                        _buildInfoSection('Kontak & Alamat', [
                          _buildProfileRow(Icons.email_rounded, 'Email', user['email'] ?? '-'),
                          _buildProfileRow(Icons.phone_rounded, 'No. HP', anggota?['no_telepon'] ?? '-'),
                          _buildProfileRow(Icons.badge_rounded, 'No. KTP', anggota?['nomor_ktp'] ?? '-'),
                          _buildProfileRow(Icons.location_on_rounded, 'Alamat', anggota?['alamat'] ?? anggota?['domisili'] ?? '-'),
                        ]),
                        _buildInfoSection('Pekerjaan', [
                          _buildProfileRow(Icons.work_rounded, 'Pekerjaan', anggota?['pekerjaan'] ?? '-'),
                          _buildProfileRow(Icons.apartment_rounded, 'Departemen', anggota?['departemen'] ?? '-'),
                        ]),
                        _buildInfoSection('Rekening Bank', [
                          _buildProfileRow(Icons.account_balance_rounded, 'Nama Bank', anggota?['nama_bank'] ?? '-'),
                          _buildProfileRow(Icons.credit_card_rounded, 'No. Rekening', anggota?['no_rekening'] ?? '-'),
                        ]),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'change_password',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen())),
            label: Text('Ganti Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.lock_reset, color: Colors.white),
            backgroundColor: Colors.orange[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ).animate().slideY(begin: 0.1, duration: 400.ms),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'edit_profile',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(anggota: _anggotaData ?? {}))).then((_) => _loadProfile());
            },
            label: Text('Edit Profil', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            backgroundColor: const Color(0xFF0D47A1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ).animate().slideY(begin: 0.1, duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(Map<String, dynamic> user, dynamic anggota) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[100],
                    child: anggota != null && anggota['foto_profile_path'] != null
                        ? ClipOval(child: SecureImageWidget(imageUrl: anggota['foto_profile_path'], width: 100, height: 100, fit: BoxFit.cover))
                        : Icon(Icons.person_rounded, size: 50, color: Colors.grey[400]),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2))),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 16),
            Text(anggota?['nama_lengkap'] ?? user['email'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(anggota?['nomor_anggota'] ?? 'Anggota Baru', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBanner(String title, String subtitle, Color color, IconData icon, {VoidCallback? onPressed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
        trailing: onPressed != null
            ? TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16)),
                child: Text('Lengkapi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12), child: Text(title.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1).withOpacity(0.6), letterSpacing: 1.2))),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(children: children),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D47A1).withOpacity(0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2D3436))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
