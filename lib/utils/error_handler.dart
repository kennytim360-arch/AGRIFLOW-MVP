/// error_handler.dart - User-friendly error message utility
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firebase and system errors to user-friendly messages
class ErrorHandler {
  /// Get user-friendly message for Firebase Auth errors
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Anonymous sign-in is not enabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'requires-recent-login':
          return 'Please sign in again to continue.';
        case 'credential-already-in-use':
          return 'These credentials are already linked to another account.';
        case 'provider-already-linked':
          return 'This account is already linked.';
        default:
          return 'Authentication error: ${error.message ?? error.code}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get user-friendly message for Firestore errors
  static String getFirestoreErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to perform this action.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'already-exists':
          return 'This item already exists.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your connection.';
        case 'resource-exhausted':
          return 'Too many requests. Please wait a moment.';
        case 'unauthenticated':
          return 'Please sign in to continue.';
        case 'invalid-argument':
          return 'Invalid data provided. Please check your input.';
        case 'failed-precondition':
          return 'Operation cannot be completed at this time.';
        default:
          return 'Database error: ${error.message ?? error.code}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get user-friendly message for generic errors
  static String getGenericErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    }
    if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    }
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is network-related and can be retried
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed';
    }
    if (error is FirebaseException) {
      return error.code == 'unavailable' || error.code == 'deadline-exceeded';
    }
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }

  /// Check if error is a rate limit error
  static bool isRateLimitError(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'too-many-requests';
    }
    if (error is FirebaseException) {
      return error.code == 'resource-exhausted';
    }
    return false;
  }
}
