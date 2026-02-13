import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
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

  const _Msg({required this.text, required this.isMe, required this.time, this.read = false});
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
  State<VolunteerFamilyChatScreen> createState() => _VolunteerFamilyChatScreenState();
}

class _VolunteerFamilyChatScreenState extends State<VolunteerFamilyChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<_Msg> _messages;
  String? _conversationId;
  bool _loading = false;
  String? _loadError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = [];
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      _conversationId = widget.conversationId;
      _loadMessagesDirect();
    } else if (widget.familyId.isNotEmpty) {
      _resolveAndLoadMessages();
    } else {
      _messages = _defaultMessages();
    }
  }

  Future<void> _loadMessagesDirect() async {
    final cid = _conversationId;
    if (cid == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
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
      final chatService = ChatService(getToken: () => AuthService().getStoredToken());
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

  Future<void> _resolveAndLoadMessages() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
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
      final chatService = ChatService(getToken: () => AuthService().getStoredToken());
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
        text: "Bonjour Lucas ! Merci beaucoup d'avoir accepté notre mission. Seriez-vous disponible vers 14h30 ?",
        isMe: false,
        time: '10:15',
      ),
      const _Msg(
        text: "Bonjour ! Oui, c'est parfait pour moi. J'ai bien noté l'adresse au 12 Rue des Lilas.",
        isMe: true,
        time: '10:18',
        read: true,
      ),
      const _Msg(
        text: "C'est parfait. Je vous laisserai la liste sur la table de l'entrée. À tout à l'heure !",
        isMe: false,
        time: '10:20',
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
        final chatService = ChatService(getToken: () => AuthService().getStoredToken());
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
                          ],
                        ),
            ),
          ),
          ChatMessageBar(
            controller: _controller,
            onSend: _sendMessage,
            hintText: 'Votre message...',
            sending: _sending,
            onVoiceTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message vocal — bientôt disponible')),
              );
            },
            onPhotoTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Envoi de photo — bientôt disponible')),
              );
            },
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
                      child: Icon(_missionIcon(widget.missionType), color: Colors.white, size: 12),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
                Text(
                  'Mission : ${widget.missionType}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline, color: _textMuted, size: 24),
          ),
        ],
      ),
    );
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted),
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
          if (!msg.isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isMe ? Colors.white : _textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
    if (type.toLowerCase().contains('course') || type.toLowerCase().contains('proximité')) return Icons.shopping_basket;
    if (type.toLowerCase().contains('lecture') || type.toLowerCase().contains('compagnie')) return Icons.menu_book;
    if (type.toLowerCase().contains('accompagnement') || type.toLowerCase().contains('extérieur')) return Icons.directions_walk;
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

}
