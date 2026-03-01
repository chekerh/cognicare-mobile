import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task_reminder.dart';
import '../../providers/auth_provider.dart';
import '../../services/children_service.dart';
import '../../services/reminders_service.dart';
import '../../services/saved_appointments_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate500 = Color(0xFF64748B);
const Color _green600 = Color(0xFF16A34A);

/// Un événement affiché sur le calendrier (routine ou rendez-vous).
class _CalendarEvent {
  final DateTime date;
  final String time; // "09:00", "10:30"
  final String title;
  final String? subtitle;
  final bool isAppointment;
  const _CalendarEvent({
    required this.date,
    required this.time,
    required this.title,
    this.subtitle,
    required this.isAppointment,
  });
}

/// Calendrier famille : rendez-vous + routine (rappels) par jour.
class FamilyCalendarScreen extends StatefulWidget {
  const FamilyCalendarScreen({super.key});

  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<_CalendarEvent> _events = [];
  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;
  bool _loading = true;
  String? _error;
  Map<DateTime, List<_CalendarEvent>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadChildrenAndEvents();
  }

  Future<void> _loadChildrenAndEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final childrenService =
        ChildrenService(getToken: () async => auth.accessToken);
    final remindersService =
        RemindersService(getToken: () async => auth.accessToken);

    try {
      final list = await childrenService.getChildren();
      if (!mounted) return;
      String? childId = list.isNotEmpty ? list.first.id : null;
      if (_selectedChildId != null &&
          list.any((c) => c.id == _selectedChildId)) {
        childId = _selectedChildId;
      }
      setState(() {
        _children = list.map((c) => {'id': c.id, 'name': c.fullName}).toList();
        _selectedChildId = childId;
      });

      if (childId == null) {
        setState(() {
          _loading = false;
          _eventsByDay = {};
          _events = [];
        });
        return;
      }

      final reminders = await remindersService.getRemindersByChild(childId);
      if (!mounted) return;

      final events = <_CalendarEvent>[];
      final now = DateTime.now();
      final startMonth = DateTime(now.year, now.month - 1, 1);
      final endMonth = DateTime(now.year, now.month + 2, 0);

      for (final r in reminders) {
        if (!r.isActive) continue;
        final daysOfWeek = r.daysOfWeek;
        final times = r.times;
        if (times.isEmpty) continue;

        for (var d = startMonth;
            d.isBefore(endMonth) || d.isAtSameMomentAs(endMonth);
            d = d.add(const Duration(days: 1))) {
          bool includeDay = false;
          switch (r.frequency) {
            case ReminderFrequency.daily:
              includeDay = true;
              break;
            case ReminderFrequency.weekly:
              final w = d.weekday; // 1=Mon, 7=Sun
              final wStr = w == 7 ? '0' : w.toString();
              includeDay = daysOfWeek.isEmpty || daysOfWeek.contains(wStr);
              break;
            case ReminderFrequency.once:
              if (r.createdAt != null) {
                includeDay = _isSameDay(d, r.createdAt!);
              }
              break;
            default:
              includeDay = true;
          }
          if (!includeDay) continue;
          for (final t in times) {
            events.add(_CalendarEvent(
              date: DateTime(d.year, d.month, d.day),
              time: t,
              title: r.title,
              subtitle: r.description,
              isAppointment: false,
            ));
          }
        }
      }

      // Rendez-vous enregistrés (bouton "Ajouter à mon calendrier")
      final saved = await SavedAppointmentsService.getSavedAppointments();
      for (final a in saved) {
        DateTime? eventDate;
        try {
          final parts = a.dateIso.split('-');
          if (parts.length == 3) {
            eventDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (_) {}
        if (eventDate != null) {
          events.add(_CalendarEvent(
            date: eventDate,
            time: a.time,
            title: a.title,
            subtitle: a.subtitle,
            isAppointment: true,
          ));
        }
      }
      // Rendez-vous mock (exemples)
      final mockAppointments = _mockAppointments();
      for (final a in mockAppointments) {
        events.add(_CalendarEvent(
          date: a['date'] as DateTime,
          time: a['time'] as String,
          title: a['title'] as String,
          subtitle: a['subtitle'] as String?,
          isAppointment: true,
        ));
      }

      final byDay = <DateTime, List<_CalendarEvent>>{};
      for (final e in events) {
        final key = DateTime(e.date.year, e.date.month, e.date.day);
        byDay.putIfAbsent(key, () => []).add(e);
      }

      setState(() {
        _eventsByDay = byDay;
        _refreshEventsForSelectedDay();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _eventsByDay = {};
        _events = [];
      });
    }
  }

  List<Map<String, dynamic>> _mockAppointments() {
    final now = DateTime.now();
    return [
      {
        'date': DateTime(now.year, now.month, now.day + 2).isBefore(now)
            ? DateTime(now.year, now.month + 1, now.day + 2)
            : DateTime(now.year, now.month, now.day + 2),
        'time': '10:30',
        'title': 'Dr. Sarah Williams',
        'subtitle': 'Neurologue',
      },
      {
        'date': DateTime(now.year, now.month, now.day + 5).isBefore(now)
            ? DateTime(now.year, now.month + 1, now.day + 5)
            : DateTime(now.year, now.month, now.day + 5),
        'time': '15:00',
        'title': 'Dr. James Cooper',
        'subtitle': 'Gériatre',
      },
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _refreshEventsForSelectedDay() {
    if (_selectedDay == null) {
      _events = [];
      return;
    }
    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final list = _eventsByDay[key] ?? [];
    list.sort((a, b) => a.time.compareTo(b.time));
    _events = list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.dashboardPlanning,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _slate800,
          ),
        ),
        backgroundColor: _primary,
        foregroundColor: _slate800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            onPressed: () => context.push(AppConstants.familyExpertAppointmentsRoute),
            tooltip: 'Mes rendez-vous',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChildrenAndEvents,
                          style: ElevatedButton.styleFrom(backgroundColor: _primary),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_children.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            value: _selectedChildId != null &&
                                    _children.any((c) => c['id'] == _selectedChildId)
                                ? _selectedChildId
                                : (_children.isNotEmpty
                                    ? _children.first['id'] as String
                                    : null),
                            decoration: InputDecoration(
                              labelText: 'Enfant',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _children
                                .map((c) => DropdownMenuItem<String>(
                                      value: c['id'] as String,
                                      child: Text(c['name'] as String),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedChildId = v;
                                _loadChildrenAndEvents();
                              });
                            },
                          ),
                        ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        child: SizedBox(
                          height: 400,
                          child: TableCalendar<_CalendarEvent>(
                            firstDay: DateTime(2020, 1, 1),
                            lastDay: DateTime(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) {
                              final sel = _selectedDay;
                              return sel != null && _isSameDay(day, sel);
                            },
                            eventLoader: (day) {
                              final key = DateTime(day.year, day.month, day.day);
                              return _eventsByDay[key] ?? [];
                            },
                            calendarFormat: CalendarFormat.month,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              leftChevronIcon: Icon(Icons.chevron_left, color: _slate800),
                              rightChevronIcon: Icon(Icons.chevron_right, color: _slate800),
                            ),
                            calendarStyle: CalendarStyle(
                              selectedDecoration: const BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: _primary.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: _green600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            onDaySelected: (selected, focused) {
                              if (!mounted) return;
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                                _refreshEventsForSelectedDay();
                              });
                            },
                            onPageChanged: (focused) {
                              if (mounted) setState(() => _focusedDay = focused);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _selectedDay != null
                            ? 'Événements le ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                            : 'Sélectionnez un jour',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _slate800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              _selectedDay != null
                                  ? 'Aucun rendez-vous ni tâche ce jour-là.'
                                  : '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _slate500,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._events.map((e) => _buildEventTile(e)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppConstants.familyCreateReminderRoute),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Ajouter un rappel / tâche'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEventTile(_CalendarEvent e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: e.isAppointment ? _primary : _green600.withOpacity(0.2),
          child: Icon(
            e.isAppointment ? Icons.event : Icons.check_circle_outline,
            color: e.isAppointment ? _slate800 : _green600,
            size: 22,
          ),
        ),
        title: Text(
          e.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _slate800,
          ),
        ),
        subtitle: Text(
          [if (e.subtitle != null && e.subtitle!.isNotEmpty) e.subtitle, e.time]
              .whereType<String>()
              .join(' · '),
          style: const TextStyle(fontSize: 12, color: _slate500),
        ),
      ),
    );
  }
}
