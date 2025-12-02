# AgriFlow Architecture

## Overview

AgriFlow follows a **layered architecture** with clear separation of concerns. This document explains the system design, data flow patterns, and architectural decisions.

---

## Layered Architecture

```
┌─────────────────────────────────────────────────────┐
│              PRESENTATION LAYER                     │
│         (Screens + Widgets + Theme)                 │
│                                                     │
│  • Renders UI components                           │
│  • Handles user interactions                       │
│  • Displays data from providers                    │
│  • NO direct Firebase access                       │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│          STATE MANAGEMENT LAYER                     │
│              (Providers)                            │
│                                                     │
│  • Manages app-wide state                          │
│  • Notifies listeners of changes                   │
│  • Provides reactive data to UI                    │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│          BUSINESS LOGIC LAYER                       │
│               (Services)                            │
│                                                     │
│  • Executes business operations                    │
│  • Validates data                                  │
│  • Interacts with Firebase                         │
│  • Transforms data for presentation                │
│  • Implements domain rules                         │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                DATA LAYER                           │
│         (Firebase Auth + Firestore)                 │
│                                                     │
│  • Persists data                                   │
│  • Authentication                                  │
│  • Real-time synchronization                       │
│  • Data validation (Firestore rules)               │
└─────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### Presentation Layer

**Location:** `lib/screens/`, `lib/widgets/`, `lib/config/theme.dart`

**Responsibilities:**
- Render UI components using Material Design 3
- Handle user interactions (taps, swipes, form inputs)
- Display data from providers/services
- Navigate between screens
- Show loading states and error messages

**Rules:**
- ✅ Can read from providers/services
- ✅ Can call service methods
- ❌ Cannot directly access Firebase
- ❌ Cannot contain business logic (calculations, validation)
- ❌ Cannot reference BuildContext outside build methods

**Example:**

```dart
class DashboardScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    // Read from provider
    final groups = Provider.of<PortfolioService>(context).groups;

    // Display data (NO business logic here)
    return Scaffold(
      body: ListView(
        children: groups.map((g) => CattleCard(group: g)).toList(),
      ),
    );
  }
}
```

---

### State Management Layer

**Location:** `lib/providers/`

**Responsibilities:**
- Manage app-wide state (theme mode, authentication status)
- Notify listeners when state changes
- Provide reactive data to UI layer
- Persist user preferences

**Implementation:** Provider pattern with ChangeNotifier

**Current Providers:**
1. `ThemeProvider` - Manages light/dark/system theme mode
2. `AuthService` - Authentication state (also a service)
3. `UserPreferencesService` - User settings state (also a service)

**Example:**

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners(); // Triggers UI rebuild
  }
}
```

**Usage in UI:**

```dart
// Listen to changes
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return MaterialApp(
      themeMode: themeProvider.themeMode,
      // ...
    );
  },
)

// Make changes
final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
themeProvider.setThemeMode(ThemeMode.dark);
```

---

### Business Logic Layer

**Location:** `lib/services/`

**Responsibilities:**
- Execute business operations (CRUD, calculations)
- Validate data before persistence
- Interact with Firebase (Auth, Firestore)
- Transform data for presentation
- Implement domain rules (e.g., 95th percentile filtering for Price Pulse)
- Handle errors gracefully

**Rules:**
- ✅ Can access Firebase directly
- ✅ Can extend ChangeNotifier if stateful
- ✅ Can throw exceptions for error handling
- ❌ Cannot import widgets
- ❌ Cannot reference BuildContext

**Services:**
1. `AuthService` - Anonymous authentication
2. `PortfolioService` - Cattle group CRUD
3. `PricePulseService` - Price submissions and analytics
4. `UserPreferencesService` - Settings persistence
5. `PDFExportService` - PDF generation

**Example:**

```dart
class PortfolioService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CattleGroup>> loadGroups() async {
    try {
      // Business logic: fetch, validate, transform
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users/$userId/portfolios')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((d) => CattleGroup.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      print('❌ Error loading groups: $e');
      rethrow;
    }
  }
}
```

---

### Data Layer

**Location:** Firebase (external), `lib/models/` (interfaces)

**Responsibilities:**
- Persist data to Firestore
- Authenticate users
- Provide real-time synchronization
- Enforce data validation via Firestore security rules

**Components:**
- **Firebase Auth:** Anonymous authentication (no email/password)
- **Cloud Firestore:** NoSQL document database with real-time listeners
- **Models:** Dart representations of Firestore documents (serialization)

**Example Model:**

```dart
class CattleGroup {
  final String id;
  final Breed breed;
  final int quantity;

  // Converts to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'breed': breed.name,
      'quantity': quantity,
    };
  }

  // Creates from Firestore document
  factory CattleGroup.fromMap(Map<String, dynamic> map, String id) {
    return CattleGroup(
      id: id,
      breed: Breed.values.byName(map['breed']),
      quantity: map['quantity'] as int,
    );
  }
}
```

---

## Data Flow Patterns

### Read Flow (Display Data)

```
Firestore → Service.loadData() → Provider → Widget → UI
```

**Example: Loading Portfolio**

1. User opens Portfolio screen
2. Screen calls `portfolioService.loadGroups()`
3. Service queries Firestore: `users/{uid}/portfolios`
4. Service converts docs to `List<CattleGroup>`
5. Service returns data to screen
6. Screen displays data in ListView

**Code:**

```dart
// In screen
final portfolioService = Provider.of<PortfolioService>(context);
final groups = await portfolioService.loadGroups();

// In service
Future<List<CattleGroup>> loadGroups() async {
  final snapshot = await _firestore.collection(_getUserPath()).get();
  return snapshot.docs.map((d) => CattleGroup.fromMap(d.data(), d.id)).toList();
}
```

---

### Write Flow (User Action)

```
UI → Widget.onTap → Service.writeData() → Firestore → Real-time listener → UI Update
```

**Example: Adding Cattle Group**

1. User fills out AddGroupSheet
2. User taps "Add Group"
3. Sheet calls `portfolioService.addGroup(group)`
4. Service validates data
5. Service writes to Firestore: `users/{uid}/portfolios`
6. Firestore triggers real-time listener
7. UI automatically updates with new group

**Code:**

```dart
// In widget (AddGroupSheet)
ElevatedButton(
  onPressed: () async {
    final group = CattleGroup(/* ... */);
    await portfolioService.addGroup(group);
    Navigator.pop(context); // Close sheet
  },
  child: Text('Add Group'),
)

// In service
Future<String> addGroup(CattleGroup group) async {
  final docRef = await _firestore
      .collection(_getUserPath())
      .add(group.toMap());
  notifyListeners(); // Notify listeners of change
  return docRef.id;
}
```

---

### Real-Time Updates (StreamBuilder)

```
Firestore → Stream → StreamBuilder → UI (automatic rebuild)
```

**Example: Real-time Portfolio**

```dart
// In service
Stream<List<CattleGroup>> getGroupsStream() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  return _firestore
      .collection('users/$userId/portfolios')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((d) => CattleGroup.fromMap(d.data(), d.id))
          .toList());
}

// In screen
StreamBuilder<List<CattleGroup>>(
  stream: portfolioService.getGroupsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (_, i) => CattleCard(group: snapshot.data![i]),
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

## Authentication Flow

```
App Start → Firebase.initializeApp() → AuthService.signInAnonymously() → User ID generated → User-specific data accessible
```

**Key Points:**
- **Anonymous by design:** No email/password required
- **Persistent:** User ID stored locally, survives app restarts
- **User-specific data:** All Firestore paths include `{userId}`
- **Privacy:** Users can delete account via Settings → Delete All Data

**Implementation:**

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}

// AuthService
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<UserCredential> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('❌ Auth error: $e');
      rethrow;
    }
  }
}
```

---

## Firestore Schema

### Collections & Documents

#### 1. `users/{userId}/portfolios` (Subcollection)

**Purpose:** Store user's cattle groups

**Document Structure:**

```json
{
  "animal_type": "cattle",
  "breed": "charolais",
  "quantity": 30,
  "weight_bucket": "w600_700",
  "desired_price": 4.20,
  "county": "Cork",
  "created_at": Timestamp(2025, 11, 30)
}
```

**Security Rules:**

```javascript
match /users/{userId}/portfolios/{portfolioId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

#### 2. `price_pulses` (Root Collection)

**Purpose:** Anonymous market price submissions (public read, 7-day auto-delete)

**Document Structure:**

```json
{
  "breed": "angus",
  "weight_bucket": "w600_700",
  "price": 4.35,
  "county": "Galway",
  "timestamp": Timestamp(2025, 11, 30),
  "ttl": 604800
}
```

**TTL (Time-To-Live):** Auto-deletes after 7 days via Firestore TTL policy on `ttl` field

**Security Rules:**

```javascript
match /price_pulses/{pulseId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.resource.data.ttl == 604800;
}
```

---

#### 3. `users/{userId}/preferences` (Subcollection)

**Purpose:** User settings (theme, notifications, default county)

**Document Structure:**

```json
{
  "dark_mode": true,
  "notifications": false,
  "default_county": "Cork",
  "rain_alerts": true,
  "holiday_alerts": true,
  "target_date_alerts": true,
  "is_gaeilge": false,
  "updated_at": Timestamp(2025, 11, 30)
}
```

**Security Rules:**

```javascript
match /users/{userId}/preferences {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## State Management Strategy

### When to Use Provider

Use Provider (ChangeNotifier) for:
- **App-wide state:** Theme mode, auth status
- **Expensive operations:** Firebase listeners
- **Shared data:** Multiple screens need same data
- **State that changes over time:** User preferences

**Example:**

```dart
class AuthService extends ChangeNotifier {
  User? _user;

  Future<void> signIn() async {
    _user = await _auth.signInAnonymously();
    notifyListeners(); // All listeners rebuild
  }
}
```

---

### When to Use StatefulWidget

Use local state (setState) for:
- **Local state:** Form inputs, tabs, toggles
- **Temporary data:** Search queries, filters
- **No sharing:** Data only used in one widget
- **Simple counters or flags**

**Example:**

```dart
class CalculatorScreen extends StatefulWidget {
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  double _weight = 600.0; // Local state (not shared)

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _weight,
      onChanged: (value) => setState(() => _weight = value),
    );
  }
}
```

---

### When to Use Streams (StreamBuilder)

Use streams for:
- **Real-time Firestore data:** Portfolio groups, price pulses
- **Firebase Auth state:** Login/logout changes
- **Live updates:** Data that changes while user is viewing

**Example:**

```dart
StreamBuilder<List<CattleGroup>>(
  stream: portfolioService.getGroupsStream(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (_, i) => CattleCard(group: snapshot.data![i]),
      );
    }
    return Text('No data');
  },
)
```

---

## Design Patterns

### 1. Repository Pattern (Services)

**Intent:** Abstract data access behind service interfaces

**Implementation:** Services hide Firebase complexity from UI

**Example:**

```dart
// Good: Service abstracts Firestore
final groups = await portfolioService.loadGroups();

// Bad: Screen directly accesses Firestore
final snapshot = await FirebaseFirestore.instance
  .collection('users/${auth.currentUser!.uid}/portfolios')
  .orderBy('created_at', descending: true)
  .get();
```

---

### 2. Observer Pattern (ChangeNotifier)

**Intent:** Notify UI of state changes automatically

**Implementation:** Provider + ChangeNotifier

**Example:**

```dart
class AuthService extends ChangeNotifier {
  User? _user;

  Future<void> signIn() async {
    _user = await _auth.signInAnonymously();
    notifyListeners(); // All listening widgets rebuild
  }
}
```

---

### 3. Factory Pattern (Model Constructors)

**Intent:** Create objects from different sources (Firestore, JSON, etc.)

**Implementation:** Named factory constructors

**Example:**

```dart
class CattleGroup {
  // Regular constructor
  CattleGroup({required this.breed, required this.quantity});

  // Factory for Firestore
  factory CattleGroup.fromMap(Map<String, dynamic> map, String id) {
    return CattleGroup(
      id: id,
      breed: Breed.values.byName(map['breed']),
      quantity: map['quantity'] as int,
    );
  }

  // Factory for JSON (future: API integration)
  factory CattleGroup.fromJson(Map<String, dynamic> json) {
    return CattleGroup(
      breed: Breed.values.byName(json['breed']),
      quantity: json['quantity'] as int,
    );
  }
}
```

---

## Performance Considerations

### Firestore Optimization

1. **Indexes:** Create composite indexes for common queries
   - Example: `breed + weight_bucket + county` for Price Pulse filters
2. **Pagination:** Use `.limit()` for large collections (not yet implemented)
3. **Caching:** Firestore caches by default (reduces reads)
4. **Real-time listeners:** Only on active screens (avoid memory leaks)

**Example Index (Firestore Console):**

```
Collection: price_pulses
Fields: breed (Ascending), weight_bucket (Ascending), county (Ascending)
```

---

### UI Optimization

1. **Lazy loading:** Use `ListView.builder` for long lists
2. **Keys:** Use `ValueKey(id)` for list items to preserve state
3. **Const constructors:** Mark widgets const when possible
4. **Separate widgets:** Extract to reduce rebuild scope

**Example: Optimized List**

```dart
ListView.builder(
  itemCount: groups.length,
  itemBuilder: (context, index) {
    final group = groups[index];
    return CattleCard(
      key: ValueKey(group.id), // Preserves state on reorder
      group: group,
    );
  },
)
```

---

## Error Handling Strategy

### Service Layer

- **Throw exceptions** for business logic errors
- **Log errors** to console (future: Firebase Crashlytics)
- **Provide context** in error messages

**Example:**

```dart
Future<void> addGroup(CattleGroup group) async {
  try {
    if (group.quantity < 1) {
      throw Exception('Quantity must be at least 1');
    }
    await _firestore.collection(_getUserPath()).add(group.toMap());
  } on FirebaseException catch (e) {
    print('❌ Firestore error: ${e.code} - ${e.message}');
    rethrow;
  } catch (e) {
    print('❌ Unexpected error: $e');
    rethrow;
  }
}
```

---

### UI Layer

- **Catch exceptions** from service calls
- **Show SnackBars** for user-facing errors
- **Fallback UI** for loading/error states

**Example:**

```dart
try {
  await portfolioService.addGroup(group);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Group added successfully!')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## Testing Strategy

### Unit Tests (Recommended)

**Target:** Services, models
**Mock:** Firebase with `fake_cloud_firestore`
**Focus:** Business logic, data transformations

**Example:**

```dart
test('CattleGroup.toMap() serializes correctly', () {
  final group = CattleGroup(breed: Breed.charolais, quantity: 30);
  final map = group.toMap();

  expect(map['breed'], 'charolais');
  expect(map['quantity'], 30);
});
```

---

### Widget Tests (Recommended)

**Target:** Widgets, screens
**Mock:** Services with mocks
**Focus:** UI interactions, state changes

**Example:**

```dart
testWidgets('StatCard displays correct value', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StatCard(
        icon: Icons.inventory,
        label: 'Total',
        value: '150',
      ),
    ),
  );

  expect(find.text('150'), findsOneWidget);
  expect(find.text('Total'), findsOneWidget);
});
```

---

### Integration Tests (Future)

**Target:** Full user flows
**Use:** Firebase Emulator Suite
**Focus:** End-to-end scenarios (add group, submit pulse, export PDF)

---

## Security Considerations

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User must be authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // User can only access their own data
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

    // Price pulses (public read, authenticated write)
    match /price_pulses/{pulseId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.resource.data.ttl == 604800;
    }
  }
}
```

---

## Future Architectural Improvements

### Short-term (v1.1)

- [ ] Add repository layer to abstract Firestore further
- [ ] Implement proper error types (sealed classes or enums)
- [ ] Add logging service (Firebase Crashlytics)
- [ ] Create widget library package for reusability

### Medium-term (v1.5)

- [ ] Add unit tests for services and models
- [ ] Implement pagination for large portfolio lists
- [ ] Add offline persistence (sqflite or Hive)
- [ ] Refactor widgets into categorized folders

### Long-term (v2.0)

- [ ] Consider BLoC or Riverpod for complex state
- [ ] Implement GraphQL API (replace direct Firestore access)
- [ ] Add integration tests with Firebase Emulator
- [ ] Create design system package (shared colors, typography)

---

## Conclusion

AgriFlow's layered architecture provides clear separation of concerns, making it easy to:
- **Understand:** Each layer has a single responsibility
- **Test:** Layers can be tested in isolation
- **Maintain:** Changes in one layer don't affect others
- **Scale:** New features follow existing patterns

For implementation details, see:
- [PROJECT_MAP.md](PROJECT_MAP.md) - Component reference
- [WIDGET_CATALOG.md](WIDGET_CATALOG.md) - UI components
- [ONBOARDING.md](ONBOARDING.md) - Developer setup
- [REFACTORING_GUIDE.md](REFACTORING_GUIDE.md) - Improvement plans

---

**Last Updated:** 2025-11-30
**Maintained by:** Development Team
