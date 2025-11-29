# Firebase Setup for AgriFlow

## What We're Doing
Reverting from Supabase back to Firebase (the original plan from the Canvas).

## Prerequisites
You need a Firebase project. If you don't have one:
1. Go to https://console.firebase.google.com
2. Click "Add Project"
3. Name it "AgriFlow" (or whatever you prefer)
4. Disable Google Analytics (optional for MVP)
5. Click "Create Project"

## Step 1: Enable Firebase Services

### Enable Authentication
1. In Firebase Console, click **Authentication**
2. Click **Get Started**
3. Click **Sign-in method** tab
4. Enable **Anonymous** provider
5. Click **Save**

### Enable Firestore
1. Click **Firestore Database** in left sidebar
2. Click **Create Database**
3. Choose **Start in test mode** (we'll add security rules later)
4. Choose a location close to you
5. Click **Enable**

## Step 2: Get Firebase Configuration

### For Web (if you want web support later):
1. In Firebase Console, click the gear icon → **Project Settings**
2. Scroll down to "Your apps"
3. Click the **Web** icon (`</>`)
4. Register app name: "AgriFlow Web"
5. Copy the `firebaseConfig` object

### For Windows/Desktop:
Firebase doesn't have native Windows SDK, so we'll use the **Web SDK** in Flutter for Windows.

## Step 3: Add Firebase Config to Flutter

I'll create a `lib/config/firebase_config.dart` file with your Firebase credentials.

You'll need to fill in:
- `apiKey`
- `authDomain`
- `projectId`
- `storageBucket`
- `messagingSenderId`
- `appId`

These come from the Firebase Console → Project Settings → Your apps → Web app config.

## Step 4: Security Rules

Once everything works, add these Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Private user data
    match /artifacts/{appId}/users/{userId}/cattle_inventory/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public price pulse data
    match /artifacts/{appId}/public/data/price_pulses/{document=**} {
      allow read: if true; // Anyone can read
      allow write: if request.auth != null; // Only authenticated users can write
    }
  }
}
```

## Next Steps
1. Create Firebase project
2. Enable Anonymous Auth
3. Enable Firestore
4. Get your web config
5. I'll update the code to use Firebase
