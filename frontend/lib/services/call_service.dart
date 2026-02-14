import 'dart:async';
import 'dart:convert';
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

/// Token + appId response from backend.
class CallTokenResponse {
  final String token;
  final String channel;
  final String uid;
  final String appId;

  CallTokenResponse({
    required this.token,
    required this.channel,
    required this.uid,
    required this.appId,
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

  Future<CallTokenResponse> getRtcToken({
    required String channel,
    required String uid,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Non authentifié');
    final uri = Uri.parse(
        '$_baseUrl/api/v1/calls/token?channel=${Uri.encodeComponent(channel)}&uid=${Uri.encodeComponent(uid)}');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      final body = response.body;
      Map<String, dynamic>? err;
      try {
        err = jsonDecode(body) as Map<String, dynamic>?;
      } catch (_) {}
      throw Exception(err?['message'] ?? 'Erreur token: ${response.statusCode}');
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return CallTokenResponse(
      token: map['token'] as String,
      channel: map['channel'] as String,
      uid: map['uid'] as String,
      appId: map['appId'] as String,
    );
  }

  /// Connect to signaling WebSocket. Call when user logs in.
  Future<void> connect(String userId) async {
    if (_socket?.connected == true && _userId == userId) return;
    disconnect();
    _userId = userId;
    final token = await _getToken();
    if (token == null) return;
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
    _socket!.onConnect((_) {});
    _socket!.on('call:incoming', (data) {
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
      _callAcceptedController.add(channelId);
    });
    _socket!.on('call:rejected', (_) => _callRejectedController.add(null));
    _socket!.on('call:ended', (_) => _callEndedController.add(null));
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
    _socket?.emit('call:initiate', {
      'targetUserId': targetUserId,
      'channelId': channelId,
      'isVideo': isVideo,
      'callerName': callerName,
    });
  }

  void acceptCall({required String fromUserId, required String channelId}) {
    _socket?.emit('call:accept', {
      'fromUserId': fromUserId,
      'channelId': channelId,
    });
  }

  void rejectCall(String fromUserId) {
    _socket?.emit('call:reject', {'fromUserId': fromUserId});
  }

  void endCall(String targetUserId) {
    _socket?.emit('call:end', {'targetUserId': targetUserId});
  }
}
