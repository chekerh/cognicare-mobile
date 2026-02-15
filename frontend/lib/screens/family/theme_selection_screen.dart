import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';

const Color _bgLight = Color(0xFFF8FAFC);
const Color _textPrimary = Color(0xFF1E293B);
const Color _accentBlue = Color(0xFF007AFF);
const Color _cardLight = Color(0xFFE2E8F0);

/// Un thème prédéfini : id, nom, dégradé ou couleur.
class _ThemeItem {
  const _ThemeItem({
    required this.id,
    required this.name,
    this.color,
    this.gradient,
  });
  final String id;
  final String name;
  final Color? color;
  final Gradient? gradient;
}

/// Écran de sélection du thème (style Messenger).
/// Deux boutons : Créer avec l'IA, Importer une image + grille de thèmes.
class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  static const List<_ThemeItem> _themes = [
    _ThemeItem(
      id: 'amour',
      name: 'Amour',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6B2D5C), Color(0xFF9B3D7A)],
      ),
    ),
    _ThemeItem(
      id: 'saint_valentin',
      name: 'Saint-Valentin',
      color: Color(0xFF9B59B6),
    ),
    _ThemeItem(
      id: 'simpsons',
      name: 'The Simpsons',
      color: Color(0xFFFFD93D),
    ),
    _ThemeItem(
      id: 'football',
      name: 'Football',
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2D5016), Color(0xFF1B2E0F)],
      ),
    ),
    _ThemeItem(
      id: 'brat',
      name: 'Brat',
      color: Color(0xFF0D0D0D),
    ),
    _ThemeItem(
      id: 'je_taime',
      name: "Je t'aime",
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
      ),
    ),
    _ThemeItem(
      id: 'cool_crew',
      name: 'The Cool Crew',
      color: Color(0xFF1E3A5F),
    ),
    _ThemeItem(
      id: 'hivernal',
      name: 'Hivernal',
      color: Color(0xFF2C3E50),
    ),
    _ThemeItem(
      id: 'shape_friends',
      name: 'Shape Friends',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF74B9FF), Color(0xFF81ECEC), Color(0xFF55EFC4)],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedId = themeProvider.themeId ?? 'amour';
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Thème',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textPrimary, size: 28),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Terminé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _accentBlue,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            children: [
              Expanded(
                child: _BuildCreateCard(
                  label: "Créer avec l'IA",
                  icon: Icons.auto_awesome,
                  foregroundColor: _textPrimary,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary.withOpacity(0.9), AppTheme.primary],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Créer avec l'IA — bientôt disponible"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: _textPrimary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BuildCreateCard(
                  label: 'Importer une image',
                  icon: Icons.image_outlined,
                  color: _cardLight,
                  foregroundColor: _textPrimary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Importer une image — bientôt disponible'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: _textPrimary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: _themes.map((t) => _ThemeThumbnail(
              theme: t,
              isSelected: selectedId == t.id,
              onTap: () => themeProvider.setThemeId(t.id),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _BuildCreateCard extends StatelessWidget {
  const _BuildCreateCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.gradient,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final Gradient? gradient;
  final Color? foregroundColor;
  final VoidCallback onTap;

  static const Color _defaultForeground = Colors.white;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? _defaultForeground;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? color : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 32),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeThumbnail extends StatelessWidget {
  const _ThemeThumbnail({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final _ThemeItem theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: theme.gradient,
                  color: theme.gradient == null ? theme.color : null,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              if (isSelected)
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _accentBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 22),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            theme.name,
            style: const TextStyle(
              fontSize: 12,
              color: _textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
