import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';

class DesktopInsights extends StatelessWidget {
  const DesktopInsights({
    super.key,
    required this.mainContent,
    required this.todoPanel,
    required this.controller,
  });

  final Widget mainContent;
  final Widget todoPanel;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: mainContent),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: todoPanel),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
