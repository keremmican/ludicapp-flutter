import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ludicapp/core/enums/completion_status.dart';
import 'package:ludicapp/core/enums/play_status.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:ludicapp/services/repository/rating_repository.dart';
import 'package:ludicapp/services/model/request/user_game_rating_update_request.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class RatingModal extends StatefulWidget {
  final String gameName;
  final String coverUrl;
  final int gameId;
  final UserGameRating? initialUserGameRating;
  final Function(UserGameRating updatedRating) onUpdateComplete;

  const RatingModal({
    Key? key,
    required this.gameName,
    required this.coverUrl,
    required this.gameId,
    required this.onUpdateComplete,
    this.initialUserGameRating,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String gameName,
    required String coverUrl,
    required int gameId,
    required Function(UserGameRating updatedRating) onUpdateComplete,
    UserGameRating? initialUserGameRating,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85, 
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => RatingModal(
              gameName: gameName,
              coverUrl: coverUrl,
              gameId: gameId,
            onUpdateComplete: onUpdateComplete,
            initialUserGameRating: initialUserGameRating,
          ),
        ),
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final RatingRepository _ratingRepository = RatingRepository();
  bool _isLoading = false;

  int? _selectedRating;
  PlayStatus? _selectedPlayStatus;
  CompletionStatus? _selectedCompletionStatus;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();

  final _scrollController = ScrollController();
  
  // State for ToggleButtons
  late List<bool> _playStatusSelected;
  late List<bool> _completionStatusSelected;
  
  @override
  void initState() {
    super.initState();
    final initialData = widget.initialUserGameRating;
    _selectedRating = initialData?.rating;
    _selectedPlayStatus = initialData?.playStatus == PlayStatus.notSet ? PlayStatus.playing : (initialData?.playStatus ?? PlayStatus.playing);
    _selectedCompletionStatus = initialData?.completionStatus ?? CompletionStatus.notSelected;
    _commentController.text = initialData?.comment ?? '';

    // Playtime değerlerini daha belirgin şekilde ayarla
    if (initialData?.playtimeInMinutes != null && initialData!.playtimeInMinutes! > 0) {
      final int hours = initialData.playtimeInMinutes! ~/ 60;
      final int minutes = initialData.playtimeInMinutes! % 60;
      _hoursController.text = hours > 0 ? hours.toString() : '';
      _minutesController.text = minutes >= 0 ? minutes.toString() : '';
      print('Playtime initialized: ${hours}h ${minutes}m from ${initialData.playtimeInMinutes} minutes');
    } else {
      _hoursController.text = '';
      _minutesController.text = '';
      print('No initial playtime');
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    // Initialize ToggleButton states
    _initializeToggleStates();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeToggleStates() {
    // Play Status ToggleButton initialization - daha güvenli seçim yapıyoruz
    _playStatusSelected = List.generate(PlayStatus.values.length, (index) => false);
    if (_selectedPlayStatus != null) {
      // Enum değerinin index'ini doğru şekilde alıyoruz
      final int statusIndex = PlayStatus.values.indexWhere(
        (status) => status == _selectedPlayStatus
      );
      if (statusIndex != -1) {
        _playStatusSelected[statusIndex] = true;
        print('PlayStatus initialized: $_selectedPlayStatus at index $statusIndex');
      } else {
        // notSet kaldırıldığından, varsayılan olarak "playing" kullan
        final int playingIndex = PlayStatus.values.indexWhere(
          (status) => status == PlayStatus.playing
        );
        if (playingIndex != -1) {
          _playStatusSelected[playingIndex] = true;
          _selectedPlayStatus = PlayStatus.playing;
        }
      }
    } else {
      // notSet kaldırıldığından, varsayılan olarak "playing" kullan
      final int playingIndex = PlayStatus.values.indexWhere(
        (status) => status == PlayStatus.playing
      );
      if (playingIndex != -1) {
        _playStatusSelected[playingIndex] = true;
        _selectedPlayStatus = PlayStatus.playing;
      }
    }

    // Completion Status ToggleButton initialization - daha güvenli seçim yapıyoruz 
    _completionStatusSelected = List.generate(CompletionStatus.values.length, (index) => false);
    if (_selectedCompletionStatus != null) {
      // Enum değerinin index'ini doğru şekilde alıyoruz
      final int completionIndex = CompletionStatus.values.indexWhere(
        (status) => status == _selectedCompletionStatus
      );
      if (completionIndex != -1) {
        _completionStatusSelected[completionIndex] = true;
        print('CompletionStatus initialized: $_selectedCompletionStatus at index $completionIndex');
      } else {
        print('CompletionStatus not found in CompletionStatus.values: $_selectedCompletionStatus');
      }
    } else {
      print('No initial CompletionStatus selected');
    }
  }

  int? _getPlaytimeInMinutes() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    if (hours <= 0 && minutes <= 0) return null;
    // Basic validation for minutes
    if (minutes >= 60) return (hours * 60) + 59; // Cap minutes at 59
    return (hours * 60) + minutes;
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Determine selected statuses from ToggleButton state
    final selectedPlayStatusIndex = _playStatusSelected.indexWhere((isSelected) => isSelected);
    final finalPlayStatus = selectedPlayStatusIndex != -1 
        ? PlayStatus.values[selectedPlayStatusIndex] 
        : PlayStatus.playing; // Default olarak playing
    
    // CompletionStatus'u sadece PlayStatus completed ise gönder
    CompletionStatus? finalCompletionStatus = null;
    if (finalPlayStatus == PlayStatus.completed) {
      final selectedCompletionIndex = _completionStatusSelected.indexWhere((isSelected) => isSelected);
      finalCompletionStatus = selectedCompletionIndex != -1 
          ? CompletionStatus.values[selectedCompletionIndex] 
          : null;
    }

    final playtime = _getPlaytimeInMinutes();
    
    // GEÇİCİ DEBUG KODU - SORUN ÇÖZÜLDÜĞÜNDE KALDIR
    print('DEBUG - Gönderilen: playStatus=${finalPlayStatus}, toJson=${finalPlayStatus.toJson()}, completionStatus=${finalCompletionStatus}, toJson=${finalCompletionStatus?.toJson()}');
    
    final request = UserGameRatingUpdateRequest(
      gameId: widget.gameId,
      rating: _selectedRating,
      comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      // PlayStatus her zaman gönderilmeli
      playStatus: finalPlayStatus,
      // CompletionStatus sadece PlayStatus completed ise gönderilmeli
      completionStatus: finalCompletionStatus,
      playtimeInMinutes: playtime,
    );

    try {
      final updatedRating = await _ratingRepository.updateRatingEntry(request);
      
      // GEÇİCİ DEBUG KODU - SORUN ÇÖZÜLDÜĞÜNDE KALDIR
      print('DEBUG - Alınan cevap: playStatus=${updatedRating.playStatus}, completionStatus=${updatedRating.completionStatus}, playtime=${updatedRating.playtimeInMinutes}');
      
      if (mounted) {
        widget.onUpdateComplete(updatedRating);
        Navigator.pop(context);
      }
    } catch (e) {
      print('Update Rating error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rating details: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark, 
        borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
      child: ClipRRect(
         borderRadius: const BorderRadius.only(
           topLeft: Radius.circular(20),
           topRight: Radius.circular(20),
         ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Use SingleChildScrollView for the main content area
              SingleChildScrollView(
                 controller: _scrollController,
                 padding: const EdgeInsets.fromLTRB(20, 60, 20, 100), // Increased top padding for header, bottom for FAB
                    child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      _buildGameHeader(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Your Rating"),
                      const SizedBox(height: 10),
                      _buildRatingSelector(),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[800]),
                        const SizedBox(height: 16),
                      _buildProgressSection(), // Combined Status & Playtime
                        const SizedBox(height: 24),
                      Divider(color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      _buildCommentField(),
                      const SizedBox(height: 30), // Extra space at the bottom before FAB
                      ],
                    ),
                  ),
              // Close button positioned independently
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Floating Save Button
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Adjusted vertical padding
             child: SizedBox(
              width: double.infinity,
              height: 50, // Explicit height for the button
               child: FloatingActionButton.extended(
                 onPressed: _isLoading ? null : _handleSave,
                 backgroundColor: theme.colorScheme.primary, // Use theme color
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                 icon: _isLoading ? null : const Icon(Icons.save, color: Colors.black, size: 20), // Adjusted icon size
                 label: _isLoading 
                     ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                     : const Text(
                         'Save',
                         style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                       ),
               ), 
             ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage( // Use CachedNetworkImage
            imageUrl: widget.coverUrl,
            width: 55, // Slightly smaller cover
            height: 75,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(width: 55, height: 75, color: Colors.grey[800]),
            errorWidget: (context, url, error) => Container(
              width: 55,
              height: 75,
              color: Colors.grey[800],
              child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.gameName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20, // Larger title
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return SizedBox(
      height: 45, // Define a fixed height for the row
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 10, // 1-10 arasında (0 butonunu kaldırdık)
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ratingValue = index + 1; // 1'den başlayarak 10'a kadar
          return _buildRatingButton(ratingValue);
        },
      ),
    );
  }

  Widget _buildRatingButton(int ratingValue) {
    final bool isSelected = _selectedRating == ratingValue;
    final theme = Theme.of(context);

    Color buttonColor;
    Color contentColor;
    double elevation = 1.0;

    buttonColor = isSelected ? _getRatingColor(ratingValue) : Colors.grey[800]!;
    contentColor = isSelected ? Colors.white : Colors.grey[400]!;
    if (isSelected) elevation = 4.0;
    
    return SizedBox(
      width: 42, // Slightly larger buttons
      height: 42,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                setState(() {
                  _selectedRating = ratingValue;
                });
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: elevation,
          shadowColor: Colors.black.withOpacity(0.5), // Add subtle shadow
        ),
        child: Text(
          ratingValue.toString(),
          style: TextStyle(
            color: contentColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         _buildSectionTitle("Your Review"), // English Title
         const SizedBox(height: 10),
         TextField(
          controller: _commentController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 4, // Slightly more lines
          maxLength: 500, // Increased limit
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: "Write your review...", 
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder( // Subtle border when enabled
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!), 
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // New combined section for Status and Playtime
 Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Your Progress"),
        const SizedBox(height: 16),
        _buildSubsectionTitle("Play Status"),
        const SizedBox(height: 10),
        _buildPlayStatusSelector(), // Yeni method
        const SizedBox(height: 20),
        
        // Completion Status'u sadece Play Status "completed" olduğunda göster
        if (_selectedPlayStatus == PlayStatus.completed) ...[
          _buildSubsectionTitle("Completion"),
          const SizedBox(height: 10),
          _buildCompletionStatusSelector(), // Yeni method
          const SizedBox(height: 20),
        ],
        
        _buildSubsectionTitle("Play Time"),
        const SizedBox(height: 10),
        _buildPlaytimeInput(), // Keep playtime input here
      ],
    );
 }

  // Yeni Play Status seçici - sadece seçili durumu göster, tıklandığında modal aç
  Widget _buildPlayStatusSelector() {
    // Mevcut seçili PlayStatus'i bul
    final selectedIndex = _playStatusSelected.indexWhere((selected) => selected);
    final currentStatus = selectedIndex != -1 
        ? PlayStatus.values[selectedIndex] 
        : PlayStatus.playing; // Default olarak playing yap
    
    return InkWell(
      onTap: () => _showPlayStatusSelectionModal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon ve seçili durum
            Row(
              children: [
                Icon(
                  _getPlayStatusIcon(currentStatus),
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _playStatusToString(currentStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            // Sağ tarafta aşağı ok
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Play Status için modal göster
  void _showPlayStatusSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Play Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Play Status seçenekleri - notSet hariç
            ...PlayStatus.values.where((status) => status != PlayStatus.notSet).map((status) {
              final isSelected = _selectedPlayStatus == status;
              return ListTile(
                onTap: () {
                  setState(() {
                    // Toggle butonu güncelle
                    for (int i = 0; i < _playStatusSelected.length; i++) {
                      _playStatusSelected[i] = PlayStatus.values[i] == status;
                    }
                    _selectedPlayStatus = status;
                    
                    // Eğer completed seçilmediyse ve completion status seçiliyse, sıfırla
                    if (status != PlayStatus.completed) {
                      for (int i = 0; i < _completionStatusSelected.length; i++) {
                        _completionStatusSelected[i] = i == 0; // NotSelected'ı seç
                      }
                      _selectedCompletionStatus = CompletionStatus.notSelected;
                    }
                  });
                  Navigator.pop(context); // Modal kapat
                },
                leading: Icon(
                  _getPlayStatusIcon(status),
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                  size: 24,
                ),
                title: Text(
                  _playStatusToString(status),
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: isSelected ? Colors.white.withOpacity(0.05) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Yeni Completion Status seçici - sadece seçili durumu göster, tıklandığında modal aç
  Widget _buildCompletionStatusSelector() {
    // Mevcut seçili CompletionStatus'i bul
    final selectedIndex = _completionStatusSelected.indexWhere((selected) => selected);
    final currentStatus = selectedIndex != -1 
        ? CompletionStatus.values[selectedIndex] 
        : CompletionStatus.notSelected;
    
    return InkWell(
      onTap: () => _showCompletionStatusSelectionModal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon ve seçili durum
            Row(
              children: [
                Icon(
                  _getCompletionStatusIcon(currentStatus),
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _completionStatusToString(currentStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            // Sağ tarafta aşağı ok
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Completion Status için modal göster
  void _showCompletionStatusSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Completion Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Opciones
            ...CompletionStatus.values.map((status) {
              final isSelected = _selectedCompletionStatus == status;
              return ListTile(
                onTap: () {
                  setState(() {
                    // Toggle butonu güncelle
                    for (int i = 0; i < _completionStatusSelected.length; i++) {
                      _completionStatusSelected[i] = CompletionStatus.values[i] == status;
                    }
                    _selectedCompletionStatus = status;
                  });
                  Navigator.pop(context); // Modal kapat
                },
                leading: Icon(
                  _getCompletionStatusIcon(status),
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                  size: 24,
                ),
                title: Text(
                  _completionStatusToString(status),
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: isSelected ? Colors.white.withOpacity(0.05) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaytimeInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align based on top
      children: [
        Expanded(
          child: TextField(
            controller: _hoursController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], // Limit hours length
            decoration: _playtimeInputDecoration("Hours"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 14), // Adjust padding
          child: Text(":", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
        ),
        Expanded(
          child: TextField(
            controller: _minutesController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], // Limit minutes length
            decoration: _playtimeInputDecoration("Minutes"),
             onChanged: (value) { // Validate minutes on change
               final int minutes = int.tryParse(value) ?? 0;
               if (minutes >= 60) {
                 _minutesController.text = '59';
                 _minutesController.selection = TextSelection.fromPosition(TextPosition(offset: _minutesController.text.length));
               }
             },
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4), // Align button better
          child: IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
            onPressed: () {
              _hoursController.clear();
              _minutesController.clear();
              FocusScope.of(context).unfocus(); // Dismiss keyboard
            },
            tooltip: "Clear Playtime",
             padding: EdgeInsets.zero,
             constraints: const BoxConstraints(),
          ),
        )
      ],
    );
  }
  
 InputDecoration _playtimeInputDecoration(String label) {
     final theme = Theme.of(context);
     return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
         enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!), 
        ),
        focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: "", // Hide the counter
        isDense: true,
      );
  }

 Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0), // Remove bottom padding
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Larger Title
      ),
    );
  }

  // New subsection title helper
  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  String _playStatusToString(PlayStatus status) {
    switch (status) {
      case PlayStatus.notSet: return "Not Set";
      case PlayStatus.playing: return "Playing";
      case PlayStatus.completed: return "Completed";
      case PlayStatus.dropped: return "Dropped";
      case PlayStatus.onHold: return "On Hold";
      case PlayStatus.backlog: return "Backlog";
      case PlayStatus.skipped: return "Skipped";
    }
  }

  String _completionStatusToString(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.notSelected: return "Not Selected";
      case CompletionStatus.mainStory: return "Main Story";
      case CompletionStatus.mainStoryPlusExtras: return "Main + Extras";
      case CompletionStatus.hundredPercent: return "100% Completion";
    }
  }

  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey[700]!;
    // More distinct colors for 1-10
    final hue = (rating - 1) * 13.3; // Spread hue from ~0 (red) to ~120 (green)
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.55).toColor(); // Saturation 60%, Lightness 55%
  }

  // --- Helper functions for ToggleButton Icons ---
 IconData _getPlayStatusIcon(PlayStatus status) {
    switch (status) {
      case PlayStatus.notSet: return FontAwesomeIcons.question;
      case PlayStatus.playing: return FontAwesomeIcons.gamepad;
      case PlayStatus.completed: return FontAwesomeIcons.check;
      case PlayStatus.dropped: return FontAwesomeIcons.trash;
      case PlayStatus.onHold: return FontAwesomeIcons.pause;
      case PlayStatus.backlog: return FontAwesomeIcons.list;
      case PlayStatus.skipped: return FontAwesomeIcons.forward;
    }
  }

  IconData _getCompletionStatusIcon(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.notSelected: return FontAwesomeIcons.minus;
      case CompletionStatus.mainStory: return FontAwesomeIcons.bookOpen;
      case CompletionStatus.mainStoryPlusExtras: return FontAwesomeIcons.plus;
      case CompletionStatus.hundredPercent: return FontAwesomeIcons.trophy;
    }
  }
  // --- End Helper Functions ---
} 