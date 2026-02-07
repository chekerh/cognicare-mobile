import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _primary = Color(0xFF8ED8E6);
const Color _bgLight = Color(0xFFF4F9FB);

/// Tableau d'Engagement hebdomadaire — temps de jeu, activités récentes, badges.
class EngagementDashboardScreen extends StatelessWidget {
  const EngagementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding),
                children: [
                  _buildPlaytimeCard(),
                  const SizedBox(height: 32),
                  _buildRecentActivities(context),
                  const SizedBox(height: 32),
                  _buildBadgesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _bgLight.withOpacity(0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            elevation: 1,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.chevron_left, color: Color(0xFF64748B), size: 24),
              ),
            ),
          ),
          const Text(
            'Tableau d\'Engagement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            elevation: 1,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.share, color: Color(0xFF64748B), size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaytimeCard() {
    const double progress = 42 / 60; // 42 min / 60 min goal
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(
            'TEMPS DE JEU AUJOURD\'HUI',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 192,
                height: 192,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: progress,
                    backgroundColor: Colors.grey.shade200,
                    progressColor: _primary,
                    strokeWidth: 12,
                  ),
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '42 ',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      children: [
                        TextSpan(text: 'min', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Objectif: 60 min', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: _primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Julie est très concentrée ! +5% de focus aujourd\'hui par rapport à hier.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Activités récentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            GestureDetector(
              onTap: () {},
              child: const Text('Voir tout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _activityItem(
          icon: Icons.extension,
          iconBg: Colors.orange.shade100,
          iconColor: Colors.orange.shade700,
          title: 'Puzzle terminé',
          time: '14:20',
          subtitle: 'Niveau expert réussi en 12 minutes.',
          badge: ('AGILITÉ COGNITIVE +10', Colors.green, Icons.trending_up),
        ),
        const SizedBox(height: 16),
        _activityItem(
          icon: Icons.nights_stay,
          iconBg: Colors.indigo.shade100,
          iconColor: Colors.indigo.shade700,
          title: 'Sommeil calme',
          time: '13:00',
          subtitle: 'Sieste de 45 min sans interruptions.',
        ),
        const SizedBox(height: 16),
        _activityItem(
          icon: Icons.graphic_eq,
          iconBg: Colors.pink.shade100,
          iconColor: Colors.pink.shade700,
          title: 'Ambiance lancée',
          time: '10:45',
          subtitle: '"Forêt de Pins" activée pour la lecture.',
          badge: ('AI COMMENT: Sérénité optimale', Colors.blue, Icons.psychology),
        ),
      ],
    );
  }

  Widget _activityItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String time,
    required String subtitle,
    (String, Color, IconData)? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                if (badge != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge.$2.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge.$3, size: 14, color: badge.$2),
                        const SizedBox(width: 4),
                        Text(badge.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badge.$2)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    final badges = [
      (Icons.emoji_events, Colors.yellow.shade700, 'EXPLORATEUR', Colors.yellow.shade100, false),
      (Icons.bolt, Colors.cyan.shade700, 'SÉANCE ÉCLAIR', Colors.cyan.shade100, false),
      (Icons.favorite, Colors.purple.shade700, 'EMPATHIE', Colors.purple.shade100, true), // locked
      (Icons.verified, _primary, '7 JOURS +', _primary.withOpacity(0.2), false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges d\'engagement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (context, i) {
              final b = badges[i];
              return Container(
                width: 112,
                margin: EdgeInsets.only(right: i < badges.length - 1 ? 16 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Opacity(
                  opacity: b.$5 ? 0.6 : 1,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: b.$4,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(b.$1, color: b.$2, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          b.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: b.$5 ? Colors.grey.shade500 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const sweepAngle = 2 * math.pi;
    const startAngle = -math.pi / 2;
    canvas.drawArc(rect, startAngle, sweepAngle * progress.clamp(0.0, 1.0), false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}
