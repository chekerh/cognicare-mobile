import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../widgets/chat_message_bar.dart';

const Color _primary = Color(0xFF77B5D1);
const Color _bgSoft = Color(0xFFEEF7FB);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);

class _Msg {
  final String text;
  final bool isMe;
  final String time;
  final bool read;
  final String? attachmentUrl;
  final String? attachmentType;
  final int? callDuration;

  const _Msg({
    required this.text,
    required this.isMe,
    required this.time,
    this.read = false,
    this.attachmentUrl,
    this.attachmentType,
    this.callDuration,
  });
}

/// Conversation bénévole avec une famille — header (famille + mission), bulles, barre de saisie.
class VolunteerFamilyChatScreen extends StatefulWidget {
  const VolunteerFamilyChatScreen({
    super.key,
    required this.familyId,
    required this.familyName,
    required this.missionType,
    this.conversationId,
  });

  final String familyId;
  final String familyName;
  final String missionType;

  /// When set, messages are loaded/sent with this conversation (no getOrCreateConversation).
  final String? conversationId;

  static VolunteerFamilyChatScreen fromState(GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    return VolunteerFamilyChatScreen(
      familyId: extra?['familyId'] as String? ?? '',
      familyName: extra?['familyName'] as String? ?? 'Famille',
      missionType: extra?['missionType'] as String? ?? 'Mission',
      conversationId: extra?['conversationId'] as String?,
    );
  }

  @override
  State<VolunteerFamilyChatScreen> createState() =>
      _VolunteerFamilyChatScreenState();
}

class _VolunteerFamilyChatScreenState extends State<VolunteerFamilyChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<_Msg> _messages;
  String? _conversationId;
  bool _loading = false;
  String? _loadError;
  bool _sending = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _currentRecordPath;
  String? _playingVoiceUrl;
  StreamSubscription<IncomingMessageEvent>? _incomingMessageSub;
  StreamSubscription<TypingEvent>? _typingSub;
  bool _isRemoteTyping = false;
  Timer? _typingTimer;
  Timer? _remoteTypingTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingVoiceUrl = null);
    });
    _messages = [];
    _bindIncomingMessageEvents();
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      _conversationId = widget.conversationId;
      _loadMessagesDirect();
    } else if (widget.familyId.isNotEmpty) {
      _resolveAndLoadMessages();
    } else {
      _messages = _defaultMessages();
    }
  }

  void _bindIncomingMessageEvents() {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    _incomingMessageSub?.cancel();
    _incomingMessageSub = callProvider.service.onIncomingMessage.listen((evt) {
      if (!mounted) return;
      final cid = _conversationId;
      if (cid == null || cid.isEmpty) return;
      if (evt.conversationId != cid) {
        debugPrint(
            '💬 [VOLUNTEER_CHAT] Event conversationId mismatch: ${evt.conversationId} != $cid');
        return;
      }
      debugPrint(
          '💬 [VOLUNTEER_CHAT] Real-time message received, reloading...');
      _loadMessagesDirect(silent: true);
    });

    _typingSub?.cancel();
    _typingSub = callProvider.service.onTyping.listen((evt) {
      if (!mounted) return;
      if (evt.conversationId != _conversationId ||
          evt.userId != widget.familyId) {
        return;
      }

      setState(() => _isRemoteTyping = evt.isTyping);

      _remoteTypingTimer?.cancel();
      if (evt.isTyping) {
        _remoteTypingTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _isRemoteTyping = false);
        });
      }
    });
  }

  Future<void> _loadMessagesDirect({bool silent = false}) async {
    final cid = _conversationId;
    if (cid == null) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = auth.user?.id;
      if (currentUserId == null) {
        setState(() {
          _loading = false;
          _loadError = 'Non connecté';
        });
        return;
      }
      final chatService = ChatService();
      final list = await chatService.getMessages(cid);
      if (!mounted) return;
      setState(() {
        _messages = list.map((m) {
          final isMe = m.senderId == currentUserId;
          return _Msg(
            text: m.text,
            isMe: isMe,
            time: _formatTime(m.createdAt),
            read: false,
            attachmentUrl: m.attachmentUrl,
            attachmentType: m.attachmentType,
            callDuration: m.callDuration,
          );
        }).toList();
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _resolveAndLoadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = auth.user?.id;
      if (currentUserId == null) {
        setState(() {
          _loading = false;
          _loadError = 'Non connecté';
        });
        return;
      }
      final chatService = ChatService();
      final conv = await chatService.getOrCreateConversation(widget.familyId);
      if (!mounted) return;
      _conversationId = conv.id;
      final list = await chatService.getMessages(conv.id);
      if (!mounted) return;
      setState(() {
        _messages = list.map((m) {
          final isMe = m.senderId == currentUserId;
          return _Msg(
            text: m.text,
            isMe: isMe,
            time: _formatTime(m.createdAt),
            read: false,
            attachmentUrl: m.attachmentUrl,
            attachmentType: m.attachmentType,
            callDuration: m.callDuration,
          );
        }).toList();
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<_Msg> _defaultMessages() {
    return [
      const _Msg(
        text:
            "Bonjour Lucas ! Merci beaucoup d'avoir accepté notre mission. Seriez-vous disponible vers 14h30 ?",
        isMe: false,
        time: '10:15',
      ),
      const _Msg(
        text:
            "Bonjour ! Oui, c'est parfait pour moi. J'ai bien noté l'adresse au 12 Rue des Lilas.",
        isMe: true,
        time: '10:18',
        read: true,
      ),
      const _Msg(
        text:
            "C'est parfait. Je vous laisserai la liste sur la table de l'entrée. À tout à l'heure !",
        isMe: false,
        time: '10:20',
      ),
    ];
  }

  @override
  void dispose() {
    _incomingMessageSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _remoteTypingTimer?.cancel();
    _recordingTimer?.cancel();
    if (_isRecording) _recorder.stop().ignore();
    _recorder.dispose();
    _audioPlayer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playVoiceMessage(_Msg msg) async {
    if (msg.attachmentUrl == null) return;
    final url = AppConstants.fullImageUrl(msg.attachmentUrl!);
    if (_playingVoiceUrl == msg.attachmentUrl) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _playingVoiceUrl = null);
      return;
    }
    void onVoiceError() {
      if (mounted) {
        setState(() => _playingVoiceUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire le message vocal')),
        );
      }
    }

    runZonedGuarded(() {
      _audioPlayer.play(UrlSource(url, mimeType: 'audio/mp4')).then((_) {
        if (mounted) setState(() => _playingVoiceUrl = msg.attachmentUrl);
      }).catchError((e, st) {
        onVoiceError();
        return null;
      });
    }, (error, stack) => onVoiceError());
  }

  Future<void> _onVoiceTap() async {
    if (_conversationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation non chargée')));
      }
      return;
    }
    if (_isRecording) {
      await _stopRecordingAndSend();
      return;
    }
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autorisez l\'accès au micro.')));
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      _currentRecordPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _currentRecordPath!);
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      final path = await _recorder.stop();
      final voicePath = path ?? _currentRecordPath;
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _currentRecordPath = null;
      });
      if (voicePath != null && File(voicePath).existsSync()) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final chatService = ChatService();
        setState(() => _sending = true);
        try {
          final url =
              await chatService.uploadAttachment(File(voicePath), 'voice');
          await chatService.sendMessage(_conversationId!, 'Message vocal',
              attachmentUrl: url, attachmentType: 'voice');
          if (!mounted) return;
          setState(() {
            _messages.add(_Msg(
                text: 'Message vocal',
                isMe: true,
                time: _formatTime(DateTime.now()),
                attachmentType: 'voice',
                attachmentUrl: url));
            _sending = false;
          });
        } catch (e) {
          if (mounted) {
            setState(() => _sending = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', ''))));
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _onPhotoTap() async {
    if (_conversationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation non chargée')));
      }
      return;
    }
    try {
      final XFile? picked =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chatService = ChatService();
      setState(() => _sending = true);
      try {
        final url =
            await chatService.uploadAttachment(File(picked.path), 'image');
        await chatService.sendMessage(_conversationId!, 'Photo',
            attachmentUrl: url, attachmentType: 'image');
        if (!mounted) return;
        setState(() {
          _messages.add(_Msg(
              text: 'Photo',
              isMe: true,
              time: _formatTime(DateTime.now()),
              attachmentType: 'image',
              attachmentUrl: url));
          _sending = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() => _sending = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''))));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _onTypingChanged() {
    if (_conversationId == null) return;
    _typingTimer?.cancel();

    // Emit "typing" status
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.service.sendTypingStatus(
      targetUserId: widget.familyId,
      conversationId: _conversationId!,
      isTyping: _controller.text.isNotEmpty,
    );

    // Stop typing after 2s of inactivity
    if (_controller.text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          callProvider.service.sendTypingStatus(
            targetUserId: widget.familyId,
            conversationId: _conversationId!,
            isTyping: false,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final cid = _conversationId;
    if (cid != null) {
      setState(() => _sending = true);
      final optimistic = _Msg(
        text: text,
        isMe: true,
        time: _formatTime(DateTime.now()),
      );
      setState(() => _messages.add(optimistic));
      _controller.clear();
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final chatService = ChatService();
        await chatService.sendMessage(cid, text);
        if (!mounted) return;
        setState(() => _sending = false);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _messages.remove(optimistic);
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } else {
      setState(() {
        _messages.add(_Msg(
          text: text,
          isMe: true,
          time: _formatTime(DateTime.now()),
        ));
      });
      _controller.clear();
    }
  }

  String _formatTime(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            left: true,
            right: true,
            child: _buildHeader(context),
          ),
          Expanded(
            child: Container(
              color: _bgSoft,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_loadError!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    if (widget.conversationId != null) {
                                      _loadMessagesDirect();
                                    } else {
                                      _resolveAndLoadMessages();
                                    }
                                  },
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            left: 16 + padding.left,
                            right: 16 + padding.right,
                            top: 24,
                            bottom: 24,
                          ),
                          children: [
                            _buildDateSeparator(),
                            const SizedBox(height: 24),
                            ..._messages.map((m) => _buildBubble(m)),
                            if (_isRemoteTyping) _buildTypingIndicator(),
                          ],
                        ),
            ),
          ),
          ChatMessageBar(
            controller: _controller,
            onSend: _sendMessage,
            hintText: 'Votre message...',
            sending: _sending,
            onVoiceTap: _onVoiceTap,
            onPhotoTap: _onPhotoTap,
            isRecording: _isRecording,
            recordingDuration: _recordingDuration,
            onChanged: (val) => _onTypingChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            style: IconButton.styleFrom(foregroundColor: _textPrimary),
          ),
          const SizedBox(width: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group, color: _textMuted, size: 22),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(_missionIcon(widget.missionType),
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.familyName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary),
                ),
                Text(
                  'Mission : ${widget.missionType}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _initiateCall(context, false),
            icon: const Icon(Icons.call, color: _textMuted, size: 26),
          ),
          IconButton(
            onPressed: () => _initiateCall(context, true),
            icon: const Icon(Icons.videocam_outlined,
                color: _textMuted, size: 26),
          ),
        ],
      ),
    );
  }

  void _initiateCall(BuildContext context, bool isVideo) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caller = auth.user;
    if (caller == null) {
      debugPrint(
          '📞 [VOLUNTEER_CHAT] Appel impossible: utilisateur non connecté');
      return;
    }
    if (widget.familyId.isEmpty) {
      debugPrint('📞 [VOLUNTEER_CHAT] Appel impossible: familyId vide');
      return;
    }
    debugPrint(
        '📞 [VOLUNTEER_CHAT] Initiation appel vers familyId=${widget.familyId} isVideo=$isVideo');
    final ids = [caller.id, widget.familyId]..sort();
    final channelId =
        'call_${ids[0]}_${ids[1]}_${DateTime.now().millisecondsSinceEpoch}';
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.service.initiateCall(
      targetUserId: widget.familyId,
      channelId: channelId,
      isVideo: isVideo,
      callerName: caller.fullName,
    );
    context.push(AppConstants.callRoute, extra: {
      'channelId': channelId,
      'remoteUserId': widget.familyId,
      'remoteUserName': widget.familyName,
      'remoteImageUrl': null,
      'isVideo': isVideo,
      'isIncoming': false,
    });
  }

  Widget _buildDateSeparator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          "AUJOURD'HUI",
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted),
        ),
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) _avatar(),
          if (!msg.isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: msg.isMe ? _primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                      bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: msg.attachmentType == 'image' &&
                          msg.attachmentUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            AppConstants.fullImageUrl(msg.attachmentUrl!),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200,
                              height: 200,
                              color: msg.isMe ? Colors.white12 : _bgSoft,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported,
                                      size: 48,
                                      color: msg.isMe
                                          ? Colors.white70
                                          : _textMuted),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: msg.isMe
                                            ? Colors.white70
                                            : _textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : msg.attachmentType == 'voice'
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: msg.attachmentUrl != null
                                    ? () => _playVoiceMessage(msg)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _playingVoiceUrl == msg.attachmentUrl
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color:
                                            msg.isMe ? Colors.white : _primary,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.mic,
                                          color: msg.isMe
                                              ? Colors.white70
                                              : _textMuted,
                                          size: 22),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Message vocal',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: msg.isMe
                                                ? Colors.white
                                                : _textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : msg.attachmentType == 'call_missed'
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.call_missed,
                                          color: msg.isMe
                                              ? Colors.white70
                                              : Colors.red.shade400,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Appel manqué',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: msg.isMe
                                                  ? Colors.white
                                                  : _textPrimary,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.text, // "Appel vocal" or "Appel vidéo"
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: msg.isMe
                                            ? Colors.white70
                                            : _textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => _initiateCall(
                                          context, msg.text.contains('vidéo')),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        backgroundColor: msg.isMe
                                            ? Colors.white24
                                            : Colors.grey.shade100,
                                      ),
                                      child: Text('Rappeler',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: msg.isMe
                                                  ? Colors.white
                                                  : _primary)),
                                    ),
                                  ],
                                )
                              : msg.attachmentType == 'call_summary'
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              msg.text.contains('vidéo')
                                                  ? Icons.videocam
                                                  : Icons.call,
                                              color: msg.isMe
                                                  ? Colors.white70
                                                  : _primary,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              msg.text.startsWith('Appel ')
                                                  ? msg.text
                                                  : 'Transcription de l\'appel',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: msg.isMe
                                                    ? Colors.white
                                                    : _textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!msg.text.startsWith('Appel ')) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            msg.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: msg.isMe
                                                  ? Colors.white
                                                      .withOpacity(0.9)
                                                  : _textPrimary
                                                      .withOpacity(0.8),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        if (msg.callDuration != null &&
                                            msg.callDuration! > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDuration(msg.callDuration!),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: msg.isMe
                                                  ? Colors.white70
                                                  : _textMuted,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => _initiateCall(
                                              context,
                                              msg.text.contains('vidéo')),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            backgroundColor: msg.isMe
                                                ? Colors.white24
                                                : Colors.grey.shade100,
                                          ),
                                          child: Text('Rappeler',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: msg.isMe
                                                      ? Colors.white
                                                      : _primary)),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      msg.text,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: msg.isMe
                                              ? Colors.white
                                              : _textPrimary,
                                          height: 1.4),
                                    ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: msg.isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!msg.isMe) const SizedBox(width: 8),
                    Text(
                      msg.time,
                      style: const TextStyle(fontSize: 10, color: _textMuted),
                    ),
                    if (msg.isMe && msg.read) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: _primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (msg.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  static IconData _missionIcon(String type) {
    if (type.toLowerCase().contains('course') ||
        type.toLowerCase().contains('proximité')) {
      return Icons.shopping_basket;
    }
    if (type.toLowerCase().contains('lecture') ||
        type.toLowerCase().contains('compagnie')) {
      return Icons.menu_book;
    }
    if (type.toLowerCase().contains('accompagnement') ||
        type.toLowerCase().contains('extérieur')) {
      return Icons.directions_walk;
    }
    return Icons.volunteer_activism;
  }

  Widget _avatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 18, color: _textMuted),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return "";
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins min et $secs s';
    } else {
      return '$secs s';
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _avatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'En train d\'écrire...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
