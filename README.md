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
