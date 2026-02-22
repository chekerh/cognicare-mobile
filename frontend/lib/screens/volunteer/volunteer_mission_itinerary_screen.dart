import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Couleurs du design HTML
const Color _primary = Color(0xFF77B5D1);
const Color _brandLight = Color(0xFFA8D9EB);
const Color _bgLight = Color(0xFFF8FAFC);

/// Écran Itinéraire — carte, instructions, boutons Démarrer / Appeler / Contacter.
class VolunteerMissionItineraryScreen extends StatelessWidget {
  const VolunteerMissionItineraryScreen({
    super.key,
    required this.familyName,
    required this.address,
  });

  final String familyName;
  final String address;

  static VolunteerMissionItineraryScreen fromState(GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    return VolunteerMissionItineraryScreen(
      familyName: extra?['family'] as String? ?? 'Famille',
      address: extra?['address'] as String? ?? 'Adresse non disponible',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          // Map area
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Stack(
                  children: [
                    // Map placeholder with gradient
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _brandLight.withOpacity(0.4),
                            _bgLight,
                          ],
                        ),
                        color: Colors.grey.shade200,
                      ),
                      child: CustomPaint(
                        painter: _MapRoutePainter(),
                      ),
                    ),
                    // Map controls
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _mapButton(Icons.my_location),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 40, minHeight: 40)),
                                Container(
                                    height: 1,
                                    width: 24,
                                    color: Colors.grey.shade200),
                                IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 40, minHeight: 40)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 24, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Itinéraire',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200.withOpacity(0.8),
                      blurRadius: 24,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              familyName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('12 min',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _primary)),
                          Text('3.4 km',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'INSTRUCTIONS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          _stepIcon(Icons.turn_right, true),
                          Container(
                              width: 2,
                              height: 32,
                              color: Colors.grey.shade200),
                          _stepIcon(Icons.straight, false),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tourner à droite sur Avenue du Maine',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B))),
                            Text('Dans 450 m',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(height: 32),
                            const Text('Continuer tout droit sur 1.2 km',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B))),
                            Text('Puis tourner à gauche',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Material(
                          color: _primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.navigation,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text('Démarrer la navigation',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: _brandLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Icon(Icons.call,
                                  color: _primary, size: 28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: _primary, size: 20),
                      label: Text('Contacter la famille',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.grey.shade600),
        onPressed: () {},
      ),
    );
  }

  Widget _stepIcon(IconData icon, bool isActive) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? _primary.withOpacity(0.1) : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          size: 14, color: isActive ? _primary : Colors.grey.shade500),
    );
  }
}

class _MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.83);
    path.cubicTo(
      size.width * 0.38,
      size.height * 0.75,
      size.width * 0.63,
      size.height * 0.8,
      size.width * 0.7,
      size.height * 0.58,
    );
    path.cubicTo(
      size.width * 0.75,
      size.height * 0.45,
      size.width * 0.88,
      size.height * 0.33,
      size.width * 0.8,
      size.height * 0.25,
    );

    final paint = Paint()
      ..color = _primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    // Start point (pulsing circle)
    final startPaint = Paint()..color = _primary;
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.83), 8, startPaint);

    // End point (red pin)
    final endX = size.width * 0.8;
    final endY = size.height * 0.25;
    final endPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(Offset(endX, endY - 5), 10, endPaint);
    final trianglePath = Path();
    trianglePath.moveTo(endX - 10, endY + 15);
    trianglePath.lineTo(endX + 10, endY + 15);
    trianglePath.lineTo(endX, endY + 35);
    trianglePath.close();
    canvas.drawPath(trianglePath, endPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
