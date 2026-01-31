import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_text_field.dart';

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
        const SnackBar(
          content: Text('Please enter your email address'),
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
            const SnackBar(
              content: Text('Verification code sent to your email'),
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
        const SnackBar(
          content: Text('Please enter verification code'),
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
            const SnackBar(
              content: Text('Email verified successfully!'),
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
    
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first'),
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
    final localizations = AppLocalizations.of(context)!;

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
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to login screen
        context.go(AppConstants.loginRoute);
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
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Back button
                IconButton(
                  onPressed: () => context.go(AppConstants.loginRoute),
                  icon: const Icon(Icons.arrow_back),
                  color: AppTheme.text,
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  localizations.signupTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  localizations.signupSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.text.withOpacity(0.7),
                      ),
                ),

                const SizedBox(height: 32),

                // Full Name field
                CustomTextField(
                  controller: _fullNameController,
                  label: localizations.fullNameLabel,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.fullNameRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Email field
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

                const SizedBox(height: 16),

                // Email verification section
                if (!_emailVerified) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSendingCode || _codeSent ? null : _sendVerificationCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _codeSent ? Colors.grey : AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: _isSendingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_codeSent ? Icons.check : Icons.email),
                          label: Text(_codeSent ? 'Code Sent' : 'Send Code'),
                        ),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isSendingCode ? null : _sendVerificationCode,
                          child: const Text('Resend'),
                        ),
                      ],
                    ],
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _verificationCodeController,
                            label: 'Verification Code',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSendingCode ? null : _verifyEmailCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Email verified',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Phone field
                CustomTextField(
                  controller: _phoneController,
                  label: localizations.phoneLabel,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                // Role selection
                Text(
                  localizations.roleLabel,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    items: ['family', 'doctor', 'volunteer'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_getRoleDisplayName(role, localizations)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Password field
                CustomTextField(
                  controller: _passwordController,
                  label: localizations.passwordLabel,
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

                const SizedBox(height: 24),

                // Confirm Password field
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

                const SizedBox(height: 24),

                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primary,
                    ),
                    Expanded(
                      child: Text(
                        localizations.termsAgreement,
                        style: TextStyle(
                          color: AppTheme.text.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Signup button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            localizations.signupButton,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Already have account link
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppConstants.loginRoute),
                    child: Text(
                      localizations.alreadyHaveAccountLink,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
}