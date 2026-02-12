import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/sticker_book_provider.dart';
import '../../utils/constants.dart';
import '../../utils/gamification_helper.dart';
import '../../services/gamification_service.dart';

// Cognitive Matching Game — couleurs du HTML
const Color _primary = Color(0xFFA0DCE8);
const Color _primaryDark = Color(0xFF457B9D);
const Color _slate600 = Color(0xFF475569);

/// Une carte du jeu : paire (icon + label) ou face cachée (?).
class _GameCard {
  final int pairId;
  final IconData icon;
  final Color iconColor;
  final String label;
  bool isRevealed = false;
  bool isMatched = false;

  _GameCard({
    required this.pairId,
    required this.icon,
    required this.iconColor,
    required this.label,
  });
}

/// Jeu "Match Pairs!" — grille 2x3, 3 paires à retrouver.
class MatchingGameScreen extends StatefulWidget {
  const MatchingGameScreen({super.key});

  @override
  State<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends State<MatchingGameScreen> {
  static const List<({IconData icon, Color color, String label})> _pairs = [
    (icon: Icons.lightbulb_rounded, color: Color(0xFFFB923C), label: 'Light'),
    (icon: Icons.directions_car_rounded, color: Color(0xFF60A5FA), label: 'Car'),
    (icon: Icons.star_rounded, color: Color(0xFFFBBF24), label: 'Star'),
  ];

  late List<_GameCard> _cards;
  int? _firstSelectedIndex;
  bool _canTap = true;
  int _pairsFound = 0;
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
    _resetGame();
  }

  void _resetGame() {
    final rnd = Random();
    final list = <_GameCard>[];
    for (int i = 0; i < 3; i++) {
      final p = _pairs[i];
      list.add(_GameCard(pairId: i, icon: p.icon, iconColor: p.color, label: p.label));
      list.add(_GameCard(pairId: i, icon: p.icon, iconColor: p.color, label: p.label));
    }
    list.shuffle(rnd);
    setState(() {
      _cards = list;
      _firstSelectedIndex = null;
      _canTap = true;
      _pairsFound = 0;
      _gameStartTime = DateTime.now();
    });
  }

  Future<void> _onCardTap(int index) async {
    if (!_canTap) return;
    final card = _cards[index];
    if (card.isRevealed || card.isMatched) return;

    setState(() {
      card.isRevealed = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
      return;
    }

    final first = _cards[_firstSelectedIndex!];
    if (first.pairId == card.pairId) {
      first.isMatched = true;
      card.isMatched = true;
      _firstSelectedIndex = null;
      final newPairs = _cards.where((c) => c.isMatched).length ~/ 2;
      setState(() => _pairsFound = newPairs);
      if (newPairs == 3) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        
        // Calculate time spent
        final timeSpent = _gameStartTime != null
            ? DateTime.now().difference(_gameStartTime!).inSeconds
            : null;

        // Record game completion (local + backend)
        await recordGameCompletion(
          context: context,
          levelKey: StickerBookProvider.levelKeyForMatching(),
          gameType: GameType.matching,
          timeSpentSeconds: timeSpent,
          metrics: {'pairsFound': 3},
        );

        final provider = Provider.of<StickerBookProvider>(context, listen: false);
        final stickerIndex = provider.unlockedCount - 1;
        if (!context.mounted) return;
        context.push(AppConstants.familyGameSuccessRoute, extra: {
          'stickerIndex': stickerIndex,
          'gameRoute': AppConstants.familyMatchingGameRoute,
        });
      }
      return;
    }

    _canTap = false;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      first.isRevealed = false;
      card.isRevealed = false;
      _firstSelectedIndex = null;
      _canTap = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStars(),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 24.0;
                  const padding = 24.0 * 2;
                  final availableWidth = constraints.maxWidth - padding;
                  final availableHeight = constraints.maxHeight;
                  // 3 lignes + 2 espaces : 3 * cell + 2 * gap <= availableHeight
                  final cellHeight = (availableHeight - 2 * gap) / 3;
                  final cellWidth = (availableWidth - gap) / 2;
                  final cellSize = cellHeight < cellWidth ? cellHeight : cellWidth;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                        mainAxisExtent: cellSize,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => _buildCard(index, _cards[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildFooter(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryDark, size: 24),
              ),
            ),
          ),
          const Text(
            'MATCH PAIRS!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _primaryDark,
              letterSpacing: 1.2,
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.volume_up_rounded, color: _primaryDark, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = i < _pairsFound;
          return Icon(
            Icons.star_rounded,
            size: 28,
            color: filled ? _primaryDark : Colors.white.withOpacity(0.5),
          );
        }),
      ),
    );
  }

  Widget _buildCard(int index, _GameCard card) {
    final showFace = card.isRevealed || card.isMatched;
    return Material(
      color: showFace ? Colors.white : _primaryDark,
      borderRadius: BorderRadius.circular(24),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      child: InkWell(
        onTap: () => _onCardTap(index),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: showFace ? Colors.white : Colors.white.withOpacity(0.2),
              width: 4,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: showFace
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(card.icon, size: 48, color: card.iconColor),
                    const SizedBox(height: 8),
                    Text(
                      card.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _slate600,
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 48,
                    color: Colors.white38,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppConstants.familyShapeSortingRoute),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _pairsFound == 3 ? 'Bravo, Léo !' : 'Keep going, Leo!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
