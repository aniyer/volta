import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/auth_service.dart';

/// Login screen with username/password auth
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isRegistering = false;
  String _selectedRole = 'child';
  
  // Avatar selection
  List<String> _avatarSeeds = [];
  String _selectedAvatarSeed = '';

  @override
  void initState() {
    super.initState();
    _shuffleAvatars();
  }

  void _shuffleAvatars() {
    setState(() {
      _avatarSeeds = List.generate(5, (_) => Random().nextInt(1000000).toString());
      if (!_avatarSeeds.contains(_selectedAvatarSeed)) {
        _selectedAvatarSeed = _avatarSeeds.first;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthService>();
    bool success;
    
    if (_isRegistering) {
      final avatarUrl = 'https://api.dicebear.com/7.x/big-smile/png?seed=$_selectedAvatarSeed';
      
      success = await auth.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        avatarUrl: avatarUrl,
      );
    } else {
      success = await auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Authentication failed'),
          backgroundColor: CyberVibrantTheme.magmaOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: CyberVibrantTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  _isRegistering ? 'Create Account' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: 0.2),
                
                const SizedBox(height: 8),
                
                Text(
                  _isRegistering 
                      ? 'Join your household crew' 
                      : 'Ready to spin?',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms),
                
                const SizedBox(height: 48),
                
                // Name field (only for registration)
                if (_isRegistering) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Username field matches existing login logic (can be email or username)
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: _isRegistering ? 'Username' : 'Email',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isRegistering ? 'Please enter your username' : 'Please enter your email';
                    }
                    if (_isRegistering && value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                  ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isRegistering && value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                  ),
                
                // Role selector (only for registration)
                if (_isRegistering) ...[
                  const SizedBox(height: 24),
                  
                  Text(
                    'Select your role:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          label: 'Child',
                          icon: Icons.child_care,
                          isSelected: _selectedRole == 'child',
                          color: CyberVibrantTheme.electricTeal,
                          onTap: () => setState(() => _selectedRole = 'child'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _RoleCard(
                          label: 'Parent',
                          icon: Icons.supervisor_account,
                          isSelected: _selectedRole == 'parent',
                          color: CyberVibrantTheme.neonViolet,
                          onTap: () => setState(() => _selectedRole = 'parent'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose Avatar:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _shuffleAvatars,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Shuffle'),
                        style: TextButton.styleFrom(
                          foregroundColor: CyberVibrantTheme.electricTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatarSeeds.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final seed = _avatarSeeds[index];
                        final isSelected = _selectedAvatarSeed == seed;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatarSeed = seed),
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
                                ),
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
                ].animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 32),
                
                // Submit button
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isRegistering ? 'CREATE ACCOUNT' : 'LOGIN'),
                ),
                
                const SizedBox(height: 16),
                
                // Toggle login/register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                    });
                  },
                  child: Text(
                    _isRegistering
                        ? 'Already have an account? Login'
                        : 'New here? Create account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection card widget
class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? CyberVibrantTheme.withAlpha(color, 0.2) 
              : CyberVibrantTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : CyberVibrantTheme.textMuted),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : CyberVibrantTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
