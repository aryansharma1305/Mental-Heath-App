import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const lockEnabledKey = 'app_lock_enabled';
  static const lockTimeoutKey = 'app_lock_timeout_seconds';
  static const defaultTimeoutSeconds = 60;

  final LocalAuthentication _localAuth;

  AppLockService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(lockEnabledKey) ?? true;
  }

  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(lockEnabledKey, enabled);
  }

  Future<int> getLockTimeoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lockTimeoutKey) ?? defaultTimeoutSeconds;
  }

  Future<void> setLockTimeoutSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lockTimeoutKey, seconds);
  }

  Future<bool> authenticate() async {
    if (!await isLockEnabled()) return true;

    final canAuthenticate =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    if (!canAuthenticate) {
      return true;
    }

    return _localAuth.authenticate(
      localizedReason: 'Unlock Mental Capacity Assessment',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}
