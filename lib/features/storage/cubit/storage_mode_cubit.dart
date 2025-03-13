import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'dart:developer' as developer;

part 'storage_mode_state.dart';

class StorageModeCubit extends Cubit<StorageModeState> {
  final SharedPreferences _prefs;
  static const String _storageModeKey = 'storage_mode';

  StorageModeCubit(this._prefs) : super(_loadInitialState(_prefs)) {
    // Add debug logging for initial mode
    developer.log(
        'StorageModeCubit initialized with mode: ${state.mode.displayName}');
    developer.log('isLocalMode: $isLocalMode, isCloudMode: $isCloudMode');
  }

  static StorageModeState _loadInitialState(SharedPreferences prefs) {
    final storedModeIndex = prefs.getInt(_storageModeKey);
    developer.log('Loaded storage mode index from prefs: $storedModeIndex');

    // Explicitly handle the null case
    StorageMode mode;
    if (storedModeIndex == null) {
      // No value stored yet, default to Cloud Mode
      mode = StorageMode.cloud;
      developer.log('No storage mode found in prefs, defaulting to Cloud Mode');
    } else if (storedModeIndex == 1) {
      // Value is 1, use Local Mode
      mode = StorageMode.local;
    } else {
      // Value is 0 or any other value, use Cloud Mode
      mode = StorageMode.cloud;
    }

    developer.log('Initial storage mode set to: ${mode.name}');
    return StorageModeState(mode: mode);
  }

  /// Changes the storage mode to the specified mode
  Future<void> changeMode(StorageMode mode) async {
    if (state.mode == mode) return;

    emit(state.copyWith(isChangingMode: true, errorMessage: null));

    try {
      // Save the mode to SharedPreferences
      await _prefs.setInt(_storageModeKey, mode == StorageMode.local ? 1 : 0);
      developer.log(
          'Saved storage mode to prefs: ${mode.name} (${mode == StorageMode.local ? 1 : 0})');

      // Update the state
      emit(state.copyWith(mode: mode, isChangingMode: false));

      developer.log('Storage mode changed to: ${mode.displayName}');
    } catch (e) {
      developer.log('Error changing storage mode: $e');
      emit(state.copyWith(
        isChangingMode: false,
        errorMessage: 'Failed to change storage mode: $e',
      ));
    }
  }

  /// Sets the storage mode to Local Mode
  Future<void> useLocalMode() => changeMode(StorageMode.local);

  /// Sets the storage mode to Cloud Mode
  Future<void> useCloudMode() => changeMode(StorageMode.cloud);

  /// Returns true if the app is currently in Local Mode
  bool get isLocalMode => state.mode.isLocal;

  /// Returns true if the app is currently in Cloud Mode
  bool get isCloudMode => state.mode.isCloud;
}
