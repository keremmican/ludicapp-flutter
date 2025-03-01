import 'package:flutter/material.dart';
import 'package:ludicapp/core/utils/date_formatter.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';

class MainPageGame extends StatefulWidget {
  final GameSummary game;
  final VoidCallback onTap;

  const MainPageGame({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  State<MainPageGame> createState() => _MainPageGameState();
}

class _MainPageGameState extends State<MainPageGame> with AutomaticKeepAliveClientMixin {
  bool _isImageLoaded = false;
  late final NetworkImage _imageProvider;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.game.coverUrl?.isNotEmpty ?? false) {
      _imageProvider = NetworkImage(widget.game.coverUrl!);
      _loadImage();
    }
  }

  void _loadImage() {
    if (widget.game.coverUrl?.isEmpty ?? true) return;
    
    // Doğrudan ImageProvider'ı kullanarak resmi yükle
    final image = _imageProvider.resolve(const ImageConfiguration());
    
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted && !_isImageLoaded) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
          });
        }
      },
    );
    
    image.addListener(listener);
  }

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
                tag: 'game-${widget.game.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: _buildGameImage(),
                  ),
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

  Widget _buildGameImage() {
    if (widget.game.coverUrl?.isEmpty ?? true) {
      return _buildErrorWidget();
    }
    
    if (_hasError) {
      return _buildErrorWidget();
    }
    
    if (_isImageLoaded) {
      return Image(
        image: _imageProvider,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
    
    return _buildLoadingWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
