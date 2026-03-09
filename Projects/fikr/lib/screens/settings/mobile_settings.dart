import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
            isCard: false,
            title: 'Theme',
            child: Obx(
              () => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeController.themeMode.value},
                onSelectionChanged: (s) async {
                  if (s.isEmpty) return;
                  final mode = s.first;
                  themeController.setThemeMode(mode);
                  await controller.updateConfig(
                    controller.config.value.copyWith(themeMode: mode.name),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          _Section(
            isCard: true,
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
            isCard: true,
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
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.person_remove_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Permanently remove your account and data',
                      ),
                      onTap: () => _showDeleteAccountDialog(context),
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
            isCard: true,
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
          const SizedBox(height: 32),
          _Section(
            isCard: true,
            title: 'Legal',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () => launchUrl(
                    Uri.parse('https://fikr.bigmints.com/privacy'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Use'),
                  onTap: () => launchUrl(
                    Uri.parse('https://fikr.bigmints.com/terms'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  const _Section({
    required this.title,
    required this.child,
    required this.isCard,
  });
  final String title;
  final Widget child;
  final bool isCard;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        isCard ? Card(child: child) : child,
      ],
    );
  }
}
