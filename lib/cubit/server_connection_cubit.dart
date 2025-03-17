import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_status.dart';
import '../services/ollama_service.dart';

part 'server_connection_cubit.freezed.dart';
part 'server_connection_cubit.g.dart';

@freezed
class ServerConnectionState with _$ServerConnectionState {
  const factory ServerConnectionState({
    required ServerStatusInfo status,
    required String serverUrl,
    @Default(false) bool isCheckingStatus,
  }) = _ServerConnectionState;

  factory ServerConnectionState.initial() => const ServerConnectionState(
        status: ServerStatusInfo(
          status: ServerStatus.disconnected,
          message: 'Not connected to Ollama server',
        ),
        serverUrl: 'http://localhost:11434',
      );

  factory ServerConnectionState.fromJson(Map<String, dynamic> json) =>
      _$ServerConnectionStateFromJson(json);
}

class ServerConnectionCubit extends Cubit<ServerConnectionState> {
  final OllamaService _ollamaService;
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isInitialized = false;

  ServerConnectionCubit({required OllamaService ollamaService})
      : _ollamaService = ollamaService,
        super(ServerConnectionState.initial());

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('server_url');

      if (savedUrl != null && savedUrl.isNotEmpty) {
        emit(state.copyWith(serverUrl: savedUrl));
        _ollamaService.updateServerUrl(savedUrl);
      }

      await checkServerStatus();
      startPolling();
    } catch (e) {
      log('Error initializing ServerConnectionCubit: $e');
    }
  }

  Future<ServerStatusInfo> checkServerStatus() async {
    if (state.isCheckingStatus) return state.status;

    emit(state.copyWith(isCheckingStatus: true));
    ServerStatusInfo newStatus;

    try {
      final url = state.serverUrl;
      if (url.isEmpty) {
        newStatus = ServerStatusInfo.error('Server URL is not set');
      } else {
        final response = await http
            .get(Uri.parse('$url/api/tags'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = data['models'] as List<dynamic>?;
          final hasModels = models != null && models.isNotEmpty;
          final modelNames = hasModels
              ? models.map((m) => m['name'].toString()).toList().cast<String>()
              : <String>[];

          newStatus = ServerStatusInfo.connected(
            hasModels: hasModels,
            availableModels: modelNames,
          );
        } else {
          newStatus = ServerStatusInfo.error(
            'Server responded with status ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      log('Error checking server status: $e');
      newStatus = ServerStatusInfo.error(
        e.toString().contains('SocketException')
            ? 'Cannot connect to server. Make sure Ollama is running.'
            : 'Error connecting: ${e.toString()}',
      );
    }

    emit(state.copyWith(
      status: newStatus,
      isCheckingStatus: false,
    ));
    return newStatus;
  }

  Future<void> updateServerUrl(String url) async {
    try {
      if (url != state.serverUrl) {
        emit(state.copyWith(serverUrl: url));
        _ollamaService.updateServerUrl(url);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_url', url);

        // Check connection with new URL
        await checkServerStatus();
      }
    } catch (e) {
      log('Error updating server URL: $e');
    }
  }

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkServerStatus();
    });
  }

  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
