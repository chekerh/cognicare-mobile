enum ReminderType {
  water,
  meal,
  medication,
  homework,
  activity,
  hygiene,
  custom,
}

enum ReminderFrequency {
  once,
  daily,
  weekly,
  interval,
}

/// One entry in completion history (from API).
class CompletionHistoryEntry {
  final DateTime date;
  final bool completed;
  final String? feedback;
  final DateTime? completedAt;

  CompletionHistoryEntry({
    required this.date,
    required this.completed,
    this.feedback,
    this.completedAt,
  });

  static CompletionHistoryEntry? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final date = json['date'];
    if (date == null) return null;
    return CompletionHistoryEntry(
      date: date is String ? DateTime.parse(date) : date as DateTime,
      completed: json['completed'] as bool? ?? false,
      feedback: json['feedback'] as String?,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is String
              ? DateTime.parse(json['completedAt'] as String)
              : json['completedAt'] as DateTime)
          : null,
    );
  }
}

class TaskReminder {
  final String id;
  final String childId;
  final String createdBy;
  final ReminderType type;
  final String title;
  final String? description;
  final String? icon;
  final String? color;
  final ReminderFrequency frequency;
  final List<String> times;
  final int? intervalMinutes;
  final List<String> daysOfWeek;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool isActive;
  final String? linkedNutritionPlanId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? completedToday;
  final DateTime? completedAt;
  final String? verificationStatus;
  final Map<String, dynamic>? verificationMetadata;
  final List<CompletionHistoryEntry>? completionHistory;

  TaskReminder({
    required this.id,
    required this.childId,
    required this.createdBy,
    required this.type,
    required this.title,
    this.description,
    this.icon,
    this.color,
    required this.frequency,
    required this.times,
    this.intervalMinutes,
    required this.daysOfWeek,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.isActive,
    this.linkedNutritionPlanId,
    this.createdAt,
    this.updatedAt,
    this.completedToday,
    this.completedAt,
    this.verificationStatus,
    this.verificationMetadata,
    this.completionHistory,
  });

  factory TaskReminder.fromJson(Map<String, dynamic> json) {
    return TaskReminder(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      type: _reminderTypeFromString(json['type']),
      title: json['title'] ?? '',
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      frequency: _reminderFrequencyFromString(json['frequency']),
      times: (json['times'] as List<dynamic>?)?.cast<String>() ?? [],
      intervalMinutes: json['intervalMinutes'],
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.cast<String>() ?? [],
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      isActive: json['isActive'] ?? true,
      linkedNutritionPlanId: json['linkedNutritionPlanId'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      completedToday: json['completedToday'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      verificationStatus: json['verificationStatus'],
      verificationMetadata: json['verificationMetadata'],
      completionHistory: (json['completionHistory'] as List<dynamic>?)
          ?.map(
              (e) => CompletionHistoryEntry.fromJson(e as Map<String, dynamic>))
          .whereType<CompletionHistoryEntry>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'type': type.name,
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'frequency': frequency.name,
      'times': times,
      'intervalMinutes': intervalMinutes,
      'daysOfWeek': daysOfWeek,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'isActive': isActive,
      'linkedNutritionPlanId': linkedNutritionPlanId,
      'verificationStatus': verificationStatus,
      'verificationMetadata': verificationMetadata,
    };
  }

  static ReminderType _reminderTypeFromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'water':
        return ReminderType.water;
      case 'meal':
        return ReminderType.meal;
      case 'medication':
        return ReminderType.medication;
      case 'homework':
        return ReminderType.homework;
      case 'activity':
        return ReminderType.activity;
      case 'hygiene':
        return ReminderType.hygiene;
      default:
        return ReminderType.custom;
    }
  }

  static ReminderFrequency _reminderFrequencyFromString(String? frequency) {
    switch (frequency?.toLowerCase()) {
      case 'once':
        return ReminderFrequency.once;
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'interval':
        return ReminderFrequency.interval;
      default:
        return ReminderFrequency.daily;
    }
  }

  TaskReminder copyWith({
    bool? completedToday,
    DateTime? completedAt,
    String? verificationStatus,
    Map<String, dynamic>? verificationMetadata,
    List<CompletionHistoryEntry>? completionHistory,
  }) {
    return TaskReminder(
      id: id,
      childId: childId,
      createdBy: createdBy,
      type: type,
      title: title,
      description: description,
      icon: icon,
      color: color,
      frequency: frequency,
      times: times,
      intervalMinutes: intervalMinutes,
      daysOfWeek: daysOfWeek,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      isActive: isActive,
      linkedNutritionPlanId: linkedNutritionPlanId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedToday: completedToday ?? this.completedToday,
      completedAt: completedAt ?? this.completedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationMetadata: verificationMetadata ?? this.verificationMetadata,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }
}
