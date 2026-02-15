import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import '../../models/llm_provider.dart';
import '../../controllers/theme_controller.dart';
import '../../services/firebase_service.dart';
import '../../services/sync_service.dart';
import '../../services/toast_service.dart';
import 'auth_screen.dart';
import 'provider_detail_screen.dart';

class MobileSettings extends StatelessWidget {
  const MobileSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final themeController = Get.find<ThemeController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: 'Theme',
            child: Obx(
              () => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeController.themeMode.value},
                onSelectionChanged: (s) {
                  final mode = s.first;
                  themeController.setThemeMode(mode);
                  controller.updateConfig(
                    controller.config.value.copyWith(themeMode: mode.name),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'AI Provider',
            child: Obx(() {
              final provider = controller.config.value.activeProvider;
              if (provider == null) {
                return ListTile(
                  title: const Text('Not configured'),
                  subtitle: const Text('Tap to set up your AI provider'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.to(() => const ProviderDetailScreen()),
                );
              }
              return ListTile(
                title: Text(provider.name),
                subtitle: Text(provider.type.displayName),
                onTap: () =>
                    Get.to(() => ProviderDetailScreen(provider: provider)),
                trailing: const Icon(Icons.chevron_right),
              );
            }),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'Account & Cloud Sync',
            child: Obx(() {
              final user = FirebaseService().currentUser.value;
              final isAnonymous = user?.isAnonymous ?? true;
              final isLoggedIn = user != null && !isAnonymous;

              if (isLoggedIn) {
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: FaIcon(
                          FontAwesomeIcons.user,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(user.email ?? 'Signed In'),
                      subtitle: const Text('Cloud sync enabled'),
                    ),
                    ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.cloudArrowUp,
                        size: 18,
                      ),
                      title: const Text('Sync Now'),
                      onTap: () => Get.find<SyncService>().syncToCloud(),
                    ),
                    ListTile(
                      leading: FaIcon(
                        FontAwesomeIcons.rightFromBracket,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () async {
                        await FirebaseService().signOut();
                        if (context.mounted) {
                          ToastService.showSuccess(
                            context,
                            title: 'Signed Out',
                            description: 'Cloud sync disabled.',
                          );
                        }
                      },
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sign in to back up your notes to the cloud and access them across devices.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => AuthScreen.show(context),
                        icon: const FaIcon(
                          FontAwesomeIcons.rightToBracket,
                          size: 16,
                        ),
                        label: const Text('Sign In or Create Account'),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'Data',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  onTap: () async {
                    final dir = await controller.pickExportDirectory();
                    if (dir != null) await controller.exportAll(dir);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Clear All Data',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showClearDialog(context, controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Delete all notes? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
