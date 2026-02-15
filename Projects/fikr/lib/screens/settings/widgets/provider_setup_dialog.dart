import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/app_controller.dart';
import '../../../models/llm_provider.dart';
import '../../../services/openai_service.dart';
import '../../../services/toast_service.dart';

class ProviderSetupDialog extends StatefulWidget {
  const ProviderSetupDialog({super.key});

  @override
  State<ProviderSetupDialog> createState() => _ProviderSetupDialogState();
}

class _ProviderSetupDialogState extends State<ProviderSetupDialog> {
  final _keyController = TextEditingController();
  bool _isLoading = false;
  bool _isValid = false;
  // ignore: prefer_final_fields
  LLMProviderType _selectedType = LLMProviderType.openai;

  @override
  void initState() {
    super.initState();
    _keyController.addListener(_validate);
  }

  void _validate() {
    final isValid = _keyController.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  Future<void> _submit() async {
    if (!_isValid) return;

    setState(() => _isLoading = true);
    try {
      final controller = Get.find<AppController>();
      final String id = '${_selectedType.name}-default';

      // Create new provider config
      final provider = LLMProvider(
        id: id,
        name: _selectedType.name,
        type: _selectedType,
        baseUrl: _selectedType.defaultBaseUrl,
      );

      final currentConfig = controller.config.value;

      // Validate API key by sending a test request
      final llmService = LLMService();
      final isKeyValid = await llmService.validateApiKey(
        _keyController.text.trim(),
        provider: provider,
      );
      if (!isKeyValid) {
        if (mounted) {
          ToastService.showError(
            context,
            title: 'Invalid API Key',
            description:
                'Could not connect with this key. Please check and try again.',
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Update config to single active provider
      final newConfig = currentConfig.copyWith(
        activeProvider: provider,
        analysisModel: _selectedType.defaultAnalysisModel,
        transcriptionModel: _selectedType.defaultTranscriptionModel,
      );

      // Save Config & Key
      await controller.updateConfig(newConfig);
      await controller.storage.saveApiKey(id, _keyController.text.trim());

      // Force refresh of recording state
      // (This is handled inside updateConfig -> _updateCanRecord, but good to know)

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ToastService.showSuccess(
          context,
          title: 'Ready to Record',
          description: 'AI Assistant configured successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          title: 'Setup Failed',
          description: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.wandMagicSparkles,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Unlock your AI Assistant',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect a provider to start turning your voice into structured, actionable notes instantly.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // Provider Selector (Simplified for now to just OpenAI as primary, but scalable)
                Text(
                  'Provider',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _ProviderCard(
                        title: 'OpenAI',
                        subtitle: 'Recommended for best accuracy',
                        assetPath: 'assets/images/openai_logo.svg',
                        isSelected: _selectedType == LLMProviderType.openai,
                        onTap:
                            () {}, // Only one option likely needed for quick start, or expand later
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'API Key',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'sk-...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1F2937)
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your key is stored securely on your device.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),

                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isLoading || !_isValid ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Start Recording',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'By connecting your provider, you agree to our terms of service and privacy policy.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://fikr.app/terms'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text('Terms of Service'),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://fikr.app/privacy'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text('Privacy Policy'),
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
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: SvgPicture.asset(
                  assetPath,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
