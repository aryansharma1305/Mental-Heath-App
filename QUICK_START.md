# Quick Start Guide - Mental Capacity Assessment App

## ⚠️ IMPORTANT: First Time Setup

### Problem: Registration Fails
If you're getting "Registration failed" errors, it's likely because **the Supabase database tables don't exist yet**.

### Solution: Create Database Tables

#### Option 1: Using Supabase Dashboard (Recommended)

1. **Go to your Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**: `uikkanfplfjglehpfrwu`
3. **Click on "SQL Editor"** (left sidebar)
4. **Copy the entire contents** of `supabase_schema.sql` from this project
5. **Paste into SQL Editor** and click **"Run"**
6. **Verify tables were created**:
   - Go to **"Table Editor"** (left sidebar)
   - You should see 4 tables:
     - `users`
     - `questions`
     - `assessments`
     - `question_responses`

#### Option 2: Test Without Supabase (Offline Mode)

The app will automatically fall back to local SQLite if Supabase fails. However, you need to ensure the local database is working.

**To force local-only mode:**
1. Turn off WiFi/mobile data
2. Register a new user
3. The app will use SQLite locally

---

## 🧪 Testing Supabase Connection

### Using the Test Screen

1. **Open the app**
2. **On the Login screen**, click the **cloud icon** (☁️) in the top-right corner
3. **Click "Test Supabase Connection"**
4. **Check the results**:
   - ✅ **Success**: Supabase is connected and tables exist
   - ⚠️ **Warning**: Connected but tables don't exist → Run the SQL schema
   - ❌ **Error**: Connection failed → Check credentials or internet

### Reading Console Logs

When the app starts, look for these messages:

```
═══════════════════════════════════════
🔧 INITIALIZING SUPABASE
═══════════════════════════════════════
URL: https://uikkanfplfjglehpfrwu.supabase.co
Key format: New publishable key ✅
✅ SUPABASE INITIALIZED SUCCESSFULLY
   Client ready: true
═══════════════════════════════════════
```

If you see this, Supabase is initialized! If registration still fails, you need to create the tables.

---

## 🔑 Current Credentials

**Supabase URL**: `https://uikkanfplfjglehpfrwu.supabase.co`  
**Anon Key**: `sb_publishable_FxSBCHvosWWrQBdqCmW7Mg_s9iG0DCN`

These are currently hardcoded in `lib/main.dart` for testing.

---

## 📝 Registration Requirements

When registering, ensure your password meets these requirements:
- ✅ At least 8 characters
- ✅ One uppercase letter (A-Z)
- ✅ One lowercase letter (a-z)
- ✅ One number (0-9)
- ✅ One special character (!@#$%^&*(),.?":{}|<>)

**Example valid password**: `SecurePass123!`

---

## 🔍 Debugging Tips

### If registration keeps failing:

1. **Check console logs** for error messages:
   ```
   ⚠️ Supabase registration failed: [error details]
   ```

2. **Test Supabase connection** using the cloud icon

3. **Check if tables exist**:
   - Go to Supabase Dashboard → Table Editor
   - Look for the `users` table

4. **Try registering with simple data**:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `TestPass123!`
   - Full Name: `Test User`
   - Role: `Patient`

5. **Check for specific error messages**:
   - "Username already exists" → Try a different username
   - "Password must contain..." → Fix password format
   - "Registration failed" → Check console logs for details
---
## 🚀 Next Steps

After setting up the database:

1. **Register your first admin user**:
   - Role: Admin
   - Department: IT/Administration

2. **Login and test features**:
   - Patient: Answer assessment questions
   - Doctor: Review patient assessments
   - Admin: Manage questions in the database

3. **Click the cloud icon** to verify Supabase is working and see users in the database
---
## 📚 Additional Resources

- **Full Setup Guide**: See `SUPABASE_SETUP.md`
- **SQL Schema**: See `supabase_schema.sql`
- **README**: See `README.md` for full app documentation
---
## ⚡ Hot Reload
After making changes, press `r` in the terminal where `flutter run` is active to hot reload the app.

