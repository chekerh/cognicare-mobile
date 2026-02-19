import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../services/chat_service.dart';

// ─── Colors ──────────────────────────────────────────────────────────
const Color _primary = Color(0xFFA8DADC);
const Color _controlBg = Color(0xFF1E293B);
const Color _endCallRed = Color(0xFFEF4444);
const Color _acceptGreen = Color(0xFF22C55E);

// ─── ICE servers ────────────────────────────────────────────────────
const Map<String, dynamic> _iceServers = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ]
};

/// Call status states
enum CallStatus { ringing, connecting, connected, ended, failed }

/// Écran d'appel vocal ou vidéo — WebRTC peer-to-peer.
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

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late CallService _callService;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // State
  CallStatus _callStatus = CallStatus.ringing;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  String? _error;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _noAnswerTimer;

  // Subscriptions
  StreamSubscription? _acceptedSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;

  // PiP drag position
  Offset _pipOffset = const Offset(16, 80);

  // Pending ICE candidates (before remote description is set)
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _remoteDescriptionSet = false;

  // Animation for pulsing avatar
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isVideoEnabled = widget.isVideo;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _callService =
          Provider.of<CallProvider>(context, listen: false).service;
      _initRenderers().then((_) {
        if (widget.isIncoming && widget.incomingCall != null) {
          _listenForEnd();
          _listenForWebRTCSignaling();
        } else {
          _listenForResponse();
          _listenForEnd();
          _listenForWebRTCSignaling();
          _startNoAnswerTimer();
        }
      });
    });
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // ─── Signaling listeners ─────────────────────────────────────────

  void _listenForResponse() {
    _acceptedSub = _callService.onCallAccepted.listen((channelId) {
      debugPrint(
          '📞 [CALL_SCREEN] call:accepted channelId=$channelId');
      if (channelId == widget.channelId && mounted) {
        _noAnswerTimer?.cancel();
        _startWebRTCAsOffer();
      }
    });
    _rejectedSub = _callService.onCallRejected.listen((_) {
      if (mounted) {
        _addMissedCallMessage();
        setState(() => _callStatus = CallStatus.ended);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appel refusé')));
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    });
  }

  void _listenForEnd() {
    _endedSub = _callService.onCallEnded.listen((_) {
      if (mounted) _hangUp();
    });
  }

  void _listenForWebRTCSignaling() {
    _offerSub = _callService.onRemoteOffer.listen((data) async {
      debugPrint('📞 [CALL_SCREEN] Received offer');
      if (!mounted) return;
      try {
        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']),
        );
        _remoteDescriptionSet = true;
        // Drain pending ICE
        for (final c in _pendingIceCandidates) {
          await _peerConnection!.addCandidate(c);
        }
        _pendingIceCandidates.clear();

        // Create answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _callService.sendAnswer(
          targetUserId: widget.remoteUserId,
          sdp: answer,
        );
        if (mounted) setState(() => _callStatus = CallStatus.connecting);
      } catch (e) {
        debugPrint('📞 [CALL_SCREEN] Error handling offer: $e');
        if (mounted) setState(() => _error = e.toString());
      }
    });

    _answerSub = _callService.onRemoteAnswer.listen((data) async {
      debugPrint('📞 [CALL_SCREEN] Received answer');
      if (!mounted || _peerConnection == null) return;
      try {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']),
        );
        _remoteDescriptionSet = true;
        for (final c in _pendingIceCandidates) {
          await _peerConnection!.addCandidate(c);
        }
        _pendingIceCandidates.clear();
      } catch (e) {
        debugPrint('📞 [CALL_SCREEN] Error handling answer: $e');
      }
    });

    _iceSub = _callService.onRemoteIceCandidate.listen((data) async {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      if (_remoteDescriptionSet && _peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        _pendingIceCandidates.add(candidate);
      }
    });
  }

  // ─── WebRTC ──────────────────────────────────────────────────────

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;

    // Get user media
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': widget.isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    };

    _localStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

    // Create peer connection
    _peerConnection = await createPeerConnection(_iceServers);

    // Add local tracks
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // ICE candidate callback
    _peerConnection!.onIceCandidate = (candidate) {
      _callService.sendIceCandidate(
        targetUserId: widget.remoteUserId,
        candidate: candidate,
      );
    };

    // Remote stream
    _peerConnection!.onTrack = (event) {
      debugPrint('📞 [WEBRTC] onTrack: ${event.streams.length} streams');
      if (event.streams.isNotEmpty && mounted) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    // Connection state
    _peerConnection!.onConnectionState = (state) {
      debugPrint('📞 [WEBRTC] connectionState=$state');
      if (!mounted) return;
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          setState(() => _callStatus = CallStatus.connected);
          _startDurationTimer();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          setState(() {
            _callStatus = CallStatus.failed;
            _error = 'La connexion a échoué';
          });
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          if (_callStatus == CallStatus.connected) {
            _hangUp();
          }
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('📞 [WEBRTC] iceConnectionState=$state');
    };

    if (mounted) setState(() {});
  }

  Future<void> _startWebRTCAsOffer() async {
    try {
      setState(() => _callStatus = CallStatus.connecting);
      await _createPeerConnection();
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _callService.sendOffer(
        targetUserId: widget.remoteUserId,
        sdp: offer,
      );
    } catch (e) {
      debugPrint('📞 [CALL_SCREEN] Error creating offer: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _callStatus = CallStatus.failed;
        });
      }
    }
  }

  // ─── Call actions ────────────────────────────────────────────────

  Future<void> _acceptCall() async {
    if (widget.incomingCall == null) return;
    debugPrint('📞 [CALL_SCREEN] Accepting call');
    _callService.acceptCall(
      fromUserId: widget.incomingCall!.fromUserId,
      channelId: widget.channelId,
    );
    setState(() => _callStatus = CallStatus.connecting);
    // Wait for the caller to send the WebRTC offer
  }

  void _rejectCall() {
    if (widget.incomingCall != null) {
      _callService.rejectCall(widget.incomingCall!.fromUserId);
    }
    context.pop();
  }

  void _hangUp() {
    _callService.endCall(widget.remoteUserId);
    _cleanup();
    if (mounted) {
      setState(() => _callStatus = CallStatus.ended);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = _isMuted; // toggle
      }
      setState(() => _isMuted = !_isMuted);
    }
  }

  void _toggleVideo() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.enabled = !_isVideoEnabled;
      }
      setState(() => _isVideoEnabled = !_isVideoEnabled);
    }
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    // flutter_webrtc handles speaker via helper
    if (_localStream != null) {
      Helper.setSpeakerphoneOn(_isSpeakerOn);
    }
  }

  Future<void> _switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
        setState(() => _isFrontCamera = !_isFrontCamera);
      }
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration += const Duration(seconds: 1));
    });
  }

  void _startNoAnswerTimer() {
    _noAnswerTimer?.cancel();
    if (widget.isIncoming) return;
    _noAnswerTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) return;
      _addMissedCallMessage();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pas de réponse')));
      _hangUp();
    });
  }

  Future<void> _addMissedCallMessage() async {
    try {
      final auth =
          Provider.of<AuthProvider>(context, listen: false);
      if (auth.user == null || widget.remoteUserId.isEmpty) return;
      final chatService = ChatService(
        getToken: () async =>
            auth.accessToken ?? await AuthService().getStoredToken(),
      );
      final conv =
          await chatService.getOrCreateConversation(widget.remoteUserId);
      final text =
          widget.isVideo ? 'Appel vidéo manqué' : 'Appel vocal manqué';
      await chatService.sendMessage(
        conv.id,
        text,
        attachmentType: 'call_missed',
      );
    } catch (_) {}
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _noAnswerTimer?.cancel();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _peerConnection?.close();
    _peerConnection = null;
    _remoteDescriptionSet = false;
    _pendingIceCandidates.clear();
  }

  @override
  void dispose() {
    _noAnswerTimer?.cancel();
    _durationTimer?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    _pulseController.dispose();
    _cleanup();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // ─── BUILD ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: _error != null && _callStatus == CallStatus.failed
            ? _buildError()
            : widget.isIncoming &&
                    widget.incomingCall != null &&
                    _callStatus == CallStatus.ringing
                ? _buildIncomingUI()
                : _buildCallUI(),
      ),
    );
  }

  // ─── Error UI ──────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _endCallRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.call_end, color: _endCallRed, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Échec de la connexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: const Color(0xFF0F172A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Incoming call UI ────────────────────────────────────────────

  Widget _buildIncomingUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Pulsing avatar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + _pulseController.value * 0.08;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primary.withOpacity(0.3),
                        _primary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: _primary.withOpacity(0.4),
                      child: Text(
                        widget.remoteUserName.isNotEmpty
                            ? widget.remoteUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            widget.remoteUserName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isVideo ? 'Appel vidéo entrant...' : 'Appel vocal entrant...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const Spacer(flex: 3),
          // Accept / Reject buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallActionButton(
                  icon: Icons.call_end,
                  color: _endCallRed,
                  label: 'Refuser',
                  onTap: _rejectCall,
                ),
                _buildCallActionButton(
                  icon: widget.isVideo ? Icons.videocam : Icons.call,
                  color: _acceptGreen,
                  label: 'Accepter',
                  onTap: _acceptCall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ─── Active call UI ──────────────────────────────────────────────

  Widget _buildCallUI() {
    final isVideoCall = widget.isVideo;
    final hasRemoteVideo = _remoteRenderer.srcObject != null &&
        _callStatus == CallStatus.connected;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (isVideoCall && hasRemoteVideo)
          // Remote video fullscreen
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          // Gradient background for audio call or when connecting
          _buildAudioCallBackground(),

        // Top bar with status
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),

        // Local video PiP (draggable)
        if (isVideoCall && _localStream != null)
          Positioned(
            left: _pipOffset.dx,
            top: _pipOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pipOffset += details.delta;
                });
              },
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isVideoEnabled
                      ? RTCVideoView(
                          _localRenderer,
                          mirror: _isFrontCamera,
                          objectFit: RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitCover,
                        )
                      : Container(
                          color: _controlBg,
                          child: const Center(
                            child: Icon(Icons.videocam_off,
                                color: Colors.white54, size: 32),
                          ),
                        ),
                ),
              ),
            ),
          ),

        // Bottom control bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildControlBar(),
        ),
      ],
    );
  }

  Widget _buildAudioCallBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _callStatus == CallStatus.connected
                    ? 1.0
                    : 1.0 + _pulseController.value * 0.06;
                return Transform.scale(
                  scale: scale,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: _primary.withOpacity(0.3),
                    child: Text(
                      widget.remoteUserName.isNotEmpty
                          ? widget.remoteUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.remoteUserName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _statusText {
    switch (_callStatus) {
      case CallStatus.ringing:
        return 'Appel en cours...';
      case CallStatus.connecting:
        return 'Connexion...';
      case CallStatus.connected:
        return _formatDuration(_callDuration);
      case CallStatus.ended:
        return 'Appel terminé';
      case CallStatus.failed:
        return 'Échec de la connexion';
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _hangUp(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _callStatus == CallStatus.connected
                            ? _acceptGreen
                            : _callStatus == CallStatus.failed
                                ? _endCallRed
                                : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _callStatus == CallStatus.connected
                          ? _formatDuration(_callDuration)
                          : _statusText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.isVideo && _callStatus == CallStatus.connected)
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch_rounded,
                  color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Son off' : 'Micro',
            isActive: !_isMuted,
            onTap: _toggleMute,
          ),
          if (widget.isVideo)
            _controlButton(
              icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              label: _isVideoEnabled ? 'Caméra' : 'Cam off',
              isActive: _isVideoEnabled,
              onTap: _toggleVideo,
            ),
          _controlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
            label: _isSpeakerOn ? 'HP' : 'Écouteur',
            isActive: _isSpeakerOn,
            onTap: _toggleSpeaker,
          ),
          // End call
          GestureDetector(
            onTap: _hangUp,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: _endCallRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40EF4444),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.call_end, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
