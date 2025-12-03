#!/bin/bash
# AgriFlow - Firebase Deployment Script

set -e  # Exit on error

echo "🚀 AgriFlow Firebase Deployment"
echo "================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found"
    echo ""
    echo "Install it with:"
    echo "  npm install -g firebase-tools"
    echo ""
    exit 1
fi

echo "✓ Firebase CLI found"
echo ""

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase"
    echo ""
    echo "Login with:"
    echo "  firebase login"
    echo ""
    exit 1
fi

echo "✓ Logged in to Firebase"
echo ""

# Show current project
echo "Current Firebase project:"
firebase use

echo ""
echo "📋 What to deploy?"
echo ""
echo "1) Firestore rules & indexes (CRITICAL - do this first!)"
echo "2) Hosting (web build)"
echo "3) Functions (if you have Cloud Functions)"
echo "4) Everything"
echo ""
read -p "Select option (1-4): " option

case $option in
    1)
        echo ""
        echo "🔐 Deploying Firestore rules and indexes..."
        firebase deploy --only firestore:rules,firestore:indexes
        echo ""
        echo "✅ Firestore rules deployed successfully!"
        echo ""
        echo "⚠️  IMPORTANT: Wait 1-2 minutes for rules to propagate globally"
        echo ""
        ;;
    2)
        echo ""
        echo "🌐 Building Flutter web app..."
        flutter build web --release
        echo ""
        echo "🚀 Deploying to Firebase Hosting..."
        firebase deploy --only hosting
        echo ""
        echo "✅ Web app deployed successfully!"
        ;;
    3)
        echo ""
        echo "⚡ Deploying Cloud Functions..."
        firebase deploy --only functions
        echo ""
        echo "✅ Functions deployed successfully!"
        ;;
    4)
        echo ""
        echo "📦 Building Flutter web app..."
        flutter build web --release
        echo ""
        echo "🚀 Deploying everything..."
        firebase deploy
        echo ""
        echo "✅ Full deployment complete!"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "════════════════════════════════════════"
echo "✨ Deployment complete!"
echo "════════════════════════════════════════"
echo ""
