import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/engagement_service.dart';

const Color _primary = Color(0xFF8ED8E6);
const Color _bgLight = Color(0xFFF4F9FB);

/// Tableau d'Engagement avec données réelles (API).
class EngagementDashboardScreen extends StatefulWidget {
  const EngagementDashboardScreen({super.key, this.childId});

  final String? childId;

  @override
  State<EngagementDashboardScreen> createState() => _EngagementDashboardScreenState();
}

class _EngagementDashboardScreenState extends State<EngagementDashboardScreen> {
  final EngagementService _engagementService = EngagementService();
  EngagementDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _engagementService.getDashboard(childId: widget.childId);
      if (mounted) {
        setState(() {
          _dashboard = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _primary))
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: _bgLight.withOpacity(0.8)),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final d = _dashboard!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final progress = d.playTimeGoalMinutes > 0
        ? (d.playTimeTodayMinutes / d.playTimeGoalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding),
      children: [
        _buildPlaytimeCard(progress, d.playTimeTodayMinutes, d.playTimeGoalMinutes, d.focusMessage),
        const SizedBox(height: 32),
        _buildRecentActivities(d.recentActivities),
        const SizedBox(height: 32),
        _buildBadgesSection(d.badges),
      ],
    );
  }

  Widget _buildPlaytimeCard(double progress, int minutes, int goal, String focusMessage) {
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$minutes ',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      children: [
                        TextSpan(text: 'min', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Objectif: $goal min', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                    focusMessage,
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

  Widget _buildRecentActivities(List<EngagementActivity> activities) {
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
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Center(
              child: Text(
                'Aucune activité aujourd\'hui.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _activityItem(
                  icon: a.type == 'game' ? Icons.extension : Icons.check_circle_outline,
                  iconBg: a.type == 'game' ? Colors.orange.shade100 : Colors.indigo.shade100,
                  iconColor: a.type == 'game' ? Colors.orange.shade700 : Colors.indigo.shade700,
                  title: a.title,
                  time: a.time,
                  subtitle: a.subtitle,
                  badgeLabel: a.badgeLabel,
                  badgeColor: a.badgeColor,
                ),
              )),
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
    String? badgeLabel,
    String? badgeColor,
  }) {
    Color badgeColorResolved = Colors.green;
    if (badgeColor != null) {
      switch (badgeColor.toLowerCase()) {
        case 'green':
          badgeColorResolved = Colors.green;
          break;
        case 'blue':
          badgeColorResolved = Colors.blue;
          break;
        case 'orange':
          badgeColorResolved = Colors.orange;
          break;
        default:
          badgeColorResolved = Colors.green;
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                if (badgeLabel != null && badgeLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColorResolved.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 14, color: badgeColorResolved),
                        const SizedBox(width: 4),
                        Text(badgeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColorResolved)),
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

  Widget _buildBadgesSection(List<EngagementBadge> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges d\'engagement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        if (badges.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Center(
              child: Text(
                'Aucun badge encore. Continue de jouer !',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
          )
        else
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events, color: _primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        b.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                    ],
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
