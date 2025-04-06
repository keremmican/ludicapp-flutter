import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Using font_awesome for icons
import 'package:url_launcher/url_launcher.dart'; // To launch URLs

class FollowUsSection extends StatelessWidget {
  const FollowUsSection({super.key});

  // Define social media links (Replace with your actual links)
  static const String _instagramUrl = 'https://www.instagram.com/your_profile';
  static const String _discordUrl = 'https://discord.gg/your_invite';
  static const String _twitterUrl = 'https://twitter.com/your_handle';

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error - e.g., show a snackbar
      print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow Us',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute icons evenly
            children: [
              _buildSocialIcon(
                icon: FontAwesomeIcons.instagram,
                url: _instagramUrl,
                color: Colors.pinkAccent, // Example color
                context: context,
              ),
              _buildSocialIcon(
                icon: FontAwesomeIcons.discord,
                url: _discordUrl,
                color: Colors.indigoAccent, // Example color
                context: context,
              ),
              _buildSocialIcon(
                icon: FontAwesomeIcons.twitter, // Or FontAwesomeIcons.xTwitter
                url: _twitterUrl,
                color: Colors.lightBlue, // Example color
                context: context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required String url,
    required Color color,
    required BuildContext context,
  }) {
    return IconButton(
      icon: FaIcon(icon, size: 30.0, color: color),
      tooltip: 'Follow us on ${icon.toString().split('.').last}', // Basic tooltip
      onPressed: () => _launchUrl(url),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(12.0), // Add some padding
        shape: RoundedRectangleBorder( // Optional: Add a background shape
          borderRadius: BorderRadius.circular(12.0),
        ),
        // Add hover/focus effects if desired
      ),
    );
  }
} 