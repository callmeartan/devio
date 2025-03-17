import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_status.g.dart';
part 'server_status.freezed.dart';

enum ServerStatus {
  @JsonValue(0)
  disconnected,

  @JsonValue(1)
  connecting,

  @JsonValue(2)
  connected,

  @JsonValue(3)
  error,
}

@freezed
class ServerStatusInfo with _$ServerStatusInfo {
  const factory ServerStatusInfo({
    required ServerStatus status,
    String? message,
    String? version,
    @Default(false) bool hasModels,
    List<String>? availableModels,
  }) = _ServerStatusInfo;

  factory ServerStatusInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerStatusInfoFromJson(json);

  factory ServerStatusInfo.disconnected() => const ServerStatusInfo(
        status: ServerStatus.disconnected,
        message: 'Not connected to Ollama server',
      );

  factory ServerStatusInfo.connecting() => const ServerStatusInfo(
        status: ServerStatus.connecting,
        message: 'Connecting to Ollama server...',
      );

  factory ServerStatusInfo.connected({
    String? version,
    bool hasModels = false,
    List<String>? availableModels,
  }) =>
      ServerStatusInfo(
        status: ServerStatus.connected,
        message: 'Connected to Ollama server',
        version: version,
        hasModels: hasModels,
        availableModels: availableModels,
      );

  factory ServerStatusInfo.error(String message) => ServerStatusInfo(
        status: ServerStatus.error,
        message: message,
      );
}
