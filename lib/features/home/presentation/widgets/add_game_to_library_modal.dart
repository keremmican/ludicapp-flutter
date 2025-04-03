import 'package:flutter/material.dart';
import 'package:ludicapp/services/repository/search_repository.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'package:ludicapp/core/enums/library_type.dart'; // Import LibraryType

class AddGameToLibraryModal extends StatefulWidget {
  final int? targetLibraryId; // Nullable for types like CurrentlyPlaying
  final LibraryType targetLibraryType;
  final String libraryName; // For modal title
  final int? limit; // Optional limit
  final Function(GameDetailWithUserInfo)? onGameAddedCallback; // Updated Signature
  final Set<int>? initialGameIdsInLibrary; // <-- Add this

  const AddGameToLibraryModal({
    Key? key,
    required this.targetLibraryType,
    required this.libraryName,
    this.targetLibraryId,
    this.limit,
    this.onGameAddedCallback, 
    this.initialGameIdsInLibrary, // <-- Add to constructor
  }) : super(key: key);

  static void show(BuildContext context, {
    required LibraryType targetLibraryType,
    required String libraryName, 
    int? targetLibraryId, // Make nullable
    int? limit, 
    Function(GameDetailWithUserInfo)? onGameAddedCallback, // Updated Signature
    Set<int>? initialGameIdsInLibrary, // <-- Add here too
  }) {
    if (targetLibraryType == LibraryType.CUSTOM && targetLibraryId == null) {
      print("Error: targetLibraryId is required for CUSTOM library type.");
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: Library ID missing for custom list.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.8, 
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: AddGameToLibraryModal(
               targetLibraryType: targetLibraryType,
               libraryName: libraryName,
               targetLibraryId: targetLibraryId,
               limit: limit,
               onGameAddedCallback: onGameAddedCallback, 
               initialGameIdsInLibrary: initialGameIdsInLibrary, // <-- Pass to instance
            ),
          ),
        ),
      ),
    );
  }

  @override
  _AddGameToLibraryModalState createState() =>
      _AddGameToLibraryModalState();
}

// Helper StatefulWidget to keep the ListTile state alive
class _GameListItem extends StatefulWidget {
  final SearchGame game;
  final bool isAdded;
  final bool isProcessing;
  final bool showLimitReached;
  final VoidCallback onToggle;

  const _GameListItem({
    // Use Key for the StatefulWidget itself, based on game ID
    required Key key, 
    required this.game,
    required this.isAdded,
    required this.isProcessing,
    required this.showLimitReached,
    required this.onToggle,
  }) : super(key: key);

  @override
  _GameListItemState createState() => _GameListItemState();
}

class _GameListItemState extends State<_GameListItem> with AutomaticKeepAliveClientMixin {
  // Keep the widget alive
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Make sure to call super.build(context) for the mixin to work
    super.build(context);

    return Padding(
      // No key needed here anymore, StatefulWidget has it
      padding: const EdgeInsets.symmetric(vertical: 4.0), 
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        leading: SizedBox(
          width: 40,
          height: 55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
                imageUrl: widget.game.imageUrl ?? '', 
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                ),
            ),
          ),
        ),
        title: Text(widget.game.name, style: const TextStyle(color: Colors.white)),
        subtitle: null, 
        // Pass necessary state down to the trailing button builder
        trailing: _buildTrailingButton(),
        onTap: (widget.isProcessing || widget.game.id == null) ? null : widget.onToggle, 
      ),
    );
  }

  Widget _buildTrailingButton() {
    // Access properties via widget.
    final SearchGame game = widget.game;
    final bool isAdded = widget.isAdded;
    final bool isProcessing = widget.isProcessing;
    final bool showVisualLimit = widget.showLimitReached;
    final VoidCallback onToggle = widget.onToggle;
    
    if (game.id == null) {
     // Button for games with null ID (disabled Add)
     return OutlinedButton(
       onPressed: null,
       child: Text('Add'),
       style: OutlinedButton.styleFrom(
         foregroundColor: Colors.grey[700],
         side: BorderSide(color: Colors.grey[800]!),
         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
         textStyle: TextStyle(fontSize: 12),
         minimumSize: Size(60, 30),
       ),
     );
    }

    // Show Added/Add button 
    if (isAdded) {
       // Added button
       return TextButton.icon(
           icon: Icon(Icons.check, size: 16, color: Colors.black87),
           label: Text('Added'),
           onPressed: isProcessing ? null : onToggle, 
           style: TextButton.styleFrom(
             foregroundColor: Colors.black87,
             backgroundColor: isProcessing ? Colors.grey[600] : Theme.of(context).colorScheme.primary,
             padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
             minimumSize: Size(60, 30),
             shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
             ),
           ),
       );
    } else {
       // Add / Limit button
       return OutlinedButton(
         onPressed: (showVisualLimit || isProcessing) ? null : onToggle,
         style: OutlinedButton.styleFrom(
           foregroundColor: (showVisualLimit || isProcessing) ? Colors.grey[600] : Colors.white,
           side: BorderSide(color: (showVisualLimit || isProcessing) ? Colors.grey[800]! : Colors.grey[600]!),
           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
           textStyle: TextStyle(fontSize: 12),
           minimumSize: Size(60, 30), 
         ),
         child: Text(showVisualLimit ? 'Limit' : 'Add'),
       );
    }
  }
}

class _AddGameToLibraryModalState
    extends State<AddGameToLibraryModal> {
  static const int _pageSize = 20;

  final _searchController = TextEditingController();
  late final SearchRepository _searchRepository;
  late final LibraryRepository _libraryRepositoryModal;
  late final ScrollController _scrollController;

  List<SearchGame> _searchResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 0;
  Timer? _debounce;
  String _lastQuery = '';

  Set<int> _gamesToggledInSession = {}; 
  Set<int> _initialGameIds = {}; // Track initial IDs for comparison
  final HomeController _homeController = HomeController();
  int? _processingGameId; // ID of the game currently being added/removed
  final PageStorageKey _listKey = PageStorageKey('addGameModalListKey'); // Add PageStorageKey

  @override
  void initState() {
    super.initState();
    _searchRepository = SearchRepository();
    _libraryRepositoryModal = LibraryRepository(); 
    _scrollController = ScrollController();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    if (widget.targetLibraryType == LibraryType.CURRENTLY_PLAYING) {
      // Populate both initial set and toggled set from HomeController
      final currentlyPlayingSummaries = _homeController.currentlyPlayingGames;
      _initialGameIds = currentlyPlayingSummaries
          .map((game) => game.id) 
          .where((id) => id != 0) 
          .toSet();
      _gamesToggledInSession = Set.from(_initialGameIds); // Start toggled with initial
      print("Initial Game IDs (Currently Playing): $_initialGameIds");
    } else if (widget.targetLibraryType == LibraryType.CUSTOM && widget.initialGameIdsInLibrary != null) {
      // Use the passed set for CUSTOM lists
      _initialGameIds = Set.from(widget.initialGameIdsInLibrary!); 
      _gamesToggledInSession = Set.from(widget.initialGameIdsInLibrary!); // Start toggled with initial
      print("Initial Game IDs (Custom - Passed): $_initialGameIds");
    } else {
       // Fallback for other types or if set is not passed
      _initialGameIds = {}; 
      _gamesToggledInSession = {};
      print("Initial Game IDs (Fallback - Empty)");
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.9; 
    
    if (currentScroll >= threshold) {
      _loadMoreResults();
    }
  }

  void _loadMoreResults() {
     if (!_isLoading && _hasMore) {
        setState(() {
           _currentPage++;
        });
        _performSearch(isLoadMore: true);
     }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _lastQuery) {
        setState(() {
          _lastQuery = query;
          _searchResults = [];
          _currentPage = 0;
          _hasMore = true;
          _errorMessage = null;
        });
        if (_lastQuery.isNotEmpty) {
           _performSearch();
        } else {
           setState(() { _isLoading = false; }); 
        }
      } 
    });
  }

  Future<void> _performSearch({bool isLoadMore = false}) async {
    if (_isLoading || (!isLoadMore && !_hasMore)) return;
    if (_lastQuery.isEmpty) {
       setState(() { _searchResults = []; _isLoading = false; });
       return;
    }

    setState(() {
      _isLoading = true;
      if (!isLoadMore) { 
         _errorMessage = null;
      }
    });

    try {
      final response = await _searchRepository.searchGames(
        _lastQuery,
        _currentPage,
        _pageSize,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _searchResults.addAll(response.content);
          } else {
            _searchResults = response.content;
          }
          _hasMore = !response.last;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Search Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!isLoadMore) { 
            _errorMessage = "Error searching games: $e";
            _searchResults = [];
          }
        });
      }
    }
  }

  Future<void> _toggleGameInLibrary(SearchGame game) async {
    // Prevent concurrent operations
    if (_processingGameId != null) return; 

    if (game.id == null) {
      print('Error: Tapped game has a null ID.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot add game: Missing ID.')),
      );
      return;
    }
    
    final int gameId = game.id!;
    final bool isCurrentlyInLibrary = _gamesToggledInSession.contains(gameId); 
    
    bool limitReached = false;
    if (!isCurrentlyInLibrary && widget.limit != null) { 
       int currentCount = 0;
       if (widget.targetLibraryType == LibraryType.CURRENTLY_PLAYING) {
          // Calculate count based on initial state and session toggles
          int initialCount = _initialGameIds.length;
          int addedCount = _gamesToggledInSession.difference(_initialGameIds).length;
          int removedCount = _initialGameIds.difference(_gamesToggledInSession).length;
          currentCount = initialCount + addedCount - removedCount;
          print("Calculated Current Count: $currentCount (Initial: $initialCount, Added: $addedCount, Removed: $removedCount)");
       } else {
         // Cannot reliably check limit for CUSTOM without initial count/fetch
         // We will rely on backend to enforce limit for now for CUSTOM lists.
         // For now, assume we don't check the limit visually for CUSTOM here
       }
       
       // Check limit only if applicable and calculable
       if (widget.targetLibraryType == LibraryType.CURRENTLY_PLAYING && currentCount >= widget.limit!) { 
          limitReached = true;
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('${widget.libraryName} limit (${widget.limit}) reached.')),
          );
          return; // Exit if limit reached
       }
    }

    // Set processing state
    setState(() {
      _processingGameId = gameId;
      // Optimistic UI Update still happens here
      if (isCurrentlyInLibrary) {
        _gamesToggledInSession.remove(gameId);
      } else {
        _gamesToggledInSession.add(gameId);
      }
    });

    bool success = false;
    GameDetailWithUserInfo? returnedGameDetails; // Renamed for clarity

    try {
       // --- API Calls --- 
       if (widget.targetLibraryType == LibraryType.CURRENTLY_PLAYING) {
         if (isCurrentlyInLibrary) { 
           success = await _libraryRepositoryModal.removeFromCurrentlyPlaying(gameId);
         } else { 
           returnedGameDetails = await _libraryRepositoryModal.addToCurrentlyPlaying(gameId);
           success = returnedGameDetails != null; 
         }
       } else if (widget.targetLibraryType == LibraryType.CUSTOM) {
         if (widget.targetLibraryId == null) {
            throw Exception("targetLibraryId cannot be null for CUSTOM type");
         }
         if (isCurrentlyInLibrary) { 
            success = await _libraryRepositoryModal.removeGameFromLibrary(widget.targetLibraryId!, gameId);
            // No callback needed for removal
         } else { 
            returnedGameDetails = await _libraryRepositoryModal.addGameToLibrary(widget.targetLibraryId!, gameId);
            success = returnedGameDetails != null; 
            // Call callback ONLY if successful ADD, pass the returned details
            if (success && mounted) {
              widget.onGameAddedCallback?.call(returnedGameDetails!); // Pass details here
            }
         }
       } else {
         throw Exception("Unsupported library type: ${widget.targetLibraryType}");
       }
       // --- End API Calls --- 

      if (!success && mounted) {
        _revertOptimisticUpdate(gameId, isCurrentlyInLibrary); // Revert is now outside setState
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ${widget.libraryName}.')),
        );
      } else if (success && mounted) {
        print('API Call successful for game $gameId in ${widget.libraryName}');
        if (!isCurrentlyInLibrary) { 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${game.name} to ${widget.libraryName}'),
              duration: Duration(seconds: 2),
           ),
         );
        }
        if (widget.targetLibraryType == LibraryType.CURRENTLY_PLAYING) {
          if (isCurrentlyInLibrary) { // If we successfully removed it
            _homeController.removeGameFromCurrentlyPlaying(gameId);
            // Also update initial state if needed for subsequent checks in this session
            _initialGameIds.remove(gameId); 
          } else if (returnedGameDetails != null) { // Use returnedGameDetails
            final gameSummary = GameSummary.fromGameDetailWithUserInfo(returnedGameDetails);
            _homeController.addGameToCurrentlyPlaying(gameSummary);
            _homeController.processUserGameInfo(returnedGameDetails);
             // Also update initial state if needed
            _initialGameIds.add(gameId); 
          }
        }
      }
    } catch (e) {
      print('Error toggling game in library: $e');
      if (mounted) {
        _revertOptimisticUpdate(gameId, isCurrentlyInLibrary); // Revert is now outside setState
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ${widget.libraryName}: ${e.toString()}')),
        );
      }
    } finally {
       // Reset processing state regardless of outcome
       if (mounted) {
          setState(() {
             _processingGameId = null;
          });
       }
    }
  }

  // Revert logic needs to be outside setState now
  void _revertOptimisticUpdate(int gameId, bool wasInLibraryBeforeToggle) {
     // Directly manipulate the set, UI update will happen in finally block's setState
     if (wasInLibraryBeforeToggle) { 
        _gamesToggledInSession.add(gameId);
     } else {
        _gamesToggledInSession.remove(gameId);
     }
     // No setState here needed anymore
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search games to add...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        Divider(color: Colors.grey[800], height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            "Add games to ${widget.libraryName}", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
          ),
        ),
        Expanded(
          child: _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    // Handle loading state for the initial search explicitly if needed
    if (_isLoading && _searchResults.isEmpty && _lastQuery.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorMessage!, style: TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
       return Center(
        child: Text('Start typing to search for games.', style: TextStyle(color: Colors.grey[500])), 
      );
    }
    
    // Don't show "No games found" if currently loading more
    if (_searchResults.isEmpty && !_isLoading && _lastQuery.isNotEmpty) {
      return Center(
        child: Text('No games found for "$_lastQuery".', style: TextStyle(color: Colors.grey[500])), 
      );
    }

    // Return a Column containing the ListView and the loading indicator
    return Column(
      children: [
        Expanded( // Make ListView fill available space
          child: ListView.builder(
            key: _listKey, 
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            // itemCount is now just the number of results
            itemCount: _searchResults.length, 
            itemBuilder: (context, index) {
              // No need to check index >= length anymore
              
              final game = _searchResults[index];
              final bool isAdded = game.id != null ? _gamesToggledInSession.contains(game.id) : false; 
              final bool isProcessingThisGame = _processingGameId == game.id;

              // Determine visual limit for this item
              bool showVisualLimit = false;
              if (!isAdded && !isProcessingThisGame && widget.targetLibraryType == LibraryType.CURRENTLY_PLAYING && widget.limit != null) {
                 int initialCount = _initialGameIds.length;
                 int addedCount = _gamesToggledInSession.difference(_initialGameIds).length;
                 int removedCount = _initialGameIds.difference(_gamesToggledInSession).length;
                 int potentialCount = initialCount + addedCount - removedCount + 1; 
                 showVisualLimit = potentialCount > widget.limit!;
              }

              // Return the _GameListItem
              return _GameListItem(
                 key: ValueKey(game.id ?? index), 
                 game: game,
                 isAdded: isAdded,
                 isProcessing: isProcessingThisGame,
                 showLimitReached: showVisualLimit, 
                 onToggle: () => _toggleGameInLibrary(game),
              );
            },
          ),
        ),
        
        // Conditionally display the loading indicator *below* the list
        if (_isLoading && _hasMore) 
          const Padding(
             padding: EdgeInsets.symmetric(vertical: 16.0),
             child: SizedBox(
                height: 24, // Give it a fixed height
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
             ),
           ),
      ],
    );
  }
} 