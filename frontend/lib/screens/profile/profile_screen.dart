import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../providers/child_security_code_provider.dart';
import 'change_password_dialog.dart';
import 'change_email_dialog.dart';
import 'change_phone_dialog.dart';

// Design from HTML: primary #A2D9E7, background #F8FAFC, rounded-3xl
const Color _profilePrimary = Color(0xFFA2D9E7);
const Color _profileBackground = Color(0xFFF8FAFC);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _error;
  String? _localProfilePicPath;
  bool _childMode = true;
  bool _dataSharing = false;
  bool _familyNotifications = true;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
    _loadLocalProfilePic();
  }

  Future<void> _loadLocalProfilePic() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_pic.jpg');
      if (await file.exists()) {
        setState(() => _localProfilePicPath = file.path);
      }
    } catch (_) {}
  }

  Future<void> _refreshProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasCachedUser = authProvider.user != null;
    setState(() {
      _error = null;
      _isLoading = !hasCachedUser;
    });
    try {
      final user = await AuthService().getProfile();
      if (mounted) {
        authProvider.updateUser(user);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      final isUnauthorized = message.contains('Unauthorized') || message.contains('No authentication token');
      if (mounted) {
        setState(() {
          _error = message;
          _isLoading = false;
        });
        if (isUnauthorized) {
          await authProvider.logout();
          if (mounted) context.go(AppConstants.loginRoute);
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logoutConfirmTitle),
        content: Text(loc.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.logout),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) context.go(AppConstants.loginRoute);
    }
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final xFile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 800);
      if (xFile == null) return;
      if (!mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final dest = File('${dir.path}/profile_pic.jpg');
      await File(xFile.path).copy(dest.path);
      if (!mounted) return;
      setState(() => _localProfilePicPath = dest.path);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) authProvider.updateUser(user.copyWith(profilePic: dest.path));
      try {
        final updatedUser = await AuthService().uploadProfilePicture(dest);
        if (mounted) Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLanguageDialog() async {
    final loc = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.languageCode;
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, code: 'en', name: 'English', isSelected: currentLanguage == 'en'),
            const SizedBox(height: 8),
            _buildLanguageOption(context, code: 'fr', name: 'Français', isSelected: currentLanguage == 'fr'),
            const SizedBox(height: 8),
            _buildLanguageOption(context, code: 'ar', name: 'العربية', isSelected: currentLanguage == 'ar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );
    if (selectedLanguage != null && mounted) {
      await languageProvider.setLanguage(selectedLanguage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.languageChanged} ${languageProvider.getLanguageName(selectedLanguage)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildLanguageOption(BuildContext context, {required String code, required String name, required bool isSelected}) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _profilePrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _profilePrimary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _profilePrimary : AppTheme.text,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: _profilePrimary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _profileBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _profileBackground,
        appBar: AppBar(
          backgroundColor: _profilePrimary,
          title: Text(loc.profileTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(loc.errorLoadingProfile, style: TextStyle(fontSize: 18, color: AppTheme.text.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontSize: 14, color: AppTheme.text.withOpacity(0.5)), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: _profilePrimary),
                  child: Text(loc.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Barre de statut en bleu (icônes claires)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final topPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _profileBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header bloc bleu jusqu'en haut (pas d'espace blanc)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, topPadding + 24, 24, 32),
                decoration: BoxDecoration(
                  color: _profilePrimary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headerButton(Icons.settings),
                        Column(
                          children: [
                            Text(
                              loc.monProfil,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.familyCaregiver,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                            ),
                          ],
                        ),
                        _headerButton(Icons.edit),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _pickProfilePicture,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(user),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _profilePrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Contenu sous le header (-mt-12 style)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Ma Famille
                    _buildMaFamilleCard(loc),

                    const SizedBox(height: 24),

                    // Paramètres rapides
                    Text(
                      loc.quickSettings,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickSettingsCard(loc),

                    const SizedBox(height: 16),

                    // Engagement
                    _buildEngagementCard(loc),

                    const SizedBox(height: 24),

                    // Account Information (design 2e image)
                    Text(
                      loc.accountInformation,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(icon: Icons.email_outlined, label: loc.emailInfo, value: user?.email ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoCard(icon: Icons.phone_outlined, label: loc.phoneInfo, value: user?.phone ?? loc.notProvided),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.calendar_today_outlined,
                      label: loc.memberSince,
                      value: user?.createdAt != null ? _formatDate(user!.createdAt) : 'N/A',
                    ),

                    const SizedBox(height: 24),

                    // Account Settings
                    Text(
                      loc.accountSettings,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile(icon: Icons.lock_outline, label: loc.changePassword, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
                      if (result != true) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Mot de passe mis à jour. Veuillez vous reconnecter.'), backgroundColor: Colors.green),
                      );
                      await _handleLogout();
                    }),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.email_outlined, label: loc.changeEmail, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => const ChangeEmailDialog());
                      if (result != true) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Email mis à jour. Veuillez vous reconnecter.'), backgroundColor: Colors.green),
                      );
                      await _handleLogout();
                    }),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.language_outlined, label: loc.changeLanguage, onTap: _showLanguageDialog),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.phone_outlined, label: loc.changePhone, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => ChangePhoneDialog(currentPhone: user?.phone),
                      );
                      if (result != true) return;
                      _refreshProfile();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Téléphone mis à jour'), backgroundColor: Colors.green),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 22),
                            const SizedBox(width: 10),
                            Text(loc.logout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(dynamic user) {
    if (_localProfilePicPath != null) {
      return Image.file(File(_localProfilePicPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _profilePlaceholder());
    }
    if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
      final url = user.profilePic!.startsWith('http') ? user.profilePic! : '${AppConstants.baseUrl}${user.profilePic}';
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _profilePlaceholder());
    }
    return _profilePlaceholder();
  }

  Widget _profilePlaceholder() {
    return Container(
      color: Colors.white,
      child: const Icon(Icons.person, size: 64, color: _profilePrimary),
    );
  }

  Widget _headerButton(IconData icon) {
    return Material(
      color: Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildMaFamilleCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.myFamily,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
              ),
              Text(
                loc.seeAll,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _profilePrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _familyMemberChip('Thomas', _profilePrimary.withOpacity(0.2), 'https://lh3.googleusercontent.com/aida-public/AB6AXuBKs8HO57e-9ULVYza-1fs4FtkC-okignnf2GSb499MqWdTMv81N-2rrO4D5SFU-GZyYrc7U0Pn33KcnBOkKVu62bYfjzV3Ao9D8MhpJcRlGhCcZfW1VRnxWIfy32E0JSXyoB6S7Zm-ZrWvIaiiN4MKwvEDciofeO3a-dEDBYs3yPT4hkXLzoWba7pVFk4lrNwMVxhqzsgqW-GBXeotGpQ9tQBNd5YIo_q2nNUVKZw8gM1cIofQLTi0ef7lUIeKN0U_2lWFK4h6Z0g'),
                const SizedBox(width: 16),
                _familyMemberChip('Julie', Colors.orange.shade100, 'https://lh3.googleusercontent.com/aida-public/AB6AXuAcrva4YUunD5KuO3iG3Se8mC3-2ID3qtHH3C3_fiBHYLpLzPobo8wHneQsbziTQeN-_ymLSeBJgxqJRS8uyA8titky5LVR5m1ZU2lvtVo8QhM00DLV21AuTBC_1uo-iu4GTaXC0ygCAtbc1fQc-WV-GgCq9iJN9E9KfXF4rqpRwVIDA5X_oc5hK-Yb_XnE_3TmXLGjfZv6moHo6GrpyX6GnDkPTqgC-Dn6H7AlJRYAUb2NfUtJ-ZKRFPYxJP3SbZ_zernNcaU6t24'),
                const SizedBox(width: 16),
                _addMemberChip(loc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _familyMemberChip(String name, Color bgColor, String imageUrl) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bgColor.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: _profilePrimary)),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.text)),
      ],
    );
  }

  Widget _addMemberChip(AppLocalizations loc) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.add, color: Colors.grey.shade400, size: 28),
        ),
        const SizedBox(height: 8),
        Text(loc.addMember, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildQuickSettingsCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _settingRow(
            icon: Icons.child_care,
            iconColor: Colors.indigo,
            title: loc.childMode,
            subtitle: loc.simplifiedInterfaceActive,
            value: _childMode,
            onChanged: (v) {
              setState(() => _childMode = v);
              if (v) context.push(AppConstants.familyChildModeRoute);
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _settingRow(
            icon: Icons.share,
            iconColor: Colors.green,
            title: loc.dataSharing,
            subtitle: loc.syncWithRelatives,
            value: _dataSharing,
            onChanged: (v) => setState(() => _dataSharing = v),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _settingRow(
            icon: Icons.notifications,
            iconColor: Colors.red.shade400,
            title: loc.familyNotifications,
            subtitle: loc.importantActivityAlerts,
            value: _familyNotifications,
            onChanged: (v) => setState(() => _familyNotifications = v),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _securityCodeRow(context, loc),
        ],
      ),
    );
  }

  Widget _securityCodeRow(BuildContext context, AppLocalizations loc) {
    return Consumer<ChildSecurityCodeProvider>(
      builder: (context, codeProvider, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppConstants.familyCreateSecurityCodeRoute),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline, color: Colors.orange.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.securityCode,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.manageChildModeExitCode,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _settingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return _profilePrimary;
                  return null;
                }),
                trackColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return _profilePrimary.withOpacity(0.5);
                  return null;
                }),
              ),
            ),
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(AppLocalizations loc) {
    return Material(
      color: _profilePrimary.withOpacity(0.12),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.push(AppConstants.familyEngagementDashboardRoute),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _profilePrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _profilePrimary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.engagement.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _profilePrimary, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '14 ${loc.activitiesThisWeek}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _profilePrimary, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _profilePrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _profilePrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _profilePrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _profilePrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.text),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
