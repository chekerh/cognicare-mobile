import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _primary = Color(0xFF77B5D1);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF8FAFC);

class _Conversation {
  final String id;
  final String name;
  final String? subtitle;
  final String lastMessage;
  final String timeAgo;
  final String? missionType;
  final bool isFamily;

  const _Conversation({
    required this.id,
    required this.name,
    this.subtitle,
    required this.lastMessage,
    required this.timeAgo,
    this.missionType,
    this.isFamily = false,
  });
}

/// Messages bénévole — onglets Personnes / Familles, liste de conversations.
class VolunteerMessagesScreen extends StatefulWidget {
  const VolunteerMessagesScreen({super.key});

  @override
  State<VolunteerMessagesScreen> createState() => _VolunteerMessagesScreenState();
}

class _VolunteerMessagesScreenState extends State<VolunteerMessagesScreen> {
  int _selectedTab = 0; // 0: Personnes, 1: Familles
  String _searchQuery = '';

  static const List<_Conversation> _personsList = [
    _Conversation(
      id: 'lefebvre',
      name: 'Mme. Lefebvre',
      subtitle: 'Famille Lefebvre',
      lastMessage: 'Votre visite est prévue demain à 14:00.',
      timeAgo: '10:15',
      isFamily: false,
    ),
    _Conversation(
      id: 'marie-dubois',
      name: 'Marie Dubois',
      subtitle: 'Famille Dubois',
      lastMessage: 'Merci encore Lucas pour votre aide précieuse aujourd\'hui !',
      timeAgo: '14:30',
      isFamily: false,
    ),
  ];

  static const List<_Conversation> _familiesList = [
    _Conversation(
      id: 'martin',
      name: 'Famille Martin',
      subtitle: '4 members',
      lastMessage: 'C\'est parfait. Je vous laisserai la liste sur la table de l\'entrée.',
      timeAgo: '10:20',
      missionType: 'Courses de proximité',
      isFamily: true,
    ),
    _Conversation(
      id: 'dubois',
      name: 'Famille Dubois',
      subtitle: '3 members',
      lastMessage: 'Merci encore Lucas pour votre aide précieuse aujourd\'hui !',
      timeAgo: '14:30',
      missionType: 'Lecture & Compagnie',
      isFamily: true,
    ),
    _Conversation(
      id: 'lefebvre-fam',
      name: 'Famille Lefebvre',
      subtitle: '2 members',
      lastMessage: 'Session accompagnement extérieur confirmée.',
      timeAgo: 'Hier',
      missionType: 'Accompagnement extérieur',
      isFamily: true,
    ),
  ];

  void _openChat(BuildContext context, _Conversation c) {
    context.push(
      '/volunteer/family-chat',
      extra: {
        'familyId': c.id,
        'familyName': c.name,
        'missionType': c.missionType ?? c.subtitle ?? 'Mission',
      },
    );
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
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Messages',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary),
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _tab('Personnes', 0),
          _tab('Familles', 1),
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
    final rawList = _selectedTab == 0 ? _personsList : _familiesList;
    final list = _filterBySearch(rawList);
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Aucune conversation',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _primary.withOpacity(0.2),
                child: Icon(c.isFamily ? Icons.group : Icons.person, color: _primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    if (c.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        c.subtitle!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      c.lastMessage,
                      style: const TextStyle(fontSize: 14, color: _textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                c.timeAgo,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
