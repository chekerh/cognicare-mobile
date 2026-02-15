import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_notification.dart';
import '../../services/notifications_feed_service.dart';

/// Family Notifications Center — données depuis l'API (pas de mock).
const Color _bgLight = Color(0xFFA2D9E3);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _textSoft = Color(0xFF475569);

class FamilyNotificationsScreen extends StatefulWidget {
  const FamilyNotificationsScreen({super.key});

  @override
  State<FamilyNotificationsScreen> createState() => _FamilyNotificationsScreenState();
}

class _FamilyNotificationsScreenState extends State<FamilyNotificationsScreen> {
  final NotificationsFeedService _service = NotificationsFeedService();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = result.notifications;
          _unreadCount = result.unreadCount;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _unreadCount = 0;
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return '${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }

  static ({String label, IconData icon, Color color, bool alert}) _styleForType(String type) {
    switch (type) {
      case 'health_alert':
        return (label: 'HEALTH ALERT', icon: Icons.favorite, color: const Color(0xFFE11D48), alert: true);
      case 'achievement':
        return (label: 'ACHIEVEMENT', icon: Icons.star, color: const Color(0xFFD97706), alert: false);
      case 'family_message':
        return (label: 'FAMILY MESSAGE', icon: Icons.chat_bubble, color: const Color(0xFF2563EB), alert: false);
      case 'health_update':
        return (label: 'HEALTH UPDATE', icon: Icons.favorite, color: const Color(0xFF059669), alert: false);
      case 'order_confirmed':
        return (label: 'PAIEMENT CONFIRMÉ', icon: Icons.check_circle, color: const Color(0xFF059669), alert: false);
      default:
        return (label: type.toUpperCase(), icon: Icons.notifications, color: _textMuted, alert: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final style = _styleForType(n.type);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _NotificationCard(
                            categoryLabel: style.label,
                            icon: style.icon,
                            color: style.color,
                            timeAgo: _timeAgo(n.createdAt),
                            title: n.title,
                            description: n.description.isEmpty ? '—' : n.description,
                            hasAlertBorder: style.alert,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final unreadStr = _unreadCount == 0
        ? 'Aucune mise à jour non lue'
        : (_unreadCount == 1 ? '1 mise à jour non lue' : '$_unreadCount mises à jour non lues');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unreadStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textSoft,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(999),
            elevation: 1,
            child: InkWell(
              onTap: _unreadCount > 0 ? _markAllRead : null,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.done_all, color: _textPrimary, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String categoryLabel;
  final IconData icon;
  final Color color;
  final String timeAgo;
  final String title;
  final String description;
  final bool hasAlertBorder;

  const _NotificationCard({
    required this.categoryLabel,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.title,
    required this.description,
    this.hasAlertBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: hasAlertBorder
            ? const Border(
                left: BorderSide(color: Color(0xFFF43F5E), width: 4),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSoft,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
