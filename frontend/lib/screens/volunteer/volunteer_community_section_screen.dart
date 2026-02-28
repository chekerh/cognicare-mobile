import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'volunteer_community_feed_screen.dart';
import 'volunteer_donations_list_screen.dart';
import 'volunteer_community_market_screen.dart';

// Même design que les écrans individuels : header bleu + onglets
const Color _primary = Color(0xFFa3dae1);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);

/// Écran unique Communauté : header et onglets restent fixes, seul le contenu (Feed / Dons / Marketplace) change.
/// Évite le rechargement de la page et garde la partie haute intacte.
class VolunteerCommunitySectionScreen extends StatefulWidget {
  const VolunteerCommunitySectionScreen({super.key});

  @override
  State<VolunteerCommunitySectionScreen> createState() =>
      _VolunteerCommunitySectionScreenState();
}

class _VolunteerCommunitySectionScreenState
    extends State<VolunteerCommunitySectionScreen> {
  int _selectedTab = 0; // 0 Community, 1 Donations, 2 Marketplace

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFF),
      body: Column(
        children: [
          _buildHeaderWave(context),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                VolunteerCommunityFeedScreen(showHeader: false),
                VolunteerDonationsListScreen(showHeader: false),
                VolunteerCommunityMarketScreen(showHeader: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWave(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: _primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.elliptical(400, 28),
          bottomRight: Radius.elliptical(400, 28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: _primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CogniCare',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        border: Border.all(color: _primary, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSegmentTabs(),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _tab(0, 'Community'),
          _tab(1, 'Donations'),
          _tab(2, 'Marketplace'),
        ],
      ),
    );
  }

  Widget _tab(int index, String label) {
    final selected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _cardBg : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? _textPrimary : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
