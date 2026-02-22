import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

const Color _primary = Color(0xFF77B5D1);
const Color _brandLight = Color(0xFFA8D9EB);

/// Écran de confirmation — Tâche Acceptée, détails mission, actions.
class VolunteerTaskAcceptedScreen extends StatelessWidget {
  final String volunteerName;
  final String familyName;
  final String missionType;
  final String schedule;
  final String address;
  final IconData missionIcon;

  const VolunteerTaskAcceptedScreen({
    super.key,
    required this.volunteerName,
    required this.familyName,
    required this.missionType,
    required this.schedule,
    required this.address,
    this.missionIcon = Icons.shopping_basket,
  });

  static IconData _iconFromMissionType(String? type, BuildContext context) {
    if (type == null) return Icons.shopping_basket;
    final l = AppLocalizations.of(context)!;
    if (type.toLowerCase().contains(l.reading.toLowerCase()) || type.toLowerCase().contains('lecture')) return Icons.menu_book;
    return Icons.shopping_basket;
  }

  static VolunteerTaskAcceptedScreen fromState(GoRouterState state, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final extra = state.extra as Map<String, dynamic>?;
    final missionType = extra?['missionType'] as String? ?? l.missionLabel;
    return VolunteerTaskAcceptedScreen(
      volunteerName: extra?['volunteerName'] as String? ?? l.volunteerLabel,
      familyName: extra?['familyName'] as String? ?? l.familyLabel,
      missionType: missionType,
      schedule: extra?['schedule'] as String? ?? l.toDefineLabel,
      address: extra?['address'] as String? ?? '',
      missionIcon: _iconFromMissionType(missionType, context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_brandLight, _primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 100 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 40),
                        ],
                      ),
                      child: const Icon(Icons.check, color: _primary, size: 56),
                    ),
                    Positioned(
                      left: -16,
                      right: -16,
                      top: -16,
                      bottom: -16,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  AppLocalizations.of(context)!.taskAcceptedLabel,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.taskAcceptedMessage(volunteerName, familyName),
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                    child: Column(
                    children: [
                      _detailRow(missionIcon, AppLocalizations.of(context)!.missionTypeLabel, missionType),
                      const Divider(height: 24),
                      _detailRow(Icons.family_restroom, AppLocalizations.of(context)!.beneficiaryLabel, familyName),
                      const Divider(height: 24),
                      _detailRow(Icons.schedule, AppLocalizations.of(context)!.plannedScheduleLabel, schedule),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/volunteer/mission-itinerary', extra: {'family': familyName, 'address': address}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.viewItineraryLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.sendMessageLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => context.go('/volunteer/dashboard'),
                  child: Text(AppLocalizations.of(context)!.backToHomeLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
                ),
                const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }
}
