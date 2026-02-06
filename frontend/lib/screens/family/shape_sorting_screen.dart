import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../utils/constants.dart';

// Shape Sorting Challenge — couleurs du HTML
const Color _primary = Color(0xFFA5DCE7);
const Color _primaryDark = Color(0xFF006064);
const Color _shapeYellow = Color(0xFFFFD700);
const Color _shapeRed = Color(0xFFFF5F5F);
const Color _shapeBlue = Color(0xFF0091EA);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF37474F);

enum _ShapeType { square, circle, triangle }

/// Jeu Shape Sorting — glisser la forme correspondante dans la zone.
class ShapeSortingScreen extends StatefulWidget {
  const ShapeSortingScreen({super.key});

  @override
  State<ShapeSortingScreen> createState() => _ShapeSortingScreenState();
}

class _ShapeSortingScreenState extends State<ShapeSortingScreen> {
  static const int _maxLevel = 3;
  static const int _maxAttempts = 3;
  int _level = 1;
  int _score = 0;
  int _attempts = _maxAttempts;
  double _levelProgress = 0.0;
  _ShapeType _targetShape = _ShapeType.square;
  final Random _rnd = Random();
  bool _blocked = false;
  bool _gameFinished = false;

  void _nextShape() {
    if (_gameFinished) return;
    setState(() {
      _targetShape = _ShapeType.values[_rnd.nextInt(_ShapeType.values.length)];
      _attempts = _maxAttempts;
      _score += 50;
      _blocked = false;
      _levelProgress = (_levelProgress + 0.2).clamp(0.0, 1.0);
      if (_levelProgress >= 1.0 && _level < _maxLevel) {
        _level++;
        _levelProgress = 0.0;
      } else if (_level == _maxLevel && _levelProgress >= 1.0) {
        _gameFinished = true;
        _showGameFinishedDialog();
      }
    });
  }

  void _onCorrectMatch() {
    if (_gameFinished) return;
    setState(() {
      _score += 100;
      _attempts = _maxAttempts;
      _blocked = false;
      _levelProgress = (_levelProgress + 0.25).clamp(0.0, 1.0);
      if (_levelProgress >= 1.0 && _level < _maxLevel) {
        _level++;
        _levelProgress = 0.0;
      } else if (_level == _maxLevel && _levelProgress >= 1.0) {
        _gameFinished = true;
        _showGameFinishedDialog();
        return;
      }
      _targetShape = _ShapeType.values[_rnd.nextInt(3)];
    });
    if (!_gameFinished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bien joué !'), duration: Duration(milliseconds: 800), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showGameFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bravo, Léo !'),
        content: Text(
          'Tu as terminé les $_maxLevel niveaux ! Score final : $_score',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
              context.push(AppConstants.familyStarTracerRoute);
            },
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  void _onWrongMatch() {
    if (_blocked) return;
    setState(() {
      _attempts--;
      if (_attempts <= 0) {
        _blocked = true;
        _showOutOfAttemptsDialog();
      }
    });
    if (_attempts > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pas la bonne forme. Il te reste $_attempts tentative${_attempts > 1 ? 's' : ''}.'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOutOfAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Plus de tentatives !'),
        content: const Text(
          'Tu as utilisé tes 3 tentatives pour cette forme. Tu peux réessayer ou passer au jeu suivant.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _attempts = _maxAttempts;
                _blocked = false;
              });
            },
            child: const Text('Réessayer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Jeu suivant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildLevelAndProgress(),
            _buildInstruction(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTargetArea(context),
                  const SizedBox(height: 48),
                  _buildDraggableShapes(context),
                ],
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 28),
          ),
          const Expanded(
            child: Text(
              'Shape Sorting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded, color: _textDark, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelAndProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $_level of $_maxLevel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
              Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_maxAttempts, (i) {
                      return Icon(
                        i < _attempts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: i < _attempts ? _shapeRed : _textMuted,
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.stars_rounded, color: _primaryDark, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _levelProgress,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryDark),
              minHeight: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Match the shapes!',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textMuted,
        ),
      ),
    );
  }

  Widget _buildTargetArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DragTarget<_ShapeType>(
        onAcceptWithDetails: (details) {
          if (_blocked) return;
          if (details.data == _targetShape) {
            _onCorrectMatch();
          } else {
            _onWrongMatch();
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 4,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Silhouette de la forme cible
                _buildShapeOutline(_targetShape, size: 96, opacity: 0.5),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 32,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _shapeYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShapeOutline(_ShapeType type, {required double size, double opacity = 1.0}) {
    final color = Colors.black.withOpacity(0.05 * opacity);
    switch (type) {
      case _ShapeType.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case _ShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case _ShapeType.triangle:
        return CustomPaint(
          size: Size(size, size),
          painter: _TriangleOutlinePainter(color: color),
        );
    }
  }

  Widget _buildDraggableShapes(BuildContext context) {
    return Column(
      children: [
        const Text(
          'DRAG A SHAPE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _textMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDraggableShape(_ShapeType.square),
            _buildDraggableShape(_ShapeType.circle),
            _buildDraggableShape(_ShapeType.triangle),
          ],
        ),
      ],
    );
  }

  Widget _buildDraggableShape(_ShapeType type) {
    return Draggable<_ShapeType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: _buildShapeWidget(type, size: 96),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildShapeWidget(type, size: 96),
      ),
      child: _buildShapeWidget(type, size: 96),
    );
  }

  Widget _buildShapeWidget(_ShapeType type, {required double size}) {
    Color color;
    Widget inner;
    switch (type) {
      case _ShapeType.square:
        color = _shapeBlue;
        inner = Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
            borderRadius: BorderRadius.circular(6),
          ),
        );
        break;
      case _ShapeType.circle:
        color = _shapeYellow;
        inner = Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
          ),
        );
        break;
      case _ShapeType.triangle:
        color = _shapeRed;
        inner = CustomPaint(
          size: Size(size * 0.5, size * 0.5),
          painter: _TriangleStrokePainter(
            strokeColor: Colors.white.withOpacity(0.3),
          ),
        );
        break;
    }
    if (type == _ShapeType.triangle) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            color: color,
            alignment: Alignment.center,
            child: inner,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: type == _ShapeType.circle ? null : BorderRadius.circular(12),
        shape: type == _ShapeType.circle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: inner),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            elevation: 2,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up_rounded, color: _primaryDark),
                    const SizedBox(width: 8),
                    const Text(
                      'Sound On',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: _primaryDark,
            borderRadius: BorderRadius.circular(999),
            elevation: 2,
            child: InkWell(
              onTap: _nextShape,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next Shape',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(size.width * 0.5, 0);
    p.lineTo(0, size.height);
    p.lineTo(size.width, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TriangleOutlinePainter extends CustomPainter {
  final Color color;

  _TriangleOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    p.moveTo(size.width * 0.5, 0);
    p.lineTo(0, size.height);
    p.lineTo(size.width, size.height);
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TriangleStrokePainter extends CustomPainter {
  final Color strokeColor;

  _TriangleStrokePainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    p.moveTo(size.width * 0.5, 0);
    p.lineTo(0, size.height);
    p.lineTo(size.width, size.height);
    p.close();
    canvas.drawPath(
      p,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
