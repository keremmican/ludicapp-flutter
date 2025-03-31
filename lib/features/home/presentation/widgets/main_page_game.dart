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
            borderRadius: BorderRadius.circular(24),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Game Image with Hero animation
              Hero(
                tag: 'main_game_cover_${widget.game.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.5, 0.7, 0.85, 1.0],
                  ),
                ),
              ),

              // Game Details
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.game.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatDate(widget.game.releaseDate),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
    return CachedNetworkImage(
      imageUrl: widget.game.coverUrl ?? '',
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
    );
  }
}
