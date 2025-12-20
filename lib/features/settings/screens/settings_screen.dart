/// Settings Screen
/// 
/// Main settings page with navigation to master data management.

library;

import 'package:flutter/material.dart';

import 'breeds_settings_screen.dart';
import 'blocks_settings_screen.dart';
import 'finance_categories_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Data Master'),
          _SettingsTile(
            icon: Icons.apartment,
            title: 'Block Kandang',
            subtitle: 'Kelola gedung/area kandang',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlocksSettingsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.pets,
            title: 'Ras (Breeds)',
            subtitle: 'Kelola jenis/ras ternak',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BreedsSettingsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.category,
            title: 'Kategori Keuangan',
            subtitle: 'Kelola kategori pemasukan & pengeluaran',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceCategoriesSettingsScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'Aplikasi'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'DSFarm v1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DSFarm',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 DSFarm',
      children: [
        const SizedBox(height: 16),
        const Text('Aplikasi manajemen peternakan kelinci.'),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
