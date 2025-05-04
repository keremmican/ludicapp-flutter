import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ludicapp/core/utils/date_formatter.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MainPageGame extends StatefulWidget {
  final GameSummary game;
  final VoidCallback onTap;
  final ImageProvider? initialCoverProvider;

  const MainPageGame({
    super.key,
    required this.game,
    required this.onTap,
    this.initialCoverProvider,
  });

  @override
  State<MainPageGame> createState() => _MainPageGameState();
}

class _MainPageGameState extends State<MainPageGame> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          height: (MediaQuery.of(context).size.width - 32) * (1942 / 1559),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: CupertinoTheme.of(context).brightness == Brightness.dark
                   ? CupertinoColors.darkBackgroundGray
                   : CupertinoColors.systemGrey6,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Game Image with Hero animation
              Hero(
                tag: 'main_game_cover_${widget.game.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.initialCoverProvider != null
                    ? Image(
                        image: widget.initialCoverProvider!,
                        fit: BoxFit.cover,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            child: child,
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCachedImageFallback();
                        },
                      )
                    : _buildCachedImageFallback(),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CupertinoColors.black.withOpacity(0.0),
                      CupertinoColors.black.withOpacity(0.4),
                      CupertinoColors.black.withOpacity(0.7),
                      CupertinoColors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),

              // Game Details
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.game.name,
                        style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              CupertinoIcons.calendar,
                              color: CupertinoColors.lightBackgroundGray,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatDate(widget.game.releaseDate),
                            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCachedImageFallback() {
    final bool isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    return CachedNetworkImage(
      imageUrl: widget.game.coverUrl ?? '',
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Container(
        color: isDarkMode ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemGrey6,
        child: const Center(child: CupertinoActivityIndicator(radius: 12)),
      ),
      errorWidget: (context, url, error) => Container(
        color: isDarkMode ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemGrey6,
        child: Center(
          child: Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: CupertinoColors.secondaryLabel,
            size: 40,
          ),
        ),
      ),
    );
  }
}
