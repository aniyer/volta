import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/cyber_vibrant_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  XFile? _avatarFile;
  final ImagePicker _picker = ImagePicker();
  
  // BigHead / DiceBear Avatar State
  List<String> _avatarSeeds = [];
  String? _selectedAvatarSeed;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    _nameController = TextEditingController(text: user?.getStringValue('name') ?? '');
    _shuffleAvatars();
  }

  void _shuffleAvatars() {
    setState(() {
      _avatarSeeds = List.generate(5, (_) => Random().nextInt(1000000).toString());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _avatarFile = image);
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    final newPassword = _passwordController.text.isNotEmpty ? _passwordController.text : null;
    final newPasswordConfirm = _confirmPasswordController.text.isNotEmpty ? _confirmPasswordController.text : null;

    List<int>? avatarBytes;
    String? avatarName;
    String? avatarUrl;
    
    if (_avatarFile != null) {
      avatarBytes = await _avatarFile!.readAsBytes();
      avatarName = _avatarFile!.name;
    } else if (_selectedAvatarSeed != null) {
      avatarUrl = 'https://api.dicebear.com/7.x/big-smile/png?seed=$_selectedAvatarSeed';
    }

    final success = await auth.updateProfile(
      name: _nameController.text,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
      avatarBytes: avatarBytes,
      avatarFileName: avatarName,
      avatarUrl: avatarUrl,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: CyberVibrantTheme.electricTeal,
          ),
        );
        Navigator.pop(context); // Go back home
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${auth.error ?? "Unknown error"}'),
            backgroundColor: CyberVibrantTheme.magmaOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE SETTINGS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: CyberVibrantTheme.glowingCard(),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: CyberVibrantTheme.primaryGradient,
                                border: Border.all(
                                  color: CyberVibrantTheme.electricTeal,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CyberVibrantTheme.neonVioletGlow,
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: () {
                                  // 1. Show newly picked file
                                  if (_avatarFile != null) {
                                    return Image.network(
                                      _avatarFile!.path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => const Icon(Icons.person, size: 50, color: Colors.white),
                                    );
                                  }
                                  // 2. Show newly picked avatar seed
                                  if (_selectedAvatarSeed != null) {
                                     return Image.network(
                                      'https://api.dicebear.com/7.x/big-smile/png?seed=$_selectedAvatarSeed',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => const Icon(Icons.person, size: 50, color: Colors.white),
                                    );
                                  }
                                  // 3. Show existing avatar
                                  final user = context.read<AuthService>().user;
                                  final existingAvatar = user?.getStringValue('avatar');
                                  final existingAvatarUrl = user?.getStringValue('avatar_url');

                                  if (existingAvatar != null && existingAvatar.isNotEmpty) {
                                    return Image.network(
                                      '${const String.fromEnvironment('PB_URL', defaultValue: 'http://127.0.0.1:8090')}/api/files/${user!.collectionId}/${user.id}/$existingAvatar',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => const Icon(Icons.person, size: 50, color: Colors.white),
                                    );
                                  } else if (existingAvatarUrl != null && existingAvatarUrl.isNotEmpty) {
                                     return Image.network(
                                      existingAvatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => const Icon(Icons.person, size: 50, color: Colors.white),
                                    );
                                  }
                                  // 4. Default
                                  return const Icon(Icons.person, size: 50, color: Colors.white);
                                }(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: CyberVibrantTheme.electricTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Avatar Picker Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choose Avatar:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: CyberVibrantTheme.textSecondary),
                          ),
                          TextButton.icon(
                            onPressed: _shuffleAvatars,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Shuffle'),
                            style: TextButton.styleFrom(
                               foregroundColor: CyberVibrantTheme.electricTeal,
                               padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _avatarSeeds.length,
                          separatorBuilder: (c, i) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final seed = _avatarSeeds[index];
                            final isSelected = _selectedAvatarSeed == seed;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAvatarSeed = seed;
                                  _avatarFile = null; // Clear file if picking big smile
                                });
                              },
                              child: Container(
                                width: 70,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected 
                                        ? CyberVibrantTheme.electricTeal 
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: CyberVibrantTheme.electricTeal.withOpacity(0.5),
                                      blurRadius: 10,
                                    )
                                  ] : null,
                                ),
                                child: CircleAvatar(
                                  backgroundColor: CyberVibrantTheme.darkCard,
                                  backgroundImage: NetworkImage(
                                    'https://api.dicebear.com/7.x/big-smile/png?seed=$seed'
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.badge, color: CyberVibrantTheme.neonViolet),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Change Password (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CyberVibrantTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock, color: CyberVibrantTheme.electricTeal),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return 'Password must be 6+ chars';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_clock, color: CyberVibrantTheme.electricTeal),
                  ),
                  validator: (v) {
                     if (_passwordController.text.isNotEmpty && v != _passwordController.text) {
                       return 'Passwords do not match';
                     }
                     return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text('SAVE CHANGES'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
