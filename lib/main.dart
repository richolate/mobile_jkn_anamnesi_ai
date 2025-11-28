import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';
import 'screens/soulmed_screen.dart';
import 'screens/konsultasi_anamnesis_screen.dart';
import 'screens/analisis_gambar_export.dart';
import 'utils/app_theme.dart';
import 'services/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await ApiConfig.initialize();

  // Validate configuration
  if (!ApiConfig.isConfigured) {
    print('⚠️ WARNING: ${ApiConfig.configStatus}');
  } else {
    print('✅ ${ApiConfig.configStatus}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile JKN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryBlue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryBlue,
          primary: AppTheme.primaryBlue,
        ),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
      routes: {
        '/soulmed': (context) => const SoulMedScreen(),
        '/konsultasi-anamnesis': (context) => const KonsultasiAnamnesisScreen(),
        '/analisis-gambar-medis': (context) =>
            const AnalisisGambarMedisScreen(),
      },
    );
  }
}
