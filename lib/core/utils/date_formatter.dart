import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'TBA';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  static String formatYear(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'TBA';
    }

    try {
      final date = DateTime.parse(dateString);
      return date.year.toString();
    } catch (e) {
      return dateString;
    }
  }
} 