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
import '../profile/change_password_dialog.dart';
import '../profile/change_email_dialog.dart';
import '../profile/change_phone_dialog.dart';

const Color _primary = Color(0xFFA4D9E5);
const Color _background = Color(0xFFF8FAFC);
const Color _grey600 = Color(0xFF757575);
const Color _grey700 = Color(0xFF616161);

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  bool _isLoading = false;
  String? _error;
  String? _localProfilePicPath;
  int _profilePicVersion = 0;
  bool _availabilityActive = true;

  static const List<Widget> _aboutSkills = [
    Chip(label: Text('Autisme', style: TextStyle(fontSize: 12)), backgroundColor: Color(0xFFE2E8F0)),
    Chip(label: Text('Communication douce', style: TextStyle(fontSize: 12)), backgroundColor: Color(0xFFE2E8F0)),
    Chip(label: Text('Mobilité', style: TextStyle(fontSize: 12)), backgroundColor: Color(0xFFE2E8F0)),
  ];

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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(loc.cancel)),
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
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choisir depuis la galerie'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Prendre une photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.cancel), title: const Text('Annuler'), onTap: () => Navigator.pop(context)),
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
        final mimeType = xFile.mimeType ?? 'image/jpeg';
        final updatedUser = await AuthService().uploadProfilePicture(dest, mimeType: mimeType);
        if (!mounted) return;
        Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);
        setState(() {
          _localProfilePicPath = null;
          _profilePicVersion = DateTime.now().millisecondsSinceEpoch;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red),
          );
        }
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
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.cancel))],
      ),
    );
    if (selectedLanguage != null && mounted) {
      await languageProvider.setLanguage(selectedLanguage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.languageChanged} ${languageProvider.getLanguageName(selectedLanguage)}'), backgroundColor: Colors.green),
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
          color: isSelected ? _primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _primary : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? _primary : AppTheme.text))),
            if (isSelected) const Icon(Icons.check_circle, color: _primary, size: 20),
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
      return const Scaffold(backgroundColor: _background, body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _primary,
          title: const Text('Profil Bénévole', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                ElevatedButton(onPressed: _refreshProfile, style: ElevatedButton.styleFrom(backgroundColor: _primary), child: Text(loc.retry)),
              ],
            ),
          ),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFA4D9E5),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Partie fixe en haut : header + Modifier + Missions (ne scrolle pas)
            Container(
              color: _background,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: topPadding + 20, bottom: 48, left: 24, right: 24),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _headerButton(Icons.chevron_left, onTap: () => context.go(AppConstants.volunteerDashboardRoute)),
                            const Text('Mon Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                            _headerButton(Icons.settings_outlined, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickProfilePicture,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: ClipRRect(borderRadius: BorderRadius.circular(20), child: _buildProfileImage(user)),
                              ),
                              Positioned(
                                bottom: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _primary, width: 3),
                                  ),
                                  child: const Icon(Icons.verified, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(user?.fullName ?? 'Bénévole', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user, size: 14, color: Color(0xFF1E293B)),
                              SizedBox(width: 6),
                              Text('Compte vérifié', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenu scrollable (Modifier, Missions + tout le reste)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disponibilités
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.event_available, color: _primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Disponibilités', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text)),
                                Text('Actif pour les missions', style: TextStyle(fontSize: 12, color: _grey600)),
                              ],
                            ),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(
                              switchTheme: SwitchThemeData(
                                thumbColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? _primary : null),
                                trackColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.selected) ? _primary.withOpacity(0.5) : null),
                              ),
                            ),
                            child: Switch(value: _availabilityActive, onChanged: (v) => setState(() => _availabilityActive = v)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Badges & Impact
                          Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Badges & Impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                        GestureDetector(
                          onTap: () {},
                          child: const Text('Voir tout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _badgeChip('Expert', Icons.military_tech, Colors.amber.shade700),
                              _badgeChip('Altruiste', Icons.volunteer_activism, Colors.blue.shade600),
                              _badgeChip('Mentor', Icons.psychology, Colors.green.shade600),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('124', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text)),
                                  Text('Heures de service', style: TextStyle(fontSize: 12, color: _grey600)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('48', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text)),
                                  Text('Missions réussies', style: TextStyle(fontSize: 12, color: _grey600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // À propos
                    const Text('À propos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passionné par l\'inclusion sociale et le soutien aux personnes avec des troubles cognitifs. Bénévole depuis 3 ans, spécialisé dans l\'accompagnement à la mobilité et les activités créatives.',
                            style: TextStyle(fontSize: 14, color: _grey700, height: 1.5),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _aboutSkills,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Information
                    Text(loc.accountInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    const SizedBox(height: 12),
                    _buildInfoCard(icon: Icons.email_outlined, label: loc.emailInfo, value: user?.email ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoCard(icon: Icons.phone_outlined, label: loc.phoneInfo, value: user?.phone ?? loc.notProvided),
                    const SizedBox(height: 12),
                    _buildInfoCard(icon: Icons.calendar_today_outlined, label: loc.memberSince, value: user?.createdAt != null ? _formatDate(user!.createdAt) : 'N/A'),

                    const SizedBox(height: 24),

                    // Account Settings
                    Text(loc.accountSettings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    const SizedBox(height: 12),
                    _buildActionTile(icon: Icons.lock_outline, label: loc.changePassword, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
                      if (result != true) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour. Veuillez vous reconnecter.'), backgroundColor: Colors.green));
                      await _handleLogout();
                    }),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.email_outlined, label: loc.changeEmail, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => const ChangeEmailDialog());
                      if (result != true) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Email mis à jour. Veuillez vous reconnecter.'), backgroundColor: Colors.green));
                      await _handleLogout();
                    }),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.language_outlined, label: loc.changeLanguage, onTap: _showLanguageDialog),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.phone_outlined, label: loc.changePhone, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => ChangePhoneDialog(currentPhone: user?.phone));
                      if (result != true) return;
                      _refreshProfile();
                      messenger.showSnackBar(const SnackBar(content: Text('Téléphone mis à jour'), backgroundColor: Colors.green));
                    }),

                    const SizedBox(height: 24),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildProfileImage(dynamic user) {
    if (_localProfilePicPath != null) {
      return Image.file(File(_localProfilePicPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _profilePlaceholder());
    }
    if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
      final base = user.profilePic!.startsWith('http') ? user.profilePic! : '${AppConstants.baseUrl}${user.profilePic}';
      final url = '$base${base.contains('?') ? '&' : '?'}v=$_profilePicVersion';
      return Image.network(url, key: ValueKey(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _profilePlaceholder());
    }
    return _profilePlaceholder();
  }

  Widget _profilePlaceholder() {
    return Container(color: Colors.white, child: const Icon(Icons.person, size: 48, color: _primary));
  }

  Widget _headerButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 24)),
      ),
    );
  }

  Widget _badgeChip(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _primary, size: 22),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: _primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: _primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.text))),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
