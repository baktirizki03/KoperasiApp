import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;
    int percentage = (progress * 100).toInt();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LANGKAH $currentStep DARI $totalSteps',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(255, 249, 249, 249).withOpacity(0.5),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStepName(currentStep),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 8, 47, 104).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 8,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _getStepName(int step) {
    switch (step) {
      case 1: return 'Data Akun';
      case 2: return 'Informasi Pribadi';
      case 3: return 'Data Tambahan';
      case 4: return 'Verifikasi KTP';
      default: return 'Pendaftaran';
    }
  }
}

class SecurityChecklist extends StatelessWidget {
  final String password;

  const SecurityChecklist({super.key, required this.password});

  bool get hasMinLength => password.length >= 8;
  bool get hasUpperLower =>
      password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));
  bool get hasDigits => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecial => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF), // Harmonious light blue
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: const Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              Text(
                'KEAMANAN AKUN',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D47A1),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckItem('Min. 8 Karakter', hasMinLength),
          const SizedBox(height: 10),
          _buildCheckItem('Huruf Besar & Kecil', hasUpperLower),
          const SizedBox(height: 10),
          _buildCheckItem('Gunakan Angka', hasDigits),
          const SizedBox(height: 10),
          _buildCheckItem('Simbol Khusus (!@#)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isMet) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isMet ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            color: isMet ? const Color(0xFF1B5E20) : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const InfoBox({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? const Color(0xFF0D47A1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.05), // More faded
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColor.withOpacity(0.1), // More subtle
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: themeColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF212121),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoGuide extends StatelessWidget {
  const PhotoGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              Text(
                'Panduan Foto',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuideItem('Pastikan seluruh bagian KTP terlihat jelas'),
          _buildGuideItem('Pencahayaan cukup dan tidak ada pantulan cahaya'),
          _buildGuideItem('Tulisan pada KTP harus terbaca (tidak blur)'),
          _buildGuideItem('Gunakan KTP asli, bukan fotokopi'),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
