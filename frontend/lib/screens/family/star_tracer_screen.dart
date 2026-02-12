import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/sticker_book_provider.dart';
import '../../utils/constants.dart';
import '../../utils/gamification_helper.dart';
import '../../services/gamification_service.dart';
import '../../widgets/child_mode_exit_button.dart';

// Star Tracer — couleurs du HTML
const Color _primary = Color(0xFF2b8cee);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF64748B);

/// Points du contour de l’étoile (coordonnées 0–100, ordre de tracé).
class _LevelConfig {
  final String name;
  final List<Offset> points;
  const _LevelConfig(this.name, this.points);
}

/// Une seule forme : l’étoile à 5 branches (5 segments à tracer).
final List<_LevelConfig> _levelConfigs = [
  const _LevelConfig('Étoile', [
    Offset(50, 8),   // haut
    Offset(90, 38),   // droite-haut
    Offset(72, 88),   // droite-bas
    Offset(28, 88),   // gauche-bas
    Offset(10, 38),  // gauche-haut
  ]),
];

class _ShapePathPainter extends CustomPainter {
  final int segmentsTraced;
  final Size size;
  final List<Offset> shapePoints;

  _ShapePathPainter({required this.segmentsTraced, required this.size, required this.shapePoints});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(this.size.width, this.size.height) / 100;
    final center = Offset(size.width / 2, size.height / 2);
    final origin = center - Offset(50 * scale, 50 * scale);
    final pts = shapePoints.map((p) => origin + Offset(p.dx * scale, p.dy * scale)).toList();

    // Contour complet de l'étoile (ligne bien visible à suivre)
    final guidePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      guidePath.lineTo(pts[i].dx, pts[i].dy);
    }
    guidePath.close();
    canvas.drawPath(
      guidePath,
      Paint()
        ..color = _primary.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Pointillés par-dessus pour le style (optionnel)
    final dashed = Paint()
      ..color = _primary.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawDashedPolygon(canvas, pts, dashed);

    // Partie tracée (trait plein, plus épais et plus foncé)
    if (segmentsTraced > 0) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i <= segmentsTraced; i++) {
        path.lineTo(pts[i % pts.length].dx, pts[i % pts.length].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Point actif (cercle blanc avec halo)
    if (segmentsTraced < pts.length) {
      final pt = pts[segmentsTraced % pts.length];
      canvas.drawCircle(pt, 8, Paint()..color = _primary.withOpacity(0.5));
      canvas.drawCircle(pt, 4, Paint()..color = Colors.white);
    }
  }

  void _drawDashedPolygon(Canvas canvas, List<Offset> pts, Paint paint) {
    for (int i = 0; i < pts.length; i++) {
      final next = (i + 1) % pts.length;
      _drawDashedLine(canvas, pts[i], pts[next], paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = sqrt(dx * dx + dy * dy);
    final steps = (len / (dash * 2)).floor();
    if (steps <= 0) return;
    final stepX = dx / steps / 2;
    final stepY = dy / steps / 2;
    for (int i = 0; i < steps; i++) {
      final s = Offset(a.dx + stepX * (2 * i), a.dy + stepY * (2 * i));
      final e = Offset(s.dx + stepX, s.dy + stepY);
      canvas.drawLine(s, e, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePathPainter oldDelegate) =>
      oldDelegate.segmentsTraced != segmentsTraced ||
      oldDelegate.shapePoints.length != shapePoints.length;
}

/// Jeu Star Tracer — suivre les points de l’étoile dans l’ordre.
class StarTracerScreen extends StatefulWidget {
  const StarTracerScreen({super.key, this.inSequence = false});

  final bool inSequence;

  @override
  State<StarTracerScreen> createState() => _StarTracerScreenState();
}

class _StarTracerScreenState extends State<StarTracerScreen> {
  static const int _maxLevel = 1;
  int _level = 1;
  int _segmentsTraced = 0;
  bool _gameFinished = false;
  Size _canvasSize = Size.zero;
  DateTime? _gameStartTime;

  List<Offset> get _currentPoints => _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)].points;
  int get _totalSegments => _currentPoints.length;
  String get _currentLevelName => _levelConfigs[(_level - 1).clamp(0, _levelConfigs.length - 1)].name;

  int get _starsCollected => _totalSegments > 0 ? (_segmentsTraced / _totalSegments * 5).floor().clamp(0, 5) : 0;
  int get _progressPercent => _totalSegments > 0 ? (_segmentsTraced / _totalSegments * 100).round() : 0;

  List<Offset> get _scaledPoints {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return [];
    final scale = min(_canvasSize.width, _canvasSize.height) / 100;
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    final origin = center - Offset(50 * scale, 50 * scale);
    return _currentPoints.map((p) => origin + Offset(p.dx * scale, p.dy * scale)).toList();
  }

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
  }

  /// Distance from point P to segment A-B.
  double _distToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return (p - a).distance;
    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - proj).distance;
  }

  void _onPanUpdate(Offset local) {
    if (_gameFinished) return;
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return;
    if (_segmentsTraced >= _totalSegments) return;
    final pts = _scaledPoints;
    if (pts.length < 2) return;
    final i = _segmentsTraced % pts.length;
    final j = (i + 1) % pts.length;
    final a = pts[i];
    final b = pts[j];
    const endRadius = 32.0;
    const segmentTolerance = 50.0;
    final distToEnd = (local - b).distance;
    final distToSegment = _distToSegment(local, a, b);
    if (distToEnd < endRadius && distToSegment < segmentTolerance) {
      setState(() {
        _segmentsTraced++;
        if (_segmentsTraced >= _totalSegments) {
          _segmentsTraced = _totalSegments;
          if (_level >= _maxLevel) {
            final k = StickerBookProvider.levelKeyForStarTracerLevel(_maxLevel);
            _gameFinished = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              final timeSpent = _gameStartTime != null
                  ? DateTime.now().difference(_gameStartTime!).inSeconds
                  : null;
              await recordGameCompletion(
                context: context,
                levelKey: k,
                gameType: GameType.star_tracer,
                level: _maxLevel,
                timeSpentSeconds: timeSpent,
                metrics: {'segmentsTraced': _totalSegments},
              );
              if (!context.mounted) return;
              final provider = Provider.of<StickerBookProvider>(context, listen: false);
              final stickerIndex = provider.unlockedCount - 1;
              final completed = provider.tasksCompletedCount;
              final milestoneSteps = [5, 10, 15, 20, 25, 30];
              final loc = AppLocalizations.of(context);
              final milestoneMessage = (loc != null && milestoneSteps.contains(completed))
                  ? loc.milestoneLevelsCompleted(completed)
                  : null;
              if (!context.mounted) return;
              if (widget.inSequence) {
                context.pushReplacement(
                  AppConstants.familyBasketSortRoute,
                  extra: {'inSequence': true},
                );
              } else {
                context.push(AppConstants.familyGameSuccessRoute, extra: {
                  'stickerIndex': stickerIndex,
                  'gameRoute': AppConstants.familyStarTracerRoute,
                  if (milestoneMessage != null) 'milestoneMessage': milestoneMessage,
                });
              }
            });
          } else {
            final k = StickerBookProvider.levelKeyForStarTracerLevel(_level);
            _level++;
            _segmentsTraced = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Provider.of<StickerBookProvider>(context, listen: false).recordLevelCompleted(k);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Niveau $_level !'),
                duration: const Duration(milliseconds: 1200),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _canvasSize = Size(constraints.maxWidth - 32, constraints.maxHeight - 120);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: _canvasSize.width,
                          height: _canvasSize.height,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _primary.withOpacity(0.2),
                              width: 4,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (d) => _onPanUpdate(d.localPosition),
                              child: CustomPaint(
                                size: _canvasSize,
                                painter: _ShapePathPainter(
                                  segmentsTraced: _segmentsTraced,
                                  size: _canvasSize,
                                  shapePoints: _currentPoints,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(top: 8, right: 24, child: Icon(Icons.star_rounded, color: Colors.amber[400], size: 24)),
                        Positioned(bottom: 48, left: 24, child: Icon(Icons.auto_awesome, color: _primary.withOpacity(0.4), size: 28)),
                        Positioned(top: 64, left: 32, child: Icon(Icons.auto_awesome, color: _primary.withOpacity(0.3), size: 20)),
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _primary.withOpacity(0.1)),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.keepGoing,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: _primary.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left_rounded, color: _primary, size: 32),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.starTracer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ),
          ChildModeExitButton(iconColor: _primary, textColor: _primary, opacity: 0.9),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.traceLevel(_currentLevelName),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suis les lignes avec ton doigt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trace chaque trait jusqu\'au point bleu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _primary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.level} $_level',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.tracingProgress,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              Text(
                '$_progressPercent%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressPercent / 100,
              backgroundColor: _primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              minHeight: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_starsCollected/5 ${AppLocalizations.of(context)!.stars}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              Material(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      AppLocalizations.of(context)!.hint,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
