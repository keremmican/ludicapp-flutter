import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludicapp/features/authentication/presentation/login_page.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/services/repository/auth_repository.dart';
import 'package:ludicapp/services/repository/user_repository.dart';
import 'package:ludicapp/providers/theme_provider.dart';
import 'edit_profile_page.dart'; // Add import for the new page

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiService = ApiService();
  final _tokenService = TokenService();
  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();
  bool _profileUpdated = false;

  @override
  void dispose() {
    if (_profileUpdated) {
      // Eğer profil güncellendiyse, çıkış yaparken bu bilgiyi ilet
      Navigator.pop(context, 'updated');
    }
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final success = await _authRepository.signOut();
      
      if (!mounted) return;

      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/landing',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Logout Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode currentThemeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.appBarTheme.titleTextStyle),
        iconTheme: theme.appBarTheme.iconTheme,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10.0),
        children: [
          _buildSectionHeader('APPEARANCE'),
          _buildThemeSelectionTile(
            title: 'Light',
            mode: ThemeMode.light,
            currentMode: currentThemeMode,
            onChanged: (mode) => themeNotifier.setThemeMode(mode!),
            theme: theme,
          ),
          _buildThemeSelectionTile(
            title: 'Dark',
            mode: ThemeMode.dark,
            currentMode: currentThemeMode,
            onChanged: (mode) => themeNotifier.setThemeMode(mode!),
            theme: theme,
          ),
          _buildThemeSelectionTile(
            title: 'System Default',
            mode: ThemeMode.system,
            currentMode: currentThemeMode,
            onChanged: (mode) => themeNotifier.setThemeMode(mode!),
            theme: theme,
          ),

          const SizedBox(height: 20),

          _buildSectionHeader('ACCOUNT'),
          _buildListTile(
            'Profile',
            Icons.edit,
            onTap: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const EditProfilePage())
              );
              
              if (result == 'updated') {
                await _userRepository.refreshCurrentUserProfile();
                _profileUpdated = true;
              }
            },
          ),
          _buildListTile('Dashboard Setup', Icons.dashboard, onTap: () {
            print('Dashboard Setup clicked');
          }),
          _buildListTile('Additional Interests', Icons.interests, onTap: () {
            print('Additional Interests clicked');
          }),
          _buildListTile('Push Notifications', Icons.notifications, onTap: () {
            print('Push Notifications clicked');
          }),
          _buildListTile('Premium', Icons.star, onTap: () {
            print('Premium clicked');
          }),

          const SizedBox(height: 20),

          _buildSectionHeader('SUPPORT'),
          _buildListTile('FAQ', Icons.help_outline, onTap: () {
            print('FAQ clicked');
          }),
          _buildListTile('Add Missing Title', Icons.add_box, onTap: () {
            print('Add Missing Title clicked');
          }),
          _buildListTile('Report Issue / Feedback', Icons.feedback, onTap: () {
            print('Report Issue / Feedback clicked');
          }),
          _buildListTile('Terms Of Service', Icons.article, onTap: () {
            print('Terms Of Service clicked');
          }),
          _buildListTile('Privacy Policy', Icons.privacy_tip, onTap: () {
            print('Privacy Policy clicked');
          }),
          _buildListTile(
            'Delete Account',
            Icons.delete,
            onTap: () {
              print('Delete Account clicked');
            },
            textColor: colorScheme.error,
          ),

          const SizedBox(height: 20),

          _buildSignOutButton(context, colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon,
      {required VoidCallback onTap, Color? textColor}) {
    final theme = Theme.of(context);
    final effectiveTextColor = textColor ?? theme.listTileTheme.textColor ?? theme.colorScheme.onSurface;
    final iconColor = textColor ?? theme.listTileTheme.iconColor ?? theme.iconTheme.color;

    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(color: effectiveTextColor, fontSize: 16),
      ),
      leading: Icon(icon, color: iconColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
      trailing: Icon(Icons.arrow_forward_ios, color: theme.hintColor, size: 16),
    );
  }

  Widget _buildThemeSelectionTile({
    required String title,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode?> onChanged,
    required ThemeData theme,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
      value: mode,
      groupValue: currentMode,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
    );
  }

  Widget _buildSignOutButton(BuildContext context, Color color) {
    return ListTile(
      onTap: () => _handleLogout(context),
      title: Text(
        'Sign Out',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
    );
  }
}
