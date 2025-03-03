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
import 'package:ludicapp/core/utils/date_formatter.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/user_game_info.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';

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
  final _libraryRepository = LibraryRepository();
  final _homeController = HomeController();
  final List<Image> _cachedImages = [];
  bool _areImagesLoaded = false;
  bool _isExpandedSummary = false;
  bool _showAllLanguages = false;
  int? _userRating;
  bool _isSaved = false;
  late Game _game;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    
    // Set user actions from the game object if available
    if (widget.game.userActions != null) {
      _userRating = widget.game.userActions!.userRating;
      _isSaved = widget.game.userActions!.isSaved ?? false;
    }
    
    // Clear previous background cache and set new background
    _backgroundProvider.clearCache();
    if (_game.coverUrl != null) {
      _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.coverUrl);
    }
    
    // Only initialize game details if coming from search
    if (widget.fromSearch) {
      _initializeGame();
    } else {
      _isLoading = false;
      _preloadImages();
    }
  }

  Future<void> _initializeGame() async {
    if (!widget.fromSearch) return;
    
    setState(() => _isLoading = true);
    try {
      // Fetch game details with user info
      final gameWithUserInfo = await _gameRepository.fetchGameDetailsWithUserInfo(_game.gameId);
      
      if (mounted) {
        setState(() {
          // Update game with user actions
          _game = gameWithUserInfo.toGame();
          _userRating = gameWithUserInfo.userActions?.userRating;
          _isSaved = gameWithUserInfo.userActions?.isSaved ?? false;
          _isLoading = false;
        });
        
        _preloadImages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _preloadImages() async {
    try {
      // Cache cover image
      if (_game.coverUrl != null && _game.gameId != null) {
        _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.coverUrl!);
      }

      if (_game.screenshots?.isNotEmpty ?? false) {
        // Get preloaded screenshots or load them if not available
        final preloadedImages = _game.gameId != null ? Game.getPreloadedScreenshots(_game.gameId!) : null;
        if (preloadedImages != null) {
          _cachedImages.addAll(preloadedImages);
          for (final image in preloadedImages) {
            if (mounted) {
              await precacheImage(image.image, context);
            }
          }
        } else {
          // Cache screenshots
          for (final screenshot in _game.screenshots!) {
            if (_game.gameId != null) {
              _backgroundProvider.cacheBackground('${_game.gameId}_${screenshot.hashCode}', screenshot);
            }
            final image = Image.network(screenshot);
            _cachedImages.add(image);
            if (mounted) {
              await precacheImage(image.image, context);
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _areImagesLoaded = true;
          });
        }
      }
    } catch (e) {
      print('Error preloading images: $e');
      if (mounted) {
        setState(() {
          _areImagesLoaded = false;
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
                              animation: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              ),
                              builder: (context, child) {
                                final progress = animation.value;
                                
                                // Calculate aspect ratio based on original image dimensions
                                final double originalAspectRatio = 135 / 180; // width/height of original image
                                final double targetWidth = MediaQuery.of(context).size.width * 0.5;
                                final double targetHeight = targetWidth / originalAspectRatio;
                                
                                // Interpolate between original and target sizes
                                final double currentWidth = 135 + (targetWidth - 135) * progress;
                                final double currentHeight = 180 + (targetHeight - 180) * progress;
                                
                                return Center(
                                  child: Container(
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
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.width * 0.5 * (180/135),
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
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cachedBackground = _game.gameId != null ? _backgroundProvider.getBackground(_game.gameId.toString()) : null;

    print('build - _isSaved: $_isSaved');
    print('build - userActions: ${widget.game.userActions}');
    if (widget.game.userActions != null) {
      print('build - userActions.isSaved: ${widget.game.userActions!.isSaved}');
    }

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

    // Error state
    if (_game == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load game details',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _initializeGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[300],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
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
                  : _game.screenshots?.isNotEmpty ?? false
                      ? Image.network(
                          _game.screenshots![0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.black);
                          },
                        )
                      : Container(color: Colors.black),
            ),
          ),

          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      children: [
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
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
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
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _game.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Text(
                              "75% Match",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Game Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _game.summary ?? 'No description available.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          maxLines: _isExpandedSummary ? null : 3,
                          overflow: _isExpandedSummary ? null : TextOverflow.ellipsis,
                        ),
                        if (_game.summary != null && _game.summary!.length > 150)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isExpandedSummary = !_isExpandedSummary;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              _isExpandedSummary ? 'Show Less' : 'Read More',
                              style: const TextStyle(
                                color: Colors.blue,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(FontAwesomeIcons.shareFromSquare, 'Share'),
                        const SizedBox(width: 50),
                        _buildActionButton(FontAwesomeIcons.eyeSlash, 'Hide'),
                        const SizedBox(width: 50),
                        _buildActionButton(FontAwesomeIcons.circleCheck, 'Seen'),
                        const SizedBox(width: 50),
                        InkWell(
                          onTap: _handleSaveGame,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                                color: _isSaved ? Colors.orange[400] : Colors.white70,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Save',
                                style: TextStyle(
                                  color: _isSaved ? Colors.orange[400] : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Divider(
                    color: Colors.grey.withOpacity(0.3), // Çizginin rengi
                    thickness: 1, // Çizginin kalınlığı
                    indent: 0, // Soldan boşluk
                    endIndent: 0, // Sağdan boşluk
                  ),

                  const SizedBox(height: 5),

                  // User Reviews Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_game.totalRating != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${_game.totalRating!.toStringAsFixed(1)}",
                                      style: TextStyle(
                                        color: Colors.amber[400],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
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
                                      const SizedBox(height: 12),
                                      const Expanded(
                                        child: Text(
                                          "Great game! The story and gameplay mechanics are amazing. Highly recommended for all players.",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to reviews page
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Show All Reviews",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(
                    color: Colors.grey.withOpacity(0.3), // Çizginin rengi
                    thickness: 1, // Çizginin kalınlığı
                    indent: 0, // Soldan boşluk
                    endIndent: 0, // Sağdan boşluk
                  ),

                  const SizedBox(height: 5),

                  // Screenshots Section
                  if (_game.screenshots?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _game.screenshots?.length ?? 0,
                              itemBuilder: (context, index) {
                                final screenshot = _game.screenshots?[index];
                                if (screenshot == null) return const SizedBox();
                                
                                return GestureDetector(
                                  onTap: () => _openImageGallery(context, index),
                                  child: Container(
                                    width: 280,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        screenshot,
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
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Divider(
                      color: Colors.grey.withOpacity(0.3),
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),

                    const SizedBox(height: 8),
                  ],

                  // Additional Details Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_game.platforms?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Platforms', _getPlatformsText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.genres?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Genres', _getGenresText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.themes?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Themes', _getThemesText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.releaseDate != null) ...[
                          _buildDetailRow('Release Date', DateFormatter.formatDate(_game.releaseDate!)),
                          const SizedBox(height: 16),
                        ],
                        if (_game.companies?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Publisher', _getPublisherText()),
                          const SizedBox(height: 16),
                          _buildDetailRow('Developer', _getDeveloperText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.gameModes?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Game Modes', _getGameModesText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.playerPerspectives?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Player Perspectives', _getPlayerPerspectivesText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.franchises?.isNotEmpty ?? false) ...[
                          _buildDetailRow('Franchises', _getFranchisesText()),
                          const SizedBox(height: 16),
                        ],
                        if (_game.pegiAgeRating != null)
                          _buildDetailRow('Age Rating', _formatAgeRating(_game.pegiAgeRating)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Divider(
                    color: Colors.grey.withOpacity(0.3),
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                  ),

                  const SizedBox(height: 8),

                  // Language Support Section
                  if (_game.languageSupports?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Language Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLanguageSupportsTable(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Divider(
                      color: Colors.grey.withOpacity(0.3),
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),

                    const SizedBox(height: 8),
                  ],

                  // Time to Beat Section
                  if (_game.hastilyGameTime != null || 
                      _game.normallyGameTime != null || 
                      _game.completelyGameTime != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time to Beat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeInfoCard(
                                'Hastily',
                                _formatGameTime(_game.hastilyGameTime),
                                Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _buildTimeInfoCard(
                                'Normally',
                                _formatGameTime(_game.normallyGameTime),
                                Colors.green,
                              ),
                              const SizedBox(width: 8),
                              _buildTimeInfoCard(
                                'Completely',
                                _formatGameTime(_game.completelyGameTime),
                                Colors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Divider(
                      color: Colors.grey.withOpacity(0.3),
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),

                    const SizedBox(height: 8),
                  ],

                  // Social Media & Websites Section
                  if (_game.websites?.entries.where((entry) => 
                    ['OFFICIAL', 'INSTAGRAM', 'DISCORD', 'REDDIT', 'YOUTUBE', 'TWITCH', 'TWITTER']
                    .contains(entry.key.toUpperCase())).isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Social Media & Websites',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
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
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Divider(
                      color: Colors.grey.withOpacity(0.3),
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),

                    const SizedBox(height: 8),
                  ],

                  // Where to Buy Section
                  if (_game.websites?.entries
                      .where((entry) => ['STEAM', 'EPICGAMES', 'GOG']
                          .contains(entry.key.toUpperCase()))
                          .isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Where to Buy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildStoreIcon(entry.key),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatStoreName(entry.key),
                                                  style: const TextStyle(
                                                    color: Colors.white,
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
                      ),
                    ),

                    const SizedBox(height: 14),

                    Divider(
                      color: Colors.grey.withOpacity(0.3),
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),

                    const SizedBox(height: 8),
                  ],

                  // Videos Section
                  if (_game.gameVideos != null && _game.gameVideos!.length > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Videos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _game.gameVideos!.length,
                            itemBuilder: (context, index) {
                              final video = _game.gameVideos![index];
                              final thumbnailUrl = _getYouTubeThumbnail(video['url'] ?? '');
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _launchUrl(video['url'] ?? ''),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Thumbnail
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.network(
                                                  thumbnailUrl,
                                                  width: 120,
                                                  height: 68,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 120,
                                                      height: 68,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[900],
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            Colors.grey[900]!,
                                                            Colors.grey[800]!,
                                                          ],
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            FontAwesomeIcons.gamepad,
                                                            color: Colors.grey[600],
                                                            size: 24,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'No Preview',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Container(
                                                  width: 120,
                                                  height: 68,
                                                  color: Colors.black.withOpacity(0.2),
                                                ),
                                                Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.white.withOpacity(0.8),
                                                  size: 32,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Video title
                                          Expanded(
                                            child: Text(
                                              video['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfoCard(String label, String time, Color color) {
    return SizedBox(
      width: 100, // Sabit genişlik
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    if (label == 'Seen') {
      final hasRating = _userRating != null;
      final ratingColor = hasRating ? _getRatingColor(_userRating!) : Colors.white70;
      final ratingIcon = hasRating ? _getRatingIcon(_userRating!) : icon;
      
      return InkWell(
        onTap: () {
          if (hasRating) {
            _showReviewDialog();
          } else {
            _showRatingDialog();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ratingIcon,
              color: ratingColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              hasRating ? _getRatingLabel(_userRating!) : label,
              style: TextStyle(
                color: ratingColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showReviewDialog() {
    ReviewModal.show(
      context,
      gameName: _game.name,
      coverUrl: _game.coverUrl ?? '',
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

  void _showRatingDialog() {
    RatingModal.show(
      context,
      gameName: _game.name,
      coverUrl: _game.coverUrl ?? '',
      initialRating: _userRating,
      onRatingSelected: (rating) {
        setState(() {
          _userRating = rating;
        });
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
      case 'PEGI_3': return 'PEGI 3';
      case 'PEGI_7': return 'PEGI 7';
      case 'PEGI_12': return 'PEGI 12';
      case 'PEGI_16': return 'PEGI 16';
      case 'PEGI_18': return 'PEGI 18';
      default: return ageRating.replaceAll('PEGI_', 'PEGI ');
    }
  }

  String _getCompanyInfo() {
    if (_game.companies.isEmpty) {
      return 'N/A';
    }

    final publishers = _game.companies
        .where((company) => company['isPublisher'] as bool)
        .map((company) => company['name'] as String)
        .toList();

    final developers = _game.companies
        .where((company) => !(company['isPublisher'] as bool))
        .map((company) => company['name'] as String)
        .toList();

    final result = [];
    if (publishers.isNotEmpty) {
      result.add('Publishers: ${publishers.join(", ")}');
    }
    if (developers.isNotEmpty) {
      result.add('Developers: ${developers.join(", ")}');
    }

    return result.isEmpty ? 'N/A' : result.join('\n');
  }

  String _getPlatformsText() {
    if (_game.platforms?.isEmpty ?? true) return 'N/A';
    try {
      return _game.platforms!
          .map((platform) => platform['name']?.toString() ?? 'Unknown')
          .where((name) => name.isNotEmpty)
          .join(', ');
    } catch (e) {
      print('Error getting platforms text: $e');
      return 'N/A';
    }
  }

  String _getGenresText() {
    if (_game.genres?.isEmpty ?? true) return 'N/A';
    try {
      return _game.genres!
          .map((genre) => genre['name']?.toString() ?? 'Unknown')
          .where((name) => name.isNotEmpty)
          .join(', ');
    } catch (e) {
      print('Error getting genres text: $e');
      return 'N/A';
    }
  }

  String _getThemesText() {
    if (_game.themes?.isEmpty ?? true) return 'N/A';
    try {
      return _game.themes!
          .map((theme) => theme['name']?.toString() ?? 'Unknown')
          .where((name) => name.isNotEmpty)
          .join(', ');
    } catch (e) {
      print('Error getting themes text: $e');
      return 'N/A';
    }
  }

  String _getGameModesText() {
    if (_game.gameModes?.isEmpty ?? true) return 'N/A';
    return _game.gameModes!
        .map((mode) => mode.name)
        .join(', ');
  }

  String _getPlayerPerspectivesText() {
    if (_game.playerPerspectives?.isEmpty ?? true) return 'N/A';
    return _game.playerPerspectives!
        .map((perspective) => perspective.name)
        .join(', ');
  }

  String _getFranchisesText() {
    if (_game.franchises?.isEmpty ?? true) return 'N/A';
    return _game.franchises!
        .map((franchise) => franchise.name)
        .join(', ');
  }

  String _getLanguageSupportsText() {
    if (_game.languageSupports?.isEmpty ?? true) return 'N/A';
    
    // Create a map to store language support types
    final Map<String, Map<String, bool>> languageMap = {};
    
    // Initialize all languages with all types as false
    for (final support in _game.languageSupports!) {
      final language = support.language;
      if (!languageMap.containsKey(language)) {
        languageMap[language] = {
          'Audio': false,
          'Interface': false,
          'Subtitles': false,
        };
      }
      // Mark the supported type as true
      switch (support.type) {
        case 'Audio':
          languageMap[language]!['Audio'] = true;
          break;
        case 'Interface':
          languageMap[language]!['Interface'] = true;
          break;
        case 'Subtitles':
          languageMap[language]!['Subtitles'] = true;
          break;
      }
    }
    
    // Sort languages alphabetically
    final sortedLanguages = languageMap.keys.toList()..sort();
    
    // Create table header
    final result = ['Language\t\tAudio\tInterface\tSubtitles'];
    
    // Add a separator line
    result.add('─' * 50);
    
    // Create table rows
    for (final language in sortedLanguages) {
      final supports = languageMap[language]!;
      result.add(
        '$language\t\t${supports['Audio']! ? '✓' : '✗'}\t'
        '${supports['Interface']! ? '✓' : '✗'}\t\t'
        '${supports['Subtitles']! ? '✓' : '✗'}'
      );
    }
    
    return result.join('\n');
  }

  Widget _buildLanguageSupportsTable() {
    if (_game.languageSupports?.isEmpty ?? true) {
      return const Text(
        'N/A',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      );
    }

    // Create a map to store language support types
    final Map<String, Map<String, bool>> languageMap = {};
    
    // Initialize all languages with all types as false
    for (final support in _game.languageSupports!) {
      final language = support.language;
      if (!languageMap.containsKey(language)) {
        languageMap[language] = {
          'Audio': false,
          'Interface': false,
          'Subtitles': false,
        };
      }
      // Mark the supported type as true
      switch (support.type) {
        case 'Audio':
          languageMap[language]!['Audio'] = true;
          break;
        case 'Interface':
          languageMap[language]!['Interface'] = true;
          break;
        case 'Subtitles':
          languageMap[language]!['Subtitles'] = true;
          break;
      }
    }

    // Define common languages to show first
    final commonLanguages = {'English', 'Spanish', 'French', 'German', 'Japanese', 'Chinese'};
    
    // Sort languages into common and other
    final sortedCommonLanguages = languageMap.keys
        .where((lang) => commonLanguages.contains(lang))
        .toList()..sort();
    final sortedOtherLanguages = languageMap.keys
        .where((lang) => !commonLanguages.contains(lang))
        .toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language support summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: Colors.blue[300],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${languageMap.length} Languages Supported',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Including audio, interface, and subtitle support',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.grey[800],
          ),

          // Language grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Common languages grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...sortedCommonLanguages.map((language) => _buildLanguageChip(
                      language,
                      languageMap[language]!,
                    )),
                    if (!_showAllLanguages && sortedOtherLanguages.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _showAllLanguages = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[900]?.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.blue[300]!.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${sortedOtherLanguages.length} More',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.blue[300],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_showAllLanguages)
                      ...sortedOtherLanguages.map((language) => _buildLanguageChip(
                        language,
                        languageMap[language]!,
                      )),
                    if (_showAllLanguages)
                      GestureDetector(
                        onTap: () => setState(() => _showAllLanguages = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[900]?.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.blue[300]!.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Show Less',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Colors.blue[300],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String language, Map<String, bool> supports) {
    final bool hasFullSupport = supports.values.every((supported) => supported);
    final bool hasPartialSupport = supports.values.any((supported) => supported);
    
    final Color backgroundColor = hasFullSupport
        ? Colors.green[900]!.withOpacity(0.3)
        : hasPartialSupport
            ? Colors.orange[900]!.withOpacity(0.3)
            : Colors.grey[800]!.withOpacity(0.3);
    
    final Color borderColor = hasFullSupport
        ? Colors.green[300]!.withOpacity(0.3)
        : hasPartialSupport
            ? Colors.orange[300]!.withOpacity(0.3)
            : Colors.grey[600]!.withOpacity(0.3);
    
    final List<String> supportedFeatures = [];
    if (supports['Audio']!) supportedFeatures.add('Audio');
    if (supports['Interface']!) supportedFeatures.add('Interface');
    if (supports['Subtitles']!) supportedFeatures.add('Subtitles');

    return Tooltip(
      message: supportedFeatures.isEmpty
          ? 'No support'
          : 'Supports: ${supportedFeatures.join(', ')}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language,
              style: TextStyle(
                color: hasFullSupport
                    ? Colors.green[300]
                    : hasPartialSupport
                        ? Colors.orange[300]
                        : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasFullSupport) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green[300],
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _getGameTrailerUrl() {
    if (_game.gameVideos?.isEmpty ?? true) return null;
    try {
      return _game.gameVideos?.first['url']?.toString();
    } catch (e) {
      print('Error getting game trailer URL: $e');
      return null;
    }
  }

  String _getYouTubeVideoId(String url) {
    try {
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/')[1].split('?')[0];
      }
      if (url.contains('youtube.com/watch?v=')) {
        return url.split('watch?v=')[1].split('&')[0];
      }
      if (url.contains('youtube.com/embed/')) {
        return url.split('embed/')[1].split('?')[0];
      }
      return '';
    } catch (e) {
      print('Error extracting YouTube video ID: $e');
      return '';
    }
  }

  String _getYouTubeThumbnail(String url) {
    final videoId = _getYouTubeVideoId(url);
    if (videoId.isEmpty) return '';
    // Using maxresdefault for better quality
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  Widget _buildSocialButton(String platform, IconData icon, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
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

  String _formatStoreName(String platform) {
    switch (platform.toUpperCase()) {
      case 'STEAM':
        return 'Steam';
      case 'EPICGAMES':
        return 'Epic Games';
      case 'GOG':
        return 'GOG';
      default:
        return platform;
    }
  }

  String _getPublisherText() {
    if (_game.companies?.isEmpty ?? true) return 'N/A';
    try {
      final publishers = _game.companies!
          .where((company) => company['isPublisher'] as bool? ?? false)
          .map((company) => company['name']?.toString() ?? 'Unknown')
          .where((name) => name.isNotEmpty)
          .toList();
      return publishers.isEmpty ? 'N/A' : publishers.join(', ');
    } catch (e) {
      print('Error getting publisher text: $e');
      return 'N/A';
    }
  }

  String _getDeveloperText() {
    if (_game.companies?.isEmpty ?? true) return 'N/A';
    try {
      final developers = _game.companies!
          .where((company) => !(company['isPublisher'] as bool? ?? false))
          .map((company) => company['name']?.toString() ?? 'Unknown')
          .where((name) => name.isNotEmpty)
          .toList();
      return developers.isEmpty ? 'N/A' : developers.join(', ');
    } catch (e) {
      print('Error getting developer text: $e');
      return 'N/A';
    }
  }

  Future<void> _handleSaveGame() async {
    if (_game.gameId == null) return;

    try {
      final bool success = _isSaved 
        ? await _libraryRepository.unsaveGame(_game.gameId!)
        : await _libraryRepository.saveGame(_game.gameId!);

      if (success && mounted) {
        setState(() {
          _isSaved = !_isSaved;
          // Update the game's userActions
          _game.userActions = _game.userActions?.copyWith(isSaved: _isSaved) ?? 
              UserGameActions(isSaved: _isSaved);
        });
        
        // Update in HomeController for other pages
        _homeController.updateGameSaveState(_game.gameId!, _isSaved);
      }
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  void _showSavedNotification() {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 32,
        left: MediaQuery.of(context).size.width / 2 - 32,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Icon(
                Icons.favorite,
                color: Colors.orange[400],
                size: 64,
              ),
            );
          },
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }
}
