import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _key = 'saved_calendar_appointments';

/// Un rendez-vous enregistré dans le calendrier (ex. après confirmation).
class SavedAppointment {
  final String dateIso; // "2025-02-28"
  final String time;   // "15:30"
  final String title;
  final String? subtitle;
  /// "video" | "in_person"
  final String? mode;
  /// UserId du professionnel (pour lancer l'appel depuis "Rejoindre l'appel").
  final String? expertUserId;

  const SavedAppointment({
    required this.dateIso,
    required this.time,
    required this.title,
    this.subtitle,
    this.mode,
    this.expertUserId,
  });

  Map<String, dynamic> toJson() => {
        'dateIso': dateIso,
        'time': time,
        'title': title,
        'subtitle': subtitle,
        'mode': mode,
        'expertUserId': expertUserId,
      };

  static SavedAppointment fromJson(Map<String, dynamic> json) =>
      SavedAppointment(
        dateIso: json['dateIso'] as String? ?? '',
        time: json['time'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        mode: json['mode'] as String?,
        expertUserId: json['expertUserId'] as String?,
      );

  /// Date au format français "28 Février 2025".
  static const List<String> _monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  String get dateFormatted {
    final parts = dateIso.split('-');
    if (parts.length != 3) return dateIso;
    try {
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      if (m >= 1 && m <= 12) {
        return '$d ${_monthNames[m - 1]} $y';
      }
    } catch (_) {}
    return dateIso;
  }

  bool get isVideo => mode == 'video';
}


/// Enregistre et charge les rendez-vous ajoutés au calendrier par l'utilisateur.
class SavedAppointmentsService {
  static Future<void> saveAppointment(SavedAppointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedAppointments();
    list.add(appointment);
    final encoded =
        list.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(encoded));
  }

  static Future<List<SavedAppointment>> getSavedAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => SavedAppointment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
