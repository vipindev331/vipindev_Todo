import 'package:vipinde_todo/core/app_exception.dart';

/// Exhaustive async state used by every provider in the app.
///
/// Being a sealed class, `switch` over it in the UI is checked by the compiler,
/// so a new state can never be silently unhandled.
sealed class UiState<T> {
  const UiState();

  const factory UiState.idle() = Idle<T>;
  const factory UiState.loading() = Loading<T>;
  const factory UiState.success(T data) = Success<T>;
  const factory UiState.failure(AppException error) = Failure<T>;

  bool get isLoading => this is Loading<T>;

  /// The payload when this state is a [Success], otherwise `null`.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        _ => null,
      };
}

final class Idle<T> extends UiState<T> {
  const Idle();
}

final class Loading<T> extends UiState<T> {
  const Loading();
}

final class Success<T> extends UiState<T> {
  const Success(this.data);

  final T data;
}

final class Failure<T> extends UiState<T> {
  const Failure(this.error);

  final AppException error;
}
