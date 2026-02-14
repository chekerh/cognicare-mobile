import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../services/chat_service.dart';

const Color _primary = Color(0xFFA8DADC);

/// Écran d'appel vocal ou vidéo (Jitsi Meet - gratuit, open source).
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.channelId,
    required this.remoteUserId,
    required this.remoteUserName,
    required this.remoteImageUrl,
    required this.isVideo,
    required this.isIncoming,
    this.incomingCall,
  });

  final String channelId;
  final String remoteUserId;
  final String remoteUserName;
  final String? remoteImageUrl;
  final bool isVideo;
  final bool isIncoming;
  final IncomingCall? incomingCall;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late CallService _callService;
  JitsiMeet? _jitsiMeet;
  bool _joined = false;
  bool _muted = false;
  bool _videoEnabled = true;
  String? _error;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;
  Timer? _noAnswerTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _callService = Provider.of<CallProvider>(context, listen: false).service;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isIncoming && widget.incomingCall != null) {
        _listenForEnd();
      } else {
        _listenForResponse();
        _joinCall();
      }
    });
  }

  void _listenForResponse() {
    _acceptedSub = _callService.onCallAccepted.listen((channelId) {
      if (channelId == widget.channelId && mounted) _joinCall();
    });
    _rejectedSub = _callService.onCallRejected.listen((_) {
      if (mounted) {
        _addMissedCallMessage();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appel refusé')));
        context.pop();
      }
    });
  }

  void _listenForEnd() {
    _endedSub = _callService.onCallEnded.listen((_) {
      if (mounted) context.pop();
    });
  }

  void _startNoAnswerTimer() {
    _noAnswerTimer?.cancel();
    if (widget.isIncoming) return;
    _noAnswerTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) return;
      if (_joined) return;
      _noAnswerTimer?.cancel();
      _addMissedCallMessage();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pas de réponse')));
      context.pop();
    });
  }

  Future<void> _joinCall() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userName = auth.user?.fullName ?? auth.user?.email ?? 'Utilisateur';
      final roomName = CallService.jitsiRoomName(widget.channelId);

      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: roomName,
        userInfo: JitsiMeetUserInfo(
          displayName: userName,
          email: '',
        ),
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': !widget.isVideo,
          'subject': widget.isVideo ? 'Appel vidéo CogniCare' : 'Appel vocal CogniCare',
        },
        featureFlags: {
          'unsaferoomwarning.enabled': false,
        },
      );

      final listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          if (mounted) setState(() => _joined = true);
          if (!widget.isIncoming) _noAnswerTimer?.cancel();
        },
        participantJoined: (email, name, role, participantId) {
          if (mounted) _noAnswerTimer?.cancel();
        },
        conferenceTerminated: (url, error) {
          if (mounted) _onCallEnded();
        },
        readyToClose: () {
          if (mounted) _onCallEnded();
        },
      );

      _jitsiMeet = JitsiMeet();
      _jitsiMeet!.join(options, listener);

      if (mounted && !widget.isIncoming) _startNoAnswerTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onCallEnded() {
    _callService.endCall(widget.remoteUserId);
    _noAnswerTimer?.cancel();
    if (mounted) context.pop();
  }

  Future<void> _addMissedCallMessage() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user == null || widget.remoteUserId.isEmpty) return;
      final chatService = ChatService(
        getToken: () async => auth.accessToken ?? await AuthService().getStoredToken(),
      );
      final conv = await chatService.getOrCreateConversation(widget.remoteUserId);
      final text = widget.isVideo ? 'Appel vidéo manqué' : 'Appel vocal manqué';
      await chatService.sendMessage(
        conv.id,
        text,
        attachmentType: 'call_missed',
      );
    } catch (_) {}
  }

  Future<void> _acceptCall() async {
    if (widget.incomingCall == null) return;
    _callService.acceptCall(
      fromUserId: widget.incomingCall!.fromUserId,
      channelId: widget.channelId,
    );
    _endedSub?.cancel();
    _listenForEnd();
    await _joinCall();
  }

  void _rejectCall() {
    if (widget.incomingCall != null) {
      _callService.rejectCall(widget.incomingCall!.fromUserId);
    }
    context.pop();
  }

  void _endCall() {
    _callService.endCall(widget.remoteUserId);
    _jitsiMeet?.hangUp();
    _noAnswerTimer?.cancel();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _noAnswerTimer?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _jitsiMeet?.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _error != null
            ? _buildError()
            : widget.isIncoming && widget.incomingCall != null && !_joined
                ? _buildIncomingUI()
                : _buildJoiningOrCallUI(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => context.pop(), child: const Text('Fermer')),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        CircleAvatar(
          radius: 60,
          backgroundColor: _primary.withOpacity(0.3),
          child: Text(
            widget.remoteUserName.isNotEmpty ? widget.remoteUserName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 48, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.remoteUserName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          widget.isVideo ? 'Appel vidéo entrant' : 'Appel vocal entrant',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _circleButton(icon: Icons.call_end, color: Colors.red, onTap: _rejectCall),
            _circleButton(icon: Icons.call, color: Colors.green, onTap: _acceptCall),
          ],
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildJoiningOrCallUI() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: _primary.withOpacity(0.3),
                child: Text(
                  widget.remoteUserName.isNotEmpty ? widget.remoteUserName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.remoteUserName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _joined ? 'Réunion Jitsi en cours...' : 'Connexion à la réunion...',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleButton(icon: Icons.call_end, color: Colors.red, onTap: _endCall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
