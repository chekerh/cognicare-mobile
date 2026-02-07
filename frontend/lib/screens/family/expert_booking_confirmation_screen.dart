import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _primaryDark = Color(0xFF7FBAC4);

/// Confirmation de Rendez-vous — RDV confirmé avec détails.
class ExpertBookingConfirmationScreen extends StatelessWidget {
  const ExpertBookingConfirmationScreen({
    super.key,
    required this.expertName,
    required this.expertSpecialty,
    required this.date,
    required this.time,
    required this.mode,
    this.expertImageUrl,
  });

  final String expertName;
  final String expertSpecialty;
  final String date;
  final String time;
  final String mode; // video | in_person
  final String? expertImageUrl;

  static ExpertBookingConfirmationScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    return ExpertBookingConfirmationScreen(
      expertName: e['expertName'] as String? ?? 'Dr. Sarah Williams',
      expertSpecialty: e['expertSpecialty'] as String? ?? 'Pédopsychiatre',
      expertImageUrl: e['expertImageUrl'] as String?,
      date: e['date'] as String? ?? '4 Octobre 2023',
      time: e['time'] as String? ?? '10:30',
      mode: e['mode'] as String? ?? 'video',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final modeLabel = mode == 'video' ? loc.expertBookingVideoCall : loc.expertBookingInPerson;
    final dateTimeStr = '$date ${loc.atLabel} $time';

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    _buildConfirmationCard(context, loc, modeLabel, dateTimeStr),
                    const SizedBox(height: 32),
                    _buildAddToCalendarButton(loc),
                    const SizedBox(height: 12),
                    _buildViewAppointmentsButton(context, loc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
          ),
          Expanded(
            child: Text(
              loc.expertBookingConfirmationTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard(BuildContext context, AppLocalizations loc, String modeLabel, String dateTimeStr) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Icon(Icons.calendar_today, size: 56, color: Colors.blue.shade600),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            loc.expertBookingConfirmedTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.expertBookingConfirmedSubtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          _detailRow(Icons.person, loc.expertBookingSpecialistLabel, expertName),
          const SizedBox(height: 16),
          _detailRow(Icons.event, loc.expertBookingDateTimeLabel, dateTimeStr),
          const SizedBox(height: 16),
          _detailRow(Icons.videocam, loc.expertBookingModeLabel, modeLabel),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCalendarButton(AppLocalizations loc) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: _primary.withOpacity(0.5),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, color: _primaryDark, size: 22),
              const SizedBox(width: 12),
              Text(loc.expertBookingAddToCalendar, style: const TextStyle(color: _primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAppointmentsButton(BuildContext context, AppLocalizations loc) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(AppConstants.familyExpertAppointmentsRoute),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(loc.expertBookingViewAppointments, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
