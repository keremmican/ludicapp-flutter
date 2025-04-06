import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'library_detail_page.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/core/enums/library_type.dart';

class AllLibrariesPage extends StatefulWidget {
  final String username;
  final String? userId;
  final bool fetchFollowedLibraries;

  const AllLibrariesPage({
    Key? key,
    required this.username,
    this.userId,
    this.fetchFollowedLibraries = false,
  }) : super(key: key);

  @override
  State<AllLibrariesPage> createState() => _AllLibrariesPageState();
}

class _AllLibrariesPageState extends State<AllLibrariesPage> {
  final LibraryRepository _libraryRepository = LibraryRepository();
  final TokenService _tokenService = TokenService();
  List<LibrarySummaryResponse>? _libraries;
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentUserId = await _tokenService.getUserId();
    _loadLibraries(initialLoad: true);
  }

  Future<void> _loadLibraries({bool initialLoad = true}) async {
    if (initialLoad) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      if (_error != null) {
        setState(() { _error = null; });
      }
      print('Refreshing libraries in background...');
    }

    try {
      final targetUserIdString = widget.userId ?? _currentUserId?.toString();
      if (targetUserIdString == null) {
        throw Exception("Target User ID could not be determined.");
      }
      final targetUserId = int.parse(targetUserIdString);

      List<LibrarySummaryResponse>? summaries;
      if (widget.fetchFollowedLibraries) {
        print('Fetching followed libraries for user $targetUserId');
        final response = await _libraryRepository.getFollowedLibrariesByUser(
          targetUserId,
        );
        summaries = response?.content;
      } else {
        print('Fetching owned libraries for user $targetUserId');
        summaries = await _libraryRepository.getAllLibrarySummaries(
          userId: targetUserIdString,
        );
      }
      
      if (mounted) {
        setState(() {
          _libraries = summaries ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading libraries: $e');
      if (mounted) {
        if (initialLoad) {
          _error = 'Failed to load libraries. Please try again.';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to refresh libraries.')),
          );
        }
        _isLoading = false;
      }
    }
  }

  bool get _isViewingCurrentUser => widget.userId == null || widget.userId == _currentUserId?.toString();

  @override
  Widget build(BuildContext context) {
    final String pageTitle;
    if (widget.fetchFollowedLibraries) {
      pageTitle = _isViewingCurrentUser ? 'Libraries You Follow' : '${widget.username}\'s Followed Libraries';
    } else {
      pageTitle = _isViewingCurrentUser ? 'My Libraries' : '${widget.username}\'s Libraries';
    }
    
    final bool showCreateButton = _isViewingCurrentUser && !widget.fetchFollowedLibraries;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context, 'updated'),
        ),
        actions: [
          if (showCreateButton)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Create New Library',
              onPressed: _showCreateLibraryDialog,
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_libraries == null || _libraries!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.fetchFollowedLibraries ? Icons.rss_feed_rounded : Icons.list_alt_rounded,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              widget.fetchFollowedLibraries ? 'Not following any libraries yet' : 'No libraries found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Create a mutable copy for sorting
    List<LibrarySummaryResponse> sortedLibraries = List.from(_libraries!);

    // Safely parse and sort libraries by updatedAt in descending order (most recent first)
    sortedLibraries.sort((a, b) {
      DateTime? dateA = a.updatedAt != null ? DateTime.tryParse(a.updatedAt.toString()) : null;
      DateTime? dateB = b.updatedAt != null ? DateTime.tryParse(b.updatedAt.toString()) : null;

      // Handle null or invalid dates (put them at the end)
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // a comes after b
      if (dateB == null) return -1; // a comes before b

      // Compare valid dates (descending)
      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedLibraries.length, // Use sorted list length
      itemBuilder: (context, index) {
        final library = sortedLibraries[index]; // Use sorted list item
        return _buildLibraryListItem(library);
      },
    );
  }

  Widget _buildLibraryListItem(LibrarySummaryResponse library) {
    final bool _isViewingCurrentUser = widget.userId == null || widget.userId == _currentUserId?.toString();
    final bool canFollowThisLibrary = !_isViewingCurrentUser && library.libraryType == LibraryType.CUSTOM && !widget.fetchFollowedLibraries;
    // Determine ownership based on context
    final bool isOwned = _isViewingCurrentUser && !widget.fetchFollowedLibraries;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryDetailPage(
               librarySummary: library,
               userId: widget.userId, 
               isFollowable: canFollowThisLibrary, 
            ),
          ),
        );

        if (result == 'deleted' && !widget.fetchFollowedLibraries) {
          setState(() {
            _libraries?.removeWhere((lib) => lib.id == library.id);
          });
        } else if (result == 'updated') {
          print('Returned from LibraryDetailPage with update signal, refreshing libraries...');
          _loadLibraries(initialLoad: false);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Library Cover/Icon
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: library.coverUrl != null && library.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: library.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[800]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              _getLibraryIcon(library.displayName),
                              color: Colors.white.withOpacity(0.9),
                              size: 30,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getLibraryGradient(library.displayName),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getLibraryIcon(library.displayName),
                            color: Colors.white.withOpacity(0.9),
                            size: 30,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Library Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    library.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${library.gameCount} Games',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron Icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to get icon and gradient based on library name
  IconData _getLibraryIcon(String title) {
    switch (title) {
      case 'Saved':
        return Icons.bookmark;
      case 'Hidden':
        return Icons.visibility_off;
      case 'Rated':
        return Icons.star;
      case 'Currently Playing':
        return Icons.sports_esports;
      default:
        return Icons.list_alt; // Default icon
    }
  }

  List<Color> _getLibraryGradient(String title) {
    switch (title) {
      case 'Saved':
        return [const Color(0xFF6A3093), const Color(0xFFA044FF)];
      case 'Hidden':
        return [const Color(0xFF434343), const Color(0xFF000000)];
      case 'Rated':
        return [const Color(0xFFFF512F), const Color(0xFFDD2476)];
      case 'Currently Playing':
        return [const Color(0xFF1A2980), const Color(0xFF26D0CE)];
      default:
        return [const Color(0xFF4B79A1), const Color(0xFF283E51)]; // Default gradient
    }
  }

  // Method to show the create library dialog
  Future<void> _showCreateLibraryDialog() async {
    final titleController = TextEditingController();
    final newLibraryTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Create New Library', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter library title',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final enteredTitle = titleController.text.trim();
              if (enteredTitle.isNotEmpty) {
                Navigator.pop(context, enteredTitle); // Return new title
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (newLibraryTitle != null) {
      setState(() { _isLoading = true; });
      final createdLibraryDto = await _libraryRepository.createCustomLibrary(newLibraryTitle);
      setState(() { _isLoading = false; });

      if (createdLibraryDto != null && mounted) {
        // Check if we have the current user ID before creating the summary
        if (_currentUserId == null) {
          print("Error: Current user ID is null, cannot assign owner to new library.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error creating library: User ID not found.')),
          );
          return;
        }

        final LibraryType newLibraryType = LibraryType.fromString(createdLibraryDto.type);
        
        final newLibrarySummary = LibrarySummaryResponse(
          id: createdLibraryDto.id,
          // Assign the current user ID as the owner
          ownerUserId: _currentUserId,
          libraryName: createdLibraryDto.title, 
          libraryType: newLibraryType,
          gameCount: 0,
          coverUrl: null, 
          isPrivate: false,
          // isCurrentUserFollowing will be null for a newly created library
        );

        setState(() {
          _libraries?.insert(0, newLibrarySummary);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Library "$newLibraryTitle" created!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create library. Please try again.')),
        );
      }
    }
  }
} 