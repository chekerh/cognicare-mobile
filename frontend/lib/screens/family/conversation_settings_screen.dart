import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _bgLight = Color(0xFFF8FAFC);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);
const Color _destructiveRed = Color(0xFFFF3B30);

/// Écran des paramètres de conversation — 8 options reliées à MongoDB.
class ConversationSettingsScreen extends StatefulWidget {
  const ConversationSettingsScreen({
    super.key,
    required this.title,
    this.conversationId,
    this.personId,
    this.groupId,
    this.isGroup = false,
    this.personImageUrl,
    this.memberCount = 0,
  });

  final String title;
  final String? conversationId;
  final String? personId;
  final String? groupId;
  final bool isGroup;
  final String? personImageUrl;
  final int memberCount;

  @override
  State<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState extends State<ConversationSettingsScreen> {
  bool _autoSavePhotos = false;
  bool _muted = false;
  bool _loadingSettings = true;

  ChatService get _chatService => ChatService(
        getToken: () async =>
            Provider.of<AuthProvider>(context, listen: false).accessToken ??
            await AuthService().getStoredToken(),
      );

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _loadSettings();
    } else {
      setState(() => _loadingSettings = false);
    }
  }

  Future<void> _loadSettings() async {
    final cid = widget.conversationId;
    if (cid == null) {
      setState(() => _loadingSettings = false);
      return;
    }
    try {
      final data = await _chatService.getConversationSettings(cid);
      if (!mounted) return;
      setState(() {
        _autoSavePhotos = data['autoSavePhotos'] as bool? ?? false;
        _muted = data['muted'] as bool? ?? false;
        _loadingSettings = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<void> _updateAutoSavePhotos(bool value) async {
    final cid = widget.conversationId;
    if (cid == null) return;
    setState(() => _autoSavePhotos = value);
    try {
      await _chatService.updateConversationSettings(cid, autoSavePhotos: value);
    } catch (e) {
      if (mounted) {
        setState(() => _autoSavePhotos = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateMuted(bool value) async {
    final cid = widget.conversationId;
    if (cid == null) return;
    setState(() => _muted = value);
    try {
      await _chatService.updateConversationSettings(cid, muted: value);
    } catch (e) {
      if (mounted) {
        setState(() => _muted = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textPrimary, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
          _Section(
            title: 'Personnalisation',
            children: [
                    _SettingsTile(
                      icon: Icons.favorite,
                      iconColor: AppTheme.primaryForThemeId(
                        Provider.of<ThemeProvider>(context).themeId,
                      ),
                      label: 'Thème',
                      onTap: () => _showThemePicker(context),
                      showArrow: true,
                    ),
                  ],
                ),
                _Section(
                  title: 'Autres actions',
                  children: [
                    _SettingsTile(
                      icon: Icons.photo_library_outlined,
                      iconColor: _textMuted,
                      label: 'Voir les contenus multimédias, les fichiers et les liens',
                      onTap: () => _showMedia(context),
                      showArrow: true,
                    ),
                    _SettingsTile(
                      icon: Icons.download_rounded,
                      iconColor: _textMuted,
                      label: 'Enregistrer automatiquement les photos',
                      onTap: () {},
                      trailing: Switch(
                        value: _autoSavePhotos,
                        onChanged: widget.conversationId != null
                            ? (v) => _updateAutoSavePhotos(v)
                            : null,
                        activeColor: AppTheme.primary,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.search_rounded,
                      iconColor: _textMuted,
                      label: 'Rechercher dans la conversation',
                      onTap: () => _showSearch(context),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      iconColor: _textMuted,
                      label: 'Sons et notifications',
                      onTap: () {},
                      trailing: Switch(
                        value: _muted,
                        onChanged: widget.conversationId != null
                            ? (v) => _updateMuted(v)
                            : null,
                        activeColor: AppTheme.primary,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.share_rounded,
                      iconColor: _textMuted,
                      label: 'Partager le contact',
                      onTap: () => _shareContact(context),
                    ),
                  ],
                ),
                _Section(
                  title: 'Confidentialité',
                  children: [
                    if (widget.personId != null && !widget.isGroup)
                      _SettingsTile(
                        icon: Icons.block_rounded,
                        iconColor: _textMuted,
                        label: 'Bloquer',
                        onTap: () => _showBlockConfirm(context),
                      ),
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: _destructiveRed,
                      label: 'Supprimer la discussion',
                      labelColor: _destructiveRed,
                      onTap: () => _deleteConversation(context),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showThemePicker(BuildContext context) {
    context.push(AppConstants.familyThemeSelectionRoute);
  }

  Future<void> _showMedia(BuildContext context) async {
    final cid = widget.conversationId;
    if (cid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune conversation sélectionnée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final list = await _chatService.getConversationMedia(cid);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Médias et fichiers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun média dans cette conversation',
                          style: TextStyle(color: _textMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final m = list[i];
                          final url = m['attachmentUrl'] as String? ?? '';
                          final type = m['attachmentType'] as String? ?? 'image';
                          final fullUrl = url.isEmpty
                              ? ''
                              : url.startsWith('http')
                                  ? url
                                  : AppConstants.fullImageUrl(url);
                          return ListTile(
                            leading: type == 'image' && fullUrl.isNotEmpty
                                ? Image.network(
                                    fullUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        color: _textMuted),
                                  )
                                : const Icon(Icons.mic, color: _textMuted),
                            title: Text(
                              type == 'voice' ? 'Message vocal' : 'Image',
                              style: const TextStyle(color: _textPrimary),
                            ),
                            subtitle: Text(
                              m['text'] as String? ?? '',
                              style: const TextStyle(
                                  color: _textMuted, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
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

  Future<void> _showSearch(BuildContext context) async {
    final cid = widget.conversationId;
    if (cid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune conversation sélectionnée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Rechercher', style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Mot ou phrase...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (q) async {
            if (q.trim().isEmpty) return;
            try {
              final list = await _chatService.searchConversationMessages(
                  cid, q.trim());
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              _showSearchResults(context, list);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final q = controller.text.trim();
              if (q.isEmpty) return;
              try {
                final list =
                    await _chatService.searchConversationMessages(cid, q);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _showSearchResults(context, list);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(e.toString().replaceFirst('Exception: ', '')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Rechercher',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(
      BuildContext context, List<Map<String, dynamic>> list) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${list.length} résultat(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun message trouvé',
                        style: TextStyle(color: _textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final m = list[i];
                        return ListTile(
                          title: Text(
                            m['text'] as String? ?? '',
                            style: const TextStyle(
                                color: _textPrimary, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareContact(BuildContext context) {
    Share.share(
      'Contact: ${widget.title}',
      subject: widget.title,
    );
  }

  void _showBlockConfirm(BuildContext context) {
    final pid = widget.personId;
    if (pid == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Bloquer', style: TextStyle(color: _textPrimary)),
        content: Text(
          'Bloquer ${widget.title} ? Cette personne ne pourra plus vous envoyer de messages.',
          style: const TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _chatService.blockUser(pid);
                if (!context.mounted) return;
                context.pop();
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact bloqué'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Bloquer',
                style: TextStyle(color: _destructiveRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(BuildContext context) async {
    final cid = widget.conversationId;
    if (cid == null || cid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette conversation ne peut pas être supprimée.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Supprimer la discussion',
            style: TextStyle(color: _textPrimary)),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette conversation ? Les messages seront définitivement supprimés.',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Supprimer', style: TextStyle(color: _destructiveRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await _chatService.deleteConversation(cid);
      if (!context.mounted) return;
      context.pop();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discussion supprimée'),
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
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Column(
          children: children,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = _textMuted,
    this.labelColor = _textPrimary,
    this.trailing,
    this.showArrow = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 16,
                    color: labelColor,
                    fontWeight: FontWeight.w400),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 4),
            ],
            if (showArrow && trailing == null)
              const Icon(Icons.chevron_right_rounded,
                  color: _textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
