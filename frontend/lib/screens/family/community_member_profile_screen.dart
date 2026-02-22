import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _secondary = Color(0xFF7FBAC4);

/// Profil d'un membre de la communauté — avatar, nom, rôle, Message Privé, Suivre, Parcours, Principaux, stats.
class CommunityMemberProfileScreen extends StatelessWidget {
  const CommunityMemberProfileScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    this.memberRole,
    this.memberImageUrl,
    this.memberDiagnosis,
    this.memberJourney,
    this.memberTags,
    this.postsCount,
    this.followersCount,
    this.helpsCount,
  });

  final String memberId;
  final String memberName;
  final String? memberRole;
  final String? memberImageUrl;
  final String? memberDiagnosis;
  final String? memberJourney;
  final List<String>? memberTags;
  final int? postsCount;
  final int? followersCount;
  final int? helpsCount;

  static CommunityMemberProfileScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    final tags = e['memberTags'] as List<dynamic>?;
    return CommunityMemberProfileScreen(
      memberId: e['memberId'] as String? ?? '',
      memberName: e['memberName'] as String? ?? '',
      memberRole: e['memberRole'] as String?,
      memberImageUrl: e['memberImageUrl'] as String?,
      memberDiagnosis: e['memberDiagnosis'] as String?,
      memberJourney: e['memberJourney'] as String?,
      memberTags: tags?.map((t) => t.toString()).toList(),
      postsCount: e['postsCount'] as int?,
      followersCount: e['followersCount'] as int?,
      helpsCount: e['helpsCount'] as int?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final role = memberRole ?? loc.defaultRoleParent;
    final diagnosis = memberDiagnosis ?? loc.defaultDiagnosisMildAutism;
    final journey = memberJourney ?? loc.defaultJourneyText;
    final tags = memberTags ?? [
      loc.tagSpeechTherapy,
      loc.tagEmotionalSupport,
      loc.tagSensoryActivities,
      loc.tagSchoolInclusion,
    ];
    final posts = postsCount ?? 124;
    final followers = followersCount ?? 1200;
    final helps = helpsCount ?? 450;

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  children: [
                    _buildProfileSection(memberName, role),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 32),
                    _buildParcoursCard(diagnosis, journey, loc),
                    const SizedBox(height: 16),
                    _buildPrincipauxCard(tags, loc),
                    const SizedBox(height: 24),
                    _buildStatsCard(posts, followers, helps, loc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Color(0xFF334155)),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.3)),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String name, String role) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: memberImageUrl != null && memberImageUrl!.isNotEmpty
                    ? NetworkImage(memberImageUrl!)
                    : null,
                child: memberImageUrl == null || memberImageUrl!.isEmpty
                    ? Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _secondary),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(
                '${AppConstants.familyPrivateChatRoute}?id=${Uri.encodeComponent(memberId)}&name=${Uri.encodeComponent(memberName)}${memberImageUrl != null && memberImageUrl!.isNotEmpty ? '&imageUrl=${Uri.encodeComponent(memberImageUrl!)}' : ''}',
              );
            },
            icon: const Icon(Icons.mail_outline, size: 20),
            label: Text(loc.privateMessageAction),
            style: OutlinedButton.styleFrom(
              foregroundColor: _secondary,
              side: const BorderSide(color: _secondary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add, size: 20),
            label: Text(loc.followAction),
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParcoursCard(String diagnosis, String journey, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: _secondary, size: 24),
              const SizedBox(width: 12),
              Text(loc.sectionJourney, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(diagnosis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          Text(journey, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPrincipauxCard(List<String> tags, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _secondary, size: 24),
              const SizedBox(width: 12),
              Text(loc.sectionMainTopics, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _primary.withOpacity(0.3)),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int posts, int followers, int helps, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: _statBox('$posts', loc.statsPosts),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statBox('${followers >= 1000 ? '${(followers / 1000).toStringAsFixed(1)}k' : followers}', loc.statsFollowers),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statBox('$helps', loc.statsHelps),
        ),
      ],
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
