/// firebase_config.example.dart - Firebase configuration template
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

class FirebaseConfig {
  // TODO: Replace with your actual Firebase credentials
  // Get these from Firebase Console → Project Settings → Your apps → Web app

  static const String apiKey = 'YOUR_API_KEY';
  static const String authDomain = 'YOUR_PROJECT_ID.firebaseapp.com';
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String storageBucket = 'YOUR_PROJECT_ID.appspot.com';
  static const String messagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
  static const String appId = 'YOUR_APP_ID';

  // App identifier for Firestore paths
  static const String appId_firestore = 'agriflow_mvp';
}
