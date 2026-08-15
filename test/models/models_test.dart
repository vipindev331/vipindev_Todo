import 'package:flutter_test/flutter_test.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/models/repo_sort.dart';

void main() {
  group('GithubUser.fromJson', () {
    test('parses a full payload', () {
      final user = GithubUser.fromJson(const {
        'login': 'octocat',
        'name': 'The Octocat',
        'bio': 'Mascot',
        'avatar_url': 'https://example.com/a.png',
        'followers': 1200,
        'following': 9,
        'public_repos': 8,
        'company': '@github',
        'location': 'San Francisco',
      });

      expect(user.login, 'octocat');
      expect(user.displayName, 'The Octocat');
      expect(user.bio, 'Mascot');
      expect(user.followers, 1200);
      expect(user.following, 9);
      expect(user.publicRepos, 8);
    });

    test('treats null and blank optional fields as null', () {
      final user = GithubUser.fromJson(const {
        'login': 'ghost',
        'name': null,
        'bio': '   ',
        'avatar_url': 'https://example.com/a.png',
        'followers': 0,
        'following': 0,
        'public_repos': 0,
      });

      expect(user.name, isNull);
      expect(user.bio, isNull);
      // Falls back to the handle when there is no display name.
      expect(user.displayName, 'ghost');
    });

    test('survives missing counts instead of throwing', () {
      final user = GithubUser.fromJson(const {'login': 'partial'});

      expect(user.followers, 0);
      expect(user.following, 0);
      expect(user.publicRepos, 0);
      expect(user.avatarUrl, '');
    });
  });

  group('GithubRepo.fromJson', () {
    test('parses fields and dates', () {
      final repo = GithubRepo.fromJson(const {
        'id': 1,
        'name': 'flutter',
        'full_name': 'flutter/flutter',
        'description': 'UI toolkit',
        'stargazers_count': 160000,
        'forks_count': 27000,
        'fork': false,
        'language': 'Dart',
        'updated_at': '2026-08-01T10:00:00Z',
      });

      expect(repo.name, 'flutter');
      expect(repo.stars, 160000);
      expect(repo.language, 'Dart');
      expect(repo.updatedAt, isNotNull);
      expect(repo.updatedAt!.toUtc().year, 2026);
    });

    test('handles a null description, language and date', () {
      final repo = GithubRepo.fromJson(const {
        'id': 2,
        'name': 'empty',
        'description': null,
        'language': null,
        'updated_at': null,
      });

      expect(repo.description, isNull);
      expect(repo.language, isNull);
      expect(repo.updatedAt, isNull);
      expect(repo.stars, 0);
    });
  });

  group('RepoSort', () {
    GithubRepo repo(String name, int stars, String? updated) => GithubRepo.fromJson({
          'id': name.hashCode,
          'name': name,
          'stargazers_count': stars,
          'updated_at': updated,
        });

    final repos = [
      repo('old-but-popular', 500, '2020-01-01T00:00:00Z'),
      repo('fresh', 10, '2026-08-10T00:00:00Z'),
      repo('undated', 50, null),
    ];

    test('stars sorts descending by star count', () {
      final sorted = RepoSort.stars.apply(repos);
      expect(sorted.map((r) => r.name), ['old-but-popular', 'undated', 'fresh']);
    });

    test('recentlyUpdated sorts newest first and pushes undated to the end', () {
      final sorted = RepoSort.recentlyUpdated.apply(repos);
      expect(sorted.map((r) => r.name), ['fresh', 'old-but-popular', 'undated']);
    });

    test('does not mutate the source list', () {
      final original = [...repos];
      RepoSort.stars.apply(repos);
      expect(repos.map((r) => r.name), original.map((r) => r.name));
    });
  });
}
