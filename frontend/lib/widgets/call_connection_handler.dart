import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../services/call_service.dart';
import '../utils/constants.dart';

/// Connects CallProvider on login, disconnects on logout, and navigates
/// to CallScreen when an incoming call is received.
class CallConnectionHandler extends StatefulWidget {
  const CallConnectionHandler({super.key, required this.child, this.router});

  final Widget child;
  final GoRouter? router;

  @override
  State<CallConnectionHandler> createState() => _CallConnectionHandlerState();
}

class _CallConnectionHandlerState extends State<CallConnectionHandler> {
  String? _connectedUserId;
  StreamSubscription<IncomingCall>? _incomingSub;
  late CallProvider _callProvider;

  @override
  void initState() {
    super.initState();
    _callProvider = Provider.of<CallProvider>(context, listen: false);
    // Attach listener once and keep it active
    _incomingSub = _callProvider.service.onIncomingCall.listen(_handleIncomingCall);
  }

  void _handleIncomingCall(IncomingCall call) {
    if (!mounted) return;
    debugPrint(
        '📞 [CALL_HANDLER] Appel entrant reçu! fromUserId=${call.fromUserId} fromUserName=${call.fromUserName} channelId=${call.channelId}');
    
    // Store pending for UI
    _callProvider.setPendingIncoming(call);
    
    // Navigate to call screen after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _callProvider.clearPendingIncoming();
      debugPrint('📞 [CALL_HANDLER] Navigation vers écran d\'appel...');
      final r = widget.router;
      if (r != null) {
        r.push(
          AppConstants.callRoute,
          extra: {
            'channelId': call.channelId,
            'remoteUserId': call.fromUserId,
            'remoteUserName': call.fromUserName,
            'isVideo': call.isVideo,
            'isIncoming': true,
            'incomingCall': call,
          },
        );
      } else {
        context.push(
          AppConstants.callRoute,
          extra: {
            'channelId': call.channelId,
            'remoteUserId': call.fromUserId,
            'remoteUserName': call.fromUserName,
            'isVideo': call.isVideo,
            'isIncoming': true,
            'incomingCall': call,
          },
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isAuthenticated && auth.user != null) {
      final uid = auth.user!.id;
      if (_connectedUserId != uid) {
        _connectedUserId = uid;
        debugPrint(
            '📞 [CALL_HANDLER] Utilisateur connecté, connexion WebSocket userId=$uid');
        
        // Wrap in post-frame to avoid build exceptions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _connectedUserId == uid) {
            _callProvider.connect(uid);
          }
        });
      }
    } else if (_connectedUserId != null) {
      debugPrint(
          '📞 [CALL_HANDLER] Utilisateur déconnecté, déconnexion WebSocket');
      final lastId = _connectedUserId;
      _connectedUserId = null;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only disconnect if we are still logged out
        if (mounted && _connectedUserId == null) {
          _callProvider.disconnect();
        }
      });
    }
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
