import 'package:flutter/material.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/widgets/large_game_card.dart';

class LargeGameSection extends StatefulWidget {
  final String title;
  final List<Game> games;
  final Function(Game) onGameTap;
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
          height: 270, // Daha küçük bir height değeri
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: widget.games.length,
            itemBuilder: (context, index) {
              return LargeGameCard(
                game: widget.games[index],
                onTap: () => widget.onGameTap(widget.games[index]),
              );
            },
          ),
        ),
      ],
    );
  }
} 