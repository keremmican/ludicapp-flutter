import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/providers/blurred_background_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LargeGameCard extends ConsumerWidget {
  final Game game;
  final VoidCallback onTap;
  final double scale;

  const LargeGameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.scale = 1.5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Arka planı ön belleğe al
    if (game.screenshots != null && game.screenshots!.isNotEmpty) {
      // BlurredBackgroundProvider doğrudan sınıf olarak kullan
      final backgroundProvider = BlurredBackgroundProvider();
      backgroundProvider.cacheBackground(
        game.gameId.toString(),
        game.screenshots![0],
      );
      
      // Önceden ön belleğe al (çıktıyı bekleme)
      try {
        precacheImage(CachedNetworkImageProvider(game.screenshots![0]), context)
          .catchError((e) => print('Error pre-caching screenshot: $e'));
      } catch (e) {
        print('Error initiating screenshot pre-cache: $e');
      }
    }
    
    // Kapak görselini de önceden ön belleğe al
    if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
      try {
        precacheImage(CachedNetworkImageProvider(game.coverUrl!), context)
          .catchError((e) => print('Error pre-caching cover: $e'));
      } catch (e) {
        print('Error initiating cover pre-cache: $e');
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width: 135 * scale,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).brightness == Brightness.dark 
                     ? CupertinoColors.darkBackgroundGray 
                     : CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              image: game.coverUrl != null && game.coverUrl!.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(game.coverUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        CupertinoColors.black.withOpacity(0.2),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CupertinoColors.black.withOpacity(0.0),
                      CupertinoColors.black.withOpacity(0.6),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (game.totalRating != null)
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.star_fill,
                                  color: CupertinoColors.systemYellow,
                                  size: 16 * scale,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  game.totalRating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 