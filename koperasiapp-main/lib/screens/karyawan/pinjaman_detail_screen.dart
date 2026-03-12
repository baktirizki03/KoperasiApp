import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PinjamanDetailScreen extends StatefulWidget {
  final int pinjamanId;

  const PinjamanDetailScreen({super.key, required this.pinjamanId});

  @override
  State<PinjamanDetailScreen> createState() => _PinjamanDetailScreenState();
}

class _PinjamanDetailScreenState extends State<PinjamanDetailScreen> {
  final ApiService _apiService = ApiService();
  final _alasanController = TextEditingController();
  late Future<Map<String, dynamic>> _pinjamanDetailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _pinjamanDetailFuture = _apiService.getPinjamanDetail(widget.pinjamanId);
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _approvePinjaman() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan'),
        content: const Text(
          'Apakah Anda yakin ingin menyetujui pengajuan pinjaman ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog();
    try {
      await _apiService.approvePinjaman(widget.pinjamanId);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pinjaman berhasil disetujui'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectPinjaman() async {
    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: _alasanController,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan penolakan',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_alasanController.text.isNotEmpty) {
                Navigator.of(ctx).pop(_alasanController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak Pinjaman'),
          ),
        ],
      ),
    );

    if (alasan != null && alasan.isNotEmpty) {
      _showLoadingDialog();
      try {
        await _apiService.rejectPinjaman(widget.pinjamanId, alasan);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pinjaman berhasil ditolak'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _requestRevision() async {
    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minta Perbaikan'),
        content: TextField(
          controller: _alasanController,
          decoration: const InputDecoration(
            hintText: 'Jelaskan apa yang perlu diperbaiki...',
            labelText: 'Catatan Perbaikan',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_alasanController.text.isNotEmpty) {
                Navigator.of(ctx).pop(_alasanController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );

    if (alasan != null && alasan.isNotEmpty) {
      _showLoadingDialog();
      try {
        await _apiService.requestRevision(widget.pinjamanId, alasan);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan perbaikan berhasil dikirim'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmPayAngsuran(int angsuranId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text(
          'Apakah Anda yakin ingin mengonfirmasi pembayaran untuk angsuran ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _showLoadingDialog();
      try {
        await _apiService.payAngsuran(angsuranId);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil dicatat'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDetail();
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showImage(String path, String title) {
    // Gunakan storageUrl dari ApiService
    final imageUrl = '${_apiService.storageUrl}/$path';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        Text('Gagal memuat gambar'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pinjamanDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          final pinjaman = snapshot.data!;
          final anggota = pinjaman['anggota'];
          final angsurans = pinjaman['angsurans'] as List;
          final bool isPending = pinjaman['status'] == 'pending';
          final bool isApproved =
              pinjaman['status'] == 'disetujui' ||
              pinjaman['status'] == 'lunas';

          final isKetua =
              Provider.of<AuthProvider>(context, listen: false).role == 'ketua';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pemohon:', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  anggota['nama_lengkap'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(anggota['user']['email']),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Pribadi Anggota',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        _buildDetailRow('No. KTP', anggota['nomor_ktp'] ?? '-'),
                        _buildDetailRow(
                          'No. Telepon',
                          anggota['no_telepon'] ?? '-',
                        ),
                        _buildDetailRow(
                          'TTL',
                          '${anggota['tempat_lahir'] ?? '-'}, ${anggota['tanggal_lahir'] ?? '-'}',
                        ),
                        _buildDetailRow(
                          'Jenis Kelamin',
                          anggota['jenis_kelamin'] ?? '-',
                        ),
                        _buildDetailRow('Agama', anggota['agama'] ?? '-'),
                        _buildDetailRow(
                          'Pendidikan',
                          anggota['pendidikan'] ?? '-',
                        ),
                        _buildDetailRow(
                          'Alamat Domisili',
                          anggota['domisili'] ?? '-',
                        ),
                        _buildDetailRow(
                          'Status Pernikahan',
                          anggota['status_pernikahan'] ?? '-',
                        ),
                        _buildDetailRow(
                          'Nama Ibu Kandung',
                          anggota['nama_ibu_kandung'] ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),

                // -------------------------------
                const Divider(height: 32),

                Text(
                  'Detail Pinjaman',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('Nominal'),
                  subtitle: Text(formatRupiah(pinjaman['nominal'])),
                ),
                ListTile(
                  leading: const Icon(Icons.timelapse),
                  title: const Text('Tenor'),
                  subtitle: Text('${pinjaman['tenor_cicilan']} bulan'),
                ),
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Pekerjaan'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dept: ${pinjaman['departemen_pekerjaan'] ?? '-'}'),
                      Text(
                        'Gaji: ${formatRupiah(pinjaman['pendapatan_per_bulan'])}',
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Bank & Rekening'),
                  subtitle: Text(
                    '${pinjaman['nama_bank'] ?? '-'} - ${pinjaman['no_rekening'] ?? '-'}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Alamat Saudara'),
                  subtitle: Text('${pinjaman['alamat_tempat_tinggal'] ?? '-'}'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Keperluan'),
                  subtitle: Text('${pinjaman['untuk_keperluan'] ?? '-'}'),
                ),
                ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: const Text('Saudara Terdekat'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pinjaman['nama_saudara_terdekat'] ?? '-'}'),
                      Text(
                        'Telp: ${pinjaman['no_telepon_saudara'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),
                const Text(
                  'Dokumen:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Showing uploaded documents
                if (pinjaman['foto_kk'] != null)
                  ListTile(
                    leading: const Icon(
                      Icons.perm_contact_calendar,
                      color: Colors.purple,
                    ),
                    title: const Text('Foto KK'),
                    trailing: const Icon(Icons.visibility),
                    onTap: () => _showImage(pinjaman['foto_kk'], 'Foto KK'),
                  ),

                if (pinjaman['foto_id_karyawan'] != null)
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blue),
                    title: const Text('Foto ID Karyawan'),
                    trailing: const Icon(Icons.visibility),
                    onTap: () => _showImage(
                      pinjaman['foto_id_karyawan'],
                      'Foto ID Karyawan',
                    ),
                  ),

                if (pinjaman['slip_gaji_path'] != null)
                  ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: Colors.orange,
                    ),
                    title: const Text('Slip Gaji'),
                    trailing: const Icon(Icons.visibility),
                    onTap: () =>
                        _showImage(pinjaman['slip_gaji_path'], 'Slip Gaji'),
                  ),

                // KTP from Anggota
                if (anggota['ktp_path'] != null)
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.green),
                    title: const Text('Foto KTP'),
                    trailing: const Icon(Icons.visibility),
                    onTap: () => _showImage(anggota['ktp_path'], 'Foto KTP'),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Status'),
                  subtitle: Text(pinjaman['status'].toUpperCase()),
                ),

                if (pinjaman['status'] == 'ditolak')
                  ListTile(
                    leading: const Icon(Icons.cancel),
                    title: const Text('Alasan Ditolak'),
                    subtitle: Text(pinjaman['alasan_penolakan']),
                  ),

                const SizedBox(height: 32),
                if (isPending && !isKetua)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _rejectPinjaman,
                              icon: const Icon(Icons.close),
                              label: const Text('Tolak'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _approvePinjaman,
                              icon: const Icon(Icons.check),
                              label: const Text('Setujui'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _requestRevision,
                          icon: const Icon(Icons.edit),
                          label: const Text('Minta Perbaikan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (isApproved && angsurans.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(
                    'Jadwal Angsuran',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: angsurans.length,
                    itemBuilder: (ctx, index) {
                      final angsuran = angsurans[index];
                      final bool sudahLunas = angsuran['status'] == 'lunas';
                      return Card(
                        color: sudahLunas ? Colors.green[50] : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                child: Text('${angsuran['angsuran_ke']}'),
                              ),
                              title: Text(
                                formatRupiah(
                                  angsuran['jumlah_angsuran'] ??
                                      angsuran['jumlah_bayar'],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(DateTime.parse(angsuran['tanggal_jatuh_tempo']))}',
                                  ),
                                  if (angsuran['status'] ==
                                      'menunggu_konfirmasi')
                                    const Text(
                                      'Menunggu Konfirmasi',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: sudahLunas
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const Text(
                                          'Lunas',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            // Action Buttons Row (Below ListTile)
                            if (!sudahLunas && !isKetua)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (angsuran['bukti_bayar_path'] != null)
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.image,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        label: const Text('Bukti'),
                                        onPressed: () => _showImage(
                                          angsuran['bukti_bayar_path'],
                                          'Bukti Pembayaran',
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _confirmPayAngsuran(angsuran['id']),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(0, 32),
                                        backgroundColor:
                                            angsuran['status'] ==
                                                'menunggu_konfirmasi'
                                            ? Colors.orange
                                            : Colors.blue,
                                      ),
                                      child: const Text('Verifikasi'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
