import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/injection_container.dart';

class AiConfigurationPage extends StatefulWidget {
  const AiConfigurationPage({super.key});

  @override
  State<AiConfigurationPage> createState() => _AiConfigurationPageState();
}

class _AiConfigurationPageState extends State<AiConfigurationPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final GeminiService _geminiService = sl<GeminiService>();
  bool _isAutoSwitchEnabled = true;
  bool _isObscured = true;
  bool _isLoading = false;
  List<String> _apiKeys = [];

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keys = await _geminiService.getApiKeys();
    setState(() {
      _apiKeys = keys;
    });
  }

  Future<void> _saveKey() async {
    final newKey = _apiKeyController.text.trim();
    if (newKey.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _geminiService.saveApiKey(newKey);
      await _loadKeys();
      _apiKeyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New API Key added to pool'),
            backgroundColor: AppTheme.kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKey(String key) async {
    await _geminiService.deleteApiKey(key);
    await _loadKeys();
  }

  String _maskKey(String key) {
    if (key.length < 8) return "••••••••";
    return "••••${key.substring(key.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildAutoSwitchToggle(),
                  const SizedBox(height: 32),
                  _buildAddConnectionForm(),
                  const SizedBox(height: 32),
                  _buildKeyPoolList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.kBackgroundColor.withOpacity(0.8),
      floating: true,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'SONIC ASSISTANT',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONFIGURATION',
          style: TextStyle(
            color: AppTheme.kPrimaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'API ENGINES',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 48,
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Manage your neural connections and orchestration fallbacks for the Sonic Assistant environment.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.kOnSurfaceVariantColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSwitchToggle() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerHighestColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.alt_route, color: AppTheme.kPrimaryColor),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Switch Engine',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Enable smart fallback logic',
                  style: TextStyle(
                    color: AppTheme.kOnSurfaceVariantColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAutoSwitchEnabled,
            onChanged: (v) => setState(() => _isAutoSwitchEnabled = v),
            activeThumbColor: AppTheme.kPrimaryColor,
            activeTrackColor: AppTheme.kPrimaryColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildAddConnectionForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Connection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildLabel('SELECT PROVIDER'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceContainerHighestColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Google Gemini',
                isExpanded: true,
                dropdownColor: AppTheme.kSurfaceContainerHighestColor,
                items:
                    [
                          'OpenAI GPT-4o',
                          'Anthropic Claude',
                          'Google Gemini',
                          'Mistral Large 2',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel('SECRET KEY'),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _isObscured,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.kSurfaceContainerHighestColor,
              hintText: 'sk-••••••••••••••••',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.kOnSurfaceVariantColor,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _isLoading ? null : _saveKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.kPrimaryColor,
                    AppTheme.kPrimaryContainerColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kPrimaryColor.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: Colors.black, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Establish Connector',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPoolList() {
    if (_apiKeys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API KEY POOL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.kOnSurfaceVariantColor,
          ),
        ),
        const SizedBox(height: 16),
        ..._apiKeys.map(
          (key) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceContainerLowColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: AppTheme.kPrimaryColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _maskKey(key),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _deleteKey(key),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppTheme.kOnSurfaceVariantColor,
        letterSpacing: 2,
      ),
    );
  }
}
