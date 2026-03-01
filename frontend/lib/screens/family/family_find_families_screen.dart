import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../services/community_service.dart';
import '../../utils/constants.dart';

/// Écran "Trouver des Familles" — recherche et envoi de demande de suivi (Se connecter).
const Color _primary = Color(0xFFA3DAE1);
const Color _bgLight = Color(0xFFF0F9FA);
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

class FamilyFindFamiliesScreen extends StatefulWidget {
  const FamilyFindFamiliesScreen({super.key});

  @override
  State<FamilyFindFamiliesScreen> createState() =>
      _FamilyFindFamiliesScreenState();
}

class _FamilyFindFamiliesScreenState extends State<FamilyFindFamiliesScreen> {
  final ChatService _chatService = ChatService();
  final CommunityService _community = CommunityService();
  List<FamilyUser> _allFamilies = [];
  Map<String, String?> _statusByUserId = {};
  String _searchQuery = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _chatService.getFamiliesToContact();
      if (!mounted) return;
      setState(() {
        _allFamilies = list;
        _loading = false;
      });
      _loadStatuses(list.map((e) => e.id).toList());
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadStatuses(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final statuses = <String, String?>{};
    await Future.wait(userIds.take(50).map((id) async {
      try {
        final r = await _community.getFollowStatus(id);
        statuses[id] = r?.status;
      } catch (_) {
        statuses[id] = null;
      }
    }));
    if (mounted) setState(() => _statusByUserId = statuses);
  }

  /// Affiche des résultats uniquement après une recherche (pas de liste par défaut).
  List<FamilyUser> get _filtered {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.trim().toLowerCase();
    return _allFamilies
        .where((f) => f.fullName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
      decoration: BoxDecoration(
        color: _bgLight,
        border: Border(bottom: BorderSide(color: _primary.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: _textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Trouver des Familles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou lieu',
                hintStyle: TextStyle(color: _textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: _primary, size: 22),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Même diagnostic que Léo', true),
                const SizedBox(width: 8),
                _chip('Proximité', false),
                const SizedBox(width: 8),
                _chip('Filtres', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? _primary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: active ? _primary : _primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.verified : Icons.location_on,
            size: 18,
            color: active ? _textPrimary : _textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? _textPrimary : _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _textMuted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final list = _filtered;
    if (_searchQuery.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 56, color: _primary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Entrez un nom pour rechercher des familles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Les résultats s\'afficheront ici avec le bouton « Se connecter » pour envoyer une demande.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _textMuted.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Aucun résultat pour « $_searchQuery »',
          style: TextStyle(fontSize: 14, color: _textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final f = list[index];
        final status = _statusByUserId[f.id];
        return _buildCard(context, f, status);
      },
    );
  }

  Widget _buildCard(BuildContext context, FamilyUser family, String? status) {
    final loc = AppLocalizations.of(context)!;
    final isAccepted = status == 'accepted';
    final isPending = status == 'pending';
    final imageUrl = family.profilePic != null && family.profilePic!.isNotEmpty
        ? _imageUrl(family.profilePic)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withOpacity(0.05)),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: imageUrl.isEmpty
                  ? Container(
                      width: 56,
                      height: 56,
                      color: _primary.withOpacity(0.2),
                      child: Center(
                        child: Text(
                          family.fullName.isNotEmpty
                              ? family.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: _primary.withOpacity(0.2),
                        child: const Icon(Icons.person, color: _primary),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Famille',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildActionButton(context, family.id, isAccepted, isPending, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String userId,
    bool isAccepted,
    bool isPending,
    AppLocalizations loc,
  ) {
    if (isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          loc.followStatusFriends,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _textMuted.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          loc.followRequestPendingLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _textMuted,
          ),
        ),
      );
    }
    return Material(
      color: _primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _sendRequest(context, userId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: const Text(
            'Se connecter',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context, String targetUserId) async {
    try {
      await _community.createFollowRequest(targetUserId);
      if (!mounted) return;
      setState(() => _statusByUserId[targetUserId] = 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.followRequestSent),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
