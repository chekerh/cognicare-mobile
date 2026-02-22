import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../../l10n/app_localizations.dart';

const Color _primary = Color(0xFF2b8cee);

/// Session Planner : calendrier hebdo, créneaux (Game Session, Clinical Check-up), AI Insights.
class HealthcarePlannerScreen extends StatelessWidget {
  const HealthcarePlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeef7ff),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.psychology, color: _primary, size: 28),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.sessionPlannerLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Badge(
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _monthBar(context),
            const SizedBox(height: 16),
            _weekStrip(context),
            const SizedBox(height: 24),
            _slot(context, '09:00', AppLocalizations.of(context)!.gameSessionLabel, 'Leo Miller', 'Spatial Focus • Level 2', _primary),
            _slot(context, '10:30', AppLocalizations.of(context)!.clinicalCheckupLabel, 'Sarah Chen', 'Monthly Assessment', Colors.green),
            _slotEmpty(context, '14:00'),
            const SizedBox(height: 24),
            _aiInsightsSection(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _monthBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          intl.DateFormat.yMMMM(Localizations.localeOf(context).languageCode).format(DateTime(2023, 10)).toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(AppLocalizations.of(context)!.todayLabel, style: const TextStyle(color: _primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _weekStrip(BuildContext context) {
    final days = ['Mon 2', 'Tue 3', 'Wed 4', 'Thu 5', 'Fri 6', 'Sat 7'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.asMap().entries.map((e) {
          final isThu = e.value == 'Thu 5';
          return Container(
            width: 56,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isThu ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isThu ? _primary.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  blurRadius: isThu ? 12 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  intl.DateFormat.E(Localizations.localeOf(context).languageCode).format(DateTime(2023, 10, 2 + e.key)),
                  style: TextStyle(
                    fontSize: 11,
                    color: isThu ? Colors.white70 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (2 + e.key).toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isThu ? Colors.white : const Color(0xFF111418),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    String time,
    String type,
    String patientName,
    String subtitle,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: borderColor, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                      ),
                      Icon(Icons.more_horiz, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111418),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111418),
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotEmpty(BuildContext context, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: Colors.grey.shade300, width: 4)),
              ),
              child: Text(
                AppLocalizations.of(context)!.noSessionScheduledLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiInsightsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: _primary, size: 22),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.aiInsightsLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111418),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.recommendedForPatient('Leo Miller'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              _insightCard(context, 'Visual Memory Plus', 'Focus: Pattern Recognition', Icons.extension),
              const SizedBox(height: 8),
              _insightCard(context, 'Reaction Sprint', 'Focus: Motor Response', Icons.timer),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightCard(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111418),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(AppLocalizations.of(context)!.addToSessionLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
