import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
class FamilyPrivateChatScreen extends StatefulWidget {
  const FamilyPrivateChatScreen({
    super.key,
    required this.personId,
    required this.personName,
    this.personImageUrl,
  });

  final String personId;
  final String personName;
  final String? personImageUrl;

  @override
  State<FamilyPrivateChatScreen> createState() => _FamilyPrivateChatScreenState();
}

class _FamilyPrivateChatScreenState extends State<FamilyPrivateChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<_Msg> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _defaultMessages();
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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
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

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final am = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildDateSeparator(),
                  const SizedBox(height: 24),
                  ..._messages.map((m) => _buildBubble(m)),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        ),
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
                  'Online',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
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
    return Container(
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
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
