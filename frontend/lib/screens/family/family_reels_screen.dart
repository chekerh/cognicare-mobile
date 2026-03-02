import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reel.dart';
import '../../services/reels_service.dart';

/// Écran Reels — défilement vertical type Instagram, lecture intégrée (pas de navigation YouTube).
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
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        _refreshMessage = '${result.added} vidéo(s) ajoutée(s).';
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _refreshMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  static const Color _bg = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasReels = _reels.isNotEmpty && !_loading && _error == null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: hasReels
          ? _buildReelsFeedFullScreen(context, loc)
          : SafeArea(
              child: _loading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _buildEmpty(loc),
            ),
    );
  }

  /// Feed plein écran type Instagram : une vidéo par écran, scroll vertical, bouton retour en overlay.
  Widget _buildReelsFeedFullScreen(BuildContext context, AppLocalizations loc) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        // PageView plein écran — une vidéo par page, scroll vertical, autoplay sur la page visible
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _reels.length + (_hasMore ? 1 : 0),
          onPageChanged: (index) {
            setState(() => _currentPageIndex = index);
            if (index >= _reels.length - 2 && _hasMore && !_loadingMore) _loadMore();
          },
          itemBuilder: (context, index) {
            if (index >= _reels.length) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: _loadingMore
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                            strokeWidth: 2,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }
            return _ReelFullPage(
              reel: _reels[index],
              isActive: index == _currentPageIndex,
            );
          },
        ),
        // Bouton retour en overlay (zone safe)
        Positioned(
          top: topPadding + 4,
          left: 8,
          child: Material(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Chargement des vidéos...',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Sur Render, le 1er chargement peut prendre 30–60 s.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Assurez-vous que le backend est démarré et que l\'app peut le joindre.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
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
    );
  }

  Widget _buildEmpty(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_rounded, size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              loc.reelsCardSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune vidéo pour le moment. Les reels sont filtrés pour les troubles cognitifs et l\'autisme.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (_refreshMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _refreshMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 22),
                label: Text(_refreshing ? 'Chargement...' : 'Charger les vidéos'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF475569),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// URL d’embed pour lecture dans l’app (pas d’ouverture YouTube/Dailymotion externe).
String _embedUrlForReel(Reel reel) {
  switch (reel.source) {
    case 'dailymotion':
      return 'https://www.dailymotion.com/embed/video/${reel.sourceId}?autoplay=1&mute=1';
    case 'youtube':
    case 'scraped':
    default:
      // youtube-nocookie limite l'erreur 153 (configuration lecteur) en respectant la politique de referrer
      return 'https://www.youtube-nocookie.com/embed/${reel.sourceId}?autoplay=1&mute=1';
  }
}

class _ReelFullPage extends StatefulWidget {
  const _ReelFullPage({required this.reel, required this.isActive});

  final Reel reel;
  final bool isActive;

  @override
  State<_ReelFullPage> createState() => _ReelFullPageState();
}

class _ReelFullPageState extends State<_ReelFullPage> {
  late final WebViewController _controller;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final embedUrl = _embedUrlForReel(widget.reel);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _triggerAutoplay(),
          onWebResourceError: (error) {
            if (mounted) setState(() => _loadFailed = true);
          },
        ),
      );
    if (Platform.isAndroid) {
      _controller.setBackgroundColor(Colors.black);
    }
    _controller.loadRequest(Uri.parse(embedUrl));
  }

  /// Force la lecture automatique sans bouton : video.play() ou clic sur play après chargement.
  void _triggerAutoplay() {
    void runPlay() {
      if (!mounted) return;
      _controller.runJavaScript('''
        (function() {
          var v = document.querySelector('video');
          if (v) { v.muted = true; v.play().catch(function(){}); return; }
          var btn = document.querySelector('[aria-label="Play"], [aria-label="Lire"], .dmp_PlayButton, button[class*="play"], .np_icodnp_play');
          if (btn) { btn.click(); return; }
          var svg = document.querySelector('svg[class*="play"]');
          if (svg && svg.closest('button')) svg.closest('button').click();
        })();
      ''');
    }
    Future.delayed(const Duration(milliseconds: 600), runPlay);
    Future.delayed(const Duration(milliseconds: 1800), runPlay);
  }

  @override
  void didUpdateWidget(covariant _ReelFullPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _pauseVideo();
    }
  }

  void _pauseVideo() {
    try {
      _controller.runJavaScript('''
        (function() {
          var v = document.querySelector('video');
          if (v) v.pause();
          var iframe = document.querySelector('iframe');
          if (iframe && iframe.contentWindow) {
            try {
              var iv = iframe.contentDocument && iframe.contentDocument.querySelector('video');
              if (iv) iv.pause();
            } catch(e) {}
          }
        })();
      ''');
    } catch (_) {}
  }

  void _retryLoad() {
    setState(() => _loadFailed = false);
    _controller.loadRequest(Uri.parse(_embedUrlForReel(widget.reel)));
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond noir + miniature avant chargement du player
        Container(
          color: Colors.black,
          child: Image.network(
            reel.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.videocam_rounded, size: 64, color: Colors.white38),
            ),
          ),
        ),
        // Lecteur embed (YouTube/Dailymotion) — lecture dans l'app
        ClipRect(
          child: WebViewWidget(controller: _controller),
        ),
        // Si erreur réseau : message + réessayer
        if (_loadFailed)
          Container(
            color: Colors.black87,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  'Vidéo indisponible',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        // Overlay gradient + titre en bas (style Instagram)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              40,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
              ),
            ),
            child: Text(
              reel.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
