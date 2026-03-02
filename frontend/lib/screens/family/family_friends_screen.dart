import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../utils/constants.dart';

/// Écran "Mes Amis" — liste d'amis, demandes en attente, recherche, statut en ligne.
const Color _primary = Color(0xFFA3DAE1);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);

String _imageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}

class FamilyFriendsScreen extends StatefulWidget {
  const FamilyFriendsScreen({
    super.key,
    this.userId,
    this.memberName,
  });

  /// Si défini, affiche les amis de cet utilisateur (ex. profil de Malek → amis de Malek).
  final String? userId;
  final String? memberName;

  @override
  State<FamilyFriendsScreen> createState() => _FamilyFriendsScreenState();
}

class _FamilyFriendsScreenState extends State<FamilyFriendsScreen> {
  final CommunityService _community = CommunityService();
  List<CommunityFriend> _friends = [];
  List<PendingFollowRequest> _pending = [];
  Map<String, bool> _presence = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isViewingOtherProfile => widget.userId != null && widget.userId!.isNotEmpty;

  bool _isVolunteerContext(BuildContext context) {
    final path = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return path.startsWith('/volunteer');
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final friends = _isViewingOtherProfile
          ? await _community.getFriendsOfUser(widget.userId!)
          : await _community.getFriends();
      final pending = _isViewingOtherProfile
          ? <PendingFollowRequest>[]
          : await _community.getPendingFollowRequests();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _pending = pending;
      });
      _loadPresence();
    } catch (_) {
      if (mounted) setState(() {
        _friends = [];
        _pending = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPresence() async {
    if (_friends.isEmpty) return;
    final ids = _friends.map((f) => f.id).toList();
    final results = <String, bool>{};
    await Future.wait(ids.map((id) async {
      try {
        final online = await AuthService().getPresence(id);
        results[id] = online;
      } catch (_) {
        results[id] = false;
      }
    }));
    if (mounted) setState(() => _presence = results);
  }

  List<CommunityFriend> get _filteredFriends {
    if (_searchQuery.trim().isEmpty) return _friends;
    final q = _searchQuery.trim().toLowerCase();
    return _friends.where((f) => f.fullName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                      children: [
                        if (!_isViewingOtherProfile) ...[
                          _buildPendingCard(loc),
                          const SizedBox(height: 32),
                        ],
                        Text(
                          _friendsSectionTitle(loc),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._filteredFriends.map((f) => _buildFriendTile(
                              context,
                              f,
                              _presence[f.id] ?? false,
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 24),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _myFriendsTitle(loc),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (!_isViewingOtherProfile)
                    Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => context.push(AppConstants.familyFindFamiliesRoute),
                        borderRadius: BorderRadius.circular(20),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40, height: 40),
                  if (!_isViewingOtherProfile && _pending.isNotEmpty)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _primary, width: 2),
                        ),
                        child: Text(
                          '${_pending.length > 99 ? 99 : _pending.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isViewingOtherProfile)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: _searchFriendHint(loc),
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.85),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(AppLocalizations loc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Bénévole → /volunteer/friend-requests, Famille → /family/friend-requests (sinon redirection).
          final baseRoute = _isVolunteerContext(context)
              ? AppConstants.volunteerFriendRequestsRoute
              : AppConstants.familyFriendRequestsRoute;
          final uniqueId = DateTime.now().millisecondsSinceEpoch;
          context.push('$baseRoute/$uniqueId');
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.notifications_active, color: _primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _friendRequestsTitle(loc),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _pending.isEmpty
                          ? _noNewRequests(loc)
                          : _newRequestsCount(loc, _pending.length),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendTile(
    BuildContext context,
    CommunityFriend friend,
    bool isOnline,
  ) {
    final imageUrl = friend.profilePic != null && friend.profilePic!.isNotEmpty
        ? _imageUrl(friend.profilePic)
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push(
            AppConstants.familyCommunityMemberProfileRoute,
            extra: {
              'memberId': friend.id,
              'memberName': friend.fullName,
              'memberImageUrl': imageUrl.isEmpty ? null : imageUrl,
            },
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _primary.withOpacity(0.2),
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.person, color: _primary, size: 28)
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? 'En ligne' : 'Hors ligne',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _textMuted, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _myFriendsTitle(AppLocalizations loc) {
    if (_isViewingOtherProfile && widget.memberName != null && widget.memberName!.isNotEmpty) {
      return 'Amis de ${widget.memberName}';
    }
    return 'Mes Amis';
  }

  String _searchFriendHint(AppLocalizations loc) => 'Rechercher un ami...';
  String _friendRequestsTitle(AppLocalizations loc) => 'Demandes d\'amis';
  String _noNewRequests(AppLocalizations loc) => 'Aucune nouvelle demande';
  String _newRequestsCount(AppLocalizations loc, int n) =>
      n == 1 ? '1 nouvelle demande' : '$n nouvelles demandes';
  String _friendsSectionTitle(AppLocalizations loc) =>
      _isViewingOtherProfile
          ? 'Tous les amis (${_filteredFriends.length})'
          : 'Tous les amis (${_filteredFriends.length})';
}
