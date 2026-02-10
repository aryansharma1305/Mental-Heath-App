import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mental_capacity_assessment/l10n/app_localizations.dart';
import 'screens/simple_splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/database_service.dart';
import 'services/language_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    print('🚀🚀🚀 APP STARTING - DEBUG MODE 🚀🚀🚀');
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ WidgetsFlutterBinding initialized');
  
  // Load environment variables (optional - for future Supabase sync)
  String supabaseUrl = 'https://uikkanfplfjglehpfrwu.supabase.co';
  String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVpa2thbmZwbGZqZ2xlaHBmcnd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5ODQ1NDksImV4cCI6MjA4MTU2MDU0OX0.SCtZgXvtFfla5rvadCxHi2OLbLADNduiYA-Qu3Dav1M';
  
  try {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
  } catch (e) {
    debugPrint('⚠️ .env file not found, using defaults');
  }
  
  // Initialize Supabase (for future sync - currently using local storage)
  try {
    // Validate key format before initialization
    final isValidKeyFormat = supabaseAnonKey.startsWith('eyJ');
    if (!isValidKeyFormat) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('⚠️ SUPABASE KEY FORMAT WARNING');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Current key starts with: ${supabaseAnonKey.substring(0, 15)}...');
      debugPrint('Expected format: JWT starting with "eyJ..."');
      debugPrint('');
      debugPrint('To fix this:');
      debugPrint('1. Go to https://supabase.com/dashboard');
      debugPrint('2. Select your project');
      debugPrint('3. Go to Settings → API');
      debugPrint('4. Copy the "anon" public key');
      debugPrint('5. Update SUPABASE_ANON_KEY in .env file');
      debugPrint('═══════════════════════════════════════');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    // Verify connection by checking if client is accessible
    final isConnected = Supabase.instance.isInitialized;
    if (isConnected) {
      debugPrint('✅ Supabase initialized successfully');
      debugPrint('   URL: $supabaseUrl');
      debugPrint('   Key format valid: $isValidKeyFormat');
    } else {
      debugPrint('⚠️ Supabase initialized but client not ready');
    }
  } catch (e) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('❌ SUPABASE INITIALIZATION FAILED');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Error: $e');
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
  
  // Trigger background sync
  try {
    DatabaseService().syncPendingAssessments();
  } catch (e) {
    debugPrint('Background sync initialization failed: $e');
  }

    print('🚀 runApp called');
    
    runApp(const MentalCapacityAssessmentApp());
  }, (error, stack) {
    print('❌❌❌ UNCAUGHT ERROR: $error');
    print(stack);
  });
}

class MentalCapacityAssessmentApp extends StatefulWidget {
  const MentalCapacityAssessmentApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MentalCapacityAssessmentAppState? state = context.findAncestorStateOfType<_MentalCapacityAssessmentAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MentalCapacityAssessmentApp> createState() => _MentalCapacityAssessmentAppState();
}

class _MentalCapacityAssessmentAppState extends State<MentalCapacityAssessmentApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final langService = LanguageService();
    await langService.init();
    setState(() {
      _locale = langService.currentLanguage.locale;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Capacity Assessment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ta'), // Tamil
        Locale('hi'), // Hindi
      ],
      home: const SimpleSplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
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