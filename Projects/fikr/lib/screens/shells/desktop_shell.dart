import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/record_controller.dart';
import '../../utils/assets.dart';
import '../note_detail_screen.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.index,
    required this.title,
    required this.body,
    required this.onSelect,
    required this.onRecord,
    required this.showFilters,
    required this.onToggleFilters,
    required this.onSettings,
    this.insightsActions,
  });

  final int index;
  final String title;
  final Widget body;
  final ValueChanged<int> onSelect;
  final VoidCallback onRecord;
  final bool showFilters;
  final VoidCallback onToggleFilters;
  final VoidCallback onSettings;
  final Widget? insightsActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PrimarySidebar(
          currentIndex: index,
          onSelect: onSelect,
          onRecord: onRecord,
        ),
        Expanded(
          child: Column(
            children: [
              _DesktopTopBar(
                title: title,
                showSettings: index != 2,
                onSettings: onSettings,
                actions: index == 0
                    ? [
                        IconButton(
                          onPressed: () async {
                            final appController = Get.find<AppController>();
                            final note = await appController.createEmptyNote();
                            if (context.mounted) {
                              NoteDetailScreen.show(context, note);
                            }
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 18,
                          ),
                          tooltip: 'New Note',
                        ),
                        Obx(() {
                          final appController = Get.find<AppController>();
                          if (appController.notes.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const FaIcon(
                                  FontAwesomeIcons.magnifyingGlass,
                                  size: 18,
                                ),
                                tooltip: 'Search',
                              ),
                              IconButton(
                                onPressed: onToggleFilters,
                                icon: FaIcon(
                                  showFilters
                                      ? FontAwesomeIcons.arrowUpWideShort
                                      : FontAwesomeIcons.filter,
                                  size: 18,
                                ),
                                tooltip: showFilters
                                    ? 'Hide Filters'
                                    : 'Show Filters',
                              ),
                            ],
                          );
                        }),
                      ]
                    : index == 1 && insightsActions != null
                    ? [insightsActions!]
                    : null,
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.showSettings,
    required this.onSettings,
    this.actions,
  });

  final String title;
  final bool showSettings;
  final VoidCallback onSettings;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _PrimarySidebar extends StatelessWidget {
  const _PrimarySidebar({
    required this.currentIndex,
    required this.onSelect,
    required this.onRecord,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: SvgPicture.asset(
                      Assets.getLogo(context),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fikr',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final recordController = Get.find<RecordController>();
                  final isRecording = recordController.isRecording.value;
                  return FilledButton.icon(
                    onPressed: onRecord,
                    icon: FaIcon(
                      isRecording
                          ? FontAwesomeIcons.stop
                          : FontAwesomeIcons.microphone,
                      size: 16,
                    ),
                    label: Text(isRecording ? 'Stop Recording' : 'Record'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isRecording ? Colors.red : null,
                      foregroundColor: isRecording ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              _SidebarItem(
                label: 'Notes',
                icon: FontAwesomeIcons.noteSticky,
                activeIcon: FontAwesomeIcons.noteSticky,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _SidebarItem(
                label: 'Insights',
                icon: FontAwesomeIcons.chartLine,
                activeIcon: FontAwesomeIcons.chartLine,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              _SidebarItem(
                label: 'Settings',
                icon: FontAwesomeIcons.gear,
                activeIcon: FontAwesomeIcons.gear,
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        leading: FaIcon(selected ? activeIcon : icon, size: 18),
        title: Text(label, style: theme.textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
        selectedColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
