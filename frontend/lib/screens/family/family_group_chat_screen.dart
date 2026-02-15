import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/chat_message_bar.dart';

// Aligné sur les autres écrans de conversation (Family Private Chat)
const Color _primary = Color(0xFFA8DADC);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);

/// Écran de chat de groupe familial — design aligné sur le HTML Family Circle Chat.
class FamilyGroupChatScreen extends StatefulWidget {
  const FamilyGroupChatScreen({
    super.key,
    required this.groupName,
    this.memberCount = 5,
    this.groupId,
    this.isGroup = false,
  });

  final String groupName;
  final int memberCount;
  final String? groupId;
  /// When true, this is a real group (API); show ADD button to add members.
  final bool isGroup;

  @override
  State<FamilyGroupChatScreen> createState() => _FamilyGroupChatScreenState();
}

class _FamilyGroupChatScreenState extends State<FamilyGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRecording = false;
  String? _currentRecordPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _playingMessageId;

  List<_ChatMessage> _messages = [];
  bool _loading = false;
  String? _loadError;
  bool _sending = false;

  static List<_ChatMessage> _defaultLocalMessages() {
    return [
      _ChatMessage(
        id: '1',
        senderName: 'Mom',
        senderType: _SenderType.mom,
        text: "How did the session go today? Did he enjoy the new puzzle game? 🧩",
        time: '10:15 AM',
        isFromRight: false,
      ),
      _ChatMessage(
        id: '2',
        senderName: 'Dr. Sarah (Therapist)',
        senderType: _SenderType.therapist,
        text: 'He was very focused! He completed the level 2 sequence without any frustration today. Huge win! 🌟',
        time: '10:22 AM',
        isFromRight: false,
        quotedText: '"Great progress on motor skills"',
      ),
      _ChatMessage(
        id: '3',
        senderName: 'Dad',
        senderType: _SenderType.dad,
        text: "That's amazing news! I'll make sure we practice the same pattern at home tonight before bed.",
        time: '10:45 AM',
        isFromRight: true,
        showReadReceipt: true,
      ),
      _ChatMessage(
        id: '4',
        senderName: 'Dr. Sarah (Therapist)',
        senderType: _SenderType.therapist,
        text: "Here's the setup we used today.",
        time: '10:50 AM',
        isFromRight: false,
        hasImage: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _messages = [];
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessagesFromApi());
    } else {
      _messages = _defaultLocalMessages();
    }
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingMessageId = null);
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _showAddMember(BuildContext context) async {
    final cid = widget.groupId;
    if (cid == null) return;
    try {
      final chatService = ChatService(
        getToken: () async =>
            Provider.of<AuthProvider>(context, listen: false).accessToken ??
            await AuthService().getStoredToken(),
      );
      final families = await chatService.getFamiliesToContact();
      if (!mounted) return;
      if (families.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune autre famille à ajouter pour le moment.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ajouter un membre au groupe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              ...families.map((f) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(f.fullName),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await chatService.addMemberToGroup(cid, f.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${f.fullName} a été ajouté au groupe.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceFirst('Exception: ', '')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  )),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadMessagesFromApi() async {
    final cid = widget.groupId;
    if (cid == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = auth.user?.id;
      final chatService = ChatService(
        getToken: () async =>
            Provider.of<AuthProvider>(context, listen: false).accessToken ??
            await AuthService().getStoredToken(),
      );
      final list = await chatService.getMessages(cid);
      if (!mounted) return;
      setState(() {
        _messages = list.map((m) {
          final isMe = currentUserId != null && m.senderId == currentUserId;
          return _ChatMessage(
            id: m.id,
            senderName: isMe ? 'Me' : widget.groupName,
            senderType: isMe ? _SenderType.dad : _SenderType.therapist,
            text: m.text,
            time: _formatTime(m.createdAt),
            isFromRight: isMe,
            hasImage: m.attachmentType == 'image',
            hasVoice: m.attachmentType == 'voice',
            voicePath: m.attachmentType == 'voice' ? m.attachmentUrl : null,
            imageUrl: m.attachmentType == 'image' ? m.attachmentUrl : null,
          );
        }).toList();
        _loading = false;
        _loadError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _messages = _defaultLocalMessages();
      });
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_isRecording) {
      _recorder.stop().ignore();
    }
    _recorder.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoicePlayback(_ChatMessage msg) async {
    if (msg.voicePath == null) return;
    final pathOrUrl = msg.voicePath!;
    final isUrl = pathOrUrl.startsWith('http');
    if (!isUrl && !File(pathOrUrl).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier vocal introuvable.')),
        );
      }
      return;
    }
    if (_playingMessageId == msg.id) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _playingMessageId = null);
      return;
    }
    if (_playingMessageId != null) {
      await _audioPlayer.stop();
    }
    if (isUrl) {
      await _audioPlayer.play(UrlSource(pathOrUrl));
    } else {
      await _audioPlayer.play(DeviceFileSource(pathOrUrl));
    }
    if (mounted) setState(() => _playingMessageId = msg.id);
  }

  Future<void> _onMicTap() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorisez l’accès au micro pour enregistrer un message vocal.'),
          ),
        );
      }
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
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
          SnackBar(content: Text('Impossible de démarrer l’enregistrement: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      final duration = _recordingDuration;
      final voicePath = path ?? _currentRecordPath;
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _currentRecordPath = null;
      });
      if (voicePath != null && duration.inSeconds > 0) {
        final cid = widget.groupId;
        if (cid != null) {
          try {
            final chatService = ChatService(
              getToken: () async =>
                  Provider.of<AuthProvider>(context, listen: false).accessToken ??
                  await AuthService().getStoredToken(),
            );
            final url = await chatService.uploadAttachment(File(voicePath), 'voice');
            final sent = await chatService.sendMessage(
              cid,
              'Message vocal',
              attachmentUrl: url,
              attachmentType: 'voice',
            );
            if (!mounted) return;
            setState(() {
              _messages.add(
                _ChatMessage(
                  id: sent.id,
                  senderName: 'Me',
                  senderType: _SenderType.dad,
                  text: 'Message vocal',
                  time: _formatTime(sent.createdAt),
                  isFromRight: true,
                  hasVoice: true,
                  voicePath: url,
                  durationSeconds: duration.inSeconds,
                ),
              );
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          setState(() {
            _messages.add(
              _ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                senderName: 'Me',
                senderType: _SenderType.dad,
                text: 'Message vocal',
                time: _formatTime(DateTime.now()),
                isFromRight: true,
                hasVoice: true,
                voicePath: voicePath,
                durationSeconds: duration.inSeconds,
              ),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur enregistrement: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _onPhotoTap() async {
    final cid = widget.groupId;
    if (cid == null) {
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
      final chatService = ChatService(
        getToken: () async =>
            Provider.of<AuthProvider>(context, listen: false).accessToken ??
            await AuthService().getStoredToken(),
      );
      setState(() => _sending = true);
      try {
        final url = await chatService.uploadAttachment(file, 'image');
        await chatService.sendMessage(cid, 'Photo', attachmentUrl: url, attachmentType: 'image');
        if (!mounted) return;
        setState(() {
          _sending = false;
          _messages.add(
            _ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              senderName: 'Me',
              senderType: _SenderType.dad,
              text: 'Photo',
              time: _formatTime(DateTime.now()),
              isFromRight: true,
              hasImage: true,
              imageUrl: url,
            ),
          );
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final cid = widget.groupId;
    if (cid != null) {
      setState(() => _sending = true);
      try {
        final chatService = ChatService(
          getToken: () async =>
              Provider.of<AuthProvider>(context, listen: false).accessToken ??
              await AuthService().getStoredToken(),
        );
        final sent = await chatService.sendMessage(cid, text);
        if (!mounted) return;
        setState(() {
          _sending = false;
          _messages.add(
            _ChatMessage(
              id: sent.id,
              senderName: 'Me',
              senderType: _SenderType.dad,
              text: sent.text,
              time: _formatTime(sent.createdAt),
              isFromRight: true,
            ),
          );
        });
        _messageController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      setState(() {
        _messages.add(
          _ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderName: 'Me',
            senderType: _SenderType.dad,
            text: text,
            time: _formatTime(DateTime.now()),
            isFromRight: true,
          ),
        );
      });
      _messageController.clear();
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
                                Text(_loadError!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _loadMessagesFromApi,
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
                            ..._messages.map((m) => _buildMessageBubble(context, m)),
                          ],
                        ),
            ),
          ),
          ChatMessageBar(
            controller: _messageController,
            onSend: _sendMessage,
            hintText: 'Votre message...',
            sending: _sending,
            onVoiceTap: _onMicTap,
            isRecording: _isRecording,
            recordingDuration: _recordingDuration,
            onPhotoTap: _onPhotoTap,
          ),
        ],
      ),
    );
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
              onTap: () => context.pop(),
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
                        'title': widget.groupName,
                        if (widget.groupId != null) 'conversationId': widget.groupId!,
                        if (widget.groupId != null) 'groupId': widget.groupId!,
                        'isGroup': '1',
                        'memberCount': '${widget.memberCount}',
                      },
                    ).toString(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _primary.withOpacity(0.3),
                      child: const Icon(Icons.group_rounded, color: _textMuted, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.groupName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.memberCount} participants',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textMuted,
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
          if (widget.isGroup && widget.groupId != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAddMember(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.person_add_rounded, color: _textPrimary, size: 24),
                ),
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call, color: _textPrimary, size: 26),
          ),
          IconButton(
            onPressed: () {},
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
          'AUJOURD\'HUI',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, _ChatMessage msg) {
    final isMe = msg.isFromRight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _avatar(),
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? _primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: msg.hasVoice
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: msg.voicePath != null ? () => _toggleVoicePlayback(msg) : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _playingMessageId == msg.id
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: isMe ? Colors.white : _primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.mic, color: isMe ? Colors.white70 : _textMuted, size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    msg.durationSeconds != null
                                        ? _formatDuration(Duration(seconds: msg.durationSeconds!))
                                        : 'Message vocal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe ? Colors.white : _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : msg.hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                msg.imageUrl != null && msg.imageUrl!.isNotEmpty
                                    ? (msg.imageUrl!.startsWith('http')
                                        ? msg.imageUrl!
                                        : AppConstants.fullImageUrl(msg.imageUrl!))
                                    : '',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 200,
                                  height: 200,
                                  color: isMe ? Colors.white12 : const Color(0xFFF1F5F9),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                        color: isMe ? Colors.white70 : _textMuted,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image non disponible',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMe ? Colors.white70 : _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 15,
                                color: isMe ? Colors.white : _textPrimary,
                                height: 1.4,
                              ),
                            ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      msg.time,
                      style: const TextStyle(fontSize: 11, color: _textMuted),
                    ),
                    if (msg.showReadReceipt) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.done_all, size: 16, color: _primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _primary.withOpacity(0.3),
      child: const Icon(Icons.person, size: 16, color: _textMuted),
    );
  }

}

enum _SenderType { mom, dad, therapist }

class _ChatMessage {
  final String id;
  final String senderName;
  final _SenderType senderType;
  final String text;
  final String time;
  final bool isFromRight;
  final String? quotedText;
  final bool showReadReceipt;
  final bool hasImage;
  final bool hasVoice;
  final String? voicePath;
  final int? durationSeconds;
  final String? imageUrl;

  _ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderType,
    required this.text,
    required this.time,
    required this.isFromRight,
    this.quotedText,
    this.showReadReceipt = false,
    this.hasImage = false,
    this.hasVoice = false,
    this.voicePath,
    this.durationSeconds,
    this.imageUrl,
  });
}
