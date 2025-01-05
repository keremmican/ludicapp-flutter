import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/game_detail.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ludicapp/theme/app_theme.dart';


class GameDetailPage extends StatefulWidget {
  final int id;

  const GameDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  _GameDetailPageState createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final GameRepository _gameRepository = GameRepository();
  GameDetail? _gameDetail;
  bool _isLoading = true;
  Color? _backgroundColor;

  @override
  void initState() {
    super.initState();
    _fetchGameDetail();
  }
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Future<void> _fetchGameDetail() async {
    try {
      final gameDetail = await _gameRepository.fetchGameDetails(widget.id);
      setState(() {
        _gameDetail = gameDetail;
        _isLoading = false;
      });
      if (_gameDetail != null && _gameDetail!.screenshots.isNotEmpty) {
        _generateBackgroundColor(_gameDetail!.screenshots[0]);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching game detail: $error");
    }
  }

  Future<void> _generateBackgroundColor(String imageUrl) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(NetworkImage(imageUrl));
    setState(() {
      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      _backgroundColor = dominantColor.withOpacity(0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gameDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.videogame_asset_rounded,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'We couldn\'t load the game details at this moment. Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameDetailPage(id: widget.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _gameDetail!.screenshots.isNotEmpty
                ? Image.network(
                    _gameDetail!.screenshots[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.black);
                    },
                  )
                : Container(color: Colors.black),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _gameDetail!.screenshots.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _gameDetail!.screenshots[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 220,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text(
                                    'Screenshot not available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        if (_currentIndex > 0)
                          Positioned(
                            left: 10,
                            child: GestureDetector(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                        if (_currentIndex < _gameDetail!.screenshots.length - 1)
                          Positioned(
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "75% Match",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _gameDetail!.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_gameDetail!.genre} • ${_gameDetail!.releaseFullDate}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 10.0),
                    child: ElevatedButton.icon(
                      onPressed: _gameDetail!.gameVideo != null
                          ? () => _launchUrl(_gameDetail!.gameVideo!)
                          : null,
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: const Text(
                        "Watch Trailer",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gameDetail!.gameVideo != null
                            ? Colors.grey[800]
                            : Colors.grey[500]?.withOpacity(0.7),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _truncateText(_gameDetail!.summary, 4),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(FontAwesomeIcons.shareFromSquare, 'Share'),
                      _buildActionButton(FontAwesomeIcons.eyeSlash, 'Hide'),
                      _buildActionButton(FontAwesomeIcons.circleCheck, 'Seen'),
                      _buildActionButton(FontAwesomeIcons.bookmark, 'Save'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating section
                  if (_gameDetail!.totalRatingScore != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber[400],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_gameDetail!.totalRatingScore!.toStringAsFixed(1)} User Score",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // User Reviews Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "User Reviews",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemBuilder: (context, index) {
                            return _buildReviewCard();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to reviews page
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Show All Reviews",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Stats",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildStatCard(
                                "Players Completed",
                                "68%",
                                Colors.green,
                                0.68,
                                Icons.check_circle_outline,
                              ),
                              _buildStatCard(
                                "Average Playtime",
                                "32.5h",
                                Colors.blue,
                                0.75,
                                Icons.timer_outlined,
                              ),
                              _buildStatCard(
                                "Achievement Rate",
                                "45%",
                                Colors.amber,
                                0.45,
                                Icons.emoji_events_outlined,
                              ),
                              _buildStatCard(
                                "Currently Playing",
                                "1.2K",
                                Colors.purple,
                                0.82,
                                Icons.sports_esports,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_gameDetail!.hastilyGameTime != null || 
                      _gameDetail!.normallyGameTime != null || 
                      _gameDetail!.completelyGameTime != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[400]?.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.timer_outlined,
                                  color: Colors.blue[400],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Time to Beat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (_gameDetail!.hastilyGameTime != null)
                                _buildTimeInfoCard(
                                  'Hastily',
                                  (_gameDetail!.hastilyGameTime! / 3600).toStringAsFixed(1) + 'h',
                                  Colors.red[400]!,
                                ),
                              if (_gameDetail!.normallyGameTime != null)
                                _buildTimeInfoCard(
                                  'Normally',
                                  (_gameDetail!.normallyGameTime! / 3600).toStringAsFixed(1) + 'h',
                                  Colors.green[400]!,
                                ),
                              if (_gameDetail!.completelyGameTime != null)
                                _buildTimeInfoCard(
                                  'Completely',
                                  (_gameDetail!.completelyGameTime! / 3600).toStringAsFixed(1) + 'h',
                                  Colors.purple[400]!,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Game Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Platforms', _gameDetail!.platforms.join(', ')),
                        const SizedBox(height: 12),
                        _buildDetailRow('Genre', _gameDetail!.genre),
                        const SizedBox(height: 12),
                        _buildDetailRow('Publisher/Developer', _gameDetail!.companies?.join(', ') ?? 'Unknown'),
                        if (_gameDetail!.websites['OFFICIAL'] != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow('Website', _gameDetail!.websites['OFFICIAL']!,
                              isLink: true, onTap: () => _launchUrl(_gameDetail!.websites['OFFICIAL']!)),
                        ],
                      ],
                    ),
                  ),

                  if (_gameDetail!.themes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Themes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _gameDetail!.themes.map((theme) => 
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  theme,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ],
                      ),
                    ),

                  if (_gameDetail!.ageRating != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Age Rating: ${_gameDetail!.ageRating}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  if (_gameDetail!.websites.entries
                      .where((entry) => ['STEAM', 'EPICGAMES', 'GOG'].contains(entry.key.toUpperCase()))
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Where to Buy',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: _gameDetail!.websites.entries
                                  .where((entry) => ['STEAM', 'EPICGAMES', 'GOG']
                                      .contains(entry.key.toUpperCase()))
                                  .map((entry) => Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: GestureDetector(
                                          onTap: () => _launchUrl(entry.value),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildStoreIcon(entry.key),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatStoreName(entry.key),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLines) {
    final lines = text.split('\n');
    if (lines.length <= maxLines) return text;
    return lines.take(maxLines).join(' ') + '...';
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String platform) {
    IconData getIcon() {
      switch (platform.toUpperCase()) {
        case 'FACEBOOK':
          return FontAwesomeIcons.facebook;
        case 'INSTAGRAM':
          return FontAwesomeIcons.instagram;
        case 'TWITTER':
          return FontAwesomeIcons.twitter;
        case 'YOUTUBE':
          return FontAwesomeIcons.youtube;
        case 'TWITCH':
          return FontAwesomeIcons.twitch;
        case 'REDDIT':
          return FontAwesomeIcons.reddit;
        case 'DISCORD':
          return FontAwesomeIcons.discord;
        case 'STEAM':
          return FontAwesomeIcons.steam;
        case 'WIKIPEDIA':
          return FontAwesomeIcons.wikipediaW;
        default:
          return FontAwesomeIcons.globe;
      }
    }

    return Icon(
      getIcon(),
      color: Colors.white70,
      size: 24,
    );
  }

  Widget _buildStoreIcon(String platform) {
    String getIconPath() {
      switch (platform.toUpperCase()) {
        case 'STEAM':
          return 'lib/assets/icons/icons8-steam-48.png';
        case 'EPICGAMES':
          return 'lib/assets/icons/icons8-epic-games-48.png';
        case 'GOG':
          return 'lib/assets/icons/icons8-gog-galaxy-48.png';
        default:
          return '';
      }
    }

    return Image.asset(
      getIconPath(),
      width: 32,
      height: 32
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch $url');
    }
  }

  Widget _buildTimeInfoCard(String label, String time, Color color) {
    final Map<String, Color> timeColors = {
      'Hastily': Color(0xFFFFB74D),
      'Normally': Color(0xFF81C784),
      'Completely': Color(0xFF9575CD),
    };

    final cardColor = timeColors[label] ?? color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: TextStyle(
              color: cardColor.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: cardColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            value,
            style: TextStyle(
              color: isLink ? Colors.blue[300] : Colors.white,
              fontSize: 16,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // TODO: Implement action
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  "https://i.pravatar.cc/100",
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "John Doe",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber[400],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "4.5",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Great game! The story and gameplay mechanics are amazing. Highly recommended for all players.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, double progress, IconData icon) {
    final statColors = {
      "Players Completed": Color(0xFF66BB6A),
      "Average Playtime": Color(0xFF64B5F6),
      "Achievement Rate": Color(0xFFFFB74D),
      "Currently Playing": Color(0xFFBA68C8),
    };

    final cardColor = statColors[label] ?? color;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: cardColor.withOpacity(0.9),
            size: 24,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: cardColor.withOpacity(0.9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: cardColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cardColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(cardColor.withOpacity(0.7)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStoreName(String storeName) {
    switch (storeName.toUpperCase()) {
      case 'STEAM':
        return 'Steam';
      case 'EPICGAMES':
        return 'Epic Games';
      case 'GOG':
        return 'GOG';
      default:
        return storeName;
    }
  }
}
