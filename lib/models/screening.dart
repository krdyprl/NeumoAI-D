import 'enums.dart';

class Screening {
  const Screening({
    required this.id,
    required this.childId,
    required this.date,
    required this.symptoms,
    required this.audioDuration,
    required this.riskLevel,
    required this.disease,
    required this.confidence,
    required this.status,
  });

  final String id;
  final String childId;
  final String date;
  final List<String> symptoms;
  final int audioDuration;
  final RiskLevel riskLevel;
  final String disease;
  final int confidence;
  final SyncStatus status;

  Screening copyWith({SyncStatus? status}) => Screening(
        id: id,
        childId: childId,
        date: date,
        symptoms: symptoms,
        audioDuration: audioDuration,
        riskLevel: riskLevel,
        disease: disease,
        confidence: confidence,
        status: status ?? this.status,
      );
}
