import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../utils/theme.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../widgets/chat_message_bar.dart';

/// Chat privé 1-on-1 — design Private Community Chat.
/// Header: back, avatar (avec point vert Online), nom, statut, vidéo, info.
/// Bulles: entrantes (blanc, gauche + avatar), sortantes (bleu, droite).
const Color _primary = Color(0xFFA8DADC);
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

/// Écran de conversation privée avec une personne.
/// Si [conversationId] est fourni, charge et envoie les messages via l'API.
class FamilyPrivateChatScreen extends StatefulWidget {
  const FamilyPrivateChatScreen({
    super.key,
    required this.personId,
    required this.personName,
    this.personImageUrl,
    this.conversationId,
  });

  final String personId;
  final String personName;
  final String? personImageUrl;
  /// When set, messages are loaded and sent via API.
  final String? conversationId;

  @override
  State<FamilyPrivateChatScreen> createState() => _FamilyPrivateChatScreenState();
}

class _FamilyPrivateChatScreenState extends State<FamilyPrivateChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late List<_Msg> _messages;
  bool _loading = false;
  String? _loadError;
  bool _sending = false;
  String? _conversationId;
  bool? _isOnline;
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

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _messages = [];
    _conversationId = widget.conversationId;
    _loadPresence();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _initConversationAndMessages();
    _bindIncomingMessageEvents();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingVoiceUrl = null);
    });
  }

  void _bindIncomingMessageEvents() {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    _incomingMessageSub?.cancel();
    _incomingMessageSub = callProvider.service.onIncomingMessage.listen((evt) {
      if (!mounted) return;
      final cid = _conversationId;
      if (cid == null) return;
      if (evt.conversationId != cid) {
        debugPrint('💬 [CHAT] Event conversationId mismatch: ${evt.conversationId} != $cid');
        return;
      }
      debugPrint('💬 [CHAT] Real-time message received, reloading...');
      _loadMessages(silent: true);
    });

    _typingSub?.cancel();
    _typingSub = callProvider.service.onTyping.listen((evt) {
      if (!mounted) return;
      if (evt.conversationId != _conversationId || evt.userId != widget.personId) return;
      
      setState(() => _isRemoteTyping = evt.isTyping);
      
      // Auto-clear typing indicator after 5 seconds if no stop event received
      _remoteTypingTimer?.cancel();
      if (evt.isTyping) {
        _remoteTypingTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _isRemoteTyping = false);
        });
      }
    });
  }

  Future<void> _loadPresence() async {
    try {
      final online = await AuthService().getPresence(widget.personId);
      if (!mounted) return;
      setState(() => _isOnline = online);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOnline = false);
    }
  }

  Future<void> _initConversationAndMessages() async {
    // If a conversationId was provided, just load messages from API.
    if (_conversationId != null) {
      await _loadMessages();
      return;
    }

    // Otherwise, create or fetch a real conversation with the backend
    // so that it appears in the inbox list (Benevole tab).
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final chatService =
          ChatService();
      final conv = await chatService.getOrCreateConversation(widget.personId);
      if (!mounted) return;
      setState(() {
        _conversationId = conv.id;
      });
      await _loadMessages(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
        // Fallback to local demo messages if backend fails.
        _messages = _defaultMessages();
      });
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
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
      final chatService = ChatService();
      final list = await chatService.getMessages(cid);
      if (!mounted) return;
      setState(() {
        _messages = list.map((m) {
          final isMe = currentUserId != null && m.senderId == currentUserId;
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
      // Afficher les derniers messages en bas.
      _scrollToBottom(animated: false);
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
        text: "Hi! How's your mother doing today? I heard she had a follow-up appointment this morning. 😊",
        isMe: false,
        time: '10:40 AM',
      ),
      const _Msg(
        text: "She's doing much better! The doctor was very pleased with her recovery progress.",
        isMe: true,
        time: '10:42 AM',
      ),
      const _Msg(
        text: "Thank you so much for checking in. It means a lot to our family.",
        isMe: true,
        time: '10:43 AM',
        read: true,
      ),
      const _Msg(
        text: "That's wonderful news! I'm around this weekend if you need any help with groceries or just some company.",
        isMe: false,
        time: '10:45 AM',
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
          const SnackBar(content: Text('Conversation non chargée')),
        );
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
          const SnackBar(content: Text('Autorisez l\'accès au micro pour enregistrer.')),
        );
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      _currentRecordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _currentRecordPath!);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
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
        final file = File(voicePath);
        final chatService = ChatService();
        setState(() => _sending = true);
        try {
          final url = await chatService.uploadAttachment(file, 'voice');
          await chatService.sendMessage(_conversationId!, 'Message vocal', attachmentUrl: url, attachmentType: 'voice');
          if (!mounted) return;
          setState(() {
            _messages.add(_Msg(
              text: 'Message vocal',
              isMe: true,
              time: _formatTime(DateTime.now()),
              attachmentType: 'voice',
              attachmentUrl: url,
            ));
            _sending = false;
          });
        } catch (e) {
          if (mounted) {
            setState(() => _sending = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
            );
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
          const SnackBar(content: Text('Conversation non chargée')),
        );
      }
      return;
    }
    try {
      final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      // Priorité au token stocké pour éviter 401 si AuthProvider pas encore rechargé
      final chatService = ChatService();
      setState(() => _sending = true);
      try {
        final url = await chatService.uploadAttachment(file, 'image');
        await chatService.sendMessage(_conversationId!, 'Photo', attachmentUrl: url, attachmentType: 'image');
        if (!mounted) return;
        setState(() {
          _messages.add(_Msg(
            text: 'Photo',
            isMe: true,
            time: _formatTime(DateTime.now()),
            attachmentType: 'image',
            attachmentUrl: url,
          ));
          _sending = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() => _sending = false);
          final msg = e.toString().replaceFirst('Exception: ', '');
          final isUnauthorized = msg.toLowerCase().contains('unauthorized') || msg.toLowerCase().contains('session expirée');
          if (isUnauthorized) {
            setState(() => _loadError = msg);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUnauthorized ? 'Session expirée. Veuillez vous reconnecter.' : msg),
              action: isUnauthorized
                  ? SnackBarAction(
                      label: 'Reconnecter',
                      onPressed: () async {
                        await Provider.of<AuthProvider>(context, listen: false).logout();
                        if (context.mounted) context.go(AppConstants.loginRoute);
                      },
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        final isUnauthorized = msg.toLowerCase().contains('unauthorized') || msg.toLowerCase().contains('session expirée');
        if (isUnauthorized) setState(() => _loadError = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isUnauthorized ? 'Session expirée. Veuillez vous reconnecter.' : msg)),
        );
      }
    }
  }

  void _onTypingChanged() {
    if (_conversationId == null) return;
    _typingTimer?.cancel();
    
    // Emit "typing" status
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.service.sendTypingStatus(
      targetUserId: widget.personId,
      conversationId: _conversationId!,
      isTyping: _controller.text.isNotEmpty,
    );

    // Stop typing after 2s of inactivity
    if (_controller.text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
           callProvider.service.sendTypingStatus(
            targetUserId: widget.personId,
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
      _scrollToBottom();
      try {
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
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } else {
      setState(() {
        _messages.add(
          _Msg(
            text: text,
            isMe: true,
            time: _formatTime(DateTime.now()),
          ),
        );
      });
      _controller.clear();
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final am = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _buildHeader(context),
          ),
          Expanded(
            child: Container(
              decoration: AppTheme.chatBackgroundForThemeId(
                Provider.of<ThemeProvider>(context).themeId,
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _loadError!.toLowerCase().contains('unauthorized') ||
                                          _loadError!.toLowerCase().contains('not authenticated')
                                      ? 'Session expirée. Veuillez vous reconnecter.'
                                      : _loadError!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                if (_loadError!.toLowerCase().contains('unauthorized') ||
                                    _loadError!.toLowerCase().contains('not authenticated'))
                                  TextButton(
                                    onPressed: () async {
                                      await Provider.of<AuthProvider>(context, listen: false).logout();
                                      if (context.mounted) context.go(AppConstants.loginRoute);
                                    },
                                    child: const Text('Se reconnecter'),
                                  )
                                else
                                  TextButton(
                                    onPressed: _loadMessages,
                                    child: const Text('Réessayer'),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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



  void _initiateCall(BuildContext context, bool isVideo) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caller = auth.user;
    if (caller == null) {
      debugPrint('📞 [FAMILY_CHAT] Appel impossible: utilisateur non connecté');
      return;
    }
    if (widget.personId.isEmpty) {
      debugPrint('📞 [FAMILY_CHAT] Appel impossible: personId vide');
      return;
    }
    debugPrint('📞 [FAMILY_CHAT] Initiation appel vers personId=${widget.personId} isVideo=$isVideo');
    final ids = [caller.id, widget.personId]..sort();
    final channelId = 'call_${ids[0]}_${ids[1]}_${DateTime.now().millisecondsSinceEpoch}';
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.service.initiateCall(
      targetUserId: widget.personId,
      channelId: channelId,
      isVideo: isVideo,
      callerName: caller.fullName,
    );
    context.push(AppConstants.callRoute, extra: {
      'channelId': channelId,
      'remoteUserId': widget.personId,
      'remoteUserName': widget.personName,
      'remoteImageUrl': widget.personImageUrl,
      'isVideo': isVideo,
      'isIncoming': false,
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(AppConstants.familyFamiliesRoute),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios, color: _textPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push(
                    Uri(
                      path: AppConstants.familyConversationSettingsRoute,
                      queryParameters: {
                        'title': widget.personName,
                        if (widget.conversationId != null) 'conversationId': widget.conversationId!,
                        'personId': widget.personId,
                        'isGroup': '0',
                        if (widget.personImageUrl != null && widget.personImageUrl!.isNotEmpty)
                          'personImageUrl': widget.personImageUrl!,
                      },
                    ).toString(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _primary.withOpacity(0.3),
                          backgroundImage: widget.personImageUrl != null && widget.personImageUrl!.isNotEmpty
                              ? NetworkImage(widget.personImageUrl!)
                              : null,
                          child: widget.personImageUrl == null || widget.personImageUrl!.isEmpty
                              ? const Icon(Icons.person, color: _textMuted, size: 28)
                              : null,
                        ),
                        if (_isOnline == true)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.personName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOnline == true ? 'En ligne' : 'Hors ligne',
                            style: TextStyle(
                              fontSize: 13,
                              color: _isOnline == true ? Colors.green.shade700 : _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _initiateCall(context, false),
            icon: const Icon(Icons.call, color: _textPrimary, size: 26),
          ),
          IconButton(
            onPressed: () => _initiateCall(context, true),
            icon: const Icon(Icons.videocam_outlined, color: _textPrimary, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'TODAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) _avatar(),
          if (!msg.isMe) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: msg.attachmentType == 'image' && msg.attachmentUrl != null
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
                              color: msg.isMe ? Colors.white12 : const Color(0xFFF1F5F9),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 48, color: msg.isMe ? Colors.white70 : _textMuted),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(fontSize: 12, color: msg.isMe ? Colors.white70 : _textMuted),
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
                                onTap: msg.attachmentUrl != null ? () => _playVoiceMessage(msg) : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _playingVoiceUrl == msg.attachmentUrl
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: msg.isMe ? Colors.white : _primary,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.mic, color: msg.isMe ? Colors.white70 : _textMuted, size: 22),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Message vocal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: msg.isMe ? Colors.white : _textPrimary,
                                        ),
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
                                          color: msg.isMe ? Colors.white70 : Colors.red.shade400,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Appel manqué',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: msg.isMe ? Colors.white : _textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.text, // "Appel vocal" or "Appel vidéo"
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: msg.isMe ? Colors.white70 : _textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => _initiateCall(context, msg.text.contains('vidéo')),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        backgroundColor: msg.isMe ? Colors.white24 : Colors.grey.shade100,
                                      ),
                                      child: Text('Rappeler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: msg.isMe ? Colors.white : _primary)),
                                    ),
                                  ],
                                )
                           : msg.attachmentType == 'call_summary'
                               ? Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Icon(
                                           msg.text.contains('vidéo') ? Icons.videocam : Icons.call,
                                           color: msg.isMe ? Colors.white70 : _primary,
                                           size: 22,
                                         ),
                                         const SizedBox(width: 8),
                                          Text(
                                            msg.text.startsWith('Appel ') ? msg.text : 'Transcription de l\'appel',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: msg.isMe ? Colors.white : _textPrimary,
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
                                            color: msg.isMe ? Colors.white.withOpacity(0.9) : _textPrimary.withOpacity(0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                     if (msg.callDuration != null && msg.callDuration! > 0) ...[
                                       const SizedBox(height: 2),
                                       Text(
                                         _formatDuration(msg.callDuration!),
                                         style: TextStyle(
                                           fontSize: 12,
                                           color: msg.isMe ? Colors.white70 : _textMuted,
                                         ),
                                       ),
                                     ],
                                     const SizedBox(height: 8),
                                     TextButton(
                                       onPressed: () => _initiateCall(context, msg.text.contains('vidéo')),
                                       style: TextButton.styleFrom(
                                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                         minimumSize: Size.zero,
                                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                         backgroundColor: msg.isMe ? Colors.white24 : Colors.grey.shade100,
                                       ),
                                       child: Text('Rappeler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: msg.isMe ? Colors.white : _primary)),
                                     ),
                                   ],
                                 )
                          : Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 15,
                                color: msg.isMe ? Colors.white : _textPrimary,
                                height: 1.4,
                              ),
                            ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      msg.time,
                      style: const TextStyle(fontSize: 11, color: _textMuted),
                    ),
                    if (msg.read) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.done_all, size: 16, color: _primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (msg.isMe) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _primary.withOpacity(0.3),
      backgroundImage: widget.personImageUrl != null && widget.personImageUrl!.isNotEmpty
          ? NetworkImage(widget.personImageUrl!)
          : null,
      child: widget.personImageUrl == null || widget.personImageUrl!.isEmpty
          ? const Icon(Icons.person, size: 16, color: _textMuted)
          : null,
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
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
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
