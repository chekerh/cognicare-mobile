import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/availability_service.dart';

const Color _primary = Color(0xFFa3dae1);
const Color _primaryDark = Color(0xFF7bc5ce);
const Color _brandBlue = Color(0xFFa3dae1);
const Color _bgLight = Color(0xFFF0F9FF);

/// Nouvelle Disponibilité — sélection dates, plage horaire, récurrence, enregistrer.
class VolunteerNewAvailabilityScreen extends StatefulWidget {
  const VolunteerNewAvailabilityScreen({super.key});

  @override
  State<VolunteerNewAvailabilityScreen> createState() =>
      _VolunteerNewAvailabilityScreenState();
}

class _VolunteerNewAvailabilityScreenState
    extends State<VolunteerNewAvailabilityScreen> {
  DateTime _displayMonth = DateTime.now();
  final Set<DateTime> _selectedDates = {};
  bool _recurrenceOn = true;
  int _recurrenceType = 0; // 0 Hebdomadaire, 1 Toutes les 2 semaines
  final TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  final TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _saving = false;

  static const _daysShort = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];

  List<DateTime?> _getCalendarDays() {
    final first = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final last = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    final startWeekday = first.weekday;
    final padStart = startWeekday - 1;
    final days = <DateTime?>[];
    for (int i = 0; i < padStart; i++) {
      final d = first.subtract(Duration(days: padStart - i));
      days.add(d);
    }
    for (int i = 1; i <= last.day; i++) {
      days.add(DateTime(_displayMonth.year, _displayMonth.month, i));
    }
    final remaining = 42 - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(last.add(Duration(days: i)));
    }
    return days;
  }

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSelected(DateTime d) {
    return _selectedDates
        .any((s) => s.year == d.year && s.month == d.month && s.day == d.day);
  }

  void _toggleDate(DateTime d) {
    setState(() {
      final n = _norm(d);
      final existing = _selectedDates
          .where(
              (s) => s.year == n.year && s.month == n.month && s.day == n.day)
          .toList();
      if (existing.isNotEmpty) {
        for (final e in existing) {
          _selectedDates.remove(e);
        }
      } else {
        _selectedDates.add(n);
      }
    });
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _saveAvailability() async {
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez au moins une date'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dates = _selectedDates.map((d) {
        final y = d.year.toString();
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '$y-$m-$day';
      }).toList();
      final service = AvailabilityService();
      await service.create(
        dates: dates,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        recurrence: _recurrenceType == 0 ? 'weekly' : 'biweekly',
        recurrenceOn: _recurrenceOn,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Disponibilité enregistrée'),
            behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getCalendarDays();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  _circleButton(Icons.chevron_left, () => context.pop()),
                  const SizedBox(width: 16),
                  const Text('Nouvelle Disponibilité',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Sélectionner les dates',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.chevron_left,
                                          color: Colors.grey.shade600),
                                      onPressed: () => setState(() =>
                                          _displayMonth = DateTime(
                                              _displayMonth.year,
                                              _displayMonth.month - 1))),
                                  IconButton(
                                      icon: Icon(Icons.chevron_right,
                                          color: Colors.grey.shade600),
                                      onPressed: () => setState(() =>
                                          _displayMonth = DateTime(
                                              _displayMonth.year,
                                              _displayMonth.month + 1))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _daysShort
                                .map((d) => Text(d,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500)))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7, childAspectRatio: 1.2),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: days.length,
                            itemBuilder: (_, i) {
                              final d = days[i];
                              if (d == null) return const SizedBox();
                              final isCurrentMonth =
                                  d.month == _displayMonth.month;
                              final selected = _isSelected(d);
                              final now = DateTime.now();
                              final isToday = isCurrentMonth &&
                                  d.year == now.year &&
                                  d.month == now.month &&
                                  d.day == now.day;
                              return GestureDetector(
                                onTap: isCurrentMonth
                                    ? () => _toggleDate(d)
                                    : null,
                                child: Center(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected ? _primary : null,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isToday && !selected
                                          ? Border.all(
                                              color: _primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      '${d.day}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: !isCurrentMonth
                                            ? Colors.grey.shade400
                                            : selected
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                                'Appuyez pour sélectionner plusieurs dates',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Plage horaire',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DÉBUT',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatTime(_startTime),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Icon(Icons.schedule,
                                              color: Colors.grey.shade500,
                                              size: 20),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                  width: 24,
                                  height: 2,
                                  color: Colors.grey.shade300),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('FIN',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatTime(_endTime),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Icon(Icons.schedule,
                                              color: Colors.grey.shade500,
                                              size: 20),
                                        ],
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
                    const SizedBox(height: 24),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Récurrence',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B))),
                              Switch(
                                value: _recurrenceOn,
                                onChanged: (v) =>
                                    setState(() => _recurrenceOn = v),
                                activeColor: _primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _recurrenceType = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _recurrenceType == 0
                                          ? _primary.withOpacity(0.08)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: _recurrenceType == 0
                                              ? _primary
                                              : Colors.grey.shade200,
                                          width: 2),
                                    ),
                                    child: Text('Hebdomadaire',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _recurrenceType == 0
                                                ? _brandBlue
                                                : Colors.grey.shade500)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _recurrenceType = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _recurrenceType == 1
                                          ? _primary.withOpacity(0.08)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: _recurrenceType == 1
                                              ? _primary
                                              : Colors.grey.shade200,
                                          width: 2),
                                    ),
                                    child: Text('Toutes les 2 semaines',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _recurrenceType == 1
                                                ? _brandBlue
                                                : Colors.grey.shade500)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveAvailability,
                      icon: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle, size: 22),
                      label: Text(
                          _saving
                              ? 'Enregistrement...'
                              : 'Enregistrer ma disponibilité',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: _primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}
