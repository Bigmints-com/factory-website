import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/app_controller.dart';
import '../../models/llm_provider.dart';
import '../../controllers/theme_controller.dart';
import '../../services/firebase_service.dart';
import '../../services/sync_service.dart';
import '../../services/toast_service.dart';
import 'auth_screen.dart';
import 'provider_detail_screen.dart';

class DesktopSettings extends StatelessWidget {
  const DesktopSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<AppController>();
    final themeController = Get.find<ThemeController>();

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 32),
                _SettingItem(
                  title: 'Theme',
                  child: Obx(
                    () => SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeController.themeMode.value},
                      onSelectionChanged: (s) {
                        final mode = s.first;
                        themeController.setThemeMode(mode);
                        controller.updateConfig(
                          controller.config.value.copyWith(
                            themeMode: mode.name,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SettingItem(
                  title: 'AI Service',
                  child: Obx(() {
                    final provider = controller.config.value.activeProvider;
                    if (provider == null) {
                      return Card(
                        child: ListTile(
                          title: const Text('Not configured'),
                          subtitle: const Text('Tap to get started'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Get.to(() => const ProviderDetailScreen()),
                        ),
                      );
                    }
                    return Card(
                      child: ListTile(
                        title: Text(provider.name),
                        subtitle: Text(provider.type.displayName),
                        onTap: () => Get.to(
                          () => ProviderDetailScreen(provider: provider),
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                _SettingItem(
                  title: 'Account & Cloud Sync',
                  child: Obx(() {
                    final user = FirebaseService().currentUser.value;
                    final isAnonymous = user?.isAnonymous ?? true;
                    final isLoggedIn = user != null && !isAnonymous;

                    if (isLoggedIn) {
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              FeatherIcons.user,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.email ?? 'Signed In',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  'Cloud sync enabled',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                Get.find<SyncService>().syncToCloud(),
                            icon: const Icon(
                              FeatherIcons.uploadCloud,
                              size: 14,
                            ),
                            label: const Text('Sync Now'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () async {
                              await FirebaseService().signOut();
                              if (context.mounted) {
                                ToastService.showSuccess(
                                  context,
                                  title: 'Signed Out',
                                  description: 'Cloud sync disabled.',
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Sign Out'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => _showDeleteAccountDialog(context),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Delete Account'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Sign in to back up your notes to the cloud and access them across devices.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => AuthScreen.show(context),
                            icon: const Icon(FeatherIcons.logIn, size: 14),
                            label: const Text('Sign In or Create Account'),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 24),
                _SettingItem(
                  title: 'Data Management',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final dir = await controller
                                    .pickExportDirectory();
                                if (dir != null) {
                                  await controller.exportAll(dir);
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Export All Notes'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _showClearDialog(context, controller),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear All Data'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SettingItem(
                  title: 'Legal',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://fikr.bigmints.com/privacy'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.privacy_tip_outlined),
                          label: const Text('Privacy Policy'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://fikr.bigmints.com/terms'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Terms of Use'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This will permanently delete all your data from the cloud. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await FirebaseService().deleteAccount();
                if (context.mounted) {
                  ToastService.showSuccess(
                    context,
                    title: 'Account Deleted',
                    description: 'Your account and data have been removed.',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ToastService.showError(
                    context,
                    title: 'Error',
                    description:
                        'Could not delete account. You might need to re-authenticate.',
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        content: const Text(
          'Delete all notes and recordings? This cannot be undone.',
        ),
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

class _SettingItem extends StatelessWidget {
  const _SettingItem({required this.title, required this.child});
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
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
