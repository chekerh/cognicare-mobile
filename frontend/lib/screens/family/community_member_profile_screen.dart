import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../models/community_post.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../utils/constants.dart';

/// Couleurs alignées sur le HTML Premium (primary #a3dae1, gradient).
const Color _primary = Color(0xFFA3DAE1);
const Color _secondary = Color(0xFF7FBAC4);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _cardLight = Color(0xFFFFFFFF);
const Color _slate800 = Color(0xFF334155);
const Color _slate500 = Color(0xFF64748B);
const Color _slate400 = Color(0xFF94A3B8);

/// Profil d'un membre de la communauté — avatar, nom, rôle, Message, Suivre, Parcours, Principaux, stats.
class CommunityMemberProfileScreen extends StatefulWidget {
  const CommunityMemberProfileScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    this.memberRole,
    this.memberImageUrl,
    this.memberDiagnosis,
    this.memberJourney,
    this.memberTags,
    this.postsCount,
    this.followersCount,
    this.helpsCount,
  });

  final String memberId;
  final String memberName;
  final String? memberRole;
  final String? memberImageUrl;
  final String? memberDiagnosis;
  final String? memberJourney;
  final List<String>? memberTags;
  final int? postsCount;
  final int? followersCount;
  final int? helpsCount;

  @override
  State<CommunityMemberProfileScreen> createState() =>
      _CommunityMemberProfileScreenState();

  static CommunityMemberProfileScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    final q = state.uri.queryParameters;
    // Permet d'ouvrir le profil depuis un lien partagé (query params)
    final memberId = e['memberId'] as String? ?? q['memberId'] ?? '';
    final memberName = e['memberName'] as String? ?? q['memberName'] ?? 'Membre';
    final tags = e['memberTags'] as List<dynamic>?;
    return CommunityMemberProfileScreen(
      memberId: memberId,
      memberName: memberName,
      memberRole: e['memberRole'] as String? ?? 'Parent de Iline',
      memberImageUrl: e['memberImageUrl'] as String?,
      memberDiagnosis:
          e['memberDiagnosis'] as String? ?? 'Diagnostic : Autisme léger',
      memberJourney: e['memberJourney'] as String? ??
          'Nous naviguons dans ce parcours depuis 3 ans. Toujours ouvert à partager nos découvertes sur les outils sensoriels.',
      memberTags: tags?.map((t) => t.toString()).toList() ??
          [
            'Conseils en orthophonie',
            'Soutien émotionnel',
            'Activités sensorielles',
            'Inclusion scolaire'
          ],
      postsCount: e['postsCount'] as int? ?? 124,
      followersCount: e['followersCount'] as int? ?? 1200,
      helpsCount: e['helpsCount'] as int? ?? 450,
    );
  }
}

class _CommunityMemberProfileScreenState
    extends State<CommunityMemberProfileScreen> {
  String? _followStatus;
  String? _followRequestId;
  bool _followLoading = false;
  bool? _isOnline;
  bool _isInFriendsList = false;

  List<CommunityPost>? _memberPosts;
  bool _loadingPosts = false;
  String? _postsError;

  List<CommunityFriend>? _memberFriends;
  bool _loadingFriends = false;

  MemberContactInfo? _memberContactInfo;
  bool _loadingContact = false;

  /// Infos publiques du membre (nom, photo, email, téléphone) — chargées pour tout profil.
  MemberPublicInfo? _loadedPublicInfo;
  bool _loadingPublicInfo = false;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
    _loadPresence();
    _loadFriendsCheck();
    _loadMemberPosts();
    _loadMemberFriends();
    _loadMemberContactInfo();
    if (widget.memberId.isNotEmpty) _loadMemberPublicInfo();
  }

  Future<void> _loadMemberPublicInfo() async {
    if (widget.memberId.isEmpty) return;
    setState(() => _loadingPublicInfo = true);
    try {
      final info = await CommunityService().getMemberPublicInfo(widget.memberId);
      if (!mounted) return;
      setState(() {
        _loadedPublicInfo = info;
        _loadingPublicInfo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadedPublicInfo = null;
        _loadingPublicInfo = false;
      });
    }
  }

  Future<void> _loadMemberContactInfo() async {
    if (widget.memberId.isEmpty) return;
    setState(() => _loadingContact = true);
    try {
      final info = await CommunityService().getMemberContactInfo(widget.memberId);
      if (!mounted) return;
      setState(() {
        _memberContactInfo = info;
        _loadingContact = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memberContactInfo = null;
        _loadingContact = false;
      });
    }
  }

  Future<void> _loadMemberFriends() async {
    if (widget.memberId.isEmpty) return;
    setState(() => _loadingFriends = true);
    try {
      final list =
          await CommunityService().getFriendsOfUser(widget.memberId);
      if (!mounted) return;
      setState(() {
        _memberFriends = list;
        _loadingFriends = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memberFriends = [];
        _loadingFriends = false;
      });
    }
  }

  Future<void> _loadMemberPosts() async {
    if (widget.memberId.isEmpty) return;
    setState(() {
      _loadingPosts = true;
      _postsError = null;
    });
    try {
      final list =
          await CommunityService().getPostsByAuthor(widget.memberId);
      if (!mounted) return;
      setState(() {
        _memberPosts = list;
        _loadingPosts = false;
        _postsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memberPosts = null;
        _loadingPosts = false;
        _postsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadPresence() async {
    if (widget.memberId.isEmpty) return;
    try {
      final online = await AuthService().getPresence(widget.memberId);
      if (!mounted) return;
      setState(() => _isOnline = online);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOnline = false);
    }
  }

  Future<void> _loadFollowStatus() async {
    if (widget.memberId.isEmpty) return;
    try {
      final result =
          await CommunityService().getFollowStatus(widget.memberId);
      if (mounted) {
        setState(() {
          _followStatus = result?.status;
          _followRequestId = result?.requestId;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _followStatus = null;
        _followRequestId = null;
      });
    }
  }

  Future<void> _loadFriendsCheck() async {
    if (widget.memberId.isEmpty) return;
    try {
      final friends = await CommunityService().getFriends();
      if (mounted) {
        setState(() => _isInFriendsList =
            friends.any((f) => f.id == widget.memberId));
      }
    } catch (_) {
      if (mounted) setState(() => _isInFriendsList = false);
    }
  }

  static const String _defaultRole = 'Parent de Iline';
  static const String _defaultDiagnosis = 'Diagnostic : Autisme léger';
  static const String _defaultJourney =
      'Nous naviguons dans ce parcours depuis 3 ans. Toujours ouvert à partager nos découvertes sur les outils sensoriels.';
  static const List<String> _defaultTags = [
    'Orthophonie',
    'Soutien Émotionnel',
  ];

  @override
  Widget build(BuildContext context) {
    final role = widget.memberRole ?? _defaultRole;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildGradientHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding),
                child: Column(
                  children: [
                    _buildProfileSection(_displayName, role),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 32),
                    _buildMesAmisSection(),
                    const SizedBox(height: 24),
                    _buildInformationsPersonnellesCard(),
                    const SizedBox(height: 24),
                    _buildPublicationsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.arrow_back_ios_new, color: _slate800, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  String get _displayName =>
      _loadedPublicInfo?.fullName ?? widget.memberName;

  String? get _displayImageUrl =>
      _loadedPublicInfo?.profilePic ?? widget.memberImageUrl;

  Widget _buildProfileSection(String name, String role) {
    final imageUrl = _displayImageUrl != null && _displayImageUrl!.isNotEmpty
        ? AppConstants.fullImageUrl(_displayImageUrl!)
        : null;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _cardLight, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: _cardLight,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: _primary.withOpacity(0.2),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                                    color: _secondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: _primary.withOpacity(0.2),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _secondary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (_isOnline == true)
            Positioned(
                  bottom: 2,
                  right: 2,
              child: Container(
                    width: 28,
                    height: 28,
                decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                      border: Border.all(color: _cardLight, width: 4),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _slate800,
            ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
            role.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _slate500,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _isOnline == true ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isOnline == true ? _primary : _slate400,
            ),
            textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isPending = _followStatus == 'pending';
    final isAccepted =
        _followStatus == 'accepted' || _isInFriendsList;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
      children: [
        Expanded(
            child: Material(
                color: _primary,
                borderRadius: BorderRadius.circular(20),
                shadowColor: _primary.withOpacity(0.3),
                elevation: 4,
                child: InkWell(
                  onTap: () {
              context.push(
                      '${AppConstants.familyPrivateChatRoute}?id=${Uri.encodeComponent(widget.memberId)}&name=${Uri.encodeComponent(_displayName)}${_displayImageUrl != null && _displayImageUrl!.isNotEmpty ? '&imageUrl=${Uri.encodeComponent(AppConstants.fullImageUrl(_displayImageUrl!))}' : ''}',
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: _slate800, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            loc.privateMessageAction,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _slate800,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
              child: _followLoading
                  ? const SizedBox(
                      height: 52,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Material(
                      color: isAccepted ? _slate800.withOpacity(0.6) : _slate800,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: isAccepted
                            ? null
                            : isPending
                                ? () => _onCancelRequest(context)
                                : () => _onFollowTap(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAccepted ? Icons.people : Icons.person_add,
                                size: 20,
                                color: isAccepted ? Colors.white70 : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isAccepted
                                      ? loc.followStatusFriends
                                      : isPending
                                          ? loc.cancelFollowRequestLabel
                                          : loc.followAction,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isAccepted ? Colors.white70 : Colors.white,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Material(
              color: _slate800.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  final base = AppConstants.baseUrl.endsWith('/')
                      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
                      : AppConstants.baseUrl;
                  final profileLink = '$base/profile/member/${widget.memberId}';
                  final shareText = 'Découvre le profil de $_displayName sur CogniCare : $profileLink';
                  Share.share(
                    shareText,
                    subject: 'Profil de $_displayName',
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox(
                  width: 56,
                  height: 52,
                  child: Icon(Icons.share, color: _slate500, size: 22),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMesAmisSection() {
    final count = _memberFriends?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Mes Amis ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _slate800,
                  ),
                  children: [
                    TextSpan(
                      text: '($count)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: _slate400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push(
                  AppConstants.familyFriendsRoute,
                  extra: {
                    'userId': widget.memberId,
                    'memberName': _displayName,
                  },
                ),
                child: const Text(
                  'Tout voir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _loadingFriends
            ? const SizedBox(
                height: 88,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : count == 0
                ? const SizedBox(
                    height: 88,
                    child: Center(
                      child: Text(
                        'Aucun ami',
                        style: TextStyle(
                          fontSize: 14,
                          color: _slate400,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: (_memberFriends ?? []).map((f) {
                        final imageUrl = f.profilePic != null && f.profilePic!.isNotEmpty
                            ? AppConstants.fullImageUrl(f.profilePic!)
                            : null;
                        return _friendChip(
                          f.fullName,
                          imageUrl,
                          memberId: f.id,
                          memberName: f.fullName,
                          memberImageUrl: f.profilePic,
                          highlighted: false,
                        );
                      }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _friendChip(
    String name,
    String? imageUrl, {
    bool highlighted = false,
    String? memberId,
    String? memberName,
    String? memberImageUrl,
  }) {
    final content = Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: highlighted ? Border.all(color: _primary, width: 2) : null,
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: _primary.withOpacity(0.2),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Text(
                      name.isNotEmpty ? name.substring(0, 1) : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primary,
                          fontSize: 20),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _slate500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (memberId != null && memberId.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          context.push(
            AppConstants.familyCommunityMemberProfileRoute,
            extra: {
              'memberId': memberId,
              'memberName': memberName ?? name,
              'memberImageUrl': memberImageUrl,
            },
          );
        },
        child: content,
      );
    }
    return content;
  }

  Widget _buildInformationsPersonnellesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _slate800,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingContact || _loadingPublicInfo)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            _buildContactContent(),
        ],
      ),
    );
  }

  Widget _buildContactContent() {
    final loc = AppLocalizations.of(context)!;
    final email = _loadedPublicInfo?.email ?? _memberContactInfo?.email;
    final phone = _loadedPublicInfo?.phone ?? _memberContactInfo?.phone;
    final location = _loadedPublicInfo?.location ?? _memberContactInfo?.location;
    final hasEmail = (email ?? '').isNotEmpty;
    final hasPhone = (phone ?? '').isNotEmpty;
    final hasLocation = (location ?? '').isNotEmpty;
    if (!hasEmail && !hasPhone && !hasLocation) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Aucune information de contact partagée.',
          style: TextStyle(
            fontSize: 14,
            color: _slate400,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasEmail)
          _buildContactRow(Icons.email_outlined, loc.emailInfo, email!),
        if (hasEmail && (hasPhone || hasLocation)) const SizedBox(height: 12),
        if (hasPhone)
          _buildContactRow(Icons.phone_outlined, loc.phoneInfo, phone!),
        if (hasPhone && hasLocation) const SizedBox(height: 12),
        if (hasLocation)
          _buildContactRow(Icons.location_on_outlined, loc.locationInfo, location!),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                  style: TextStyle(
                      fontSize: 12,
                  color: _slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _slate800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onFollowTap(BuildContext context) async {
    if (widget.memberId.isEmpty) return;
    setState(() => _followLoading = true);
    try {
      final result = await CommunityService().createFollowRequest(widget.memberId);
      if (!mounted) return;
      setState(() {
        _followLoading = false;
        _followStatus = 'pending';
        _followRequestId = result.requestId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.followRequestSent),
          backgroundColor: _secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _followLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onCancelRequest(BuildContext context) async {
    final requestId = _followRequestId;
    if (requestId == null || requestId.isEmpty) {
      // Pas d'id : on met quand même à jour l'UI pour afficher Suivre (demande peut déjà être supprimée).
      setState(() {
        _followStatus = null;
        _followRequestId = null;
      });
      return;
    }
    setState(() => _followLoading = true);
    try {
      await CommunityService().cancelFollowRequest(requestId);
      if (!mounted) return;
      setState(() {
        _followLoading = false;
        _followStatus = null;
        _followRequestId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.followRequestCancelled),
          backgroundColor: _secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadFollowStatus();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _followLoading = false);
      // Si "not found" ou erreur 404 : la demande n'existe plus, on met à jour l'UI pour pouvoir recliquer Suivre.
      if (msg.toLowerCase().contains('not found') || msg.contains('404')) {
        setState(() {
          _followStatus = null;
          _followRequestId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.followRequestCancelled),
            backgroundColor: _secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPublicationsSection() {
    if (_loadingPosts) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (_postsError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Publications récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _slate800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _postsError!,
              style: TextStyle(fontSize: 14, color: _slate500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    final list = _memberPosts ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Publications récentes',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _slate800,
            ),
          ),
        ),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.article_outlined,
                      size: 48, color: _primary.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune publication',
                    style: TextStyle(
                      fontSize: 14,
                      color: _slate500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...list.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPostCard(post),
              )),
      ],
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final imageUrl = post.authorProfilePic != null &&
            post.authorProfilePic!.isNotEmpty
        ? AppConstants.fullImageUrl(post.authorProfilePic!)
        : null;
    final postImageUrl = post.hasImage && post.imagePath != null
        ? (post.imagePath!.startsWith('http')
            ? post.imagePath!
            : AppConstants.fullImageUrl(post.imagePath!))
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primary.withOpacity(0.2),
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null
                    ? const Icon(Icons.person, color: _primary, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    Text(
                      post.timeAgo,
                  style: TextStyle(
                      fontSize: 12,
                        color: _slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.text,
                          style: const TextStyle(
                              fontSize: 14,
              color: _slate800,
              height: 1.5,
            ),
          ),
          if (postImageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                postImageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                post.likeCount > 0 ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: post.likeCount > 0 ? _primary : _slate500,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.likeCount}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _slate500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 20, color: _slate500),
              const SizedBox(width: 6),
              Text(
                '${post.commentCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _slate500,
                ),
              ),
              const Spacer(),
              Icon(Icons.bookmark_border, size: 22, color: _slate400),
            ],
          ),
        ],
      ),
    );
  }
}
