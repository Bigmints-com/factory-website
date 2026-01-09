import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),

            // Appearance Section
            _SettingsSection(
              title: 'APPEARANCE',
              children: [
                Obx(
                  () => _SettingsTile(
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: themeController.isDarkMode.value,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // API Configuration Section
            _SettingsSection(
              title: 'API CONFIGURATION',
              children: [
                Obx(
                  () => _SettingsTile(
                    title: 'API & Models',
                    subtitle: controller.config.value.hasApiKey
                        ? 'Configured'
                        : 'Not configured',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _ApiConfigScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recording Section
            _SettingsSection(
              title: 'RECORDING',
              children: [
                _SettingsTile(
                  title: 'Silence Detection',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const _SilenceDetectionScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1A2B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// Sub-screens with progressive disclosure

class _ApiConfigScreen extends StatefulWidget {
  const _ApiConfigScreen();

  @override
  State<_ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<_ApiConfigScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late final TextEditingController _transcriptionController;

  @override
  void initState() {
    super.initState();
    final config = Get.find<AppController>().config.value;
    _apiKeyController = TextEditingController();
    _modelController = TextEditingController(text: config.model);
    _transcriptionController = TextEditingController(
      text: config.transcriptionModel,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('API & Models')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Key Section
          Text(
            'OPENAI API KEY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              controller.config.value.hasApiKey
                  ? 'API key is configured'
                  : 'No API key configured',
              style: TextStyle(
                fontSize: 14,
                color: controller.config.value.hasApiKey
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                    : (isDark
                          ? Colors.orange.shade300
                          : Colors.orange.shade700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  final trimmed = _apiKeyController.text.trim();
                  if (trimmed.isEmpty) return;

                  final ok = await controller.validateAndSaveApiKey(trimmed);
                  if (!context.mounted) return;

                  if (ok) {
                    _apiKeyController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API key saved successfully'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(controller.errorMessage.value)),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Models Section
          Text(
            'ANALYSIS MODEL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              hintText: 'gpt-4o-mini',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'TRANSCRIPTION MODEL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _transcriptionController,
            decoration: const InputDecoration(
              hintText: 'whisper-1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await controller.updateConfig(
                controller.config.value.copyWith(
                  model: _modelController.text.trim(),
                  transcriptionModel: _transcriptionController.text.trim(),
                ),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Models updated')));
            },
            child: const Text('Save Models'),
          ),
        ],
      ),
    );
  }
}

class _SilenceDetectionScreen extends StatefulWidget {
  const _SilenceDetectionScreen();

  @override
  State<_SilenceDetectionScreen> createState() =>
      _SilenceDetectionScreenState();
}

class _SilenceDetectionScreenState extends State<_SilenceDetectionScreen> {
  late final TextEditingController _silenceController;

  @override
  void initState() {
    super.initState();
    final config = Get.find<AppController>().config.value;
    _silenceController = TextEditingController(
      text: config.silenceSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _silenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Silence Detection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'SILENCE THRESHOLD (SECONDS)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _silenceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '3',
              border: OutlineInputBorder(),
              helperText: 'Recording stops after this many seconds of silence',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final value = int.tryParse(_silenceController.text.trim());
              if (value == null || value < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
                return;
              }

              await controller.updateConfig(
                controller.config.value.copyWith(silenceSeconds: value),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Silence threshold updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BucketsScreen extends StatefulWidget {
  const _BucketsScreen();

  @override
  State<_BucketsScreen> createState() => _BucketsScreenState();
}

class _BucketsScreenState extends State<_BucketsScreen> {
  late final TextEditingController _bucketsController;

  @override
  void initState() {
    super.initState();
    final config = Get.find<AppController>().config.value;
    _bucketsController = TextEditingController(text: config.buckets.join(', '));
  }

  @override
  void dispose() {
    _bucketsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Buckets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'TOPIC BUCKETS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bucketsController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Work, Personal, Ideas',
              border: OutlineInputBorder(),
              helperText: 'Comma-separated list of topics',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final buckets = _bucketsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              await controller.updateConfig(
                controller.config.value.copyWith(buckets: buckets),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Buckets updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
