import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../providers/gamification_provider.dart';
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

class _FamilyMemberItem {
  final String? id;
  final String name;
  final String? imageUrl;
  final String? imagePath;
  _FamilyMemberItem(
      {this.id, required this.name, this.imageUrl, this.imagePath});
  Map<String, String?> toJson() =>
      {'id': id, 'name': name, 'imageUrl': imageUrl, 'imagePath': imagePath};
  static _FamilyMemberItem fromJson(Map<String, dynamic> j) {
    final rawUrl = j['imageUrl'] ?? j['image_url'];
    String? imageUrl;
    if (rawUrl is String && rawUrl.trim().isNotEmpty && rawUrl != 'null') {
      imageUrl = rawUrl.trim();
    }
    return _FamilyMemberItem(
      id: j['id'] as String?,
      name: j['name'] as String? ?? 'Membre',
      imageUrl: imageUrl,
      imagePath: j['imagePath'] as String?,
    );
  }
}

const String _keyFamilyMembers = 'profile_family_members';

List<_FamilyMemberItem> get _defaultFamilyMembers => [
      _FamilyMemberItem(
          name: 'Thomas',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBKs8HO57e-9ULVYza-1fs4FtkC-okignnf2GSb499MqWdTMv81N-2rrO4D5SFU-GZyYrc7U0Pn33KcnBOkKVu62bYfjzV3Ao9D8MhpJcRlGhCcZfW1VRnxWIfy32E0JSXyoB6S7Zm-ZrWvIaiiN4MKwvEDciofeO3a-dEDBYs3yPT4hkXLzoWba7pVFk4lrNwMVxhqzsgqW-GBXeotGpQ9tQBNd5YIo_q2nNUVKZw8gM1cIofQLTi0ef7lUIeKN0U_2lWFK4h6Z0g'),
      _FamilyMemberItem(
          name: 'Julie',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAcrva4YUunD5KuO3iG3Se8mC3-2ID3qtHH3C3_fiBHYLpLzPobo8wHneQsbziTQeN-_ymLSeBJgxqJRS8uyA8titky5LVR5m1ZU2lvtVo8QhM00DLV21AuTBC_1uo-iu4GTaXC0ygCAtbc1fQc-WV-GgCq9iJN9E9KfXF4rqpRwVIDA5X_oc5hK-Yb_XnE_3TmXLGjfZv6moHo6GrpyX6GnDkPTqgC-Dn6H7AlJRYAUb2NfUtJ-ZKRFPYxJP3SbZ_zernNcaU6t24'),
    ];

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _error;
  String? _localProfilePicPath;
  int _profilePicVersion = 0; // force reload image after upload (cache-busting)
  bool _childMode = false;
  bool _dataSharing = false;
  bool _familyNotifications = true;

  List<_FamilyMemberItem> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _refreshProfile();
    _loadLocalProfilePic();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final apiList = await AuthService().getFamilyMembers();
      if (apiList.isNotEmpty && mounted) {
        setState(() {
          _familyMembers = apiList.map((m) {
            final imageUrl = (m['imageUrl']?.toString() ?? '').trim();
            return _FamilyMemberItem(
              id: m['id'],
              name: m['name'] ?? 'Membre',
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
            );
          }).toList();
        });
        await _saveFamilyMembers();
        return;
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyFamilyMembers);
      if (json == null || json.isEmpty) {
        if (mounted) {
          setState(() => _familyMembers = List.from(_defaultFamilyMembers));
        }
        return;
      }
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null || list.isEmpty) {
        if (mounted) {
          setState(() => _familyMembers = List.from(_defaultFamilyMembers));
        }
        return;
      }
      final loaded = <_FamilyMemberItem>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        loaded.add(_FamilyMemberItem.fromJson(e));
      }
      if (mounted) setState(() => _familyMembers = loaded);
    } catch (_) {
      if (mounted) {
        setState(() => _familyMembers = List.from(_defaultFamilyMembers));
      }
    }
  }

  Future<void> _saveFamilyMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _familyMembers.map((m) => m.toJson()).toList();
      await prefs.setString(_keyFamilyMembers, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _loadLocalProfilePic() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_pic_$userId.jpg');
      if (await file.exists() && mounted) {
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
      final isUnauthorized = message.contains('Unauthorized') ||
          message.contains('No authentication token');
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
      final xFile = await picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 800);
      if (xFile == null) return;
      if (!mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 'local';
      final dest = File('${dir.path}/profile_pic_$userId.jpg');
      await File(xFile.path).copy(dest.path);
      if (!mounted) return;
      setState(() => _localProfilePicPath = dest.path);
      try {
        final mimeType = xFile.mimeType ?? 'image/jpeg';
        final updatedUser =
            await AuthService().uploadProfilePicture(dest, mimeType: mimeType);
        if (!mounted) return;
        authProvider.updateUser(updatedUser);
        setState(() {
          _localProfilePicPath = null;
          _profilePicVersion = DateTime.now().millisecondsSinceEpoch;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo de profil mise à jour'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erreur: ${e.toString().replaceFirst('Exception: ', '')}'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLanguageDialog() async {
    final loc = AppLocalizations.of(context)!;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.languageCode;
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context,
                code: 'en',
                name: 'English',
                isSelected: currentLanguage == 'en'),
            const SizedBox(height: 8),
            _buildLanguageOption(context,
                code: 'fr',
                name: 'Français',
                isSelected: currentLanguage == 'fr'),
            const SizedBox(height: 8),
            _buildLanguageOption(context,
                code: 'ar',
                name: 'العربية',
                isSelected: currentLanguage == 'ar'),
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
            content: Text(
                '${loc.languageChanged} ${languageProvider.getLanguageName(selectedLanguage)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildLanguageOption(BuildContext context,
      {required String code, required String name, required bool isSelected}) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _profilePrimary.withOpacity(0.1)
              : Colors.transparent,
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
            if (isSelected)
              const Icon(Icons.check_circle, color: _profilePrimary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
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
          title: Text(loc.profileTitle,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.red.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(loc.errorLoadingProfile,
                    style: TextStyle(
                        fontSize: 18, color: AppTheme.text.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.text.withOpacity(0.5)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshProfile,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _profilePrimary),
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
                        const SizedBox(width: 40), // Espace vide à gauche
                        Column(
                          children: [
                            Text(
                              loc.monProfil,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.familyCaregiver,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        _headerButton(
                          Icons.edit,
                          onTap: _showAccountSettingsDrawer,
                        ),
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
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4)),
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
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
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
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text),
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
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: loc.emailInfo,
                        value: user?.email ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                        icon: Icons.phone_outlined,
                        label: loc.phoneInfo,
                        value: user?.phone ?? loc.notProvided),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.calendar_today_outlined,
                      label: loc.memberSince,
                      value: user?.createdAt != null
                          ? _formatDate(user!.createdAt)
                          : 'N/A',
                    ),

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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 22),
                            const SizedBox(width: 10),
                            Text(loc.logout,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
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
    // Only use local path if it was set this session (e.g. after pick, before upload)
    if (_localProfilePicPath != null) {
      return Image.file(File(_localProfilePicPath!),
          key: const ValueKey('local_profile'),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _profilePlaceholder());
    }
    if (user?.profilePic != null && user!.profilePic!.isNotEmpty) {
      final base = user.profilePic!.startsWith('http')
          ? user.profilePic!
          : '${AppConstants.baseUrl}${user.profilePic}';
      final url = '$base${base.contains('?') ? '&' : '?'}v=$_profilePicVersion';
      // Key by user id so each user has their own image; avoids showing previous user's cached photo
      return Image.network(
        url,
        key: ValueKey('profile_${user!.id}_$url'),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _profilePlaceholder(),
      );
    }
    return _profilePlaceholder();
  }

  Widget _profilePlaceholder() {
    return Container(
      color: Colors.white,
      child: const Icon(Icons.person, size: 64, color: _profilePrimary),
    );
  }

  Widget _headerButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  void _showAccountSettingsDrawer() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSettingsOption(
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFFA3D9E5),
                      title: 'Change Password',
                      onTap: () async {
                        Navigator.of(context).pop(); // Close drawer
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) => const ChangePasswordDialog(),
                        );
                        if (result != true) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Mot de passe mis à jour. Veuillez vous reconnecter.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _handleLogout();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFFA3D9E5),
                      title: 'Change Email',
                      onTap: () async {
                        Navigator.of(context).pop(); // Close drawer
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) => const ChangeEmailDialog(),
                        );
                        if (result != true) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Email mis à jour. Veuillez vous reconnecter.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _handleLogout();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.language_outlined,
                      iconColor: const Color(0xFFA3D9E5),
                      title: 'Change Language',
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        _showLanguageDialog();
                      },
                    ),
                    _buildSettingsOption(
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFFA3D9E5),
                      title: 'Change Phone',
                      onTap: () async {
                        Navigator.of(context).pop(); // Close drawer
                        final messenger = ScaffoldMessenger.of(context);
                        final user =
                            Provider.of<AuthProvider>(context, listen: false)
                                .user;
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) =>
                              ChangePhoneDialog(currentPhone: user?.phone),
                        );
                        if (result != true) return;
                        _refreshProfile();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Téléphone mis à jour'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Color(0xFF94A3B8),
        ),
        onTap: onTap,
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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
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
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(_familyMembers.length, (i) {
                  final m = _familyMembers[i];
                  final bgColor = i == 0
                      ? _profilePrimary.withOpacity(0.2)
                      : Colors.orange.shade100;
                  return Padding(
                    padding: EdgeInsets.only(
                        right: i < _familyMembers.length - 1 ? 16 : 0),
                    child: _familyMemberChip(m, bgColor, () async {
                      final id = m.id;
                      setState(() => _familyMembers.removeAt(i));
                      _saveFamilyMembers();
                      if (id != null && id.isNotEmpty) {
                        try {
                          await AuthService().deleteFamilyMember(id);
                        } catch (_) {}
                      }
                    }),
                  );
                }),
                const SizedBox(width: 16),
                _addMemberChip(loc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberImage(_FamilyMemberItem member) {
    if (member.imagePath != null) {
      return Image.file(
        File(member.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: _profilePrimary),
      );
    }
    final url = member.imageUrl != null && member.imageUrl!.trim().isNotEmpty
        ? (member.imageUrl!.startsWith('http')
            ? member.imageUrl!
            : AppConstants.fullImageUrl(member.imageUrl!))
        : null;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: _profilePrimary),
      );
    }
    return const Icon(Icons.person, color: _profilePrimary);
  }

  Widget _familyMemberChip(
      _FamilyMemberItem member, Color bgColor, VoidCallback onDelete) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
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
                child: _buildFamilyMemberImage(member),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1)),
                      ],
                    ),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(member.name,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.text)),
      ],
    );
  }

  Future<void> _showAddFamilyMemberDialog(AppLocalizations loc) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (!mounted || file == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.addMember),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: loc.fullNameLabel,
            hintText: 'Thomas',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) =>
              Navigator.of(ctx).pop(v.trim().isEmpty ? 'Membre' : v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(
                nameController.text.trim().isEmpty
                    ? 'Membre'
                    : nameController.text.trim()),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    try {
      final added = await AuthService().addFamilyMember(File(file.path), name);
      if (!mounted) return;
      final imageUrl = (added['imageUrl']?.toString() ?? '').trim();
      setState(() => _familyMembers.add(_FamilyMemberItem(
            id: added['id'],
            name: added['name'] ?? name,
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
          )));
      await _saveFamilyMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Membre ajouté'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _addMemberChip(AppLocalizations loc) {
    return InkWell(
      onTap: () => _showAddFamilyMemberDialog(loc),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                  width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.grey.shade400, size: 28),
          ),
          const SizedBox(height: 8),
          Text(loc.addMember,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500)),
        ],
      ),
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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
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
            onTap: () =>
                context.push(AppConstants.familyCreateSecurityCodeRoute),
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
                    child: Icon(Icons.lock_outline,
                        color: Colors.orange.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.securityCode,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.manageChildModeExitCode,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey.shade400),
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
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _profilePrimary;
                  }
                  return null;
                }),
                trackColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _profilePrimary.withOpacity(0.5);
                  }
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
        onTap: () async {
          final gp = context.read<GamificationProvider>();
          await gp.initialize();
          final childId = gp.currentChildId;
          if (context.mounted) {
            final path = childId != null && childId.isNotEmpty
                ? '${AppConstants.familyEngagementDashboardRoute}?childId=${Uri.encodeComponent(childId)}'
                : AppConstants.familyEngagementDashboardRoute;
            context.push(path);
          }
        },
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
                  boxShadow: [
                    BoxShadow(
                        color: _profilePrimary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child:
                    const Icon(Icons.favorite, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.engagement.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _profilePrimary,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '14 ${loc.activitiesThisWeek}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text),
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

  Widget _buildInfoCard(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
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
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
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
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
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
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.text),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
