import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:get/get.dart';
import '../../controllers/record_controller.dart';
import '../../controllers/theme_controller.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.index,
    required this.title,
    required this.body,
    required this.onSelect,
    required this.onRecord,
    this.actions,
    this.isSearching = false,
    this.searchQuery = '',
    this.onSearchChanged,
    this.onSearchToggle,
  });

  final int index;
  final String title;
  final Widget body;
  final ValueChanged<int> onSelect;
  final VoidCallback onRecord;
  final List<Widget>? actions;
  final bool isSearching;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchToggle;

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
      body: Column(
        children: [
          if (isSearching)
            _MobileSearchBar(
              query: searchQuery,
              onChanged: onSearchChanged,
              onClose: onSearchToggle,
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          height: 65,
          elevation: 0,
          backgroundColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(FeatherIcons.fileText, size: 20),
              selectedIcon: Icon(FeatherIcons.fileText, size: 20),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(FeatherIcons.trendingUp, size: 20),
              selectedIcon: Icon(FeatherIcons.trendingUp, size: 20),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(FeatherIcons.checkSquare, size: 20),
              selectedIcon: Icon(FeatherIcons.checkSquare, size: 20),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(FeatherIcons.settings, size: 20),
              selectedIcon: Icon(FeatherIcons.settings, size: 20),
              label: 'Settings',
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        final isRecording = recordController.isRecording.value;
        return SizedBox(
          height: 64,
          width: 64,
          child: FloatingActionButton(
            onPressed: onRecord,
            elevation: 4,
            backgroundColor: isRecording
                ? AppPalette.danger
                : AppPalette.primary,
            shape: const CircleBorder(),
            child: isRecording
                ? const Icon(FeatherIcons.square, color: Colors.white, size: 24)
                : const Icon(FeatherIcons.mic, color: Colors.white, size: 28),
          ),
        );
      }),
    );
  }
}

class _MobileSearchBar extends StatefulWidget {
  const _MobileSearchBar({
    required this.query,
    required this.onChanged,
    required this.onClose,
  });

  final String query;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClose;

  @override
  State<_MobileSearchBar> createState() => _MobileSearchBarState();
}

class _MobileSearchBarState extends State<_MobileSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _MobileSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search notes...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              _controller.clear();
              widget.onChanged?.call('');
              widget.onClose?.call();
            },
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
