import '../../models/health_center.dart';

abstract class HealthCenterRepository {
  Future<List<HealthCenter>> getCenters();
}
