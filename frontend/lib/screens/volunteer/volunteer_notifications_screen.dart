import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../services/community_service.dart';
import '../../services/notifications_feed_service.dart';

/// Centre de notifications bénévole — données depuis l'API, cartes follow_request avec Accepter/Refuser.
const Color _primary = Color(0xFF77B5D1);
const Color _brandLight = Color(0xFFA8D9EB);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);
const Color _textSoft = Color(0xFF475569);
const Color _unreadDot = Color(0xFF3B82F6);

class VolunteerNotificationsScreen extends StatefulWidget {
  const VolunteerNotificationsScreen({super.key});

  @override
  State<VolunteerNotificationsScreen> createState() =>
      _VolunteerNotificationsScreenState();
}

class _VolunteerNotificationsScreenState
    extends State<VolunteerNotificationsScreen> {
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _acceptFollowRequest(String requestId) async {
    try {
      await CommunityService().acceptFollowRequest(requestId);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.followRequestAccept),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  Future<void> _declineFollowRequest(String requestId) async {
    try {
      await CommunityService().declineFollowRequest(requestId);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
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

  static String _timeAgo(DateTime? date, AppLocalizations loc) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return loc.timeAgoJustNow;
    if (diff.inMinutes < 60) return loc.timeAgoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return loc.timeAgoHours(diff.inHours);
    if (diff.inDays == 1) return loc.yesterdayLabel;
    if (diff.inDays < 7) return loc.timeAgoDays(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  static ({String label, IconData icon, Color color, bool alert}) _styleForType(
      AppLocalizations loc, String type) {
    switch (type) {
      case 'health_alert':
        return (
          label: 'HEALTH ALERT',
          icon: Icons.favorite,
          color: const Color(0xFFE11D48),
          alert: true
        );
      case 'achievement':
        return (
          label: 'ACHIEVEMENT',
          icon: Icons.star,
          color: const Color(0xFFD97706),
          alert: false
        );
      case 'family_message':
        return (
          label: 'FAMILY MESSAGE',
          icon: Icons.chat_bubble,
          color: const Color(0xFF2563EB),
          alert: false
        );
      case 'health_update':
        return (
          label: 'HEALTH UPDATE',
          icon: Icons.favorite,
          color: const Color(0xFF059669),
          alert: false
        );
      case 'order_confirmed':
        return (
          label: loc.notificationsPaymentConfirmed,
          icon: Icons.check_circle,
          color: const Color(0xFF059669),
          alert: false
        );
      case 'routine_reminder':
        return (
          label: 'ROUTINE',
          icon: Icons.alarm,
          color: const Color(0xFF0EA5E9),
          alert: false
        );
      case 'follow_request':
        return (
          label: loc.followRequestNotificationLabel.toUpperCase(),
          icon: Icons.person_add,
          color: const Color(0xFF7FBAC4),
          alert: false
        );
      default:
        return (
          label: type.toUpperCase(),
          icon: Icons.notifications,
          color: _textMuted,
          alert: false
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final unreadStr = _unreadCount == 0
        ? (loc?.noUnreadUpdates ?? 'Aucune mise à jour non lue')
        : (_unreadCount == 1
            ? (loc?.oneUnreadUpdate ?? '1 mise à jour non lue')
            : (loc?.unreadUpdatesCount(_unreadCount) ??
                '$_unreadCount mises à jour non lues'));

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 192,
              child: Container(color: _brandLight.withOpacity(0.6))),
          Positioned(
              top: 96,
              left: 0,
              right: 0,
              height: 96,
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _brandLight.withOpacity(0.5),
                            _bgLight
                          ])))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 24, 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left),
                        style: IconButton.styleFrom(
                            foregroundColor: _textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          loc?.notificationsTitle ?? 'Notifications',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: _unreadCount > 0 ? _markAllRead : null,
                        child: Text(
                          'Tout lire',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _unreadCount > 0
                                  ? _primary
                                  : _textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          100 + MediaQuery.of(context).padding.bottom),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final style = _styleForType(loc!, n.type);
                        final requestId = n.followRequestId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _NotificationCard(
                            categoryLabel: style.label,
                            icon: style.icon,
                            color: style.color,
                            timeAgo: _timeAgo(n.createdAt, loc),
                            title: n.title,
                            description: n.description.isEmpty
                                ? '—'
                                : n.description,
                            hasAlertBorder: style.alert,
                            isRead: n.read,
                            followRequestId: requestId,
                            onAccept: requestId != null
                                ? () => _acceptFollowRequest(requestId)
                                : null,
                            onDecline: requestId != null
                                ? () => _declineFollowRequest(requestId)
                                : null,
                            acceptLabel: loc.followRequestAccept,
                            declineLabel: loc.followRequestDecline,
                          ),
                        );
                      },
                    ),
                  ),
              ],
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
  final bool isRead;
  final String? followRequestId;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final String acceptLabel;
  final String declineLabel;

  const _NotificationCard({
    required this.categoryLabel,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.title,
    required this.description,
    this.hasAlertBorder = false,
    this.isRead = false,
    this.followRequestId,
    this.onAccept,
    this.onDecline,
    this.acceptLabel = 'Accept',
    this.declineLabel = 'Decline',
  });

  @override
  Widget build(BuildContext context) {
    final showFollowActions =
        followRequestId != null && onAccept != null && onDecline != null;

    return Opacity(
      opacity: isRead ? 0.85 : 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: hasAlertBorder
                  ? const Border(
                      left: BorderSide(color: Color(0xFFF43F5E), width: 4),
                    )
                  : Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
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
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showFollowActions) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: onDecline,
                              child: Text(declineLabel),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: onAccept,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF7FBAC4),
                              ),
                              child: Text(acceptLabel),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Positioned(
              top: 20,
              right: 16,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: _unreadDot, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
