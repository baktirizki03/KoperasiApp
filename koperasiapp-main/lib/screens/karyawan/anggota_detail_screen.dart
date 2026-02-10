import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AnggotaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> anggota;

  const AnggotaDetailScreen({super.key, required this.anggota});

  @override
  _AnggotaDetailScreenState createState() => _AnggotaDetailScreenState();
}

class _AnggotaDetailScreenState extends State<AnggotaDetailScreen> {
  // Final usage of these variables will come when we add financial history
  // For now, removing them to clear lints.

  @override
  Widget build(BuildContext context) {
    final anggota = widget.anggota;
    final apiService = ApiService();
    String ktpUrl = anggota['ktp_path'] ?? '';
    if (ktpUrl.isNotEmpty && !ktpUrl.startsWith('http')) {
      ktpUrl = "${apiService.storageUrl}/$ktpUrl";
    }

    String fotoProfileUrl = anggota['foto_profile_path'] ?? '';
    if (fotoProfileUrl.isNotEmpty && !fotoProfileUrl.startsWith('http')) {
      fotoProfileUrl = "${apiService.storageUrl}/$fotoProfileUrl";
    }

    return Scaffold(
      appBar: AppBar(title: Text('Detail Anggota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(anggota, ktpUrl, fotoProfileUrl),
            SizedBox(height: 16),
            _buildInfoCard('Informasi Pribadi', [
              _buildInfoRow(
                'TTL',
                '${anggota['tempat_lahir']}, ${anggota['tanggal_lahir']}',
              ),
              _buildInfoRow('Jenis Kelamin', anggota['jenis_kelamin']),
              _buildInfoRow('Agama', anggota['agama']),
              _buildInfoRow('Status Pernikahan', anggota['status_pernikahan']),
              _buildInfoRow('Pendidikan', anggota['pendidikan']),
              _buildInfoRow('Pekerjaan', anggota['pekerjaan']),
              _buildInfoRow('Nama Ibu Kandung', anggota['nama_ibu_kandung']),
            ]),
            SizedBox(height: 16),
            _buildInfoCard('Kontak & Alamat', [
              _buildInfoRow('Email', anggota['user']?['email'] ?? '-'),
              _buildInfoRow('No. Telepon', anggota['no_telepon']),
              _buildInfoRow('Alamat', anggota['domisili']),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    Map<String, dynamic> anggota,
    String ktpUrl,
    String fotoProfileUrl,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: fotoProfileUrl.isNotEmpty
                  ? NetworkImage(fotoProfileUrl)
                  : null,
              child: fotoProfileUrl.isEmpty
                  ? Text(
                      anggota['nama_lengkap'][0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 12),
            Text(
              anggota['nama_lengkap'],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'No Anggota: ${anggota['nomor_anggota'] ?? '-'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            _buildStatusBadge(anggota['is_ktp_verified'] == 1),
            SizedBox(height: 12),
            if (ktpUrl.isNotEmpty)
              OutlinedButton.icon(
                icon: Icon(Icons.image),
                label: Text('Lihat KTP'),
                onPressed: () => _showKtpDialog(context, ktpUrl),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isVerified) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.hourglass_top,
            size: 16,
            color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
          ),
          SizedBox(width: 8),
          Text(
            isVerified ? 'Terverifikasi' : 'Belum Diverifikasi',
            style: TextStyle(
              color: isVerified
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(fontWeight: FontWeight.w500),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Foto KTP'),
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : Container(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  child: Center(child: Text('Gagal memuat gambar')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
