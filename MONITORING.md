# AgriFlow - Production Monitoring Setup

## 🔍 Overview

This guide covers setting up monitoring and observability for AgriFlow in production.

## 📊 Firebase Analytics

### Setup (Already Configured)

Firebase Analytics is already included via `firebase_analytics: ^12.0.4` in pubspec.yaml.

### Key Metrics to Track

**Automatic Events:**
- `first_open` - New user installs
- `user_engagement` - Session duration
- `screen_view` - Page navigation

**Custom Events to Add:**

```dart
// In lib/main.dart or create analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track price pulse submissions
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

  // Track portfolio actions
  Future<void> logPortfolioAction({
    required String action, // 'add', 'update', 'delete'
    required int quantity,
  }) async {
    await _analytics.logEvent(
      name: 'portfolio_action',
      parameters: {
        'action': action,
        'quantity': quantity,
      },
    );
  }

  // Track PDF exports
  Future<void> logPdfExport({
    required int groupCount,
    required int totalAnimals,
  }) async {
    await _analytics.logEvent(
      name: 'pdf_export',
      parameters: {
        'group_count': groupCount,
        'total_animals': totalAnimals,
      },
    );
  }

  // Track errors
  Future<void> logError({
    required String errorType,
    required String screen,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'screen': screen,
      },
    );
  }
}
```

### Viewing Analytics

1. Go to Firebase Console → Analytics → Dashboard
2. Key reports:
   - **Engagement** → See active users, retention
   - **Events** → Track custom events
   - **Conversions** → Mark important events (e.g., first portfolio creation)

---

## 🚀 Firebase Performance Monitoring

### Setup (Needs Configuration)

Performance monitoring tracks app startup time, network requests, and custom traces.

**Enable Performance Monitoring:**

1. **Add to pubspec.yaml:**
```yaml
dependencies:
  firebase_performance: ^0.10.0+8
```

2. **Initialize in main.dart:**
```dart
import 'package:firebase_performance/firebase_performance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Enable performance monitoring
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  runApp(const MyApp());
}
```

3. **Add custom traces for critical operations:**

```dart
// In lib/services/price_pulse_service.dart
Future<void> submitPricePulse(...) async {
  final trace = FirebasePerformance.instance.newTrace('submit_price_pulse');
  await trace.start();

  try {
    // ... existing code ...
    await trace.stop();
  } catch (e) {
    await trace.stop();
    rethrow;
  }
}

// Track Firestore query performance
Future<double?> getMedianPrice(...) async {
  final trace = FirebasePerformance.instance.newTrace('get_median_price');
  await trace.start();

  try {
    // ... existing query code ...
    trace.setMetric('result_count', results.length);
    await trace.stop();
    return medianPrice;
  } catch (e) {
    await trace.stop();
    rethrow;
  }
}

// Track PDF generation time
Future<void> exportPortfolio(...) async {
  final trace = FirebasePerformance.instance.newTrace('pdf_export');
  await trace.start();

  try {
    // ... PDF generation code ...
    trace.setMetric('group_count', groups.length);
    await trace.stop();
  } catch (e) {
    await trace.stop();
    rethrow;
  }
}
```

### Viewing Performance Data

Firebase Console → Performance → Dashboard

**Key Metrics:**
- App start time (should be < 3 seconds)
- Screen rendering times
- Network request durations
- Custom trace timings

---

## 💥 Firebase Crashlytics

### Current Status

**Temporarily disabled** due to version conflicts with Firebase Core 4.x.

```yaml
# In pubspec.yaml - currently commented out
# firebase_crashlytics: ^4.3.10
```

### Re-enable When Compatible

1. **Wait for firebase_crashlytics to support Firebase Core 4.x**
   - Check: https://pub.dev/packages/firebase_crashlytics

2. **Add to pubspec.yaml:**
```yaml
dependencies:
  firebase_crashlytics: ^4.3.10  # Or latest version
```

3. **Initialize in main.dart:**
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}
```

4. **Add custom logging:**
```dart
// In error handlers
try {
  // ... operation ...
} catch (e, stackTrace) {
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
  // ... show user error ...
}

// Add user context
FirebaseCrashlytics.instance.setUserIdentifier(userId);

// Add custom keys for debugging
FirebaseCrashlytics.instance.setCustomKey('portfolio_size', groupCount);
FirebaseCrashlytics.instance.setCustomKey('last_screen', 'DashboardScreen');
```

---

## 📱 Application Monitoring

### Health Check Metrics

Monitor these in Firebase Console:

**Daily Active Users (DAU)**
- Target: Growth trend
- Alert if: Sudden 50% drop (indicates critical bug)

**Crash-Free Users %**
- Target: > 99%
- Alert if: < 95%

**App Startup Time**
- Target: < 3 seconds
- Alert if: > 5 seconds

**API Response Times**
- Firestore reads: < 500ms
- Firestore writes: < 1s
- Alert if: > 2s consistently

**Error Rate**
- Target: < 1% of operations
- Alert if: > 5%

### Custom Dashboard Queries

In Firebase Console → Analytics → Custom Dashboards:

1. **User Engagement Dashboard**
   - DAU/MAU ratio
   - Average session duration
   - Screens per session

2. **Feature Adoption Dashboard**
   - Price pulse submission rate
   - Portfolio creation rate
   - PDF export usage
   - Validation/flag actions

3. **Error Dashboard**
   - Errors by type
   - Errors by screen
   - Network error rate

---

## 🔔 Alerting Setup

### Firebase Alerts

Set up in Firebase Console → Alerts:

**Critical Alerts:**
1. Crash rate > 5%
2. App not responding rate > 2%
3. Network success rate < 90%

**Warning Alerts:**
1. Startup time > 5 seconds
2. Memory usage > 200MB
3. CPU usage > 80%

### Email Notifications

Configure in Firebase Console → Project Settings → Integrations:
- Add email for critical alerts
- Add Slack webhook for team notifications
- Add PagerDuty for on-call escalation

---

## 📈 Key Performance Indicators (KPIs)

### Technical KPIs

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| App Crash Rate | < 0.5% | > 2% |
| App Start Time | < 2s | > 5s |
| API Success Rate | > 99% | < 95% |
| Screen Load Time | < 1s | > 3s |
| Memory Usage | < 150MB | > 250MB |

### Business KPIs

| Metric | Track |
|--------|-------|
| Daily Price Pulses | Trend over time |
| Active Portfolios | Growth rate |
| PDF Exports | Usage frequency |
| User Retention (7-day) | Percentage |
| User Retention (30-day) | Percentage |

---

## 🛠️ Implementation Checklist

### Phase 1: Basic Monitoring (Now)
- [x] Firebase Analytics configured
- [x] Custom error logging via Logger utility
- [ ] Add AnalyticsService wrapper
- [ ] Log key user events (price pulse, portfolio actions)

### Phase 2: Performance Monitoring (Week 1)
- [ ] Add firebase_performance dependency
- [ ] Instrument critical paths (queries, PDF generation)
- [ ] Set up custom traces
- [ ] Configure performance alerts

### Phase 3: Crash Reporting (When Available)
- [ ] Wait for firebase_crashlytics compatibility
- [ ] Add crashlytics to pubspec.yaml
- [ ] Initialize in main.dart
- [ ] Add custom crash logging
- [ ] Set up crash alerts

### Phase 4: Advanced Analytics (Week 2-4)
- [ ] Create custom dashboards
- [ ] Set up BigQuery export (for advanced queries)
- [ ] Configure A/B testing experiments
- [ ] Add user property tracking

---

## 📊 Sample Analytics Implementation

Create `lib/services/analytics_service.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // User properties
  Future<void> setUserProperties({
    required String userId,
    required int portfolioCount,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(
      name: 'portfolio_count',
      value: portfolioCount.toString(),
    );
  }

  // Business events
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

  Future<void> logPortfolioCreated(int animalCount) async {
    await _analytics.logEvent(
      name: 'portfolio_created',
      parameters: {'animal_count': animalCount},
    );
  }

  Future<void> logPdfExported(int groupCount) async {
    await _analytics.logEvent(
      name: 'pdf_exported',
      parameters: {'group_count': groupCount},
    );
  }
}
```

---

## 🎯 Next Steps

1. **Immediate:** Add AnalyticsService and log key events
2. **Week 1:** Enable Performance Monitoring
3. **Monitor:** Watch Firebase Console for first week of data
4. **Optimize:** Address any performance issues found
5. **Alert:** Set up critical alerts for production

---

**Last Updated:** 2025-12-03
**Status:** Analytics ready, Performance monitoring pending, Crashlytics pending compatibility
