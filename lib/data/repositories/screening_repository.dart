import '../../models/screening.dart';

abstract class ScreeningRepository {
  Future<List<Screening>> getScreenings();
  Future<List<Screening>> getScreeningsForChild(String childId);
  Future<void> addScreening(Screening screening);
  Future<void> updateScreening(Screening screening);
}
