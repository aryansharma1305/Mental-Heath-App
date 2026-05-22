import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mental_capacity_assessment/l10n/app_localizations.dart';
import 'screens/simple_splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_lock_service.dart';
import 'services/database_service.dart';
import 'services/language_service.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      debugPrint('APP STARTING');
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('WidgetsFlutterBinding initialized');

      // Initialise reminder service early so plugin registers before any screen.
      try {
        await ReminderService.instance.init();
      } catch (e) {
        debugPrint('⚠️ ReminderService init failed: $e');
      }

      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('⚠️ .env file not found, using defaults');
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

      // Initialize language service before app starts to prevent locale flashes
      await LanguageService().init();

      debugPrint('runApp called');

      runApp(const MentalCapacityAssessmentApp());
    },
    (error, stack) {
      debugPrint('UNCAUGHT ERROR: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MentalCapacityAssessmentApp extends StatefulWidget {
  const MentalCapacityAssessmentApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MentalCapacityAssessmentAppState? state = context
        .findAncestorStateOfType<_MentalCapacityAssessmentAppState>();
    state?.setLocale(newLocale);
  }

  static void lockNow(BuildContext context) {
    final state = context
        .findAncestorStateOfType<_MentalCapacityAssessmentAppState>();
    state?.lockNow();
  }

  @override
  State<MentalCapacityAssessmentApp> createState() =>
      _MentalCapacityAssessmentAppState();
}

class _MentalCapacityAssessmentAppState
    extends State<MentalCapacityAssessmentApp>
    with WidgetsBindingObserver {
  Locale? _locale = LanguageService().currentLanguage.locale;
  final AppLockService _appLockService = AppLockService();
  DateTime? _backgroundedAt;
  bool _locked = true;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlockIfRequired());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      _lockAfterResumeTimeout();
    }
  }

  Future<void> _lockAfterResumeTimeout() async {
    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt == null) return;
    final timeout = await _appLockService.getLockTimeoutSeconds();
    if (timeout < 0) return;
    final elapsed = DateTime.now().difference(backgroundedAt);
    if (elapsed.inSeconds >= timeout) {
      await lockNow();
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<void> lockNow() async {
    if (!mounted) return;
    setState(() => _locked = true);
    await _unlockIfRequired();
  }

  Future<void> _unlockIfRequired() async {
    if (_authenticating || !mounted) return;
    final enabled = await _appLockService.isLockEnabled();
    if (!enabled) {
      if (mounted) setState(() => _locked = false);
      return;
    }

    setState(() => _authenticating = true);
    final unlocked = await _appLockService.authenticate();
    if (!mounted) return;
    setState(() {
      _locked = !unlocked;
      _authenticating = false;
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
      home: _locked
          ? _LockScreen(
              authenticating: _authenticating,
              onUnlock: () => _unlockIfRequired(),
            )
          : const SimpleSplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
          ),
          child: child!,
        );
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool authenticating;
  final Future<void> Function() onUnlock;

  const _LockScreen({required this.authenticating, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mental Capacity Assessment is locked',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Authenticate to access clinical records.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: authenticating ? null : onUnlock,
                icon: authenticating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(authenticating ? 'Authenticating...' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
