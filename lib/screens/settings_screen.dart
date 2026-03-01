import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Account Profile'),
            subtitle: Text('Manage your account details (coming soon)'),
            trailing: Icon(Icons.chevron_right),
            enabled: false,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Appearance'),
            subtitle: Text('Change app theme (coming soon)'),
            trailing: Icon(Icons.chevron_right),
            enabled: false,
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
        ],
      ),
    );
  }
}
