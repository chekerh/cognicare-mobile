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
  const CallConnectionHandler({super.key, required this.child});

  final Widget child;

  @override
  State<CallConnectionHandler> createState() => _CallConnectionHandlerState();
}

class _CallConnectionHandlerState extends State<CallConnectionHandler> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      if (auth.isAuthenticated && auth.user != null) {
        callProvider.connect(auth.user!.id);
      } else {
        callProvider.disconnect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Provider.of<CallProvider>(context),
      builder: (context, _) {
        final callProvider = Provider.of<CallProvider>(context, listen: false);
        final pending = callProvider.pendingIncoming;
        if (pending != null && context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callProvider.clearPendingIncoming();
            if (context.mounted) {
              context.push(
                AppConstants.callRoute,
                extra: {
                  'channelId': pending.channelId,
                  'remoteUserId': pending.fromUserId,
                  'remoteUserName': pending.fromUserName,
                  'isVideo': pending.isVideo,
                  'isIncoming': true,
                  'incomingCall': pending,
                },
              );
            }
          });
        }
        return widget.child;
      },
    );
  }
}
