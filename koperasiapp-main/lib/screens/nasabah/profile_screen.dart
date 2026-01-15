import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:koperasiapp/screens/nasabah/profile_edit_screen.dart';
import '../../services/api_service.dart';

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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mengunggah KTP...')));

        final bytes = await image.readAsBytes();
        await _apiService.uploadKtp(bytes, image.name);

        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KTP berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfile();
      } catch (e) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          final user = snapshot.data!;
          final anggota = user['anggota'];
          final bool isKtpUploaded =
              anggota != null && anggota['ktp_path'] != null;
          final bool isKtpVerified =
              anggota != null && anggota['is_ktp_verified'] == 1;
          final bool isProfileComplete =
              anggota != null &&
              (anggota['nama_lengkap'] != null &&
                  anggota['nama_lengkap'].isNotEmpty);

          return RefreshIndicator(
            onRefresh: () async => _loadProfile(),
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                if (!isProfileComplete)
                  _buildNotificationBanner(
                    'Profil Belum Lengkap',
                    'Silakan lengkapi data diri Anda.',
                    Colors.orange,
                    Icons.edit_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileEditScreen(anggota: anggota ?? {}),
                        ),
                      );
                    },
                  ).animate().fadeIn().slideX(),

                if (isProfileComplete && !isKtpUploaded)
                  _buildNotificationBanner(
                    'KTP Belum Diunggah',
                    'Unggah foto KTP Anda untuk proses verifikasi.',
                    Colors.red,
                    Icons.upload_file_rounded,
                    onPressed: _pickAndUploadKtp,
                  ).animate().fadeIn().slideX(),

                if (isKtpUploaded && !isKtpVerified)
                  _buildNotificationBanner(
                    'Menunggu Verifikasi',
                    'KTP Anda sedang dalam proses verifikasi oleh admin.',
                    Colors.blue,
                    Icons.hourglass_top_rounded,
                  ).animate().fadeIn().slideX(),

                if (isKtpVerified)
                  _buildNotificationBanner(
                    'Profil Terverifikasi',
                    'Data diri dan KTP Anda telah berhasil diverifikasi.',
                    Colors.green,
                    Icons.check_circle_rounded,
                  ).animate().fadeIn().slideX(),

                const SizedBox(height: 20),
                Text(
                  'Info Pribadi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                _buildProfileItem(
                  Icons.badge_rounded,
                  'Nomor Anggota',
                  anggota?['nomor_anggota'] ?? 'Tidak tersedia',
                  0,
                ),
                _buildProfileItem(
                  Icons.person_outline_rounded,
                  'Nama Lengkap',
                  anggota?['nama_lengkap'] ?? 'Tidak tersedia',
                  1,
                ),
                _buildProfileItem(
                  Icons.email_outlined,
                  'Email',
                  user['email'] ?? 'Tidak tersedia',
                  2,
                ),
                _buildProfileItem(
                  Icons.cake_outlined,
                  'Tempat, Tanggal Lahir',
                  '${anggota?['tempat_lahir'] ?? '-'}, ${anggota?['tanggal_lahir'] ?? '-'}',
                  3,
                ),
                _buildProfileItem(
                  anggota?['jenis_kelamin'] == 'laki-laki'
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  'Jenis Kelamin',
                  (anggota?['jenis_kelamin'] ?? 'Tidak tersedia')
                      .toString()
                      .toUpperCase(),
                  4,
                ),

                _buildProfileItem(
                  Icons.phone_outlined,
                  'No. Telepon',
                  anggota?['no_telepon'] ?? 'Tidak tersedia',
                  6,
                ),
                _buildProfileItem(
                  Icons.badge_outlined,
                  'No. KTP / SIM',
                  anggota?['no_ktp'] ?? 'Tidak tersedia',
                  7,
                ),
                _buildProfileItem(
                  Icons.location_on_outlined,
                  'Alamat',
                  anggota?['alamat'] ??
                      anggota?['domisili'] ??
                      'Tidak tersedia',
                  8,
                ),
                _buildProfileItem(
                  Icons.work_outline_rounded,
                  'Pekerjaan',
                  anggota?['pekerjaan'] ?? 'Tidak tersedia',
                  9,
                ),
                _buildProfileItem(
                  Icons.school_outlined,
                  'Pendidikan Terakhir',
                  anggota?['pendidikan'] ?? 'Tidak tersedia',
                  10,
                ),
                _buildProfileItem(
                  Icons
                      .mosque_outlined, // Using generic religious icon lookalike or star
                  'Agama',
                  anggota?['agama'] ?? 'Tidak tersedia',
                  11,
                ),
                _buildProfileItem(
                  Icons.family_restroom_rounded,
                  'Status Pernikahan',
                  anggota?['status_pernikahan'] ?? 'Tidak tersedia',
                  12,
                ),
                _buildProfileItem(
                  Icons.face_3_outlined,
                  'Nama Ibu Kandung',
                  anggota?['nama_ibu_kandung'] ?? 'Tidak tersedia',
                  13,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfileEditScreen(anggota: _anggotaData ?? {}),
            ),
          ).then((_) => _loadProfile());
        },
        label: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.edit_rounded),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    String subtitle,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX();
  }

  Widget _buildNotificationBanner(
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    VoidCallback? onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
        ),
        trailing: onPressed != null
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Aksi'),
              )
            : null,
      ),
    );
  }
}
