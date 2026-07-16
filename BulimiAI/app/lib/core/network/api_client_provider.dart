import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Shared [ApiClient] instance, injected into every feature's remote data
/// source. Currently `getAuthToken` returns null (no real Firebase session
/// yet) — once `FirebaseAuthRepositoryImpl` replaces `MockAuthRepository`,
/// wire this to pull the current user's ID token instead.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(getAuthToken: () async => null);
});
