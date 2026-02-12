import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../widgets/child_mode_exit_button.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _cardYellow = Color(0xFFFFD56B);
const Color _cardGreen = Color(0xFF81E2BB);
const Color _cardCoral = Color(0xFFFF9F89);
const Color _textDark = Color(0xFF334155);

/// Écran de sélection des jeux : l’enfant choisit quel jeu jouer (Match Pairs, Shape Sorting, Star Tracer).
class GamesSelectionScreen extends StatelessWidget {
  const GamesSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: _primary,
      body: Column(
        children: [
          SizedBox(height: padding.top),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                  iconSize: 28,
                ),
                Expanded(
                  child: Text(
                    loc.chooseAGame,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const ChildModeExitButton(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, padding.bottom + 24),
              child: Column(
                children: [
                  _GameCard(
                    icon: Icons.grid_view_rounded,
                    iconBg: _cardYellow,
                    title: loc.gameMatchPairs,
                    onTap: () => context.push(
                      AppConstants.familyMatchingGameRoute,
                      extra: {'inSequence': true},
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GameCard(
                    icon: Icons.change_circle_rounded,
                    iconBg: _cardGreen,
                    title: loc.gameShapeSorting,
                    onTap: () => context.push(AppConstants.familyShapeSortingRoute),
                  ),
                  const SizedBox(height: 20),
                  _GameCard(
                    icon: Icons.auto_awesome,
                    iconBg: _cardCoral,
                    title: loc.starTracer,
                    onTap: () => context.push(AppConstants.familyStarTracerRoute),
                  ),
                  const SizedBox(height: 20),
                  _GameCard(
                    icon: Icons.shopping_basket_rounded,
                    iconBg: const Color(0xFF2B8CEE),
                    title: loc.gameBasketSort,
                    onTap: () => context.push(AppConstants.familyBasketSortRoute),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _textDark.withOpacity(0.5), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
