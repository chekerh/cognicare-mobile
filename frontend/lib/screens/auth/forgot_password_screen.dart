import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Design Premium OTP / Forgot : primary #A3D9E2, background #F8FBFC
const Color _authPrimary = Color(0xFFA3D9E2);
const Color _authBackground = Color(0xFFF8FBFC);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _resendCountdown--);
    });
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ok = await _sendForgotPasswordRequest();
      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;
      if (ok) {
        setState(() => _currentStep = 1);
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.codeSentSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!ok) {
        throw Exception(localizations.unknownError);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.unknownError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _sendForgotPasswordRequest() async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/v1/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _emailController.text.trim()}),
    );
    return response.statusCode == 200;
  }

  Future<void> _verifyCode() async {
    if (_currentStep == 1) {
      final code = _codeController.text.trim();
      if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.codeInvalid),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _codeController.text.trim(),
        }),
      );

      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;

      if (response.statusCode == 200) {
        setState(() => _currentStep = 2);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.codeVerifiedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? localizations.unknownError);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.unknownError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context)!;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.passwordsDontMatch),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _codeController.text.trim(),
          'newPassword': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.passwordResetSuccess),
              backgroundColor: Colors.green,
            ),
          );
          context.go(AppConstants.loginRoute);
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? localizations.unknownError);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.unknownError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Back button
                Material(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        context.go(AppConstants.loginRoute);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.text, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_currentStep == 0) ..._buildEmailStep(localizations),
                if (_currentStep == 1) ..._buildOtpStep(localizations),
                if (_currentStep == 2) ..._buildPasswordStep(localizations),

                const SizedBox(height: 32),

                // Action button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(_currentStep == 1 ? 28 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: _authPrimary.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authPrimary,
                      foregroundColor: AppTheme.text,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(_currentStep == 1 ? 28 : 20),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _getButtonText(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep(AppLocalizations localizations) {
    return [
      Text(
        localizations.enterEmailStepTitle,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppTheme.text,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        localizations.enterEmailStepSubtitle,
        style: TextStyle(
          fontSize: 15,
          color: AppTheme.text.withOpacity(0.6),
          height: 1.4,
        ),
      ),
      const SizedBox(height: 24),
      _buildEmailInput(localizations),
    ];
  }

  Widget _buildEmailInput(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _authPrimary.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _authPrimary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: localizations.emailLabel,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontWeight: FontWeight.w500),
        ),
        style: const TextStyle(
            color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w500),
        validator: (v) {
          if (v == null || v.isEmpty) return localizations.emailRequired;
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
            return localizations.emailInvalid;
          }
          return null;
        },
      ),
    );
  }

  List<Widget> _buildOtpStep(AppLocalizations localizations) {
    return [
      // Email en lecture seule (comme sur la photo)
      _buildReadOnlyField(
        icon: Icons.mail_outline,
        value: _emailController.text.trim(),
      ),
      const SizedBox(height: 16),
      // Code Sent + Resend (style photo : bouton gris + lien bleu)
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.grey.shade700, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    localizations.codeSentButton,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: (_resendCountdown > 0 || _isLoading)
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    final ok = await _sendForgotPasswordRequest();
                    if (mounted) {
                      setState(() => _isLoading = false);
                      if (ok) {
                        _startResendCountdown();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.codeSentSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
            child: Text(
              localizations.resendButton,
              style: TextStyle(
                color: _resendCountdown > 0 ? Colors.grey : _authPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Champ code unique + compteur 0/6
      _buildCodeInput(localizations),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildReadOnlyField({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: _authPrimary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: _authPrimary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: localizations.verificationCodeLabel,
              prefixIcon: Icon(Icons.pin_outlined,
                  color: Colors.grey.shade400, size: 22),
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return null;
              if (s.length != 6 || !RegExp(r'^\d{6}$').hasMatch(s)) {
                return localizations.codeInvalid;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _codeController,
          builder: (context, value, _) {
            return Text(
              '${value.text.length}/6',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildPasswordStep(AppLocalizations localizations) {
    return [
      Text(
        localizations.createNewPasswordStepTitle,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppTheme.text,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        localizations.createNewPasswordStepSubtitle,
        style: TextStyle(
          fontSize: 15,
          color: AppTheme.text.withOpacity(0.6),
          height: 1.4,
        ),
      ),
      const SizedBox(height: 24),
      _buildPasswordInput(localizations.newPasswordLabel, _passwordController,
          (v) {
        if (v == null || v.isEmpty) return localizations.passwordRequired;
        if (v.length < 6) return localizations.passwordTooShort;
        return null;
      }),
      const SizedBox(height: 16),
      _buildPasswordInput(
          localizations.confirmPasswordLabel, _confirmPasswordController, (v) {
        if (v == null || v.isEmpty) {
          return localizations.confirmPasswordRequired;
        }
        if (v != _passwordController.text) {
          return localizations.passwordsDontMatch;
        }
        return null;
      }),
    ];
  }

  Widget _buildPasswordInput(
    String label,
    TextEditingController controller,
    String? Function(String?)? validator,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: _authPrimary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(Icons.lock, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(
            color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w500),
        validator: validator,
      ),
    );
  }

  String _getButtonText() {
    final localizations = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        return localizations.sendCodeButton;
      case 1:
        return localizations.verifyCodeButton;
      case 2:
        return localizations.resetPasswordTitle;
      default:
        return localizations.nextButton;
    }
  }

  void _handleAction() {
    switch (_currentStep) {
      case 0:
        _requestCode();
        break;
      case 1:
        _verifyCode();
        break;
      case 2:
        _resetPassword();
        break;
    }
  }
}
