import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';
import 'notification_service.dart';
import 'notifications_feed_service.dart';

// ─── Data classes ────────────────────────────────────────────────────

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

/// Incoming chat notification payload from WebSocket.
class IncomingMessageEvent {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String preview;
  final String? text;
  final String? attachmentUrl;
  final String? attachmentType;
  final int? callDuration;
  final String? messageId;
  final DateTime? createdAt;

  IncomingMessageEvent({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.preview,
    this.text,
    this.attachmentUrl,
    this.attachmentType,
    this.callDuration,
    this.messageId,
    this.createdAt,
  });
}

class TypingEvent {
  final String userId;
  final String conversationId;
  final bool isTyping;

  TypingEvent({
    required this.userId,
    required this.conversationId,
    required this.isTyping,
  });
}

// ─── CallService (signaling) ─────────────────────────────────────────

class CallService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  io.Socket? _socket;
  String? _userId;

  // Call lifecycle streams
  final _incomingCallController = StreamController<IncomingCall>.broadcast();
  final _callAcceptedController = StreamController<String>.broadcast();
  final _callRejectedController = StreamController<void>.broadcast();
  final _callEndedController = StreamController<void>.broadcast();
  final _incomingMessageController =
      StreamController<IncomingMessageEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();

  // WebRTC signaling streams
  final _remoteOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _remoteAnswerController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _remoteIceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final NotificationsFeedService _notificationsFeedService =
      NotificationsFeedService();

  // Call lifecycle
  Stream<IncomingCall> get onIncomingCall => _incomingCallController.stream;
  Stream<String> get onCallAccepted => _callAcceptedController.stream;
  Stream<void> get onCallRejected => _callRejectedController.stream;
  Stream<void> get onCallEnded => _callEndedController.stream;
  Stream<IncomingMessageEvent> get onIncomingMessage =>
      _incomingMessageController.stream;
  Stream<TypingEvent> get onTyping => _typingController.stream;

  // WebRTC signaling
  Stream<Map<String, dynamic>> get onRemoteOffer =>
      _remoteOfferController.stream;
  Stream<Map<String, dynamic>> get onRemoteAnswer =>
      _remoteAnswerController.stream;
  Stream<Map<String, dynamic>> get onRemoteIceCandidate =>
      _remoteIceCandidateController.stream;

  String get _baseUrl {
    final base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;
    return base;
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
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
      debugPrint(
          '📞 [CALL] ERREUR: Token null, impossible de se connecter au WebSocket');
      return;
    }
    debugPrint('📞 [CALL] Connexion WebSocket en cours...');
    final wsUrl = _baseUrl;
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
    _socket!
        .onDisconnect((_) => debugPrint('📞 [CALL] WebSocket déconnecté'));

    // ─── Call lifecycle events ───
    _socket!.on('call:incoming', (data) {
      debugPrint('📞 [CALL] call:incoming reçu: $data');
      if (data is Map) {
        final callerName = (data['fromUserName'] ?? 'Appelant').toString();
        final isVideo = data['isVideo'] == true;
        
        // Show local notification for visibility
        NotificationService().showIncomingCall(
          callerName: callerName,
          isVideo: isVideo,
        );

        _incomingCallController.add(IncomingCall(
          fromUserId: (data['fromUserId'] ?? '').toString(),
          fromUserName: callerName,
          channelId: (data['channelId'] ?? '').toString(),
          isVideo: isVideo,
        ));
      }
    });
    _socket!.on('call:accepted', (data) {
      final channelId =
          data is Map ? (data['channelId'] ?? '').toString() : '';
      debugPrint(
          '📞 [CALL] call:accepted reçu channelId=$channelId');
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

    // ─── WebRTC signaling events ───
    _socket!.on('webrtc:offer', (data) {
      debugPrint('📞 [WEBRTC] offer reçu');
      if (data is Map) {
        _remoteOfferController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('webrtc:answer', (data) {
      debugPrint('📞 [WEBRTC] answer reçu');
      if (data is Map) {
        _remoteAnswerController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('webrtc:ice-candidate', (data) {
      debugPrint('📞 [WEBRTC] ice-candidate reçu');
      if (data is Map) {
        _remoteIceCandidateController
            .add(Map<String, dynamic>.from(data));
      }
    });

    // ─── Chat message events ───
    _socket!.on('message:new', (data) {
      debugPrint('📞 [CALL] message:new reçu: $data');
      if (data is Map) {
        final senderName =
            (data['senderName'] ?? 'Quelqu\'un').toString();
        final senderId = (data['senderId'] ?? '').toString();
        final preview = (data['preview'] ?? '').toString();
        final text = data['text']?.toString();
        final attachmentUrl = data['attachmentUrl']?.toString();
        final attachmentType = data['attachmentType']?.toString();
        final callDurationRaw = data['callDuration'];
        final callDuration = callDurationRaw != null
            ? int.tryParse(callDurationRaw.toString())
            : null;
        final conversationId =
            (data['conversationId'] ?? '').toString();
        final messageIdRaw = data['messageId'];
        final createdAtRaw = data['createdAt'];
        final createdAt = createdAtRaw != null
            ? DateTime.tryParse(createdAtRaw.toString())
            : null;
        if (conversationId.isNotEmpty) {
          _incomingMessageController.add(
            IncomingMessageEvent(
              conversationId: conversationId,
              senderId: senderId,
              senderName: senderName,
              preview: preview,
              text: text,
              attachmentUrl: attachmentUrl,
              attachmentType: attachmentType,
              callDuration: callDuration,
              messageId: messageIdRaw?.toString(),
              createdAt: createdAt,
            ),
          );
        }
        _notificationsFeedService
            .createNotification(
              type: 'family_message',
              title: senderName,
              description:
                  preview.isNotEmpty ? preview : 'Nouveau message',
            )
            .catchError((e) {
          debugPrint('🔔 [NOTIF] Échec enregistrement feed notif: $e');
        });
        NotificationService().showNewMessage(
          senderName: senderName,
          preview: preview.isNotEmpty ? preview : 'Nouveau message',
        );
      }
    });

    _socket!.on('chat:typing', (data) {
      if (data is Map) {
        _typingController.add(TypingEvent(
          userId: (data['userId'] ?? '').toString(),
          conversationId: (data['conversationId'] ?? '').toString(),
          isTyping: data['isTyping'] == true,
        ));
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _userId = null;
  }

  // ─── Call lifecycle methods ───

  void initiateCall({
    required String targetUserId,
    required String channelId,
    required bool isVideo,
    required String callerName,
  }) {
    debugPrint(
        '📞 [CALL] initiateCall targetUserId=$targetUserId channelId=$channelId isVideo=$isVideo socketConnected=${_socket?.connected}');
    if (_socket?.connected != true) {
      debugPrint(
          '📞 [CALL] ERREUR: Socket non connecté, call:initiate non envoyé!');
    }
    _socket?.emit('call:initiate', {
      'targetUserId': targetUserId,
      'channelId': channelId,
      'isVideo': isVideo,
      'callerName': callerName,
    });
  }

  void acceptCall({required String fromUserId, required String channelId}) {
    debugPrint(
        '📞 [CALL] acceptCall fromUserId=$fromUserId channelId=$channelId socketConnected=${_socket?.connected}');
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
    if (kDebugMode) {
      debugPrint('📞 [CALL] endCall stack: ${StackTrace.current}');
    }
    _socket?.emit('call:end', {'targetUserId': targetUserId});
  }

  // ─── WebRTC signaling methods ───

  void sendOffer({
    required String targetUserId,
    required RTCSessionDescription sdp,
  }) {
    debugPrint('📞 [WEBRTC] sendOffer to=$targetUserId');
    _socket?.emit('webrtc:offer', {
      'targetUserId': targetUserId,
      'sdp': sdp.sdp,
      'type': sdp.type,
    });
  }

  void sendAnswer({
    required String targetUserId,
    required RTCSessionDescription sdp,
  }) {
    debugPrint('📞 [WEBRTC] sendAnswer to=$targetUserId');
    _socket?.emit('webrtc:answer', {
      'targetUserId': targetUserId,
      'sdp': sdp.sdp,
      'type': sdp.type,
    });
  }

  void sendIceCandidate({
    required String targetUserId,
    required RTCIceCandidate candidate,
  }) {
    _socket?.emit('webrtc:ice-candidate', {
      'targetUserId': targetUserId,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  void sendTypingStatus({
    required String targetUserId,
    required String conversationId,
    required bool isTyping,
  }) {
    _socket?.emit('chat:typing', {
      'targetUserId': targetUserId,
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }
}
