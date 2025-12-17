# Supabase Setup Guide

## Step-by-Step Instructions

### 1. Create Tables in Supabase

1. **Go to SQL Editor** in your Supabase dashboard
   - Click on "SQL Editor" in the left sidebar
   - Or go to: `https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql/new`

2. **Run the Schema SQL**
   - Copy the contents of `supabase_schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" or press `Ctrl+Enter` (Windows) / `Cmd+Enter` (Mac)

3. **Verify Tables Created**
   - Go to "Tables" in the left sidebar
   - You should see 4 tables:
     - `users`
     - `questions`
     - `assessments`
     - `question_responses`

### 2. Get Your Supabase Connection Details

1. **Go to Project Settings**
   - Click the gear icon (⚙️) in the left sidebar
   - Select "API" or "Database"

2. **Copy These Values:**
   - **Project URL**: `https://YOUR_PROJECT_ID.supabase.co`
   - **Anon/Public Key**: (for client-side access)
   - **Service Role Key**: (for server-side access - keep secret!)
   - **Database Password**: (if you need direct database access)

3. **Database Connection String:**
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-ID].supabase.co:5432/postgres
   ```

### 3. Update Your Flutter App

#### Option A: Use Supabase Client (Recommended)

1. **Add Supabase package to `pubspec.yaml`:**
   ```yaml
   dependencies:
     supabase_flutter: ^2.0.0
   ```

2. **Initialize Supabase in `main.dart`:**
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await Supabase.initialize(
       url: 'YOUR_SUPABASE_URL',
       anonKey: 'YOUR_ANON_KEY',
     );
     
     runApp(const MentalCapacityAssessmentApp());
   }
   ```

3. **Create a Supabase service:**
   ```dart
   // lib/services/supabase_service.dart
   import 'package:supabase_flutter/supabase_flutter.dart';

   class SupabaseService {
     static final SupabaseClient client = Supabase.instance.client;
     
     // Add methods to interact with Supabase
   }
   ```

#### Option B: Use Direct PostgreSQL Connection

1. **Add PostgreSQL package:**
   ```yaml
   dependencies:
     postgres: ^3.0.0
   ```

2. **Update `.env` file:**
   ```env
   DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-ID].supabase.co:5432/postgres
   API_BASE_URL=https://[YOUR-PROJECT-ID].supabase.co
   ```

### 4. Set Up Authentication (Optional)

If you want to use Supabase Auth instead of custom auth:

1. **Go to Authentication** in Supabase dashboard
2. **Enable Email Auth** (or other providers)
3. **Update your auth service** to use Supabase Auth

### 5. Test the Connection

1. **Insert a test user:**
   ```sql
   INSERT INTO users (username, email, full_name, role)
   VALUES ('testuser', 'test@example.com', 'Test User', 'patient');
   ```

2. **Verify in Tables view** that the user was created

### 6. Security Notes

- **Row Level Security (RLS)** is enabled by default
- Adjust RLS policies based on your needs
- For development, you might want to temporarily disable RLS:
  ```sql
  ALTER TABLE users DISABLE ROW LEVEL SECURITY;
  ALTER TABLE questions DISABLE ROW LEVEL SECURITY;
  ALTER TABLE assessments DISABLE ROW LEVEL SECURITY;
  ```

### 7. Next Steps

1. **Create initial admin user** (via SQL or app registration)
2. **Add default questions** (via Admin Panel in app)
3. **Test the full flow:**
   - Register as Patient → Take Assessment
   - Register as Doctor → Review Assessment
   - Register as Admin → Manage Questions

### Troubleshooting

**Issue: Tables not showing up**
- Check SQL Editor for errors
- Verify you're in the correct project
- Refresh the Tables page

**Issue: Connection errors**
- Verify your connection string
- Check firewall settings
- Ensure database password is correct

**Issue: RLS blocking queries**
- Temporarily disable RLS for testing
- Or adjust policies to match your auth setup

### Useful Supabase Features

- **Real-time subscriptions**: Get live updates when data changes
- **Storage**: Store files (PDFs, images) if needed
- **Edge Functions**: Serverless functions for complex operations
- **Database Backups**: Automatic daily backups

### Migration from SQLite

When ready to migrate:
1. Export data from SQLite
2. Import to Supabase using SQL scripts
3. Update app to use Supabase instead of SQLite
4. Keep SQLite for offline mode, sync to Supabase when online

