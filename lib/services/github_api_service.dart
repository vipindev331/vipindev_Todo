import 'package:dio/dio.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/github_user.dart';

/// Thin, typed wrapper around the GitHub REST API.
///
/// Everything that leaves this class is either a model or an [AppException];
/// raw JSON and Dio types never reach the providers or the UI.
class GithubApiService {
  GithubApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.github.com',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'Accept': 'application/vnd.github+json',
                  'X-GitHub-Api-Version': '2022-11-28',
                },
              ),
            );

  final Dio _dio;

  /// Fetches a single user profile. Throws [AppException] on any failure.
  Future<GithubUser> fetchUser(String username, {CancelToken? cancelToken}) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        'Please enter a GitHub username.',
        kind: ErrorKind.notFound,
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        '/users/${Uri.encodeComponent(trimmed)}',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException(
          'Unexpected response from GitHub.',
          kind: ErrorKind.server,
        );
      }
      return GithubUser.fromJson(data);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// Fetches up to [perPage] repositories for [username], newest push first.
  /// Sorting for display happens client-side so toggling is instant.
  Future<List<GithubRepo>> fetchRepositories(
    String username, {
    int perPage = 100,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/users/${Uri.encodeComponent(username.trim())}/repos',
        queryParameters: {'per_page': perPage, 'sort': 'updated'},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is! List) {
        throw const AppException(
          'Unexpected response from GitHub.',
          kind: ErrorKind.server,
        );
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(GithubRepo.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}
