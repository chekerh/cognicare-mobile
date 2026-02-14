import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA8DADC);

/// Écran d'appel vocal ou vidéo (Agora RTC).
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
  final CallService _callService = CallService();
  RtcEngine? _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _speakerOn = true;
  bool _videoEnabled = true;
  String? _error;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;

  @override
  void initState() {
    super.initState();
    if (widget.isIncoming && widget.incomingCall != null) {
      _listenForEnd();
    } else {
      _listenForResponse();
      _joinChannel();
    }
  }

  void _listenForResponse() {
    _acceptedSub = _callService.onCallAccepted.listen((channelId) {
      if (channelId == widget.channelId && mounted) {
        _joinChannel();
      }
    });
    _rejectedSub = _callService.onCallRejected.listen((_) {
      if (mounted) {
        _showSnack('Appel refusé');
        context.pop();
      }
    });
  }

  void _listenForEnd() {
    _endedSub = _callService.onCallEnded.listen((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _joinChannel() async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');
      final resp = await _callService.getRtcToken(
        channel: widget.channelId,
        uid: userId,
      );
      if (resp.appId.isEmpty) {
        throw Exception('Agora non configuré. Configurez AGORA_APP_ID sur le backend.');
      }
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: resp.appId));
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      if (widget.isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
      }
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) setState(() => _joined = true);
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            if (mounted) setState(() => _remoteUid = uid);
          },
          onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
            if (mounted) setState(() => _remoteUid = null);
          },
          onError: (ErrorCodeType err, String msg) {
            if (mounted) setState(() => _error = msg);
          },
        ),
      );
      await _engine!.joinChannelWithUserAccount(
        token: resp.token,
        channelId: widget.channelId,
        userAccount: userId,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _acceptCall() async {
    if (widget.incomingCall == null) return;
    _callService.acceptCall(
      fromUserId: widget.incomingCall!.fromUserId,
      channelId: widget.channelId,
    );
    _endedSub?.cancel();
    _listenForEnd();
    await _joinChannel();
  }

  void _rejectCall() {
    if (widget.incomingCall != null) {
      _callService.rejectCall(widget.incomingCall!.fromUserId);
    }
    context.pop();
  }

  void _endCall() {
    _callService.endCall(widget.remoteUserId);
    _engine?.leaveChannel();
    _engine?.release();
    context.pop();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
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
                : _buildCallUI(),
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
            _circleButton(
              icon: Icons.call_end,
              color: Colors.red,
              onTap: _rejectCall,
            ),
            _circleButton(
              icon: Icons.call,
              color: Colors.green,
              onTap: _acceptCall,
            ),
          ],
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildCallUI() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.isVideo)
          _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: _remoteUid!),
                    connection: RtcConnection(channelId: widget.channelId),
                  ),
                )
              : Center(
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
                      const SizedBox(height: 16),
                      Text(
                        _joined ? 'Appel en cours...' : 'Connexion...',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                )
        else
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
                Text(
                  _joined ? 'En communication' : 'Connexion...',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        if (widget.isVideo && _joined)
          Positioned(
            top: 16,
            left: 16,
            child: SizedBox(
              width: 120,
              height: 160,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleButton(
                icon: _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? Colors.red : Colors.white24,
                onTap: () async {
                  await _engine?.muteLocalAudioStream(_muted ? false : true);
                  setState(() => _muted = !_muted);
                },
              ),
              if (widget.isVideo)
                _circleButton(
                  icon: _videoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: _videoEnabled ? Colors.white24 : Colors.red,
                  onTap: () async {
                    await _engine?.muteLocalVideoStream(_videoEnabled ? true : false);
                    setState(() => _videoEnabled = !_videoEnabled);
                  },
                ),
              _circleButton(
                icon: Icons.call_end,
                color: Colors.red,
                onTap: _endCall,
              ),
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
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
