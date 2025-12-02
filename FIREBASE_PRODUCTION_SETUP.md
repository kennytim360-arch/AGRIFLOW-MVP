# Firebase Production Setup Guide for AgriFlow

**Last Updated**: 2025-12-01
**Status**: Implementation Guide

---

## Overview

This guide walks through setting up a production-ready Firebase backend for AgriFlow, following the requirements specification provided.

---

## Table of Contents

1. [Firebase Project Setup](#1-firebase-project-setup)
2. [Authentication Configuration](#2-authentication-configuration)
3. [Cloud Firestore Setup](#3-cloud-firestore-setup)
4. [Security Rules](#4-security-rules)
5. [Cloud Functions](#5-cloud-functions)
6. [Analytics & Crashlytics](#6-analytics--crashlytics)
7. [Firebase Hosting](#7-firebase-hosting)
8. [Platform Configuration](#8-platform-configuration)
9. [Testing & Validation](#9-testing--validation)

---

## 1. Firebase Project Setup

### Step 1.1: Create Production Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Project name: `agriflow-production` (or your preferred name)
4. Enable Google Analytics: **Yes** (recommended)
5. Choose or create Analytics account
6. Click **"Create project"**

### Step 1.2: Upgrade to Blaze Plan (Pay-as-you-go)

**Why**: Cloud Functions require Blaze plan

1. In Firebase Console, click **"Upgrade"** in the bottom left
2. Select **"Blaze Plan"**
3. Set up billing account
4. **Note**: Free tier is generous; typical costs for MVP: $0-5/month

---

## 2. Authentication Configuration

### Step 2.1: Enable Anonymous Authentication

1. Navigate to **Authentication** → **Sign-in method**
2. Click **"Anonymous"**
3. Toggle **"Enable"**
4. Click **"Save"**

### Step 2.2: Enable Email/Password Authentication

1. In **Sign-in method**, click **"Email/Password"**
2. Toggle **"Enable"**
3. Optional: Enable **"Email link (passwordless sign-in)"**
4. Click **"Save"**

### Step 2.3: Enable Google Sign-In (Optional)

1. In **Sign-in method**, click **"Google"**
2. Toggle **"Enable"**
3. Project public-facing name: `AgriFlow`
4. Support email: Your email
5. Click **"Save"**

### Step 2.4: Account Linking Strategy

**Implementation Note**: Account linking (Anonymous → Persistent) will be implemented in the Flutter app using:

```dart
// Link anonymous account to email/password
await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
```

This is handled in `lib/services/auth_service.dart` (to be updated).

---

## 3. Cloud Firestore Setup

### Step 3.1: Create Firestore Database

1. Navigate to **Firestore Database** → **Create database**
2. Select **"Start in production mode"** (we'll add custom rules next)
3. Choose region: **europe-west1** (Ireland - closest to target users)
4. Click **"Enable"**

### Step 3.2: Create Collections

Firebase collections are created automatically when first document is added. The app will create:

#### Collection: `users`
- Document ID: `{userId}` (Firebase Auth UID)
- Fields:
  ```json
  {
    "created_at": Timestamp,
    "subscription_status": "free" | "premium",
    "settings": {
      "dark_mode": boolean,
      "notifications": boolean,
      "default_county": string
    }
  }
  ```

#### Subcollection: `users/{userId}/portfolios`
- Document ID: Auto-generated
- Fields:
  ```json
  {
    "animal_type": "cattle",
    "breed": string,
    "quantity": number,
    "weight_bucket": string,
    "desired_price": number,
    "county": string,
    "created_at": Timestamp
  }
  ```

#### Subcollection: `users/{userId}/preferences`
- Document ID: `settings` (single document)
- Fields: Same as UserPreferences model

#### Collection: `pricePulses`
- Document ID: Auto-generated
- Fields:
  ```json
  {
    "submitted_by": string (Auth UID),
    "timestamp": Timestamp,
    "breed": string,
    "weight_bucket": string,
    "price": number,
    "county": string,
    "ttl": number (604800 = 7 days in seconds)
  }
  ```

### Step 3.3: Create Indexes

Required composite indexes for Price Pulse queries:

1. Navigate to **Firestore** → **Indexes** → **Composite**
2. Click **"Create index"**

**Index 1: Breed + Weight + County + Timestamp**
- Collection ID: `pricePulses`
- Fields:
  - `breed` (Ascending)
  - `weight_bucket` (Ascending)
  - `county` (Ascending)
  - `timestamp` (Descending)
- Query scope: Collection

**Index 2: Breed + Weight + Timestamp (All Ireland)**
- Collection ID: `pricePulses`
- Fields:
  - `breed` (Ascending)
  - `weight_bucket` (Ascending)
  - `timestamp` (Descending)
- Query scope: Collection

**Index 3: TTL Cleanup**
- Collection ID: `pricePulses`
- Fields:
  - `ttl` (Ascending)
  - `timestamp` (Ascending)
- Query scope: Collection

**Note**: Indexes take 5-10 minutes to build.

### Step 3.4: Set Up TTL Policy

1. Navigate to **Firestore** → **Data**
2. Select `pricePulses` collection
3. Click **"Add field"** → Name: `ttl`, Type: Number
4. Navigate to **Settings** → **Time-to-live (TTL)**
5. Click **"Enable TTL policy"**
6. Collection: `pricePulses`
7. TTL field: `ttl`
8. Click **"Enable"**

**How it works**: Documents with `ttl` field set to Unix timestamp are auto-deleted after that time.

For 7-day expiry, set `ttl = timestamp.seconds + 604800` when creating documents.

---

## 4. Security Rules

### Step 4.1: Update Firestore Security Rules

1. Navigate to **Firestore** → **Rules**
2. Replace with the following rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidPricePulse() {
      let data = request.resource.data;
      return data.keys().hasAll(['breed', 'weight_bucket', 'price', 'county', 'timestamp', 'ttl', 'submitted_by'])
        && data.submitted_by == request.auth.uid
        && data.price is number
        && data.price > 0
        && data.price < 10
        && data.ttl == 604800
        && data.timestamp == request.time;
    }

    function isValidPortfolio() {
      let data = request.resource.data;
      return data.keys().hasAll(['animal_type', 'breed', 'quantity', 'weight_bucket', 'desired_price', 'county', 'created_at'])
        && data.quantity is number
        && data.quantity > 0
        && data.quantity <= 1000
        && data.desired_price is number
        && data.desired_price > 0;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);

      // Portfolio subcollection
      match /portfolios/{portfolioId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) && isValidPortfolio();
        allow update: if isOwner(userId) && isValidPortfolio();
        allow delete: if isOwner(userId);
      }

      // Preferences subcollection
      match /preferences/{preferenceId} {
        allow read, write: if isOwner(userId);
      }
    }

    // Price Pulses collection (anonymous submissions, public read)
    match /pricePulses/{pricePulseId} {
      allow read: if isAuthenticated(); // Any authenticated user can read
      allow create: if isAuthenticated() && isValidPricePulse(); // Authenticated users can submit
      allow update: if false; // Immutable once created
      allow delete: if false; // Only Cloud Functions can delete (via admin SDK)
    }
  }
}
```

3. Click **"Publish"**

### Step 4.2: Test Security Rules

1. Click **"Rules Playground"**
2. Test various scenarios:
   - Anonymous user reading pricePulses: ✅ Should allow
   - User reading own portfolio: ✅ Should allow
   - User reading another user's portfolio: ❌ Should deny
   - Unauthenticated user reading pricePulses: ❌ Should deny

---

## 5. Cloud Functions

### Step 5.1: Initialize Functions

**In your project directory:**

```bash
cd C:\Users\user\desktop\agriflow\agriflow
npm install -g firebase-tools
firebase login
firebase init functions
```

**Select options:**
- Language: TypeScript
- ESLint: Yes
- Install dependencies: Yes

This creates a `functions/` directory.

### Step 5.2: Install Dependencies

```bash
cd functions
npm install --save firebase-admin firebase-functions
```

### Step 5.3: Implement Cloud Functions

Edit `functions/src/index.ts`:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Scheduled function to delete expired price pulses
 * Runs daily at 2:00 AM UTC
 */
export const deleteExpiredPricePulses = functions
  .region("europe-west1")
  .pubsub.schedule("0 2 * * *")
  .timeZone("Europe/Dublin")
  .onRun(async (context) => {
    const firestore = admin.firestore();
    const now = admin.firestore.Timestamp.now().seconds;

    try {
      // Query price pulses older than 7 days (604800 seconds)
      const expiredPulsesQuery = firestore
        .collection("pricePulses")
        .where("timestamp", "<", admin.firestore.Timestamp.fromMillis((now - 604800) * 1000))
        .limit(500); // Process in batches to avoid timeouts

      const snapshot = await expiredPulsesQuery.get();

      if (snapshot.empty) {
        console.log("No expired price pulses to delete");
        return null;
      }

      // Batch delete
      const batch = firestore.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${snapshot.size} expired price pulses`);

      return null;
    } catch (error) {
      console.error("Error deleting expired price pulses:", error);
      throw error;
    }
  });

/**
 * Triggered function when a user document is deleted
 * Recursively deletes all user's subcollections
 */
export const onUserDelete = functions
  .region("europe-west1")
  .firestore.document("users/{userId}")
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    const firestore = admin.firestore();

    try {
      // Delete portfolios subcollection
      const portfoliosRef = firestore.collection(`users/${userId}/portfolios`);
      const portfoliosSnapshot = await portfoliosRef.get();

      const batch = firestore.batch();
      portfoliosSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // Delete preferences subcollection
      const preferencesRef = firestore.collection(`users/${userId}/preferences`);
      const preferencesSnapshot = await preferencesRef.get();
      preferencesSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      console.log(`Deleted all subcollections for user ${userId}`);
      return null;
    } catch (error) {
      console.error(`Error deleting subcollections for user ${userId}:`, error);
      throw error;
    }
  });

/**
 * Optional: Aggregate market insights from price pulses
 * Can be triggered on schedule or on write
 */
export const aggregateMarketInsights = functions
  .region("europe-west1")
  .pubsub.schedule("0 */6 * * *") // Every 6 hours
  .timeZone("Europe/Dublin")
  .onRun(async (context) => {
    const firestore = admin.firestore();

    try {
      // Query recent price pulses (last 7 days)
      const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - 7 * 24 * 60 * 60 * 1000
      );

      const pulsesSnapshot = await firestore
        .collection("pricePulses")
        .where("timestamp", ">=", sevenDaysAgo)
        .get();

      // Aggregate by breed and weight bucket
      const aggregates: { [key: string]: number[] } = {};

      pulsesSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const key = `${data.breed}_${data.weight_bucket}`;

        if (!aggregates[key]) {
          aggregates[key] = [];
        }
        aggregates[key].push(data.price);
      });

      // Calculate median prices
      const insights: { [key: string]: any } = {};

      for (const [key, prices] of Object.entries(aggregates)) {
        const sorted = prices.sort((a, b) => a - b);
        const median = sorted[Math.floor(sorted.length / 2)];

        const [breed, weightBucket] = key.split("_");
        insights[key] = {
          breed,
          weight_bucket: weightBucket,
          median_price: median,
          sample_size: prices.length,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };
      }

      // Store aggregated insights (optional - for faster dashboard loading)
      // This can be stored in a separate collection or in-memory cache
      console.log("Market insights aggregated:", insights);

      return null;
    } catch (error) {
      console.error("Error aggregating market insights:", error);
      throw error;
    }
  });
```

### Step 5.4: Deploy Functions

```bash
firebase deploy --only functions
```

**Note**: First deployment may take 5-10 minutes.

---

## 6. Analytics & Crashlytics

### Step 6.1: Enable Firebase Analytics

1. Navigate to **Analytics** → **Dashboard**
2. Analytics should already be enabled if you chose it during project creation
3. If not, click **"Enable Analytics"**

### Step 6.2: Add Analytics to Flutter App

**Update `pubspec.yaml`:**

```yaml
dependencies:
  firebase_analytics: ^11.3.3
```

Run:
```bash
flutter pub get
```

**Update `lib/main.dart`:**

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  runApp(MyApp(analytics: analytics));
}
```

**Create `lib/services/analytics_service.dart`:**

```dart
/// analytics_service.dart - Firebase Analytics tracking
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log custom events
  Future<void> logPricePulseSubmitted({
    required String breed,
    required String weightBucket,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'price_pulse_submitted',
      parameters: {
        'breed': breed,
        'weight_bucket': weightBucket,
        'price': price,
      },
    );
  }

  Future<void> logPortfolioUpdated({required int groupCount}) async {
    await _analytics.logEvent(
      name: 'portfolio_updated',
      parameters: {'group_count': groupCount},
    );
  }

  Future<void> logCalculatorUsed({required String calculationType}) async {
    await _analytics.logEvent(
      name: 'calculator_used',
      parameters: {'type': calculationType},
    );
  }

  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}
```

### Step 6.3: Enable Crashlytics

1. Navigate to **Crashlytics** → **Get started**
2. Click **"Enable Crashlytics"**

**Update `pubspec.yaml`:**

```yaml
dependencies:
  firebase_crashlytics: ^4.1.3
```

Run:
```bash
flutter pub get
```

**Update `lib/main.dart`:**

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(MyApp());
}
```

---

## 7. Firebase Hosting

### Step 7.1: Initialize Hosting

```bash
firebase init hosting
```

**Select options:**
- Public directory: `build/web`
- Configure as single-page app: Yes
- Set up automatic builds with GitHub: No (for now)
- Overwrite index.html: No

### Step 7.2: Configure `firebase.json`

Edit `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=604800"
          }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  }
}
```

### Step 7.3: Build and Deploy Web App

```bash
flutter build web --release
firebase deploy --only hosting
```

Your app will be available at: `https://agriflow-production.web.app`

---

## 8. Platform Configuration

### Step 8.1: Android Configuration

1. In Firebase Console, click **"Add app"** → **Android**
2. Android package name: `com.agriflow.app` (or from `android/app/build.gradle`)
3. Download `google-services.json`
4. Place in `android/app/`

**Get SHA-1 fingerprint:**

```bash
cd android
./gradlew signingReport
```

Copy the SHA-1 fingerprint and add it in Firebase Console → Project Settings → Your apps → Android → Add fingerprint.

### Step 8.2: iOS Configuration

1. In Firebase Console, click **"Add app"** → **iOS**
2. iOS bundle ID: `com.agriflow.app` (or from `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag `GoogleService-Info.plist` into `Runner/Runner` folder

---

## 9. Testing & Validation

### Step 9.1: Test Authentication

```bash
flutter run -d chrome
```

1. Open app
2. Sign in anonymously
3. Check Firebase Console → Authentication → Users (should see anonymous user)

### Step 9.2: Test Firestore

1. Add a cattle group in Portfolio screen
2. Check Firebase Console → Firestore → users/{uid}/portfolios (should see document)

### Step 9.3: Test Security Rules

1. Try accessing another user's portfolio (should fail)
2. Submit price pulse anonymously (should succeed)

### Step 9.4: Test Cloud Functions

Manually trigger function:

```bash
firebase functions:shell
deleteExpiredPricePulses()
```

### Step 9.5: Test Analytics

1. Use app for a few minutes
2. Check Firebase Console → Analytics → Events (may take 24 hours to appear)

### Step 9.6: Test Crashlytics

Add test crash in app:

```dart
FirebaseCrashlytics.instance.crash(); // Force crash for testing
```

Check Firebase Console → Crashlytics (may take a few minutes).

---

## 10. Production Checklist

Before going live:

- [ ] All security rules tested and validated
- [ ] Indexes created and active
- [ ] Cloud Functions deployed and tested
- [ ] Analytics events logging correctly
- [ ] Crashlytics reporting test crashes
- [ ] Firebase Hosting deployed (if using web)
- [ ] Android SHA-1 fingerprints added (debug + release)
- [ ] iOS bundle ID configured
- [ ] TTL policy enabled for pricePulses
- [ ] Billing alerts set up in Google Cloud Console
- [ ] Backup strategy for critical data (optional)

---

## 11. Monitoring & Maintenance

### Daily Tasks
- Check Crashlytics for new crashes
- Monitor Firestore usage (reads/writes/deletes)

### Weekly Tasks
- Review Analytics events and user behavior
- Check Cloud Functions logs for errors
- Review Firestore costs

### Monthly Tasks
- Audit security rules
- Review and optimize indexes
- Update Firebase SDK versions

---

## Troubleshooting

### Issue: "Firebase not initialized"
**Solution**: Ensure `Firebase.initializeApp()` is called before `runApp()` in `main.dart`.

### Issue: "Firestore index required"
**Solution**: Firebase will log the exact index needed. Copy the link and create the index in Console.

### Issue: "Cloud Functions timeout"
**Solution**: Increase timeout in function configuration or optimize batch size.

### Issue: "Anonymous users can't write to Firestore"
**Solution**: Check security rules - anonymous users must be authenticated (`request.auth != null`).

---

## Cost Estimation (MVP)

Assuming 1,000 active users:

- **Firestore**: ~10,000 reads/day, ~1,000 writes/day = ~$0.50/month
- **Cloud Functions**: ~1,000 invocations/day = ~$0.10/month
- **Hosting**: 10 GB bandwidth = ~$0.15/month
- **Analytics**: Free
- **Crashlytics**: Free
- **Storage**: Minimal (~$0.01/month)

**Total**: ~$0.76/month (well within free tier for small MVP)

At 10,000 users: ~$7-15/month

---

## Next Steps

1. Complete Firebase setup following this guide
2. Update `lib/config/firebase_config.dart` with production credentials
3. Implement account linking in `lib/services/auth_service.dart`
4. Add Analytics tracking to all screens
5. Test on real Android and iOS devices
6. Proceed to Priority 2: Testing Infrastructure

---

**Last Updated**: 2025-12-01
**Maintained by**: Development Team
