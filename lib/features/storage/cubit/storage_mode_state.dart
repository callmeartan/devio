part of 'storage_mode_cubit.dart';

// Simple implementation without Freezed to fix the errors
class StorageModeState {
  final StorageMode mode;
  final bool isChangingMode;
  final String? errorMessage;

  const StorageModeState({
    required this.mode,
    this.isChangingMode = false,
    this.errorMessage,
  });

  factory StorageModeState.initial() => const StorageModeState(
        mode: StorageMode.cloud,
      );

  StorageModeState copyWith({
    StorageMode? mode,
    bool? isChangingMode,
    String? errorMessage,
  }) {
    return StorageModeState(
      mode: mode ?? this.mode,
      isChangingMode: isChangingMode ?? this.isChangingMode,
      errorMessage: errorMessage,
    );
  }
}
