import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

// Couleurs de la 2e photo : fond bleu pastel clair, accent bleu
const Color _bgLight = Color(0xFFF0F9FF);
const Color _brandBlue = Color(0xFF89CFF0);
const Color _brandBlueDark = Color(0xFF2563EB);

/// Agenda bénévole — Mon Agenda, calendrier, missions du jour.
class VolunteerAgendaScreen extends StatefulWidget {
  const VolunteerAgendaScreen({super.key});

  @override
  State<VolunteerAgendaScreen> createState() => _VolunteerAgendaScreenState();
}

class _VolunteerAgendaScreenState extends State<VolunteerAgendaScreen> {
  bool _isMonthView = true;
  bool _showQuickMenu = false;
  DateTime _displayDate = DateTime(2024, 3, 13);
  DateTime _selectedDay = DateTime(2024, 3, 13);

  static const _monthsFr = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];
  static const _daysFr = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  void _previousPeriod() {
    setState(() {
      if (_isMonthView) {
        _displayDate = DateTime(_displayDate.year, _displayDate.month - 1);
      } else {
        _displayDate =
            _weekStart(_displayDate).subtract(const Duration(days: 7));
        _selectedDay = _displayDate;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_isMonthView) {
        _displayDate = DateTime(_displayDate.year, _displayDate.month + 1);
      } else {
        _displayDate = _weekStart(_displayDate).add(const Duration(days: 7));
        _selectedDay = _displayDate;
      }
    });
  }

  DateTime _weekStart(DateTime d) {
    final diff = d.weekday - 1;
    return d.subtract(Duration(days: diff));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mon Agenda',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Icon(Icons.more_horiz,
                              color: Colors.grey.shade600, size: 22),
                        ),
                      ],
                    ),
                  ),
                  // Segmented: Mois / Semaine
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isMonthView = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isMonthView
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isMonthView
                                      ? [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2))
                                        ]
                                      : null,
                                ),
                                child: Text('Mois',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _isMonthView
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: _isMonthView
                                            ? const Color(0xFF1E293B)
                                            : Colors.grey.shade600)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isMonthView = false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isMonthView
                                      ? Colors.transparent
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isMonthView
                                      ? null
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2))
                                        ],
                                ),
                                child: Text('Semaine',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _isMonthView
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                        color: _isMonthView
                                            ? Colors.grey.shade600
                                            : const Color(0xFF1E293B))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Calendrier
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${_monthsFr[_displayDate.month - 1]} ${_displayDate.year}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B))),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _previousPeriod,
                                    child: Icon(Icons.chevron_left,
                                        color: Colors.grey.shade600, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: _nextPeriod,
                                    child: Icon(Icons.chevron_right,
                                        color: Colors.grey.shade600, size: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _isMonthView ? _buildMonthGrid() : _buildWeekRow(),
                        ],
                      ),
                    ),
                  ),
                  // Événements du jour
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${_daysFr[_selectedDay.weekday - 1]}, ${_selectedDay.day} ${_monthsFr[_selectedDay.month - 1]}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.2)),
                            Text(
                                _isMonthView
                                    ? '2 missions'
                                    : '2 missions prévues',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _brandBlue)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildEventTimeline(isWeekView: !_isMonthView),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showQuickMenu)
            GestureDetector(
              onTap: () => setState(() => _showQuickMenu = false),
              child: Container(
                color: Colors.white.withOpacity(0.1),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          if (_showQuickMenu)
            Positioned(
              bottom: 100,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _quickActionRow('Rapport de Mission', Icons.description, () {
                    setState(() => _showQuickMenu = false);
                    context.push(AppConstants.volunteerMissionReportRoute);
                  }),
                  const SizedBox(height: 24),
                  _quickActionRow('Proposer Aide', Icons.favorite_border, () {
                    setState(() => _showQuickMenu = false);
                    context.push(AppConstants.volunteerOfferHelpRoute);
                  }),
                  const SizedBox(height: 24),
                  _quickActionRow(
                      'Nouvelle Disponibilité', Icons.event_available, () {
                    setState(() => _showQuickMenu = false);
                    context.push(AppConstants.volunteerNewAvailabilityRoute);
                  }),
                ],
              ),
            ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Material(
              color: _showQuickMenu ? _brandBlueDark : _brandBlue,
              borderRadius: BorderRadius.circular(999),
              elevation: 4,
              shadowColor: _brandBlue.withOpacity(0.4),
              child: InkWell(
                onTap: () => setState(() => _showQuickMenu = !_showQuickMenu),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: _showQuickMenu ? 0.785 : 0,
                    child: const Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionRow(String label, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brandBlueDark)),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _brandBlue.withOpacity(0.2)),
              ),
              child: Icon(icon, color: _brandBlueDark, size: 26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final first = DateTime(_displayDate.year, _displayDate.month, 1);
    final start = first.subtract(Duration(days: first.weekday - 1));
    const totalCells = 42;
    final now = DateTime.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays
              .map((d) => Text(d,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400)))
              .toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: totalCells,
          itemBuilder: (_, i) {
            final cellDate = start.add(Duration(days: i));
            final isCurrentMonth = cellDate.month == _displayDate.month;
            final isSelected = cellDate.day == _selectedDay.day &&
                cellDate.month == _selectedDay.month &&
                cellDate.year == _selectedDay.year;
            final isToday = cellDate.day == now.day &&
                cellDate.month == now.month &&
                cellDate.year == now.year;
            final hasDot = isCurrentMonth &&
                (cellDate.day == 1 || cellDate.day == 6 || cellDate.day == 14);
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = cellDate),
              child: Center(
                child: _dayCell(
                  cellDate.day,
                  hasDot,
                  isSelected || isToday,
                  isCurrentMonth,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _dayCell(
      int day, bool hasDot, bool isHighlighted, bool isCurrentMonth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: isHighlighted
              ? const BoxDecoration(color: _brandBlue, shape: BoxShape.circle)
              : null,
          alignment: Alignment.center,
          child: Text('$day',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted
                      ? Colors.white
                      : (isCurrentMonth
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade300))),
        ),
        if (hasDot) ...[
          const SizedBox(height: 2),
          Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: _brandBlue, shape: BoxShape.circle)),
        ],
      ],
    );
  }

  Widget _buildWeekRow() {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final weekStart = _weekStart(_displayDate);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final cellDate = weekStart.add(Duration(days: i));
          final isSelected = cellDate.day == _selectedDay.day &&
              cellDate.month == _selectedDay.month &&
              cellDate.year == _selectedDay.year;
          final hasDot = cellDate.day == 13;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDay = cellDate;
              _displayDate = cellDate;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 44,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekdays[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _brandBlue : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? _brandBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: _brandBlue.withOpacity(0.3),
                                    blurRadius: 12)
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${cellDate.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (hasDot) ...[
                      const SizedBox(height: 2),
                      Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: _brandBlue, shape: BoxShape.circle)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventTimeline({bool isWeekView = false}) {
    return Stack(
      children: [
        Positioned(
            left: 11,
            top: 20,
            bottom: 20,
            child: Container(width: 2, color: Colors.grey.shade200)),
        Column(
          children: [
            _eventCard(
              isActive: true,
              icon: Icons.menu_book,
              iconColor: _brandBlue,
              title: 'Session de lecture',
              time: '14:30 - 16:00',
              subtitle: 'Lucas Martin • Lyon 03',
              initials: 'LM',
            ),
            const SizedBox(height: 16),
            _eventCard(
              isActive: false,
              icon: Icons.park,
              iconColor: Colors.green.shade600,
              title: 'Sortie au Parc',
              time: '17:00 - 18:30',
              subtitle: 'Sophie Dubois • Villeurbanne',
              initials: 'SD',
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bgLight, width: 4)),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                      isWeekView
                          ? 'Fin de journée'
                          : 'Aucun autre événement aujourd\'hui',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _eventCard({
    required bool isActive,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String subtitle,
    required String initials,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: isActive ? _brandBlue : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: _bgLight, width: 4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                      ],
                    ),
                    Text(time,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(initials,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700)),
                    ),
                    const SizedBox(width: 8),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
