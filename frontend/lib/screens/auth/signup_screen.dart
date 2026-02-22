import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// Design Premium Sign-up : primary #A3D9E2, background #F8FBFC
const Color _authPrimary = Color(0xFFA3D9E2);
const Color _authBackground = Color(0xFFF8FBFC);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  String _selectedRole = 'family';
  bool _acceptTerms = false;
  bool _emailVerified = false;
  bool _codeSent = false;
  bool _isSendingCode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.emailRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/send-verification-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _codeSent = true;
          _emailVerified = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.codeSentSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send verification code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.unknownError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/verify-email-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'code': _verificationCodeController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _emailVerified = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.codeVerifiedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid verification code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context)!;

    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.emailNotVerifiedError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.termsRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signup(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
        role: _selectedRole,
        verificationCode: _verificationCodeController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.signupSuccess),
            backgroundColor: Colors.green,
          ),
        );
        if (_selectedRole == 'family') {
          context.go(AppConstants.familyChildProfileSetupRoute);
        } else {
          context.go(AppConstants.loginRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString(), localizations)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getErrorMessage(String error, AppLocalizations localizations) {
    if (error.contains('already exists')) {
      return localizations.emailAlreadyExists;
    } else if (error.contains('Network')) {
      return localizations.networkError;
    }
    return localizations.unknownError;
  }

  String _getRoleDisplayName(String role, AppLocalizations localizations) {
    switch (role) {
      case 'family':
        return localizations.roleFamily;
      case 'doctor':
        return localizations.roleDoctor;
      case 'volunteer':
        return localizations.roleVolunteer;
      case 'organization_leader':
        return localizations.roleOrganizationLeader;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

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
                Material(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => context.go(AppConstants.loginRoute),
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new, color: AppTheme.text, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Illustration (volunteer_activism + favorite)
                Center(
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_authPrimary.withOpacity(0.2), _authPrimary.withOpacity(0.05)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _authPrimary.withOpacity(0.15),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: _authPrimary.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite, color: _authPrimary, size: 48),
                            const SizedBox(height: 4),
                            Icon(Icons.volunteer_activism, color: Colors.green.shade400, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        localizations.signupTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.signupSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.text.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Nom complet
                _buildInput(
                  context: context,
                  controller: _fullNameController,
                  icon: Icons.person,
                  hint: localizations.fullNameLabel,
                  validator: (v) {
                    if (v == null || v.isEmpty) return localizations.fullNameRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email
                _buildInput(
                  context: context,
                  controller: _emailController,
                  icon: Icons.mail,
                  hint: localizations.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return localizations.emailRequired;
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return localizations.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email verification
                if (!_emailVerified) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _authButton(
                          onPressed: _isSendingCode || _codeSent ? null : _sendVerificationCode,
                          label: _codeSent ? localizations.codeSentButton : localizations.sendCodeButton,
                          isLoading: _isSendingCode && !_codeSent,
                          icon: _codeSent ? Icons.check : Icons.email,
                        ),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isSendingCode ? null : _sendVerificationCode,
                          child: Text(
                            localizations.resendButton,
                            style: const TextStyle(color: _authPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInput(
                            context: context,
                            controller: _verificationCodeController,
                            icon: Icons.pin,
                            hint: localizations.verificationCodeLabel,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _authButton(
                          onPressed: _isSendingCode ? null : _verifyEmailCode,
                          label: localizations.verifyButton,
                          isLoading: _isSendingCode,
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            localizations.emailVerifiedMessage,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Téléphone (optionnel)
                _buildInput(
                  context: context,
                  controller: _phoneController,
                  icon: Icons.phone,
                  hint: localizations.phoneLabel,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Je suis... (dropdown)
                _buildDropdown(context, localizations),
                const SizedBox(height: 16),
                // Mot de passe
                _buildInput(
                  context: context,
                  controller: _passwordController,
                  icon: Icons.lock,
                  hint: localizations.passwordLabel,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return localizations.passwordRequired;
                    if (v.length < 6) return localizations.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  context: context,
                  controller: _confirmPasswordController,
                  icon: Icons.lock,
                  hint: localizations.confirmPasswordLabel,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return localizations.confirmPasswordRequired;
                    if (v != _passwordController.text) return localizations.passwordsDontMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      activeColor: _authPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          localizations.termsAgreement,
                          style: TextStyle(
                            color: AppTheme.text.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // S'inscrire button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _authPrimary.withOpacity(0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authPrimary,
                      foregroundColor: AppTheme.text,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizations.signupButton, // This line was replaced
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 22),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppConstants.loginRoute),
                    child: Text(
                      localizations.alreadyHaveAccountLink,
                      style: const TextStyle(
                        color: _authPrimary,
                        fontSize: 14,
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

  Widget _authButton({
    required VoidCallback? onPressed,
    required String label,
    bool isLoading = false,
    IconData? icon,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _authPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _authPrimary,
          foregroundColor: AppTheme.text,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(Icons.expand_more, color: Colors.grey.shade400),
        items: ['family', 'doctor', 'volunteer', 'organization_leader'].map((role) {
          return DropdownMenuItem(
            value: role,
            child: Row(
              children: [
                Icon(Icons.groups, color: Colors.grey.shade400, size: 22),
                const SizedBox(width: 12),
                Text(
                  _getRoleDisplayName(role, localizations),
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedRole = value!),
      ),
    );
  }

  Widget _buildInput({
    required BuildContext context,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
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
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
        ),
        style: const TextStyle(
          color: AppTheme.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
