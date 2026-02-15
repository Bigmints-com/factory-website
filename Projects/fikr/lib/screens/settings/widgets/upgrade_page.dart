import 'package:flutter/material.dart';

/// Upgrade page — temporarily disabled for initial app store submission.
/// Re-enable when in-app purchases are implemented.
class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  static void show(BuildContext context) {
    // No-op: IAP temporarily disabled
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Coming soon')));
  }
}
