import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

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
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

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
    super.dispose();
  }

  /// Opens an in-app auth browser via ASWebAuthenticationSession (iOS/macOS)
  /// or Chrome Custom Tabs (Android). The browser automatically closes when
  /// the web app redirects to `fikr://auth/callback?token=...`.
  Future<void> _openWebAuth(String mode) async {
    setState(() => _isLoading = true);

    try {
      // 1. Open in-app auth browser — blocks until redirect to fikr:// happens
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: 'https://www.fikr.one/$mode?returnUrl=fikr://auth/callback',
        callbackUrlScheme: 'fikr',
      );

      // 2. Extract the custom token from the callback URL
      final uri = Uri.parse(resultUrl);
      final token = uri.queryParameters['token'];

      if (token == null || token.isEmpty) {
        throw Exception('No token received from auth server');
      }

      // 3. Sign in to Firebase with the custom token
      await FirebaseAuth.instance.signInWithCustomToken(token);

      // 4. Success — close this screen
      if (mounted) {
        Navigator.of(context).pop();
        ToastService.showSuccess(
          context,
          title: 'Successfully signed in to Fikr Cloud',
        );
      }
    } on Exception catch (e) {
      debugPrint('Web auth error: $e');
      // User cancelled or something went wrong
      if (mounted && !e.toString().contains('CANCELED')) {
        ToastService.showError(
          context,
          title: 'Sign in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (!isDesktop) {
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
                    const SizedBox(height: 48),
                    _buildWebAuthButton(
                      colorScheme,
                      'login',
                      'Sign In to Fikr Cloud',
                      true,
                    ),
                    const SizedBox(height: 16),
                    _buildWebAuthButton(
                      colorScheme,
                      'register',
                      'Create an Account',
                      false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(colorScheme),
                        const SizedBox(height: 48),
                        _buildWebAuthButton(
                          colorScheme,
                          'login',
                          'Sign In to Fikr Cloud',
                          true,
                        ),
                        const SizedBox(height: 16),
                        _buildWebAuthButton(
                          colorScheme,
                          'register',
                          'Create an Account',
                          false,
                        ),
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
        if (showCloseButton)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_sync, size: 40, color: colorScheme.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          'Fikr Cloud',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Securely sync your notes across devices and access premium AI models with Fikr Cloud.',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWebAuthButton(
    ColorScheme colorScheme,
    String mode,
    String label,
    bool primary,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _openWebAuth(mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? colorScheme.primary : colorScheme.surface,
          foregroundColor: primary
              ? colorScheme.onPrimary
              : colorScheme.primary,
          side: primary ? null : BorderSide(color: colorScheme.outlineVariant),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary ? colorScheme.onPrimary : colorScheme.primary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
