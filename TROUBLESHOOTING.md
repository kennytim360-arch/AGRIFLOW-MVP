# Troubleshooting: "Nothing happens when adding a group"

## Most Common Causes:

### 1. ❌ SQL Tables Not Created
**Check:**
1. Go to Supabase Dashboard → **Table Editor** (left sidebar)
2. Do you see these tables?
   - `cattle_groups`
   - `price_pulses`

**If NO:**
- You need to run the SQL script from `SUPABASE_SETUP.md`
- Go to SQL Editor → New Query → Paste the entire SQL script → Run

---

### 2. ❌ Row Level Security (RLS) Policies Missing
**Check:**
1. In Supabase, go to **Authentication** → **Policies**
2. Click on `cattle_groups` table
3. You should see 3 policies:
   - "Users can see their own groups"
   - "Users can insert their own groups"  
   - "Users can delete their own groups"

**If NO:**
- The SQL script creates these automatically
- Re-run the SQL script from `SUPABASE_SETUP.md`

---

### 3. ❌ Anonymous Auth Not Working
**Check the Flutter Console:**
Look for error messages like:
- "Error adding group: ..."
- "Permission denied"
- "JWT expired"

**To see console:**
- The terminal where you ran `flutter run -d windows`
- Look for red error text

---

### 4. ❌ User Not Signed In
**Check:**
1. In the Flutter console, look for:
   - ✅ "Sign in successful: [some-uuid]"
   - ❌ "Error signing in: ..."

**If you see an error:**
- Anonymous auth might not be enabled
- Go to Supabase → Authentication → Providers → Anonymous Sign-ins → Toggle ON

---

## Quick Diagnostic Steps:

### Step 1: Verify Tables Exist
```
Supabase Dashboard → Table Editor → Look for cattle_groups table
```

### Step 2: Try Manual Insert
1. In Supabase Table Editor, click `cattle_groups`
2. Click **"Insert row"**
3. Fill in:
   - `user_id`: Click "Generate UUID" or use any UUID
   - `breed`: "charolais"
   - `quantity`: 10
   - `weight_bucket`: "w600_700"
   - `county`: "Cork"
   - `desired_price_per_kg`: 4.2
4. Click **Save**

**If this works:** The table exists, but the app has an auth/permission issue
**If this fails:** The table structure is wrong

### Step 3: Check Flutter Console
In the terminal where the app is running, look for:
```
Error adding group: [error message here]
```

Copy the EXACT error message and share it with me.

---

## Most Likely Issue:

**You probably need to run the SQL script!**

Here's the quick fix:

1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy the ENTIRE SQL from `SUPABASE_SETUP.md` (lines 17-60)
6. Paste into SQL Editor
7. Click **Run** (or Ctrl+Enter)
8. You should see: "Success. No rows returned"

Then try adding a group again in the app!

---

## What to Share With Me:

Please check and tell me:
1. ✅ or ❌ Do you see `cattle_groups` table in Supabase Table Editor?
2. ✅ or ❌ Did you run the SQL script?
3. Copy any error messages from the Flutter console (the terminal)

This will help me pinpoint the exact issue! 🔍
