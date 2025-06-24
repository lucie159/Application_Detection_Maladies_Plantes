import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_guard/pages/home_page.dart';
import 'package:plant_guard/pages/camera_page.dart';
import 'package:plant_guard/pages/diagnostic_page.dart';
import 'package:plant_guard/pages/history_page.dart';
import 'package:plant_guard/pages/language_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await EasyLocalization.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = true;

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('fr')],
        path: 'assets/language',
        fallbackLocale: const Locale('fr'),
        child: const PlantGuardApp(),
      ),
    );
  } catch (e, stack) {
    // Simple log d'erreur pour éviter tout problème de typage
    debugPrint("Initialization error: $e\n$stack");

    // Application minimale d'erreur sans dépendances
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erreur initialisation: $e'),
          ),
        ),
      ),
    );
  }
}

class PlantGuardApp extends StatelessWidget {
  const PlantGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,

      // Désactiver temporairement la gestion avancée des erreurs
      builder: (context, child) => child!,

      // Navigation simplifiée sans cast de type
      routes: {
        '/': (context) => const HomePage(),
        '/camera': (context) => const CameraPage(),
        '/language': (context) => const LanguagePage(),
        '/history': (context) => const HistoryPage(),
      },

      // Gestion de DiagnosticPage sans argument de route
      onGenerateRoute: (settings) {
        if (settings.name == '/diagnostic') {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Utilisez Navigator.push() directement')),
            ),
          );
        }
        return null;
      },
    );
  }
}