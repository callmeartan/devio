/// A mixin that provides pattern matching functionality similar to Freezed's
/// but doesn't rely on Freezed's code generation.
mixin StatePatternMatchingMixin {
  /// Executes a callback based on the runtime state type, or returns the orElse value if no match.
  ///
  /// Usage:
  /// ```dart
  /// state.maybeWhen(
  ///   matching: {
  ///     'State.initial': () => doSomething(),
  ///     'State.loading': () => showLoading(),
  ///     'State.success': (data) => showData(data),
  ///   },
  ///   orElse: () => showDefault(),
  /// );
  /// ```
  T maybeWhen<T>({
    required Map<String, dynamic> matching,
    required T Function() orElse,
  }) {
    final stateString = toString();

    for (final entry in matching.entries) {
      if (stateString.startsWith(entry.key)) {
        final callback = entry.value;
        if (callback is Function) {
          try {
            // Try to invoke the callback with the current instance (this) as the parameter
            return Function.apply(callback, [], {}) as T;
          } catch (e) {
            // If there's an error, return orElse
            return orElse();
          }
        }
      }
    }

    return orElse();
  }

  /// Similar to maybeWhen but returns null if no match is found instead of executing orElse.
  T? whenOrNull<T>({
    required Map<String, dynamic> matching,
  }) {
    final stateString = toString();

    for (final entry in matching.entries) {
      if (stateString.startsWith(entry.key)) {
        final callback = entry.value;
        if (callback is Function) {
          try {
            // Try to invoke the callback with the current instance (this) as the parameter
            return Function.apply(callback, [], {}) as T;
          } catch (e) {
            // If there's an error, return null
            return null;
          }
        }
      }
    }

    return null;
  }
}
