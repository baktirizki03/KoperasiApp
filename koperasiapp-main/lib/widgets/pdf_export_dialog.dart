import 'package:flutter/material.dart';

class PdfExportDialog extends StatefulWidget {
  final String title;

  const PdfExportDialog({super.key, required this.title});

  @override
  State<PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<PdfExportDialog> {
  int? selectedBulan;
  int? selectedTahun;

  final List<String> namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<int> listTahun = [2024, 2025, 2026, 2027, 2028, 2029, 2030];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cetak ${widget.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pilih periode laporan yang ingin dicetak. Kosongkan bulan dan tahun untuk mencetak semua data.'),
          const SizedBox(height: 16),
          // Tambahkan row untuk membersihkan filter
          if (selectedBulan != null || selectedTahun != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedBulan = null;
                    selectedTahun = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Reset Filter'),
              ),
            ),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Bulan (Opsional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: selectedBulan,
            items: List.generate(12, (index) {
              return DropdownMenuItem(
                value: index + 1,
                child: Text(namaBulan[index]),
              );
            }),
            onChanged: (val) {
              setState(() {
                selectedBulan = val;
                // Jika bulan dipilih tapi tahun kosong, default ke tahun ini
                if (selectedTahun == null) {
                  selectedTahun = DateTime.now().year;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Tahun (Opsional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: selectedTahun,
            items: listTahun.map((tahun) {
              return DropdownMenuItem(
                value: tahun,
                child: Text(tahun.toString()),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedTahun = val;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // return null
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop({
              'bulan': selectedBulan,
              'tahun': selectedTahun,
            });
          },
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text('Cetak PDF'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }
}
