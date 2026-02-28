import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../services/saved_appointments_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _blue600 = Color(0xFF2563EB);

class _Appointment {
  final String expertName;
  final String specialty;
  final String imageUrl;
  final String date;
  final String time;
  final String status;
  final bool isVideo;
  /// UserId du professionnel (pour "Rejoindre l'appel" via backend d'appels).
  final String? expertUserId;

  const _Appointment({
    required this.expertName,
    required this.specialty,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.status,
    required this.isVideo,
    this.expertUserId,
  });
}

/// Mes Rendez-vous — liste des rendez-vous enregistrés (après confirmation).
class ExpertAppointmentsScreen extends StatefulWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  State<ExpertAppointmentsScreen> createState() =>
      _ExpertAppointmentsScreenState();
}

class _ExpertAppointmentsScreenState extends State<ExpertAppointmentsScreen> {
  int _tabIndex = 0; // 0: À venir, 1: Passés
  List<_Appointment> _upcoming = [];
  List<_Appointment> _past = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    final list = await SavedAppointmentsService.getSavedAppointments();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = <_Appointment>[];
    final past = <_Appointment>[];
    for (final a in list) {
      DateTime? d;
      try {
        final parts = a.dateIso.split('-');
        if (parts.length == 3) {
          d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
      if (d == null) continue;
      final card = _Appointment(
        expertName: a.title,
        specialty: a.subtitle ?? '',
        imageUrl: '',
        date: a.dateFormatted,
        time: a.time,
        status: 'confirmed',
        isVideo: a.isVideo,
        expertUserId: a.expertUserId,
      );
      if (d.isAfter(today) || d.isAtSameMomentAs(today)) {
        upcoming.add(card);
      } else {
        past.add(card);
      }
    }
    upcoming.sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
    past.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
    if (!mounted) return;
    setState(() {
      _upcoming = upcoming;
      _past = past;
      _loading = false;
    });
  }

  DateTime _parseDate(String dateStr) {
    const months = {
      'Janvier': 1, 'Février': 2, 'Mars': 3, 'Avril': 4, 'Mai': 5, 'Juin': 6,
      'Juillet': 7, 'Août': 8, 'Septembre': 9, 'Octobre': 10, 'Novembre': 11, 'Décembre': 12,
    };
    final parts = dateStr.split(' ');
    if (parts.length != 3) return DateTime(2000, 1, 1);
    try {
      final d = int.parse(parts[0]);
      final m = months[parts[1]] ?? 1;
      final y = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return DateTime(2000, 1, 1);
    }
  }

  /// Lance l'appel vers le professionnel (backend d'appels) et ouvre l'écran d'appel.
  void _joinCall(BuildContext context, _Appointment a) {
    final expertUserId = a.expertUserId;
    if (expertUserId == null || expertUserId.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caller = auth.user;
    if (caller == null) return;
    final ids = [caller.id, expertUserId]..sort();
    final channelId =
        'call_${ids[0]}_${ids[1]}_${DateTime.now().millisecondsSinceEpoch}';
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.service.initiateCall(
      targetUserId: expertUserId,
      channelId: channelId,
      isVideo: true,
      callerName: caller.fullName,
    );
    context.push(AppConstants.callRoute, extra: {
      'channelId': channelId,
      'remoteUserId': expertUserId,
      'remoteUserName': a.expertName,
      'remoteImageUrl': a.imageUrl,
      'isVideo': true,
      'isIncoming': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final list = _tabIndex == 0 ? _upcoming : _past;

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottomPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTabBar(loc),
                          const SizedBox(height: 24),
                          if (list.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Text(
                                  _tabIndex == 0
                                      ? 'Aucun rendez-vous à venir.\nPrenez rendez-vous puis ajoutez-le à votre calendrier.'
                                      : 'Aucun rendez-vous passé.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...list.map((a) => _buildAppointmentCard(a, loc)),
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
            onPressed: () => context.go(AppConstants.familyDashboardRoute),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2)),
          ),
          Expanded(
            child: Text(
              loc.expertAppointmentsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
            style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: _tabIndex == 0 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => setState(() => _tabIndex = 0),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    loc.expertAppointmentsUpcoming,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _tabIndex == 0
                          ? const Color(0xFF334155)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: _tabIndex == 1 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => setState(() => _tabIndex = 1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    loc.expertAppointmentsPast,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _tabIndex == 1
                          ? const Color(0xFF334155)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(_Appointment a, AppLocalizations loc) {
    final isConfirmed = a.status == 'confirmed';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: a.imageUrl.isNotEmpty
                    ? Image.network(a.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarPlaceholder())
                    : _avatarPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.expertName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(a.specialty,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isConfirmed
                            ? loc.expertAppointmentsConfirmed
                            : loc.expertAppointmentsPending,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isConfirmed
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: _blue600, size: 20),
                const SizedBox(width: 8),
                Text(a.date,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155))),
                const Spacer(),
                const Icon(Icons.schedule, color: _blue600, size: 20),
                const SizedBox(width: 8),
                Text(a.time,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155))),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: a.isVideo && isConfirmed
                      ? _blue600
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: (a.isVideo && isConfirmed &&
                            (a.expertUserId != null &&
                                a.expertUserId!.isNotEmpty))
                        ? () => _joinCall(context, a)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(a.isVideo ? Icons.videocam : Icons.location_on,
                              color: a.isVideo && isConfirmed
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isConfirmed
                                ? (a.isVideo
                                    ? loc.expertAppointmentsJoinCall
                                    : loc.expertAppointmentsViewItinerary)
                                : loc.expertAppointmentsAppointmentDetails,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: a.isVideo && isConfirmed
                                    ? Colors.white
                                    : Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.person, color: Colors.grey),
      );
}
