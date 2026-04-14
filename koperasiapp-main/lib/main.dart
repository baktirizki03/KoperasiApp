import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
          debugShowCheckedModeBanner: false,
          title: 'Aplikasi Koperasi',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1), // Deep Royal Blue
              primary: const Color(0xFF0D47A1),
              secondary: const Color(0xFFFFC107), // Amber/Gold
              surface: Colors.white,
              background: const Color(0xFFF8F9FA), // Off-White
              error: const Color(0xFFB00020),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            textTheme: GoogleFonts.poppinsTextTheme().apply(
              bodyColor: const Color(0xFF424242), // Slate Grey
              displayColor: const Color(0xFF1A237E), // Dark Navy
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A237E),
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            /*
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            */
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF0D47A1).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF0D47A1),
                  width: 1.5,
                ),
              ),
              labelStyle: const TextStyle(color: Color(0xFF757575)),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
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
