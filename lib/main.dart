import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/simple_splash_screen.dart';
import 'screens/assessment_home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional - for future Supabase sync)
  String supabaseUrl = 'https://uikkanfplfjglehpfrwu.supabase.co';
  String supabaseAnonKey = 'sb_publishable_FxSBCHvosWWrQBdqCmW7Mg_s9iG0DCN';
  
  try {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
  } catch (e) {
    debugPrint('⚠️ .env file not found, using defaults');
  }
  
  // Initialize Supabase (for future sync - currently using local storage)
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized (for future sync)');
  } catch (e) {
    debugPrint('⚠️ Supabase init skipped - using local storage only');
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
      title: 'Mental Capacity Assessment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SimpleSplashScreen(),
      routes: {
        '/home': (context) => const AssessmentHomeScreen(),
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