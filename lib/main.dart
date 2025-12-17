import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/supabase_test_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  String supabaseUrl = 'https://uikkanfplfjglehpfrwu.supabase.co';
  String supabaseAnonKey = 'sb_publishable_FxSBCHvosWWrQBdqCmW7Mg_s9iG0DCN';
  
  try {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint('⚠️ .env file not found, using hardcoded defaults');
    // Continue with default values
  }
  
  // Initialize Supabase (following official Supabase Flutter pattern)
  debugPrint('═══════════════════════════════════════');
  debugPrint('🔧 INITIALIZING SUPABASE');
  debugPrint('═══════════════════════════════════════');
  debugPrint('URL: $supabaseUrl');
  debugPrint('Key format: ${supabaseAnonKey.startsWith('sb_publishable_') ? "New publishable key ✅" : supabaseAnonKey.startsWith('eyJ') ? "Legacy JWT key ✅" : "Unknown format ⚠️"}');
  debugPrint('Key length: ${supabaseAnonKey.length} characters');
  
  try {
    // Initialize Supabase (following official Supabase Flutter pattern)
    // Wrap in try-catch to handle any initialization errors
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (initError) {
      // If initialization throws an error, catch it here
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ SUPABASE INITIALIZATION FAILED');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Initialization error: $initError');
      debugPrint('Error type: ${initError.runtimeType}');
      debugPrint('📱 App will continue with local SQLite database');
      debugPrint('═══════════════════════════════════════');
      // Continue with app - don't return, just skip Supabase
    }
    
    // Verify initialization - wait a bit for async operations
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if initialized (safely)
    try {
      final isInitialized = Supabase.instance.isInitialized;
      if (isInitialized) {
        try {
          final client = Supabase.instance.client;
          debugPrint('✅ SUPABASE INITIALIZED SUCCESSFULLY');
          debugPrint('   Client ready: ${client != null}');
          debugPrint('═══════════════════════════════════════');
        } catch (clientError) {
          debugPrint('⚠️ Client access error: $clientError');
          debugPrint('═══════════════════════════════════════');
        }
      } else {
        debugPrint('⚠️ Supabase initialization completed but not marked as initialized');
        debugPrint('═══════════════════════════════════════');
      }
    } catch (checkError) {
      debugPrint('⚠️ Error checking initialization status: $checkError');
      debugPrint('═══════════════════════════════════════');
    }
  } catch (e) {
    // Catch any other unexpected errors
    debugPrint('═══════════════════════════════════════');
    debugPrint('❌ UNEXPECTED ERROR DURING SUPABASE SETUP');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Error: $e');
    debugPrint('Error type: ${e.runtimeType}');
    debugPrint('📱 App will continue with local SQLite database');
    debugPrint('═══════════════════════════════════════');
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MentalCapacityAssessmentApp());
}

class MentalCapacityAssessmentApp extends StatelessWidget {
  const MentalCapacityAssessmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindCare - Mental Capacity Assessment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/supabase_test': (context) => const SupabaseTestScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}