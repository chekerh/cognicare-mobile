import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Barre de message type Instagram : emoji, champ texte, vocal, photo, envoi.
/// Respecte la charte graphique (AppTheme.primary).
class ChatMessageBar extends StatelessWidget {
  const ChatMessageBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Votre message...',
    this.onEmojiTap,
    this.onVoiceTap,
    this.onPhotoTap,
    this.sending = false,
    this.isRecording = false,
    this.recordingDuration,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onPhotoTap;
  final bool sending;
  final bool isRecording;
  final Duration? recordingDuration;

  static const List<String> _defaultEmojis = [
    '😀', '😊', '👍', '❤️', '🙏', '😅', '😂', '🥰',
    '👋', '💪', '✨', '🔥', '✅', '🎉', '💯', '🙌',
  ];

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom + 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _defaultEmojis.map((e) {
            return InkWell(
              onTap: () {
                controller.text = controller.text + e;
                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    const primary = AppTheme.primary;
    const textColor = AppTheme.text;
    final muted = textColor.withOpacity(0.6);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji
            _CircleIconButton(
              icon: Icons.emoji_emotions_outlined,
              color: muted,
              onTap: onEmojiTap ?? () => _showEmojiPicker(context),
            ),
            const SizedBox(width: 8),
            // Champ texte
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(color: muted, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        onSubmitted: (_) => _submit(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Vocal
            _CircleIconButton(
              icon: Icons.mic_none_rounded,
              color: isRecording ? Colors.red : muted,
              onTap: onVoiceTap ?? () {},
              label: isRecording && recordingDuration != null
                  ? _formatDuration(recordingDuration!)
                  : null,
            ),
            const SizedBox(width: 6),
            // Photo
            _CircleIconButton(
              icon: Icons.photo_library_outlined,
              color: muted,
              onTap: onPhotoTap ?? () {},
            ),
            const SizedBox(width: 6),
            // Envoyer
            Material(
              color: primary,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: sending ? null : () => _submit(context),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: sending ? Colors.white70 : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    onSend();
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
