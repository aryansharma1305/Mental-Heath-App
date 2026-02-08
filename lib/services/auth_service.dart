import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import 'supabase_service.dart';
import 'database_service.dart';

// Helper for secure storage with macOS fallback
class _SecureStorageHelper {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static bool _useFallback = false;
  
  static Future<void> write({required String key, required String value}) async {
    if (_useFallback || Platform.isMacOS) {
      // Use SharedPreferences on macOS as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('_secure_$key', value);
      } catch (e) {
        debugPrint('SharedPreferences fallback write error: $e');
      }
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage error: $e, falling back to SharedPreferences');
      _useFallback = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('_secure_$key', value);
    }
  }
  
  static Future<String?> read({required String key}) async {
    if (_useFallback || Platform.isMacOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('_secure_$key');
      } catch (e) {
        return null;
      }
    }
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage error: $e, falling back to SharedPreferences');
      _useFallback = true;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('_secure_$key');
    }
  }
  
  static Future<void> delete({required String key}) async {
    if (_useFallback || Platform.isMacOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('_secure_$key');
      } catch (e) {
        // Ignore
      }
      return;
    }
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      _useFallback = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('_secure_$key');
    }
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  final SupabaseService _supabaseService = SupabaseService();
  
  String? _currentToken;
  Map<String, dynamic>? _currentUser;
  app_models.User? _currentUserModel;
  final DatabaseService _databaseService = DatabaseService();

  // Get current token
  String? get currentToken => _currentToken;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _SecureStorageHelper.read(key: 'auth_token');
      if (token == null) return false;

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        await logout();
        return false;
      }

      _currentToken = token;
      _decodeUserFromToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Login with email/username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // Try Supabase first
    try {
      final hashedPassword = _hashPassword(password);
      
      // Get user from Supabase
      final user = await _supabaseService.getUserByUsername(username);
      
      if (user != null) {
        // Verify password - check local database for password hash
        final storedHash = await _databaseService.getPasswordHash(username);
        if (storedHash == hashedPassword || storedHash == null) {
          // Password matches or no hash stored (first login)
          // Generate token
          final token = _generateLocalToken(username);
          await _SecureStorageHelper.write(key: 'auth_token', value: token);
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', user.username);
          await prefs.setString('full_name', user.fullName);
          await prefs.setString('role', user.role.name);
          await prefs.setString('department', user.department ?? '');
          await prefs.setString('user_id', user.id);
          
          _currentToken = token;
          _currentUser = {
            'username': user.username,
            'full_name': user.fullName,
            'role': user.role.name,
            'department': user.department,
            'id': user.id,
          };
          _currentUserModel = user;
          
          return {
            'success': true,
            'message': 'Login successful',
            'user': _currentUser,
          };
        }
      }
    } catch (e) {
      // Supabase failed, try local
    }

    // Fallback to local authentication (offline mode)
    return await _localLogin(username: username, password: password);
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? department,
  }) async {
    // Validate password strength
    final passwordValidation = _validatePassword(password);
    if (!passwordValidation['valid']) {
      return {
        'success': false,
        'message': passwordValidation['message'],
      };
    }

    // Hash password
    final hashedPassword = _hashPassword(password);

    // Parse role
    UserRole userRole;
    try {
      userRole = UserRole.values.firstWhere((r) => r.name == role.toLowerCase());
    } catch (e) {
      userRole = UserRole.patient; // Default to patient
    }

    // Try Supabase first (only if available)
    if (SupabaseService.isAvailable) {
      try {
        // Check if user already exists in Supabase
        final existingUser = await _supabaseService.getUserByUsername(username);
        if (existingUser != null) {
          return {
            'success': false,
            'message': 'Username already exists',
          };
        }

        // Create user in Supabase
        final user = await _supabaseService.createUser(
          username: username,
          email: email,
          fullName: fullName,
          role: userRole,
          department: department,
          passwordHash: hashedPassword,
        );

        // Also save to local database for offline access
        await _databaseService.insertUser(user);
        await _databaseService.savePasswordHash(username, hashedPassword);

        // Generate token
        final token = _generateLocalToken(username);
        await _SecureStorageHelper.write(key: 'auth_token', value: token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.username);
        await prefs.setString('email', email);
        await prefs.setString('password_hash', hashedPassword);
        await prefs.setString('full_name', user.fullName);
        await prefs.setString('role', user.role.name);
        await prefs.setString('department', user.department ?? '');
        await prefs.setString('user_id', user.id);

        _currentToken = token;
        _currentUserModel = user;
        _currentUser = {
          'username': user.username,
          'full_name': user.fullName,
          'role': user.role.name,
          'department': user.department,
          'id': user.id,
        };

        return {
          'success': true,
          'message': 'Registration successful',
          'user': _currentUser,
        };
      } catch (e) {
        // Supabase failed, log error and fall back to local registration
        debugPrint('⚠️ Supabase registration failed: $e');
        debugPrint('Falling back to local registration');
      }
    }

    // Fallback to local registration (offline mode)
    return await _localRegister(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      department: department ?? '',
    );
  }

  // Local login fallback (for offline mode)
  Future<Map<String, dynamic>> _localLogin({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('username');
    final storedPassword = prefs.getString('password_hash');

    if (storedUsername == username && storedPassword == _hashPassword(password)) {
      // Generate a simple token for local use
      final token = _generateLocalToken(username);
      await _SecureStorageHelper.write(key: 'auth_token', value: token);
      _currentToken = token;
      _currentUser = {
        'username': username,
        'full_name': prefs.getString('full_name') ?? '',
        'role': prefs.getString('role') ?? '',
        'department': prefs.getString('department') ?? '',
      };

      return {
        'success': true,
        'message': 'Login successful (offline mode)',
        'user': _currentUser,
      };
    }

    return {
      'success': false,
      'message': 'Invalid credentials',
    };
  }

  // Local register fallback
  Future<Map<String, dynamic>> _localRegister({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String department,
  }) async {
    // Check if username already exists in database
    final existingUser = await _databaseService.getUserByUsername(username);
    if (existingUser != null) {
      return {
        'success': false,
        'message': 'Username already exists',
      };
    }

    // Parse role
    UserRole userRole;
    try {
      userRole = UserRole.values.firstWhere((r) => r.name == role.toLowerCase());
    } catch (e) {
      userRole = UserRole.patient; // Default to patient
    }

    // Create user model
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final user = app_models.User(
      id: userId,
      username: username,
      email: email,
      fullName: fullName,
      role: userRole,
      department: department.isNotEmpty ? department : null,
      createdAt: DateTime.now(),
    );

    // Save to database
    await _databaseService.insertUser(user);

    // Store in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    await prefs.setString('password_hash', _hashPassword(password));
    await prefs.setString('full_name', fullName);
    await prefs.setString('role', role);
    await prefs.setString('department', department);
    await prefs.setString('user_id', userId);

    // Generate token
    final token = _generateLocalToken(username);
    await _SecureStorageHelper.write(key: 'auth_token', value: token);
    _currentToken = token;
    _currentUserModel = user;
    _currentUser = {
      'username': username,
      'full_name': fullName,
      'role': role,
      'department': department,
      'id': userId,
    };

    return {
      'success': true,
      'message': 'Registration successful (offline mode)',
      'user': _currentUser,
    };
  }

  // Logout
  Future<void> logout() async {
    try {
      await _SecureStorageHelper.delete(key: 'auth_token');
      await _SecureStorageHelper.delete(key: 'refresh_token');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('password_hash');
      
      _currentToken = null;
      _currentUser = null;
    } catch (e) {
      // Handle error
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _SecureStorageHelper.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      // For now, just regenerate token if not expired
      final token = await _SecureStorageHelper.read(key: 'auth_token');
      if (token != null && !JwtDecoder.isExpired(token)) {
        return true;
      }
      
      // Token expired, need to re-login
      return false;
    } catch (e) {
      return false;
    }
  }

  // Validate password strength
  Map<String, dynamic> _validatePassword(String password) {
    if (password.length < 8) {
      return {
        'valid': false,
        'message': 'Password must be at least 8 characters long',
      };
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one uppercase letter',
      };
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one lowercase letter',
      };
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one number',
      };
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return {
        'valid': false,
        'message': 'Password must contain at least one special character',
      };
    }

    return {'valid': true, 'message': 'Password is valid'};
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate local token (simple implementation)
  String _generateLocalToken(String username) {
    final payload = {
      'username': username,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  // Decode user from token
  void _decodeUserFromToken(String token) {
    try {
      if (JwtDecoder.isExpired(token)) {
        _currentUser = null;
        return;
      }

      final decodedToken = JwtDecoder.decode(token);
      _currentUser = Map<String, dynamic>.from(decodedToken);
    } catch (e) {
      _currentUser = null;
    }
  }

  // Get stored user info
  Future<Map<String, dynamic>?> getStoredUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return null;

    return {
      'username': username,
      'full_name': prefs.getString('full_name') ?? '',
      'role': prefs.getString('role') ?? '',
      'department': prefs.getString('department') ?? '',
    };
  }

  // Get current user model
  Future<app_models.User?> getCurrentUserModel() async {
    if (_currentUserModel != null) return _currentUserModel;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return null;

    _currentUserModel = await _databaseService.getUserById(userId);
    return _currentUserModel;
  }

  // Get user role
  Future<UserRole> getCurrentUserRole() async {
    final user = await getCurrentUserModel();
    return user?.role ?? UserRole.patient;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}

