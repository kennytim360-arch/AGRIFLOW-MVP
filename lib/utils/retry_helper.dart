/// retry_helper.dart - Retry mechanism for network operations
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'dart:async';
import 'logger.dart';
import 'error_handler.dart';

/// Helper for retrying operations with exponential backoff
class RetryHelper {
  /// Retry an async operation with exponential backoff
  ///
  /// [operation] - The async function to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry in milliseconds (default: 1000ms)
  /// [maxDelay] - Maximum delay between retries in milliseconds (default: 10000ms)
  /// [shouldRetry] - Optional function to determine if error is retryable
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    int delay = initialDelay;

    while (true) {
      attempt++;

      try {
        Logger.debug('Attempting operation (attempt $attempt/$maxAttempts)');
        return await operation();
      } catch (error) {
        // Check if we've exhausted attempts
        if (attempt >= maxAttempts) {
          Logger.error(
            'Operation failed after $maxAttempts attempts',
            error,
          );
          rethrow;
        }

        // Check if error is retryable
        final isRetryable = shouldRetry?.call(error) ??
            ErrorHandler.isNetworkError(error) ||
            ErrorHandler.isRateLimitError(error);

        if (!isRetryable) {
          Logger.warning('Error is not retryable, failing immediately');
          rethrow;
        }

        Logger.warning(
          'Operation failed (attempt $attempt/$maxAttempts), retrying in ${delay}ms...',
        );

        // Wait before retry
        await Future.delayed(Duration(milliseconds: delay));

        // Exponential backoff (double the delay, up to maxDelay)
        delay = (delay * 2).clamp(initialDelay, maxDelay);
      }
    }
  }

  /// Retry a Firebase operation (auth or firestore)
  static Future<T> retryFirebaseOperation<T>({
    required Future<T> Function() operation,
    String? operationName,
  }) async {
    try {
      return await retry(
        operation: operation,
        maxAttempts: 3,
        initialDelay: 1000,
        maxDelay: 5000,
      );
    } catch (error) {
      final errorMessage = ErrorHandler.getGenericErrorMessage(error);
      Logger.error(
        'Firebase operation ${operationName ?? "unknown"} failed: $errorMessage',
        error,
      );
      rethrow;
    }
  }

  /// Retry with custom attempts and delay
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    required int attempts,
    required Duration initialDelay,
  }) async {
    return retry(
      operation: operation,
      maxAttempts: attempts,
      initialDelay: initialDelay.inMilliseconds,
    );
  }
}
