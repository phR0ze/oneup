import 'points_old.dart';

class UserOld {
  int id;             // Unique identifier for the user
  String name;        // User name that can be changed
  List<PointsOld> points;   // User points

  // Constructor
  UserOld(this.id, this.name, this.points);

  /// copyWith constructur
  UserOld copyWith({String? name}) {
    return UserOld(
      this.id,
      name ?? this.name,
      this.points,
    );
  }
}