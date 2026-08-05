import '../../models/child.dart';

abstract class ChildRepository {
  Future<List<Child>> getChildren();
  Future<void> addChild(Child child);
  Future<void> updateChild(Child child);
  Future<void> deleteChild(String id);
}
