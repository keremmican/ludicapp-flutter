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
import 'package:ludicapp/services/repository/rating_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/widgets/add_to_list_modal.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:ludicapp/services/model/request/rating_filter_request.dart';
import 'package:ludicapp/features/game/presentation/all_reviews_page.dart';
import 'package:ludicapp/services/model/response/user_game_rating_with_user.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'package:ludicapp/services/token_service.dart'; // Import TokenService
import 'package:ludicapp/core/enums/completion_status.dart'; // Added import
import 'package:ludicapp/core/enums/play_status.dart'; // Added import

class GameDetailPage extends StatefulWidget {
  final Game game;
  final bool fromSearch;
  final ImageProvider? initialCoverProvider;

  const GameDetailPage({
    Key? key, 
    required this.game,
    this.fromSearch = false,
    this.initialCoverProvider,
  }) : super(key: key);

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final _backgroundProvider = BlurredBackgroundProvider();
  final _gameRepository = GameRepository();
  final _libraryRepository = LibraryRepository();
  final _homeController = HomeController();
  final _ratingRepository = RatingRepository();
  final _tokenService = TokenService(); // Add TokenService instance
  final List<Image> _cachedImages = [];
  bool _areImagesLoaded = false;
  bool _isExpandedSummary = false;
  bool _showAllLanguages = false;
  int? _userRating;
  bool _isSaved = false;
  bool _isHidden = false; // <-- Add state for hidden status
  late Game _game;
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentUserId; // Add state for current user ID
  UserGameRatingWithUser? _currentUserReviewData; // Store fetched user review data
  
  // Yorumlar için değişkenler
  List<UserGameRatingWithUser> _gameReviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    _loadCurrentUserId(); // Load user ID first
    
    // Set user actions from the game object if available
    if (widget.game.userActions != null) {
      _userRating = widget.game.userActions!.userRating;
      _isSaved = widget.game.userActions!.isSaved ?? false;
      _isHidden = widget.game.userActions!.isHidden ?? false; // <-- Initialize hidden status
      final initialComment = widget.game.userActions!.comment; 
      
      // Widget'tan oyun durumu alanlarını logla (debug)
      print('initState - Checking widget.game.userActions: playStatus=${widget.game.userActions!.playStatus}, completionStatus=${widget.game.userActions!.completionStatus}, playtime=${widget.game.userActions!.playtimeInMinutes}');
      
      // _game'in userActions'ını comment ile başlat/güncelle - diğer değerleri de ekle
      _game = _game.copyWith(
        userActions: (_game.userActions ?? UserGameActions()).copyWith(
          userRating: _userRating,
          isSaved: _isSaved,
          isHidden: _isHidden, // <-- Set hidden status in game object
          comment: initialComment,
          // ÖNEMLİ: Oyun durumu alanlarını da kopyala
          playStatus: widget.game.userActions!.playStatus, 
          completionStatus: widget.game.userActions!.completionStatus,
          playtimeInMinutes: widget.game.userActions!.playtimeInMinutes,
        )
      );

      print('initState - userRating from widget: $_userRating');
      print('initState - isSaved from widget: $_isSaved');
      print('initState - isHidden from widget: $_isHidden'); // <-- Log hidden status
      print('initState - comment from widget: $initialComment'); 
      print('initState - userActions from widget: ${_game.userActions}'); 
      print('initState - playStatus from widget: ${_game.userActions?.playStatus}');
      print('initState - completionStatus from widget: ${_game.userActions?.completionStatus}');
    }
    
    // Game ID varsa, HomeController'dan rating, save ve comment durumunu da kontrol edelim
    if (_game.gameId != null) {
      // HomeController'dan bu oyun için rating değeri var mı kontrol et
      final gameId = _game.gameId!;
      
      // Eğer HomeController'da rating varsa, onu kullan
      if (_homeController.gameRatings.containsKey(gameId)) {
        _userRating = _homeController.gameRatings[gameId];
        print('initState - Using rating from HomeController: $_userRating');
        
        // Game nesnesinin userActions'ını da güncelle
        _game = _game.copyWith(
          userActions: (_game.userActions ?? UserGameActions()).copyWith(
            isRated: _userRating != null && _userRating! > 0, // Rating varsa isRated true
            userRating: _userRating,
            isHidden: _isHidden, // <-- Ensure hidden status is preserved
          )
        );
      }
      
      // Eğer HomeController'da save durumu varsa, onu kullan
      if (_homeController.savedGames.contains(gameId)) {
        _isSaved = true;
        print('initState - Using save state from HomeController: $_isSaved');
        
        // Game nesnesinin userActions'ını da güncelle
        _game = _game.copyWith(
          userActions: (_game.userActions ?? UserGameActions()).copyWith(
            isSaved: true,
            isHidden: _isHidden, // <-- Ensure hidden status is preserved
          )
        );
      }
      
      // TODO: Check hidden status from HomeController if needed
      if (_homeController.hiddenGames.contains(gameId)) { // <-- Check hidden state
         _isHidden = true;
         print('initState - Using hidden state from HomeController: $_isHidden');
         _game = _game.copyWith(userActions: (_game.userActions ?? UserGameActions()).copyWith(isHidden: true));
      }
      
      // Eğer HomeController'da comment varsa ve widget'tan gelen comment null ise, onu kullan
      final bool commentExistsInWidget = _game.userActions?.comment != null;
      if (!commentExistsInWidget && _homeController.gameComments.containsKey(gameId)) {
        final commentFromController = _homeController.gameComments[gameId];
        if (commentFromController != null) { // Controller'dan gelen yorumun null olmadığından emin ol
          print('initState - Using comment from HomeController because initial comment was null: $commentFromController');
          // Game nesnesinin userActions'ını da güncelle
          _game = _game.copyWith(
            userActions: (_game.userActions ?? UserGameActions()).copyWith(
              comment: commentFromController,
              isHidden: _isHidden, // <-- Ensure hidden status is preserved
            )
          );
        }
      }
    }
    
    // Clear previous background cache and set new background
    _backgroundProvider.clearCache();
    if (_game.coverUrl != null) {
      _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.coverUrl!);
    }
    
    // Only initialize game details if coming from search
    if (widget.fromSearch) {
      _initializeGame();
    } else {
      _isLoading = false;
      _preloadImages();
      
      // Oyun yüklendiğinde yorumları getir
      if (_game.gameId != null) {
        _loadGameReviews();
      }
    }
  }

  // --- New method to load current user ID ---
  Future<void> _loadCurrentUserId() async {
    try {
      _currentUserId = await _tokenService.getUserId();
      print('GameDetailPage - Current User ID: $_currentUserId');
      // After getting user ID, initialize game details if needed
      // (ensure _initializeGame or _loadGameReviews runs AFTER this completes if they depend on it)
      if (widget.fromSearch) {
        await _initializeGame(); // Ensure initialize happens after getting ID if needed
      } else if (_game.gameId != null) {
        await _loadGameReviews(); // Ensure reviews load after getting ID
      }
    } catch (e) {
      print('Error loading current user ID: $e');
      // Handle error if necessary, maybe show a message
    }
  }
  // --- End of new method ---

  Future<void> _initializeGame() async {
    if (!widget.fromSearch || _game.gameId == null) return; // gameId null ise çık
    
    setState(() => _isLoading = true);
    try {
      // Fetch game details with user info
      final gameWithUserInfo = await _gameRepository.fetchGameDetailsWithUserInfo(_game.gameId!);
      
      if (mounted) {
        setState(() {
          // Update game with user actions from fetched data
          _game = gameWithUserInfo.toGame(); // Bu metodun userActions'ı doğru atadığını varsayıyoruz
          _userRating = gameWithUserInfo.userActions?.userRating;
          _isSaved = gameWithUserInfo.userActions?.isSaved ?? false;
          _isHidden = gameWithUserInfo.userActions?.isHidden ?? false; // <-- Get hidden status from fetch
          final fetchedComment = gameWithUserInfo.userActions?.comment; // Backend'den gelen comment'i al

          // Emin olmak için _game.userActions'ı fetched comment ile güncelle
          _game = _game.copyWith(
            userActions: (_game.userActions ?? UserGameActions()).copyWith(
              userRating: _userRating,
              isRated: _userRating != null && _userRating! > 0,
              isSaved: _isSaved,
              isHidden: _isHidden, // <-- Set hidden status from fetch
              comment: fetchedComment, // Fetched comment'i ata
            )
          );

          print('_initializeGame - Fetched comment: $fetchedComment'); // Log eklendi
          print('_initializeGame - Fetched isHidden: $_isHidden'); // <-- Log hidden status
          print('_initializeGame - Updated _game.userActions: ${_game.userActions}'); // Log eklendi

          _isLoading = false;
        });
        
        _preloadImages();
        
        // Oyun detayları yüklendiğinde yorumları getir
        if (_game.gameId != null) {
          // Ensure user ID is loaded before loading reviews dependent on it
          if (_currentUserId != null) {
             await _loadGameReviews();
          } else {
            // Wait for _loadCurrentUserId to complete if it hasn't yet
            // This might require restructuring initState slightly
            print("Waiting for user ID before loading reviews in _initializeGame");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          print('Error in _initializeGame: $e'); // Hata log'u
        });
      }
    }
  }

  Future<void> _preloadImages() async {
    // Only run if images aren't already marked as loaded
    if (_areImagesLoaded) return;

    try {
      bool imagesMarkedLoaded = false;
      // Preload cover image FIRST if available and mounted, WITHOUT await
      if (_game.coverUrl != null && _game.coverUrl!.isNotEmpty && mounted) {
        print('Initiating pre-cache for cover in GameDetailPage for ${_game.name}');
        precacheImage(CachedNetworkImageProvider(_game.coverUrl!), context)
            .then((_) => print('Pre-cache completed for cover: ${_game.name}'))
            .catchError((e) => print('Error pre-caching cover in GameDetailPage: $e'));
        // Mark loaded after initiating cover preload attempt
        if (mounted && !_areImagesLoaded) {
           setState(() { _areImagesLoaded = true; });
           imagesMarkedLoaded = true;
        }
      }
      
      // Then preload screenshots if available, WITHOUT await
      if (_game.screenshots != null && _game.screenshots!.isNotEmpty) {
        // Remove the backgroundProvider call here
        // if (_game.gameId != null) {
        //   if (_game.coverUrl == null || _game.coverUrl!.isEmpty) {
        //      _backgroundProvider.cacheBackground(_game.gameId.toString(), _game.screenshots![0]);
        //   }
        // }
        
        // Precaching screenshots with CachedNetworkImage provider (fire and forget)
        if (mounted) {
          print('Initiating pre-cache for screenshots in GameDetailPage for ${_game.name}');
          Future.wait(_game.screenshots!.map((url) => 
            precacheImage(CachedNetworkImageProvider(url), context)
          ).toList()).then((_) => print('Pre-cache completed for screenshots: ${_game.name}'))
          .catchError((e) {
            print("Error pre-caching screenshots in GameDetailPage: $e");
          });
        }

        // Mark images as 'loaded' if not already done
        if (mounted && !imagesMarkedLoaded && !_areImagesLoaded) {
          setState(() {
            _areImagesLoaded = true;
          });
        }
      } else if (mounted && !imagesMarkedLoaded && !_areImagesLoaded && _game.coverUrl != null && _game.coverUrl!.isNotEmpty) {
        // If only cover exists and wasn't marked loaded before, mark now.
        setState(() {
          _areImagesLoaded = true;
        });
      }
    } catch (e) {
      print('Error during image preloading initiation: $e');
      if (mounted && !_areImagesLoaded) { // Check _areImagesLoaded again
        setState(() {
          _areImagesLoaded = false; // Indicate loading potentially failed
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
                                      child: CachedNetworkImage(
                                        imageUrl: _game.coverUrl ?? '',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: Colors.grey[900]),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.error_outline, color: Colors.white),
                                        ),
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
                              child: CachedNetworkImage(
                                imageUrl: _game.coverUrl ?? '',
                                fit: BoxFit.cover,
                                memCacheWidth: (MediaQuery.of(context).size.width * 0.5 * 2).round(), // Optimize cache size
                                memCacheHeight: (MediaQuery.of(context).size.width * 0.5 * (180/135) * 2).round(), // Optimize cache size
                                fadeInDuration: Duration.zero, // Instant fade in
                                fadeOutDuration: Duration.zero, // Instant fade out
                                placeholder: (context, url) => Container(color: Colors.grey[900]),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.error_outline, color: Colors.white),
                                ),
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
    // Always try to get background, even if loading
    final cachedBackground = _game?.gameId != null ? _backgroundProvider.getBackground(_game!.gameId.toString()) : null;
    final coverUrl = _game?.coverUrl; // Get cover URL even if loading
    final firstScreenshotUrl = (_game?.screenshots?.isNotEmpty ?? false) ? _game!.screenshots![0] : null; // Get first screenshot URL

    // Use coverUrl for main caching key, fallback to first screenshot if no cover
    final backgroundImageUrl = coverUrl ?? firstScreenshotUrl;

    print('build - _isLoading: $_isLoading');
    print('build - _isSaved: $_isSaved');
    print('build - userActions: ${_game?.userActions}');
    if (_game?.userActions != null) {
      print('build - userActions.isSaved: ${_game!.userActions!.isSaved}');
    }

    // Show main structure immediately, overlay progress indicator if needed
    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur (Always attempt to show from cache)
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: backgroundImageUrl != null
                  ? CachedNetworkImage(
                      // Use the determined background image URL
                      imageUrl: backgroundImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.black),
                      errorWidget: (context, url, error) => Container(color: Colors.black),
                      // Consider adding memCache optimization here too if needed
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    )
                  : Container(color: Colors.black), // Fallback if no image URL
            ),
          ),

          // Blur overlay (Always show)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),

          // Main content area (conditionally shown or overlaid with loader)
          if (!_isLoading && _game != null)
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
                          // Cover image in center (Always attempt to show from cache)
                          Center(
                            child: GestureDetector(
                              onTap: () => _game != null ? _openCoverImage(context) : null,
                              child: Hero(
                                // Ensure tag is unique even if _game is initially null temporarily
                                tag: 'cover_${widget.game.gameId}', 
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
                                    // *** Use passed provider first, fallback to CachedNetworkImage ***
                                    child: widget.initialCoverProvider != null 
                                      ? Image(
                                          image: widget.initialCoverProvider!, 
                                          fit: BoxFit.cover,
                                          // Remove frameBuilder for instant appearance
                                          /* frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                            if (wasSynchronouslyLoaded) return child;
                                            return AnimatedOpacity(
                                              child: child,
                                              opacity: frame == null ? 0 : 1,
                                              duration: const Duration(milliseconds: 100), // Short fade
                                              curve: Curves.easeOut,
                                            );
                                          }, */
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback if the provider fails 
                                            print("Error with initialCoverProvider, falling back: $error");
                                            return CachedNetworkImage(
                                              imageUrl: coverUrl ?? '',
                                              fit: BoxFit.cover,
                                              memCacheWidth: 270, 
                                              memCacheHeight: 360, 
                                              fadeInDuration: Duration.zero, 
                                              fadeOutDuration: Duration.zero, 
                                              placeholder: (context, url) => Container(color: Colors.grey[900]),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.grey[900],
                                                child: const Icon(Icons.error_outline, color: Colors.white),
                                              ),
                                            );
                                          },
                                        )
                                      // Fallback if provider wasn't passed or direct Image fails
                                      : CachedNetworkImage(
                                          imageUrl: coverUrl ?? '',
                                          fit: BoxFit.cover,
                                          memCacheWidth: 270, 
                                          memCacheHeight: 360, 
                                          fadeInDuration: Duration.zero, 
                                          fadeOutDuration: Duration.zero, 
                                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[900],
                                            child: const Icon(Icons.error_outline, color: Colors.white),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Back button (Always show)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: GestureDetector(
                              onTap: () {
                                print('GameDetailPage - Returning game from back button: isSaved=${_game?.userActions?.isSaved}, isRated=${_game?.userActions?.isRated}, userRating=${_game?.userActions?.userRating}');
                                // Return the potentially updated _game or the initial widget.game if _game is null
                                Navigator.pop(context, _game ?? widget.game); 
                              },
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
                            _game!.name, // Now safe to use ! because of !_isLoading && _game != null check
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added horizontal padding
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Use spaceEvenly for consistent spacing
                        children: [
                          // Always show Share button
                          _buildActionButton(FontAwesomeIcons.shareFromSquare, 'Share'),
                          
                          // Conditionally show other buttons based on _isHidden and _userRating
                          if (_isHidden) // If hidden, only show Unhide
                             _buildActionButton(FontAwesomeIcons.eye, 'Unhide') 
                          else if (_userRating != null && _userRating! > 0) // If rated (and not hidden), show Seen
                            _buildActionButton(FontAwesomeIcons.circleCheck, 'Seen') 
                          else ...[ // If not hidden AND not rated, show Hide, Seen (default), Save
                            _buildActionButton(FontAwesomeIcons.eyeSlash, 'Hide'),
                            _buildActionButton(FontAwesomeIcons.circleCheck, 'Seen'), 
                            _buildActionButton(FontAwesomeIcons.bookmark, 'Save'),
                          ],
                          
                          // Always show Add to List button
                          _buildActionButton(Icons.playlist_add_outlined, 'Add to List'),
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
                            
                            // Yatay review listesi (kullanıcı reviewi ilk eleman olacak)
                            SizedBox(
                              height: 160,
                              // REMOVE: Conditional loading indicator
                              // child: _isLoadingReviews
                              //   ? Center(
                              //       child: CircularProgressIndicator(
                              //         valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                              //       ),
                              //     )
                              //   : ListView.builder( // Always build the ListView now
                              child: ListView.builder( // Always build the ListView now
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 1 + _gameReviews.length, // 1 kullanıcı yorumu + gerçek yorumlar
                                    padding: EdgeInsets.zero,
                                    itemBuilder: (context, index) {
                                      // Log comment state during build for user review card
                                      if (index == 0) {
                                        print('Building user review card - comment: ${_game.userActions?.comment}');
                                      }
                                      // Kullanıcının kendi review'i (ilk eleman)
                                      if (index == 0) {
                                        return GestureDetector(
                                          key: ValueKey('user_review_card_${_game.gameId}_${_userRating}'), 
                                          onTap: () {
                                            // Check if user has rated the game already
                                            if (_userRating == null) {
                                              // If no rating, show rating modal first
                                              RatingModal.show(
                                                context,
                                                gameName: _game.name,
                                                coverUrl: _game.coverUrl ?? '',
                                                gameId: _game.gameId!,
                                                // Correct parameter name
                                                initialUserGameRating: UserGameRating(
                                                  id: _currentUserReviewData?.id ?? 0,
                                                  userId: _currentUserId ?? 0,
                                                  gameId: _game.gameId!, 
                                                  rating: _userRating,
                                                  comment: _game.userActions?.comment,
                                                  // Fetch these if available from _currentUserReviewData or local state
                                                  playStatus: _currentUserReviewData?.playStatus,
                                                  completionStatus: _currentUserReviewData?.completionStatus,
                                                  playtimeInMinutes: _currentUserReviewData?.playtimeInMinutes,
                                                ),
                                                // Correct callback name
                                                onUpdateComplete: (updatedRating) async {
                                                  // Update state based on the full returned object
                                                  setState(() {
                                                    _userRating = updatedRating.rating;
                                                    
                                                    _game = _game.copyWith(
                                                      userActions: (_game.userActions ?? UserGameActions()).copyWith(
                                                        isRated: updatedRating.rating != null && updatedRating.rating! > 0,
                                                        userRating: updatedRating.rating,
                                                        comment: updatedRating.comment, 
                                                        // TODO: Update other actions if stored locally
                                                      ),
                                                    );
                                                    // Update _currentUserReviewData if necessary
                                                    _currentUserReviewData = UserGameRatingWithUser(
                                                       id: updatedRating.id, 
                                                       userId: updatedRating.userId, 
                                                       gameId: updatedRating.gameId, 
                                                       rating: updatedRating.rating, 
                                                       comment: updatedRating.comment, 
                                                       playStatus: updatedRating.playStatus, 
                                                       completionStatus: updatedRating.completionStatus, 
                                                       playtimeInMinutes: updatedRating.playtimeInMinutes,
                                                       lastUpdatedDate: updatedRating.lastUpdatedDate, 
                                                       // Keep existing profile info if available
                                                       username: _currentUserReviewData?.username ?? 'You',
                                                       profilePhotoUrl: _currentUserReviewData?.profilePhotoUrl, 
                                                       profilePhotoType: _currentUserReviewData?.profilePhotoType,
                                                    ); 
                                                    print('Updated state from RatingModal (User Review Card)');
                                                  });
                                                  
                                                  // HomeController update
                                                  if (_game.gameId != null) {
                                                    _homeController.updateGameRatingState(_game.gameId!, updatedRating.rating);
                                                    _homeController.updateGameComment(_game.gameId!, updatedRating.comment);
                                                     // TODO: Update other Home Controller states
                                                  }
                                                  
                                                  // Show Review Modal only if a valid rating exists *after* update
                                                  if (updatedRating.rating != null && updatedRating.rating! > 0) {
                                                    Future.delayed(const Duration(milliseconds: 100), () {
                                                      if (mounted) {
                                                        ReviewModal.show(
                                                          context,
                                                          gameName: _game.name,
                                                          coverUrl: _game.coverUrl ?? '',
                                                          initialReview: updatedRating.comment, // Pass updated comment
                                                          onReviewSubmitted: _handleReviewSubmitted,
                                                        );
                                                      }
                                                    });
                                                  }
                                                },
                                              );
                                            } else {
                                              // If already rated, show review modal directly
                                              ReviewModal.show(
                                                context,
                                                gameName: _game.name,
                                                coverUrl: _game.coverUrl ?? '',
                                                initialReview: _game.userActions?.comment, // Mevcut yorumu ilet
                                                onReviewSubmitted: _handleReviewSubmitted,
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: 280,
                                            margin: const EdgeInsets.only(right: 12), // Original margin
                                            padding: const EdgeInsets.all(16), // Original padding
                                            constraints: const BoxConstraints(), // Remove max height constraint
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(12), // Original border radius
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    // --- Updated CircleAvatar for User Review ---
                                                    Builder( // Use Builder to easily access context if needed later
                                                      builder: (context) {
                                                        Widget userImageContent;
                                                        final photoType = ProfilePhotoType.fromString(_currentUserReviewData?.profilePhotoType);
                                                        final photoUrl = _currentUserReviewData?.profilePhotoUrl;

                                                        if (photoType == ProfilePhotoType.CUSTOM && photoUrl != null && photoUrl.isNotEmpty) {
                                                          userImageContent = CircleAvatar(
                                                            radius: 16, // Original radius
                                                            backgroundColor: Colors.grey[700],
                                                            backgroundImage: CachedNetworkImageProvider(photoUrl),
                                                          );
                                                        } else {
                                                          final String? assetPath = photoType.assetPath;
                                                          if (assetPath != null) {
                                                            userImageContent = CircleAvatar(
                                                              radius: 16, // Original radius
                                                              backgroundColor: Colors.grey[700],
                                                              backgroundImage: AssetImage(assetPath),
                                                            );
                                                          } else {
                                                            // Fallback: Use rating icon if rated, otherwise person icon
                                                            userImageContent = CircleAvatar(
                                                              radius: 16, // Original radius
                                                              backgroundColor: Colors.grey[700],
                                                              child: Icon(
                                                                _userRating != null && _userRating! > 0
                                                                    ? _getRatingIcon(_userRating!) // Rating icon
                                                                    : Icons.person, // Default person icon
                                                                color: Colors.white,
                                                                size: 20, // Original size
                                                              ),
                                                            );
                                                          }
                                                        }
                                                        return userImageContent;
                                                      }
                                                    ),
                                                    // --- End Updated CircleAvatar ---
                                                    const SizedBox(width: 8), // Original spacing
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            "Your Review",
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 14, // Original font size
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (_userRating != null)
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.star,
                                                                  color: Colors.amber[400],
                                                                  size: 14, // Original size
                                                                ),
                                                                const SizedBox(width: 4), // Original spacing
                                                                Text(
                                                                  "$_userRating",
                                                                  style: TextStyle(
                                                                    color: Colors.grey[400],
                                                                    fontSize: 12, // Original font size
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.edit,
                                                      color: Colors.white54,
                                                      size: 16, // Original size
                                                    ),
                                                  ],
                                                ),
                                                if (_game.userActions?.comment != null && _game.userActions!.comment!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 12), // Original padding
                                                    child: Text(
                                                      _game.userActions!.comment!,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14, // Original font size
                                                        height: 1.4, // Original line height
                                                      ),
                                                      maxLines: 3, // Original max lines
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                // Keep the Wrap layout for game status chips but with original sizing
                                                if (_game.userActions?.playStatus != null && _game.userActions!.playStatus != PlayStatus.notSet ||
                                                    _game.userActions?.completionStatus != null && _game.userActions!.completionStatus != CompletionStatus.notSelected ||
                                                    _game.userActions?.playtimeInMinutes != null && _game.userActions!.playtimeInMinutes! > 0)
                                                  Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 12), // Original padding
                                                      child: Wrap(
                                                        spacing: 8, // Original spacing
                                                        runSpacing: 6, // Original spacing
                                                        children: [
                                                          if (_game.userActions?.playStatus != null && _game.userActions!.playStatus != PlayStatus.notSet)
                                                            _buildIconChip(
                                                              _getPlayStatusIcon(_game.userActions!.playStatus!),
                                                              _getPlayStatusTooltip(_game.userActions!.playStatus!),
                                                            ),
                                                          if (_game.userActions?.completionStatus != null && _game.userActions!.completionStatus != CompletionStatus.notSelected)
                                                            _buildIconChip(
                                                              _getCompletionStatusIcon(_game.userActions!.completionStatus!),
                                                              _getCompletionStatusText(_game.userActions!.completionStatus!),
                                                            ),
                                                          if (_game.userActions?.playtimeInMinutes != null && _game.userActions!.playtimeInMinutes! > 0)
                                                            _buildInfoChip(
                                                              Icons.timer_outlined,
                                                              _formatPlaytime(_game.userActions!.playtimeInMinutes!),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (_game.userActions?.comment == null || _game.userActions?.comment?.isEmpty == true)
                                                  const Padding(
                                                    padding: EdgeInsets.only(top: 12), // Original padding
                                                    child: Text(
                                                      'Tap to add your review', // Original text
                                                      style: TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 14, // Original font size
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      
                                      // API'den gelen yorumlar
                                      final review = _gameReviews[index - 1];
                                      // DEBUG: Log the profile photo URL and type
                                      print('Review ${review.id} - User: ${review.username} - Photo URL: ${review.profilePhotoUrl} - Type: ${review.profilePhotoType}');

                                      // Determine the image widget based on type and URL
                                      Widget imageContent;
                                      final photoType = ProfilePhotoType.fromString(review.profilePhotoType); // Use existing fromString method

                                      if (photoType == ProfilePhotoType.CUSTOM && review.profilePhotoUrl != null && review.profilePhotoUrl!.isNotEmpty) {
                                        // Custom URL - Use CachedNetworkImageProvider
                                        imageContent = CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[700], // Placeholder background
                                          backgroundImage: CachedNetworkImageProvider(review.profilePhotoUrl!),
                                          // No child needed when backgroundImage is set
                                        );
                                      } else {
                                        // Default asset or fallback
                                        final String? assetPath = photoType.assetPath;
                                        if (assetPath != null) {
                                          // Use local asset
                                          imageContent = CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.grey[700], // Background for asset
                                            backgroundImage: AssetImage(assetPath),
                                            // Error handling for asset can be added if needed
                                          );
                                        } else {
                                          // Fallback placeholder (if type is CUSTOM but URL missing, or unknown type, or no asset path)
                                          imageContent = CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.grey[700],
                                            child: const Icon(Icons.person, color: Colors.white, size: 20), // Standard fallback icon
                                          );
                                        }
                                      }

                                      return Container(
                                        width: 280,
                                        margin: const EdgeInsets.only(right: 12), // Original margin
                                        padding: const EdgeInsets.all(16), // Original padding
                                        constraints: const BoxConstraints(), // Remove max height constraint
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12), // Original border radius
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                imageContent, // Use the determined image widget
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      review.username,
                                                      style: const TextStyle(
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
                                                          "${review.rating}",
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
                                            Expanded(
                                              child: Text(
                                                review.comment ?? "",
                                                style: const TextStyle(
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
                                // "Show All Reviews" butonuna tıklandığında AllReviewsPage'e git
                                if (_game.gameId != null) {
                                  // Kullanıcının kendi yorumunu oluştur (varsa)
                                  UserGameRating? userReview;
                                  
                                  if (_userRating != null && _userRating! > 0) {
                                    // Kullanıcının yorumu için UserGameRating oluştur
                                    userReview = UserGameRating(
                                      id: 0, // ID önemli değil
                                      userId: 0, // Kullanıcının ID'si (oturum açmış kullanıcı)
                                      gameId: _game.gameId!,
                                      rating: _userRating!,
                                      comment: _game.userActions?.comment,
                                      lastUpdatedDate: DateTime.now(), // Use lastUpdatedDate
                                    );
                                  }
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllReviewsPage(
                                        gameId: _game.gameId!,
                                        gameName: _game.name,
                                        coverUrl: _game.coverUrl,
                                        userRating: userReview, // Kullanıcının yorumunu aktar
                                      ),
                                    ),
                                  ).then((_) {
                                    // Geri döndüğünde yorumları güncelle
                                    if (_game.gameId != null) {
                                      _loadGameReviews();
                                    }
                                  });
                                }
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
                                      margin: const EdgeInsets.only(right: 12), // Original margin
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8), // Smaller border radius
                                        child: CachedNetworkImage(
                                          imageUrl: screenshot,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[900],
                                            child: const Icon(Icons.error_outline, color: Colors.white),
                                          ),
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
                                                  CachedNetworkImage(
                                                    imageUrl: thumbnailUrl,
                                                    width: 120,
                                                    height: 68,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Container(
                                                      width: 120,
                                                      height: 68,
                                                      color: Colors.grey[900],
                                                    ),
                                                    errorWidget: (context, url, error) {
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
            )
          // Loading Indicator or Error Message Overlay
          else if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else // Error state (_errorMessage != null or _game is null and not loading)
            Center(
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
                    _errorMessage ?? 'Could not load game details',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Only show Try Again if it came from search, otherwise it might be a different error
                  if (widget.fromSearch) 
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
    // --- ADD TO LIST BUTTON --- 
    if (label == 'Add to List') {
      return InkWell(
        onTap: () { // Remove async
          if (_game.gameId != null) { // Ensure gameId is available
            // Show the modal (cannot await void)
            AddToListModal.show(
              context,
              gameId: _game.gameId!,
              gameName: _game.name,
            );

            // Optimistic update: Assume the action might succeed and update state.
            // This happens immediately after showing the modal, not after completion.
            // A more robust solution requires modifying AddToListModal or using state management.
            if (mounted) { 
              setState(() {
                // Check if userActions is null and initialize if needed
                final currentActions = _game.userActions ?? const UserGameActions();
                // Only update if it's not already true
                if (currentActions.isInCustomList != true) { 
                  _game = _game.copyWith(
                    userActions: currentActions.copyWith(
                      isInCustomList: true, 
                    ),
                  );
                  print("Game Detail Page: Optimistically updated _game.userActions after showing AddToListModal: ${_game.userActions}");
                }
              });
            } 
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    
    // --- RATING BUTTON ('Seen') ---
    if (label == 'Seen' || label == 'Awful' || label == 'Meh' || label == 'Good' || label == 'Amazing') {
      final bool hasRating = _userRating != null && _userRating! > 0;
      final Color displayColor = hasRating ? _getRatingColor(_userRating!) : Colors.white70;
      final IconData displayIcon = hasRating ? _getRatingIcon(_userRating!) : FontAwesomeIcons.circleCheck; // Use check if rated, star otherwise? No, use specific rating icons. Default is circleCheck.
      final String displayLabel = hasRating ? _getRatingLabel(_userRating!) : 'Seen';
      
      return InkWell(
        onTap: _showRatingModal,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                displayIcon,
                color: displayColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                displayLabel,
                style: TextStyle(
                  color: displayColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // --- SHARE BUTTON ---
    if (label == 'Share') {
      return InkWell(
        onTap: () {
          // TODO: Implement share functionality
          print('Share button tapped - (Snackbar removed)');
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    
    // --- HIDE / UNHIDE BUTTON ---
    if (label == 'Hide' || label == 'Unhide') {
      // Use `_isHidden` to determine the current state and action
      final bool currentlyHidden = _isHidden; 
      final IconData displayIcon = currentlyHidden ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash;
      final String displayLabel = currentlyHidden ? 'Unhide' : 'Hide';
      final Color displayColor = currentlyHidden ? Colors.blue[300]! : Colors.white70; // Highlight Unhide

      return InkWell(
        onTap: _handleHideGame, // Use a dedicated handler
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                displayIcon,
                color: displayColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                displayLabel,
                style: TextStyle(
                  color: displayColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // --- SAVE BUTTON ---
    if (label == 'Save') {
      final Color displayColor = _isSaved ? Colors.orange[400]! : Colors.white70;
      final IconData displayIcon = _isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark;

      return InkWell(
        onTap: _handleSaveGame,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                displayIcon,
                color: displayColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label, // Label remains 'Save'
                style: TextStyle(
                  color: displayColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Default case (should not happen with current logic)
    return const SizedBox.shrink(); 
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

  void _showRatingModal() {
    // Fetch the most recent full rating data before showing the modal
    // Use the existing _game.userActions object as the source
    UserGameRating? currentRatingData;
    if (_game.userActions != null && _game.gameId != null) {
         currentRatingData = UserGameRating(
            // Try to get an ID if we have stored the full review data, otherwise 0
            id: _currentUserReviewData?.id ?? 0, 
            userId: _currentUserId ?? 0, // Use the loaded current user ID
            gameId: _game.gameId!, 
            rating: _game.userActions!.userRating,
            comment: _game.userActions!.comment,
            // Read existing values from userActions - debug loglarını ekleyelim
            playStatus: _game.userActions!.playStatus, 
            completionStatus: _game.userActions!.completionStatus,
            playtimeInMinutes: _game.userActions!.playtimeInMinutes,
            // We don't have lastUpdatedDate in userActions, pass null
            lastUpdatedDate: null, 
        );
        print("Showing rating modal with: playStatus=${_game.userActions!.playStatus}, completionStatus=${_game.userActions!.completionStatus}, playtimeInMinutes=${_game.userActions!.playtimeInMinutes}");
    } else if (_game.gameId != null) {
      // If userActions is null, create a minimal object for the modal
       currentRatingData = UserGameRating(
          id: 0,
          userId: _currentUserId ?? 0,
          gameId: _game.gameId!,
          rating: null,
          comment: null,
          playStatus: PlayStatus.notSet, // Default
          completionStatus: CompletionStatus.notSelected, // Default
          playtimeInMinutes: null,
          lastUpdatedDate: null,
      );
    }
    
    // If gameId is null or something went wrong, don't show modal
    if (currentRatingData == null) {
      print("Error: Cannot show rating modal - currentRatingData is null.");
      // Optionally show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load rating details.')),
      );
      return;
    }

    // Show the updated modal
    RatingModal.show(
      context,
      gameName: _game.name,
      coverUrl: _game.coverUrl ?? '',
      gameId: _game.gameId!, // Ensure gameId is not null here
      // Pass the correct parameter name and the correct data variable
      initialUserGameRating: currentRatingData, 
      // Updated callback
      onUpdateComplete: (updatedRating) {
         print('RatingModal Callback - Received updated rating: ${updatedRating.toJson()}');

        // --- Rule: Rating a game removes hidden status ---
        bool shouldUnhide = false;
        if ((updatedRating.rating != null && updatedRating.rating! > 0) && _isHidden) {
          shouldUnhide = true;
          print('Rating action is unhiding the game.');
        }

        setState(() {
          // Update local state based on the returned full object
          _userRating = updatedRating.rating;
          final newComment = updatedRating.comment;
          // TODO: Update local state for playStatus, completionStatus, playtime if needed
          // --> No need for separate local state, update userActions directly
          
          // Unhide if necessary
          if (shouldUnhide) {
            _isHidden = false;
          }

          // Update the _game.userActions object comprehensively
          _game = _game.copyWith(
            userActions: (_game.userActions ?? const UserGameActions()).copyWith(
              isRated: _userRating != null && _userRating! > 0,
              userRating: _userRating,
              comment: newComment, // Update comment
              isHidden: _isHidden, // Update hidden status
              // Include the new fields
              playStatus: updatedRating.playStatus, 
              completionStatus: updatedRating.completionStatus,
              playtimeInMinutes: updatedRating.playtimeInMinutes,
            )
          );
          
          // Use _userRating for printing
          print('Updated _userRating: $_userRating'); 
          print('Updated isHidden: $_isHidden'); 
          print('Updated userActions: ${_game.userActions}'); 
        });
        
        // Update HomeController
        if (_game.gameId != null) {
          // Use _userRating here
          _homeController.updateGameRatingState(_game.gameId!, _userRating);
          _homeController.updateGameComment(_game.gameId!, updatedRating.comment);
          // Update new fields in HomeController
          _homeController.updateGamePlayStatus(_game.gameId!, updatedRating.playStatus);
          _homeController.updateGameCompletionStatus(_game.gameId!, updatedRating.completionStatus);
          _homeController.updateGamePlaytime(_game.gameId!, updatedRating.playtimeInMinutes);
           
          if (shouldUnhide) {
            _homeController.updateGameHiddenState(_game.gameId!, false); 
            print('HomeController hidden state update needed for game ${_game.gameId}: false'); 
          }
        }

        // Call backend to unhide game if necessary (redundant if updateRatingEntry handles it)
        // Consider removing this if the main update endpoint handles unhiding implicitly
        if (shouldUnhide && _game.gameId != null) {
           print('Backend call MAYBE needed: unhideGame(${_game.gameId}) - Check if update endpoint handles this');
           // try {
           //   await _libraryRepository.unhideGame(_game.gameId!); 
           // } catch (e) {
           //   print('Error unhiding game via rating: $e');
           // }
        }
      },
    );
  }

  String _getRatingLabel(int rating) {
    // Adjust labels for 1-10 scale or remove if not needed
    if (rating <= 2) return 'Awful';
    if (rating <= 4) return 'Meh';
    if (rating <= 7) return 'Good';
    if (rating <= 9) return 'Great';
    return 'Amazing'; // 10
  }

  IconData _getRatingIcon(int? rating) {
    // Adjust icons for 1-10 or remove if using numbered buttons only
    if (rating == null || rating == 0) return FontAwesomeIcons.faceMeh;
    if (rating <= 2) return FontAwesomeIcons.faceAngry;
    if (rating <= 4) return FontAwesomeIcons.faceFrown;
    if (rating <= 6) return FontAwesomeIcons.faceMeh;
    if (rating <= 8) return FontAwesomeIcons.faceSmile;
    return FontAwesomeIcons.faceGrinStars; // 9-10
  }

  Color _getRatingColor(int rating) {
     // Adjust colors for 1-10
    if (rating <= 2) return Colors.redAccent.shade400;
    if (rating <= 4) return Colors.orange.shade700;
    if (rating <= 7) return Colors.amber.shade700;
    if (rating <= 9) return Colors.lightGreen.shade600;
    return Colors.teal.shade500; // 10
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
                  'Including audio, interface, and subtitle support. Tap to see.',
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

    return InkWell(
      onTap: () => _showLanguageDetails(language, supports),
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

  void _showLanguageDetails(String language, Map<String, bool> supports) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language header
                  Row(
                    children: [
                      Text(
                        language,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.translate_rounded,
                        color: Colors.blue[300],
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Support details
                  _buildSupportDetail(
                    'Audio',
                    supports['Audio']!,
                    Icons.volume_up_rounded,
                    'Voice acting and sound in this language',
                  ),
                  const SizedBox(height: 16),
                  _buildSupportDetail(
                    'Interface',
                    supports['Interface']!,
                    Icons.settings_rounded,
                    'Menu and UI elements in this language',
                  ),
                  const SizedBox(height: 16),
                  _buildSupportDetail(
                    'Subtitles',
                    supports['Subtitles']!,
                    Icons.closed_caption_rounded,
                    'Text and captions in this language',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportDetail(String title, bool isSupported, IconData icon, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSupported 
                ? Colors.green[900]?.withOpacity(0.3)
                : Colors.grey[800]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSupported ? Colors.green[300] : Colors.grey[500],
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSupported 
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    color: isSupported ? Colors.green[300] : Colors.grey[500],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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

    final bool intendingToSave = !_isSaved;
    bool shouldUnhide = false;

    // --- Rule: Saving a game removes hidden status ---
    if (intendingToSave && _isHidden) {
      shouldUnhide = true;
      print('Save action is unhiding the game.');
    }

    try {
      // Perform save/unsave FIRST
      final bool success = intendingToSave
        ? await _libraryRepository.saveGame(_game.gameId!)
        : await _libraryRepository.unsaveGame(_game.gameId!);

      if (success && mounted) {
        setState(() {
          _isSaved = intendingToSave;
          
          // Unhide if necessary
          if (shouldUnhide) {
            _isHidden = false;
          }
          
          // Update the game's userActions
          _game.userActions = (_game.userActions ?? UserGameActions()).copyWith(
             isSaved: _isSaved,
             isHidden: _isHidden, // Update hidden status
          );

          print('Updated isSaved: $_isSaved');
          print('Updated isHidden: $_isHidden');
          print('Updated userActions: ${_game.userActions}');
        });
        
        // Update in HomeController for other pages
        _homeController.updateGameSaveState(_game.gameId!, _isSaved);
        if (shouldUnhide) {
           // Call HomeController to update hidden status
           _homeController.updateGameHiddenState(_game.gameId!, false);
           print('HomeController hidden state update needed for game ${_game.gameId}: false'); 
        }

        // Show save animation if game is being saved
        if (_isSaved) {
          _showSavedNotification();
        }

        // Call backend to unhide game if shouldUnhide is true
        // This might be redundant if saving implicitly unhides on the backend
        if (shouldUnhide) {
           print('Backend call needed: unhideGame(${_game.gameId})');
           try {
             await _libraryRepository.unhideGame(_game.gameId!); // Await is already valid here
           } catch (e) {
             print('Error unhiding game via save: $e');
             // Optionally show error to user
           }
        }
      }
    } catch (e) {
      print('Error saving/unhiding game: $e');
       // SnackBar removed
       // ScaffoldMessenger.of(context).showSnackBar(
       //   SnackBar(content: Text('Error updating game: ${e.toString()}')),
       // );
    }
  }

  // --- New handler for Hide/Unhide button ---
  Future<void> _handleHideGame() async {
    if (_game.gameId == null) return;

    final bool intendToHide = !_isHidden;

    // --- Rule: Hiding removes rating, review, saved status ---
    int? previousRating;
    String? previousComment;
    bool wasSaved;

    if (intendToHide) {
      print('Hide action initiated. Clearing rating, review, save status.');
      previousRating = _userRating;
      previousComment = _game.userActions?.comment;
      wasSaved = _isSaved;
    } else {
      // Unhiding doesn't automatically restore previous states
      print('Unhide action initiated.');
      wasSaved = false; // To avoid unnecessary backend call check later
    }

    // Call backend for hide/unhide
    print('Backend call needed: ${intendToHide ? 'hideGame' : 'unhideGame'}(${_game.gameId})');
    try {
      bool success = false;
      if (intendToHide) {
        success = await _libraryRepository.hideGame(_game.gameId!); // Await is valid here
      } else {
        success = await _libraryRepository.unhideGame(_game.gameId!); // Await is valid here
      }
      
      if (!success) throw Exception('Backend update failed');

      // Update state only after successful backend call
      if (mounted) { 
        setState(() {
          _isHidden = intendToHide;

          // If hiding, clear related states
          if (intendToHide) {
            _userRating = null;
            _isSaved = false;
            // Update game object's actions
            _game = _game.copyWith(
              userActions: (_game.userActions ?? UserGameActions()).copyWith(
                isHidden: true,
                isRated: false,
                userRating: null,
                comment: null,
                isSaved: false,
              ),
            );
          } else {
            // If unhiding, just update the hidden flag in the game object
             _game = _game.copyWith(
              userActions: (_game.userActions ?? UserGameActions()).copyWith(
                isHidden: false,
              ),
            );
          }
           print('Updated isHidden: $_isHidden');
           print('Updated userRating: $_userRating');
           print('Updated isSaved: $_isSaved');
           print('Updated userActions: ${_game.userActions}');
        });

        // Update HomeController
        if (_game.gameId != null) {
           // Call HomeController to update hidden status
           _homeController.updateGameHiddenState(_game.gameId!, _isHidden);
           print('HomeController hidden state update needed for game ${_game.gameId}: $_isHidden'); 

          // If hiding, update other states in HomeController too
          // These are now automatically handled by updateGameHiddenState in HomeController
          /* if (intendToHide) {
            _homeController.updateGameRatingState(_game.gameId!, null); 
            _homeController.updateGameComment(_game.gameId!, null); 
            _homeController.updateGameSaveState(_game.gameId!, false); 
          } */
        }
      }

    } catch (e) {
       print('Error hiding/unhiding game: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error updating hidden status: ${e.toString()}')),
         );
       }
       return; // Don't update UI if backend failed
    }

    // Commented out old state update logic that was moved inside the try block
    /* setState(() {
      _isHidden = intendToHide;

      // If hiding, clear related states
      if (intendToHide) {
        _userRating = null;
        _isSaved = false;
        // Update game object's actions
        _game = _game.copyWith(
          userActions: (_game.userActions ?? UserGameActions()).copyWith(
            isHidden: true,
            isRated: false,
            userRating: null,
            comment: null,
            isSaved: false,
          ),
        );
      } else {
        // If unhiding, just update the hidden flag in the game object
         _game = _game.copyWith(
          userActions: (_game.userActions ?? UserGameActions()).copyWith(
            isHidden: false,
          ),
        );
      }
       print('Updated isHidden: $_isHidden');
       print('Updated userRating: $_userRating');
       print('Updated isSaved: $_isSaved');
       print('Updated userActions: ${_game.userActions}');
    });

    // Update HomeController
    if (_game.gameId != null) {
       // Call HomeController to update hidden status
       _homeController.updateGameHiddenState(_game.gameId!, _isHidden);
       print('HomeController hidden state update needed for game ${_game.gameId}: $_isHidden'); 

      // If hiding, update other states in HomeController too
      if (intendToHide) {
        _homeController.updateGameRatingState(_game.gameId!, null);
        _homeController.updateGameComment(_game.gameId!, null);
        _homeController.updateGameSaveState(_game.gameId!, false);
      }
    } */

    // TODO: Optional: Add backend calls to remove rating/review/save status if hiding
    // These might be handled implicitly by the hideGame endpoint, or need separate calls.
    // if (intendToHide) {
    //    if (previousRating != null) { /* call remove rating endpoint */ }
    //    if (previousComment != null) { /* call remove comment endpoint */ }
    //    if (wasSaved) { /* call unsave endpoint */ }
    // }
  }

  void _showSavedNotification() {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 40, // Biraz daha büyük container için ayarladım
        left: MediaQuery.of(context).size.width / 2 - 40,  // Biraz daha büyük container için ayarladım
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                width: 80, // Container boyutu
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5), // Yarı şeffaf siyah arka plan
                  borderRadius: BorderRadius.circular(16), // Yumuşak köşeler
                ),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.solidBookmark,
                    color: Colors.orange[400],
                    size: 40, // İkonu biraz küçülttüm container içinde daha iyi görünmesi için
                  ),
                ),
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

  Future<void> _loadGameReviews() async {
    if (_game.gameId == null || _currentUserId == null) {
      print('Cannot load reviews: gameId or currentUserId is null');
      return;
    }

    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final filter = RatingFilterRequest(gameId: _game.gameId);
      final reviews = await _ratingRepository.filterRatingsWithUser(
        filter: filter,
        page: 0,
        size: 20, // Fetch a bit more initially to find user's review
      );

      UserGameRatingWithUser? currentUserReview;
      List<UserGameRatingWithUser> otherReviews = [];

      // Loop over the 'content' list inside the PagedResponse
      for (final review in reviews.content) { 
        if (review.userId == _currentUserId) {
          currentUserReview = review;
          // API'den gelen enum değerlerini hemen logla
          print('Found user review in API response: playStatus=${review.playStatus}, completionStatus=${review.completionStatus}, playtimeInMinutes=${review.playtimeInMinutes}');
        } else {
          otherReviews.add(review);
        }
      }

      if (mounted) {
        setState(() {
          // Update game actions with the fetched user review details (if found)
          if (currentUserReview != null) {
             print('User review found, updating _game.userActions and _currentUserReviewData');
            
            // Parse and handle nullable values
            PlayStatus? updatedPlayStatus = currentUserReview.playStatus;
            CompletionStatus? updatedCompletionStatus = currentUserReview.completionStatus;
            
            // Apply defaults if null
            updatedPlayStatus ??= PlayStatus.notSet;
            updatedCompletionStatus ??= CompletionStatus.notSelected;
            
            // Preserve meaningful values
            if (updatedPlayStatus == PlayStatus.notSet && 
                _game.userActions?.playStatus != null && 
                _game.userActions!.playStatus != PlayStatus.notSet) {
              print('Preserving existing playStatus: ${_game.userActions!.playStatus} instead of API value: $updatedPlayStatus');
              updatedPlayStatus = _game.userActions!.playStatus;
            }
            
            if (updatedCompletionStatus == CompletionStatus.notSelected && 
                _game.userActions?.completionStatus != null && 
                _game.userActions!.completionStatus != CompletionStatus.notSelected) {
              print('Preserving existing completionStatus: ${_game.userActions!.completionStatus} instead of API value: $updatedCompletionStatus');
              updatedCompletionStatus = _game.userActions!.completionStatus;
            }
            
            _game = _game.copyWith(
              userActions: (_game.userActions ?? UserGameActions()).copyWith(
                isRated: true,
                userRating: currentUserReview.rating,
                comment: currentUserReview.comment,
                // Using our properly parsed values that can't be null anymore
                playStatus: updatedPlayStatus,
                completionStatus: updatedCompletionStatus,
                playtimeInMinutes: currentUserReview.playtimeInMinutes,
              ),
            );
            
             // Also update _currentUserReviewData with our corrected values
             _currentUserReviewData = UserGameRatingWithUser(
               id: currentUserReview.id,
               userId: currentUserReview.userId,
               gameId: currentUserReview.gameId,
               rating: currentUserReview.rating,
               comment: currentUserReview.comment,
               playStatus: updatedPlayStatus,
               completionStatus: updatedCompletionStatus,
               playtimeInMinutes: currentUserReview.playtimeInMinutes,
               lastUpdatedDate: currentUserReview.lastUpdatedDate,
               username: currentUserReview.username,
               profilePhotoUrl: currentUserReview.profilePhotoUrl,
               profilePhotoType: currentUserReview.profilePhotoType,
             );
             
             // Also update local _userRating state if necessary for consistency
             _userRating = currentUserReview.rating;
             print('Updated _userRating from fetched review: $_userRating');
             print('Updated _game.userActions.comment from fetched review: ${_game.userActions?.comment}');
             print('Updated _game.userActions.playStatus from fetched review: ${_game.userActions?.playStatus}');
             print('Updated _game.userActions.completionStatus from fetched review: ${_game.userActions?.completionStatus}');
             print('Updated _game.userActions.playtimeInMinutes from fetched review: ${_game.userActions?.playtimeInMinutes}');
             
             // DEBUG: Diğer nesnelerin değerlerini kontrol et
             print('_currentUserReviewData after update: playStatus=${_currentUserReviewData?.playStatus}, completionStatus=${_currentUserReviewData?.completionStatus}');
             print('Direct _game.userActions check: ${_game.userActions}');
          } else {
            // If user's review wasn't in the fetched list (maybe they haven't reviewed)
            // Ensure local state reflects no rating/comment if it wasn't set initially
            // This part might need refinement based on how initial state is handled
             print('User review not found in fetched list.');
          }

          // Store only *other* users' reviews for the horizontal list
          // Limit to 9 as before for the horizontal display
          _gameReviews = otherReviews.take(9).toList();
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading game reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }
  
  // Yorum gönderildiğinde çağrılacak metod
  void _handleReviewSubmitted(String? comment) async {
    if (_game.gameId == null || _currentUserId == null) return;

    final int? previousRating = _userRating; // Store previous rating

    // Update local state immediately
    setState(() {
      final currentActions = _game.userActions ?? UserGameActions();
      _game = _game.copyWith(
        userActions: currentActions.copyWith(
          comment: comment,
          // Assuming rating doesn't change here, only comment
        ),
      );
      print('ReviewModal Callback - Updated comment in GameDetail: $comment');
    });

    // Update HomeController
    _homeController.updateGameComment(_game.gameId!, comment);

    // Backend call
    try {
      if (comment != null && comment.isNotEmpty) {
        await _ratingRepository.commentGame(_game.gameId!, comment);
        print('Comment successfully sent to backend: $comment');
      } else {
        // Only delete comment if there was a rating previously
        // If no rating exists, submitting an empty comment shouldn't delete anything
        if (previousRating != null && previousRating > 0) {
           await _ratingRepository.deleteComment(_game.gameId!);
           print('Comment deleted from backend because it was empty/null');
        } else {
           print('Skipping comment deletion as there was no prior rating.');
        }
      }
      // Refresh reviews after successful backend update
      await _loadGameReviews();
    } catch (e) {
      print('Error submitting comment to backend: $e');
      // Revert state or show error?
      // Consider showing a snackbar
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error saving review: ${e.toString()}')),
         );
       }
       // Optionally revert the comment state here if needed
    }
  }

  IconData _getPlayStatusIcon(PlayStatus status) {
    switch (status) {
      case PlayStatus.notSet: return Icons.help_outline;
      case PlayStatus.playing: return Icons.gamepad;
      case PlayStatus.completed: return Icons.check_circle_outline;
      case PlayStatus.dropped: return Icons.cancel_outlined;
      case PlayStatus.onHold: return Icons.pause_circle_outline;
      case PlayStatus.backlog: return Icons.pending_outlined;
      case PlayStatus.skipped: return Icons.skip_next;
    }
  }

  String _getPlayStatusText(PlayStatus status) {
    switch (status) {
      case PlayStatus.notSet: return "Not Started";
      case PlayStatus.playing: return "Currently Playing";
      case PlayStatus.completed: return "Completed";
      case PlayStatus.dropped: return "Dropped";
      case PlayStatus.onHold: return "On Hold";
      case PlayStatus.backlog: return "In Backlog";
      case PlayStatus.skipped: return "Skipped";
    }
  }

  IconData _getCompletionStatusIcon(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.notSelected: return Icons.help_outline;
      case CompletionStatus.mainStory: return Icons.book_outlined;
      case CompletionStatus.mainStoryPlusExtras: return Icons.extension_outlined;
      case CompletionStatus.hundredPercent: return Icons.workspace_premium_outlined;
    }
  }

  String _getCompletionStatusText(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.notSelected: return "Not Selected";
      case CompletionStatus.mainStory: return "Main Story";
      case CompletionStatus.mainStoryPlusExtras: return "Main Story + Extras";
      case CompletionStatus.hundredPercent: return "100% Completion";
    }
  }

  String _formatPlaytime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      if (mins > 0) {
        return "$hours hr $mins min";
      } else {
        return "$hours hr";
      }
    } else {
      return "$mins min";
    }
  }

  // Add this helper method to create compact info chips
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Original padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6), // Original radius
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 14, // Original size
          ),
          const SizedBox(width: 4), // Original spacing
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12, // Original font size
            ),
          ),
        ],
      ),
    );
  }

  // Add a new method for icon-only chips
  Widget _buildIconChip(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
      ),
    );
  }

  // Return tooltip text for PlayStatus
  String _getPlayStatusTooltip(PlayStatus status) {
    return _getPlayStatusText(status);
  }
}
