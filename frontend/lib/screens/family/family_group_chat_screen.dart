import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// Family Circle Chat — aligné sur le HTML (primary #457B9D, background #A8E0E9)
const Color _primary = Color(0xFF457B9D);
const Color _backgroundLight = Color(0xFFA8E0E9);
const Color _bubbleMom = Color(0xFFE9D5FF);
const Color _bubbleDad = Color(0xFFDBEAFE);
const Color _bubbleTherapist = Color(0xFFDCFCE7);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate600 = Color(0xFF475569);
const Color _slate500 = Color(0xFF64748B);
const Color _amber100 = Color(0xFFFEF3C7);
const Color _amber600 = Color(0xFFD97706);

/// Écran de chat de groupe familial — design aligné sur le HTML Family Circle Chat.
class FamilyGroupChatScreen extends StatefulWidget {
  const FamilyGroupChatScreen({
    super.key,
    required this.groupName,
    this.memberCount = 5,
    this.groupId,
  });

  final String groupName;
  final int memberCount;
  final String? groupId;

  @override
  State<FamilyGroupChatScreen> createState() => _FamilyGroupChatScreenState();
}

class _FamilyGroupChatScreenState extends State<FamilyGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _currentRecordPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _playingMessageId;

  final List<_ChatMessage> _messages = [
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

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingMessageId = null);
    });
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
    final path = msg.voicePath!;
    if (!File(path).existsSync()) {
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
    await _audioPlayer.play(DeviceFileSource(path));
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
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
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

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final am = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _buildSharedNotesCard(context),
                  const SizedBox(height: 16),
                  _buildDateSeparator(),
                  const SizedBox(height: 24),
                  ..._messages.map((m) => _buildMessageBubble(context, m)),
                ],
              ),
            ),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: _backgroundLight,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${widget.memberCount} members active',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _slate600,
                      ),
                    ),
                  ],
                ),
              ),
              _headerButton(icon: Icons.more_horiz_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAvatarRow(),
              const Spacer(),
              Material(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: _slate800, size: 22),
        ),
      ),
    );
  }

  Widget _buildAvatarRow() {
    const colors = [_bubbleMom, _bubbleDad, Color(0xFFFFE4C4), _bubbleTherapist];
    const double size = 40;
    const double overlap = 12;
    const int count = 4;
    return SizedBox(
      width: size + (count - 1) * (size - overlap),
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (size - overlap).toDouble(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: colors[i],
              ),
              child: const Icon(Icons.person_rounded, size: 22, color: _slate600),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSharedNotesCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _amber100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.push_pin_rounded, color: _amber600, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHARED NOTES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _slate500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Timmy's Focus Goals - Week 12",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _slate800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _slate500, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'TODAY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _slate600,
          ),
        ),
      ),
    );
  }

  Color _bubbleColor(_SenderType type) {
    switch (type) {
      case _SenderType.mom:
        return _bubbleMom;
      case _SenderType.dad:
        return _bubbleDad;
      case _SenderType.therapist:
        return _bubbleTherapist;
    }
  }

  Widget _buildMessageBubble(BuildContext context, _ChatMessage msg) {
    final bubbleColor = _bubbleColor(msg.senderType);
    final isRight = msg.isFromRight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isRight) _avatar(16),
          if (!isRight) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.senderName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _slate600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.hasImage ? Colors.white : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isRight ? 16 : 0),
                      bottomRight: Radius.circular(isRight ? 0 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: msg.senderType == _SenderType.therapist && !msg.hasImage
                        ? Border.all(color: _bubbleTherapist.withOpacity(0.5))
                        : null,
                  ),
                  child: msg.hasVoice
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: msg.voicePath != null ? () => _toggleVoicePlayback(msg) : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _playingMessageId == msg.id
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_filled_rounded,
                                    color: _primary,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.mic_rounded, color: _primary.withOpacity(0.8), size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    msg.durationSeconds != null
                                        ? _formatDuration(Duration(seconds: msg.durationSeconds!))
                                        : '0:00',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _slate800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : msg.hasImage
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuCaWTCNRVa1TUBGu100X7UIdyafBlBx6Bp-sn7RvgP_vxc-7K0ANL8YDG6lwLZlHzSxLU_q_Likji59SH2nGPkt3sfY9Bhg-DGJXzo_6ORctg_SF7MFgXn_4gvHvW_SVko421lgGzIgamYmIr3BSV5aio80qjtuGN9hYjimXuC7l41ndUAuGceul_EGfjlsIEPRrc8_nK9QzyoPoNZQyiBVgOHCqJzMYfB_uFrXK4iMgBMyiHlq4ntxblcH5SIcF5yJVgk2RuPEa6c',
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              msg.text,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _slate800,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (msg.quotedText != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  msg.quotedText!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: _slate800,
                                  ),
                                ),
                              ),
                            Text(
                              msg.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _slate800,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      msg.time,
                      style: const TextStyle(fontSize: 10, color: _slate500),
                    ),
                    if (msg.showReadReceipt) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all_rounded, size: 14, color: _primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isRight) const SizedBox(width: 12),
          if (isRight) _avatar(16),
        ],
      ),
    );
  }

  Widget _avatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _bubbleMom,
      child: Icon(Icons.person_rounded, size: radius * 1.2, color: _slate600),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10 + bottomPadding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: () {},
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(Icons.add_rounded, color: _primary, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: _slate500, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    suffixIcon: Icon(Icons.sentiment_satisfied_alt_rounded, size: 22, color: _slate500),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: _isRecording ? Colors.red : _primary,
                shape: const CircleBorder(),
                elevation: 4,
                shadowColor: (_isRecording ? Colors.red : _primary).withOpacity(0.4),
                child: InkWell(
                  onTap: _onMicTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: _isRecording
                        ? Text(
                            _formatDuration(_recordingDuration),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          )
                        : const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  });
}
