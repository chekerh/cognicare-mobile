import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      final localizations = AppLocalizations.of(context)!;

      if (response.statusCode == 200) {
        setState(() => _currentStep = 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.codeSentSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
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
      setState(() => _isLoading = false);
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.go(AppConstants.loginRoute);
            }
          },
        ),
        title: Text(
          localizations.resetPasswordTitle,
          style: const TextStyle(color: AppTheme.text),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                const SizedBox(height: 32),

                // Step content
                if (_currentStep == 0) _buildEmailStep(),
                if (_currentStep == 1) _buildCodeStep(),
                if (_currentStep == 2) _buildPasswordStep(),

                const SizedBox(height: 32),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _getButtonText(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        _buildStepIndicator(0, localizations.emailLabel),
        Expanded(child: Container(height: 2, color: _currentStep > 0 ? AppTheme.primary : Colors.grey[300])),
        _buildStepIndicator(1, localizations.verificationCodeLabel),
        Expanded(child: Container(height: 2, color: _currentStep > 1 ? AppTheme.primary : Colors.grey[300])),
        _buildStepIndicator(2, localizations.passwordLabel),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.text : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.enterEmailStepTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.enterEmailStepSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.text.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _emailController,
          label: localizations.emailLabel,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.emailRequired;
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return localizations.emailInvalid;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.verifyCodeStepTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.checkEmailStepSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.text.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _codeController,
          label: localizations.verificationCodeLabel,
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.unknownError;
            }
            final trimmed = value.trim();
            if (trimmed.length != 6) {
              return localizations.codeInvalid;
            }
            if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
              return localizations.unknownError;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _requestCode,
            child: Text(
              localizations.resendCodeButton,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.createNewPasswordStepTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.createNewPasswordStepSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.text.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _passwordController,
          label: localizations.newPasswordLabel,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.passwordRequired;
            }
            if (value.length < 6) {
              return localizations.passwordTooShort;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: localizations.confirmPasswordLabel,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.confirmPasswordRequired;
            }
            if (value != _passwordController.text) {
              return localizations.passwordsDontMatch;
            }
            return null;
          },
        ),
      ],
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
