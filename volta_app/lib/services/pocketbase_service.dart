import 'package:pocketbase/pocketbase.dart';

/// Singleton service for PocketBase client access
class PocketBaseService {
  late final PocketBase client;
  
  PocketBaseService(AuthStore authStore) {
    // Use relative URL for same-origin requests through nginx proxy
    // In production, nginx proxies /api/ to PocketBase
    const pbUrl = String.fromEnvironment('PB_URL', defaultValue: '/api');
    
    // For web, we need to handle the base URL differently
    final baseUrl = pbUrl == '/api' 
        ? Uri.base.origin  // Use current origin for same-origin requests
        : pbUrl;
    
    client = PocketBase(baseUrl, authStore: authStore);
  }
  
  /// Get the current user record if authenticated
  RecordModel? get currentUser => client.authStore.model;
  
  /// Check if user is authenticated
  bool get isAuthenticated => client.authStore.isValid;
  
  /// Get the auth store for direct access
  AuthStore get authStore => client.authStore;
}
