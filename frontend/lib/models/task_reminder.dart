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
  final String? time;
  final int? intervalMinutes;
  final List<String> daysOfWeek;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool piSyncEnabled;
  final bool isActive;
  final String? linkedNutritionPlanId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? completedToday;
  final DateTime? completedAt;

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
    this.time,
    this.intervalMinutes,
    required this.daysOfWeek,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.piSyncEnabled,
    required this.isActive,
    this.linkedNutritionPlanId,
    this.createdAt,
    this.updatedAt,
    this.completedToday,
    this.completedAt,
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
      time: json['time'],
      intervalMinutes: json['intervalMinutes'],
      daysOfWeek:
          (json['daysOfWeek'] as List<dynamic>?)?.cast<String>() ?? [],
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      piSyncEnabled: json['piSyncEnabled'] ?? false,
      isActive: json['isActive'] ?? true,
      linkedNutritionPlanId: json['linkedNutritionPlanId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      completedToday: json['completedToday'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
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
      'time': time,
      'intervalMinutes': intervalMinutes,
      'daysOfWeek': daysOfWeek,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'piSyncEnabled': piSyncEnabled,
      'isActive': isActive,
      'linkedNutritionPlanId': linkedNutritionPlanId,
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
      time: time,
      intervalMinutes: intervalMinutes,
      daysOfWeek: daysOfWeek,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      piSyncEnabled: piSyncEnabled,
      isActive: isActive,
      linkedNutritionPlanId: linkedNutritionPlanId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedToday: completedToday ?? this.completedToday,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
