import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

// Distinct from Family: softer background, volunteer primary for consistency
const Color _primary = Color(0xFFa3dae1);
const Color _background = Color(0xFFF5F9FC);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);
const Color _postAccent = Color(0xFFa3dae1);
const Color _donationAccent = Color(0xFF5BB38A);
const Color _marketAccent = Color(0xFFE8A84A);

/// Volunteer Community Hub — entry to Community Post, Donations, Marketplace.
/// Layout similar to Family section but with distinct colors and icons.
class VolunteerCommunityHubScreen extends StatelessWidget {
  const VolunteerCommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        title: const Text(
          'Communauté',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Partage, dons et marketplace au service de la communauté.',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _SectionCard(
                icon: Icons.article_outlined,
                iconBg: _postAccent.withOpacity(0.15),
                iconColor: _postAccent,
                title: 'Publication communautaire',
                subtitle:
                    'Consulter le fil, publier, commenter et échanger avec la communauté.',
                onTap: () => context.push(AppConstants.volunteerCommunityFeedRoute),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.favorite_border,
                iconBg: _donationAccent.withOpacity(0.15),
                iconColor: _donationAccent,
                title: 'Dons',
                subtitle:
                    'Découvrir les campagnes, contribuer ou proposer des dons pour des causes liées à l\'autisme.',
                onTap: () =>
                    context.push(AppConstants.volunteerCommunityDonationsRoute),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.storefront_outlined,
                iconBg: _marketAccent.withOpacity(0.15),
                iconColor: _marketAccent,
                title: 'Marketplace',
                subtitle:
                    'Acheter ou vendre livres, matériel éducatif, jouets adaptés et ressources pour la communauté.',
                onTap: () =>
                    context.push(AppConstants.volunteerCommunityMarketRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: _cardBg,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary.withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
