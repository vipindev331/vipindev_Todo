/// A repository, as returned by `GET /users/{username}/repos`.
class GithubRepo {
  const GithubRepo({
    required this.id,
    required this.name,
    required this.fullName,
    required this.stars,
    required this.forks,
    required this.isFork,
    this.description,
    this.language,
    this.updatedAt,
    this.htmlUrl,
  });

  final int id;
  final String name;
  final String fullName;
  final int stars;
  final int forks;
  final bool isFork;
  final String? description;
  final String? language;
  final DateTime? updatedAt;
  final String? htmlUrl;

  factory GithubRepo.fromJson(Map<String, dynamic> json) {
    return GithubRepo(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      stars: _asInt(json['stargazers_count']),
      forks: _asInt(json['forks_count']),
      isFork: json['fork'] as bool? ?? false,
      description: _asNonEmptyString(json['description']),
      language: _asNonEmptyString(json['language']),
      updatedAt: _asDate(json['updated_at']),
      htmlUrl: _asNonEmptyString(json['html_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'full_name': fullName,
        'stargazers_count': stars,
        'forks_count': forks,
        'fork': isFork,
        'description': description,
        'language': language,
        'updated_at': updatedAt?.toIso8601String(),
        'html_url': htmlUrl,
      };
}

int _asInt(Object? value) => switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

String? _asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _asDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
