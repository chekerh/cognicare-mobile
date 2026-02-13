class Medication {
  final String name;
  final String dosage;
  final String time;
  final bool withFood;
  final String? notes;

  Medication({
    required this.name,
    required this.dosage,
    required this.time,
    required this.withFood,
    this.notes,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      time: json['time'] ?? '',
      withFood: json['withFood'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'time': time,
      'withFood': withFood,
      if (notes != null) 'notes': notes,
    };
  }
}

class Snack {
  final String time;
  final List<String> items;

  Snack({
    required this.time,
    required this.items,
  });

  factory Snack.fromJson(Map<String, dynamic> json) {
    return Snack(
      time: json['time'] ?? '',
      items: (json['items'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'items': items,
    };
  }
}

class NutritionPlan {
  final String id;
  final String childId;
  final String createdBy;
  final int dailyWaterGoal;
  final int waterReminderInterval;
  final List<String> breakfast;
  final String? breakfastTime;
  final List<String> lunch;
  final String? lunchTime;
  final List<String> dinner;
  final String? dinnerTime;
  final List<Snack> snacks;
  final List<String> allergies;
  final List<String> restrictions;
  final List<String> preferences;
  final List<Medication> medications;
  final String? specialNotes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NutritionPlan({
    required this.id,
    required this.childId,
    required this.createdBy,
    required this.dailyWaterGoal,
    required this.waterReminderInterval,
    required this.breakfast,
    this.breakfastTime,
    required this.lunch,
    this.lunchTime,
    required this.dinner,
    this.dinnerTime,
    required this.snacks,
    required this.allergies,
    required this.restrictions,
    required this.preferences,
    required this.medications,
    this.specialNotes,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      dailyWaterGoal: json['dailyWaterGoal'] ?? 6,
      waterReminderInterval: json['waterReminderInterval'] ?? 120,
      breakfast:
          (json['breakfast'] as List<dynamic>?)?.cast<String>() ?? [],
      breakfastTime: json['breakfastTime'],
      lunch: (json['lunch'] as List<dynamic>?)?.cast<String>() ?? [],
      lunchTime: json['lunchTime'],
      dinner: (json['dinner'] as List<dynamic>?)?.cast<String>() ?? [],
      dinnerTime: json['dinnerTime'],
      snacks: (json['snacks'] as List<dynamic>?)
              ?.map((s) => Snack.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      allergies:
          (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      restrictions:
          (json['restrictions'] as List<dynamic>?)?.cast<String>() ?? [],
      preferences:
          (json['preferences'] as List<dynamic>?)?.cast<String>() ?? [],
      medications: (json['medications'] as List<dynamic>?)
              ?.map((m) => Medication.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      specialNotes: json['specialNotes'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'dailyWaterGoal': dailyWaterGoal,
      'waterReminderInterval': waterReminderInterval,
      'breakfast': breakfast,
      if (breakfastTime != null) 'breakfastTime': breakfastTime,
      'lunch': lunch,
      if (lunchTime != null) 'lunchTime': lunchTime,
      'dinner': dinner,
      if (dinnerTime != null) 'dinnerTime': dinnerTime,
      'snacks': snacks.map((s) => s.toJson()).toList(),
      'allergies': allergies,
      'restrictions': restrictions,
      'preferences': preferences,
      'medications': medications.map((m) => m.toJson()).toList(),
      if (specialNotes != null) 'specialNotes': specialNotes,
      'isActive': isActive,
    };
  }
}
