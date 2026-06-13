import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String friendlyErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return error.message?.trim().isNotEmpty ?? false
        ? error.message!.trim()
        : 'Authentication failed. Please sign in again.';
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'We could not access that information. Please check account permissions and try again.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please check your connection and try again.';
      case 'not-found':
        return 'That record could not be found. It may have changed or been removed.';
      case 'cancelled':
        return 'The request was cancelled. Please try again.';
      default:
        return error.message?.trim().isNotEmpty ?? false
            ? error.message!.trim()
            : 'Firebase could not complete the request. Please try again.';
    }
  }

  final message = error.toString().replaceFirst('Exception: ', '').trim();
  if (message.isEmpty) {
    return 'Something went wrong. Please try again.';
  }

  return message;
}
