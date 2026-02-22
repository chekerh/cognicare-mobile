import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _primaryDark = Color(0xFF7FBAC4);
const Color _accentDark = Color(0xFF212121);

/// Prise de Rendez-vous Expert — sélection date, créneau, type de consultation.
class ExpertBookingScreen extends StatefulWidget {
  const ExpertBookingScreen({
    super.key,
    required this.expertName,
    required this.expertSpecialty,
    required this.expertLocation,
    required this.expertImageUrl,
  });

  final String expertName;
  final String expertSpecialty;
  final String expertLocation;
  final String expertImageUrl;

  static ExpertBookingScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    return ExpertBookingScreen(
      expertName: e['name'] as String? ?? 'Dr. Sarah Williams',
      expertSpecialty: e['specialization'] as String? ?? 'Pédopsychiatre',
      expertLocation: e['location'] as String? ?? 'Downtown Medical Center',
      expertImageUrl: e['imageUrl'] as String? ?? '',
    );
  }

  @override
  State<ExpertBookingScreen> createState() => _ExpertBookingScreenState();
}

class _ExpertBookingScreenState extends State<ExpertBookingScreen> {
  DateTime _selectedDate = DateTime(2023, 10, 4);
  int _selectedTimeIndex = 1; // 10:30
  int _consultationType = 0; // 0: video, 1: in person

  static const List<String> _timeSlots = ['09:00', '10:30', '14:00', '15:30', '16:45', '18:00'];

  void _confirmAppointment(AppLocalizations loc) {
    final time = _timeSlots[_selectedTimeIndex];
    final mode = _consultationType == 0 ? 'video' : 'in_person';
    final monthNames = _getMonthNames(loc);
    context.push(AppConstants.familyExpertBookingConfirmationRoute, extra: {
      'expertName': widget.expertName,
      'expertSpecialty': widget.expertSpecialty,
      'expertImageUrl': widget.expertImageUrl,
      'date': '${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
      'time': time,
      'mode': mode,
    });
  }

  List<String> _getMonthNames(AppLocalizations loc) {
    return [
      loc.january, loc.february, loc.march, loc.april, loc.may, loc.june,
      loc.july, loc.august, loc.september, loc.october, loc.november, loc.december,
    ];
  }

  List<String> _getDaysShort(AppLocalizations loc) {
    return [loc.monShort, loc.tueShort, loc.wedShort, loc.thuShort, loc.friShort, loc.satShort, loc.sunShort];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildExpertCard(),
                    const SizedBox(height: 16),
                    _buildCalendarCard(loc, _getMonthNames(loc), _getDaysShort(loc)),
                    const SizedBox(height: 16),
                    _buildTimeSlotsSection(loc),
                    const SizedBox(height: 16),
                    _buildConsultationTypeSection(loc),
                    const SizedBox(height: 24),
                    _buildConfirmButton(loc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          Expanded(
            child: Text(
              loc.expertBookingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildExpertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.expertImageUrl.isNotEmpty
                ? Image.network(widget.expertImageUrl, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderAvatar())
                : _placeholderAvatar(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.expertName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.verified, color: _accentDark, size: 20),
                  ],
                ),
                Text(
                  widget.expertSpecialty,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primaryDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      widget.expertLocation,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() => Container(
        width: 64,
        height: 64,
        color: _primary.withOpacity(0.2),
        child: const Icon(Icons.person, size: 32, color: _primaryDark),
      );

  Widget _buildCalendarCard(AppLocalizations loc, List<String> monthNames, List<String> daysShort) {
    final month = monthNames[_selectedDate.month - 1];
    final year = _selectedDate.year;
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final startOffset = (firstDay.weekday + 6) % 7;
    final daysInMonth = lastDay.day;
    final prevMonthDays = DateTime(_selectedDate.year, _selectedDate.month, 0).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month $year',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day.clamp(1, DateTime(_selectedDate.year, _selectedDate.month - 1, 0).day));
                    }),
                    icon: Icon(Icons.chevron_left, color: Colors.grey.shade500),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day.clamp(1, DateTime(_selectedDate.year, _selectedDate.month + 2, 0).day));
                    }),
                    icon: Icon(Icons.chevron_right, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysShort
                .map((d) => Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)))
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            childAspectRatio: 1.2,
            children: List.generate(42, (i) {
              final dayIndex = i - startOffset;
              int displayDay;
              bool isCurrentMonth;
              if (dayIndex < 0) {
                displayDay = prevMonthDays + dayIndex + 1;
                isCurrentMonth = false;
              } else if (dayIndex >= daysInMonth) {
                displayDay = dayIndex - daysInMonth + 1;
                isCurrentMonth = false;
              } else {
                displayDay = dayIndex + 1;
                isCurrentMonth = true;
              }
              final isSelected = isCurrentMonth && displayDay == _selectedDate.day;
              return GestureDetector(
                onTap: isCurrentMonth ? () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, displayDay)) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$displayDay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : (isCurrentMonth ? const Color(0xFF334155) : Colors.grey.shade400),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            loc.expertBookingAvailableSlots,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: List.generate(_timeSlots.length, (i) {
            final selected = _selectedTimeIndex == i;
            return Material(
              color: selected ? _accentDark : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _selectedTimeIndex = i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: selected ? null : Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _timeSlots[i],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildConsultationTypeSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            loc.expertBookingConsultationType,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _consultationTypeButton(
                icon: Icons.videocam,
                label: loc.expertBookingVideoCall,
                selected: _consultationType == 0,
                onTap: () => setState(() => _consultationType = 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _consultationTypeButton(
                icon: Icons.person_pin_circle,
                label: loc.expertBookingInPerson,
                selected: _consultationType == 1,
                onTap: () => setState(() => _consultationType = 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _consultationTypeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.white.withOpacity(0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _accentDark : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _accentDark : Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? _accentDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(AppLocalizations loc) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: _primary.withOpacity(0.5),
      child: InkWell(
        onTap: () => _confirmAppointment(loc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.expertBookingConfirmButton,
                style: const TextStyle(color: _primaryDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: _primaryDark, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
