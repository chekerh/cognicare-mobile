import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFF0EA5E9);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF8FAFC);

class _Conversation {
  final String id;
  final String name;
  final String? subtitle;
  final String lastMessage;
  final String timeAgo;
  final bool isFamily;
  final String? conversationId;
  final String? segment;
  final String imageUrl;

  const _Conversation({
    required this.id,
    required this.name,
    this.subtitle,
    required this.lastMessage,
    required this.timeAgo,
    this.isFamily = false,
    this.conversationId,
    this.segment,
    this.imageUrl = '',
  });
}

/// Messages healthcare : conversations avec patients, volontaires, famille et équipe.
class HealthcareMessagesScreen extends StatefulWidget {
  const HealthcareMessagesScreen({super.key});

  @override
  State<HealthcareMessagesScreen> createState() => _HealthcareMessagesScreenState();
}

class _HealthcareMessagesScreenState extends State<HealthcareMessagesScreen> {
  int _selectedTab = 0; // 0: Famille, 1: Bénévole (sans Personnes)
  List<_Conversation>? _inboxConversations;
  bool _loading = false;
  String? _loadError;
  String _searchQuery = '';

  Future<void> _loadInbox() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatService = ChatService();
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
                  isFamily: e.segment == 'families',
                  conversationId: e.id,
                  segment: e.segment,
                  imageUrl: e.imageUrl,
                ))
            .toList();
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

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  void _openChat(BuildContext context, _Conversation c) {
    final cid = c.conversationId ?? c.id;
    context.push('/healthcare/chat', extra: <String, String?>{
      'conversationId': cid,
      'name': c.name,
      'imageUrl': c.imageUrl.isEmpty ? null : c.imageUrl,
      'id': c.id,
    });
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _tab('Famille', 0),
          _tab('Bénévole', 1),
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
          padding: const EdgeInsets.only(top: 14, bottom: 12),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: active ? _primary : _textMuted,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabs(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadInbox,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    final all = _inboxConversations ?? [];
    List<_Conversation> rawList;
    if (_selectedTab == 0) {
      rawList = all.where((c) => c.segment == 'families').toList();
    } else {
      rawList = all.where((c) => c.segment == 'benevole').toList();
    }
    final list = _filterBySearch(rawList);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _selectedTab == 0
                    ? 'Vos conversations avec les familles apparaîtront ici.'
                    : 'Vos conversations avec les bénévoles apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = list[i];
        return _conversationTile(c);
      },
    );
  }

  Widget _conversationTile(_Conversation c) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openChat(context, c),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipOval(
                child: c.imageUrl.isEmpty
                    ? CircleAvatar(
                        radius: 28,
                        backgroundColor: _primary.withOpacity(0.2),
                        child: Icon(
                          c.isFamily ? Icons.group : Icons.person,
                          color: _primary,
                          size: 28,
                        ),
                      )
                    : Image.network(
                        AppConstants.fullImageUrl(c.imageUrl),
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
                        errorBuilder: (_, __, ___) => CircleAvatar(
                          radius: 28,
                          backgroundColor: _primary.withOpacity(0.2),
                          child: Icon(
                            c.isFamily ? Icons.group : Icons.person,
                            color: _primary,
                            size: 28,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    if (c.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        c.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      c.lastMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                c.timeAgo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
