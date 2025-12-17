import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  bool _isLoading = false;
  String _status = 'Not tested yet';
  List<Map<String, dynamic>> _users = [];
  String? _error;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
      _error = null;
      _users = [];
    });

    try {
      // Test 1: Check if Supabase is initialized
      if (!Supabase.instance.isInitialized) {
        setState(() {
          _status = '❌ Supabase not initialized';
          _error = 'Supabase instance is not initialized';
          _isLoading = false;
        });
        return;
      }

      final client = Supabase.instance.client;
      _status = '✅ Supabase initialized\n';

      // Test 2: Try to query users table
      try {
        final response = await client
            .from('users')
            .select()
            .limit(10);

        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _status = '✅ Connection successful!\n';
          _status += 'Found ${_users.length} users in database';
          _error = null;
        });
      } catch (e) {
        setState(() {
          _status = '⚠️ Connection works but query failed';
          _error = 'Error querying users table: $e\n\n'
              'This might mean:\n'
              '1. The users table doesn\'t exist yet\n'
              '2. You need to run the SQL schema in Supabase\n'
              '3. Row Level Security (RLS) is blocking access';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Connection failed';
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _status.contains('✅')
                  ? Colors.green.shade50
                  : _status.contains('❌')
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: AppTheme.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: AppTheme.bodyMedium,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Button
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Test Supabase Connection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            if (_users.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                'Users Found (${_users.length})',
                style: AppTheme.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._users.map((user) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: AppTheme.primaryBlue),
                      title: Text(user['username'] ?? 'No username'),
                      subtitle: Text(
                        '${user['full_name'] ?? 'No name'} - ${user['role'] ?? 'No role'}',
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 30),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Setup Instructions',
                          style: AppTheme.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Go to Supabase Dashboard → SQL Editor\n'
                      '2. Copy and run the SQL from supabase_schema.sql\n'
                      '3. Verify tables are created in Table Editor\n'
                      '4. Click "Test Connection" button above',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

