import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// Aligné sur le HTML Family Member Dashboard
const Color _primary = Color(0xFFA3D9E5);
const Color _primaryDark = Color(0xFF7BBCCB);
const Color _backgroundLight = Color(0xFFF8FDFF);
const Color _cardLight = Color(0xFFFFFFFF);
const Color _slate600 = Color(0xFF475569);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate500 = Color(0xFF64748B);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate300 = Color(0xFFCBD5E1);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green600 = Color(0xFF16A34A);
const Color _blue100 = Color(0xFFDBEAFE);
const Color _blue600 = Color(0xFF2563EB);

/// Family Member Dashboard — design aligné sur le HTML fourni.
/// Bonjour Sarah, carte Jouer avec Léo, Progrès du jour, Chat Famille / Suivi Médical, activité récente.
class FamilyMemberDashboardScreen extends StatelessWidget {
  const FamilyMemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? 'Sarah';

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, userName),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildPlayWithLeoCard(context),
                  const SizedBox(height: 24),
                  _buildProgressSection(context),
                  const SizedBox(height: 24),
                  _buildTwoColumnCards(context),
                  const SizedBox(height: 24),
                  _buildRecentActivityCard(context),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
            Positioned(
              top: 0,
              right: 16,
              child: _buildDarkModeButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, $userName 👋',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _slate600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Membre de la famille',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_rounded, color: _slate800, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayWithLeoCard(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: () => context.push(AppConstants.familyMatchingGameRoute),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jouer avec Léo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lancer une session de thérapie ludique',
                      style: TextStyle(
                        fontSize: 14,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: _primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    const days = ['LUN', 'MAR', 'MER', 'JEU', 'VEN'];
    const heights = [48.0, 80.0, 112.0, 64.0, 96.0];
    const hasStar = [true, true, true, false, false];
    const isCurrent = [false, false, true, false, false];

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progrès du jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _slate800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Léo • 6 ans',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: heights[i],
                          decoration: BoxDecoration(
                            color: hasStar[i]
                                ? (isCurrent[i] ? _primary : _primary.withOpacity(0.2))
                                : _slate300.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: hasStar[i]
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: isCurrent[i] ? Colors.white : _primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent[i] ? _primary : _slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, color: _slate500),
                children: [
                  TextSpan(
                    text: 'Encore 2 étoiles ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _slate800,
                    ),
                  ),
                  TextSpan(text: 'pour le défi de la semaine !'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Card(
            child: InkWell(
              onTap: () => context.go(AppConstants.familyFamiliesRoute),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _green100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_rounded, color: _green600, size: 22),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chat Famille',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2 nouveaux messages',
                      style: TextStyle(fontSize: 12, color: _slate500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _Card(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _blue100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: _blue600, size: 22),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Suivi Médical',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RDV demain 10h',
                      style: TextStyle(fontSize: 12, color: _slate500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _primaryDark,
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: _slate800, height: 1.3),
                children: [
                  TextSpan(
                    text: 'Dr. Martin ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'a mis à jour le programme de motricité fine.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Il y a 2h',
            style: TextStyle(
              fontSize: 10,
              color: _slate500,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.dark_mode_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
