import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reel.dart';
import '../../services/reels_service.dart';

/// Écran Reels — vidéos courtes filtrées (troubles cognitifs / autisme), source YouTube + filtre IA.
class FamilyReelsScreen extends StatefulWidget {
  const FamilyReelsScreen({super.key});

  @override
  State<FamilyReelsScreen> createState() => _FamilyReelsScreenState();
}

class _FamilyReelsScreenState extends State<FamilyReelsScreen> {
  final ReelsService _reelsService = ReelsService();
  List<Reel> _reels = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _refreshMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    try {
      final result = await _reelsService.getReels(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _reels = result.reels;
        _loading = false;
        _hasMore = result.page < result.totalPages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final result = await _reelsService.getReels(page: nextPage, limit: 20);
      if (!mounted) return;
      setState(() {
        _reels.addAll(result.reels);
        _page = nextPage;
        _hasMore = result.page < result.totalPages;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefreshReels() async {
    setState(() {
      _refreshing = true;
      _refreshMessage = null;
    });
    try {
      final result = await _reelsService.refreshReels();
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _refreshMessage =
            '${result.added} vidéo(s) ajoutée(s).';
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _refreshMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openReel(Reel reel) async {
    final uri = Uri.parse(reel.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static const Color _bg = Color(0xFF1E293B);
  static const Color _cardBg = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          loc.reelsCardTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des vidéos...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sur Render, le 1er chargement peut prendre 30–60 s.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assurez-vous que le backend est démarré et que l\'app peut le joindre (même réseau ou URL de prod).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Réessayer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF475569),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _reels.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.reelsCardSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune vidéo pour le moment. Les reels sont filtrés pour les troubles cognitifs et l\'autisme.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_refreshMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _refreshMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _refreshing ? null : _onRefreshReels,
                                icon: _refreshing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded, size: 22),
                                label: Text(
                                  _refreshing
                                      ? 'Chargement...'
                                      : 'Charger les vidéos',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF475569),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _reels.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _reels.length) {
                          _loadMore();
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: Colors.white54,
                                    strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final reel = _reels[index];
                        return _ReelCard(
                          reel: reel,
                          onTap: () => _openReel(reel),
                        );
                      },
                    ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.reel, required this.onTap});

  final Reel reel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Image.network(
                    reel.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black26,
                      child: const Icon(
                        Icons.videocam_rounded,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reel.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reel.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reel.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            size: 20,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ouvrir la vidéo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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
