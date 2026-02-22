import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _blue600 = Color(0xFF2563EB);

class _Appointment {
  final String expertName;
  final String specialty;
  final String imageUrl;
  final String date;
  final String time;
  final String status; // confirmed | pending
  final bool isVideo;

  const _Appointment({
    required this.expertName,
    required this.specialty,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.status,
    required this.isVideo,
  });
}

/// Mes Rendez-vous — liste des rendez-vous avec le spécialiste.
class ExpertAppointmentsScreen extends StatefulWidget {
  const ExpertAppointmentsScreen({super.key});

  @override
  State<ExpertAppointmentsScreen> createState() =>
      _ExpertAppointmentsScreenState();
}

class _ExpertAppointmentsScreenState extends State<ExpertAppointmentsScreen> {
  int _tabIndex = 0; // 0: À venir, 1: Passés

  static const List<_Appointment> _upcomingAppointments = [
    _Appointment(
      expertName: 'Dr. Sarah Williams',
      specialty: 'Neurologue',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC43_k34ZEjEBeKmimLMsQhDlyKtKikCbSQ7aGEvameMkHW9_lhGEHBKh5PecXZ4AGgRp1ZIDWsZalUY_Njx4PD6pNrSIVxi_21lI3EBvqKuteDCDIbUS6DlFeg0CaJ1azIJvvsCP2AvbqwPA7UnMHB2xq2op2GZJkooH7ycVcaJPF-eSEOyn7oZZ5BKT5SEy85YLP2UXSzmEs2iuInoL2yDD0htypvSEfAhHnUbFSUamGUWGs1OD52CQTl4ReNmVgyIexG92zYHbI',
      date: '4 Octobre 2023',
      time: '10:30',
      status: 'confirmed',
      isVideo: true,
    ),
    _Appointment(
      expertName: 'Dr. James Cooper',
      specialty: 'Gériatre',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB8V490nnNnAQbJ_ZEQYTq3TIqUXERI9ZOAo40nHXsELWssJJd8MxZcm77UaNRQyC0e-MhJ12MCCY0-EO5raZ0NagFWgTdXeoEvW0EIOOYgMOEDwKB01efGpAmcEh83v6rLIMiJYq2OrKRctYrcxQZkkxKLc-A9bmBzsN0JbWzRq5j7WomSLExFMNx7szIuiHvzvH9hUZZEETV7O0Yy-zUH8fk4ztwkMyn-Qw_XGBYp-JHifO77eEPuPHe4ZXQgpnACFxNZS1UN5Z0',
      date: '12 Octobre 2023',
      time: '15:00',
      status: 'pending',
      isVideo: false,
    ),
    _Appointment(
      expertName: 'Dr. Emma Martin',
      specialty: 'Psychologue',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAk7hpcBDDm1M48NG078ywjRIiURS5cKOtsS5GFIJD1TGLDiqjZtvOE_dPT_E6DVGrMCovnDjmdBaR-7qlIEKhvfyZYgfW0pui_q62xWLM2-kJqC4Gzy1eZsjb_pUK-m8wHqU2YdIEZQ6NwgY3IWgSgjwZRmsZVglhPkQWKIj4M96imQ0rPhCWQ4_zwOJIq_g-zr-ohIgHpvDFVjnHRCb-5xmxly9YQWSlhTYTngP445dGw_W-42zzxUhCgd3AKxTsoSDFi3JV38',
      date: '18 Octobre 2023',
      time: '09:15',
      status: 'confirmed',
      isVideo: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTabBar(loc),
                    const SizedBox(height: 24),
                    ..._upcomingAppointments
                        .map((a) => _buildAppointmentCard(a, loc)),
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
                    onTap: () {},
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
