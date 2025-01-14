import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/game_detail.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:ludicapp/core/widgets/rating_modal.dart';
import 'package:ludicapp/features/profile/presentation/related_games_page.dart';


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
  final List<Image> _cachedImages = [];
  bool _areImagesLoaded = false;
  bool _isExpandedSummary = false;
  int? _userRating;

  @override
  void initState() {
    super.initState();
    _fetchGameDetail();
  }

  Future<void> _preloadImages() async {
    if (_gameDetail != null && _gameDetail!.screenshots.isNotEmpty) {
      for (String imageUrl in _gameDetail!.screenshots) {
        final image = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 220,
        );
        _cachedImages.add(image);
      }
      // Preload images after UI is shown
      for (Image image in _cachedImages) {
        await precacheImage(image.image, context);
      }
      setState(() {
        _areImagesLoaded = true;
      });
    }
  }

  Future<void> _fetchGameDetail() async {
    try {
      final gameDetail = await _gameRepository.fetchGameDetails(widget.id);
      setState(() {
        _gameDetail = gameDetail;
        _isLoading = false;
      });
      if (_gameDetail != null && _gameDetail!.screenshots.isNotEmpty) {
        _generateBackgroundColor(_gameDetail!.screenshots[0]);
        // Start preloading images after UI is shown
        _preloadImages();
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching game detail: $error");
    }
  }

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Future<void> _generateBackgroundColor(String imageUrl) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(NetworkImage(imageUrl));
    setState(() {
      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      _backgroundColor = dominantColor.withOpacity(0.5);
    });
  }

  void _openImageGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(_gameDetail!.screenshots[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: _gameDetail!.screenshots.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: PageController(initialPage: initialIndex),
          ),
        ),
      ),
    );
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
                  Container(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Background blur image
                        Positioned(
                          top: -MediaQuery.of(context).size.height * 0.15,
                          left: 0,
                          right: 0,
                          child: Container(
                            foregroundDecoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.95),
                                    Colors.black,
                                  ],
                                  stops: const [0.3, 0.8, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.darken,
                              child: Image.network(
                                _gameDetail!.coverUrl ?? '',
                                height: MediaQuery.of(context).size.height * 0.9,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Blur overlay
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                        // Cover image in center
                        Center(
                          child: Container(
                            height: 180,
                            width: 135,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _gameDetail!.coverUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.error_outline, color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Back button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _gameDetail!.summary,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: _isExpandedSummary ? null : 3,
                          overflow: _isExpandedSummary ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpandedSummary = !_isExpandedSummary;
                            });
                          },
                          child: Text(
                            _isExpandedSummary ? 'See less' : 'Read more',
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

                  // Screenshots Section
                  if (_gameDetail!.screenshots.isNotEmpty)
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple[400]?.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.photo_library_outlined,
                                  color: Colors.purple[400],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Screenshots',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _gameDetail!.screenshots.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _openImageGallery(context, index),
                                  child: Container(
                                    width: 280,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            _gameDetail!.screenshots[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                          // Add gradient overlay
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.5),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

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

                  // Game Details Section
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
                        if (_gameDetail!.genres.isNotEmpty) ...[
                          const Text(
                            'Genres',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _gameDetail!.genres.map((genre) => 
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RelatedGamesPage(
                                        categoryTitle: genre,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    genre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildDetailRow('Release Date', _gameDetail!.releaseFullDate),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Publisher/Developer', 
                          _gameDetail!.companies?.join('\n') ?? 'Unknown',
                          useWrap: true
                        ),

                        // Websites Section (including social media and official)
                        if (_gameDetail!.websites.entries.where((entry) => 
                          ['OFFICIAL', 'INSTAGRAM', 'DISCORD', 'REDDIT', 'YOUTUBE', 'TWITCH', 'TWITTER']
                          .contains(entry.key.toUpperCase())).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Websites',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_gameDetail!.websites['OFFICIAL'] != null)
                                _buildSocialButton(
                                  'Official',
                                  FontAwesomeIcons.globe,
                                  _gameDetail!.websites['OFFICIAL']!,
                                ),
                              if (_gameDetail!.websites['INSTAGRAM'] != null)
                                _buildSocialButton(
                                  'Instagram',
                                  FontAwesomeIcons.instagram,
                                  _gameDetail!.websites['INSTAGRAM']!,
                                ),
                              if (_gameDetail!.websites['DISCORD'] != null)
                                _buildSocialButton(
                                  'Discord',
                                  FontAwesomeIcons.discord,
                                  _gameDetail!.websites['DISCORD']!,
                                ),
                              if (_gameDetail!.websites['REDDIT'] != null)
                                _buildSocialButton(
                                  'Reddit',
                                  FontAwesomeIcons.reddit,
                                  _gameDetail!.websites['REDDIT']!,
                                ),
                              if (_gameDetail!.websites['YOUTUBE'] != null)
                                _buildSocialButton(
                                  'YouTube',
                                  FontAwesomeIcons.youtube,
                                  _gameDetail!.websites['YOUTUBE']!,
                                ),
                              if (_gameDetail!.websites['TWITCH'] != null)
                                _buildSocialButton(
                                  'Twitch',
                                  FontAwesomeIcons.twitch,
                                  _gameDetail!.websites['TWITCH']!,
                                ),
                              if (_gameDetail!.websites['TWITTER'] != null)
                                _buildSocialButton(
                                  'Twitter',
                                  FontAwesomeIcons.twitter,
                                  _gameDetail!.websites['TWITTER']!,
                                ),
                            ],
                          ),
                        ],

                        // Themes Section
                        if (_gameDetail!.themes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Themes',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _gameDetail!.themes.map((theme) => 
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RelatedGamesPage(
                                        categoryTitle: theme,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
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
                              ),
                            ).toList(),
                          ),
                        ],

                        // Age Rating Section
                        if (_gameDetail!.ageRating != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Age Rating',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _gameDetail!.ageRating!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Where to Buy Section
                        if (_gameDetail!.websites.entries
                            .where((entry) => ['STEAM', 'EPICGAMES', 'GOG']
                                .contains(entry.key.toUpperCase()))
                            .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Where to Buy',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
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

  Widget _buildDetailRow(String label, String value, {bool isLink = false, VoidCallback? onTap, bool useWrap = false}) {
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
        if (useWrap)
          Text(
            value,
            style: TextStyle(
              color: isLink ? Colors.blue[300] : Colors.white,
              fontSize: 16,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          )
        else
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
    if (label == 'Seen') {
      final hasRating = _userRating != null;
      final ratingColor = hasRating ? _getRatingColor(_userRating!) : Colors.white;
      final ratingIcon = hasRating ? _getRatingIcon(_userRating!) : icon;
      
      return InkWell(
        onTap: () {
          if (hasRating) {
            _showReviewDialog();
          } else {
            _showRatingDialog();
          }
        },
        child: SizedBox(
          width: 60, // Sabit genişlik
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ratingIcon,
                color: ratingColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                hasRating ? _getRatingLabel(_userRating!) : label,
                style: TextStyle(
                  color: ratingColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 60, // Sabit genişlik
      child: InkWell(
        onTap: () {
          // TODO: Implement other actions
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Widget _buildSocialButton(String platform, IconData icon, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              platform,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final TextEditingController reviewController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  // Game Cover Image (blur)
                  Positioned(
                    top: -MediaQuery.of(context).size.height * 0.15,
                    left: 0,
                    right: 0,
                    child: Container(
                      foregroundDecoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                      ),
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.95),
                              Colors.black,
                            ],
                            stops: const [0.3, 0.8, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.darken,
                        child: Image.network(
                          _gameDetail!.coverUrl ?? '',
                          height: MediaQuery.of(context).size.height * 0.9,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Column(
                    children: [
                      // Pull indicator
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Rating Info
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getRatingColor(_userRating!).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRatingIcon(_userRating!),
                              color: _getRatingColor(_userRating!),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getRatingLabel(_userRating!),
                              style: TextStyle(
                                color: _getRatingColor(_userRating!),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Game Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _gameDetail!.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Review Input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Write your review',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TextField(
                                  controller: reviewController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: 'Share your thoughts about the game...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[700]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[700]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _getRatingColor(_userRating!),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: Text(
                                        'Maybe Later',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // TODO: Submit review
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  FontAwesomeIcons.circleCheck,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Review submitted!'),
                                              ],
                                            ),
                                            backgroundColor: _getRatingColor(_userRating!),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _getRatingColor(_userRating!),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Submit Review',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: MediaQuery.of(context).padding.bottom),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Amazing';
      default:
        return '';
    }
  }

  IconData _getRatingIcon(int rating) {
    switch (rating) {
      case 1:
        return FontAwesomeIcons.faceFrown;
      case 2:
        return FontAwesomeIcons.faceMeh;
      case 3:
        return FontAwesomeIcons.faceSmile;
      case 4:
        return FontAwesomeIcons.faceGrinStars;
      default:
        return FontAwesomeIcons.question;
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return const Color(0xFFE57373); // Soft Red
      case 2:
        return const Color(0xFFFFB74D); // Soft Orange
      case 3:
        return const Color(0xFF81C784); // Soft Green
      case 4:
        return const Color(0xFF9575CD); // Soft Purple
      default:
        return Colors.grey[400]!;
    }
  }

  String _getRatingActionText(int rating) {
    switch (rating) {
      case 1:
        return 'Not My Type';
      case 2:
        return 'It Was Okay';
      case 3:
        return 'Really Enjoyed It';
      case 4:
        return 'Absolutely Loved It!';
      default:
        return 'Maybe Later';
    }
  }

  void _showRatingDialog() {
    RatingModal.show(
      context,
      gameName: _gameDetail!.name,
      coverUrl: _gameDetail!.coverUrl ?? '',
      releaseYear: _gameDetail!.releaseFullDate,
      initialRating: _userRating,
      onRatingSelected: (rating) {
        setState(() {
          _userRating = rating;
        });
      },
    );
  }
}
