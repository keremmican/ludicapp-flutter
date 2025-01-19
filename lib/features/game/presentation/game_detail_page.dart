import 'package:flutter/material.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
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
import 'package:ludicapp/core/widgets/review_modal.dart';
import 'package:ludicapp/core/providers/blurred_background_provider.dart';

class GameDetailPage extends StatefulWidget {
  final Game game;
  final bool fromSearch;

  const GameDetailPage({
    Key? key, 
    required this.game,
    this.fromSearch = false,
  }) : super(key: key);

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final _backgroundProvider = BlurredBackgroundProvider();
  final _gameRepository = GameRepository();
  final List<Image> _cachedImages = [];
  bool _areImagesLoaded = false;
  bool _isExpandedSummary = false;
  int? _userRating;
  late Game _game;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    
    // Clear previous background cache and set new background
    _backgroundProvider.clearCache();
    if (_game.coverUrl != null) {
      _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.coverUrl);
    }
    
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (widget.fromSearch) {
      setState(() => _isLoading = true);
      try {
        final gameDetail = await _gameRepository.fetchGameDetails(_game.gameId);
        if (mounted) {
          setState(() {
            _game = Game.fromGameSummary(gameDetail.toGameSummary());
            _isLoading = false;
          });
          // After getting full details, update the background if cover URL has changed
          if (_game.coverUrl != null && _game.coverUrl != widget.game.coverUrl) {
            _backgroundProvider.clearCache();
            _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.coverUrl);
          }
          _preloadImages();
        }
      } catch (e) {
        print('Error loading game details: $e'); // Debug için
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _preloadImages();
    }
  }

  Future<void> _preloadImages() async {
    // Cache cover image
    if (_game.coverUrl != null) {
      _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.coverUrl);
    }

    if (_game.screenshots.isNotEmpty) {
      // Get preloaded screenshots or load them if not available
      final preloadedImages = Game.getPreloadedScreenshots(_game.gameId);
      if (preloadedImages != null) {
        _cachedImages.addAll(preloadedImages);
        for (final image in preloadedImages) {
          await precacheImage(image.image, context);
        }
      } else {
        // Cache screenshots
        for (final screenshot in _game.screenshots) {
          _backgroundProvider.cacheBackground('${_game.gameId}_${screenshot.hashCode}', screenshot);
          final image = Image.network(screenshot);
          _cachedImages.add(image);
          await precacheImage(image.image, context);
        }
      }
      
      if (mounted) {
        setState(() {
          _areImagesLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clear background cache when leaving the page
    _backgroundProvider.clearCache();
    super.dispose();
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
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(_game.screenshots[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: _game.screenshots.length,
            loadingBuilder: (context, event) => Center(
              child: Container(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
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

  void _openCoverImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (BuildContext context, _, __) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Blur effect
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 20 * value,
                          sigmaY: 20 * value,
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(0.5 * value),
                        ),
                      );
                    },
                  ),
                  // Hero image
                  Center(
                    child: GestureDetector(
                      onTap: (){ /* Prevent tap from propagating */ },
                      child: Hero(
                        tag: 'cover_${_game.gameId}',
                        flightShuttleBuilder: (
                          BuildContext flightContext,
                          Animation<double> animation,
                          HeroFlightDirection flightDirection,
                          BuildContext fromHeroContext,
                          BuildContext toHeroContext,
                        ) {
                          return Material(
                            color: Colors.transparent,
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final double scale = Curves.easeOutCubic.transform(animation.value);
                                
                                // Calculate aspect ratio based on original image dimensions
                                final double originalAspectRatio = 135 / 180; // width/height of original image
                                final double targetWidth = MediaQuery.of(context).size.width * 0.7;
                                final double targetHeight = targetWidth / originalAspectRatio;
                                
                                // Interpolate between original and target sizes
                                final double currentWidth = 135 + (targetWidth - 135) * scale;
                                final double currentHeight = 180 + (targetHeight - 180) * scale;
                                
                                return Container(
                                  width: currentWidth,
                                  height: currentHeight,
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
                                      _game.coverUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.error_outline, color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7 / (135/180), // Maintain aspect ratio
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
                                _game.coverUrl ?? '',
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cachedBackground = _backgroundProvider.getBackground(_game.gameId.toString());

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (_game.screenshots.isNotEmpty) {
      return Scaffold(
        body: Stack(
          children: [
            // Background image with blur
            Positioned.fill(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: cachedBackground != null
                    ? Image(
                        image: cachedBackground,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.black);
                        },
                      )
                    : Image.network(
                        _game.screenshots[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.black);
                        },
                      ),
              ),
            ),

            // Blur overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
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
                                  _game.coverUrl ?? '',
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
                            child: GestureDetector(
                              onTap: () => _openCoverImage(context),
                              child: Hero(
                                tag: 'cover_${_game.gameId}',
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
                                      _game.coverUrl ?? '',
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
                            _game.name,
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
                        onPressed: _game.gameVideo != null
                            ? () => _launchUrl(_game.gameVideo!)
                            : null,
                        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                        label: const Text(
                          "Watch Trailer",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _game.gameVideo != null
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
                            _game.summary ?? 'No description available.',
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
                      mainAxisAlignment: _userRating != null 
                        ? MainAxisAlignment.center 
                        : MainAxisAlignment.spaceEvenly,
                      children: _userRating != null
                        ? [
                            _buildActionButton(FontAwesomeIcons.shareFromSquare, 'Share'),
                            _buildActionButton(FontAwesomeIcons.circleCheck, 'Seen'),
                          ]
                        : [
                            _buildActionButton(FontAwesomeIcons.shareFromSquare, 'Share'),
                            _buildActionButton(FontAwesomeIcons.eyeSlash, 'Hide'),
                            _buildActionButton(FontAwesomeIcons.circleCheck, 'Seen'),
                            _buildActionButton(FontAwesomeIcons.bookmark, 'Save'),
                          ],
                    ),

                    const SizedBox(height: 16),

                    // Screenshots Section
                    if (_game.screenshots.isNotEmpty)
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
                                itemCount: _game.screenshots.length,
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
                                              _game.screenshots[index],
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

                    // Time to Beat Section
                    if (_game.hastilyGameTime != null || 
                        _game.normallyGameTime != null || 
                        _game.completelyGameTime != null)
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildTimeInfoCard(
                                  'Hastily',
                                  _formatGameTime(_game.hastilyGameTime),
                                  const Color(0xFFFFB74D),
                                ),
                                _buildTimeInfoCard(
                                  'Normally',
                                  _formatGameTime(_game.normallyGameTime),
                                  const Color(0xFF81C784),
                                ),
                                _buildTimeInfoCard(
                                  'Completely',
                                  _formatGameTime(_game.completelyGameTime),
                                  const Color(0xFF9575CD),
                                ),
                              ],
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
                        if (_game.totalRating != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber[400],
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${_game.totalRating!.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          _buildDetailRow('Platforms', _game.platforms.join(', ')),
                          const SizedBox(height: 12),
                          if (_game.genres.isNotEmpty) ...[
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
                              children: _game.genres.map((genre) => 
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
                          _buildDetailRow('Release Date', _game.releaseDate?.isEmpty ?? true ? 'N/A' : _game.releaseDate!),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Publisher/Developer', 
                            _getCompanyInfo(),
                            useWrap: true
                          ),

                          // Websites Section (including social media and official)
                          if (_game.websites?.entries.where((entry) => 
                            ['OFFICIAL', 'INSTAGRAM', 'DISCORD', 'REDDIT', 'YOUTUBE', 'TWITCH', 'TWITTER']
                            .contains(entry.key.toUpperCase())).isNotEmpty ?? false) ...[
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
                                if (_game.websites?['OFFICIAL'] != null)
                                  _buildSocialButton(
                                    'Official',
                                    FontAwesomeIcons.globe,
                                    _game.websites!['OFFICIAL']!,
                                  ),
                                if (_game.websites?['INSTAGRAM'] != null)
                                  _buildSocialButton(
                                    'Instagram',
                                    FontAwesomeIcons.instagram,
                                    _game.websites!['INSTAGRAM']!,
                                  ),
                                if (_game.websites?['DISCORD'] != null)
                                  _buildSocialButton(
                                    'Discord',
                                    FontAwesomeIcons.discord,
                                    _game.websites!['DISCORD']!,
                                  ),
                                if (_game.websites?['REDDIT'] != null)
                                  _buildSocialButton(
                                    'Reddit',
                                    FontAwesomeIcons.reddit,
                                    _game.websites!['REDDIT']!,
                                  ),
                                if (_game.websites?['YOUTUBE'] != null)
                                  _buildSocialButton(
                                    'YouTube',
                                    FontAwesomeIcons.youtube,
                                    _game.websites!['YOUTUBE']!,
                                  ),
                                if (_game.websites?['TWITCH'] != null)
                                  _buildSocialButton(
                                    'Twitch',
                                    FontAwesomeIcons.twitch,
                                    _game.websites!['TWITCH']!,
                                  ),
                                if (_game.websites?['TWITTER'] != null)
                                  _buildSocialButton(
                                    'Twitter',
                                    FontAwesomeIcons.twitter,
                                    _game.websites!['TWITTER']!,
                                  ),
                              ],
                            ),
                          ],

                          // Themes Section
                          if (_game.themes.isNotEmpty && _game.themes.any((theme) => theme.isNotEmpty)) ...[
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
                              children: _game.themes.map((theme) => 
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
                          if (_game.pegiAgeRating != null || true) ...[
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
                                  _formatAgeRating(_game.pegiAgeRating),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Where to Buy Section
                          if (_game.websites?.entries
                              .where((entry) => ['STEAM', 'EPICGAMES', 'GOG']
                                  .contains(entry.key.toUpperCase()))
                                  .isNotEmpty ?? false) ...[
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
                                children: _game.websites?.entries
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
                                    .toList() ?? [],
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

    // Error state
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
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
                  _initializeGame(); // Retry loading
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
      "Hastily": Color(0xFFFFB74D),
      "Normally": Color(0xFF81C784),
      "Completely": Color(0xFF9575CD),
    };

    final cardColor = timeColors[label] ?? color;

    return Container(
      width: 100, // Sabit genişlik
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
        mainAxisSize: MainAxisSize.min, // Minimum yükseklik
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
    ReviewModal.show(
      context,
      gameName: _game.name,
      coverUrl: _game.coverUrl ?? '',
      releaseYear: _game.releaseFullDate,
      onReviewSubmitted: (review) {
        // TODO: Submit review
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
      gameName: _game.name,
      coverUrl: _game.coverUrl ?? '',
      releaseYear: _game.releaseFullDate,
      initialRating: _userRating,
      onRatingSelected: (rating) {
        setState(() {
          _userRating = rating;
        });
      },
    );
  }

  String _formatGameTime(int? seconds) {
    if (seconds == null || seconds == 0) {
      return 'N/A';
    }
    final hours = (seconds / 3600).round();
    return '${hours}h';
  }

  String _formatAgeRating(String? ageRating) {
    if (ageRating == null) return 'N/A';
    switch (ageRating) {
      case 'Three': return '+3';
      case 'Seven': return '+7';
      case 'Twelve': return '+12';
      case 'Sixteen': return '+16';
      case 'Eighteen': return '+18';
      default: return ageRating;
    }
  }

  String _getCompanyInfo() {
    if (_game.companies.isEmpty) {
      return 'N/A';
    }
    final nonEmptyCompanies = _game.companies.where((company) => company.isNotEmpty).toList();
    if (nonEmptyCompanies.isEmpty) {
      return 'N/A';
    }
    return nonEmptyCompanies.join('\n');
  }
}
