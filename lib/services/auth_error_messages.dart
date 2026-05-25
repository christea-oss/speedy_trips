String friendlyAuthError(String code, {String? message}) {
  final lowerMessage = message?.toLowerCase() ?? '';

  if (lowerMessage.contains('configuration-not-found') ||
      lowerMessage.contains('configuration_not_found')) {
    return 'Firebase Email/Password sign-in is not enabled for this project.';
  }
  if (lowerMessage.contains('api-key-not-valid') ||
      lowerMessage.contains('invalid-api-key')) {
    return 'Firebase web configuration has an invalid API key.';
  }
  if (lowerMessage.contains('app-not-authorized') ||
      lowerMessage.contains('app_not_authorized')) {
    return 'This web domain is not authorized in Firebase Authentication.';
  }

  switch (code) {
    case 'email-already-in-use':
      return 'That email is already registered.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email or password is incorrect.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'role-mismatch':
      return 'This account belongs to the other SpeedyTrips role.';
    case 'firebase-unavailable':
      return 'Firebase authentication is not configured.';
    case 'network-request-failed':
      return 'Network connection failed. Please try again.';
    case 'too-many-requests':
    case 'too_many_requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'operation-not-allowed':
    case 'operation_not_allowed':
      return 'Email login is not enabled for this Firebase project.';
    case 'configuration-not-found':
    case 'configuration_not_found':
      return 'Firebase Email/Password sign-in is not enabled for this project.';
    case 'app-not-authorized':
    case 'app_not_authorized':
    case 'unauthorized-domain':
    case 'unauthorized_domain':
      return 'This web domain is not authorized in Firebase Authentication.';
    case 'invalid-api-key':
    case 'invalid_api_key':
      return 'Firebase web configuration has an invalid API key.';
    case 'invalid-app-credential':
    case 'invalid_app_credential':
      return 'Firebase web app configuration is invalid.';
    case 'profile-write-permission-denied':
      return 'Account created, but Firestore rules blocked saving your SpeedyTrips role.';
    case 'profile-read-permission-denied':
      return 'Firebase Auth worked, but Firestore rules blocked reading your SpeedyTrips role.';
    case 'profile-write-unavailable':
    case 'profile-read-unavailable':
      return 'Firebase profile service is temporarily unavailable. Please try again.';
    case 'profile-write-failed':
      return 'Account created, but SpeedyTrips could not save your role profile.';
    case 'profile-read-failed':
      return 'Firebase Auth worked, but SpeedyTrips could not load your role profile.';
    case 'invalid-user-role':
      return 'This account has an invalid SpeedyTrips role. Please contact support.';
    case 'missing-user':
      return 'Firebase did not return a signed-in user. Please try again.';
    default:
      return message?.trim().isNotEmpty ?? false
          ? message!.trim()
          : 'Authentication failed with code: $code';
  }
}

String friendlyUnexpectedAuthError(Object error) {
  final message = error.toString();
  if (message.contains('firebase_auth')) {
    return 'Firebase Auth failed: $message';
  }
  if (message.trim().isNotEmpty) {
    return message;
  }
  return 'Authentication failed before Firebase returned an error code.';
}
