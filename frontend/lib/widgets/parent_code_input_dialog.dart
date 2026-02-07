import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/child_security_code_provider.dart';
import '../utils/constants.dart';

const Color _primary = Color(0xFF39AFEF);
const Color _textDark = Color(0xFF111518);
const Color _textMuted = Color(0xFF4F6B7D);

class ParentCodeInputDialog extends StatefulWidget {
  const ParentCodeInputDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ParentCodeInputDialog(),
    );
  }

  @override
  State<ParentCodeInputDialog> createState() => _ParentCodeInputDialogState();
}

class _ParentCodeInputDialogState extends State<ParentCodeInputDialog> {
  String _code = '';
  bool _showError = false;

  void _onDigit(String digit) {
    if (_code.length >= 4) return;
    setState(() {
      _code += digit;
      _showError = false;
    });
    if (_code.length == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onConfirm());
    }
  }

  void _onBackspace() {
    if (_code.isEmpty) return;
    setState(() {
      _code = _code.substring(0, _code.length - 1);
      _showError = false;
    });
  }

  void _onConfirm() {
    final provider = Provider.of<ChildSecurityCodeProvider>(context, listen: false);
    if (provider.verifyCode(_code)) {
      Navigator.of(context).pop(true);
      context.go(AppConstants.familyProfileRoute);
    } else {
      setState(() {
        _showError = true;
        _code = '';
      });
    }
  }

  void _onCancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: _primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                loc.parentCode,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.enterCodeToExitChildMode,
                style: const TextStyle(
                  fontSize: 15,
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _code.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? _primary : Colors.transparent,
                      border: Border.all(
                        color: _showError ? Colors.red : (filled ? _primary : const Color(0xFFDBE2E6)),
                        width: 2,
                      ),
                      boxShadow: filled ? [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 6, spreadRadius: 0)] : null,
                    ),
                  );
                }),
              ),
              if (_showError) ...[
                const SizedBox(height: 12),
                Text(
                  loc.incorrectCode,
                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
              _buildKeypad(loc),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  loc.cancel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(AppLocalizations loc) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['1', '2', '3'].map((d) => _keypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['4', '5', '6'].map((d) => _keypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['7', '8', '9'].map((d) => _keypadButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 56, height: 56),
            _keypadButton('0'),
            _backspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _keypadButton(String digit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          onTap: () => _onDigit(digit),
          borderRadius: BorderRadius.circular(12),
          onTapDown: (_) {},
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onBackspace,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.backspace_outlined, color: _textMuted, size: 24),
          ),
        ),
      ),
    );
  }
}
