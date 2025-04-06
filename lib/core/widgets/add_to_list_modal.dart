import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/library_summary_with_game_status_response.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/core/enums/library_type.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';

class AddToListModal extends StatefulWidget {
  final int gameId;
  final String gameName;

  const AddToListModal({
    Key? key,
    required this.gameId,
    required this.gameName,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required int gameId,
    required String gameName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Start at 60% height
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: AddToListModal(
              gameId: gameId,
              gameName: gameName,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<AddToListModal> createState() => _AddToListModalState();
}

class _AddToListModalState extends State<AddToListModal> {
  final LibraryRepository _libraryRepository = LibraryRepository();
  List<LibrarySummaryWithGameStatusResponse> _libraryStatuses = [];
  Map<int, int> _libraryGameCounts = {};
  bool _isLoading = true;
  String? _error;
  Map<int, bool> _isProcessing = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Fetch all statuses first
      final allStatuses = await _libraryRepository.getGamePresenceInCustomLibraries(widget.gameId);
      
      // Filter to keep only CUSTOM libraries
      final customStatuses = allStatuses
          .where((status) => status.libraryType == LibraryType.CUSTOM)
          .toList();
          
      if (mounted) {
        setState(() {
          // Store only the filtered list
          _libraryStatuses = customStatuses; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      print('Error loading library statuses for modal: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load your custom libraries.'; // Update error message slightly
        });
      }
    }
  }

  Future<void> _toggleGameInLibrary(LibrarySummaryWithGameStatusResponse libraryStatus) async {
    final bool currentlyContains = libraryStatus.isGamePresent;
    final int libraryId = libraryStatus.id;
    final int originalIndex = _libraryStatuses.indexWhere((l) => l.id == libraryId);

    if (originalIndex == -1) return; // Library not found, should not happen

    // Optimistic Update: Use copyWith on the new model
    final optimisticList = List<LibrarySummaryWithGameStatusResponse>.from(_libraryStatuses);
    optimisticList[originalIndex] = libraryStatus.copyWith(isGamePresent: !currentlyContains);
    
    // Update the state with the new list
    setState(() { 
      _libraryStatuses = optimisticList;
    });

    bool success = false;
    GameDetailWithUserInfo? addedGameDetails;

    try {
      if (currentlyContains) {
        success = await _libraryRepository.removeGameFromLibrary(libraryId, widget.gameId);
      } else {
        addedGameDetails = await _libraryRepository.addGameToLibrary(libraryId, widget.gameId);
        success = addedGameDetails != null;
      }

      if (success) {
        setState(() {
          _libraryStatuses = _libraryStatuses.map((status) {
            if (status.id == libraryId) {
              return status.copyWith(isGamePresent: !currentlyContains);
            }
            return status;
          }).toList();
          
          if (addedGameDetails != null) {
             print('Game added via AddToListModal, details received.');
          }
        });
        // Maybe show a snackbar notification?
      } else {
        // Handle failure - maybe show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update library status.')),
        );
      }
    } catch (e) {
      // Handle exception - show error message
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
    } finally {
      setState(() {
        _isProcessing[libraryId] = false;
      });
    }
  }

  // --- Helper Methods (copied/adapted from AllLibrariesPage) ---
  IconData _getLibraryIcon(String title) {
    // Since we only show CUSTOM libraries here, maybe simplify?
    // Or keep the logic if title might vary significantly for custom libs.
    // For now, keep the generic logic.
    // Note: SAVED, HIDDEN etc. cases won't be hit here due to filtering.
    switch (title) {
      case 'Saved': return Icons.bookmark;
      case 'Hidden': return Icons.visibility_off;
      case 'Rated': return Icons.star;
      case 'Currently Playing': return Icons.sports_esports;
      default: return Icons.list_alt; // Default for CUSTOM
    }
  }

  List<Color> _getLibraryGradient(String title) {
    // Similarly, simplify or keep generic.
    switch (title) {
      case 'Saved': return [const Color(0xFF6A3093), const Color(0xFFA044FF)];
      case 'Hidden': return [const Color(0xFF434343), const Color(0xFF000000)];
      case 'Rated': return [const Color(0xFFFF512F), const Color(0xFFDD2476)];
      case 'Currently Playing': return [const Color(0xFF1A2980), const Color(0xFF26D0CE)];
      default: return [const Color(0xFF4B79A1), const Color(0xFF283E51)]; // Default gradient
    }
  }
  // --- End Helper Methods ---

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
          child: Text(
            'Add "${widget.gameName}" to...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        Divider(color: Colors.grey[800], height: 1),
        Expanded(
          child: _buildContent(_libraryStatuses),
        ),
      ],
    );
  }

  Widget _buildContent(List<LibrarySummaryWithGameStatusResponse> libraries) {
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
    if (libraries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'You haven\'t created any custom libraries yet. Create one from your profile!',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Sort libraries by updatedAt in descending order (most recent first)
    libraries.sort((a, b) {
      // If updatedAt is null, put it at the end
      if (a.updatedAt == null) return 1;
      if (b.updatedAt == null) return -1;
      return b.updatedAt!.compareTo(a.updatedAt!);
    });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      itemCount: libraries.length,
      itemBuilder: (context, index) {
        final library = libraries[index];
        final bool containsGame = library.isGamePresent;

        return InkWell(
          onTap: () => _toggleGameInLibrary(library),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
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
                                  _getLibraryIcon(library.libraryName),
                                  color: Colors.white.withOpacity(0.7),
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _getLibraryGradient(library.libraryName),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getLibraryIcon(library.libraryName),
                                color: Colors.white.withOpacity(0.9),
                                size: 24,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        library.libraryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${library.gameCount} Games',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  containsGame ? Icons.check_circle : Icons.add_circle_outline,
                  color: containsGame ? Theme.of(context).colorScheme.primary : Colors.grey[500],
                  size: 28,
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
    );
  }
} 