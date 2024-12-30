import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ErrorHandler {
  static void handle(dynamic error, BuildContext context) {
    String message = "An unexpected error occurred";

    if (error is DioError) {
      switch (error.type) {
        case DioExceptionType.badResponse:
          message = "Server error: ${error.response?.statusCode}";
          break;
        case DioExceptionType.connectionTimeout:
          message = "Connection timeout";
          break;
        case DioExceptionType.receiveTimeout:
          message = "Receive timeout";
          break;
        default:
          message = "Something went wrong";
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
