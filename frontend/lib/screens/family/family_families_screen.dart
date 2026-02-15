// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';

/// Écran Chats — onglets Families, Benevole, Healthcare (sans Persons).
/// Design Community Messaging Inbox : search, Online Now, liste de conversations.
const Color _primary = Color(0xFFA8DADC);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF8FAFC);

class _Conversation {
  final String id;
  final String name;
  final String? subtitle;
  final String lastMessage;
  final String timeAgo;
  final String imageUrl;
  final bool unread;
  /// When set, opening this chat uses API (real messages).
  final String? conversationId;
  /// persons | families | benevole (from API inbox)
  final String? segment;

  const _Conversation({
    required this.id,
    required this.name,
    this.subtitle,
    required this.lastMessage,
    required this.timeAgo,
    required this.imageUrl,
    this.unread = false,
    this.conversationId,
    this.segment,
  });
}

class FamilyFamiliesScreen extends StatefulWidget {
  const FamilyFamiliesScreen({super.key});

  @override
  State<FamilyFamiliesScreen> createState() => _FamilyFamiliesScreenState();
}

class _FamilyFamiliesScreenState extends State<FamilyFamiliesScreen> {
  int _selectedTab = 0; // 0: Families, 1: Benevole, 2: Healthcare
  String _searchQuery = '';
  List<_Conversation>? _inboxConversations;
  bool _inboxLoading = false;
  String? _inboxError;
  List<FamilyUser>? _familiesToContact;
  bool _familiesLoading = false;
  String? _familiesError;

  Future<void> _loadInbox() async {
    setState(() {
      _inboxLoading = true;
      _inboxError = null;
    });
    try {
      final chatService = ChatService(getToken: () => AuthService().getStoredToken());
      final list = await chatService.getInbox();
      if (!mounted) return;
      setState(() {
        _inboxConversations = list
            .map((e) => _Conversation(
                  id: e.id,
                  name: e.name,
                  subtitle: e.subtitle,
                  lastMessage: e.lastMessage,
                  timeAgo: e.timeAgo,
                  imageUrl: e.imageUrl,
                  unread: e.unread,
                  conversationId: e.id,
                  segment: e.segment,
                ))
            .toList();
        _inboxLoading = false;
        _inboxError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inboxLoading = false;
        _inboxError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadFamiliesToContact() async {
    if (_familiesLoading || _familiesToContact != null) return;
    setState(() {
      _familiesLoading = true;
      _familiesError = null;
    });
    try {
      final chatService = ChatService(getToken: () => AuthService().getStoredToken());
      final list = await chatService.getFamiliesToContact();
      if (!mounted) return;
      setState(() {
        _familiesToContact = list;
        _familiesLoading = false;
        _familiesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _familiesLoading = false;
        _familiesError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openChatWithFamily(BuildContext context, FamilyUser family) async {
    try {
      final chatService = ChatService(getToken: () => AuthService().getStoredToken());
      final conv = await chatService.getOrCreateConversation(family.id);
      if (!context.mounted) return;
      context.push(
        Uri(
          path: AppConstants.familyPrivateChatRoute,
          queryParameters: {
            'id': family.id,
            'name': conv.name,
            if (conv.imageUrl.isNotEmpty) 'imageUrl': conv.imageUrl,
            'conversationId': conv.id,
          },
        ).toString(),
      );
      _loadInbox();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir la conversation.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  void _openChat(BuildContext context, _Conversation c) {
    // Families (0) → groupe ; Benevole (1), Healthcare (2) → chat privé 1-à-1.
    if (_selectedTab == 1 || _selectedTab == 2) {
      final params = <String, String>{
        'id': c.id,
        'name': c.name,
        if (c.imageUrl.isNotEmpty) 'imageUrl': c.imageUrl,
        if (c.conversationId != null) 'conversationId': c.conversationId!,
      };
      context.push(
        Uri(
          path: AppConstants.familyPrivateChatRoute,
          queryParameters: params,
        ).toString(),
      );
    } else {
      // Families (0) → groupe
      final membersMatch = RegExp(r'(\d+)').firstMatch(c.subtitle ?? '');
      final members = membersMatch != null ? membersMatch.group(1)! : '2';
      context.push(
        Uri(
          path: AppConstants.familyGroupChatRoute,
          queryParameters: {
            'name': c.name,
            'members': members,
            'id': c.id,
          },
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Conversations',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Material(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.edit_note, color: _textMuted, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.transparent),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
          decoration: InputDecoration(
            hintText: 'Search family & friends',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _tab('Families', 0),
          _tab('Benevole', 1),
          _tab('Healthcare', 2),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.only(top: 16, bottom: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: active ? _primary : _textMuted,
              letterSpacing: 0.015,
            ),
          ),
        ),
      ),
    );
  }

  List<_Conversation> _filterBySearch(List<_Conversation> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Widget _buildContent() {
    if (_inboxLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_inboxError != null) {
      final isUnauthorized = _inboxError!.toLowerCase().contains('unauthorized') ||
          _inboxError!.toLowerCase().contains('not authenticated');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isUnauthorized
                    ? (AppLocalizations.of(context)?.sessionExpiredReconnect ?? 'Votre session a expiré. Veuillez vous reconnecter.')
                    : _inboxError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: _textMuted),
              ),
              const SizedBox(height: 20),
              if (isUnauthorized)
                FilledButton.icon(
                  onPressed: () async {
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                    if (context.mounted) context.go(AppConstants.loginRoute);
                  },
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(AppLocalizations.of(context)?.loginButton ?? 'Se connecter'),
                )
              else
                TextButton(
                  onPressed: _loadInbox,
                  child: Text(AppLocalizations.of(context)?.retry ?? 'Réessayer'),
                ),
            ],
          ),
        ),
      );
    }
    List<_Conversation> rawList;
    if (_inboxConversations != null && _inboxConversations!.isNotEmpty) {
      if (_selectedTab == 0) {
        rawList = _inboxConversations!
            .where((c) => c.segment == 'families')
            .toList();
      } else if (_selectedTab == 1) {
        rawList = _inboxConversations!
            .where((c) => c.segment == 'benevole')
            .toList();
      } else {
        rawList = _inboxConversations!
            .where((c) => c.segment == 'healthcare')
            .toList();
      }
    } else {
      rawList = [];
    }
    final list = _filterBySearch(rawList);
    if (list.isEmpty) {
      if (_selectedTab == 0) {
        if (_familiesToContact == null && !_familiesLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadFamiliesToContact());
        }
        if (_familiesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_familiesError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _familiesError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: _textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadFamiliesToContact,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
        final families = _familiesToContact ?? [];
        if (families.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune autre famille pour le moment.\nVos conversations apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Familles avec qui communiquer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              ...families.asMap().entries.map((entry) {
                final f = entry.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.key > 0) Divider(height: 1, color: Colors.grey.shade100),
                    _FamilyContactTile(
                      family: f,
                      onTap: () => _openChatWithFamily(context, f),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _selectedTab == 1
                    ? 'Aucune conversation avec des bénévoles.'
                    : 'Aucune conversation avec les professionnels de santé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final c = list[index];
          return Dismissible(
            key: ValueKey(c.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer la conversation ?'),
                      content: const Text(
                        'Cette action supprimera la conversation pour les deux participants.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) async {
              final id = c.conversationId ?? c.id;
              final chatService =
                  ChatService(getToken: () => AuthService().getStoredToken());
              try {
                await chatService.deleteConversation(id);
              } catch (_) {
                // On ignore l'erreur ici, la conversation est déjà retirée de la liste.
              }
              setState(() {
                _inboxConversations =
                    _inboxConversations?.where((e) => e.id != c.id).toList();
              });
            },
            child: _ConversationTile(
              conversation: c,
              onTap: () => _openChat(context, c),
            ),
          );
        },
      ),
    );
  }
}

class _FamilyContactTile extends StatelessWidget {
  const _FamilyContactTile({required this.family, required this.onTap});

  final FamilyUser family;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = family.profilePic != null && family.profilePic!.isNotEmpty
        ? (family.profilePic!.startsWith('http')
            ? family.profilePic!
            : '${AppConstants.baseUrl}${family.profilePic}')
        : '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipOval(
              child: imageUrl.isEmpty
                  ? Container(
                      width: 48,
                      height: 48,
                      color: _primary.withOpacity(0.3),
                      child: const Icon(Icons.person, size: 24),
                    )
                  : Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: _primary.withOpacity(0.3),
                        child: const Icon(Icons.person, size: 24),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Appuyer pour envoyer un message',
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline, size: 20, color: _textMuted),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final _Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: conversation.imageUrl.isEmpty
                  ? Container(
                      width: 56,
                      height: 56,
                      color: _primary.withOpacity(0.3),
                      child: const Icon(Icons.person, size: 28),
                    )
                  : Image.network(
                      AppConstants.fullImageUrl(conversation.imageUrl),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: _primary.withOpacity(0.3),
                        child: const Icon(Icons.person, size: 28),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: conversation.unread ? FontWeight.bold : FontWeight.w500,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.w500,
                          color: conversation.unread ? _primary : _textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.normal,
                            color: conversation.unread ? _textPrimary : _textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
