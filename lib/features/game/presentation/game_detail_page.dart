import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/game_detail.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';


class GameDetailPage extends StatefulWidget {
  final int id;

  const GameDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  _GameDetailPageState createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final GameRepository _gameRepository = GameRepository();
  GameDetail? _gameDetail;
  bool _isLoading = true;
  Color? _backgroundColor;

  @override
  void initState() {
    super.initState();
    _fetchGameDetail();
  }
  final PageController _pageController = PageController();
int _currentIndex = 0; // Mevcut index


  Future<void> _fetchGameDetail() async {
    try {
      final gameDetail = await _gameRepository.fetchGameDetails(widget.id);
      setState(() {
        _gameDetail = gameDetail;
        _isLoading = false;
      });
      if (_gameDetail != null && _gameDetail!.screenshots.isNotEmpty) {
        _generateBackgroundColor(_gameDetail!.screenshots[0]);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching game detail: $error");
    }
  }

  Future<void> _generateBackgroundColor(String imageUrl) async {
  final PaletteGenerator paletteGenerator =
      await PaletteGenerator.fromImageProvider(NetworkImage(imageUrl));
  setState(() {
    final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
    _backgroundColor = dominantColor.withOpacity(0.5); // Daha belirgin buzlu görünüm
  });
}

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_gameDetail == null) {
    return const Center(child: Text("Game details not available"));
  }

  return Scaffold(
    body: Stack(
      children: [
        // Arka Plan Görseli
        Positioned.fill(
          child: _gameDetail!.screenshots.isNotEmpty
              ? Image.network(
                  _gameDetail!.screenshots[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                )
              : Container(color: Colors.black),
        ),

        // Buzlu Arka Plan Efekti
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4), // Daha koyu şeffaf katman
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
        ),

        // Ana İçerik
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Üst Kısım: Yalnızca Ekran Görüntüleri
                SizedBox(
  height: 220,
  child: Stack(
    alignment: Alignment.center,
    children: [
      PageView.builder(
        itemCount: _gameDetail!.screenshots.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Image.network(
            _gameDetail!.screenshots[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: 220,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Screenshot not available',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),

      // Sol ok
      if (_currentIndex > 0)
        Positioned(
          left: 10,
          child: GestureDetector(
            onTap: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

      // Sağ ok
      if (_currentIndex < _gameDetail!.screenshots.length - 1)
        Positioned(
          right: 10,
          child: GestureDetector(
            onTap: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
    ],
  ),
),

                // Bilgi Bölümü
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Başlık
                      Text(
                        _gameDetail!.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Tür ve Çıkış Tarihi
                      Text(
                        '${_gameDetail!.genre} • ${_gameDetail!.releaseFullDate}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Trailer Butonu
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 10.0),
                        child: ElevatedButton.icon(
                          onPressed: _gameDetail!.gameVideo != null
                              ? () => _launchUrl(_gameDetail!.gameVideo!)
                              : null,
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text("Watch Trailer"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gameDetail!.gameVideo != null
                                ? Colors.grey[800]
                                : Colors.grey[500]?.withOpacity(0.7),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Özet
Text(
  _truncateText(_gameDetail!.summary, 4),
  textAlign: TextAlign.center,
  style: const TextStyle(
    color: Colors.white, // Daha açık bir beyaz tonu
    fontSize: 14,
  ),
  maxLines: 4, // Maksimum 4 satır
  overflow: TextOverflow.ellipsis, // Ellipsis ekle
),

                      const SizedBox(height: 10),

                      // Şirket Bilgisi
                      Text(
                        'Company: ${_gameDetail!.company ?? 'Unknown'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.grey),

                // Puanlama
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRating(
                          _gameDetail!.totalRatingScore?.toStringAsFixed(1) ??
                              'N/A',
                          'Total Rating'),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  String _truncateText(String text, int maxLines) {
    final lines = text.split('\n');
    if (lines.length <= maxLines) return text;
    return lines.take(maxLines).join(' ') + '...';
  }

  Widget _buildRating(String score, String label) {
    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('Could not launch $url');
    }
  }
}
