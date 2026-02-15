import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/record_controller.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.index,
    required this.title,
    required this.body,
    required this.onSelect,
    required this.onRecord,
    this.actions,
  });

  final int index;
  final String title;
  final Widget body;
  final ValueChanged<int> onSelect;
  final VoidCallback onRecord;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recordController = Get.find<RecordController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleMedium),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        height: 65, // Slightly taller for better touch targets
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.noteSticky, size: 20),
            selectedIcon: const FaIcon(
              FontAwesomeIcons.solidNoteSticky,
              size: 20,
              color: Colors.white,
            ),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.chartLine, size: 20),
            selectedIcon: const FaIcon(
              FontAwesomeIcons.arrowTrendUp,
              size: 20,
              color: Colors.white,
            ),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: const FaIcon(FontAwesomeIcons.gear, size: 20),
            selectedIcon: const FaIcon(
              FontAwesomeIcons.gear,
              size: 20,
              color: Colors.white,
            ),
            label: 'Settings',
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        final isRecording = recordController.isRecording.value;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SizedBox(
          height: 64, // Standard large FAB
          width: 64,
          child: FloatingActionButton(
            onPressed: onRecord,
            elevation: 4, // Add elevation for standard FAB look
            backgroundColor: isRecording
                ? Colors.red
                : (isDark ? Colors.white : Colors.black),
            shape: const CircleBorder(),
            child: isRecording
                ? const FaIcon(
                    FontAwesomeIcons.stop,
                    color: Colors.white,
                    size: 24,
                  )
                : FaIcon(
                    FontAwesomeIcons.microphone,
                    color: isDark ? Colors.black : Colors.white,
                    size: 28,
                  ),
          ),
        );
      }),
    );
  }
}
