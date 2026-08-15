import 'package:vipinde_todo/models/github_repo.dart';

/// How the repositories list is ordered.
enum RepoSort {
  stars('Stars', '⭐'),
  recentlyUpdated('Recently updated', '🕒');

  const RepoSort(this.label, this.emoji);

  final String label;
  final String emoji;

  /// Returns a new, sorted list — the source list is never mutated.
  List<GithubRepo> apply(List<GithubRepo> repos) {
    final sorted = [...repos];
    switch (this) {
      case RepoSort.stars:
        sorted.sort((a, b) {
          final byStars = b.stars.compareTo(a.stars);
          return byStars != 0 ? byStars : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      case RepoSort.recentlyUpdated:
        sorted.sort((a, b) {
          final aDate = a.updatedAt;
          final bDate = b.updatedAt;
          if (aDate == null && bDate == null) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
    }
    return sorted;
  }
}
