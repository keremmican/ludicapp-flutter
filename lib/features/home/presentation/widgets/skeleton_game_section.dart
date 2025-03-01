import 'package:flutter/material.dart';

class SkeletonGameSection extends StatefulWidget {
  final String title;
  final ScrollController? scrollController;

  const SkeletonGameSection({
    Key? key,
    required this.title,
    this.scrollController,
  }) : super(key: key);

  @override
  State<SkeletonGameSection> createState() => _SkeletonGameSectionState();
}

class _SkeletonGameSectionState extends State<SkeletonGameSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
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
    _controller.dispose();
    // Sadece içeride oluşturduğumuz controller'ı dispose et
    if (_isInternalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(SkeletonGameSection oldWidget) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final delay = (index * 0.2) % 1.0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildSkeletonItem(delay),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonItem([double delay = 0.0]) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animValue = (_animation.value + delay) % 1.0;
        
        return Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[900]!,
                        Colors.grey[700]!.withOpacity(animValue),
                        Colors.grey[800]!,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: animValue,
                          duration: const Duration(milliseconds: 500),
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: const Alignment(-1.0, -0.5),
                                end: const Alignment(1.0, 0.5),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.srcATop,
                            child: Container(
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[700]!.withOpacity(animValue),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[700]!.withOpacity(animValue * 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
} 