import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/sticker_book_provider.dart';
import '../../providers/gamification_provider.dart';

// Mes Progrès (Mode Enfant) — design from HTML
const Color _primary = Color(0xFFA2D9E7);
const Color _accent = Color(0xFFFF9F89);
const Color _accentShadow = Color(0xFFE08C78);
const Color _sun = Color(0xFFFFD56B);
const Color _star = Color(0xFFFFD700);

class ChildProgressScreen extends StatefulWidget {
  const ChildProgressScreen({super.key});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  bool _gamificationLoaded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<StickerBookProvider>(context, listen: true);
    final progress = provider.progressTowardNextReward;
    final target = provider.nextRewardTarget;
    final hasReached = provider.hasReachedNextReward;
    final progressPercent =
        target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    // 3 stars: progression de l'enfant (4, 8, 16 tâches)
    final star1Filled = progress >= 4;
    final star2Filled = progress >= 8;
    final star3Filled = progress >= 16;

    return Scaffold(
        backgroundColor: _primary,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(loc),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 40),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStarPath(
                                    star1Filled: star1Filled,
                                    star2Filled: star2Filled,
                                    star3Filled: star3Filled,
                                    loc: loc,
                                    hasReached: hasReached,
                                    progressPercent: progressPercent,
                                    progress: progress,
                                    target: target,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildBadgesSection(context, loc),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: _buildRetourButton(context, loc),
                  ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildBadgesSection(BuildContext context, AppLocalizations loc) {
    if (!_gamificationLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GamificationProvider>().loadStats();
          setState(() => _gamificationLoaded = true);
        }
      });
    }

    return Consumer<GamificationProvider>(
      builder: (context, gamification, _) {
        final stats = gamification.stats;
        if (stats == null || (stats.badges.isEmpty && stats.totalPoints == 0)) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: _accent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    loc.myBadges,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${loc.totalPointsLabel}: ${stats.totalPoints}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              if (stats.badges.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.badges.map((b) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: _accent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _sun,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.eyeglasses,
                  color: Colors.black87, size: 44),
            ),
            Positioned(
              left: -12,
              right: -12,
              top: -12,
              bottom: -12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _sun.withOpacity(0.5),
                    width: 4,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -48,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  loc.bravo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          loc.myProgress.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStarPath({
    required bool star1Filled,
    required bool star2Filled,
    required bool star3Filled,
    required AppLocalizations loc,
    required bool hasReached,
    required double progressPercent,
    required int progress,
    required int target,
  }) {
    const starSpacing = 16.0;
    const lineTop = 28.0;
    const starSize = 56.0;
    const lineHeight = starSize * 3 + starSpacing * 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: lineTop,
          child: Center(
            child: Container(
              width: 6,
              height: lineHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStar(star1Filled, starSize),
            const SizedBox(height: starSpacing),
            _buildStar(star2Filled, starSize),
            const SizedBox(height: starSpacing),
            _buildStar(star3Filled, starSize),
            const SizedBox(height: 20),
            _buildAchievementBox(
                loc, hasReached, progressPercent, progress, target),
          ],
        ),
      ],
    );
  }

  Widget _buildStar(bool filled, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? _star : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? Colors.white : Colors.white.withOpacity(0.2),
          width: 3,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: _star.withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.star_rounded,
        color: filled ? Colors.white : Colors.white.withOpacity(0.5),
        size: size * 0.55,
      ),
    );
  }

  Widget _buildAchievementBox(AppLocalizations loc, bool hasReached,
      double progressPercent, int progress, int target) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.inventory_2_rounded, color: _accent, size: 52),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 22,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasReached ? loc.rewardReached : loc.almostThere.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
          if (!hasReached && target > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$progress / $target',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRetourButton(BuildContext context, AppLocalizations loc) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [
            BoxShadow(
              color: _accentShadow,
              offset: Offset(0, 6),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Text(
              loc.backButton.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
