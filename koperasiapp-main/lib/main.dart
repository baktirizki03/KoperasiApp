import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/karyawan/karyawan_dashboard.dart';
import 'screens/ketua/ketua_dashboard.dart';
import 'screens/nasabah/nasabah_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Aplikasi Koperasi',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0), // Official Blue
              primary: const Color(0xFF1565C0),
              secondary: const Color(0xFF2E7D32), // Coop Green
              surface: Colors.white,
              background: const Color(
                0xFFF5F7FA,
              ), // Slightly more neutral background
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1565C0), // Blue AppBar
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Green Buttons
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          home: auth.isLoggedIn
              ? _getDashboard(auth.role)
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, snapshot) =>
                      snapshot.connectionState == ConnectionState.waiting
                      ? SplashScreen()
                      : LoginScreen(),
                ),
        ),
      ),
    );
  }

  Widget _getDashboard(String? role) {
    switch (role) {
      case 'nasabah':
        return NasabahDashboard();
      case 'karyawan':
        return KaryawanDashboard();
      case 'ketua':
        return KetuaDashboard();
      default:
        return LoginScreen();
    }
  }
}
