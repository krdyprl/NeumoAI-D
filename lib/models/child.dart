import 'enums.dart';
import 'vaccination.dart';

class Child {
  const Child({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.birthWeight,
    required this.weight,
    required this.height,
    required this.emoji,
    this.medicalHistory = '',
    this.vaccinations = const [],
  });

  final String id;
  final String name;
  final Gender gender;
  final String birthDate;
  final double birthWeight;
  final double weight;
  final double height;
  final String emoji;
  final String medicalHistory;
  final List<Vaccination> vaccinations;

  Child copyWith({
    String? id,
    String? name,
    Gender? gender,
    String? birthDate,
    double? birthWeight,
    double? weight,
    double? height,
    String? emoji,
    String? medicalHistory,
    List<Vaccination>? vaccinations,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthWeight: birthWeight ?? this.birthWeight,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      emoji: emoji ?? this.emoji,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      vaccinations: vaccinations ?? this.vaccinations,
    );
  }
}
