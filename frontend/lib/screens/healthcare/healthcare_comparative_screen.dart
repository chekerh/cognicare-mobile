import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Analyse Comparative IA : comparaison de deux patients, métriques cognitives, prédictions IA.
class HealthcareComparativeScreen extends StatelessWidget {
  const HealthcareComparativeScreen({super.key});

  static HealthcareComparativeScreen fromState(GoRouterState state) {
    return const HealthcareComparativeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'COGNICARE PRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const Text(
              'Analyse Comparative IA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _comparisonModeCard(context),
            const SizedBox(height: 20),
            _metricsCard(),
            const SizedBox(height: 20),
            _predictionsCard(),
            const SizedBox(height: 20),
            _actionButtons(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _comparisonModeCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MODE COMPARAISON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.swap_horiz, size: 16, color: _brand),
                  label: const Text('MODIFIER', style: TextStyle(color: _brand, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('JD', style: TextStyle(fontWeight: FontWeight.bold, color: _brand)),
                    ),
                    const SizedBox(height: 4),
                    const Text('J. Dupont', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Mars 2024', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
                Icon(Icons.compare_arrows, color: Colors.grey.shade400),
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('TB', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                    ),
                    const SizedBox(height: 4),
                    const Text('T. Bernard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Mars 2024', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricsCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Métriques Cognitives',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Données agrégées sur 30 jours',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _legendDot(_brand, 'Dupont'),
                    const SizedBox(width: 12),
                    _legendDot(Colors.orange, 'Bernard'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 180),
                painter: _ChartPainter(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Sem 1', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('Sem 2', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('Sem 3', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Text('Sem 4', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metricChip('MÉMOIRE', '+12%', isHighlight: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricChip('FOCUS', '-2%', isHighlight: false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricChip('MOTEUR', '+5%', isHighlight: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _metricChip(String label, String value, {required bool isHighlight}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isHighlight ? _brand.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isHighlight ? Border.all(color: _brand.withOpacity(0.3)) : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isHighlight ? _brand : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? _brand : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionsCard() {
    return Material(
      color: _brand,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: _primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'PRÉDICTIONS IA - ÉVOLUTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _predictionBlock('Jailson (Patient A)', 'Stabilisation attendue des cycles REM d\'ici 14 jours. Étape : Autonomie de lecture.'),
            const SizedBox(height: 12),
            _predictionBlock('Thomas (Patient B)', 'Risque de régression motrice légère (15%). Ajustement thérapeutique suggéré.', isB: true),
          ],
        ),
      ),
    );
  }

  Widget _predictionBlock(String title, String text, {bool isB = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isB ? Colors.orange.shade200 : _primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _outlineAction(Icons.insights, 'Analyse de groupe', () {}),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _outlineAction(Icons.share, 'Exporter l\'analyse', () {}),
        ),
      ],
    );
  }

  Widget _outlineAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: _brand, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const double pad = 20.0;
    final chartW = w - pad * 2;
    final chartH = h - pad - 16;

    final bluePath = Path();
    bluePath.moveTo(pad, pad + chartH * 0.6);
    bluePath.quadraticBezierTo(pad + chartW * 0.25, pad + chartH * 0.5, pad + chartW * 0.5, pad + chartH * 0.4);
    bluePath.quadraticBezierTo(pad + chartW * 0.75, pad + chartH * 0.3, pad + chartW, pad + chartH * 0.2);
    canvas.drawPath(
      bluePath,
      Paint()..color = const Color(0xFF2D7DA1)..strokeWidth = 2.5..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(pad + chartW * 0.5, pad + chartH * 0.4), 3, Paint()..color = const Color(0xFF2D7DA1));

    final orangePath = Path();
    orangePath.moveTo(pad, pad + chartH * 0.8);
    orangePath.quadraticBezierTo(pad + chartW * 0.25, pad + chartH * 0.75, pad + chartW * 0.5, pad + chartH * 0.85);
    orangePath.quadraticBezierTo(pad + chartW * 0.75, pad + chartH * 0.9, pad + chartW, pad + chartH * 0.7);
    canvas.drawPath(
      orangePath,
      Paint()..color = Colors.orange..strokeWidth = 2.5..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(Offset(pad + chartW * 0.5, pad + chartH * 0.85), 3, Paint()..color = Colors.orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
