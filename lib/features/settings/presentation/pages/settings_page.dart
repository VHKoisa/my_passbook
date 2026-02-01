import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            _ProfileSection(),
            const SizedBox(height: 16),

            // Settings Groups
            _SettingsGroup(
              title: 'Preferences',
              items: [
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: 'Light',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.currency_rupee,
                  title: 'Currency',
                  subtitle: 'INR (₹)',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SettingsGroup(
              title: 'Notifications',
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                _SettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Email Reports',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),
                _SettingsItem(
                  icon: Icons.warning_amber_outlined,
                  title: 'Budget Alerts',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SettingsGroup(
              title: 'Security',
              items: [
                _SettingsItem(
                  icon: Icons.fingerprint,
                  title: 'Biometric Lock',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SettingsGroup(
              title: 'Data',
              items: [
                _SettingsItem(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Backup Data',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.cloud_download_outlined,
                  title: 'Restore Data',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.file_download_outlined,
                  title: 'Export to CSV',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SettingsGroup(
              title: 'About',
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement logout
                  },
                  icon: const Icon(Icons.logout, color: AppColors.expense),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.expense),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: const BorderSide(color: AppColors.expense),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'john.doe@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Navigate to edit profile
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
