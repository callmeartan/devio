import 'package:freezed_annotation/freezed_annotation.dart';

/// Enum representing the storage mode of the application.
///
/// [cloud] - Data is synced with Firebase and stored in the cloud.
/// [local] - Data is stored only on the device and not synced to the cloud.
enum StorageMode {
  @JsonValue(0)
  cloud,

  @JsonValue(1)
  local,
}

extension StorageModeExtension on StorageMode {
  String get displayName {
    switch (this) {
      case StorageMode.cloud:
        return 'Cloud Mode';
      case StorageMode.local:
        return 'Local Mode';
    }
  }

  String get description {
    switch (this) {
      case StorageMode.cloud:
        return 'Data is synced with the cloud and available across devices';
      case StorageMode.local:
        return 'Data is stored only on this device and not synced to the cloud';
    }
  }

  String get iconName {
    switch (this) {
      case StorageMode.cloud:
        return 'cloud';
      case StorageMode.local:
        return 'smartphone';
    }
  }

  bool get isLocal => this == StorageMode.local;
  bool get isCloud => this == StorageMode.cloud;
}
