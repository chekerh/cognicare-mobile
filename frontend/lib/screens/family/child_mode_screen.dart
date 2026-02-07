import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

// Child Mode "How Do You Feel Today?" — design from provided UI
const Color _cardBackground = Color(0xFFA2D9E3);
const Color _titleColor = Color(0xFF2D325A);
const Color _subtitleColor = Color(0xFF64748B);
const Color _happyColor = Color(0xFF7ED957);
const Color _sadColor = Color(0xFF6B93F7);
const Color _angryColor = Color(0xFFF76B8A);
const Color _tiredColor = Color(0xFFF7D96B);
const Color _sillyColor = Color(0xFFA26BF7);
const Color _helpLeoBg = Color(0xFFEFEFEF);
const Color _iconCircleBg = Color(0xFF374151);

class ChildModeScreen extends StatefulWidget {
  const ChildModeScreen({super.key});

  @override
  State<ChildModeScreen> createState() => _ChildModeScreenState();
}

class _ChildModeScreenState extends State<ChildModeScreen> {
  bool _darkMode = false;
  bool _soundOn = true;
  String? _selectedEmotion;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: _cardBackground,
      body: Column(
        children: [
          SizedBox(height: padding.top),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  _buildHeader(context, loc),
                  const SizedBox(height: 32),
                  Text(
                    loc.howDoYouFeelToday,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.tapTheFriendThatLooksLikeYou,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildEmotionGrid(loc),
                  const SizedBox(height: 24),
                  _buildHelpLeoButton(loc),
                  SizedBox(height: padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.6),
            foregroundColor: _titleColor,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _headerIconButton(
              icon: _darkMode ? Icons.dark_mode : Icons.light_mode,
              onTap: () => setState(() => _darkMode = !_darkMode),
            ),
            const SizedBox(width: 8),
            _headerIconButton(
              icon: _soundOn ? Icons.volume_up : Icons.volume_off,
              onTap: () => setState(() => _soundOn = !_soundOn),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _iconCircleBg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildEmotionGrid(AppLocalizations loc) {
    final emotions = [
      (color: _happyColor, icon: Icons.sentiment_very_satisfied, label: loc.happy, key: 'happy'),
      (color: _sadColor, icon: Icons.sentiment_very_dissatisfied, label: loc.sad, key: 'sad'),
      (color: _angryColor, icon: Icons.sentiment_dissatisfied, label: loc.angry, key: 'angry'),
      (color: _tiredColor, icon: Icons.nightlight_round, label: loc.tired, key: 'tired'),
      (color: _sillyColor, icon: Icons.sentiment_satisfied_alt, label: loc.silly, key: 'silly'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _emotionButton(context, emotions[0], 0)),
            const SizedBox(width: 12),
            Expanded(child: _emotionButton(context, emotions[1], 1)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _emotionButton(context, emotions[2], 2)),
            const SizedBox(width: 12),
            Expanded(child: _emotionButton(context, emotions[3], 3)),
          ],
        ),
        const SizedBox(height: 12),
        _emotionButton(context, emotions[4], 4, fullWidth: true),
      ],
    );
  }

  Widget _emotionButton(
    BuildContext context,
    ({Color color, IconData icon, String label, String key}) e,
    int index, {
    bool fullWidth = false,
  }) {
    final isSelected = _selectedEmotion == e.label;
    return Material(
      color: e.color,
      borderRadius: BorderRadius.circular(16),
      elevation: isSelected ? 4 : 1,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          setState(() => _selectedEmotion = e.label);
          context.push(AppConstants.familyChildDashboardRoute, extra: {'emotion': e.key});
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(e.icon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  e.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpLeoButton(AppLocalizations loc) {
    return Material(
      color: _helpLeoBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(AppConstants.familyGamesSelectionRoute),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.face_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                loc.helpLeoSpeakHisMind,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
