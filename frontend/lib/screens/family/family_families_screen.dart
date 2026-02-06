import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

/// Liste des groupes familiaux ; un tap ouvre le chat de groupe.
class _FamilyGroup {
  final String id;
  final String name;
  final int memberCount;
  final String? lastMessage;

  const _FamilyGroup({
    required this.id,
    required this.name,
    required this.memberCount,
    this.lastMessage,
  });
}

/// Écran Familles — liste des groupes pour communiquer entre familles.
class FamilyFamiliesScreen extends StatelessWidget {
  const FamilyFamiliesScreen({super.key});

  static const List<_FamilyGroup> _mockGroups = [
    _FamilyGroup(
      id: 'miller',
      name: 'The Miller Family',
      memberCount: 5,
      lastMessage: 'Thanks for the update! We\'ll try the same at home tomorrow.',
    ),
    _FamilyGroup(
      id: 'martin',
      name: 'Famille Martin',
      memberCount: 4,
      lastMessage: 'Prochaine séance jeudi 14h.',
    ),
    _FamilyGroup(
      id: 'bernard',
      name: 'Famille Bernard',
      memberCount: 6,
      lastMessage: '2 nouveaux messages',
    ),
  ];

  void _openGroupChat(BuildContext context, _FamilyGroup group) {
    context.push(
      Uri(
        path: AppConstants.familyGroupChatRoute,
        queryParameters: {
          'name': group.name,
          'members': '${group.memberCount}',
          'id': group.id,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: const Text(
          'Families',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _mockGroups.length,
        itemBuilder: (context, index) {
          final group = _mockGroups[index];
          return _GroupTile(
            group: group,
            onTap: () => _openGroupChat(context, group),
          );
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final _FamilyGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.3),
                child: const Icon(Icons.groups_rounded, size: 32, color: AppTheme.text),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} members',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.text.withOpacity(0.7),
                      ),
                    ),
                    if (group.lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.text.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.text),
            ],
          ),
        ),
      ),
    );
  }
}
