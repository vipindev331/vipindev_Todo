import 'package:dio/dio.dart';

/// A single, UI-friendly error type. Every failure that leaves the data layer
/// is converted into this so that widgets never have to know about Dio.
class AppException implements Exception {
  const AppException(this.message, {this.kind = ErrorKind.unknown});

  final String message;
  final ErrorKind kind;

  /// Translates a [DioException] into something a user can act on.
  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'The request timed out. Please check your connection and try again.',
          kind: ErrorKind.network,
        );
      case DioExceptionType.connectionError:
        return const AppException(
          'No internet connection. Please check your network and try again.',
          kind: ErrorKind.network,
        );
      case DioExceptionType.cancel:
        return const AppException('Request cancelled.', kind: ErrorKind.unknown);
      case DioExceptionType.badCertificate:
        return const AppException(
          'Could not establish a secure connection.',
          kind: ErrorKind.network,
        );
      case DioExceptionType.badResponse:
        return AppException._fromStatus(e.response?.statusCode);
      default:
        return const AppException(
          'Something went wrong. Please try again.',
          kind: ErrorKind.unknown,
        );
    }
  }

  factory AppException._fromStatus(int? status) {
    switch (status) {
      case 404:
        return const AppException(
          'User not found. Check the username and try again.',
          kind: ErrorKind.notFound,
        );
      case 403:
      case 429:
        return const AppException(
          'GitHub rate limit reached. Please wait a minute and try again.',
          kind: ErrorKind.rateLimited,
        );
      case 401:
        return const AppException(
          'Not authorised to access GitHub.',
          kind: ErrorKind.server,
        );
      default:
        return AppException(
          'GitHub returned an error${status == null ? '' : ' ($status)'}. '
          'Please try again.',
          kind: ErrorKind.server,
        );
    }
  }

  @override
  String toString() => 'AppException($kind): $message';
}

enum ErrorKind { network, notFound, rateLimited, server, unknown }
