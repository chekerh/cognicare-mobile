import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

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

  const _Msg({required this.text, required this.isMe, required this.time, this.read = false});
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

  late List<_Msg> _messages;
  bool _loading = false;
  String? _loadError;
  bool _sending = false;
  String? _conversationId;
  /// null = loading, true/false = from API (volunteer online only if logged in recently).
  bool? _isOnline;

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
          ChatService(getToken: () => AuthService().getStoredToken());
      final conv = await chatService.getOrCreateConversation(widget.personId);
      if (!mounted) return;
      setState(() {
        _conversationId = conv.id;
      });
      await _loadMessages();
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

  Future<void> _loadMessages() async {
    final cid = _conversationId;
    if (cid == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = auth.user?.id;
      final chatService = ChatService(getToken: () => AuthService().getStoredToken());
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
        _messages.add(
          _Msg(
            text: text,
            isMe: true,
            time: _formatTime(DateTime.now()),
          ),
        );
      });
      _controller.clear();
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
              color: const Color(0xFFF8FAFC),
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
                          ],
                        ),
            ),
          ),
          _buildInputBar(),
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
                  _isOnline == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isOnline == true ? Colors.green.shade700 : _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined, color: _textPrimary, size: 26),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline, color: _textPrimary, size: 24),
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
                  child: Text(
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

  Widget _buildInputBar() {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
        color: Colors.white,
      child: Row(
        children: [
          Material(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: _textPrimary, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 15),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _primary,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: _sending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(Icons.send_rounded, color: _sending ? Colors.white70 : Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
