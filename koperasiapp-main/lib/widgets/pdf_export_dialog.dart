import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Ekspor Laporan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                Text(
                  'Pilih periode ${widget.title.toLowerCase()} yang ingin Anda ekspor ke format PDF.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Dropdown Section
                _buildDropdownField(
                  label: 'Pilih Bulan',
                  hint: 'Semua Bulan',
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
                      if (selectedTahun == null) {
                        selectedTahun = DateTime.now().year;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Pilih Tahun',
                  hint: 'Semua Tahun',
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

                const SizedBox(height: 8),
                // Reset Button
                if (selectedBulan != null || selectedTahun != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedBulan = null;
                        selectedTahun = null;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.red),
                    label: Text(
                      'Reset Filter',
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ).animate().fadeIn(),

                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'bulan': selectedBulan,
                            'tahun': selectedTahun,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cetak PDF',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              hint: Text(hint, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D47A1)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
