import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  int _failedLoginCount = 0;
  bool _showForgotPassword = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ooops!',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.login(_email, _password);
      final token = response['access_token'];
      final role = response['user']['role'];

      setState(() {
        _failedLoginCount = 0;
        _showForgotPassword = false;
      });

      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(token, role);
    } catch (error) {
      setState(() {
        _failedLoginCount++;
        if (_failedLoginCount >= 5) {
          _showForgotPassword = true;
        }
      });
      _showErrorDialog(error.toString());
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showForgotPasswordModal() {
    final emailController = TextEditingController(text: _email);
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    int currentStep = 0; // 0: Enter Email, 1: Enter OTP & New Password
    bool isSubmitting = false;
    bool obscureNewPass = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentStep == 0 ? Icons.mark_email_unread_rounded : Icons.lock_reset_rounded,
                        color: const Color(0xFF0D47A1),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentStep == 0 ? 'Lupa Kata Sandi' : 'Reset Kata Sandi',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentStep == 0
                          ? 'Masukkan email akun Anda untuk menerima Kode OTP Reset Kata Sandi.'
                          : 'Masukkan Kode OTP 6 Digit yang dikirimkan ke email Anda & kata sandi baru.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    if (currentStep == 0) ...[
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Email Anda',
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0D47A1)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8, color: const Color(0xFF0D47A1)),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[300], letterSpacing: 8),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPassController,
                        obscureText: obscureNewPass,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Password Baru (min 8 karakter)',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D47A1)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNewPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF0D47A1)),
                            onPressed: () => setModalState(() => obscureNewPass = !obscureNewPass),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPassController,
                        obscureText: obscureNewPass,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Konfirmasi Password Baru',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D47A1)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (currentStep == 0) {
                                      final targetEmail = emailController.text.trim();
                                      if (targetEmail.isEmpty || !targetEmail.contains('@')) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan email yang valid')));
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);
                                      try {
                                        final res = await _apiService.sendForgotPasswordOtp(targetEmail);
                                        setModalState(() {
                                          isSubmitting = false;
                                          currentStep = 1;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(res['message'] ?? 'Kode OTP dikirim ke email'), backgroundColor: Colors.green),
                                        );
                                      } catch (e) {
                                        setModalState(() => isSubmitting = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    } else {
                                      final otp = otpController.text.trim();
                                      final newPass = newPassController.text.trim();
                                      final confirmPass = confirmPassController.text.trim();

                                      if (otp.length != 6) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode OTP harus 6 digit')));
                                        return;
                                      }
                                      if (newPass.length < 8) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 8 karakter')));
                                        return;
                                      }
                                      if (newPass != confirmPass) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok')));
                                        return;
                                      }

                                      setModalState(() => isSubmitting = true);
                                      try {
                                        final res = await _apiService.resetPasswordWithOtp(
                                          emailController.text.trim(),
                                          otp,
                                          newPass,
                                          confirmPass,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _failedLoginCount = 0;
                                          _showForgotPassword = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(res['message'] ?? 'Password berhasil direset!'), backgroundColor: Colors.green),
                                        );
                                      } catch (e) {
                                        setModalState(() => isSubmitting = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(currentStep == 0 ? 'Kirim OTP' : 'Reset Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Premium Design: Clean, centered, ample whitespace.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Logo Section
              Center(
                child: Container(
                  width: 120, // Slightly larger
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05), // Softer shadow
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    // Padding inside logo if needed, otherwise fit cover
                    child: Padding(
                      padding: const EdgeInsets.all(
                        12.0,
                      ), // Give logo room to breathe if it's an icon
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback Icon if asset missing
                          return Icon(
                            Icons.account_balance_wallet,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 40),

              // Welcome Text
              Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E), // Dark Navy
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                'Aplikasi Koperasi Digital',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF757575), // Cool Grey
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 48),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    CustomTextField(
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.email_outlined, // Outlined looks cleaner
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'Masukkan email yang valid.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _email = value!;
                          },
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideX(begin: -0.1, end: 0),

                     CustomTextField(
                          label: 'Password',
                          obscureText: _obscurePassword,
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF1A237E),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 5) {
                              return 'Password minimal 5 karakter.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _password = value!;
                          },
                        )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideX(begin: 0.1, end: 0),

                    if (_showForgotPassword) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _showForgotPasswordModal,
                          icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFD84315)),
                          label: Text(
                            'Lupa Kata Sandi?',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFD84315),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56, // Taller button
                      child: CustomButton(
                        text: 'MASUK',
                        onPressed: _submit,
                        isLoading: _isLoading,
                        icon: Icons.login,
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum punya akun? ',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF757575),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Daftar Sekarang',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
