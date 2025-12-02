# AgriFlow Project Map

**Last Updated:** 2025-11-30 (Post-Refactoring)
**Version:** 1.0.0

Welcome to the AgriFlow project map! This is your central navigation hub for understanding the codebase structure, finding components, and learning how to work with the project.

## Quick Navigation

- [Project Overview](#project-overview)
- [Architecture Overview](#architecture-overview)
- [Component Catalog](#component-catalog)
  - [Screens](#screens-6)
  - [Services](#services-5)
  - [Models](#models-4)
  - [Widgets](#widgets-14)
  - [Providers](#providers-1)
- [Service API Reference](#service-api-reference)
- [Data Models](#data-models)
- [Common Development Tasks](#common-development-tasks)
- [File Organization](#file-organization)
- [Design System](#design-system)
- [Dependencies](#dependencies)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

**AgriFlow** (marketed as "AgriPulse") is a Flutter mobile application designed for Irish farmers to manage their cattle herds and track market prices.

### Core Features

1. **Portfolio Management** - Track cattle groups with breed, weight, county, and target prices
2. **Time-to-Kill Calculator** - Calculate days to target weight, feed costs, and profit margins
3. **Price Pulse** - Crowdsourced market intelligence with county heatmaps and trend analysis
4. **Dashboard** - Real-time herd overview with estimated portfolio value
5. **Settings** - User preferences, dark mode, data management

### Tech Stack

- **Framework:** Flutter 3.10+
- **State Management:** Provider pattern
- **Backend:** Firebase (Auth + Firestore)
- **Charts:** fl_chart
- **PDF Export:** pdf + printing packages

---

## Architecture Overview

AgriFlow follows a **layered architecture**:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    (Screens + Widgets + Theme)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      State Management Layer         │
│         (Providers)                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Business Logic Layer          │
│          (Services)                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Data Layer                  │
│   (Firebase Auth + Firestore)       │
└─────────────────────────────────────┘
```

### Key Principles

- **Screens** display UI and handle user interactions
- **Providers** manage app-wide state (theme, auth)
- **Services** handle business logic and Firebase operations
- **Models** represent data entities with Firestore serialization

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Component Catalog

### Screens (6)

| Screen | File | Purpose | Key Features |
|--------|------|---------|--------------|
| **Main Screen** | `lib/screens/main_screen.dart` | Navigation container | Bottom navigation bar with 5 tabs |
| **Dashboard** | `lib/screens/dashboard_screen.dart` | Home/overview | Total head count, estimated value, avg price, market insights |
| **Portfolio** | `lib/screens/portfolio_screen.dart` | Herd management | Add/delete groups, PDF export, share summary, swipe-to-dismiss |
| **Calculator** | `lib/screens/calculator_screen.dart` | Time-to-kill calculator | Days to target, feed cost, profit margin, save to portfolio |
| **Price Pulse** | `lib/screens/price_pulse_screen.dart` | Market intelligence | Real-time prices, trends, heatmap, filter by breed/weight/county |
| **Settings** | `lib/screens/settings_screen.dart` | User preferences | Dark mode, notifications, data export/delete, account info |

### Services (5)

| Service | File | Responsibility | Firebase Collection |
|---------|------|----------------|---------------------|
| **AuthService** | `lib/services/auth_service.dart` | Anonymous authentication | Firebase Auth |
| **PortfolioService** | `lib/services/portfolio_service.dart` | Cattle group CRUD operations | `users/{uid}/portfolios` |
| **PricePulseService** | `lib/services/price_pulse_service.dart` | Price submissions & analytics | `price_pulses` |
| **UserPreferencesService** | `lib/services/user_preferences_service.dart` | Settings persistence | `users/{uid}/preferences` |
| **PDFExportService** | `lib/services/pdf_export_service.dart` | Portfolio PDF generation | N/A (local) |

### Models (4)

| Model | File | Purpose | Firestore Path |
|-------|------|---------|----------------|
| **CattleGroup** | `lib/models/cattle_group.dart` | Portfolio group representation | `users/{uid}/portfolios/{docId}` |
| **PricePulse** | `lib/models/price_pulse.dart` | Market price submission | `price_pulses/{docId}` |
| **UserPreferences** | `lib/models/user_preferences.dart` | User settings | `users/{uid}/preferences` |

### Widgets (14)

**Organization:** Widgets are categorized into `cards/`, `inputs/`, and `sheets/` subdirectories.

#### Display Widgets (Cards)

| Widget | File | Purpose | Used By |
|--------|------|---------|---------|
| **CustomCard** | `lib/widgets/cards/custom_card.dart` | Generic card container | Multiple screens |
| **StatCard** | `lib/widgets/cards/stat_card.dart` | Metric display (icon + label + value) | Dashboard |
| **MedianBandCard** | `lib/widgets/cards/median_band_card.dart` | Price median with confidence band | Price Pulse |
| **TrendMiniChart** | `lib/widgets/cards/trend_mini_chart.dart` | 7-day line chart | Price Pulse |
| **CountyHeatmapCard** | `lib/widgets/cards/county_heatmap_card.dart` | Geographic price comparison | Price Pulse |

#### Input Widgets

| Widget | File | Purpose | Used By |
|--------|------|---------|---------|
| **BreedPicker** | `lib/widgets/inputs/breed_picker.dart` | Emoji-first breed selector | Portfolio, Price Pulse |
| **WeightBucketPicker** | `lib/widgets/inputs/weight_bucket_picker.dart` | Weight range dropdown | Portfolio, Price Pulse |
| **CountyPicker** | `lib/widgets/inputs/county_picker.dart` | County dropdown (32 counties) | Portfolio, Price Pulse, Settings |
| **PriceSlider** | `lib/widgets/inputs/price_slider.dart` | Price selection (€/kg) | Portfolio |
| **QuantitySlider** | `lib/widgets/inputs/quantity_slider.dart` | Animal quantity (1-200) | Portfolio |
| **WeightSlider** | `lib/widgets/inputs/weight_slider.dart` | Weight range selector | Calculator |

#### Complex Widgets (Sheets & Bars)

| Widget | File | Purpose | Used By |
|--------|------|---------|---------|
| **AddGroupSheet** | `lib/widgets/sheets/add_group_sheet.dart` | Modal for adding cattle groups | Portfolio |
| **SubmitPulseSheet** | `lib/widgets/sheets/submit_pulse_sheet.dart` | Modal for price submissions | Price Pulse |
| **PricePulseFilterBar** | `lib/widgets/sheets/price_pulse_filter_bar.dart` | Filter controls (breed/weight/county) | Price Pulse |

For detailed widget documentation with usage examples, see [WIDGET_CATALOG.md](WIDGET_CATALOG.md).

### Providers (1)

| Provider | File | Type | Purpose |
|----------|------|------|---------|
| **ThemeProvider** | `lib/providers/theme_provider.dart` | ChangeNotifier | Theme mode management (light/dark/system) |

---

## Service API Reference

### AuthService

**File:** `lib/services/auth_service.dart`
**Type:** ChangeNotifier
**Firebase:** Firebase Auth (Anonymous)

#### Key Methods

```dart
/// Sign in anonymously (auto-called on app start)
Future<UserCredential> signInAnonymously()

/// Sign out current user
Future<void> signOut()

/// Delete user account (GDPR compliance)
Future<void> deleteUser()
```

#### State Properties

```dart
User? currentUser        // Current Firebase user (null if not authenticated)
bool isAuthenticated     // true if user is signed in
```

#### Usage Example

```dart
final authService = Provider.of<AuthService>(context);

// Check auth status
if (authService.isAuthenticated) {
  // User is signed in
  print('User ID: ${authService.currentUser?.uid}');
}

// Sign out
await authService.signOut();
```

---

### PortfolioService

**File:** `lib/services/portfolio_service.dart`
**Firestore Collection:** `users/{userId}/portfolios`

#### Key Methods

```dart
/// Load all cattle groups for current user
/// Returns: List<CattleGroup> sorted by created_at (newest first)
/// Throws: Exception if user not authenticated
Future<List<CattleGroup>> loadGroups()

/// Add new cattle group
/// Returns: String documentId of created group
Future<String> addGroup(CattleGroup group)

/// Delete cattle group by ID
Future<void> deleteGroup(String groupId)

/// Get real-time stream of groups
Stream<List<CattleGroup>> getGroupsStream()
```

#### Usage Example

```dart
final portfolioService = Provider.of<PortfolioService>(context, listen: false);

// Load groups
final groups = await portfolioService.loadGroups();

// Add group
final newGroup = CattleGroup(
  breed: Breed.charolais,
  quantity: 30,
  weightBucket: WeightBucket.w600_700,
  desiredPrice: 4.20,
  county: 'Cork',
  createdAt: Timestamp.now(),
);
await portfolioService.addGroup(newGroup);

// Use stream for real-time updates
StreamBuilder<List<CattleGroup>>(
  stream: portfolioService.getGroupsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final groups = snapshot.data!;
      return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) => CattleCard(group: groups[index]),
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

### PricePulseService

**File:** `lib/services/price_pulse_service.dart`
**Firestore Collection:** `price_pulses`

#### Key Methods

```dart
/// Submit anonymous price pulse
/// Auto-expires after 7 days via Firestore TTL
Future<void> submitPulse(PricePulse pulse)

/// Get median price for filters
/// Parameters:
///   - breed: Breed enum
///   - weightBucket: WeightBucket enum
///   - county: String (optional, null = All Ireland)
/// Returns: double median price (95th percentile filtered)
Future<double> getMedianPrice({
  required Breed breed,
  required WeightBucket weightBucket,
  String? county,
})

/// Get 7-day trend data
/// Returns: List<TrendPoint> with date and price
Future<List<TrendPoint>> getTrendData({
  required Breed breed,
  required WeightBucket weightBucket,
  String? county,
})

/// Get county price map for heatmap
/// Returns: Map<String, double> county -> median price
Future<Map<String, double>> getCountyPrices({
  required Breed breed,
  required WeightBucket weightBucket,
})
```

#### Usage Example

```dart
final pricePulseService = Provider.of<PricePulseService>(context, listen: false);

// Submit pulse
final pulse = PricePulse(
  breed: Breed.angus,
  weightBucket: WeightBucket.w600_700,
  price: 4.35,
  county: 'Galway',
  timestamp: Timestamp.now(),
);
await pricePulseService.submitPulse(pulse);

// Get median price
final median = await pricePulseService.getMedianPrice(
  breed: Breed.angus,
  weightBucket: WeightBucket.w600_700,
  county: 'Galway', // or null for All Ireland
);

// Get trend data
final trend = await pricePulseService.getTrendData(
  breed: Breed.angus,
  weightBucket: WeightBucket.w600_700,
);
```

---

### UserPreferencesService

**File:** `lib/services/user_preferences_service.dart`
**Type:** ChangeNotifier
**Firestore Collection:** `users/{userId}/preferences`

#### Key Methods

```dart
/// Load user preferences
Future<UserPreferences> loadPreferences()

/// Save user preferences
Future<void> savePreferences(UserPreferences preferences)

/// Update dark mode setting
Future<void> updateDarkMode(bool enabled)

/// Update notification settings
Future<void> updateNotifications(bool enabled)
```

#### Usage Example

```dart
final prefsService = Provider.of<UserPreferencesService>(context);

// Load preferences
final prefs = await prefsService.loadPreferences();

// Update dark mode
await prefsService.updateDarkMode(true);
```

---

### PDFExportService

**File:** `lib/services/pdf_export_service.dart`

#### Key Methods

```dart
/// Export portfolio to PDF and share
/// Parameters:
///   - groups: List of cattle groups
///   - totalValue: Estimated total value
/// Returns: void (opens share sheet)
Future<void> exportToPDF(List<CattleGroup> groups, double totalValue)
```

#### Usage Example

```dart
final pdfService = PDFExportService();
await pdfService.exportToPDF(groups, totalValue);
```

---

## Data Models

### CattleGroup

**File:** `lib/models/cattle_group.dart`

#### Enums

```dart
enum AnimalType {
  cattle, goat, sheep, chicken, pig
}

enum Breed {
  // Cattle (6): charolais, angus, limousin, hereford, belgianBlue, simmental
  // Goat (3): boer, saanen, alpine
  // Sheep (3): suffolk, texel, cheviot
  // Chicken (2): broiler, layer
  // Pig (3): landrace, duroc, largeWhite
}

enum WeightBucket {
  w400_500,  // "400-500 kg"
  w500_600,  // "500-600 kg"
  w600_700,  // "600-700 kg"
  w700_plus, // "700+ kg"
}
```

#### Class

```dart
class CattleGroup {
  final String id;                // Firestore document ID
  final AnimalType animalType;    // Default: cattle
  final Breed breed;              // Cattle breed
  final int quantity;             // 1-200 animals
  final WeightBucket weightBucket;// Weight range
  final double desiredPrice;      // Target €/kg (3.50-5.50)
  final String county;            // Irish county
  final Timestamp createdAt;      // Creation timestamp

  // Computed properties
  double get estimatedValue;      // quantity * avgWeight * desiredPrice
  double get avgWeight;           // Midpoint of weight bucket
}
```

#### Firestore Document

```json
{
  "animal_type": "cattle",
  "breed": "charolais",
  "quantity": 30,
  "weight_bucket": "w600_700",
  "desired_price": 4.20,
  "county": "Cork",
  "created_at": Timestamp
}
```

---

### PricePulse

**File:** `lib/models/price_pulse.dart`

```dart
class PricePulse {
  final String id;              // Firestore document ID
  final Breed breed;            // Cattle breed
  final WeightBucket weightBucket; // Weight range
  final double price;           // Actual sale price €/kg
  final String county;          // Irish county
  final Timestamp timestamp;    // Submission time
  final int ttl;                // 604800 (7 days in seconds)
}
```

**Firestore TTL:** Documents auto-delete after 7 days via `ttl` field.

---

### UserPreferences

**File:** `lib/models/user_preferences.dart`

```dart
class UserPreferences {
  final bool darkMode;          // Dark mode enabled (default: false)
  final bool notifications;     // Push notifications (default: true)
  final String defaultCounty;   // Default county (default: 'Cork')
  final bool rainAlerts;        // Weather alerts (default: true)
  final bool holidayAlerts;     // Holiday alerts (default: true)
  final bool targetDateAlerts;  // Target date alerts (default: true)
  final bool isGaeilge;         // Irish language (default: false)
}
```

---

## Common Development Tasks

### Add a New Screen

1. Create file in `lib/screens/your_screen.dart`
2. Define StatefulWidget or StatelessWidget
3. Add route in `main_screen.dart` BottomNavigationBar
4. Import required services via Provider
5. Update this PROJECT_MAP.md

**Example:**

```dart
// lib/screens/your_screen.dart
class YourScreen extends StatefulWidget {
  @override
  State<YourScreen> createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<YourService>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Your Screen')),
      body: YourContent(),
    );
  }
}
```

---

### Add a New Widget

1. Create file in `lib/widgets/your_widget.dart`
2. Make widget reusable with clear props
3. Add to [WIDGET_CATALOG.md](WIDGET_CATALOG.md)

**Example:**

```dart
class YourWidget extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const YourWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

---

### Add a New Service

1. Create file in `lib/services/your_service.dart`
2. Define class (optionally extends ChangeNotifier)
3. Implement business logic methods
4. Register in `main.dart` MultiProvider
5. Update this PROJECT_MAP.md

**Example:**

```dart
class YourService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Result> doSomething(String param) async {
    // Implementation
    notifyListeners(); // If state changed
  }
}

// In main.dart:
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => YourService()),
  ],
)
```

---

### Add a New Model

1. Create file in `lib/models/your_model.dart`
2. Define class with final fields
3. Add Firestore serialization (toMap, fromMap)
4. Update this PROJECT_MAP.md

**Example:**

```dart
class YourModel {
  final String id;
  final String field;

  const YourModel({required this.id, required this.field});

  Map<String, dynamic> toMap() => {'field': field};

  factory YourModel.fromMap(Map<String, dynamic> map, String id) {
    return YourModel(id: id, field: map['field'] as String);
  }
}
```

---

## File Organization

### Current Structure

```
lib/
├── config/           # Configuration
│   ├── theme.dart                    # App theme (light/dark)
│   ├── firebase_config.dart          # Firebase credentials (gitignored)
│   └── firebase_config.example.dart  # Firebase template
│
├── models/           # Data models
│   ├── cattle_group.dart             # Portfolio item (with enums)
│   ├── price_pulse.dart              # Market submission
│   └── user_preferences.dart         # User settings
│
├── providers/        # State management
│   └── theme_provider.dart           # Theme mode provider
│
├── screens/          # App screens (6)
│   ├── main_screen.dart              # Navigation container
│   ├── dashboard_screen.dart         # Home overview
│   ├── portfolio_screen.dart         # Herd management
│   ├── calculator_screen.dart        # Time-to-kill calculator
│   ├── price_pulse_screen.dart       # Market intelligence
│   └── settings_screen.dart          # User preferences
│
├── services/         # Business logic (5)
│   ├── auth_service.dart             # Authentication
│   ├── portfolio_service.dart        # Portfolio CRUD
│   ├── price_pulse_service.dart      # Price data
│   ├── user_preferences_service.dart # Settings persistence
│   └── pdf_export_service.dart       # PDF generation
│
├── utils/            # Constants & helpers
│   └── constants.dart                # Irish counties, app version
│
├── widgets/          # UI components
│   ├── cards/        # Display widgets
│   │   ├── custom_card.dart
│   │   ├── stat_card.dart
│   │   └── ...
│   ├── inputs/       # Input widgets
│   │   ├── breed_picker.dart
│   │   ├── county_picker.dart
│   │   └── ...
│   ├── sheets/       # Complex widgets
│   │   ├── add_group_sheet.dart
│   │   └── ...
│   └── widgets.dart  # Barrel file
│
└── main.dart                         # App entry point
```

### Improvement Recommendations

See [REFACTORING_GUIDE.md](REFACTORING_GUIDE.md) for detailed refactoring plans:
- Reorganize widgets into `cards/`, `inputs/`, `sheets/` subdirectories
- Delete unused files (cattle_entry.dart, supabase_config.dart)
- Move test file to `test/` directory
- Add barrel files for cleaner imports

---

## Design System

### Color Palette

**Light Theme:**
- Primary: `Colors.green.shade700` (#388E3C)
- Background: `Colors.grey.shade50` (#FAFAFA)
- Surface: `Colors.white` (#FFFFFF)
- Error: `Colors.red.shade700` (#D32F2F)

**Dark Theme:**
- Primary: `Colors.green.shade700` (#388E3C)
- Background: `Color(0xFF0A0A0A)` (Jet Black)
- Surface: `Color(0xFF1A1A1A)` (Dark Gray)
- Error: `Colors.red.shade700` (#D32F2F)

### Typography

Using Google Fonts (Outfit, Inter):

- **Headings:** `titleLarge`, `titleMedium`, `titleSmall`
- **Body:** `bodyLarge`, `bodyMedium`
- **Labels:** `labelLarge`, `labelMedium`

### Spacing Scale

- **xs:** 4px
- **sm:** 8px
- **md:** 12px
- **lg:** 16px
- **xl:** 24px
- **2xl:** 32px

### Border Radius

- **sm:** 8px
- **md:** 12px
- **lg:** 16px
- **xl:** 24px

### Icon Sizes

- **sm:** 16px
- **md:** 24px
- **lg:** 32px
- **xl:** 48px

---

## Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter: sdk: flutter

  # Firebase
  firebase_core: ^4.2.1
  firebase_auth: ^6.1.2
  cloud_firestore: ^6.1.0
  cloud_functions: ^6.0.4

  # State Management
  provider: ^6.0.5

  # UI & Charts
  google_fonts: ^6.3.2
  fl_chart: ^1.1.1

  # PDF & Sharing
  pdf: ^3.11.3
  printing: ^5.14.2
  share_plus: ^12.0.1

  # Utilities
  intl: ^0.18.1
  uuid: ^3.0.7
  url_launcher: ^6.3.2
  shared_preferences: ^2.5.3
```

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^5.0.0
```

---

## Troubleshooting

### Firebase Not Working

**Symptom:** "User not authenticated" errors

**Solution:**
1. Check Firebase Console → Authentication → Sign-in method → Anonymous enabled
2. Verify `firebase_config.dart` credentials match console
3. Run `test/test_firebase_connection.dart` to diagnose

### Widget Not Updating

**Symptom:** UI doesn't reflect state changes

**Solution:**
1. Ensure `setState()` is called in StatefulWidget
2. Ensure `notifyListeners()` is called in ChangeNotifier
3. Check Provider is listening: `Provider.of<Service>(context, listen: true)`

### Build Errors on Windows

**Symptom:** CMake errors during build

**Solution:**
1. Install CMake 3.21+ from [cmake.org](https://cmake.org/)
2. Add to PATH
3. Restart terminal
4. Run `flutter clean && flutter pub get`

---

## Additional Resources

- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed system design
- [WIDGET_CATALOG.md](WIDGET_CATALOG.md) - Component usage guide
- [ONBOARDING.md](ONBOARDING.md) - Developer quick start
- [REFACTORING_GUIDE.md](REFACTORING_GUIDE.md) - Proposed improvements
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Documentation](https://pub.dev/packages/provider)

---

**Maintained by:** Development Team
**Questions?** Check [ONBOARDING.md](ONBOARDING.md) or open an issue
