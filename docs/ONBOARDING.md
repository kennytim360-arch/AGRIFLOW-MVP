# AgriFlow Developer Onboarding

Welcome to AgriFlow! This guide will get you up and running in **30 minutes**.

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Flutter SDK** (3.10.1 or later) - [Install Guide](https://docs.flutter.dev/get-started/install)
- [ ] **Git** - [Install Guide](https://git-scm.com/downloads)
- [ ] **IDE:** VS Code or Android Studio with Flutter/Dart plugins
- [ ] **Firebase account** - [Sign up](https://firebase.google.com/) (free tier is sufficient)
- [ ] **Windows users:** CMake 3.21+ (for Firebase Windows SDK)
- [ ] **Android users:** Android Studio + Android SDK
- [ ] **iOS users (macOS only):** Xcode + CocoaPods

---

## Setup Steps

### 1. Clone Repository (2 minutes)

```bash
git clone https://github.com/YOUR_USERNAME/agriflow.git
cd agriflow
```

**Verify clone:**

```bash
flutter --version
# Should show Flutter 3.10.1 or later
```

---

### 2. Install Dependencies (3 minutes)

```bash
flutter pub get
```

**Expected output:**

```
Running "flutter pub get" in agriflow...
Resolving dependencies... (5.2s)
+ cloud_firestore 6.1.0
+ firebase_auth 6.1.2
+ firebase_core 4.2.1
+ fl_chart 1.1.1
+ google_fonts 6.3.2
+ provider 6.0.5
+ ... (more dependencies)
Got dependencies!
```

**Troubleshooting:**

- If you see errors, run `flutter clean` then `flutter pub get` again
- Ensure you're using Flutter 3.10+ (`flutter upgrade` if needed)

---

### 3. Configure Firebase (10 minutes)

Firebase is required for authentication and data storage.

#### Step 3.1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name: "AgriFlow" (or your preferred name)
4. Disable Google Analytics (not needed for development)
5. Click "Create project"

#### Step 3.2: Add Windows/Web/Android App

**For Windows:**
1. In Firebase Console → Project Overview → Add app → Windows
2. Register app (package name: `com.example.agriflow`)
3. Download `google-services.json` (not used for Windows, but may be shown)

**For Web:**
1. Add app → Web
2. Register app nickname: "AgriFlow Web"
3. Copy the Firebase config object (you'll need this next)

#### Step 3.3: Enable Anonymous Authentication

1. Firebase Console → Authentication → Get started
2. Sign-in method tab
3. Enable "Anonymous" provider
4. Save

#### Step 3.4: Create Firestore Database

1. Firebase Console → Firestore Database → Create database
2. Select "Start in **test mode**" (for development)
3. Choose location (us-central or europe-west)
4. Click "Enable"

**Important:** Test mode allows unrestricted access. See Security section below for production rules.

#### Step 3.5: Configure App

1. Copy the example config:

```bash
# Windows
copy lib\config\firebase_config.example.dart lib\config\firebase_config.dart

# macOS/Linux
cp lib/config/firebase_config.example.dart lib/config/firebase_config.dart
```

2. Open `lib/config/firebase_config.dart` and fill in your Firebase credentials from the Web app config:

```dart
class FirebaseConfig {
  static const String apiKey = "YOUR_API_KEY_HERE";
  static const String authDomain = "YOUR_PROJECT_ID.firebaseapp.com";
  static const String projectId = "YOUR_PROJECT_ID";
  static const String storageBucket = "YOUR_PROJECT_ID.appspot.com";
  static const String messagingSenderId = "YOUR_SENDER_ID";
  static const String appId = "YOUR_APP_ID";
}
```

**Where to find these values:**

- Firebase Console → Project Settings → General → Your apps → Web app
- Scroll to "Firebase SDK snippet" → Config

#### Step 3.6: Set Firestore Security Rules (Production)

For production, replace test mode rules with:

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

    // User portfolios (private)
    match /users/{userId}/portfolios/{portfolioId} {
      allow read, write: if isOwner(userId);
    }

    // User preferences (private)
    match /users/{userId}/preferences {
      allow read, write: if isOwner(userId);
    }

    // Price pulses (public read, authenticated write, 7-day TTL)
    match /price_pulses/{pulseId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.resource.data.ttl == 604800;
    }
  }
}
```

---

### 4. Run App (2 minutes)

**Windows:**

```bash
flutter run -d windows
```

**Web (Chrome):**

```bash
flutter run -d chrome
```

**Android (with device/emulator connected):**

```bash
flutter run
```

**Expected behavior:**

- App launches with bottom navigation bar
- Dashboard shows "No groups yet" with greeting
- Price Pulse shows filter bar
- Settings shows theme toggle and account info

**Troubleshooting:**

- **"No devices found"**: Connect a device or start an emulator
- **Build errors on Windows**: Install CMake 3.21+ and add to PATH
- **Firebase errors**: Verify `firebase_config.dart` has correct credentials

---

### 5. Test Core Features (5 minutes)

#### Test 1: Add Portfolio Group

1. Navigate to **Portfolio** tab (bottom nav, 2nd icon)
2. Tap floating action button (+) at bottom right
3. Fill out form:
   - **Breed**: Select "Charolais"
   - **Quantity**: Slide to 30
   - **Weight Bucket**: Select "600-700 kg"
   - **County**: Select "Cork"
   - **Price**: Slide to €4.20/kg
4. Tap "Add Group"
5. **Expected:** Group appears in portfolio list with estimated value

#### Test 2: Submit Price Pulse

1. Navigate to **Price Pulse** tab (3rd icon)
2. Tap "Submit Price" button (top right)
3. Fill out form:
   - **Breed**: Select "Angus"
   - **Weight**: Select "600-700 kg"
   - **County**: Select "Galway"
   - **Price**: Slide to €4.35/kg
4. Tap "Submit Pulse"
5. **Expected:** Success message, sheet closes, data appears in Price Pulse feed

#### Test 3: Toggle Dark Mode

1. Navigate to **Settings** tab (5th icon)
2. Find "Dark Mode" toggle
3. Tap toggle to enable
4. **Expected:** App theme switches to dark immediately (black background, white text)
5. Toggle again to switch back to light mode

#### Test 4: Calculate Time-to-Kill

1. Navigate to **Calculator** tab (4th icon)
2. Adjust sliders:
   - **Live Weight**: 600 kg
   - **Target Weight**: 700 kg
   - **Daily Gain**: 1.0 kg/day
   - **Feed Cost**: €2.00/day
3. **Expected:** See calculated results:
   - Days to target: 100 days
   - Expected date: [current date + 100 days]
   - Total feed cost: €200.00

**All tests passing?** You're ready to develop! 🎉

---

### 6. Explore Codebase (10 minutes)

**Essential files to read:**

1. **[PROJECT_MAP.md](PROJECT_MAP.md)** - Master navigation guide (start here!)
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design overview
3. `lib/main.dart` - App entry point and provider setup
4. `lib/screens/dashboard_screen.dart` - Example screen structure
5. `lib/services/portfolio_service.dart` - Example service pattern
6. `lib/models/cattle_group.dart` - Example data model

**Pro tip:** Use [PROJECT_MAP.md](PROJECT_MAP.md) as your primary reference. It links to all documentation and explains every component.

---

## Development Workflow

### Daily Development

1. **Pull latest changes:**

```bash
git pull origin main
```

2. **Run app with hot reload:**

```bash
flutter run -d windows
```

3. **Make changes:**
   - Edit code in IDE
   - Press `r` in terminal for hot reload (preserves state)
   - Press `R` for hot restart (resets state)
   - Press `q` to quit

4. **Check for errors:**

```bash
flutter analyze
```

5. **Format code:**

```bash
flutter format lib/
```

---

### Adding Features

**Before coding:**

1. Check [PROJECT_MAP.md](PROJECT_MAP.md) for similar patterns
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) for layer responsibilities
3. Check [WIDGET_CATALOG.md](WIDGET_CATALOG.md) for reusable components

**During coding:**

1. Follow existing naming conventions (snake_case files, PascalCase classes)
2. Use Provider for state management
3. Handle errors with try-catch
4. Keep business logic in services (not screens)

**After coding:**

1. Test manually (add, edit, delete flows)
2. Run `flutter analyze` (fix all issues)
3. Run `flutter format lib/`
4. Update [PROJECT_MAP.md](PROJECT_MAP.md) if added new components
5. Commit with clear message

---

### Common Tasks Quick Reference

#### Add New Screen

```dart
// 1. Create file: lib/screens/your_screen.dart
class YourScreen extends StatefulWidget {
  @override
  State<YourScreen> createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Screen')),
      body: Center(child: Text('Content')),
    );
  }
}

// 2. Add route in main_screen.dart bottom navigation
```

#### Add New Widget

```dart
// 1. Create file: lib/widgets/your_widget.dart
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
    return Container(/* ... */);
  }
}

// 2. Use in screens:
import 'package:agriflow/widgets/your_widget.dart';
```

#### Add New Service Method

```dart
// 1. Add method to service: lib/services/your_service.dart
Future<Result> doSomething() async {
  try {
    // Firebase logic
    final result = await _firestore.collection('path').get();
    notifyListeners(); // if ChangeNotifier
    return result;
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}

// 2. Call from screen:
final service = Provider.of<YourService>(context, listen: false);
await service.doSomething();
```

---

## Project Structure Quick Map

```
lib/
├── config/        ← Theme, Firebase setup
├── models/        ← Data classes (CattleGroup, PricePulse, etc.)
├── providers/     ← ChangeNotifiers (ThemeProvider)
├── screens/       ← Full-page views (Dashboard, Portfolio, etc.)
├── services/      ← Business logic (Auth, Portfolio, PricePulse)
├── utils/         ← Constants (counties, weight buckets)
├── widgets/       ← Reusable UI components (14 widgets)
│   ├── Custom cards, stat cards, charts
│   ├── Pickers (breed, county, weight)
│   ├── Sliders (price, quantity, weight)
│   └── Sheets (add group, submit pulse)
└── main.dart      ← App entry point
```

**Full details:** See [PROJECT_MAP.md](PROJECT_MAP.md)

---

## Code Style Guide

### Naming Conventions

```dart
// Classes: PascalCase
class CattleGroup { }

// Files: snake_case
cattle_group.dart

// Variables: camelCase
final String selectedCounty;

// Constants: camelCase
const String appVersion = '1.0.0';

// Private members: underscore prefix
final FirebaseAuth _auth;
```

### Imports Order

```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 4. Local imports
import '../models/cattle_group.dart';
import '../services/portfolio_service.dart';
```

### Comments

```dart
// Public APIs should have doc comments
/// Loads all cattle groups for the current user.
///
/// Returns a list of [CattleGroup] sorted by creation date.
/// Throws [Exception] if user is not authenticated.
Future<List<CattleGroup>> loadGroups() async { }

// Private members can use single-line comments
// Helper method to get user's Firestore path
String _getUserPath() => 'users/${_auth.currentUser!.uid}';
```

---

## Debugging Tips

### Firebase Not Working

**Symptom:** "User not authenticated" errors

**Solution:**

1. Check Firebase Console → Authentication → Sign-in method → Anonymous enabled
2. Verify `lib/config/firebase_config.dart` credentials match console
3. Run test file:

```bash
flutter run lib/test_firebase_connection.dart
```

You should see:

```
✅ Firebase initialized successfully!
✅ Anonymous sign-in successful!
User ID: [generated ID]
```

---

### Hot Reload Not Working

**Symptom:** Changes not appearing after `r`

**Solution:**

1. Try hot restart (`R`)
2. Stop app and re-run `flutter run`
3. Check for syntax errors: `flutter analyze`

---

### Build Errors on Windows

**Symptom:** CMake errors during build

**Solution:**

1. Install CMake 3.21+ from [cmake.org](https://cmake.org/)
2. Add CMake to PATH (Environment Variables)
3. Restart terminal
4. Run:

```bash
flutter clean
flutter pub get
flutter run -d windows
```

---

### Widget Not Updating

**Symptom:** UI doesn't reflect state changes

**Solution:**

1. **StatefulWidget:** Ensure `setState()` is called:

```dart
onPressed: () {
  setState(() => value = newValue); // ← Required!
}
```

2. **ChangeNotifier:** Ensure `notifyListeners()` is called:

```dart
Future<void> updateData() async {
  _data = await fetchData();
  notifyListeners(); // ← Required!
}
```

3. **Provider:** Ensure listening for changes:

```dart
// Listen to changes (rebuilds on notifyListeners)
Provider.of<Service>(context, listen: true)

// Don't listen (won't rebuild)
Provider.of<Service>(context, listen: false)
```

---

### Firestore Permission Denied

**Symptom:** "PERMISSION_DENIED: Missing or insufficient permissions"

**Solution:**

1. **Development:** Use test mode rules:

```javascript
allow read, write: if true; // ⚠️ Development only!
```

2. **Production:** Use secure rules (see Firebase setup section above)
3. Verify user is authenticated:

```dart
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  print('❌ User not authenticated!');
}
```

---

## Testing

### Manual Testing Checklist

Before submitting changes:

- [ ] Add portfolio group works
- [ ] Delete portfolio group works (swipe-to-dismiss)
- [ ] Submit price pulse works
- [ ] Price Pulse filters update chart/heatmap
- [ ] Dark mode toggle works immediately
- [ ] App doesn't crash on startup
- [ ] No console errors in debug output

### Future: Automated Testing

```bash
# Run unit tests (when implemented)
flutter test

# Run integration tests (when implemented)
flutter test integration_test/
```

---

## Getting Help

### Resources

1. **[PROJECT_MAP.md](PROJECT_MAP.md)** - Component reference, API docs, common tasks
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design, data flow, patterns
3. **[WIDGET_CATALOG.md](WIDGET_CATALOG.md)** - Widget usage examples
4. **[REFACTORING_GUIDE.md](REFACTORING_GUIDE.md)** - Improvement proposals

### External Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Documentation](https://pub.dev/packages/provider)
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)

### Community

- **GitHub Issues:** Report bugs or request features
- **Discussions:** Ask questions (use Discussions, not Issues)

---

## Next Steps

Now that you're set up:

1. **Read [PROJECT_MAP.md](PROJECT_MAP.md)** - Understand the project structure
2. **Read [ARCHITECTURE.md](ARCHITECTURE.md)** - Learn the system design
3. **Explore a feature** - Pick one (Portfolio, Price Pulse, Calculator) and trace the code flow
4. **Make a small change** - Add a console log, change a color, tweak a label
5. **Pick a task** - Look for "good first issue" labels (when available)

**Welcome to the AgriFlow team!** 🚜🐄

---

**Last Updated:** 2025-11-30
**Maintained by:** Development Team
