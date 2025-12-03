# AgriFlow MVP - Production Deployment Guide

## 🚨 CRITICAL: Deploy Firestore Rules First

**The app will NOT work without deploying the updated Firestore security rules.**

### Step 1: Deploy Firestore Rules & Indexes

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project (one-time only)
firebase init

# Deploy ONLY the rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

**Why this is critical:**
- Code expects specific fields: `timestamp`, `ttl`, `submitted_by`, `desired_price_per_kg`
- Without matching rules, all price pulse submissions will fail with permission-denied
- Portfolio operations will be rejected
- Validation/flag updates won't work

**Verify deployment:**
```bash
firebase firestore:rules --project YOUR_PROJECT_ID
```

---

## 📱 Android Production Build

### Step 2: Update Application ID

**Current:** `com.example.agriflow` (NOT allowed on Play Store)
**Required:** `com.yourdomain.agriflow` or `ie.agriflow.app`

Edit `android/app/build.gradle.kts`:
```kotlin
applicationId = "ie.agriflow.app"  // Change this
```

### Step 3: Generate Keystore for Signing

```bash
# Generate release keystore
keytool -genkey -v -keystore android/app/agriflow-release.keystore \
  -alias agriflow -keyalg RSA -keysize 2048 -validity 10000

# You'll be prompted for:
# - Keystore password (SAVE THIS SECURELY)
# - Name, organization, location
# - Alias password (can be same as keystore)
```

**⚠️ CRITICAL: Backup the keystore and passwords!**
- Store in password manager (1Password, LastPass, etc.)
- Without this, you can NEVER update your app on Play Store

### Step 4: Configure Signing

Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=agriflow
storeFile=agriflow-release.keystore
```

**Add to `.gitignore`:**
```
android/key.properties
android/app/*.keystore
```

Update `android/app/build.gradle.kts`:
```kotlin
// Add at top after plugins
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 5: Add Firebase Config Files

1. **Download google-services.json** from Firebase Console:
   - Go to Project Settings → Your apps → Android app
   - Download `google-services.json`
   - Place in `android/app/google-services.json`

2. **Update build.gradle.kts** to apply Google Services plugin:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this
}
```

3. **Update root build.gradle.kts**:
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

### Step 6: Build Release APK/AAB

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# OR build APK (for direct distribution)
flutter build apk --release --split-per-abi
```

**Output locations:**
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APKs: `build/app/outputs/flutter-apk/app-*-release.apk`

---

## 🍎 iOS Production Build (If Required)

### Step 1: Xcode Configuration

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Change Bundle Identifier from `com.example.agriflow` to your domain
2. Select your development team
3. Configure signing & capabilities

### Step 2: Download Firebase Config

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` in Xcode (don't just copy - use "Add Files")
3. Ensure "Copy items if needed" is checked

### Step 3: Build

```bash
flutter build ipa --release
```

---

## 🔍 Pre-Launch Checklist

### Critical Items (Must Complete)

- [ ] **Firestore rules deployed** (`firebase deploy --only firestore`)
- [ ] **Firestore indexes deployed** (auto-deployed with rules)
- [ ] Application ID changed from `com.example.*`
- [ ] Release keystore generated and backed up
- [ ] `google-services.json` added to Android project
- [ ] Signing configuration tested (`flutter build appbundle`)
- [ ] App tested on real device in release mode

### Important Items (Recommended)

- [ ] Update app version in `pubspec.yaml` (currently 1.0.0+1)
- [ ] Test anonymous authentication flow
- [ ] Test price pulse submission (verifies rules work)
- [ ] Test portfolio CRUD operations
- [ ] Test PDF export with live prices
- [ ] Test network error handling (airplane mode)
- [ ] Test on low-end device (performance check)

### Play Store Requirements

- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (minimum 2, up to 8)
- [ ] Privacy policy URL (required for Firebase Auth)
- [ ] App description and metadata
- [ ] Content rating questionnaire
- [ ] Store listing complete

---

## 🔐 Security Configuration

### Environment Variables

Create `.env` file (add to `.gitignore`):
```bash
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id
```

**Note:** For Flutter web builds, these will be visible in source. Rely on Firestore security rules (already configured).

### Firestore Security

✅ **Already configured** - security rules enforce:
- User-specific portfolio data (only owner can read/write)
- Validated price pulse submissions
- Rate limiting via update rules
- 7-day TTL on price data

---

## 📊 Post-Deployment Monitoring

### Firebase Console - Monitor These

1. **Authentication** → Users count should increase
2. **Firestore** → Database usage and query counts
3. **Performance** (if enabled) → App startup time, screen loads
4. **Crashlytics** (when re-enabled) → Crash-free users %

### Key Metrics to Track

- DAU/MAU (Daily/Monthly Active Users)
- Price pulse submission rate
- Portfolio creation rate
- PDF export usage
- Error rate by screen
- App startup time

---

## 🐛 Common Deployment Issues

### Issue: "Failed to get document because the client is offline"

**Cause:** Firestore not initialized properly
**Fix:** Ensure `google-services.json` is in correct location and plugin applied

### Issue: "PERMISSION_DENIED: Missing or insufficient permissions"

**Cause:** Firestore rules not deployed
**Fix:** Run `firebase deploy --only firestore:rules`

### Issue: "The application could not be verified"

**Cause:** Wrong keystore or signing config
**Fix:** Verify `key.properties` paths and passwords are correct

### Issue: "Execution failed for task ':app:processReleaseGoogleServices'"

**Cause:** `google-services.json` missing or invalid
**Fix:** Re-download from Firebase Console, ensure it matches your package name

---

## 🚀 Deployment Commands (Quick Reference)

```bash
# 1. Deploy Firebase rules (CRITICAL - DO THIS FIRST)
firebase deploy --only firestore:rules,firestore:indexes

# 2. Clean and prepare
flutter clean && flutter pub get

# 3. Build for Android
flutter build appbundle --release

# 4. Build for iOS (if needed)
flutter build ipa --release

# 5. Test release build on device
flutter install --release
```

---

## 📞 Support & Troubleshooting

### Firebase CLI Issues
```bash
# Update to latest
npm install -g firebase-tools@latest

# Re-authenticate
firebase logout
firebase login

# Check current project
firebase projects:list
firebase use YOUR_PROJECT_ID
```

### Flutter Build Issues
```bash
# Clear all caches
flutter clean
cd android && ./gradlew clean && cd ..
rm -rf build/

# Update dependencies
flutter pub upgrade
```

---

## 🎯 Version Management

Current version: `1.0.0+1` (from pubspec.yaml)

**Version format:** `MAJOR.MINOR.PATCH+BUILD`
- `1.0.0` = Version name (user-facing)
- `1` = Version code (Android) / Build number (iOS)

**For next release:**
```yaml
version: 1.0.1+2  # Bug fix
version: 1.1.0+3  # New feature
version: 2.0.0+4  # Breaking change
```

---

## ✅ Production Ready Confirmation

After completing the checklist above:

1. ✅ Firestore rules deployed and tested
2. ✅ App builds successfully in release mode
3. ✅ Signed with production keystore
4. ✅ Tested on real devices
5. ✅ Firebase config verified
6. ✅ Application ID updated

**Status:** READY FOR PLAY STORE SUBMISSION

---

**Last Updated:** 2025-12-03
**App Version:** 1.0.0+1
**Branch:** claude/code-review-01SkSFSgzXkgQAHGsPMzULPo
