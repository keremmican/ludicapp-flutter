import 'package:flutter/foundation.dart';

// Corresponds to com.ludic.ludicapp.library.dto.CustomLibraryStatusResponseDto
@immutable
class CustomLibraryStatusResponse {
  final int libraryId;
  final String libraryName;
  final bool isGamePresent;

  const CustomLibraryStatusResponse({
    required this.libraryId,
    required this.libraryName,
    required this.isGamePresent,
  });

  factory CustomLibraryStatusResponse.fromJson(Map<String, dynamic> json) {
    return CustomLibraryStatusResponse(
      libraryId: json['libraryId'] as int? ?? 0,
      libraryName: json['libraryName'] as String? ?? 'Unknown Library',
      isGamePresent: json['isGamePresent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'libraryId': libraryId,
      'libraryName': libraryName,
      'isGamePresent': isGamePresent,
    };
  }
} 