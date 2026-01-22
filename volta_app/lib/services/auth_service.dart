import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';

/// Authentication service for user login/register/logout
class AuthService extends ChangeNotifier {
  final PocketBaseService _pbService;
  
  RecordModel? _user;
  bool _isLoading = false;
  String? _error;
  
  AuthService(this._pbService) {
    // Check for existing auth on init
    _user = _pbService.currentUser;
    debugPrint('AUTH: Service init. User: ${_user?.id}, Valid: ${_pbService.isAuthenticated}');
    if (_user != null) {
      _subscribeToUserUpdates();
    }
  }
  
  /// Current authenticated user
  RecordModel? get user => _user;
  
  /// Loading state
  bool get isLoading => _isLoading;
  
  /// Error message
  String? get error => _error;
  
  /// Check if user is logged in
  bool get isLoggedIn => _pbService.isAuthenticated && _user != null;
  
  /// Check if user is a parent
  bool get isParent => _user?.getStringValue('role') == 'parent';
  
  /// Get user's current points
  int get points => _user?.getIntValue('points') ?? 0;
  
  /// Get user's name (fallback to username if empty)
  String get name {
    final n = _user?.getStringValue('name');
    if (n != null && n.isNotEmpty) return n;
    return _user?.getStringValue('username') ?? 'User';
  }
  
  /// Get user's avatar URL
  String? get avatarUrl {
    final url = _user?.getStringValue('avatar_url');
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  /// Login with username and password
  Future<bool> login(String loginIdentity, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // If loginIdentity doesn't contain @, assume it's a username and try to map to email 
      // OR just let PocketBase handle it (PocketBase supports username login natively)
      // BUT our code previously appended @volta.local.
      // Since we are now using real emails, we should try valid auth.
      
      final authData = await _pbService.client
          .collection('users')
          .authWithPassword(loginIdentity, password);
      
      _user = authData.record;
      _subscribeToUserUpdates();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login threw error: $e');
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Register a new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String name,
    required String role,
    required String avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Create the user record
      await _pbService.client.collection('users').create(body: {
        'username': username,
        'email': email,
        'emailVisibility': true,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'role': role,
        'avatar_url': avatarUrl,
        'points': 0,
      });
      
      // Auto-login after registration
      return await login(email, password);
    } catch (e) {
      debugPrint('Registration loop failed: $e');
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Logout the current user
  void logout() {
    _unsubscribeFromUserUpdates();
    _pbService.client.authStore.clear();
    _user = null;
    notifyListeners();
  }
  
  /// Refresh user data from server
  Future<void> refreshUser() async {
    if (_user == null) return;
    
    try {
      _user = await _pbService.client
          .collection('users')
          .getOne(_user!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
    }
  }

  /// Update user profile (name, password, avatar)
  Future<bool> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirm,
    List<int>? avatarBytes,
    String? avatarFileName,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (avatarUrl != null && avatarUrl.isNotEmpty) body['avatar_url'] = avatarUrl;
      
      if (newPassword != null && newPassword.isNotEmpty) {
         // Standard PocketBase: To change password, you generally just send 'password', 'passwordConfirm',
         // AND often 'oldPassword' if configured strictly. But by default for authenticated user update,
         // just password/passwordConfirm is enough IF the API rule allows it.
         // Let's assume standard behavior:
         body['password'] = newPassword;
         body['passwordConfirm'] = newPasswordConfirm;
         if (currentPassword != null) body['oldPassword'] = currentPassword;
      }

      final List<http.MultipartFile> files = [];
      if (avatarBytes != null && avatarFileName != null) {
        files.add(http.MultipartFile.fromBytes(
          'avatar',
          avatarBytes,
          filename: avatarFileName,
        ));
      }

      _user = await _pbService.client
          .collection('users')
          .update(_user!.id, body: body, files: files);
          
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Profile update failed: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Update user points (called after mission approval)
  Future<void> addPoints(int amount) async {
    if (_user == null) return;
    
    try {
      final newPoints = points + amount;
      _user = await _pbService.client
          .collection('users')
          .update(_user!.id, body: {'points': newPoints});
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update points: $e');
    }
  }
  /// Subscribe to changes on the user record (Realtime)
  void _subscribeToUserUpdates() {
    if (_user == null) return;
    
    _pbService.client.collection('users').subscribe(_user!.id, (e) {
      if (e.action == 'update' && e.record != null) {
        debugPrint('REALTIME: User update received: ${e.record}');
        _user = e.record;
        notifyListeners();
      }
    });
  }

  /// Unsubscribe
  void _unsubscribeFromUserUpdates() {
    _pbService.client.collection('users').unsubscribe();
  }

  @override
  void dispose() {
    _unsubscribeFromUserUpdates();
    super.dispose();
  }
}
