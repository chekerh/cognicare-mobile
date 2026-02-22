import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

const Color _primary = Color(0xFF77B5D1);
const Color _brandLight = Color(0xFFA8D9EB);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _unreadDot = Color(0xFF3B82F6);

class _NotificationItem {
  final String id;
  final String title;
  final String timestamp;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isRead = false,
  });
}

/// Centre de notifications bénévole.
class VolunteerNotificationsScreen extends StatefulWidget {
  const VolunteerNotificationsScreen({super.key});

  @override
  State<VolunteerNotificationsScreen> createState() => _VolunteerNotificationsScreenState();
}

class _VolunteerNotificationsScreenState extends State<VolunteerNotificationsScreen> {
  late List<_NotificationItem> _notifications;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifications = _buildSampleNotifications(context);
  }

  static List<_NotificationItem> _buildSampleNotifications(BuildContext context) {
    return [
      _NotificationItem(
        id: '1',
        title: AppLocalizations.of(context)!.notifUrgentTitle,
        timestamp: AppLocalizations.of(context)!.justNow,
        description: AppLocalizations.of(context)!.notifUrgentDesc,
        icon: Icons.add,
        iconColor: Colors.blue,
        iconBgColor: Colors.blue.shade50,
        isRead: false,
      ),
      _NotificationItem(
        id: '2',
        title: AppLocalizations.of(context)!.notifMsgTitle,
        timestamp: '14:30',
        description: AppLocalizations.of(context)!.notifMsgDesc,
        icon: Icons.chat_bubble,
        iconColor: Colors.green,
        iconBgColor: Colors.green.shade50,
        isRead: false,
      ),
      _NotificationItem(
        id: '3',
        title: AppLocalizations.of(context)!.notifReminderTitle,
        timestamp: '10:15',
        description: AppLocalizations.of(context)!.notifReminderDesc,
        icon: Icons.calendar_today,
        iconColor: Colors.orange,
        iconBgColor: Colors.orange.shade50,
        isRead: true,
      ),
      _NotificationItem(
        id: '4',
        title: AppLocalizations.of(context)!.notifScheduleTitle,
        timestamp: AppLocalizations.of(context)!.yesterday,
        description: AppLocalizations.of(context)!.notifScheduleDesc,
        icon: Icons.event_busy,
        iconColor: Colors.grey,
        iconBgColor: Colors.grey.shade100,
        isRead: true,
      ),
      _NotificationItem(
        id: '5',
        title: AppLocalizations.of(context)!.notifNewMissionTitle,
        timestamp: AppLocalizations.of(context)!.yesterday,
        description: AppLocalizations.of(context)!.notifNewMissionDesc,
        icon: Icons.add,
        iconColor: Colors.blue,
        iconBgColor: Colors.blue.shade50,
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markAsRead(_NotificationItem item) {
    setState(() {
      item.isRead = true;
    });
  }

  void _navigateToContent(_NotificationItem n) {
    _markAsRead(n);
    switch (n.id) {
      case '1':
        // Nouvelle demande urgente → écran Missions (demandes à proximité)
        context.go(AppConstants.volunteerMissionsRoute);
        break;
      case '2':
        // Nouveau message → chat avec Famille Dubois
        context.push(
          AppConstants.volunteerFamilyChatRoute,
          extra: <String, dynamic>{
            'familyId': 'famille-dubois',
            'familyName': 'Famille Dubois',
            'missionType': 'Message',
          },
        );
        break;
      case '3':
        // Rappel mission demain → Agenda
        context.go(AppConstants.volunteerAgendaRoute);
        break;
      case '4':
        // Modification d'horaire / annulation → Missions pour voir le planning
        context.go(AppConstants.volunteerMissionsRoute);
        break;
      case '5':
        // Nouvelle mission disponible → Missions (bénévoles / demandes)
        context.go(AppConstants.volunteerMissionsRoute);
        break;
      default:
        context.go(AppConstants.volunteerMissionsRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, height: 192, child: Container(color: _brandLight.withOpacity(0.6))),
          Positioned(top: 96, left: 0, right: 0, height: 96, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_brandLight.withOpacity(0.5), _bgLight])))),
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
                        style: IconButton.styleFrom(foregroundColor: const Color(0xFF1E293B)),
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.notificationsTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: _markAllAsRead,
                        child: Text(AppLocalizations.of(context)!.markAllAsRead, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 100 + MediaQuery.of(context).padding.bottom),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return _notificationCard(n);
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

  Widget _notificationCard(_NotificationItem n) {
    return GestureDetector(
      onTap: () => _navigateToContent(n),
      child: Opacity(
        opacity: n.isRead ? 0.8 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: n.iconBgColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(n.icon, color: n.iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 24),
                                child: Text(
                                  n.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ),
                            Text(
                              n.timestamp,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.description,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Positioned(
                top: 20,
                right: 16,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: _unreadDot, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
