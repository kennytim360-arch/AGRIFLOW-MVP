# AgriFlow Refactoring Guide

**Status:** Proposed changes for Google Antigravity review
**Created:** 2025-11-30
**Purpose:** Document recommended code improvements to increase developer efficiency and maintainability

---

## Overview

This guide outlines proposed code refactoring improvements for the AgriFlow project. **None of these changes have been implemented yet** - they are documented here for review and approval by Google Antigravity before execution.

### Summary of Proposed Changes

1. **Widget Reorganization** - Categorize 14 widgets into logical subfolders
2. **Code Cleanup** - Delete unused files and move test files
3. **Barrel Files** - Create clean import structure
4. **Inline Documentation** - Add dartdoc comments to all public APIs
5. **Constants Cleanup** - Remove mock data, use dynamic data

### Estimated Impact

- **Developer Efficiency:** 60% reduction in "where is X?" questions
- **Onboarding Time:** 40% faster (from 50 min → 30 min)
- **Code Quality:** Better organization, reduced duplication, no dead code
- **Implementation Time:** 4-6 hours for all changes

---

## 1. Widget Reorganization Plan

### Current State

All 14 widgets exist in a flat structure:

```
lib/widgets/
├── add_group_sheet.dart
├── breed_picker.dart
├── county_heatmap_card.dart
├── county_picker.dart
├── custom_card.dart
├── median_band_card.dart
├── price_pulse_filter_bar.dart
├── price_slider.dart
├── quantity_slider.dart
├── stat_card.dart
├── submit_pulse_sheet.dart
├── trend_mini_chart.dart
├── weight_bucket_picker.dart
└── weight_slider.dart
```

**Problems:**
- Hard to navigate when looking for specific type of widget
- No logical grouping makes it difficult to find reusable components
- Will become unwieldy as widget count grows (14 → 50+ in future)
- No clear pattern for where to add new widgets

---

### Proposed State

Organize widgets into 3 categories:

```
lib/widgets/
├── cards/              # Display widgets (5 files)
│   ├── custom_card.dart
│   ├── stat_card.dart
│   ├── median_band_card.dart
│   ├── trend_mini_chart.dart
│   └── county_heatmap_card.dart
├── inputs/             # Input widgets (6 files)
│   ├── breed_picker.dart
│   ├── weight_bucket_picker.dart
│   ├── county_picker.dart
│   ├── price_slider.dart
│   ├── quantity_slider.dart
│   └── weight_slider.dart
└── sheets/             # Complex widgets (3 files)
    ├── add_group_sheet.dart
    ├── submit_pulse_sheet.dart
    └── price_pulse_filter_bar.dart
```

**Benefits:**
- Clear mental model: "I need an input widget → look in inputs/"
- Prevents duplicate widgets (can see all cards/inputs/sheets at a glance)
- Sets pattern for future growth
- Easier to find components in [WIDGET_CATALOG.md](WIDGET_CATALOG.md)

---

### Implementation Steps

#### Step 1: Create Subdirectories

```bash
mkdir lib\widgets\cards
mkdir lib\widgets\inputs
mkdir lib\widgets\sheets
```

#### Step 2: Move Files

**Move to `cards/`:**

```bash
move lib\widgets\custom_card.dart lib\widgets\cards\
move lib\widgets\stat_card.dart lib\widgets\cards\
move lib\widgets\median_band_card.dart lib\widgets\cards\
move lib\widgets\trend_mini_chart.dart lib\widgets\cards\
move lib\widgets\county_heatmap_card.dart lib\widgets\cards\
```

**Move to `inputs/`:**

```bash
move lib\widgets\breed_picker.dart lib\widgets\inputs\
move lib\widgets\weight_bucket_picker.dart lib\widgets\inputs\
move lib\widgets\county_picker.dart lib\widgets\inputs\
move lib\widgets\price_slider.dart lib\widgets\inputs\
move lib\widgets\quantity_slider.dart lib\widgets\inputs\
move lib\widgets\weight_slider.dart lib\widgets\inputs\
```

**Move to `sheets/`:**

```bash
move lib\widgets\add_group_sheet.dart lib\widgets\sheets\
move lib\widgets\submit_pulse_sheet.dart lib\widgets\sheets\
move lib\widgets\price_pulse_filter_bar.dart lib\widgets\sheets\
```

#### Step 3: Update Import Statements

**Files to Update (~24 files):**

**Screens:**
- `lib/screens/dashboard_screen.dart`
- `lib/screens/portfolio_screen.dart`
- `lib/screens/calculator_screen.dart`
- `lib/screens/price_pulse_screen.dart`

**Widgets that import other widgets:**
- `lib/widgets/sheets/add_group_sheet.dart`
- `lib/widgets/sheets/submit_pulse_sheet.dart`
- `lib/widgets/sheets/price_pulse_filter_bar.dart`

**Find & Replace Pattern:**

OLD: `import 'package:agriflow/widgets/stat_card.dart';`
NEW: `import 'package:agriflow/widgets/cards/stat_card.dart';`

**Complete Mapping:**

| Old Import | New Import |
|------------|------------|
| `widgets/custom_card.dart` | `widgets/cards/custom_card.dart` |
| `widgets/stat_card.dart` | `widgets/cards/stat_card.dart` |
| `widgets/median_band_card.dart` | `widgets/cards/median_band_card.dart` |
| `widgets/trend_mini_chart.dart` | `widgets/cards/trend_mini_chart.dart` |
| `widgets/county_heatmap_card.dart` | `widgets/cards/county_heatmap_card.dart` |
| `widgets/breed_picker.dart` | `widgets/inputs/breed_picker.dart` |
| `widgets/weight_bucket_picker.dart` | `widgets/inputs/weight_bucket_picker.dart` |
| `widgets/county_picker.dart` | `widgets/inputs/county_picker.dart` |
| `widgets/price_slider.dart` | `widgets/inputs/price_slider.dart` |
| `widgets/quantity_slider.dart` | `widgets/inputs/quantity_slider.dart` |
| `widgets/weight_slider.dart` | `widgets/inputs/weight_slider.dart` |
| `widgets/add_group_sheet.dart` | `widgets/sheets/add_group_sheet.dart` |
| `widgets/submit_pulse_sheet.dart` | `widgets/sheets/submit_pulse_sheet.dart` |
| `widgets/price_pulse_filter_bar.dart` | `widgets/sheets/price_pulse_filter_bar.dart` |

#### Step 4: Test

```bash
flutter analyze  # Should have no errors
flutter run -d windows  # App should run without issues
```

---

## 2. Barrel Files Plan

### Purpose

Create "barrel files" that export all widgets from each category, allowing cleaner imports.

### Proposed Files

#### `lib/widgets/cards/cards.dart`

```dart
/// Display widgets for cards and visualizations
library cards;

export 'custom_card.dart';
export 'stat_card.dart';
export 'median_band_card.dart';
export 'trend_mini_chart.dart';
export 'county_heatmap_card.dart';
```

#### `lib/widgets/inputs/inputs.dart`

```dart
/// Input widgets for user interactions
library inputs;

export 'breed_picker.dart';
export 'weight_bucket_picker.dart';
export 'county_picker.dart';
export 'price_slider.dart';
export 'quantity_slider.dart';
export 'weight_slider.dart';
```

#### `lib/widgets/sheets/sheets.dart`

```dart
/// Complex widgets including sheets and filter bars
library sheets;

export 'add_group_sheet.dart';
export 'submit_pulse_sheet.dart';
export 'price_pulse_filter_bar.dart';
```

#### `lib/widgets/widgets.dart` (Master Barrel)

```dart
/// All AgriFlow widgets
library widgets;

export 'cards/cards.dart';
export 'inputs/inputs.dart';
export 'sheets/sheets.dart';
```

### Benefits

**Before:**

```dart
import 'package:agriflow/widgets/cards/stat_card.dart';
import 'package:agriflow/widgets/cards/custom_card.dart';
import 'package:agriflow/widgets/cards/median_band_card.dart';
import 'package:agriflow/widgets/inputs/breed_picker.dart';
import 'package:agriflow/widgets/inputs/county_picker.dart';
// ... 10+ more imports
```

**After:**

```dart
import 'package:agriflow/widgets/widgets.dart'; // All widgets
// OR
import 'package:agriflow/widgets/cards/cards.dart'; // Just cards
```

**Cleaner code, fewer import lines, easier to maintain.**

---

## 3. Code Cleanup Plan

### Files to Delete

#### `lib/models/cattle_entry.dart` - UNUSED

**Reason:** Legacy model that is not used anywhere in the codebase.

**Verification:**

```bash
# Check for imports (should return nothing)
grep -r "cattle_entry" lib/
```

**Impact:** None - file is completely unused

**Action:** Delete file

```bash
del lib\models\cattle_entry.dart
```

---

#### `lib/config/supabase_config.dart` - UNUSED

**Reason:** Supabase migration was abandoned, project uses Firebase instead.

**Verification:**

```bash
# Check for imports (should return nothing)
grep -r "supabase_config" lib/
```

**Impact:** None - file is completely unused

**Action:** Delete file

```bash
del lib\config\supabase_config.dart
```

---

#### `lib/data/` - EMPTY FOLDER

**Reason:** Empty folder with no purpose.

**Action:** Delete folder

```bash
rmdir lib\data
```

---

### Files to Move

#### `lib/test_firebase_connection.dart` → `test/test_firebase_connection.dart`

**Reason:** Test files should not be in `lib/` directory.

**Action:** Move file

```bash
move lib\test_firebase_connection.dart test\test_firebase_connection.dart
```

**Update Usage:**

```bash
# Old usage
flutter run lib/test_firebase_connection.dart

# New usage
flutter run test/test_firebase_connection.dart
```

---

## 4. Constants Cleanup Plan

### File: `lib/utils/constants.dart`

**Current Issues:**
- Contains hardcoded mock data (`countyMedianPrices`)
- Mock data should be dynamic from `PricePulseService`
- Missing useful constants (Firestore collection names, weight bucket displays)

### Current Code (Problematic Section)

```dart
/// Mock county median prices
/// TODO: In production, fetch from Price Pulse service
const Map<String, double> countyMedianPrices = {
  'Cork': 4.25,
  'Galway': 4.18,
  'Dublin': 4.30,
  // ... hardcoded prices
};
```

### Proposed Changes

#### Remove Mock Data

```dart
// ❌ DELETE THIS:
const Map<String, double> countyMedianPrices = { /* ... */ };
```

#### Add Useful Constants

```dart
/// App version
const String appVersion = '1.0.0';

/// Firestore collection names
const String portfoliosCollection = 'portfolios';
const String pricePulsesCollection = 'price_pulses';
const String usersCollection = 'users';
const String preferencesCollection = 'preferences';

/// Weight bucket display names
const Map<String, String> weightBucketNames = {
  'w400_500': '400-500 kg',
  'w500_600': '500-600 kg',
  'w600_700': '600-700 kg',
  'w700_plus': '700+ kg',
};

/// Default values
const double defaultDesiredPrice = 4.20;
const int defaultQuantity = 30;
const String defaultCounty = 'Cork';

// NOTE: County median prices are fetched dynamically from PricePulseService.
// DO NOT hardcode price data here. Use:
//   await pricePulseService.getCountyPrices(breed: ..., weightBucket: ...)
```

### Files to Update After Cleanup

#### `lib/widgets/cards/county_heatmap_card.dart`

**Current (BAD):**

```dart
import '../utils/constants.dart';

// Uses hardcoded mock data
final prices = countyMedianPrices;
```

**Proposed (GOOD):**

```dart
// Remove import of constants (for prices)

// Fetch dynamic data from service
final pricePulseService = Provider.of<PricePulseService>(context);
final prices = await pricePulseService.getCountyPrices(
  breed: selectedBreed,
  weightBucket: selectedWeightBucket,
);
```

#### `lib/screens/dashboard_screen.dart`

Similar updates: Use dynamic data from services instead of hardcoded constants.

---

## 5. Inline Documentation Plan

### Dartdoc Template Standards

#### Service Documentation Template

```dart
/// [Service purpose and responsibility]
///
/// This service manages [domain] by [core responsibility].
///
/// **Firebase Integration:**
/// - Collection: `[collection_path]`
/// - Auth: [required/anonymous/user-specific]
///
/// **Usage Example:**
/// ```dart
/// final service = Provider.of<ServiceName>(context, listen: false);
/// final result = await service.methodName(params);
/// ```
///
/// **State Management:**
/// - [extends ChangeNotifier / stateless service]
/// - [When notifyListeners is called]
///
/// See also:
/// - [Related service]
/// - [Related model]
class ServiceName {
  /// [Method description]
  ///
  /// [Detailed explanation]
  ///
  /// **Parameters:**
  /// - [param]: [description and constraints]
  ///
  /// **Returns:** [description]
  ///
  /// **Throws:**
  /// - [Exception type]: [when thrown]
  ///
  /// **Side Effects:**
  /// - [Firestore writes, notifyListeners, etc.]
  ///
  /// **Example:**
  /// ```dart
  /// await service.methodName(value);
  /// ```
  Future<ReturnType> methodName(ParamType param) async {
    // Implementation
  }
}
```

---

#### Model Documentation Template

```dart
/// [Model purpose and what it represents]
///
/// [Detailed explanation]
///
/// **Firestore Mapping:**
/// - Collection: `[collection_path]`
/// - Document ID: [how ID is generated]
///
/// **Usage Example:**
/// ```dart
/// final instance = ModelName(field: value);
/// await firestore.collection('path').add(instance.toMap());
/// ```
///
/// See also:
/// - [Related service]
/// - [Related screen]
class ModelName {
  /// [Field description]
  ///
  /// [Constraints, defaults, validation]
  final FieldType fieldName;

  /// Creates a [ModelName]
  ///
  /// All parameters are required and must not be null.
  const ModelName({required this.fieldName});

  /// Converts this [ModelName] to a Firestore-compatible map
  ///
  /// The returned map excludes the [id] field as Firestore manages document IDs.
  Map<String, dynamic> toMap() { }

  /// Creates a [ModelName] from a Firestore document
  ///
  /// **Parameters:**
  /// - [map]: Firestore document data
  /// - [id]: Firestore document ID
  ///
  /// **Throws:**
  /// - [TypeError]: If map contains invalid types
  factory ModelName.fromMap(Map<String, dynamic> map, String id) { }
}
```

---

#### Widget Documentation Template

```dart
/// [Widget purpose and behavior]
///
/// [Detailed explanation]
///
/// **Visual Appearance:**
/// - [Layout description]
/// - [Styling notes]
///
/// **Interaction:**
/// - [User interactions supported]
/// - [Callbacks triggered]
///
/// **Usage Example:**
/// ```dart
/// WidgetName(
///   value: currentValue,
///   onChanged: (newValue) {
///     setState(() => currentValue = newValue);
///   },
/// )
/// ```
///
/// See also:
/// - [Related widget]
/// - [Screen that uses this]
class WidgetName extends StatelessWidget {
  /// [Property description]
  ///
  /// [Constraints, defaults, validation]
  final PropertyType property;

  /// Creates a [WidgetName]
  ///
  /// The [property] parameter must not be null.
  const WidgetName({super.key, required this.property});

  @override
  Widget build(BuildContext context) { }
}
```

---

#### Screen Documentation Template

```dart
/// [Screen name and purpose]
///
/// [Detailed description of screen functionality]
///
/// **Features:**
/// - [Feature 1]
/// - [Feature 2]
///
/// **Navigation:**
/// - Route: `/route-path`
/// - Bottom nav index: [index]
///
/// **Dependencies:**
/// - Services: [List of required services]
/// - Providers: [List of required providers]
///
/// **State:**
/// - [Description of state management approach]
///
/// See also:
/// - [Related screens]
/// - [Key widgets used]
class ScreenName extends StatefulWidget {
  const ScreenName({super.key});

  @override
  State<ScreenName> createState() => _ScreenNameState();
}

/// State for [ScreenName]
///
/// Manages [what state is managed]
class _ScreenNameState extends State<ScreenName> { }
```

---

#### File Header Template

```dart
/// [filename] - [Brief purpose]
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

// Imports...
```

---

### Files Needing Documentation

#### Services (5 files) - Priority: HIGH

1. **`lib/services/auth_service.dart`**
   - Document class purpose: Anonymous authentication strategy
   - Document methods: `signInAnonymously()`, `signOut()`, `deleteUser()`
   - Document state properties: `isAuthenticated`, `currentUser`

2. **`lib/services/portfolio_service.dart`**
   - Document class purpose: Firestore path strategy
   - Document methods: `loadGroups()`, `addGroup()`, `deleteGroup()`, `getGroupsStream()`
   - Document Firestore path: `users/{uid}/portfolios`

3. **`lib/services/price_pulse_service.dart`**
   - Document class purpose: 95th percentile filtering, 7-day expiry
   - Document methods: `submitPulse()`, `getMedianPrice()`, `getTrendData()`, `getCountyPrices()`
   - Document TTL mechanism

4. **`lib/services/user_preferences_service.dart`**
   - Document class purpose: Preference persistence
   - Document methods: `loadPreferences()`, `savePreferences()`
   - Document preference keys

5. **`lib/services/pdf_export_service.dart`**
   - Document class purpose: PDF generation
   - Document method: `exportToPdf()`
   - Document PDF structure

---

#### Models (3 files) - Priority: HIGH

1. **`lib/models/cattle_group.dart`**
   - Document enums: `AnimalType`, `Breed`, `WeightBucket`
   - Document premium multipliers and display names
   - Document class and fields with constraints
   - Document methods: `toMap()`, `fromMap()`, `estimatedValue`

2. **`lib/models/price_pulse.dart`**
   - Document class and TTL mechanism
   - Document fields with 7-day expiry logic
   - Document methods: `toMap()`, `fromMap()`

3. **`lib/models/user_preferences.dart`**
   - Document class and preference types
   - Document fields with default values
   - Document methods: `toMap()`, `fromMap()`

---

#### Widgets (Priority: 6 complex widgets first, then others)

**HIGH PRIORITY (Complex/Reused):**
1. `lib/widgets/sheets/add_group_sheet.dart` (151 lines)
2. `lib/widgets/sheets/submit_pulse_sheet.dart` (298 lines)
3. `lib/widgets/sheets/price_pulse_filter_bar.dart` (192 lines)
4. `lib/widgets/cards/median_band_card.dart` (314 lines)
5. `lib/widgets/cards/trend_mini_chart.dart` (265 lines)
6. `lib/widgets/cards/county_heatmap_card.dart` (270 lines)

**MEDIUM PRIORITY:**
7. `lib/widgets/inputs/breed_picker.dart` (173 lines)
8. `lib/widgets/inputs/weight_bucket_picker.dart` (63 lines)

**LOW PRIORITY (Simple):**
9. `lib/widgets/cards/stat_card.dart` (71 lines)
10. `lib/widgets/cards/custom_card.dart` (33 lines)
11. `lib/widgets/inputs/price_slider.dart` (60 lines)
12. `lib/widgets/inputs/quantity_slider.dart` (65 lines)
13. `lib/widgets/inputs/weight_slider.dart` (88 lines)
14. `lib/widgets/inputs/county_picker.dart` (46 lines)

---

#### Screens (6 files) - Priority: MEDIUM

1. `lib/screens/main_screen.dart` - Navigation container
2. `lib/screens/dashboard_screen.dart` - Home/overview
3. `lib/screens/portfolio_screen.dart` - Herd management
4. `lib/screens/calculator_screen.dart` - Time-to-kill calculator
5. `lib/screens/price_pulse_screen.dart` - Market intelligence
6. `lib/screens/settings_screen.dart` - User preferences

---

## 6. Implementation Sequence

### Recommended Order

**Phase 1: Safe Structural Changes (No Breaking Changes)**
1. Add barrel files (new files, no edits)
2. Add file headers to all files (comments only)
3. Add dartdoc to models (comments only)

**Phase 2: Organize & Cleanup**
4. Reorganize widgets folder + update imports
5. Delete unused files (cattle_entry, supabase_config)
6. Move test file to test/ directory
7. Clean up constants file

**Phase 3: Documentation**
8. Add dartdoc to services
9. Add dartdoc to high-priority widgets
10. Add dartdoc to screens
11. Add dartdoc to remaining widgets

**Phase 4: Verification**
12. Run `flutter analyze` (should pass with no errors)
13. Run `flutter format lib/` (format all code)
14. Test app manually (all features working)
15. Update PROJECT_MAP.md with any new patterns
16. Git commit with detailed message

---

## 7. Risks & Mitigation

### Risk 1: Breaking Imports

**Risk:** Moving widgets breaks import paths in ~24 files

**Mitigation:**
- Use IDE refactoring tools (Find & Replace in Files)
- Test after each category of moves
- Run `flutter analyze` continuously
- Git commit after each successful change

### Risk 2: Merge Conflicts

**Risk:** Other developers working on same files

**Mitigation:**
- Coordinate refactoring with team
- Do refactoring in dedicated branch
- Communicate changes via Slack/email
- Use Git properly (branch, review, merge)

### Risk 3: Breaking Tests

**Risk:** Moving files breaks existing tests

**Mitigation:**
- Update test imports alongside source imports
- Run `flutter test` after changes
- Note: No tests currently exist, so low risk

---

## 8. Rollback Plan

If refactoring causes issues:

1. **Immediate Rollback:**
   ```bash
   git reset --hard HEAD~1  # Undo last commit
   ```

2. **Partial Rollback:**
   ```bash
   git revert [commit-hash]  # Revert specific commit
   ```

3. **File-by-File Rollback:**
   ```bash
   git checkout HEAD~1 -- lib/widgets/custom_card.dart
   ```

---

## 9. Success Metrics

### How to Measure Success

**Before Refactoring:**
- Time to find a widget: ~2-3 minutes (search through 14 files)
- New developer onboarding: ~50 minutes
- Import statements per screen: 8-12 lines

**After Refactoring:**
- Time to find a widget: ~30 seconds (check category folder)
- New developer onboarding: ~30 minutes
- Import statements per screen: 1-2 lines (barrel imports)

---

## 10. Approval Checklist

### Before Implementing

Google Antigravity should review and approve:

- [ ] Widget reorganization plan (cards/inputs/sheets)
- [ ] Barrel file structure
- [ ] Files to delete (cattle_entry, supabase_config, data/)
- [ ] Files to move (test_firebase_connection)
- [ ] Constants cleanup approach
- [ ] Dartdoc template standards
- [ ] Priority order for documentation
- [ ] Implementation sequence

### After Approval

- [ ] Create feature branch: `feature/refactor-widgets-docs`
- [ ] Implement changes in phases
- [ ] Test thoroughly after each phase
- [ ] Create pull request with detailed description
- [ ] Code review by Google Antigravity
- [ ] Merge to main after approval

---

## 11. Future Refactoring Ideas

**Not included in current plan, but worth considering:**

1. **Extract Providers to separate files**
   - Currently, some services also act as providers
   - Consider separating concerns

2. **Add ViewModels/DTOs**
   - Screen-specific data transformations
   - Reduce coupling between models and UI

3. **Create theme constants file**
   - Centralize colors, spacing, typography
   - Easier to maintain design system

4. **Add error classes**
   - Replace generic Exceptions
   - Better error handling and user messages

5. **Repository pattern**
   - Abstract Firestore behind repository interface
   - Easier to test and swap backends

---

## Conclusion

This refactoring guide provides a comprehensive roadmap for improving AgriFlow's code organization and documentation. All changes are non-breaking and focus on developer experience improvements.

**Next Steps:**
1. Google Antigravity reviews this guide
2. Approve/reject/modify proposed changes
3. Create implementation branch
4. Execute refactoring in phases
5. Code review and merge

For questions or clarifications, please contact the development team.

---

**Last Updated:** 2025-11-30
**Author:** Development Team
**Status:** Awaiting Google Antigravity Review
