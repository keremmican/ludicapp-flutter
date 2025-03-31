import 'package:flutter/material.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/providers/blurred_background_provider.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GameSection extends StatefulWidget {
  final String title;
  final List<Game> games;
  final Function(Game, ImageProvider?) onGameTap;
  final ScrollController? scrollController;

  const GameSection({
    Key? key,
    required this.title,
    required this.games,
    required this.onGameTap,
    this.scrollController,
  }) : super(key: key);

  @override
  State<GameSection> createState() => _GameSectionState();
}

class _GameSectionState extends State<GameSection> {
  late ScrollController _scrollController;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    
    // Dışarıdan controller verilmişse onu kullan, yoksa yeni oluştur
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController(initialScrollOffset: 0);
      _isInternalController = true;
    }
    
    // ScrollController'ı sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    // Sadece içeride oluşturduğumuz controller'ı dispose et
    if (_isInternalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(GameSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Widget güncellendiğinde controller değişmişse güncelle
    if (widget.scrollController != null && widget.scrollController != _scrollController) {
      if (_isInternalController) {
        _scrollController.dispose();
      }
      _scrollController = widget.scrollController!;
      _isInternalController = false;
      
      // ScrollController'ı sıfırla
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontally Scrolling Game Cards
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.33 * (1942/1559),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: widget.games.length,
              itemBuilder: (context, index) {
                final game = widget.games[index];
                
                return GestureDetector(
                  onTap: () {
                    ImageProvider? coverProvider;
                    // Create provider and initiate pre-cache WITHOUT awaiting
                    if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
                      coverProvider = CachedNetworkImageProvider(game.coverUrl!);
                      try {
                        if (mounted) {
                          precacheImage(coverProvider, context)
                             .catchError((e) => print('Error pre-caching cover: $e'));
                          print('Initiated pre-cache for cover: ${game.name}');
                        }
                      } catch (e) {
                        print('Sync error initiating cover pre-cache: $e');
                      }
                    }
                    // Pre-cache first screenshot (fire-and-forget)
                    if (game.screenshots != null && game.screenshots!.isNotEmpty) {
                       try {
                        if (mounted) {
                          precacheImage(CachedNetworkImageProvider(game.screenshots![0]), context)
                             .catchError((e) => print('Error pre-caching screenshot: $e'));
                          print('Initiated pre-cache for screenshot: ${game.name}');
                        }
                      } catch (e) {
                         print('Sync error initiating screenshot pre-cache: $e');
                      }
                    }

                    // Navigate immediately, passing the provider via onGameTap
                    widget.onGameTap(game, coverProvider);
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index != widget.games.length - 1 ? 12.0 : 0,
                    ),
                    width: MediaQuery.of(context).size.width * 0.30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[900]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                        fadeInDuration: const Duration(milliseconds: 100),
                        fadeOutDuration: const Duration(milliseconds: 100),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
