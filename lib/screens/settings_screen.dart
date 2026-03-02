import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alray_app/providers/theme_provider.dart';
import 'package:alray_app/providers/auth_provider.dart';
import 'package:alray_app/utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:alray_app/services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useIndianSystem = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useIndianSystem = prefs.getBool('indian_system') ?? true;
      CurrencyUtils.useIndianSystem = _useIndianSystem;
    });
  }

  Future<void> _toggleCurrency(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('indian_system', value);
    setState(() {
      _useIndianSystem = value;
      CurrencyUtils.useIndianSystem = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ai_chat_fab_settings',
        onPressed: () => context.push('/chat'),
        backgroundColor: Colors.indigo,
        tooltip: 'AI Chat Assistant',
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account Profile'),
            subtitle: Text(user?.email ?? 'Not logged in'),
            trailing: const Icon(Icons.chevron_right),
            enabled: user != null,
            onTap: () => context.push('/settings/profile'),
          ),
          const Divider(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Biometric Login'),
                subtitle: const Text('Use fingerprint to sign in instantly'),
                value: auth.biometricEnabled,
                onChanged: (val) => auth.toggleBiometricLogin(val),
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.currency_exchange),
            title: const Text('Indian Unit System'),
            subtitle: const Text('Use Lakhs & Crores (instead of M/B)'),
            value: _useIndianSystem,
            onChanged: _toggleCurrency,
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('App Theme'),
                subtitle: Text(_getThemeName(themeProvider.currentTheme)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeProvider),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            subtitle: const Text('Real Estate Budget v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Real Estate Budget',
                applicationVersion: '1.0.0',
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy, color: Colors.blueAccent),
            title: const Text('Gemini API Key'),
            subtitle: const Text('Configure AI Assistant credentials'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showApiKeyDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        authProvider.logout();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.indigo:
        return 'Indigo Premium';
      case AppTheme.emerald:
        return 'Emerald Garden';
      case AppTheme.midnight:
        return 'Midnight Navy';
      case AppTheme.rose:
        return 'Rose Quartz';
    }
  }

  Color _getThemeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.indigo:
        return const Color(0xFF6750A4);
      case AppTheme.emerald:
        return Colors.teal;
      case AppTheme.midnight:
        return const Color(0xFF1A237E);
      case AppTheme.rose:
        return const Color(0xFF880E4F);
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTheme.values.map((theme) {
            return ListTile(
              leading: CircleAvatar(backgroundColor: _getThemeColor(theme)),
              title: Text(_getThemeName(theme)),
              trailing: themeProvider.currentTheme == theme
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setTheme(theme);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final aiService = AiService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    final currentKey = await aiService.getApiKey(userId);
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await aiService.setApiKey(userId, controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
