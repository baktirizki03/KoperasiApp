import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

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
            child: Text(
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

      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(token, role);
    } catch (error) {
      _showErrorDialog(error.toString());
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms).fadeIn(),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().scale(delay: 400.ms, duration: 600.ms).fadeIn(),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 120, // Adjusted size
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  SizedBox(height: 30),

                  Text(
                    'Selamat Datang!',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),

                  Text(
                    'Silakan login untuk melanjutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),

                  SizedBox(height: 40),

                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CustomTextField(
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_rounded,
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
                            .fadeIn(delay: 600.ms)
                            .slideX(begin: -0.2, end: 0),

                        CustomTextField(
                              label: 'Password',
                              obscureText: true,
                              icon: Icons.lock_rounded,
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
                            .fadeIn(delay: 700.ms)
                            .slideX(begin: 0.2, end: 0),

                        SizedBox(height: 30),

                        CustomButton(
                          text: 'LOGIN',
                          onPressed: _submit,
                          isLoading: _isLoading,
                          icon: Icons.login_rounded,
                        ).animate().fadeIn(delay: 800.ms).scale(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
