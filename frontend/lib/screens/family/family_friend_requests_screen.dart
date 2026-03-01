import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/community_service.dart';
import '../../utils/constants.dart';

/// Écran "Demandes d'amis" — liste des demandes en attente avec Accepter / Supprimer.
const Color _primary = Color(0xFFA3DAE1);
const Color _primaryShadow = Color(0xFF86C0C8);
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

class FamilyFriendRequestsScreen extends StatefulWidget {
  const FamilyFriendRequestsScreen({super.key});

  @override
  State<FamilyFriendRequestsScreen> createState() =>
      _FamilyFriendRequestsScreenState();
}

class _FamilyFriendRequestsScreenState
    extends State<FamilyFriendRequestsScreen> {
  final CommunityService _community = CommunityService();
  List<PendingFollowRequest> _pending = [];
  bool _loading = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _community.getPendingFollowRequests();
      if (mounted) setState(() => _pending = list);
    } catch (_) {
      if (mounted) setState(() => _pending = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String requestId) async {
    if (_processingIds.contains(requestId)) return;
    setState(() => _processingIds.add(requestId));
    try {
      await _community.acceptFollowRequest(requestId);
      if (!mounted) return;
      setState(() {
        _pending = _pending.where((r) => r.id != requestId).toList();
        _processingIds.remove(requestId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.followRequestAccept),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _processingIds.remove(requestId));
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

  Future<void> _decline(String requestId) async {
    if (_processingIds.contains(requestId)) return;
    setState(() => _processingIds.add(requestId));
    try {
      await _community.declineFollowRequest(requestId);
      if (!mounted) return;
      setState(() {
        _pending = _pending.where((r) => r.id != requestId).toList();
        _processingIds.remove(requestId);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _pending = _pending.where((r) => r.id != requestId).toList();
          _processingIds.remove(requestId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primary,
              Color(0xFFF8FAFC),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _pending.isEmpty
                        ? _buildEmpty(context)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                            itemCount: _pending.length,
                            itemBuilder: (context, index) {
                              final r = _pending[index];
                              return _buildRequestCard(context, r);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white.withOpacity(0.4),
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
          const Text(
            'Demandes d\'amis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Plus de demandes en attente',
          style: TextStyle(
            fontSize: 14,
            color: _textMuted.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, PendingFollowRequest request) {
    final imageUrl = request.requesterProfilePic != null &&
            request.requesterProfilePic!.isNotEmpty
        ? _imageUrl(request.requesterProfilePic)
        : '';
    final initial = request.requesterName.isNotEmpty
        ? request.requesterName[0].toUpperCase()
        : '?';
    final isProcessing = _processingIds.contains(request.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarPlaceholder(initial),
                          )
                        : _avatarPlaceholder(initial),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Demande de suivi',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAcceptButton(
                    onPressed: isProcessing ? null : () => _accept(request.id),
                    loading: isProcessing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDeclineButton(
                    onPressed: isProcessing ? null : () => _decline(request.id),
                    label: 'Supprimer',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(String initial) {
    return Container(
      color: _primary.withOpacity(0.15),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptButton({VoidCallback? onPressed, bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryShadow.withOpacity(0.8),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Accepter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeclineButton({VoidCallback? onPressed, required String label}) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
