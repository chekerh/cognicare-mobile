import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/call_service.dart';
import '../services/notification_service.dart';

class CallProvider with ChangeNotifier {
  final CallService _service = CallService();
  IncomingCall? _pendingIncoming;

  IncomingCall? get pendingIncoming => _pendingIncoming;

  CallService get service => _service;

  void connect(String userId) {
    _service.connect(userId);
  }

  void disconnect() {
    _service.disconnect();
    _pendingIncoming = null;
    notifyListeners();
  }

  void setPendingIncoming(IncomingCall call) {
    NotificationService().showIncomingCall(
      callerName: call.fromUserName,
      isVideo: call.isVideo,
    );
    _pendingIncoming = call;
    notifyListeners();
  }

  void clearPendingIncoming() {
    _pendingIncoming = null;
    notifyListeners();
  }
}
