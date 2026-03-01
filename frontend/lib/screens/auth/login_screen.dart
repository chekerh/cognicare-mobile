import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// Design Premium Sign-in : primary #A3D9E2, background #F8FBFC
const Color _authPrimary = Color(0xFFA3D9E2);
const Color _authBackground = Color(0xFFF8FBFC);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Warm up backend while user is on the login screen
    AuthService().pingBackend().catchError((_) {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        final role = authProvider.user?.role;
        if (AppConstants.isOrganizationLeaderRole(role)) {
          context.go(AppConstants.organizationDashboardRoute);
        } else if (AppConstants.isFamilyRole(role)) {
          context.go(AppConstants.familyDashboardRoute);
        } else if (AppConstants.isVolunteerRole(role)) {
          context.go(AppConstants.volunteerDashboardRoute);
        } else {
          context.go(AppConstants.homeRoute);
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
    if (error.contains('Invalid credentials')) {
      return localizations.invalidCredentials;
    } else if (error.contains('Network')) {
      return localizations.networkError;
    }
    return localizations.unknownError;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button (circle blanc semi-transparent)
                Material(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => context.go(AppConstants.onboardingRoute),
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.text, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // App logo (larger for clarity, especially the heart)
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _authPrimary.withOpacity(0.2),
                          _authPrimary.withOpacity(0.05)
                        ],
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
                        width: 150,
                        height: 150,
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
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title & subtitle
                Center(
                  child: Column(
                    children: [
                      Text(
                        localizations.loginTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.loginSubtitle,
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
                const SizedBox(height: 24),
                // Email field (style Premium : bordure bleu clair, placeholder "Email", sans icône)
                _buildLabel(localizations.emailLabel),
                const SizedBox(height: 8),
                _buildInput(
                  controller: _emailController,
                  icon: null,
                  hint: localizations.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return localizations.emailRequired;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return localizations.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field (même style que l'email : sans icône cadenas)
                _buildLabel(localizations.passwordLabel),
                const SizedBox(height: 8),
                _buildInput(
                  controller: _passwordController,
                  icon: null,
                  hint: localizations.passwordLabel,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return localizations.passwordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.go(AppConstants.forgotPasswordRoute),
                    child: Text(
                      localizations.forgotPasswordQuestion,
                      style: TextStyle(
                        color: _authPrimary.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Se connecter button (glow)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authPrimary,
                      foregroundColor: AppTheme.text,
                      elevation: 0,
                      shadowColor: _authPrimary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localizations.loginButton,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 22),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // Pas encore de compte ? Créer un compte (même flux, sans division)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        localizations.noAccountYet,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppConstants.signupRoute),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          localizations.createAccountLink,
                          style: const TextStyle(
                            color: _authPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.text.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    IconData? icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        // Avoid Flutter VerticalCaretMovementRun assertion when pressing Arrow Up/Down
        // in RTL/locales (see https://github.com/flutter/flutter/issues/139201).
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey.shade400, size: 22)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon != null ? 16 : 20,
            vertical: 16,
          ),
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontWeight: FontWeight.w500),
        ),
        style: const TextStyle(
          color: AppTheme.text,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
