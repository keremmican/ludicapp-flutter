import 'package:flutter/cupertino.dart'; // Add Cupertino import
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
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    // final Color linkColor = CupertinoColors.link.resolveFrom(context); // No longer needed for icons

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Adjust padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow Us',
            // Apply the theme text style directly, forcing color
            style: theme.textTheme.navTitleTextStyle.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16.0), // Adjust spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Use spaceAround for better distribution
            children: [
              _buildSocialIcon(
                icon: FontAwesomeIcons.instagram,
                url: _instagramUrl,
                // Restore original color
                color: Colors.pinkAccent,
                context: context,
              ),
              _buildSocialIcon(
                icon: FontAwesomeIcons.discord,
                url: _discordUrl,
                // Restore original color
                color: Colors.indigoAccent,
                context: context,
              ),
              _buildSocialIcon(
                icon: FontAwesomeIcons.twitter, // Or FontAwesomeIcons.xTwitter
                url: _twitterUrl,
                // Restore original color
                color: Colors.lightBlue,
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
    // Use CupertinoButton for a more native feel
    return CupertinoButton(
      padding: const EdgeInsets.all(10.0), // Adjust padding
      minSize: 40, // Ensure minimum tappable area
      child: FaIcon(icon, size: 28.0, color: color), // Adjust icon size
      onPressed: () => _launchUrl(url),
    );

    // Previous IconButton implementation (commented out)
    // return IconButton(
    //   icon: FaIcon(icon, size: 30.0, color: color),
    //   tooltip: 'Follow us on ${icon.toString().split('.').last}', // Basic tooltip
    //   onPressed: () => _launchUrl(url),
    //   style: IconButton.styleFrom(
    //     padding: const EdgeInsets.all(12.0), // Add some padding
    //     shape: RoundedRectangleBorder( // Optional: Add a background shape
    //       borderRadius: BorderRadius.circular(12.0),
    //     ),
    //     // Add hover/focus effects if desired
    //   ),
    // );
  }
} 