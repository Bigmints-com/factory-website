import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/firebase_service.dart';
import '../../services/sync_service.dart';
import '../../services/toast_service.dart';

/// Premium full-screen auth modal.
/// Usage: AuthScreen.show(context);
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          pageBuilder: (context, animation, _) {
            return FadeTransition(
              opacity: animation,
              child: const AuthScreen(),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }

    // Mobile: full-screen modal
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AuthScreen(),
      ),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (!isDesktop) {
      return _buildMobileLayout(theme, colorScheme);
    }

    return _buildDesktopLayout(theme, colorScheme);
  }

  /// Full-screen layout for mobile.
  Widget _buildMobileLayout(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(colorScheme, showCloseButton: false),
                  const SizedBox(height: 32),
                  if (Platform.isIOS || Platform.isMacOS)
                    _buildAppleButton(colorScheme),
                  if (Platform.isIOS || Platform.isMacOS)
                    const SizedBox(height: 12),
                  _buildGoogleButton(colorScheme),
                  const SizedBox(height: 24),
                  _buildDivider(colorScheme),
                  const SizedBox(height: 24),
                  _buildEmailField(colorScheme),
                  const SizedBox(height: 16),
                  _buildPasswordField(colorScheme),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildError(),
                  ],
                  const SizedBox(height: 24),
                  _buildSubmitButton(colorScheme),
                  const SizedBox(height: 20),
                  _buildToggle(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Floating card overlay for desktop.
  Widget _buildDesktopLayout(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 440,
                constraints: const BoxConstraints(maxHeight: 640),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(colorScheme),
                        const SizedBox(height: 32),
                        if (Platform.isIOS || Platform.isMacOS)
                          _buildAppleButton(colorScheme),
                        if (Platform.isIOS || Platform.isMacOS)
                          const SizedBox(height: 12),
                        _buildGoogleButton(colorScheme),
                        const SizedBox(height: 24),
                        _buildDivider(colorScheme),
                        const SizedBox(height: 24),
                        _buildEmailField(colorScheme),
                        const SizedBox(height: 16),
                        _buildPasswordField(colorScheme),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _buildError(),
                        ],
                        const SizedBox(height: 24),
                        _buildSubmitButton(colorScheme),
                        const SizedBox(height: 20),
                        _buildToggle(colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, {bool showCloseButton = true}) {
    return Column(
      children: [
        // Close button row (desktop overlay only)
        if (showCloseButton)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        if (showCloseButton) const SizedBox(height: 8),
        // Cloud icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.cloud_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Create an account to keep your notes everywhere'
              : 'Sign in to get your notes back',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoogleButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: colorScheme.onSurface,
        ),
        child: _isGoogleLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSurface,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" as FontAwesome icon
                  Icon(
                    Icons.g_mobiledata,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppleButton(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isAppleLoading ? null : _handleAppleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
        child: _isAppleLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apple,
                    size: 20,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Apple',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
      ],
    );
  }

  Widget _buildEmailField(ColorScheme colorScheme) {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _passwordFocus.requestFocus(),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          Icons.mail_outline,
          size: 20,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPasswordField(ColorScheme colorScheme) {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: !_showPassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleEmailAuth(),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          size: 20,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _showPassword = !_showPassword),
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700])),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleEmailAuth,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: Theme.of(context).textTheme.bodyMedium,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(_isSignUp ? 'Create Account' : 'Sign In'),
      ),
    );
  }

  Widget _buildToggle(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account?' : "Don't have an account?",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _errorMessage = null;
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (msg.contains('wrong-password')) {
      return 'Incorrect password.';
    }
    if (msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await FirebaseService().signUp(email, password);
      } else {
        await FirebaseService().signIn(email, password);
      }

      if (mounted) {
        Get.find<SyncService>().setSyncEnabled(true);
        Navigator.of(context).pop();
        if (Get.context != null) {
          ToastService.showSuccess(
            Get.context!,
            title: _isSignUp ? 'Account Created' : 'Signed In',
            description: 'Your notes will stay in sync.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _friendlyError(e);
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await FirebaseService().signInWithGoogle();
      if (user == null) {
        // User cancelled
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      if (mounted) {
        Get.find<SyncService>().setSyncEnabled(true);
        Navigator.of(context).pop();
        if (Get.context != null) {
          ToastService.showSuccess(
            Get.context!,
            title: 'Signed In',
            description: 'Your notes will stay in sync.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = _friendlyError(e);
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await FirebaseService().signInWithApple();
      if (user == null) {
        if (mounted) setState(() => _isAppleLoading = false);
        return;
      }

      if (mounted) {
        Get.find<SyncService>().setSyncEnabled(true);
        Navigator.of(context).pop();
        if (Get.context != null) {
          ToastService.showSuccess(
            Get.context!,
            title: 'Signed In',
            description: 'Your notes will stay in sync.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
          _errorMessage = _friendlyError(e);
        });
      }
    }
  }
}
