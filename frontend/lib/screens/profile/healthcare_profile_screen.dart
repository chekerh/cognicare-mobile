import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../providers/language_provider.dart';
import '../../services/auth_service.dart';
import 'change_password_dialog.dart';
import 'change_email_dialog.dart';
import 'change_phone_dialog.dart';

// Design HTML: primary #A0D9E6, background #F3F9FB
const Color _hpPrimary = Color(0xFFA0D9E6);
const Color _hpBackground = Color(0xFFF3F9FB);

/// Profil professionnel de santé (design HTML) — stats, Mes Patients, Paramètres du Cabinet, Mon Compte, Déconnexion.
class HealthcareProfileScreen extends StatefulWidget {
  const HealthcareProfileScreen({super.key});

  @override
  State<HealthcareProfileScreen> createState() => _HealthcareProfileScreenState();
}

class _HealthcareProfileScreenState extends State<HealthcareProfileScreen> {
  String? _localProfilePicPath;

  @override
  void initState() {
    super.initState();
    _loadLocalProfilePic();
  }

  Future<void> _loadLocalProfilePic() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_pic.jpg');
      if (await file.exists()) setState(() => _localProfilePicPath = file.path);
    } catch (_) {}
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galerie'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Appareil photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.cancel), title: const Text('Annuler'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final xFile = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800);
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.languageChanged} ${languageProvider.getLanguageName(selectedLanguage)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildLanguageOption(BuildContext context, {required String code, required String name, required bool isSelected}) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _hpPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _hpPrimary : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? _hpPrimary : AppTheme.text))),
            if (isSelected) const Icon(Icons.check_circle, color: _hpPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  String _professionFromRole(String? role) {
    if (role == null) return 'Professionnel de santé';
    switch (role.toLowerCase()) {
      case 'doctor':
        return 'Pédopsychiatre';
      case 'organization_leader':
        return 'Responsable d\'organisation';
      default:
        return 'Professionnel de santé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final loc = AppLocalizations.of(context)!;
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
      backgroundColor: _hpBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header bleu jusqu'en haut (pas d'espace blanc)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 32),
                decoration: BoxDecoration(
                  color: _hpPrimary,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headerButton(Icons.arrow_back_ios_new),
                        _headerButton(Icons.edit, onTap: _pickProfilePicture),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _pickProfilePicture,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: ClipOval(child: _buildProfileImage(user)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _hpPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'Dr. ...',
                      style: const TextStyle(color: AppTheme.text, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _professionFromRole(user?.role),
                      style: TextStyle(color: AppTheme.text.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, size: 14, color: Colors.blue.shade800),
                          const SizedBox(width: 6),
                          Text(
                            loc.verifiedByOrder.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Stats card
                    _buildStatsCard(loc),

                    const SizedBox(height: 24),

                    // Mes Patients
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.myPatients, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                        TextButton(
                          onPressed: () {},
                          child: Text(loc.seeAll, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _hpPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 118,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _patientCard('LR', 'Lucas R.', '${loc.lastAppointment}: ${loc.yesterday}', Colors.blue),
                          const SizedBox(width: 16),
                          _patientCard('SM', 'Sarah M.', '${loc.lastAppointment}: 12 oct.', Colors.orange),
                          const SizedBox(width: 16),
                          _patientCard('TD', 'Thomas D.', '${loc.lastAppointment}: 05 oct.', Colors.green),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Paramètres du Cabinet
                    Text(loc.clinicSettings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    const SizedBox(height: 12),
                    _buildClinicSettingsCard(loc),

                    const SizedBox(height: 24),

                    // Account Information (comme famille)
                    Text(loc.accountInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
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

                    // Account Settings (comme famille)
                    Text(loc.accountSettings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    const SizedBox(height: 12),
                    _buildActionTile(icon: Icons.lock_outline, label: loc.changePassword, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
                      if (result != true) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Mot de passe mis à jour. Reconnectez-vous.'), backgroundColor: Colors.green),
                      );
                      await _handleLogout();
                    }),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.email_outlined, label: loc.changeEmail, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await showDialog<bool>(context: context, builder: (_) => const ChangeEmailDialog());
                      if (result != true) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Email mis à jour. Reconnectez-vous.'), backgroundColor: Colors.green),
                      );
                      await _handleLogout();
                    }),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.language_outlined, label: loc.changeLanguage, onTap: _showLanguageDialog),
                    const SizedBox(height: 8),
                    _buildActionTile(icon: Icons.phone_outlined, label: loc.changePhone, onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final result = await showDialog<bool>(context: context, builder: (_) => ChangePhoneDialog(currentPhone: user?.phone));
                      if (result != true) return;
                      try {
                        final updated = await AuthService().getProfile();
                        if (!mounted) return;
                        auth.updateUser(updated);
                      } catch (_) {}
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Téléphone mis à jour'), backgroundColor: Colors.green),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Déconnexion (bouton plein comme famille)
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
      return Image.file(File(_localProfilePicPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    }
    if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
      final url = user.profilePic!.startsWith('http') ? user.profilePic! : '${AppConstants.baseUrl}${user.profilePic}';
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(color: Colors.white, child: const Icon(Icons.person, size: 48, color: _hpPrimary));

  Widget _headerButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('42', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text)),
              const SizedBox(height: 4),
              Text(loc.patientsStat.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600, letterSpacing: 0.5)),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Column(
            children: [
              const Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text)),
              const SizedBox(height: 4),
              Text(loc.todayStat.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600, letterSpacing: 0.5)),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Column(
            children: [
              const Text('4.9', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text)),
              const SizedBox(height: 4),
              Text(loc.ratingStat.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patientCard(String initials, String name, String subtitle, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
              child: Text(initials, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicSettingsCard(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.schedule,
            iconColor: Colors.blue,
            title: loc.consultationHours,
            subtitle: loc.consultationHoursValue,
            onTap: () {},
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _settingsTile(
            icon: Icons.videocam,
            iconColor: Colors.purple,
            title: loc.teleconsultationSettings,
            subtitle: loc.teleconsultationSettingsValue,
            onTap: () {},
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _settingsTile(
            icon: Icons.description,
            iconColor: Colors.green,
            title: loc.prescriptionTemplates,
            subtitle: loc.prescriptionTemplatesValue,
            onTap: () {},
          ),
        ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hpPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _hpPrimary, size: 22),
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
                decoration: BoxDecoration(
                  color: _hpPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _hpPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.text)),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}
