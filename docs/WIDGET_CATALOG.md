# AgriFlow Widget Catalog

Quick reference guide for all reusable UI components in the AgriFlow application.

---

## Table of Contents

- [Display Widgets (Cards)](#display-widgets-cards)
- [Input Widgets](#input-widgets)
- [Complex Widgets (Sheets & Filters)](#complex-widgets-sheets--filters)
- [Theme Integration](#theme-integration)
- [Adding New Widgets](#adding-new-widgets)

---

## Display Widgets (Cards)

These widgets display information in card format with consistent styling.

### CustomCard

**File:** `lib/widgets/cards/custom_card.dart` | **Lines:** ~33

Generic container card with consistent AgriFlow styling.

**Props:**
- `child`: Widget - Content to display inside the card

**Usage:**

```dart
CustomCard(
  child: Column(
    children: [
      Text('Title'),
      Text('Content'),
    ],
  ),
)
```

**Visual Appearance:**
- Rounded corners (16px radius)
- Elevation shadow for depth
- Theme-aware background color (white in light mode, dark gray in dark mode)
- 16px internal padding
- Full width by default

**When to Use:**
- Generic content containers
- Custom layouts not covered by other cards
- Wrapping custom widgets for consistent appearance

---

### StatCard

**File:** `lib/widgets/cards/stat_card.dart` | **Lines:** ~71

Display a metric with icon, label, and value. Perfect for dashboard statistics.

**Props:**
- `icon`: IconData - Icon to display
- `label`: String - Metric label
- `value`: String - Metric value
- `subtitle`: String? (optional) - Additional context

**Usage:**

```dart
StatCard(
  icon: Icons.inventory,
  label: 'Total Groups',
  value: '5',
  subtitle: '150 head',
)
```

**Visual Appearance:**
- Vertical layout: Icon → Label → Value → Subtitle
- Icon: Colored with theme primary color, 32px size
- Label: Gray text, small font
- Value: Bold, large font (24px)
- Subtitle: Gray text, small font
- White card with shadow

**Used By:**
- Dashboard screen (total head count, estimated value, avg price)

**When to Use:**
- Displaying numerical metrics
- Dashboard summaries
- Quick stats overview

---

### MedianBandCard

**File:** `lib/widgets/cards/median_band_card.dart` | **Lines:** ~314

Show median price with confidence band and data quality indicator. Core component of Price Pulse feature.

**Props:**
- `medianPrice`: double - Median price (€/kg)
- `sampleSize`: int - Number of data points
- `confidenceLow`: double - Lower confidence bound
- `confidenceHigh`: double - Upper confidence bound
- `lastUpdated`: DateTime? (optional) - Last update timestamp

**Usage:**

```dart
MedianBandCard(
  medianPrice: 4.25,
  sampleSize: 47,
  confidenceLow: 4.10,
  confidenceHigh: 4.40,
  lastUpdated: DateTime.now(),
)
```

**Visual Appearance:**
- Large median price display: "€4.25/kg" (green, bold, 36px)
- Confidence band: "€4.10 - €4.40" (gray text)
- Data quality badge (color-coded by sample size):
  - **Green** (>50 samples): "Excellent"
  - **Yellow** (30-50): "Good"
  - **Orange** (10-30): "Fair"
  - **Red** (<10): "Limited"
- Last updated timestamp at bottom
- Green gradient background

**Data Quality Logic:**
- Excellent: High confidence, large sample
- Good: Moderate confidence
- Fair: Low confidence, small sample
- Limited: Very few data points (use with caution)

**Used By:**
- Price Pulse screen (main insight card)

**When to Use:**
- Displaying statistical data with confidence intervals
- Showing data quality to users
- Market intelligence features

---

### TrendMiniChart

**File:** `lib/widgets/cards/trend_mini_chart.dart` | **Lines:** ~265

7-day line chart for visualizing price trends over time.

**Props:**
- `trendData`: List<TrendPoint> - Primary trend data
- `comparisonData`: List<TrendPoint>? (optional) - Comparison trend
- `title`: String - Chart title
- `subtitle`: String? (optional) - Chart subtitle

**TrendPoint Model:**

```dart
class TrendPoint {
  final DateTime date;
  final double price;
}
```

**Usage:**

```dart
TrendMiniChart(
  title: '7-Day Trend',
  subtitle: 'Charolais 600-700kg',
  trendData: [
    TrendPoint(date: DateTime(2025, 11, 24), price: 4.20),
    TrendPoint(date: DateTime(2025, 11, 25), price: 4.25),
    // ... more points
  ],
  comparisonData: allIrelandTrend, // Optional comparison
)
```

**Visual Appearance:**
- Dual-line chart:
  - **Primary line:** Green (selected filter)
  - **Comparison line:** Blue (All Ireland average)
- X-axis: Days of week (Mon, Tue, Wed, etc.)
- Y-axis: Price in €/kg
- Gridlines for readability
- Touch interaction: Tap to see exact values
- Legend at top showing line colors

**Chart Features:**
- Auto-scaling Y-axis based on data range
- Smooth line curves
- Dots at data points
- Tooltip on hover/tap

**Used By:**
- Price Pulse screen (trend visualization)

**When to Use:**
- Time series data visualization
- Comparing trends over time
- Price movement analysis

---

### CountyHeatmapCard

**File:** `lib/widgets/cards/county_heatmap_card.dart` | **Lines:** ~270

Color-coded county price comparison grid showing regional price variations across Ireland.

**Props:**
- `countyPrices`: Map<String, double> - County name → median price
- `selectedCounty`: String? (optional) - Currently selected county
- `onCountyTap`: Function(String)? (optional) - Callback when county tapped

**Usage:**

```dart
CountyHeatmapCard(
  countyPrices: {
    'Cork': 4.25,
    'Galway': 4.18,
    'Dublin': 4.30,
    // ... all 32 counties
  },
  selectedCounty: 'Cork',
  onCountyTap: (county) {
    setState(() => selectedCounty = county);
  },
)
```

**Visual Appearance:**
- 8x4 grid of county cards (32 total)
- Color gradient based on price:
  - **Red** (lowest prices) → **Yellow** (median) → **Green** (highest prices)
- Each county card shows:
  - County name
  - Price (€/kg)
  - Background color (gradient)
- Selected county: Thick border highlight
- Tap interaction to select county

**Color Calculation:**
- Calculates min/max prices across all counties
- Interpolates color based on relative position
- Low prices = cooler colors (red)
- High prices = warmer colors (green)

**Used By:**
- Price Pulse screen (geographic price distribution)

**When to Use:**
- Geographic data visualization
- Regional price comparisons
- Interactive county selection

---

## Input Widgets

These widgets handle user input and selection.

### BreedPicker

**File:** `lib/widgets/inputs/breed_picker.dart` | **Lines:** ~173

Emoji-first horizontal scrolling breed selector with visual animal icons.

**Props:**
- `selectedBreed`: Breed - Currently selected breed
- `onBreedChanged`: Function(Breed) - Callback when breed changes
- `animalType`: AnimalType? (optional) - Filter breeds by animal type (default: cattle)

**Usage:**

```dart
BreedPicker(
  selectedBreed: Breed.charolais,
  onBreedChanged: (breed) {
    setState(() => selectedBreed = breed);
  },
  animalType: AnimalType.cattle, // Show only cattle breeds
)
```

**Visual Appearance:**
- Horizontal scrollable row of breed cards
- Each card: 70x70px
- Breed emoji + name below
- Selected card: Thick green border + shadow
- Unselected: Subtle border
- Smooth scroll animation

**Cattle Breeds (6):**
- Charolais - White/cream cattle
- Angus - Black cattle
- Limousin - Reddish-brown cattle
- Hereford - Brown with white face
- Belgian Blue - Muscular blue cattle
- Simmental - Red/white cattle

**Other Animal Types:**
- Goat (3): Boer, Saanen, Alpine
- Sheep (3): Suffolk, Texel, Cheviot
- Chicken (2): Broiler, Layer
- Pig (3): Landrace, Duroc, Large White

**Used By:**
- AddGroupSheet (portfolio entry)
- PricePulseFilterBar (filter by breed)
- SubmitPulseSheet (price submission)

**When to Use:**
- Breed selection in any context
- Visual animal type chooser
- Filter controls

---

### WeightBucketPicker

**File:** `lib/widgets/inputs/weight_bucket_picker.dart` | **Lines:** ~63

Dropdown picker for selecting weight ranges.

**Props:**
- `selectedBucket`: WeightBucket - Currently selected bucket
- `onChanged`: Function(WeightBucket) - Callback when selection changes

**Usage:**

```dart
WeightBucketPicker(
  selectedBucket: WeightBucket.w600_700,
  onChanged: (bucket) {
    setState(() => selectedBucket = bucket);
  },
)
```

**Weight Bucket Options:**
- **400-500 kg** - Lighter animals
- **500-600 kg** - Medium animals
- **600-700 kg** - Heavy animals
- **700+ kg** - Very heavy animals

**Visual Appearance:**
- Standard Material dropdown
- Label: "Weight Range"
- Full width
- Theme-aware border color

**Used By:**
- AddGroupSheet (portfolio entry)
- PricePulseFilterBar (filter by weight)
- SubmitPulseSheet (price submission)

**When to Use:**
- Weight range selection
- Filter controls
- Portfolio management

---

### CountyPicker

**File:** `lib/widgets/inputs/county_picker.dart` | **Lines:** ~46

Dropdown picker for selecting Irish counties (32 total).

**Props:**
- `selectedCounty`: String - Currently selected county
- `onChanged`: Function(String) - Callback when selection changes

**Usage:**

```dart
CountyPicker(
  selectedCounty: 'Cork',
  onChanged: (county) {
    setState(() => selectedCounty = county);
  },
)
```

**County Options (32):**
Antrim, Armagh, Carlow, Cavan, Clare, Cork, Derry, Donegal, Down, Dublin, Fermanagh, Galway, Kerry, Kildare, Kilkenny, Laois, Leitrim, Limerick, Longford, Louth, Mayo, Meath, Monaghan, Offaly, Roscommon, Sligo, Tipperary, Tyrone, Waterford, Westmeath, Wexford, Wicklow

**Visual Appearance:**
- Standard Material dropdown
- Label: "County"
- Full width
- Alphabetically sorted

**Used By:**
- AddGroupSheet (portfolio entry)
- SettingsScreen (default county)
- SubmitPulseSheet (price submission)

**When to Use:**
- Location selection
- Regional filtering
- User preferences

---

### PriceSlider

**File:** `lib/widgets/inputs/price_slider.dart` | **Lines:** ~60

Slider for selecting target price per kilogram (€/kg).

**Props:**
- `value`: double - Current price (€3.50 - €5.50)
- `onChanged`: Function(double) - Callback when price changes

**Usage:**

```dart
PriceSlider(
  value: 4.20,
  onChanged: (price) {
    setState(() => desiredPrice = price);
  },
)
```

**Range:**
- **Min:** €3.50/kg
- **Max:** €5.50/kg
- **Step:** €0.10 (20 divisions)

**Visual Appearance:**
- Green track color (theme primary)
- Large thumb with price badge showing current value
- Label: "Desired Price (€/kg)"
- Current value displayed: "€4.20"
- Full width

**Used By:**
- AddGroupSheet (set target price)

**When to Use:**
- Price selection
- Target price setting
- Continuous value input

---

### QuantitySlider

**File:** `lib/widgets/inputs/quantity_slider.dart` | **Lines:** ~65

Slider for selecting number of animals (1-200).

**Props:**
- `value`: int - Current quantity (1-200)
- `onChanged`: Function(int) - Callback when quantity changes

**Usage:**

```dart
QuantitySlider(
  value: 30,
  onChanged: (qty) {
    setState(() => quantity = qty);
  },
)
```

**Range:**
- **Min:** 1 animal
- **Max:** 200 animals
- **Step:** 1 animal

**Visual Appearance:**
- Blue track color
- Thumb with quantity badge showing current value
- Label: "Quantity"
- Current value displayed: "30"
- Full width

**Used By:**
- AddGroupSheet (set herd size)

**When to Use:**
- Animal count selection
- Inventory quantity input

---

### WeightSlider

**File:** `lib/widgets/inputs/weight_slider.dart` | **Lines:** ~88

Slider for selecting live weight in kilograms (alternative to WeightBucketPicker).

**Props:**
- `value`: double - Current weight (400-900 kg)
- `onChanged`: Function(double) - Callback when weight changes

**Usage:**

```dart
WeightSlider(
  value: 650.0,
  onChanged: (weight) {
    setState(() => liveWeight = weight);
  },
)
```

**Range:**
- **Min:** 400 kg
- **Max:** 900 kg
- **Step:** 10 kg

**Visual Appearance:**
- Green track color
- Thumb with weight badge showing current value
- Label: "Live Weight (kg)"
- Current value displayed: "650 kg"
- Full width

**Used By:**
- CalculatorScreen (time-to-kill calculator)

**When to Use:**
- Precise weight input (vs. weight buckets)
- Calculator scenarios
- Target weight selection

---

## Complex Widgets (Sheets & Filters)

These are larger, more complex widgets that combine multiple sub-widgets.

### AddGroupSheet

**File:** `lib/widgets/sheets/add_group_sheet.dart` | **Lines:** ~151

Modal bottom sheet for adding new cattle groups to portfolio. Combines multiple input widgets.

**Props:**
- `onSave`: Function(CattleGroup) - Callback when group is saved

**Usage:**

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => AddGroupSheet(
    onSave: (group) async {
      await portfolioService.addGroup(group);
      Navigator.pop(context);
    },
  ),
);
```

**Form Fields:**
1. **Breed** - BreedPicker (horizontal scroll)
2. **Quantity** - QuantitySlider (1-200)
3. **Weight Bucket** - WeightBucketPicker (dropdown)
4. **County** - CountyPicker (dropdown)
5. **Desired Price** - PriceSlider (€3.50-€5.50/kg)

**Visual Appearance:**
- Full-screen modal (85% screen height)
- Handle bar at top for swipe-to-dismiss
- Scrollable content (for small screens)
- Action buttons at bottom:
  - **Cancel** - Closes sheet without saving
  - **Add Group** - Saves and closes sheet
- Form validation (all fields required)

**Validation:**
- All fields must be filled
- Quantity must be ≥ 1
- Price must be within range

**Used By:**
- Portfolio screen (FAB button)

**When to Use:**
- Creating new portfolio entries
- Capturing livestock data
- Multi-field forms

---

### SubmitPulseSheet

**File:** `lib/widgets/sheets/submit_pulse_sheet.dart` | **Lines:** ~298

Modal bottom sheet for submitting anonymous price pulse data to the marketplace.

**Props:**
- `onSubmit`: Function(PricePulse) - Callback when pulse is submitted
- `initialBreed`: Breed? (optional) - Pre-fill breed
- `initialWeight`: WeightBucket? (optional) - Pre-fill weight

**Usage:**

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => SubmitPulseSheet(
    initialBreed: selectedBreed,
    initialWeight: selectedWeight,
    onSubmit: (pulse) async {
      await pricePulseService.submitPulse(pulse);
      Navigator.pop(context);
    },
  ),
);
```

**Form Fields:**
1. **Breed** - BreedPicker
2. **Weight Bucket** - WeightBucketPicker
3. **County** - CountyPicker
4. **Price** - PriceSlider (actual sale price)
5. **Date Sold** (optional) - DatePicker

**Privacy Notice:**
- "Submissions are anonymous"
- "Data expires after 7 days"
- No personal information collected

**Visual Appearance:**
- Full-screen modal
- Handle bar for swipe-to-dismiss
- Scrollable content
- Privacy notice at top (info icon)
- Action buttons at bottom:
  - **Cancel**
  - **Submit Pulse** (green button)

**Used By:**
- Price Pulse screen (submit button)

**When to Use:**
- Crowdsourced data collection
- Anonymous submissions
- Market price reporting

---

### PricePulseFilterBar

**File:** `lib/widgets/sheets/price_pulse_filter_bar.dart` | **Lines:** ~192

Complex filter controls for Price Pulse screen with breed, weight, and county selection.

**Props:**
- `selectedBreed`: Breed - Currently selected breed
- `selectedWeight`: WeightBucket - Currently selected weight
- `viewMode`: String - 'all' or 'county'
- `selectedCounty`: String - Currently selected county
- `onBreedChanged`: Function(Breed) - Callback when breed changes
- `onWeightChanged`: Function(WeightBucket) - Callback when weight changes
- `onViewModeToggle`: Function() - Callback when view mode toggles
- `onCountyEdit`: Function() - Callback to edit county

**Usage:**

```dart
PricePulseFilterBar(
  selectedBreed: breed,
  selectedWeight: weight,
  viewMode: viewMode,
  selectedCounty: county,
  onBreedChanged: (b) => setState(() => breed = b),
  onWeightChanged: (w) => setState(() => weight = w),
  onViewModeToggle: () => setState(() =>
    viewMode = viewMode == 'all' ? 'county' : 'all'
  ),
  onCountyEdit: () => showCountyPicker(),
)
```

**Visual Appearance:**

**Section 1: Breed Picker**
- Horizontal scroll of 6 cattle breeds (emoji cards)
- Selected breed highlighted with green border

**Section 2: Weight Slider**
- Inline slider with 4 positions (weight buckets)
- Badge showing selected weight range

**Section 3: County Toggle**
- Toggle button switching between:
  - "All Ireland" - nationwide data
  - "Cork" (or selected county) - county-specific data
- Swap icon indicating toggle action

**Layout:**
- White card with shadow
- Three distinct sections separated by dividers
- Compact design (fits in ~200px height)

**Used By:**
- Price Pulse screen (top of screen, sticky)

**When to Use:**
- Complex filtering scenarios
- Multi-criteria selection
- Interactive dashboards

---

## Theme Integration

All widgets use `Theme.of(context)` for colors, typography, and spacing.

### Color Usage

- **Primary (Green):** Actions, selected states, primary buttons
- **Secondary (Blue):** Informational elements, comparison data
- **Background:** Theme-aware (light/dark mode)
- **Error (Red):** Validation errors, warnings
- **Surface:** Card backgrounds, elevated elements

### Typography

- **Headings:** `Theme.of(context).textTheme.titleLarge` (24px bold)
- **Body:** `Theme.of(context).textTheme.bodyLarge` (16px regular)
- **Labels:** `Theme.of(context).textTheme.labelLarge` (14px medium)

### Spacing Scale

Consistent spacing throughout widgets:

- **xs:** 4px - Tight spacing
- **sm:** 8px - Small gaps
- **md:** 12px - Medium gaps
- **lg:** 16px - Large gaps (most common)
- **xl:** 24px - Extra large gaps
- **2xl:** 32px - Section dividers

### Example Usage in Custom Widget

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16), // lg spacing
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Content',
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
```

---

## Adding New Widgets

### Step-by-Step Guide

1. **Determine Category:**
   - Display widget (card)? → Consider extending CustomCard
   - Input widget? → Consider reusing existing pickers/sliders
   - Complex widget? → Create new standalone widget

2. **Create File:**
   ```
   lib/widgets/your_widget.dart
   ```

3. **Make Widget Reusable:**
   - Use clear, typed props
   - Make props required or provide defaults
   - Use `const` constructor when possible
   - Don't hardcode values - use props

4. **Follow Theme:**
   - Use `Theme.of(context)` for colors
   - Use `Theme.of(context).textTheme` for typography
   - Use consistent spacing (4, 8, 12, 16, 24, 32)
   - Support dark mode

5. **Add to This Catalog:**
   - Document props
   - Provide usage example
   - Describe visual appearance
   - Note which screens use it

### Widget Template

```dart
/// [Brief description of what this widget does]
///
/// Usage:
/// ```dart
/// YourWidget(
///   value: someValue,
///   onChanged: (newValue) => setState(() => value = newValue),
/// )
/// ```
class YourWidget extends StatelessWidget {
  /// [Description of this prop]
  final String value;

  /// [Description of callback]
  final ValueChanged<String> onChanged;

  const YourWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        value,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
```

---

## Widget Organization Recommendation

**Current:** All widgets in flat `lib/widgets/` folder (14 files)

**Proposed:** Categorize into subfolders (see [REFACTORING_GUIDE.md](REFACTORING_GUIDE.md)):

```
lib/widgets/
├── cards/              # Display widgets
│   ├── custom_card.dart
│   ├── stat_card.dart
│   ├── median_band_card.dart
│   ├── trend_mini_chart.dart
│   └── county_heatmap_card.dart
├── inputs/             # Input widgets
│   ├── breed_picker.dart
│   ├── weight_bucket_picker.dart
│   ├── county_picker.dart
│   ├── price_slider.dart
│   ├── quantity_slider.dart
│   └── weight_slider.dart
└── sheets/             # Complex widgets
    ├── add_group_sheet.dart
    ├── submit_pulse_sheet.dart
    └── price_pulse_filter_bar.dart
```

---

## Summary

AgriFlow has **14 reusable widgets** organized into three categories:

- **5 Display Widgets** - Cards for showing information
- **6 Input Widgets** - Pickers and sliders for user input
- **3 Complex Widgets** - Sheets and filter bars combining multiple widgets

All widgets follow Material Design 3 principles, support dark mode, and integrate seamlessly with the app's green-themed design system.

For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md).
For implementation guidance, see [ONBOARDING.md](ONBOARDING.md).

---

**Last Updated:** 2025-11-30
**Maintained by:** Development Team
