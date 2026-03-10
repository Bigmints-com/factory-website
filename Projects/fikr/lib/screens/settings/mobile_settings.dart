import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/firebase_service.dart';
import '../../services/sync_service.dart';
import '../../services/toast_service.dart';

import 'provider_detail_screen.dart';
import 'widgets/fikr_cloud_banner.dart';

class MobileSettings extends StatelessWidget {
  const MobileSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final themeController = Get.find<ThemeController>();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Obx(() {
        final user = FirebaseService().currentUser.value;
        final isAnonymous = user?.isAnonymous ?? true;
        final isLoggedIn = user != null && !isAnonymous;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── AI Service ──
              _SectionHeader(title: 'AI Service'),
              _SettingsGroup(
                children: [
                  Obx(() {
                    final provider = controller.config.value.activeProvider;
                    return _SettingsRow(
                      icon: FeatherIcons.cpu,
                      title: 'AI Provider',
                      value: provider?.name ?? 'Not set',
                      onTap: () => Get.to(
                        () => ProviderDetailScreen(provider: provider),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 28),

              // ── Preferences ──
              _SectionHeader(title: 'Preferences'),
              _SettingsGroup(
                children: [
                  Obx(() {
                    final mode = themeController.themeMode.value;
                    final label = switch (mode) {
                      ThemeMode.system => 'Auto',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    };
                    return _SettingsRow(
                      icon: FeatherIcons.sun,
                      title: 'Theme',
                      value: label,
                      onTap: () => _showThemePicker(
                        context,
                        themeController,
                        controller,
                      ),
                    );
                  }),
                  if (isLoggedIn)
                    Obx(() {
                      final syncService = Get.find<SyncService>();
                      return _SettingsToggleRow(
                        icon: FeatherIcons.uploadCloud,
                        title: 'Cloud Sync',
                        value: syncService.isSyncEnabled.value,
                        onChanged: (v) {
                          syncService.setSyncEnabled(v);
                          if (v) syncService.syncToCloud();
                        },
                      );
                    }),
                ],
              ),

              const SizedBox(height: 28),

              // ── Fikr Cloud ──
              Obx(() {
                final user = FirebaseService().currentUser.value;
                final isAnonymous = user?.isAnonymous ?? true;
                final isLoggedIn = user != null && !isAnonymous;
                final sub = Get.find<SubscriptionController>();

                // Not signed in → show sign-in card
                if (!isLoggedIn) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Fikr Cloud'),
                      const FikrCloudBanner(),
                    ],
                  );
                }

                // Signed in but free → account info + informational note
                if (sub.isFree) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Fikr Cloud'),
                      _SettingsGroup(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Icon(
                                FeatherIcons.user,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(user.email ?? 'Signed In'),
                            subtitle: const Text('Local storage only'),
                          ),
                          const FikrCloudNote(),
                          ListTile(
                            leading: Icon(
                              FeatherIcons.logOut,
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
                                  description: 'You have been signed out.',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // Signed in with subscription → full sync UI
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Fikr Cloud'),
                    _SettingsGroup(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              FeatherIcons.user,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(user.email ?? 'Signed In'),
                          subtitle: const Text('Cloud sync enabled'),
                        ),
                        ListTile(
                          leading: const Icon(
                            FeatherIcons.uploadCloud,
                            size: 18,
                          ),
                          title: const Text('Sync Now'),
                          onTap: () => Get.find<SyncService>().syncToCloud(),
                        ),
                        ListTile(
                          leading: Icon(
                            FeatherIcons.logOut,
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
                    ),
                  ],
                );
              }),

              const SizedBox(height: 28),

              // ── Data ──
              _SectionHeader(title: 'Data'),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: FeatherIcons.download,
                    title: 'Export Data',
                    onTap: () async {
                      final dir = await controller.pickExportDirectory();
                      if (dir != null) await controller.exportAll(dir);
                    },
                  ),
                  _SettingsRow(
                    icon: FeatherIcons.trash2,
                    title: 'Clear All Data',
                    isDestructive: true,
                    onTap: () => _showClearDialog(context, controller),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── About ──
              _SectionHeader(title: 'About'),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: FeatherIcons.shield,
                    title: 'Privacy Policy',
                    onTap: () => launchUrl(
                      Uri.parse('https://fikr.bigmints.com/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  _SettingsRow(
                    icon: FeatherIcons.fileText,
                    title: 'Terms of Use',
                    onTap: () => launchUrl(
                      Uri.parse('https://fikr.bigmints.com/terms'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),

              // ── Logout button at the bottom ──
              if (isLoggedIn) ...[
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
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
                    icon: const Icon(FeatherIcons.logOut, size: 16),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),
            ],
          ),
        );
      }),
    );
  }

  // ── Theme picker bottom sheet ──
  void _showThemePicker(
    BuildContext context,
    ThemeController themeController,
    AppController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Theme',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                for (final entry in {
                  ThemeMode.system: ('Auto', FeatherIcons.monitor),
                  ThemeMode.light: ('Light', FeatherIcons.sun),
                  ThemeMode.dark: ('Dark', FeatherIcons.moon),
                }.entries)
                  Obx(() {
                    final isSelected =
                        themeController.themeMode.value == entry.key;
                    return ListTile(
                      leading: Icon(entry.value.$2, size: 20),
                      title: Text(entry.value.$1),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(ctx).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        themeController.setThemeMode(entry.key);
                        controller.updateConfig(
                          controller.config.value.copyWith(
                            themeMode: entry.key.name,
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Delete account dialog ──
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

  // ── Clear data dialog ──
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

/// Small muted heading above a settings group.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A rounded container grouping several [_SettingsRow]s with dividers.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark
        ? AppPalette.outlineDark
        : AppPalette.outlineLight;

    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(height: 1, indent: 52, color: dividerColor));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor),
      ),
      child: Column(children: items),
    );
  }
}

/// Standard row: icon + title + optional trailing value + chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                value!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          Icon(
            FeatherIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}

/// Toggle row: icon + title + Switch.
class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: theme.colorScheme.primary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
