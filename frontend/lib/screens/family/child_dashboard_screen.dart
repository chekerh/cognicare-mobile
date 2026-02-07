import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_security_code_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/parent_code_input_dialog.dart';

// Child Mode Dashboard — design from HTML (Jouer, Mes Progrès, Mes Cadeaux)
const Color _primary = Color(0xFFA2D9E7);
const Color _primaryShadow = Color(0xFF89C4D3);
const Color _playIconBg = Color(0xFFFFD56B);
const Color _progressIconBg = Color(0xFF81E2BB);
const Color _giftsIconBg = Color(0xFFFF9F89);
const Color _slate700 = Color(0xFF334155);

class ChildDashboardScreen extends StatelessWidget {
  const ChildDashboardScreen({
    super.key,
    this.selectedEmotion,
  });

  /// Emotion selected on previous screen (happy, sad, angry, tired, silly)
  final String? selectedEmotion;

  String _getGreeting(AppLocalizations loc) {
    switch (selectedEmotion?.toLowerCase()) {
      case 'happy':
        return loc.greetingWhenHappy;
      case 'sad':
        return loc.greetingWhenSad;
      case 'angry':
        return loc.greetingWhenAngry;
      case 'tired':
        return loc.greetingWhenTired;
      case 'silly':
        return loc.greetingWhenSilly;
      default:
        return loc.childDashboardDefaultGreeting;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final firstName = _getFirstName(auth.user?.fullName);

    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: padding.top + 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLongPressLogout(context),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _getGreetingWithName(loc, firstName),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            _build3dButton(
                              context,
                              icon: Icons.play_arrow_rounded,
                              iconBg: _playIconBg,
                              label: loc.childDashboardPlay,
                              onTap: () => _onPlayTap(context),
                            ),
                            const SizedBox(height: 24),
                            _build3dButton(
                              context,
                              icon: Icons.star_rounded,
                              iconBg: _progressIconBg,
                              label: loc.childDashboardMyProgress,
                              multiline: true,
                              onTap: () => _onProgressTap(context),
                            ),
                            const SizedBox(height: 24),
                            _build3dButton(
                              context,
                              icon: Icons.card_giftcard_rounded,
                              iconBg: _giftsIconBg,
                              label: loc.childDashboardMyGifts,
                              multiline: true,
                              onTap: () => _onGiftsTap(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 96,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: padding.bottom + 24),
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
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 12),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Thomas';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  String _getGreetingWithName(AppLocalizations loc, String firstName) {
    final base = _getGreeting(loc);
    return base.replaceAll('{name}', firstName);
  }

  Widget _buildLongPressLogout(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final codeProvider = Provider.of<ChildSecurityCodeProvider>(context, listen: false);
    Future<void> handleLogout() async {
      if (codeProvider.hasCode) {
        await ParentCodeInputDialog.show(context);
      } else {
        if (context.mounted) context.go(AppConstants.familyProfileRoute);
      }
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => handleLogout(),
      onLongPress: () => handleLogout(),
      child: Opacity(
        opacity: 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              loc.childDashboardLongPress,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3dButton(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required String label,
    bool multiline = false,
    required VoidCallback onTap,
  }) {
    return _Pressable3dButton(
      icon: icon,
      iconBg: iconBg,
      label: label,
      onTap: onTap,
    );
  }

  void _onPlayTap(BuildContext context) {
    context.push(AppConstants.familyGamesSelectionRoute);
  }

  void _onProgressTap(BuildContext context) {
    context.push(AppConstants.familyChildProgressRoute);
  }

  void _onGiftsTap(BuildContext context) {
    context.push(AppConstants.familyStickerBookRoute);
  }
}

class _Pressable3dButton extends StatefulWidget {
  const _Pressable3dButton({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  @override
  State<_Pressable3dButton> createState() => _Pressable3dButtonState();
}

class _Pressable3dButtonState extends State<_Pressable3dButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 8 : 0, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 6),
            boxShadow: [
              BoxShadow(
                color: _primaryShadow,
                offset: Offset(0, _pressed ? 4 : 12),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 48),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _slate700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
