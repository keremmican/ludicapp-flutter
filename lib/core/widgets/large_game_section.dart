import 'package:flutter/material.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/widgets/large_game_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LargeGameSection extends StatefulWidget {
  final String title;
  final List<Game> games;
  final Function(Game, ImageProvider?) onGameTap;
  final ScrollController? scrollController;

  const LargeGameSection({
    Key? key,
    required this.title,
    required this.games,
    required this.onGameTap,
    this.scrollController,
  }) : super(key: key);

  @override
  State<LargeGameSection> createState() => _LargeGameSectionState();
}

class _LargeGameSectionState extends State<LargeGameSection> {
  late ScrollController _scrollController;
  bool _isInternalController = false;
  // Ön belleğe alınmış görüntüleri izleme
  final Map<int, bool> _preCachedGames = {};

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
      
      // Görünür öğeleri ön belleğe alma
      _startPreCaching();
    });
  }
  
  // Görünür oyunları önceden ön belleğe al
  void _startPreCaching() {
    if (!mounted) return;
    
    // İlk 5 oyunu (veya daha azını) önceden ön belleğe al
    final itemsToCache = widget.games.length > 5 ? 5 : widget.games.length;
    
    for (int i = 0; i < itemsToCache; i++) {
      final game = widget.games[i];
      if (game.gameId != null && _preCachedGames[game.gameId] != true) {
        _preCachedGames[game.gameId!] = true;
        
        // Kapak görselini ön belleğe al
        if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
          try {
            final coverProvider = CachedNetworkImageProvider(game.coverUrl!);
            precacheImage(coverProvider, context)
              .catchError((e) => print('Error pre-caching cover in advance: $e'));
          } catch (e) {
            print('Error initiating pre-cache for cover: $e');
          }
        }
        
        // İlk ekran görüntüsünü ön belleğe al
        if (game.screenshots != null && game.screenshots!.isNotEmpty) {
          try {
            precacheImage(CachedNetworkImageProvider(game.screenshots![0]), context)
              .catchError((e) => print('Error pre-caching screenshot in advance: $e'));
          } catch (e) {
            print('Error initiating pre-cache for screenshot: $e');
          }
        }
      }
    }
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
  void didUpdateWidget(LargeGameSection oldWidget) {
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
        // Görünür öğeleri ön belleğe alma
        _startPreCaching();
      });
    }
    
    // Oyun listesi değiştiyse, ön belleğe alınmış öğeleri temizle ve yenilerini ön belleğe al
    if (widget.games != oldWidget.games) {
      _preCachedGames.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPreCaching();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 270,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: widget.games.length,
            itemBuilder: (context, index) {
              final game = widget.games[index];
              return LargeGameCard(
                game: game,
                onTap: () {
                  ImageProvider? coverProvider;
                  
                  // Yüksek öncelikli ön belleğe alma - iki kere ön belleğe alıyoruz
                  // ama bu tıklama anında gerçekleşecek ve kullanıcı görsel yüklenmesini beklemeyecek
                  
                  // 1. Kapak görselini ön belleğe al
                  if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
                    // CachedNetworkImageProvider kullan - bu Flutter'ın önbellek sisteminden faydalanır
                    coverProvider = CachedNetworkImageProvider(game.coverUrl!);
                    try {
                      // Yüksek öncelikli ön belleğe alma (yükleme sırasını değiştirmez)
                      precacheImage(coverProvider, context, onError: (e, stackTrace) {
                        print('Error pre-caching cover during tap: $e');
                      });
                    } catch (e) {
                      print('Sync error initiating cover pre-cache during tap: $e');
                    }
                  }
                  
                  // 2. İlk ekran görüntüsünü ön belleğe al
                  if (game.screenshots != null && game.screenshots!.isNotEmpty) {
                    try {
                      // Yüksek öncelikli ön belleğe alma
                      precacheImage(CachedNetworkImageProvider(game.screenshots![0]), context, onError: (e, stackTrace) {
                        print('Error pre-caching screenshot during tap: $e');
                      });
                    } catch (e) {
                      print('Sync error initiating screenshot pre-cache during tap: $e');
                    }
                  }
                  
                  // 3. Hemen yönlendirme yap - ön belleğe alma işlemi arka planda devam eder
                  widget.onGameTap(game, coverProvider);
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 