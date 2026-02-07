import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Family Notifications Center — design aligné sur le HTML fourni.
/// Fond bleu clair #A2D9E3, cartes blanches, catégories (Health Alert, Achievement, etc.).
const Color _bgLight = Color(0xFFA2D9E3);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _textSoft = Color(0xFF475569);

class _NotificationItem {
  final String category;
  final String categoryLabel;
  final IconData icon;
  final Color color;
  final String timeAgo;
  final String title;
  final String description;
  final bool hasAlertBorder;

  const _NotificationItem({
    required this.category,
    required this.categoryLabel,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.title,
    required this.description,
    this.hasAlertBorder = false,
  });
}

class FamilyNotificationsScreen extends StatelessWidget {
  const FamilyNotificationsScreen({super.key});

  static const List<_NotificationItem> _items = [
    _NotificationItem(
      category: 'health_alert',
      categoryLabel: 'HEALTH ALERT',
      icon: Icons.favorite,
      color: Color(0xFFE11D48),
      timeAgo: '2m ago',
      title: 'Heart rate anomaly detected',
      description: "Leo's heart rate spiked to 115 bpm while resting. Monitor activity.",
      hasAlertBorder: true,
    ),
    _NotificationItem(
      category: 'achievement',
      categoryLabel: 'ACHIEVEMENT',
      icon: Icons.star,
      color: Color(0xFFD97706),
      timeAgo: '45m ago',
      title: 'New sticker earned!',
      description: 'Leo completed the daily memory puzzle and earned a "Super Star" sticker.',
    ),
    _NotificationItem(
      category: 'family_message',
      categoryLabel: 'FAMILY MESSAGE',
      icon: Icons.chat_bubble,
      color: Color(0xFF2563EB),
      timeAgo: '2h ago',
      title: 'Message from Sarah',
      description: '"I\'m heading over to Leo\'s now for the afternoon session. Will update later!"',
    ),
    _NotificationItem(
      category: 'health_update',
      categoryLabel: 'HEALTH UPDATE',
      icon: Icons.favorite,
      color: Color(0xFF059669),
      timeAgo: '5h ago',
      title: 'Normal sleep pattern',
      description: 'Leo had 8 hours of deep sleep last night. Recovery score is high.',
    ),
    _NotificationItem(
      category: 'achievement',
      categoryLabel: 'ACHIEVEMENT',
      icon: Icons.star,
      color: Color(0xFFD97706),
      timeAgo: 'Yesterday',
      title: 'Communication Milestone',
      description: 'Leo used 5 new words during the speech therapy session today!',
    ),
  ];

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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _NotificationCard(item: _items[index]),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '3 unread updates',
                style: TextStyle(
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
              onTap: () {},
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
  final _NotificationItem item;

  const _NotificationCard({required this.item});

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
        border: item.hasAlertBorder
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
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
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
                        item.categoryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        item.timeAgo,
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
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
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
