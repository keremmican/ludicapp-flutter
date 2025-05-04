// General Server Exception
class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

// Network related exceptions
class NetworkException implements Exception {
   final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

// Authentication/Authorization Exception
class UnauthorizedException implements Exception {
   final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

// Resource Not Found Exception
class NotFoundException implements Exception {
   final String message;
  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

// Data Parsing Exception
class DataParsingException implements Exception {
  final String message;
  DataParsingException(this.message);

  @override
  String toString() => 'DataParsingException: $message';
}

// Request Cancelled Exception
class RequestCancelledException implements Exception {
   final String message;
  RequestCancelledException(this.message);

  @override
  String toString() => 'RequestCancelledException: $message';
} 