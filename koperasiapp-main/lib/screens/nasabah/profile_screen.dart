import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:koperasiapp/screens/nasabah/profile_edit_screen.dart';
import '../common/change_password_screen.dart';
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
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

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
      backgroundColor: Theme.of(context).colorScheme.surface,
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

                // --- PROFILE PHOTO HEADER ---
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              anggota != null &&
                                  anggota['foto_profile_path'] != null
                              ? NetworkImage(
                                  '${_apiService.storageUrl}/${anggota['foto_profile_path']}',
                                )
                              : null,
                          child:
                              anggota == null ||
                                  anggota['foto_profile_path'] == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    anggota?['nama_lengkap'] ?? user['email'],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: Text(
                    anggota?['nomor_anggota'] ?? 'Belum ada nomor anggota',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- GROUP: INFO PRIBADI ---
                _buildCardGroup('Informasi Pribadi', [
                  _buildProfileRow(
                    'TTL',
                    '${anggota?['tempat_lahir'] ?? '-'}, ${anggota?['tanggal_lahir'] ?? '-'}',
                  ),
                  _buildProfileRow(
                    'Jenis Kelamin',
                    (anggota?['jenis_kelamin'] ?? '-').toString().toUpperCase(),
                  ),
                  _buildProfileRow('Agama', anggota?['agama'] ?? '-'),
                  _buildProfileRow('Pendidikan', anggota?['pendidikan'] ?? '-'),
                  _buildProfileRow(
                    'Status',
                    anggota?['status_pernikahan'] ?? '-',
                  ),
                  _buildProfileRow(
                    'Ibu Kandung',
                    anggota?['nama_ibu_kandung'] ?? '-',
                  ),
                ]),

                // --- GROUP: KONTAK & ALAMAT ---
                _buildCardGroup('Kontak & Alamat', [
                  _buildProfileRow('Email', user['email'] ?? '-'),
                  _buildProfileRow('No. HP', anggota?['no_telepon'] ?? '-'),
                  _buildProfileRow('No. KTP', anggota?['nomor_ktp'] ?? '-'),
                  _buildProfileRow(
                    'Alamat',
                    anggota?['alamat'] ?? anggota?['domisili'] ?? '-',
                  ),
                ]),

                // --- GROUP: PEKERJAAN ---
                _buildCardGroup('Pekerjaan', [
                  _buildProfileRow('Pekerjaan', anggota?['pekerjaan'] ?? '-'),
                  _buildProfileRow('Departemen', anggota?['departemen'] ?? '-'),
                ]),

                // --- GROUP: REKENING BANK ---
                _buildCardGroup('Rekening Bank', [
                  _buildProfileRow('Nama Bank', anggota?['nama_bank'] ?? '-'),
                  _buildProfileRow(
                    'No. Rekening',
                    anggota?['no_rekening'] ?? '-',
                  ),
                ]),

                const SizedBox(height: 80), // Bottom padding for FAB
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            label: Text(
              'Ganti Password',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.lock_reset),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'edit_profile',
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
        ],
      ),
    );
  }

  Widget _buildCardGroup(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for labels
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
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
