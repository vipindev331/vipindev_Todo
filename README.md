# vipinde_ToDo

A Flutter app that searches GitHub users and browses their repositories.

## Features

**Search screen**
- Enter a GitHub username and submit (keyboard action or the search button)
- Shows profile picture, name, bio, followers, following and public repository count
- Every async state is handled explicitly: idle, loading, user not found, network/API
  error (with retry) and success
- The device back button asks for confirmation before leaving the app (and dismisses
  the keyboard first if the field is focused)

**Repositories screen**
- Opened by tapping the profile card
- Each repository shows name, description, ⭐ stars, language (with a colour dot) and
  last-updated as relative time
- Sort by ⭐ **Stars** or 🕒 **Recently updated** (client-side, so toggling is instant)
- Pull to refresh; empty and error states handled

**Recent searches (bonus)**
- The last 5 usernames are persisted with `shared_preferences`
- Tapping a chip re-runs that search immediately; the list is de-duplicated
  case-insensitively and can be cleared

## Running

```bash
flutter pub get
flutter run
```

Tests and static analysis:

```bash
flutter test      # 32 tests
flutter analyze
```

No API token is needed. Unauthenticated GitHub requests are rate limited to 60/hour
per IP; that case is detected and shown as a friendly "slow down a moment" message.

## Design

The UI is built from **exactly two colours**, defined once in
`lib/core/app_theme.dart`:

| Token | Value | Used for |
| --- | --- | --- |
| `primary` | `#2563EB` | header block, actions, stat tiles, selected states, accents |
| `ink` | `#0B1220` | text, borders, surfaces |

Every other tone — page background, card borders, muted labels, tinted fills — is
one of those two blended with white (light theme) or with each other (dark theme),
so the palette never grows a third hue. Consequences worth noting: the language
marker is a single primary dot rather than a per-language colour, and error states
are carried by icon + copy instead of a warning red.

Both screens share the same structure — a rounded brand-coloured `AppHeader`
(`lib/widgets/app_header.dart`) over a light content area of white cards — so they
read as one app. Light and dark themes are both fully defined.

```
Search screen                    Repositories screen
┌─────────────────────┐          ┌─────────────────────┐
│ ▉ vipinde_ToDo      │ header   │ ▉ ← 👤 The Octocat  │ header
│ ▉ [ search…    → ]  │          │ ▉ @octocat · 8 repos│
└─────────────────────┘          └─────────────────────┘
  Recent searches  Clear           [ ⭐ Stars │ 🕒 Recent ]
  ( octocat )( flutter )           ┌───────────────────┐
  ┌───────────────────┐            │ 📁 repo-name      │
  │  ◯  The Octocat   │            │ description…      │
  │     @octocat    › │            │ ⭐ 3.8k ● Dart  🕒 │
  │  bio…             │            └───────────────────┘
  │ [24k] [ 9 ] [ 8 ] │            ┌───────────────────┐
  └───────────────────┘            │ …                 │
```

## Architecture

```
lib/
├── core/
│   ├── app_theme.dart       # the two-colour palette, shapes and both ThemeDatas
│   ├── app_exception.dart   # single UI-facing error type + Dio → AppException mapping
│   ├── ui_state.dart        # sealed UiState<T>: Idle | Loading | Success | Failure
│   └── formatters.dart      # count compaction (1.5k) and relative dates
├── models/
│   ├── github_user.dart     # fromJson / toJson, null-safe optional fields
│   ├── github_repo.dart
│   └── repo_sort.dart       # sort options + the sorting itself
├── services/
│   ├── github_api_service.dart     # Dio; returns models or throws AppException
│   └── recent_searches_service.dart # shared_preferences history (max 5)
├── providers/
│   ├── user_search_provider.dart   # search state + recent searches
│   └── repositories_provider.dart  # per-user repo list + sort selection
├── screens/
│   ├── search_screen.dart
│   └── repositories_screen.dart
└── widgets/
    ├── app_header.dart      # the brand header shared by both screens
    ├── user_profile_card.dart
    ├── repo_tile.dart
    ├── recent_searches_bar.dart
    └── error_view.dart      # shared ErrorView / EmptyView
```

**State management — Provider.** `GithubApiService` and `RecentSearchesService` are
provided at the root and injected into the `ChangeNotifier`s, which makes both
providers trivially testable with a fake API. `UserSearchProvider` lives app-wide (the
search history outlives a single screen); `RepositoriesProvider` is created by
`RepositoriesScreen` so it is disposed with the route.

**Async state.** `UiState<T>` is a sealed class, so `switch` in the UI is
exhaustiveness-checked by the compiler — a new state can never be silently
unrendered. `UserSearchProvider` tags each request with an id and drops results from
superseded requests, so a slow earlier search cannot overwrite a newer one.

**Errors.** Dio exceptions never leave the service layer. They are translated into
`AppException` with an `ErrorKind` (`network`, `notFound`, `rateLimited`, `server`,
`unknown`), which `ErrorView` turns into the right icon, headline and message.

**No raw JSON in the UI.** `Map<String, dynamic>` exists only inside `fromJson`.
Widgets only ever see `GithubUser` / `GithubRepo`. Parsing is defensive: missing
counts default to 0 and blank strings become `null`, so an unusual payload degrades
instead of throwing.

## Tests

| File | Covers |
| --- | --- |
| `test/models/models_test.dart` | `fromJson` for full, sparse and null-heavy payloads; both sort orders; sorting does not mutate its input |
| `test/providers/user_search_provider_test.dart` | loading → success/failure transitions, 404 vs network errors, empty query short-circuit, stale-response guard, 5-entry de-duplicated history, persistence across instances |
| `test/providers/repositories_provider_test.dart` | load, sort switching without refetch, error state, empty list is a success |
| `test/widgets/search_screen_test.dart` | the whole flow: empty prompt → loading → profile render, not-found, network error + retry, recent-search chip, navigation to the repositories screen, and the back-button exit confirmation (Cancel stays, Exit calls `SystemNavigator.pop`, focused keyboard is dismissed first) |

## Tech

Flutter 3.38 · Dart 3.10 (sound null safety) · `dio` · `provider` ·
`shared_preferences` · `intl`
