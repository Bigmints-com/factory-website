import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/record_controller.dart';
import 'insights_screen.dart';
import 'new_home_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatelessWidget {
  HomeShell({super.key});

  final NavigationController navController = Get.put(NavigationController());
  final RecordController recordController = Get.put(RecordController());

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.sticky_note_2_outlined),
      activeIcon: Icon(Icons.sticky_note_2),
      label: 'Notes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.auto_graph_outlined),
      activeIcon: Icon(Icons.auto_graph),
      label: 'Insights',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  final List<Widget> _screens = const [
    NewHomeScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Notes';
      case 1:
        return 'Insights';
      case 2:
        return 'Settings';
      default:
        return 'Notes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return Obx(() {
          final index = navController.index.value;
          return Scaffold(
            appBar: wide
                ? null
                : AppBar(
                    title: Text(_titleForIndex(index)),
                    actions: index == 2
                        ? null
                        : [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => navController.setIndex(2),
                            ),
                          ],
                  ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF0B0A12), const Color(0xFF1B1A2B)]
                      : [const Color(0xFFF7F3F0), const Color(0xFFF1EAFB)],
                ),
              ),
              child: Row(
                children: [
                  if (wide)
                    _PrimarySidebar(
                      currentIndex: index,
                      onSelect: navController.setIndex,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (wide)
                          _DesktopTopBar(
                            title: _titleForIndex(index),
                            showSettings: index != 2,
                            onSettings: () => navController.setIndex(2),
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _screens[index],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: wide
                ? null
                : BottomNavigationBar(
                    items: _navItems,
                    currentIndex: index,
                    onTap: navController.setIndex,
                    type: BottomNavigationBarType.fixed,
                  ),
            floatingActionButton: index == 0
                ? Obx(() {
                    final isRecording = recordController.isRecording.value;
                    final appController = Get.find<AppController>();

                    return FloatingActionButton(
                      onPressed: () {
                        if (!appController.config.value.hasApiKey &&
                            !isRecording) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('API Key Required'),
                              content: const Text(
                                'Please configure your OpenAI API key in Settings before recording.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    navController.setIndex(2);
                                  },
                                  child: const Text('Go to Settings'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        recordController.toggleRecording();
                      },
                      child: Icon(isRecording ? Icons.stop : Icons.mic),
                    );
                  })
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        });
      },
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.showSettings,
    required this.onSettings,
  });

  final String title;
  final bool showSettings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettings,
            ),
        ],
      ),
    );
  }
}

class _PrimarySidebar extends StatelessWidget {
  const _PrimarySidebar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1A2B) : const Color(0xFFFBF8F6),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE7E1DA),
          ),
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
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFFFF9DB5)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'V/T',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Voice-to-Thoughts',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F1B2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SidebarItem(
                label: 'Notes',
                icon: Icons.sticky_note_2_outlined,
                activeIcon: Icons.sticky_note_2,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _SidebarItem(
                label: 'Insights',
                icon: Icons.auto_graph_outlined,
                activeIcon: Icons.auto_graph,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              _SidebarItem(
                label: 'Settings',
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2A2938) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE7E1DA),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 20,
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF1F1B2E))
                  : (isDark ? Colors.white60 : const Color(0xFF6B657A)),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? (isDark ? Colors.white : const Color(0xFF1F1B2E))
                    : (isDark ? Colors.white60 : const Color(0xFF6B657A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
