/// A GitHub user profile, as returned by `GET /users/{username}`.
///
/// Only [login] is guaranteed by the API; everything else is optional on
/// GitHub's side, so the nullability here mirrors reality instead of hiding it.
class GithubUser {
  const GithubUser({
    required this.login,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    required this.publicRepos,
    this.name,
    this.bio,
    this.company,
    this.location,
    this.blog,
    this.htmlUrl,
  });

  final String login;
  final String avatarUrl;
  final int followers;
  final int following;
  final int publicRepos;
  final String? name;
  final String? bio;
  final String? company;
  final String? location;
  final String? blog;
  final String? htmlUrl;

  /// Name to show as the headline; falls back to the handle when the user
  /// has not set a display name.
  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : login;

  factory GithubUser.fromJson(Map<String, dynamic> json) {
    return GithubUser(
      login: json['login'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      followers: _asInt(json['followers']),
      following: _asInt(json['following']),
      publicRepos: _asInt(json['public_repos']),
      name: _asNonEmptyString(json['name']),
      bio: _asNonEmptyString(json['bio']),
      company: _asNonEmptyString(json['company']),
      location: _asNonEmptyString(json['location']),
      blog: _asNonEmptyString(json['blog']),
      htmlUrl: _asNonEmptyString(json['html_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'login': login,
        'avatar_url': avatarUrl,
        'followers': followers,
        'following': following,
        'public_repos': publicRepos,
        'name': name,
        'bio': bio,
        'company': company,
        'location': location,
        'blog': blog,
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
