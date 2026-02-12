import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sticker.dart';
import '../../utils/constants.dart';
import '../../widgets/child_mode_exit_button.dart';

const Color _primary = Color(0xFF3994EF);
const Color _brandBlue = Color(0xFFA5DAE8);
const Color _darkBlue = Color(0xFF1A4B7A);

class GameSuccessScreen extends StatelessWidget {
  const GameSuccessScreen({
    super.key,
    this.stickerIndex = 0,
    this.gameRoute,
    this.milestoneMessage,
  });

  /// Index (0-based) of the sticker just earned.
  final int stickerIndex;
  /// Route to push for "Rejouer" (e.g. familyMatchingGameRoute).
  final String? gameRoute;
  /// Optional phrase shown above "Bravo!" in large text (e.g. "You've completed 30 levels!").
  final String? milestoneMessage;

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final idx = stickerIndex.clamp(0, kStickerDefinitions.length - 1);
    final sticker = kStickerDefinitions[idx];
    final stickerName = _stickerName(loc, sticker.nameKey);
    final hasImage = (sticker.imageUrl != null && sticker.imageUrl!.isNotEmpty) ||
        (sticker.imageAsset != null && sticker.imageAsset!.isNotEmpty);

    return Scaffold(
      backgroundColor: _brandBlue,
      body: Stack(
        children: [
          // Confetti-style dots
          ..._confettiPositions.map((e) => Positioned(
            left: e.left,
            right: e.right,
            top: e.top,
            bottom: e.bottom,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: e.color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
              transform: Matrix4.identity()..rotateZ(e.rotation),
            ),
          )),
          // Content with safe area and scroll
          Column(
            children: [
              SizedBox(height: padding.top),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ChildModeExitButton(
                      iconColor: _darkBlue,
                      textColor: _darkBlue,
                      opacity: 0.9,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (milestoneMessage != null && milestoneMessage!.isNotEmpty) ...[
                        Text(
                          milestoneMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        'Bravo !',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.youSucceededTheGame,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Smiley coin
                      Container(
                        width: 140,
                        height: 140,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.shade300, width: 8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.wb_sunny_rounded, size: 88, color: Colors.amber.shade600),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(width: 12, height: 14, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                                const SizedBox(width: 24),
                                Container(width: 12, height: 14, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 36,
                              height: 14,
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.black87, width: 4)),
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                      const SizedBox(height: 16),
                      // Sticker card
                      Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            loc.stickerWon.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: hasImage
                              ? (sticker.imageAsset != null
                                  ? Image.asset(
                                      sticker.imageAsset!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => _fallbackStickerIcon(idx),
                                    )
                                  : Image.network(
                                      sticker.imageUrl!,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, progress) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: CircularProgressIndicator(
                                                  value: progress.expectedTotalBytes != null
                                                      ? progress.cumulativeBytesLoaded /
                                                          progress.expectedTotalBytes!
                                                      : null,
                                                  color: _primary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                loc.stickerWon,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => _fallbackStickerIcon(idx),
                                    ))
                              : _comingSoonSticker(idx),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stickerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Fixed bottom: buttons + safe area
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, padding.bottom + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: _primary,
                      borderRadius: BorderRadius.circular(24),
                      elevation: 12,
                      shadowColor: _primary.withOpacity(0.4),
                      child: InkWell(
                        onTap: () => context.pushReplacement(AppConstants.familyStickerBookRoute),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  loc.addToMyCollection,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        if (gameRoute != null && gameRoute!.isNotEmpty) {
                          context.pop();
                          context.push(gameRoute!);
                        } else {
                          context.pop();
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        loc.playAgain,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackStickerIcon(int index) {
    final icons = [
      Icons.pets_rounded,
      Icons.face_rounded,
      Icons.nature_rounded,
      Icons.auto_awesome_rounded,
    ];
    final icon = index < icons.length ? icons[index] : Icons.star_rounded;
    return Container(
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 72, color: _primary),
    );
  }

  Widget _comingSoonSticker(int index) {
    return Container(
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open_rounded, size: 56, color: _primary.withOpacity(0.8)),
          const SizedBox(height: 6),
          Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  static const List<({double? left, double? right, double? top, double? bottom, Color color, double rotation})> _confettiPositions = [
    (left: 40.0, top: 60.0, right: null, bottom: null, color: Colors.blue, rotation: 0.2),
    (left: null, right: 50.0, top: 80.0, bottom: null, color: Color(0xFF2563EB), rotation: -0.8),
    (left: 30.0, top: null, right: null, bottom: 280.0, color: Colors.white, rotation: 0.7),
    (left: null, right: 40.0, top: null, bottom: 220.0, color: Color(0xFF93C5FD), rotation: 0.5),
    (left: 60.0, top: null, right: null, bottom: 120.0, color: Color(0xFF3B82F6), rotation: -0.3),
    (left: null, right: 70.0, top: null, bottom: 80.0, color: Colors.white, rotation: 1.5),
  ];
}
