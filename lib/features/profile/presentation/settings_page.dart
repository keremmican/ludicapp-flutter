import 'package:flutter/material.dart';
import 'package:ludicapp/features/authentication/presentation/login_page.dart';
import 'package:ludicapp/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10.0),
        children: [
          // Account Section
          _buildSectionHeader('ACCOUNT'),
          _buildListTile('Profile', Icons.person, onTap: () {
            print('Profile clicked');
          }),
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

          // Support Section
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
            textColor: Colors.red, // Set red color for "Delete Account"
          ),

          const SizedBox(height: 20),

          // Sign Out Button
          _buildSignOutButton(context),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // List Tile
  Widget _buildListTile(String title, IconData icon,
      {required VoidCallback onTap, Color textColor = Colors.white}) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 16),
      ),
      leading: Icon(icon, color: textColor == Colors.red ? Colors.red : Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
    );
  }

  // Sign Out Button
  Widget _buildSignOutButton(BuildContext context) {
    return ListTile(
      onTap: () {
        // Clear navigation stack and redirect to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      },
      title: const Text(
        'Sign Out',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
    );
  }
}
