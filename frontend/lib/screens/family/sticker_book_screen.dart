import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sticker.dart';
import '../../providers/sticker_book_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/child_mode_exit_button.dart';

const Color _primary = Color(0xFF3994EF);
const Color _appLightBlue = Color(0xFFA5DBE7);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF617589);

class StickerBookScreen extends StatelessWidget {
  const StickerBookScreen({super.key});

  static String _stickerName(AppLocalizations loc, String nameKey) {
    switch (nameKey) {
      case 'stickerLeoTheLion': return loc.stickerLeoTheLion;
      case 'stickerHappyHippo': return loc.stickerHappyHippo;
      case 'stickerBraveBear': return loc.stickerBraveBear;
      case 'stickerSmartyPaws': return loc.stickerSmartyPaws;
      case 'stickerComingSoon': return loc.stickerComingSoon;
      default: return nameKey;
    }
  }

  static String? _stickerSkill(AppLocalizations loc, String? skillKey) {
    if (skillKey == null) return null;
    switch (skillKey) {
      case 'stickerSortingChamp': return loc.stickerSortingChamp;
      case 'stickerMemoryMaster': return loc.stickerMemoryMaster;
      case 'stickerPatternPro': return loc.stickerPatternPro;
      case 'stickerFocusStar': return loc.stickerFocusStar;
      default: return skillKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final stickerProvider = Provider.of<StickerBookProvider>(context);

    return Scaffold(
      backgroundColor: _appLightBlue,
      body: Column(
        children: [
          SizedBox(height: padding.top),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRewardCard(context, loc),
                    const SizedBox(height: 32),
                    _buildUnlockedSection(context, loc),
                    const SizedBox(height: 40),
                    _buildComingSoonSection(context, loc),
                    const SizedBox(height: 24),
                    Text(
                      stickerProvider.hasReachedNextReward
                          ? loc.superHeroPackUnlocked
                          : loc.completeXMoreTasksToUnlock(stickerProvider.tasksRemainingForNextReward),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildKeepGoingButton(context, loc, padding),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _appLightBlue,
        border: Border(bottom: BorderSide(color: _primary.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            color: _primary,
            iconSize: 32,
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.myStickerBook,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
          ChildModeExitButton(iconColor: _primary, textColor: _primary, opacity: 0.9),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, AppLocalizations loc) {
    final provider = Provider.of<StickerBookProvider>(context);
    final earnedToday = provider.stickersEarnedToday;
    final current = provider.progressTowardNextReward;
    final target = provider.nextRewardTarget;
    final remaining = provider.tasksRemainingForNextReward;
    final rewardReached = provider.hasReachedNextReward;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _appLightBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            loc.fantasticJob,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.youEarnedStickersToday(earnedToday),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.nextReward.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.superHeroPack,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '$current/$target',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
              minHeight: 20,
              backgroundColor: _primary.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                rewardReached ? Icons.check_circle : Icons.info_outline,
                color: _primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                rewardReached ? loc.rewardReached : loc.justXMoreTasksToGo(remaining),
                style: const TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (rewardReached) ...[
            const SizedBox(height: 20),
            _buildSuperHeroPackSticker(loc),
          ],
        ],
      ),
    );
  }

  Widget _buildSuperHeroPackSticker(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.15), _primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: _primary, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.superHeroPack,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.rewardReached,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: _primary, size: 28),
        ],
      ),
    );
  }

  Widget _buildUnlockedSection(BuildContext context, AppLocalizations loc) {
    final provider = Provider.of<StickerBookProvider>(context);
    final animalStickers = kStickerDefinitions.where((s) => !s.isComingSoon).toList();
    final rewardReached = provider.hasReachedNextReward;
    final itemCount = animalStickers.length + (rewardReached ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.unlockedAnimalFriends,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (rewardReached && index == itemCount - 1) {
              return _SuperHeroPackStickerCard(name: loc.superHeroPack);
            }
            final sticker = animalStickers[index];
            final globalIndex = kStickerDefinitions.indexOf(sticker);
            final isUnlocked = provider.isUnlocked(globalIndex);
            return _StickerCard(
              name: _stickerName(loc, sticker.nameKey),
              skill: _stickerSkill(loc, sticker.skillKey),
              imageUrl: sticker.imageUrl,
              isUnlocked: isUnlocked,
            );
          },
        ),
      ],
    );
  }

  Widget _buildComingSoonSection(BuildContext context, AppLocalizations loc) {
    final provider = Provider.of<StickerBookProvider>(context);
    const comingSoonCount = 6;
    const firstComingSoonIndex = 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 20, color: Colors.black.withOpacity(0.4)),
            const SizedBox(width: 8),
            Text(
              loc.comingSoon,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: comingSoonCount,
          itemBuilder: (context, index) {
            final globalIndex = firstComingSoonIndex + index;
            final isUnlocked = provider.isUnlocked(globalIndex);
            return Container(
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primary.withOpacity(0.4),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? const Icon(Icons.auto_awesome, color: _primary, size: 32)
                    : Icon(Icons.help_outline, color: _primary.withOpacity(0.6), size: 32),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeepGoingButton(BuildContext context, AppLocalizations loc, EdgeInsets padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, padding.bottom + 20),
      child: Material(
        color: _primary,
        borderRadius: BorderRadius.circular(999),
        elevation: 8,
        shadowColor: _primary.withOpacity(0.4),
        child: InkWell(
          onTap: () => context.push(AppConstants.familyGamesSelectionRoute),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    loc.keepGoing,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerCard extends StatelessWidget {
  const _StickerCard({
    required this.name,
    this.skill,
    this.imageUrl,
    required this.isUnlocked,
  });

  final String name;
  final String? skill;
  final String? imageUrl;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isUnlocked ? 1 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _appLightBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withOpacity(0.3), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isUnlocked && imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholderBox(),
                      )
                    : _placeholderBox(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (skill != null) ...[
              const SizedBox(height: 2),
              Text(
                skill!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          isUnlocked ? Icons.pets : Icons.lock,
          color: Colors.grey.shade400,
          size: 48,
        ),
      ),
    );
  }
}

class _SuperHeroPackStickerCard extends StatelessWidget {
  const _SuperHeroPackStickerCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.2), _primary.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.4), width: 3),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium, color: _primary, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const Text(
            '16/16',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
