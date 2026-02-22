import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/chat_message_bar.dart';

const Color _primary = Color(0xFFA3D9E2);

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool read;
  final bool isLocation;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.read = false,
    this.isLocation = false,
  });
}

/// Messagerie du Cercle du Don — conversation avec un donateur.
class DonationChatScreen extends StatefulWidget {
  const DonationChatScreen({
    super.key,
    required this.donorName,
    required this.donationTitle,
    this.donorAvatarUrl,
    this.donationImageUrl,
  });

  final String donorName;
  final String donationTitle;
  final String? donorAvatarUrl;
  final String? donationImageUrl;

  static DonationChatScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    return DonationChatScreen(
      donorName: e['donorName'] as String? ?? 'Marie Dupont',
      donationTitle: e['donationTitle'] as String? ?? 'Lit Médicalisé',
      donorAvatarUrl: e['donorAvatarUrl'] as String?,
      donationImageUrl: e['donationImageUrl'] as String?,
    );
  }

  @override
  State<DonationChatScreen> createState() => _DonationChatScreenState();
}

class _DonationChatScreenState extends State<DonationChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _defaultMessages();
  }

  List<_ChatMessage> _defaultMessages() {
    return [
      const _ChatMessage(
        text: 'Bonjour ! Le lit médicalisé est toujours disponible pour votre mari. Quand souhaiteriez-vous passer le récupérer au Cercle ?',
        isMe: false,
        time: '09:41',
      ),
      const _ChatMessage(
        text: 'Bonjour Marie, merci infiniment ! Serait-il possible de passer ce samedi vers 10h ?',
        isMe: true,
        time: '09:43',
        read: true,
      ),
      const _ChatMessage(
        text: 'Samedi 10h me convient parfaitement. Je vous envoie l\'adresse exacte et le code d\'accès pour le garage.',
        isMe: false,
        time: '09:45',
      ),
      const _ChatMessage(
        text: '',
        isMe: false,
        time: '09:46',
        isLocation: true,
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
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true, time: time));
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildDateSeparator(loc),
                  const SizedBox(height: 16),
                  ..._messages.map((m) => _buildMessage(m, loc)),
                ],
              ),
            ),
            ChatMessageBar(
              controller: _controller,
              onSend: _sendMessage,
              hintText: loc.writeMessage,
              onVoiceTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.featureComingSoonVoice)),
                );
              },
              onPhotoTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.featureComingSoonPhoto)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios, color: _primary, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: widget.donorAvatarUrl != null && widget.donorAvatarUrl!.isNotEmpty
                          ? NetworkImage(widget.donorAvatarUrl!)
                          : null,
                      child: widget.donorAvatarUrl == null || widget.donorAvatarUrl!.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    if (widget.donationImageUrl != null && widget.donationImageUrl!.isNotEmpty)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              widget.donationImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 14),
                            ),
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
                        widget.donorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111418),
                        ),
                      ),
                      Text(
                        '${loc.donation}: ${widget.donationTitle}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call, color: Colors.grey.shade600, size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam_outlined, color: Colors.grey.shade600, size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(AppLocalizations loc) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          loc.todayLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, AppLocalizations loc) {
    if (msg.isLocation) {
      return _buildLocationCard(msg.time);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: msg.isMe ? _primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isMe ? 16 : 0),
                      bottomRight: Radius.circular(msg.isMe ? 0 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: msg.isMe ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isMe ? Colors.white : const Color(0xFF111418),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    if (msg.isMe && msg.read) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 12, color: _primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 128,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cercle du Don - Paris 15e',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111418),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '12 Rue de la Fédération, 75015',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
