# AgriFlow 🐄

A Flutter-based cattle portfolio management and market price tracking app for Irish farmers.

## Features

- 📊 **Dashboard**: Real-time overview of your herd value and market insights
- 🐮 **Portfolio**: Manage your cattle groups with detailed tracking
- 🧮 **Calculator**: Time-to-Kill calculator with interactive sliders
- 📈 **Price Pulse**: Anonymous market price submissions and trends
- ⚙️ **Settings**: Dark mode, data management, and privacy controls

## Tech Stack

- **Frontend**: Flutter (Windows, Android, iOS, Web)
- **Backend**: Firebase (Firestore + Anonymous Auth)
- **State Management**: Provider
- **Charts**: fl_chart
- **UI**: Material Design 3 with custom "Jet Black" theme

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.1)
- Firebase account
- For Windows: CMake 3.21+ (for Firebase Windows SDK)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/agriflow.git
   cd agriflow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Follow instructions in `FIREBASE_SETUP.md`
   - Copy `lib/config/firebase_config.example.dart` to `lib/config/firebase_config.dart`
   - Add your Firebase credentials

4. **Run the app**
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d chrome   # For Web
   flutter run             # For mobile (with device connected)
   ```

## 📚 Documentation

Comprehensive documentation is available in the `docs/` folder:

- **[📍 PROJECT_MAP.md](docs/PROJECT_MAP.md)** - Start here! Master navigation hub for all components, services, screens, and models
- **[🚀 ONBOARDING.md](docs/ONBOARDING.md)** - 30-minute quick start guide for new developers
- **[🏗️ ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design, data flow, and architectural patterns
- **[🎨 WIDGET_CATALOG.md](docs/WIDGET_CATALOG.md)** - Complete reference for all reusable components
- **[🔧 REFACTORING_GUIDE.md](docs/REFACTORING_GUIDE.md)** - Proposed code improvements and refactoring roadmap

### Quick Links by Role

**New to the project?**
1. Start with [ONBOARDING.md](docs/ONBOARDING.md) to get set up in 30 minutes
2. Read [PROJECT_MAP.md](docs/PROJECT_MAP.md) to understand the codebase structure

**Daily development?**
- Use [PROJECT_MAP.md](docs/PROJECT_MAP.md) as your main reference
- Check [WIDGET_CATALOG.md](docs/WIDGET_CATALOG.md) before creating new components

**Understanding architecture?**
- Review [ARCHITECTURE.md](docs/ARCHITECTURE.md) for system design and patterns

**Planning improvements?**
- See [REFACTORING_GUIDE.md](docs/REFACTORING_GUIDE.md) for proposed code changes

## Project Structure

```
lib/
├── config/           # Configuration files (theme, Firebase)
├── models/           # Data models (CattleGroup, PricePulse)
├── screens/          # Main app screens
├── services/         # Business logic (Auth, Portfolio, PricePulse)
├── utils/            # Constants and utilities
├── widgets/          # Reusable UI components
└── main.dart         # App entry point

docs/
├── PROJECT_MAP.md          # 📍 Master navigation (start here!)
├── ONBOARDING.md          # 🚀 30-min quick start
├── ARCHITECTURE.md        # 🏗️ System design & patterns
├── WIDGET_CATALOG.md      # 🎨 Component reference
└── REFACTORING_GUIDE.md   # 🔧 Code improvements
```

## Firebase Setup

See `FIREBASE_SETUP.md` for detailed instructions on:
- Creating a Firebase project
- Enabling Anonymous Authentication
- Setting up Firestore
- Configuring security rules

## Privacy & Data

- **Anonymous Auth**: No personal data required
- **GDPR Compliant**: Instant data deletion
- **Auto-Expire**: Price pulse data auto-deletes after 7 days
- **Local Storage**: Portfolio data synced to Firebase

## Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Windows
flutter build windows

# Android
flutter build apk

# iOS
flutter build ios
```

## Contributing

This is a personal project, but suggestions are welcome! Please open an issue first to discuss proposed changes.

## License

This project is private and not licensed for public use.

## Acknowledgments

- Built for Irish farmers 🇮🇪
- Inspired by the need for transparent market pricing
- #ForFarmers

---

**Note**: This app is in MVP stage. Firebase configuration is required before running.
