import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';

class MobileInsights extends StatelessWidget {
  const MobileInsights({
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: mainContent),
        const SliverToBoxAdapter(child: Divider(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(child: todoPanel),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
