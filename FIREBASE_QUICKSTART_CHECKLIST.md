# Firebase Production Setup - Quick Start Checklist

**Estimated Time**: 2-3 hours
**Last Updated**: 2025-12-01

---

## ✅ Pre-Implementation Checklist

Before starting, ensure you have:
- [ ] Node.js installed (for Firebase CLI and Functions)
- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] Google account with billing enabled (Blaze plan required for Functions)
- [ ] Flutter environment set up and working
- [ ] Reviewed `FIREBASE_PRODUCTION_SETUP.md` (comprehensive guide)

---

## 🚀 Step-by-Step Checklist

### Phase 1: Firebase Console Setup (30 minutes)

#### 1.1 Create Project
- [ ] Go to https://console.firebase.google.com/
- [ ] Click "Add project"
- [ ] Name: `agriflow-production` (or your choice)
- [ ] Enable Google Analytics: Yes
- [ ] Create Analytics account or select existing
- [ ] Click "Create project"

#### 1.2 Upgrade to Blaze Plan
- [ ] Click "Upgrade" in Firebase Console sidebar
- [ ] Select "Blaze (Pay as you go)"
- [ ] Set up billing (credit card required)
- [ ] Set budget alert: $10/month (optional but recommended)

#### 1.3 Enable Authentication
- [ ] Navigate to **Authentication** → **Get started**
- [ ] Go to **Sign-in method** tab
- [ ] Enable **Anonymous**: Toggle on → Save
- [ ] Enable **Email/Password**: Toggle on → Save
- [ ] Optional: Enable **Google** sign-in

#### 1.4 Create Firestore Database
- [ ] Navigate to **Firestore Database** → **Create database**
- [ ] Mode: **Start in production mode** (we'll deploy custom rules)
- [ ] Location: **europe-west1** (Ireland - closest to users)
- [ ] Click **Enable**
- [ ] Wait for database creation (~1 minute)

#### 1.5 Enable Analytics
- [ ] Navigate to **Analytics** → **Dashboard**
- [ ] Should already be enabled from project creation
- [ ] If not, click "Enable Analytics"

#### 1.6 Enable Crashlytics
- [ ] Navigate to **Crashlytics** → **Get started**
- [ ] Click **"Enable Crashlytics"**

---

### Phase 2: Local Project Setup (30 minutes)

#### 2.1 Install Dependencies
```bash
cd C:\Users\user\desktop\agriflow\agriflow
flutter pub get
```

Expected output: All dependencies resolved successfully.

#### 2.2 Initialize Firebase
```bash
firebase login
```
- [ ] Browser opens → Select Google account
- [ ] Grant permissions
- [ ] Return to terminal: "Success! Logged in as..."

```bash
firebase init
```

**Select features** (use spacebar to select, enter to confirm):
- [x] Firestore
- [x] Functions
- [x] Hosting

**Firestore setup**:
- [ ] Rules file: Use existing `firestore.rules` (press Enter)
- [ ] Indexes file: Use existing `firestore.indexes.json` (press Enter)

**Functions setup**:
- [ ] Language: TypeScript
- [ ] ESLint: Yes
- [ ] Install dependencies: Yes

**Hosting setup**:
- [ ] Public directory: `build/web`
- [ ] Single-page app: Yes
- [ ] GitHub auto-deploy: No
- [ ] Overwrite index.html: No

#### 2.3 Update .firebaserc
The file should already exist. Verify it contains:
```json
{
  "projects": {
    "default": "agriflow-production"
  }
}
```

Replace `"agriflow-production"` with your actual Firebase project ID.

#### 2.4 Implement Cloud Functions
```bash
cd functions
```

Open `functions/src/index.ts` and replace contents with the code from:
**Source**: `FIREBASE_PRODUCTION_SETUP.md`, Section 5.3

Then install additional dependencies:
```bash
npm install --save firebase-admin firebase-functions
cd ..
```

---

### Phase 3: Deploy Firebase Backend (20 minutes)

#### 3.1 Deploy Firestore Rules & Indexes
```bash
firebase deploy --only firestore
```

Expected output:
```
✔  Deploy complete!
✔  firestore: rules deployed successfully
✔  firestore: indexes deployed successfully
```

**Verify**:
- [ ] Go to Firestore Console → **Rules** → See updated rules
- [ ] Go to Firestore Console → **Indexes** → See 4 indexes building

**Note**: Indexes take 5-10 minutes to build. Continue with other steps.

#### 3.2 Deploy Cloud Functions
```bash
firebase deploy --only functions
```

Expected output:
```
✔  functions[deleteExpiredPricePulses(us-central1)] deployed successfully
✔  functions[onUserDelete(us-central1)] deployed successfully
✔  functions[aggregateMarketInsights(us-central1)] deployed successfully
```

**Verify**:
- [ ] Go to Functions Console → See 3 functions deployed
- [ ] Check logs for any errors

#### 3.3 Build and Deploy Web Hosting (Optional)
```bash
flutter build web --release
firebase deploy --only hosting
```

Expected output:
```
✔  Deploy complete!
✔  Hosting URL: https://agriflow-production.web.app
```

---

### Phase 4: Platform Configuration (45 minutes)

#### 4.1 Android Setup

**Get package name**:
```bash
# From android/app/build.gradle
# Look for: applicationId "com.agriflow.app"
```

**In Firebase Console**:
- [ ] Click **Add app** → **Android**
- [ ] Package name: `com.agriflow.app` (your actual package)
- [ ] App nickname: "AgriFlow Android"
- [ ] Debug SHA-1: (get below)
- [ ] Click **Register app**
- [ ] Download `google-services.json`
- [ ] Place in `android/app/google-services.json`

**Get SHA-1 fingerprint**:
```bash
cd android
gradlew signingReport
```
Copy SHA-1 from output (looks like: `AB:CD:EF:...`)

**Add to Firebase**:
- [ ] Project Settings → Your apps → Android
- [ ] Click **Add fingerprint**
- [ ] Paste SHA-1
- [ ] Save

#### 4.2 iOS Setup

**Get Bundle ID**:
```bash
# From ios/Runner.xcodeproj/project.pbxproj
# Look for: PRODUCT_BUNDLE_IDENTIFIER = com.agriflow.app
```

**In Firebase Console**:
- [ ] Click **Add app** → **iOS**
- [ ] Bundle ID: `com.agriflow.app` (your actual bundle ID)
- [ ] App nickname: "AgriFlow iOS"
- [ ] Click **Register app**
- [ ] Download `GoogleService-Info.plist`

**Add to Xcode**:
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Drag `GoogleService-Info.plist` into `Runner/Runner` folder
- [ ] Check "Copy items if needed"
- [ ] Ensure "Runner" target is selected

---

### Phase 5: Testing & Validation (30 minutes)

#### 5.1 Test Web Version
```bash
flutter run -d chrome
```

**Verify**:
- [ ] App loads without errors
- [ ] Anonymous sign-in works (check console logs)
- [ ] Can add portfolio group
- [ ] Can submit price pulse
- [ ] Check Firestore: See user document created
- [ ] Check Firestore: See portfolio document
- [ ] Check Firestore: See price pulse document

#### 5.2 Test Android (if device available)
```bash
flutter run -d <device-id>
```

**Verify**:
- [ ] App installs
- [ ] Anonymous sign-in works
- [ ] All features work

#### 5.3 Test iOS (if device available)
```bash
flutter run -d <device-id>
```

**Verify**:
- [ ] App installs
- [ ] Anonymous sign-in works
- [ ] All features work

#### 5.4 Verify Firebase Console

**Authentication**:
- [ ] Navigate to **Authentication** → **Users**
- [ ] See anonymous user(s) listed

**Firestore**:
- [ ] Navigate to **Firestore Database** → **Data**
- [ ] See `users` collection
- [ ] See user documents with `portfolios` subcollection
- [ ] See `pricePulses` collection with submissions

**Functions**:
- [ ] Navigate to **Functions** → **Logs**
- [ ] See successful deployment logs
- [ ] No error logs

**Indexes**:
- [ ] Navigate to **Firestore Database** → **Indexes**
- [ ] All 4 indexes show status: **Enabled** (green)

#### 5.5 Test Analytics (24-hour delay)
**Immediate**:
- [ ] Run app with debug flag: `flutter run --dart-define=FIREBASE_DEBUG=true`
- [ ] Go to **Analytics** → **DebugView**
- [ ] Use app features
- [ ] See events appear in DebugView

**After 24 hours**:
- [ ] Go to **Analytics** → **Events**
- [ ] See custom events (price_pulse_submitted, etc.)

#### 5.6 Test Crashlytics
**Force crash**:
Add to any button's onPressed:
```dart
FirebaseCrashlytics.instance.crash();
```

Run app, tap button.

**Verify**:
- [ ] Navigate to **Crashlytics** in Console
- [ ] See crash report (may take 5-10 minutes)

---

## 🎯 Success Checklist

Before considering Priority 1 complete, ensure ALL are checked:

- [ ] Firebase project created and configured
- [ ] Blaze plan active
- [ ] Anonymous auth enabled and tested
- [ ] Email/password auth enabled
- [ ] Firestore database created (europe-west1)
- [ ] Security rules deployed
- [ ] Firestore indexes deployed and **enabled** (green)
- [ ] Cloud Functions deployed (all 3)
- [ ] Android app added to Firebase (with SHA-1)
- [ ] iOS app added to Firebase
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Analytics tracking events
- [ ] Crashlytics reporting crashes
- [ ] App tested on web/Android/iOS
- [ ] All CRUD operations verified in Firestore
- [ ] No console errors during testing

---

## 🐛 Common Issues

### "Permission denied" in Firestore
**Cause**: Security rules not deployed or incorrect
**Fix**: `firebase deploy --only firestore:rules`

### "Index required" error
**Cause**: Index not created or still building
**Fix**: Wait 5-10 minutes, or deploy: `firebase deploy --only firestore:indexes`

### Functions timeout
**Cause**: Cold start or heavy processing
**Fix**: Increase timeout in function config (default 60s)

### Analytics events not showing
**Cause**: 24-hour delay for production
**Fix**: Use DebugView with `--dart-define=FIREBASE_DEBUG=true`

### Android build fails
**Cause**: Missing `google-services.json`
**Fix**: Download from Firebase Console → Add to `android/app/`

### iOS build fails
**Cause**: Missing `GoogleService-Info.plist`
**Fix**: Download from Firebase Console → Add to `ios/Runner/` via Xcode

---

## 📊 Time Breakdown

| Phase | Estimated Time | Complexity |
|-------|----------------|------------|
| Firebase Console Setup | 30 min | Easy |
| Local Project Setup | 30 min | Medium |
| Deploy Backend | 20 min | Medium |
| Platform Configuration | 45 min | Medium |
| Testing & Validation | 30 min | Easy |
| **TOTAL** | **~2.5 hours** | **Medium** |

---

## 📚 Additional Resources

- **Comprehensive Guide**: `FIREBASE_PRODUCTION_SETUP.md`
- **Implementation Status**: `PRIORITY1_IMPLEMENTATION_STATUS.md`
- **Production Timeline**: Review the approved plan document
- **Firebase Documentation**: https://firebase.google.com/docs
- **Flutter Firebase Setup**: https://firebase.google.com/docs/flutter/setup

---

## 🚀 What's Next?

After completing this checklist:

1. **Update app to use Analytics**: Integrate `AnalyticsService` into all screens
2. **Add account linking UI**: Let users upgrade from anonymous to email/password
3. **Add Crashlytics to main.dart**: Global error handling
4. **Priority 2: Testing Infrastructure**: Write unit tests for services
5. **Priority 3: Platform Requirements**: App signing, store assets

---

**Last Updated**: 2025-12-01
**Maintained by**: Development Team
**Status**: Ready for implementation
