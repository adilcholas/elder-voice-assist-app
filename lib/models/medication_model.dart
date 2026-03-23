import 'dart:convert';

enum MedicationFrequency {
  daily,
  twiceDaily,
  threeTimesDaily,
  weekly,
  asNeeded,
}

class MedicationTime {
  final int hour;
  final int minute;

  const MedicationTime({required this.hour, required this.minute});

  String get formatted {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Map<String, dynamic> toMap() => {'hour': hour, 'minute': minute};

  factory MedicationTime.fromMap(Map<String, dynamic> map) =>
      MedicationTime(hour: map['hour'], minute: map['minute']);
}

class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final List<MedicationTime> times;
  final String? instructions;
  final bool isActive;
  final DateTime? lastTaken;
  final DateTime? nextDue;

  const MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.instructions,
    this.isActive = true,
    this.lastTaken,
    this.nextDue,
  });

  bool get isDueNow {
    if (nextDue == null) return false;
    final now = DateTime.now();
    return now.isAfter(nextDue!.subtract(const Duration(minutes: 15)));
  }

  bool get isOverdue {
    if (nextDue == null) return false;
    final now = DateTime.now();
    return now.isAfter(nextDue!.add(const Duration(minutes: 30)));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.name,
      'times': times.map((t) => t.toMap()).toList(),
      'instructions': instructions,
      'isActive': isActive,
      'lastTaken': lastTaken?.toIso8601String(),
      'nextDue': nextDue?.toIso8601String(),
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      frequency: MedicationFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => MedicationFrequency.daily,
      ),
      times: (map['times'] as List<dynamic>)
          .map((t) => MedicationTime.fromMap(t as Map<String, dynamic>))
          .toList(),
      instructions: map['instructions'],
      isActive: map['isActive'] as bool? ?? true,
      lastTaken: map['lastTaken'] != null
          ? DateTime.tryParse(map['lastTaken'])
          : null,
      nextDue: map['nextDue'] != null
          ? DateTime.tryParse(map['nextDue'])
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MedicationModel.fromJson(String source) =>
      MedicationModel.fromMap(jsonDecode(source));

  MedicationModel copyWith({
    String? name,
    String? dosage,
    MedicationFrequency? frequency,
    List<MedicationTime>? times,
    String? instructions,
    bool? isActive,
    DateTime? lastTaken,
    DateTime? nextDue,
  }) {
    return MedicationModel(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      lastTaken: lastTaken ?? this.lastTaken,
      nextDue: nextDue ?? this.nextDue,
    );
  }

  /// Compute the next due DateTime based on frequency
  DateTime computeNextDue() {
    final now = DateTime.now();
    if (times.isEmpty) return now.add(const Duration(hours: 8));

    // Find the next time slot today or tomorrow
    for (final t in times) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        t.hour,
        t.minute,
      );
      if (candidate.isAfter(now)) return candidate;
    }
    // All times for today passed — next is first slot tomorrow
    final first = times.first;
    return DateTime(now.year, now.month, now.day + 1, first.hour, first.minute);
  }
}
