import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/providers/blurred_background_provider.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/core/widgets/rating_modal.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'dart:ui';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/features/home/presentation/widgets/add_game_to_library_modal.dart';
import 'package:ludicapp/core/enums/library_type.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';
import 'package:ludicapp/features/profile/presentation/followers_page.dart';
import 'package:ludicapp/core/enums/display_mode.dart';
import 'package:ludicapp/features/profile/presentation/profile_page.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';

class LibraryDetailPage extends StatefulWidget {
  final LibrarySummaryResponse librarySummary;
  final String? userId;
  final bool isFollowable;

  const LibraryDetailPage({
    Key? key,
    required this.librarySummary,
    this.userId,
    this.isFollowable = false,
  }) : super(key: key);

  @override
  State<LibraryDetailPage> createState() => _LibraryDetailPageState();
}

class _LibraryDetailPageState extends State<LibraryDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final LibraryRepository _libraryRepository = LibraryRepository();
  final HomeController _homeController = HomeController();
  final BlurredBackgroundProvider _backgroundProvider = BlurredBackgroundProvider();
  final TokenService _tokenService = TokenService();
  final TextEditingController _titleController = TextEditingController();
  
  List<GameSummary> games = [];
  Map<int, GameDetailWithUserInfo> gameDetailsMap = {};
  Set<int> savedGames = {};
  Set<int> ratedGames = {};
  Map<int, int> userRatings = {};
  
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  
  late int _libraryId;
  String? _currentTitle;
  String? _currentCoverUrl;
  bool _isPrivate = false;
  int? _followerCount;
  bool _isFollowing = false;
  
  double _headerOpacity = 0.0;
  int? _currentUserId;
  bool _isOwnedByCurrentUser = false;
  
  @override
  void initState() {
    super.initState();
    _libraryId = widget.librarySummary.id;
    _currentTitle = widget.librarySummary.displayName;
    _currentCoverUrl = widget.librarySummary.coverUrl;
    _isPrivate = widget.librarySummary.isPrivate;
    _followerCount = widget.librarySummary.followerCount;
    _isFollowing = widget.librarySummary.isCurrentUserFollowing ?? false;
    
    _titleController.text = _currentTitle ?? '';
    _scrollController.addListener(_onScroll);
    _loadInitialDataAndOwnership();
    
    if (_currentCoverUrl != null) {
      _backgroundProvider.cacheBackground('library_$_libraryId', _currentCoverUrl);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.9;

    if (currentScroll >= threshold && !_isLoading && _hasMore) {
      _currentPage++;
      _loadGames();
    }
    
    if (_scrollController.offset <= 300) {
      setState(() {
        _headerOpacity = _scrollController.offset / 300;
      });
    } else if (_headerOpacity != 1.0) {
      setState(() {
        _headerOpacity = 1.0;
      });
    }
  }

  Future<void> _loadInitialDataAndOwnership() async {
    await _loadCurrentUserIdAndCheckOwnership();
    _loadGames();
  }

  Future<void> _loadCurrentUserIdAndCheckOwnership() async {
    try {
      _currentUserId = await _tokenService.getUserId();
      if (mounted && _currentUserId != null) {
        setState(() {
          _isOwnedByCurrentUser = widget.librarySummary.ownerUserId == _currentUserId;
          print('Ownership check: owner=${widget.librarySummary.ownerUserId}, current=$_currentUserId, isOwned=$_isOwnedByCurrentUser');
        });
      } else if (mounted) {
         setState(() { _isOwnedByCurrentUser = false; }); 
      }
    } catch (e) {
      print("Error loading current user ID for ownership check: $e");
      if (mounted) {
         setState(() { _isOwnedByCurrentUser = false; }); 
      }
    }
  }

  Future<void> _loadGames() async {
    if (_isLoading || (!_hasMore && _currentPage > 0)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _libraryRepository.getGamesByLibraryId(
        _libraryId,
        page: _currentPage,
        size: _pageSize,
      );

      if (mounted) {
        _processGameResponse(response);
      }
    } catch (e) {
      print('Error loading games: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  void _processGameResponse(PagedGameWithUserResponse response) {
    final newGames = response.content.map((gameWithUser) {
      _processUserGameInfo(gameWithUser);
      gameDetailsMap[gameWithUser.gameDetails.id] = gameWithUser;
      return gameWithUser.gameDetails;
    }).toList();
    
    if (mounted) {
      for (final game in newGames) {
        if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(game.coverUrl!), context)
            .catchError((e) => print('Pre-cache Error (Cover ${game.id}): $e'));
        }
      }
    }

    setState(() {
      if (_currentPage == 0) {
        games = newGames;
      } else {
        games.addAll(newGames);
      }
      _hasMore = response.last != null ? !response.last! : false;
      _isLoading = false;
      _isInitialLoading = false;
    });
  }

  void _processUserGameInfo(GameDetailWithUserInfo gameWithUser) {
    final gameId = gameWithUser.gameDetails.id;
    final userActions = gameWithUser.userActions;
    
    if (userActions != null) {
      if (userActions.userRating != null) {
        userRatings[gameId] = userActions.userRating!;
        ratedGames.add(gameId);
      }
      
      if (userActions.isSaved == true) {
        savedGames.add(gameId);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final bool intendToFollow = !_isFollowing;
    bool success = false;

    setState(() {
       _isLoading = true;
    });

    try {
       if (intendToFollow) {
          success = await _libraryRepository.followLibrary(_libraryId);
       } else {
          success = await _libraryRepository.unfollowLibrary(_libraryId);
       }

       if (success && mounted) {
          setState(() {
             _isFollowing = intendToFollow;
             if (intendToFollow) {
                _followerCount = (_followerCount ?? 0) + 1;
             } else {
                _followerCount = (_followerCount ?? 1) - 1;
                if (_followerCount! < 0) _followerCount = 0;
             }
          });
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                content: Text(intendToFollow ? 'Library followed' : 'Library unfollowed'),
                duration: const Duration(seconds: 2),
             ),
          );
       } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to ${intendToFollow ? 'follow' : 'unfollow'} library.')),
          );
       }
    } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
    } finally {
       if (mounted) {
          setState(() {
             _isLoading = false;
          });
       }
    }
  }

  Future<void> _handleSaveGame(GameSummary game) async {
    final gameDetail = gameDetailsMap[game.id];
    final isSaved = gameDetail?.userActions?.isSaved ?? false;

    try {
      final bool success = isSaved 
        ? await _libraryRepository.unsaveGame(game.id)
        : await _libraryRepository.saveGame(game.id);

      if (success && mounted) {
        setState(() {
          if (gameDetail != null) {
            final updatedActions = gameDetail.userActions?.copyWith(isSaved: !isSaved) ?? 
                UserGameActions(isSaved: !isSaved);
            gameDetailsMap[game.id] = GameDetailWithUserInfo(
              gameDetails: gameDetail.gameDetails,
              userActions: updatedActions,
            );
          }
        });
        
        _homeController.updateGameSaveState(game.id, !isSaved);

        if (!isSaved) {
          _showSavedNotification();
        }
      }
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  void _showRatingDialog(GameSummary game) {
    RatingModal.show(
      context,
      gameName: game.name,
      coverUrl: game.coverUrl ?? '',
      gameId: game.id,
      initialRating: userRatings[game.id],
      onRatingSelected: (rating) {
        setState(() {
          if (rating > 0) {
            userRatings[game.id] = rating;
            ratedGames.add(game.id);
            
            if (gameDetailsMap.containsKey(game.id)) {
              final existingGameDetail = gameDetailsMap[game.id]!;
              final updatedActions = existingGameDetail.userActions?.copyWith(
                isRated: true,
                userRating: rating,
              ) ?? UserGameActions(
                isRated: true,
                userRating: rating,
                isSaved: existingGameDetail.userActions?.isSaved ?? false,
              );
              
              gameDetailsMap[game.id] = GameDetailWithUserInfo(
                gameDetails: existingGameDetail.gameDetails,
                userActions: updatedActions,
              );
            }
          } else {
            userRatings.remove(game.id);
            ratedGames.remove(game.id);
            
            if (gameDetailsMap.containsKey(game.id)) {
              final existingGameDetail = gameDetailsMap[game.id]!;
              final updatedActions = existingGameDetail.userActions?.copyWith(
                isRated: false,
                userRating: null,
              ) ?? UserGameActions(
                isRated: false,
                userRating: null,
                isSaved: existingGameDetail.userActions?.isSaved ?? false,
              );
              
              gameDetailsMap[game.id] = GameDetailWithUserInfo(
                gameDetails: existingGameDetail.gameDetails,
                userActions: updatedActions,
              );
            }
          }
        });
      },
    );
  }

  Future<void> _handleHideGame(GameSummary gameToHide) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Hide Game',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to hide "${gameToHide.name}"? You won\'t see it again in your recommendations.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hide'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        games.removeWhere((game) => game.id == gameToHide.id);
      });
    }
  }

  void _showSavedNotification() {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 40,
        left: MediaQuery.of(context).size.width / 2 - 40,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red[400],
                    size: 40,
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

  bool get _isCustomLibrary => widget.librarySummary.libraryType == LibraryType.CUSTOM;

  Future<void> _showEditDialog() async {
    _titleController.text = _currentTitle ?? '';
    bool tempIsPrivate = _isPrivate;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
          return StatefulBuilder(
             builder: (context, setDialogState) {
                final theme = Theme.of(context);
                final inputTheme = theme.inputDecorationTheme;

                return AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(16.0)
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  title: Text('Edit Library', style: theme.textTheme.headlineSmall),
                  content: Column(
                     mainAxisSize: MainAxisSize.min, 
                     children: [
                        TextField(
                           controller: _titleController,
                           style: theme.textTheme.bodyLarge,
                           decoration: InputDecoration(
                              hintText: 'Enter library name',
                              hintStyle: inputTheme.hintStyle,
                              filled: inputTheme.filled,
                              fillColor: inputTheme.fillColor,
                              contentPadding: inputTheme.contentPadding,
                              enabledBorder: inputTheme.enabledBorder,
                              focusedBorder: inputTheme.focusedBorder,
                           ),
                           autofocus: true,
                           textCapitalization: TextCapitalization.sentences, 
                        ),
                        const SizedBox(height: 20),
                        SwitchListTile(
                           title: Text('Private Library', style: theme.textTheme.titleMedium),
                           subtitle: Text('Only you can see this library and its content.', style: theme.textTheme.bodySmall),
                           value: tempIsPrivate,
                           onChanged: (bool newValue) { 
                              setDialogState(() { 
                                 tempIsPrivate = newValue;
                              });
                           },
                           activeColor: theme.colorScheme.primary,
                           tileColor: theme.brightness == Brightness.dark 
                              ? theme.colorScheme.surface.withOpacity(0.5) 
                              : theme.colorScheme.surface,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                     ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      style: TextButton.styleFrom(
                         foregroundColor: theme.textTheme.labelLarge?.color?.withOpacity(0.7),
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final enteredTitle = _titleController.text.trim();
                        if (enteredTitle.isNotEmpty) {
                           Navigator.pop(context, {'title': enteredTitle, 'isPrivate': tempIsPrivate}); 
                        }
                      },
                      style: theme.elevatedButtonTheme.style?.copyWith(
                         foregroundColor: MaterialStateProperty.all(theme.colorScheme.onPrimary),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                );
             },
          );
       },
    );

    if (result != null) {
      final String newTitle = result['title'] as String;
      final bool newIsPrivate = result['isPrivate'] as bool;
      
      if (newTitle != _currentTitle || newIsPrivate != _isPrivate) {
         setState(() { _isLoading = true; }); 
         final updatedDto = await _libraryRepository.updateCustomLibrary(
            _libraryId,
            newTitle,
            newIsPrivate
         );
         setState(() { _isLoading = false; }); 

         if (updatedDto != null && mounted) {
            setState(() {
               _currentTitle = updatedDto.title;
               _isPrivate = newIsPrivate;
            });
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Library updated successfully!')),
            );
         } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Failed to update library. Please try again.')),
            );
         }
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
         final theme = Theme.of(context);
         return AlertDialog(
            backgroundColor: theme.dialogBackgroundColor,
            title: Text('Delete Library', style: theme.textTheme.headlineSmall),
            content: Text(
              'Are you sure you want to permanently delete the "$_currentTitle" library? This cannot be undone.',
              style: theme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                   foregroundColor: theme.textTheme.labelLarge?.color?.withOpacity(0.7),
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
         );
      }
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; });
      final success = await _libraryRepository.deleteCustomLibrary(_libraryId);
      setState(() { _isLoading = false; });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Library "$_currentTitle" deleted.')),
        );
        Navigator.pop(context, 'deleted'); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete library. Please try again.')),
        );
      }
    }
  }

  void _handleGameAddedFromModal(GameDetailWithUserInfo addedGameDetails) { 
    final GameSummary newGameSummary = GameSummary.fromGameDetailWithUserInfo(addedGameDetails);
    
    final String? newCoverUrl = addedGameDetails.gameDetails.coverUrl;

    if (newGameSummary.id != 0) { 
        setState(() {
            bool addedToList = false;
            if (!games.any((g) => g.id == newGameSummary.id)) {
               games.insert(0, newGameSummary); 
               addedToList = true;
               if (_scrollController.hasClients) {
                  Future.delayed(Duration(milliseconds: 100), () { 
                    if (_scrollController.hasClients) { 
                      _scrollController.animateTo(
                        0.0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
            }

            if (newCoverUrl != null && newCoverUrl.isNotEmpty) {
               print("Library cover updated via addGame callback details: $newCoverUrl");
               _currentCoverUrl = newCoverUrl;
               _backgroundProvider.cacheBackground('library_$_libraryId', _currentCoverUrl);
            }
        });
    } else {
       print("Could not add game optimistically: Invalid game ID");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBlurredBackground(),
          
          _buildMainContent(),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildAppBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    if (_currentCoverUrl == null) {
      return Container(color: AppTheme.primaryDark);
    }
    
    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
                  key: ValueKey(_currentCoverUrl),
                  imageUrl: _currentCoverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppTheme.primaryDark),
                  errorWidget: (context, url, error) => Container(color: AppTheme.primaryDark),
                ),
        ),
        
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: AppTheme.primaryDark.withOpacity(0.7),
            ),
          ),
        ),
        
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.primaryDark.withOpacity(0.6),
                  AppTheme.primaryDark,
                ],
                stops: const [0.1, 0.5, 0.8],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: MediaQuery.of(context).padding.top + 56,
      color: AppTheme.primaryDark.withOpacity(_headerOpacity),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context, 'updated'),
          ),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _headerOpacity,
              child: Text(
                _currentTitle ?? widget.librarySummary.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (widget.isFollowable)
            IconButton(
              icon: Icon(
                _isFollowing ? Icons.check : Icons.add,
                color: Colors.white,
              ),
              onPressed: _toggleFollow,
            )
          else if (_isOwnedByCurrentUser && _isCustomLibrary)
             PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: AppTheme.surfaceDark,
                shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                onSelected: (value) {
                   if (value == 'edit') {
                      _showEditDialog();
                   } else if (value == 'delete') {
                      _showDeleteConfirmationDialog();
                   }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                   PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                         minLeadingWidth: 0,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                         leading: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                         title: const Text('Edit', style: TextStyle(color: Colors.white)),
                      ),
                   ),
                   PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                         minLeadingWidth: 0,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                         leading: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                         title: const Text('Delete Library', style: TextStyle(color: Colors.redAccent)),
                      ),
                   ),
                ],
             ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 20),
        ),
        
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.67,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildGameCard(games[index]);
              },
              childCount: games.length, 
            ),
          ),
        ),
        
        if (_isLoading && _hasMore) 
           SliverToBoxAdapter(
             child: _buildLoadingIndicator(),
           ),
           
        SliverToBoxAdapter(
           child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _currentCoverUrl != null 
                  ? CachedNetworkImage(
                      key: ValueKey(_currentCoverUrl),
                      imageUrl: _currentCoverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[800]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(
                          _getLibraryIcon(_currentTitle ?? widget.librarySummary.displayName),
                          color: Colors.white.withOpacity(0.9),
                          size: 60,
                        ),
                      ),
                    ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            _currentTitle ?? widget.librarySummary.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              if (widget.librarySummary.ownerUserId != null) ...[
                GestureDetector(
                  onTap: () {
                    if (widget.librarySummary.ownerUserId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userId: widget.librarySummary.ownerUserId.toString(),
                            fromSearch: true,
                          ),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: widget.librarySummary.ownerProfilePhotoType == ProfilePhotoType.CUSTOM && 
                                         widget.librarySummary.ownerProfilePhotoUrl != null &&
                                         widget.librarySummary.ownerProfilePhotoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(widget.librarySummary.ownerProfilePhotoUrl!)
                            : null,
                        child: _buildOwnerProfileImage(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.librarySummary.ownerUsername ?? 'User',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 16,
                  width: 1,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 16),
              ],
              
              Text(
                '${widget.librarySummary.gameCount} Games',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
              ),
              
              if (_isCustomLibrary) ...[
                 const SizedBox(width: 16),
                 Icon(
                    Icons.people_outline,
                    color: Colors.grey[400],
                    size: 16,
                 ),
                 const SizedBox(width: 4),
                 GestureDetector(
                    onTap: () {
                       print('Follower count tapped for library $_libraryId');
                       final ownerId = widget.librarySummary.ownerUserId;
                       if (ownerId != null) {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => FollowersPage(
                               userId: ownerId,
                               username: "Owner's",
                               initialMode: DisplayMode.followers,
                             ),
                           ),
                         );
                       } else {
                         print('Cannot navigate to followers page: Library owner ID is null.');
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Cannot view followers for this library.')),
                         );
                       }
                    },
                    child: Text(
                       '${_followerCount ?? 0} Followers',
                       style: TextStyle(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          fontSize: 16,
                       ),
                    ),
                 ),
              ],
              
              const Spacer(),
              
              if (_isPrivate)
                 Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey[400],
                    size: 18,
                 ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (_isOwnedByCurrentUser && _isCustomLibrary)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  final Set<int> currentLibraryGameIds = games.map((g) => g.id).toSet();
                  AddGameToLibraryModal.show(
                    context,
                    targetLibraryId: _libraryId,
                    targetLibraryType: LibraryType.CUSTOM,
                    libraryName: _currentTitle ?? widget.librarySummary.displayName, 
                    limit: 50, 
                    onGameAddedCallback: _handleGameAddedFromModal,
                    initialGameIdsInLibrary: currentLibraryGameIds, 
                  );
                },
                icon: const Icon(Icons.playlist_add, size: 20),
                label: const Text('Add Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          
          if (widget.isFollowable)
            ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[800] : Theme.of(context).colorScheme.primary,
                foregroundColor: _isFollowing ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isFollowing ? Icons.check : Icons.add,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameSummary game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
                final coverProvider = CachedNetworkImageProvider(game.coverUrl!);
                precacheImage(coverProvider, context)
                    .catchError((e) => print('Error pre-caching cover: $e'));
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailPage(
                    game: gameDetailsMap[game.id] != null 
                      ? Game.fromGameDetailWithUserInfo(gameDetailsMap[game.id]!)
                      : Game.fromGameSummary(game),
                  ),
                ),
              ).then((result) {
                if (result != null && result is Game) {
                  setState(() {
                    if (gameDetailsMap.containsKey(game.id)) {
                      final updatedActions = UserGameActions(
                        isSaved: result.userActions?.isSaved ?? false,
                        isRated: result.userActions?.isRated ?? false,
                        userRating: result.userActions?.userRating,
                      );
                      
                      gameDetailsMap[game.id] = GameDetailWithUserInfo(
                        gameDetails: gameDetailsMap[game.id]!.gameDetails,
                        userActions: updatedActions,
                      );
                      
                      if (updatedActions.isSaved == true) {
                        savedGames.add(game.id);
                      } else {
                        savedGames.remove(game.id);
                      }
                      
                      if (updatedActions.isRated == true && updatedActions.userRating != null) {
                        ratedGames.add(game.id);
                        userRatings[game.id] = updatedActions.userRating!;
                      } else {
                        ratedGames.remove(game.id);
                        userRatings.remove(game.id);
                      }
                    }
                  });
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color?.withOpacity(0.8) ?? Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      key: ValueKey(game.coverUrl),
                      imageUrl: game.coverUrl ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(color: Theme.of(context).cardTheme.color?.withOpacity(0.5) ?? Colors.grey[800]),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).cardTheme.color?.withOpacity(0.5) ?? Colors.grey[800],
                        child: Icon(Icons.error, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (savedGames.contains(game.id))
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite,
                              color: Theme.of(context).colorScheme.error,
                              size: 16,
                            ),
                          ),
                          
                        if (ratedGames.contains(game.id))
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${userRatings[game.id]}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            game.name,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      ),
    );
  }

  IconData _getLibraryIcon(String title) {
    switch (widget.librarySummary.libraryType) {
      case LibraryType.SAVED:
        return Icons.bookmark;
      case LibraryType.HID:
        return Icons.visibility_off;
      case LibraryType.RATED:
        return Icons.star;
      case LibraryType.CURRENTLY_PLAYING:
        return Icons.sports_esports;
      case LibraryType.CUSTOM:
         switch (title) {
           default:
             return Icons.list_alt;
         }
      default:
        return Icons.games;
    }
  }

  Widget _buildOwnerProfileImage() {
    if (widget.librarySummary.ownerProfilePhotoType == ProfilePhotoType.CUSTOM && 
        widget.librarySummary.ownerProfilePhotoUrl != null && 
        widget.librarySummary.ownerProfilePhotoUrl!.isNotEmpty) {
      return Container();
    } else if (widget.librarySummary.ownerProfilePhotoType != ProfilePhotoType.CUSTOM) {
      final String? assetPath = widget.librarySummary.ownerProfilePhotoType.assetPath;
      if (assetPath != null) {
        return Image.asset(
          assetPath,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile default image: $error in path: $assetPath');
            return const Icon(Icons.person, color: Colors.white, size: 18);
          },
        );
      }
    }
    
    return const Icon(Icons.person, color: Colors.white, size: 18);
  }
} 
