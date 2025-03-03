import 'package:flutter/material.dart';

class ReviewModal extends StatefulWidget {
  final String gameName;
  final String coverUrl;
  final Function(String) onReviewSubmitted;

  const ReviewModal({
    Key? key,
    required this.gameName,
    required this.coverUrl,
    required this.onReviewSubmitted,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String gameName,
    required String coverUrl,
    required Function(String) onReviewSubmitted,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReviewModal(
          gameName: gameName,
          coverUrl: coverUrl,
          onReviewSubmitted: onReviewSubmitted,
        ),
      ),
    );
  }

  @override
  State<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  final TextEditingController _reviewController = TextEditingController();
  final int maxCharacters = 140;

  @override
  void initState() {
    super.initState();
    _reviewController.addListener(() {
      setState(() {
        // Update character counter
      });
    });
  }

  @override
  void dispose() {
    _reviewController.removeListener(() {});
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close and post buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_reviewController.text.isNotEmpty) {
                        widget.onReviewSubmitted(_reviewController.text);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(widget.coverUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.gameName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _reviewController,
                  maxLength: maxCharacters,
                  maxLines: null,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Write your review...",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    counterStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 