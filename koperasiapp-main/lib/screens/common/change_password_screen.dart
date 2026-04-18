import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../widgets/register_widgets.dart';
import '../../widgets/custom_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Real-time validation states
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasDigits => _newPasswordController.text.contains(RegExp(r'[0-9]'));

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_hasMinLength || !_hasDigits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru belum memenuhi kriteria keamanan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _apiService.updatePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
          _confirmPasswordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil diubah!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengubah password: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: Stack(
        children: [
          // --- HEADER GRADIENT ---
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM APP BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keamanan Akun',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const InfoBox(
                            text: 'Ganti password Anda secara berkala untuk menjaga keamanan akun koperasi Anda.',
                            icon: Icons.security,
                            color: Color.fromARGB(255, 10, 45, 203), // Faded color
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 24),
                          
                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D47A1).withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Password Saat Ini'),
                                _buildPasswordField(
                                  controller: _currentPasswordController,
                                  hint: 'Masukkan password lama',
                                  obscure: _obscureCurrent,
                                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                  validator: (value) => value!.isEmpty ? 'Password lama wajib diisi' : null,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Divider(height: 1),
                                ),
                                _buildSectionTitle('Password Baru'),
                                _buildPasswordField(
                                  controller: _newPasswordController,
                                  hint: 'Buat password baru yang kuat',
                                  obscure: _obscureNew,
                                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Password baru wajib diisi';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildCriteriaBox(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Divider(height: 1),
                                ),
                                _buildSectionTitle('Konfirmasi Password'),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  hint: 'Ulangi password baru',
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  validator: (value) {
                                    if (value != _newPasswordController.text) {
                                      return 'Konfirmasi password tidak cocok';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 40),
                          
                          CustomButton(
                            text: 'Simpan Perubahan',
                            onPressed: _submit,
                            isLoading: _isLoading,
                            icon: Icons.check_circle_outline,
                          ).animate().fadeIn(delay: 400.ms),
                          
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batalkan',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey[600],
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildCriteriaBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildCriteriaItem('Minimal 8 karakter', _hasMinLength),
          const SizedBox(height: 8),
          _buildCriteriaItem('Mengandung setidaknya 1 angka', _hasDigits),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String label, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.verified_user : Icons.verified_user_outlined,
          size: 16,
          color: isMet ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isMet ? Colors.black87 : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
