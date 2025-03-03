import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ludicapp/core/widgets/game_section.dart';
import 'package:ludicapp/core/widgets/large_game_section.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'package:ludicapp/features/home/presentation/widgets/main_page_game.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/home/presentation/widgets/continue_playing_section.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/name_id_response.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/features/home/presentation/widgets/skeleton_game_section.dart';
import 'package:ludicapp/features/home/presentation/widgets/skeleton_large_game_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final _controller = HomeController();
  late ScrollController _scrollController;
  
  // Yükleme durumları
  bool _isLoadingInitialData = true;
  final Map<int, bool> _isLoadingSectionMap = {};
  final Map<int, bool> _isSectionLoadedMap = {};
  
  // Görünürlük izleme
  final Map<int, GlobalKey> _sectionKeys = {};
  bool _isScrolling = false;
  
  // Popülerlik tipleri
  final List<int> _allPopularityTypes = [1, 4, 3, 10, 5, 6, 8, 2, 9];
  
  // ScrollController'ları saklamak için map
  final Map<int, ScrollController> _scrollControllers = {};
  
  // Sayfa pozisyonunu kaydetmek için
  double _savedScrollPosition = 0;
  
  // Sayfa durumunu saklamak için key
  static const _pageStorageKey = PageStorageKey<String>('home_page_state');
  
  // Scroll pozisyonunu ayarlamak için flag
  bool _isFirstBuild = true;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Tüm popülerlik tipleri için key ve ScrollController oluştur
    for (final type in _allPopularityTypes) {
      _sectionKeys[type] = GlobalKey();
      _isLoadingSectionMap[type] = false;
      _isSectionLoadedMap[type] = false;
      _scrollControllers[type] = ScrollController(initialScrollOffset: 0);
    }
    
    // PageStorage'dan kaydedilen durumu geri yükle
    // Bu işlem senkron olarak yapılmalı, böylece loading göstermeden doğrudan içeriği gösterebiliriz
    _restoreState();
    
    // ScrollController'ı oluştur
    // Eğer kaydedilen bir scroll pozisyonu varsa, initialScrollOffset olarak kullan
    _scrollController = ScrollController(initialScrollOffset: _savedScrollPosition);
    _scrollController.addListener(_onScroll);
    
    // İlk verileri yükle
    _loadInitialData();
  }

  void _restoreState() {
    // PageStorage'dan kaydedilen scroll pozisyonunu geri yükle
    final savedPosition = PageStorage.of(context)?.readState(context, identifier: 'scroll_position');
    if (savedPosition != null && savedPosition is double) {
      _savedScrollPosition = savedPosition;
    }
    
    // PageStorage'dan kaydedilen yüklenen bölümleri geri yükle
    final loadedSections = PageStorage.of(context)?.readState(context, identifier: 'loaded_sections');
    if (loadedSections != null && loadedSections is Map<dynamic, dynamic>) {
      for (final entry in loadedSections.entries) {
        if (entry.key is int && entry.value is bool) {
          _isSectionLoadedMap[entry.key as int] = entry.value as bool;
        }
      }
      
      // Eğer daha önce yüklenen bölümler varsa, loading durumunu false yap
      if (_isSectionLoadedMap.isNotEmpty) {
        _isLoadingInitialData = false;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    
    // Scroll pozisyonunu kaydet
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.position.pixels;
      
      // PageStorage'a scroll pozisyonunu kaydet
      PageStorage.of(context)?.writeState(context, _savedScrollPosition, identifier: 'scroll_position');
      
      // PageStorage'a yüklenen bölümleri kaydet
      PageStorage.of(context)?.writeState(context, Map<int, bool>.from(_isSectionLoadedMap), identifier: 'loaded_sections');
    }
    
    _scrollController.dispose();
    
    // Tüm ScrollController'ları dispose et
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _onScroll() {
    if (_isScrolling) return;
    
    _isScrolling = true;
    
    // Scroll işlemi sırasında görünür bölümleri kontrol et
    // Daha kısa bir gecikme ile daha hızlı tepki ver
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _checkVisibleSections();
        _isScrolling = false;
      }
    });
  }
  
  void _checkVisibleSections() {
    if (!mounted) return;
    
    // Ekranda görünür olan bölümleri kontrol et
    for (final entry in _sectionKeys.entries) {
      final sectionId = entry.key;
      final sectionKey = entry.value;
      
      // Eğer bu bölüm zaten yüklendiyse veya yükleniyorsa, atla
      if ((_isSectionLoadedMap[sectionId] ?? false) == true || 
          (_isLoadingSectionMap[sectionId] ?? false) == true) {
        continue;
      }
      
      // Bölümün görünürlüğünü kontrol et
      if (_isSectionVisible(sectionKey)) {
        // Kullanıcının skeleton görünümünü görmesi için kısa bir gecikme ekle
        // Bu, kullanıcının skeleton'u görmesini sağlar ve sonra veri yüklenir
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            // Tekrar kontrol et, çünkü gecikme sırasında durum değişmiş olabilir
            if ((_isLoadingSectionMap[sectionId] ?? false) == false && 
                (_isSectionLoadedMap[sectionId] ?? false) == false) {
              _loadSectionData(sectionId);
              
              // PageStorage'a yüklenen bölümleri kaydet
              WidgetsBinding.instance.addPostFrameCallback((_) {
                PageStorage.of(context)?.writeState(context, Map<int, bool>.from(_isSectionLoadedMap), identifier: 'loaded_sections');
              });
            }
          }
        });
        
        // Bir seferde sadece bir bölüm yükle ve çık
        // Bu, performansı artıracak ve UI'ın daha akıcı olmasını sağlayacak
        break;
      }
    }
  }
  
  bool _isSectionVisible(GlobalKey key) {
    if (key.currentContext == null) return false;
    
    final RenderObject? renderObject = key.currentContext!.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;
    
    try {
      // Daha hassas bir görünürlük kontrolü
      final RenderBox box = renderObject as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      
      // Ekran boyutlarını al
      final screenHeight = MediaQuery.of(context).size.height;
      final boxHeight = box.size.height;
      
      // Sadece ekranda görünen veya ekranın hemen altında olan öğeleri kontrol et
      // Ekranın %20'si kadar aşağıya bakarak önceden yüklemeye başla
      // Bu değer, kullanıcının kaydırma hızına göre ayarlanabilir
      return position.dy < screenHeight + (screenHeight * 0.2);
    } catch (e) {
      // Herhangi bir hata durumunda false döndür
      return false;
    }
  }

  Future<void> _loadInitialData() async {
    // Eğer veriler zaten yüklenmişse, tekrar yükleme
    if (!_isLoadingInitialData) {
      // Sadece görünür bölümleri kontrol et
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Daha önce yüklenmemiş görünür bölümleri kontrol et
        _checkVisibleSections();
      });
      return;
    }
    
    try {
      // Daha önce yüklenen bölümler varsa, loading göstermeden doğrudan içeriği göster
      if (_isSectionLoadedMap.isNotEmpty) {
        setState(() {
          _isLoadingInitialData = false;
        });
        
        // Daha önce yüklenmemiş görünür bölümleri kontrol et
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkVisibleSections();
        });
        return;
      }
      
      // İlk kez yükleme yapılıyorsa, verileri yükle
      await _controller.loadData();
      
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false;
        });
        
        // İlk görünür bölümleri kontrol et
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Daha önce yüklenmemiş görünür bölümleri kontrol et
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _checkVisibleSections();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false;
        });
      }
    }
  }

  Future<void> _loadSectionData(int sectionId) async {
    // Eğer bu bölüm zaten yükleniyorsa veya yüklendiyse, işlem yapma
    if ((_isLoadingSectionMap[sectionId] ?? false) == true || 
        (_isSectionLoadedMap[sectionId] ?? false) == true) {
      return;
    }
    
    // Yükleme durumunu güncelle
    setState(() {
      _isLoadingSectionMap[sectionId] = true;
    });
    
    try {
      // Bölüm için veri yükle
      await _controller.loadSpecificSection([sectionId]);
      
      if (mounted) {
        setState(() {
          _isLoadingSectionMap[sectionId] = false;
          _isSectionLoadedMap[sectionId] = true;
        });
        
        // PageStorage'a yüklenen bölümleri kaydet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          PageStorage.of(context)?.writeState(context, Map<int, bool>.from(_isSectionLoadedMap), identifier: 'loaded_sections');
          
          // Bölüm yüklendikten sonra ScrollController'ı sıfırla
          final controller = _scrollControllers[sectionId];
          if (controller != null && controller.hasClients) {
            controller.jumpTo(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSectionMap[sectionId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Eğer ilk yükleme yapılıyorsa ve daha önce yüklenen veriler yoksa loading göster
    if (_isLoadingInitialData && _isSectionLoadedMap.isEmpty) {
      return _buildLoadingScreen();
    }
    
    return PageStorage(
      bucket: PageStorageBucket(),
      key: _pageStorageKey,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // Scroll sona erdiğinde veya kullanıcı scroll yaparken belirli aralıklarla kontrol et
          if (notification is ScrollEndNotification || 
              (notification is ScrollUpdateNotification && notification.metrics.pixels % 100 == 0)) {
            _checkVisibleSections();
            
            // Scroll pozisyonunu güncelle ve kaydet
            if (_scrollController.hasClients) {
              _savedScrollPosition = _scrollController.position.pixels;
              
              // PageStorage'a scroll pozisyonunu kaydet
              PageStorage.of(context)?.writeState(context, _savedScrollPosition, identifier: 'scroll_position');
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          key: const PageStorageKey<String>('home_page_scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Showcase Game
              if (_controller.popularGameByVisits != null)
                _buildShowcaseGame(context, _controller.popularGameByVisits!),

              // New Releases Section
              if (_controller.newReleases.isNotEmpty)
                GameSection(
                  title: 'New Releases',
                  games: _controller.newReleases.map((game) => _controller.getGameWithUserActions(game)).toList(),
                  onGameTap: (game) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameDetailPage(game: game),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Continue Playing Section
              ContinuePlayingSection(
                onAddGamesPressed: () {
                  // TODO: Implement add games functionality
                },
              ),

              const SizedBox(height: 16),

              // Top Rated Section
              if (_controller.topRatedGames.isNotEmpty)
                GameSection(
                  title: 'Top Rated',
                  games: _controller.topRatedGames.map((game) {
                    final gameWithActions = _controller.getGameWithUserActions(game);
                    return gameWithActions;
                  }).toList(),
                  onGameTap: (game) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameDetailPage(game: game),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Coming Soon Section
              if (_controller.comingSoonGames.isNotEmpty)
                GameSection(
                  title: 'Coming Soon',
                  games: _controller.comingSoonGames.map((game) => _controller.getGameWithUserActions(game)).toList(),
                  onGameTap: (game) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameDetailPage(game: game),
                      ),
                    );
                  },
                ),

              // Additional popularity type sections
              ..._buildAllPopularitySections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildShowcaseGame(BuildContext context, GameSummary gameSummary) {
    final game = _controller.getGameWithUserActions(gameSummary);
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: MainPageGame(
        key: ValueKey('main_game_${gameSummary.id}'),
        game: gameSummary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailPage(
                game: game,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAllPopularitySections() {
    final List<Widget> sections = [];
    
    // Tüm popülerlik tipleri için bölüm oluştur
    for (final typeId in _allPopularityTypes) {
      sections.add(const SizedBox(height: 16));
      
      // Bölüm yüklendiyse gerçek verileri göster, yoksa iskelet görünümü göster
      if ((_isSectionLoadedMap[typeId] ?? false) == true) {
        final games = _controller.getGamesForPopularityType(typeId);
        if (games.isNotEmpty) {
          final typeObj = _controller.popularityTypes.firstWhere(
            (type) => type.id == typeId,
            orElse: () => NameIdResponse(id: typeId, name: _controller.getPopularityTypeTitle(typeId)),
          );
          sections.add(_buildPopularityTypeSection(typeObj, games));
        }
      } else {
        // İskelet görünümü göster
        sections.add(_buildSkeletonSection(typeId));
      }
    }
    
    return sections;
  }

  Widget _buildSkeletonSection(int typeId) {
    // Popülerlik tipine göre büyük veya küçük kart gösterme
    final isLargeSection = typeId == 1 || typeId == 10 || 
                          typeId == 6 || typeId == 9;
    
    final title = _controller.getPopularityTypeTitle(typeId);
    
    // ScrollController'ı al veya oluştur
    final scrollController = _scrollControllers[typeId] ?? 
        (_scrollControllers[typeId] = ScrollController(initialScrollOffset: 0));
    
    // ScrollController'ı sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    });
    
    // Skeleton görünümünü daha belirgin yapmak için Container'ı düzenle
    return Container(
      key: _sectionKeys[typeId],
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isLargeSection ? 12 : 8),
        child: isLargeSection
            ? SkeletonLargeGameSection(
                key: ValueKey('skeleton_large_${typeId}'),
                title: title,
                scrollController: scrollController,
              )
            : SkeletonGameSection(
                key: ValueKey('skeleton_${typeId}'),
                title: title,
                scrollController: scrollController,
              ),
      ),
    );
  }

  Widget _buildPopularityTypeSection(NameIdResponse popularityType, List<GameSummary> games) {
    if (games.isEmpty) return const SizedBox.shrink();

    // Popülerlik tipine göre büyük veya küçük kart gösterme
    final isLargeSection = popularityType.id == 1 || popularityType.id == 10 || 
                          popularityType.id == 6 || popularityType.id == 9;
    
    // ScrollController'ı al veya oluştur
    final scrollController = _scrollControllers[popularityType.id] ?? 
        (_scrollControllers[popularityType.id] = ScrollController(initialScrollOffset: 0));
    
    // ScrollController'ı sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    });

    // AnimatedSwitcher yerine doğrudan widget döndür
    return Container(
      key: _sectionKeys[popularityType.id],
      child: isLargeSection
        ? LargeGameSection(
            key: ValueKey('large_section_${popularityType.id}'),
            title: _controller.getPopularityTypeTitle(popularityType.id),
            games: games.map((game) => _controller.getGameWithUserActions(game)).toList(),
            onGameTap: (game) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailPage(game: game),
                ),
              );
            },
            scrollController: scrollController,
          )
        : GameSection(
            key: ValueKey('game_section_${popularityType.id}'),
            title: _controller.getPopularityTypeTitle(popularityType.id),
            games: games.map((game) => _controller.getGameWithUserActions(game)).toList(),
            onGameTap: (game) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailPage(game: game),
                ),
              );
            },
            scrollController: scrollController,
          ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Daha fazla yükleniyor...',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
