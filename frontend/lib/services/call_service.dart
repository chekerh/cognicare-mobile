import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

/// Incoming call data from WebSocket signaling.
class IncomingCall {
  final String fromUserId;
  final String fromUserName;
  final String channelId;
  final bool isVideo;

  IncomingCall({
    required this.fromUserId,
    required this.fromUserName,
    required this.channelId,
    required this.isVideo,
  });
}

class CallService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  io.Socket? _socket;
  String? _userId;
  final _incomingCallController = StreamController<IncomingCall>.broadcast();
  final _callAcceptedController = StreamController<String>.broadcast();
  final _callRejectedController = StreamController<void>.broadcast();
  final _callEndedController = StreamController<void>.broadcast();

  Stream<IncomingCall> get onIncomingCall => _incomingCallController.stream;
  Stream<String> get onCallAccepted => _callAcceptedController.stream;
  Stream<void> get onCallRejected => _callRejectedController.stream;
  Stream<void> get onCallEnded => _callEndedController.stream;

  String get _baseUrl {
    final base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;
    return base;
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  /// Nom de salle Jitsi à utiliser (meet.jit.si, gratuit, pas de clé).
  static String jitsiRoomName(String channelId) {
    return channelId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Connect to signaling WebSocket. Call when user logs in.
  Future<void> connect(String userId) async {
    debugPrint('📞 [CALL] connect() userId=$userId, baseUrl=$_baseUrl');
    if (_socket?.connected == true && _userId == userId) {
      debugPrint('📞 [CALL] Déjà connecté, skip');
      return;
    }
    disconnect();
    _userId = userId;
    final token = await _getToken();
    if (token == null) {
      debugPrint('📞 [CALL] ERREUR: Token null, impossible de se connecter au WebSocket');
      return;
    }
    debugPrint('📞 [CALL] Connexion WebSocket en cours...');
    final wsUrl = _baseUrl
        .replaceFirst('https://', 'https://')
        .replaceFirst('http://', 'http://');
    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .enableAutoConnect()
          .enableForceNew()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.onConnect((_) {
      debugPrint('📞 [CALL] WebSocket connecté pour userId=$userId');
    });
    _socket!.on('error', (e) => debugPrint('📞 [CALL] WebSocket error: $e'));
    _socket!.onDisconnect((_) => debugPrint('📞 [CALL] WebSocket déconnecté'));
    _socket!.on('call:incoming', (data) {
      debugPrint('📞 [CALL] call:incoming reçu: $data');
      if (data is Map) {
        _incomingCallController.add(IncomingCall(
          fromUserId: (data['fromUserId'] ?? '').toString(),
          fromUserName: (data['fromUserName'] ?? 'Appelant').toString(),
          channelId: (data['channelId'] ?? '').toString(),
          isVideo: data['isVideo'] == true,
        ));
      }
    });
    _socket!.on('call:accepted', (data) {
      final channelId = data is Map ? (data['channelId'] ?? '').toString() : '';
      debugPrint('📞 [CALL] call:accepted reçu channelId=$channelId');
      _callAcceptedController.add(channelId);
    });
    _socket!.on('call:rejected', (_) {
      debugPrint('📞 [CALL] call:rejected reçu');
      _callRejectedController.add(null);
    });
    _socket!.on('call:ended', (_) {
      debugPrint('📞 [CALL] call:ended reçu');
      _callEndedController.add(null);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _userId = null;
  }

  void initiateCall({
    required String targetUserId,
    required String channelId,
    required bool isVideo,
    required String callerName,
  }) {
    debugPrint('📞 [CALL] initiateCall targetUserId=$targetUserId channelId=$channelId isVideo=$isVideo socketConnected=${_socket?.connected}');
    if (_socket?.connected != true) {
      debugPrint('📞 [CALL] ERREUR: Socket non connecté, call:initiate non envoyé!');
    }
    _socket?.emit('call:initiate', {
      'targetUserId': targetUserId,
      'channelId': channelId,
      'isVideo': isVideo,
      'callerName': callerName,
    });
  }

  void acceptCall({required String fromUserId, required String channelId}) {
    debugPrint('📞 [CALL] acceptCall fromUserId=$fromUserId channelId=$channelId socketConnected=${_socket?.connected}');
    _socket?.emit('call:accept', {
      'fromUserId': fromUserId,
      'channelId': channelId,
    });
  }

  void rejectCall(String fromUserId) {
    debugPrint('📞 [CALL] rejectCall fromUserId=$fromUserId');
    _socket?.emit('call:reject', {'fromUserId': fromUserId});
  }

  void endCall(String targetUserId) {
    debugPrint('📞 [CALL] endCall targetUserId=$targetUserId');
    _socket?.emit('call:end', {'targetUserId': targetUserId});
  }
}
