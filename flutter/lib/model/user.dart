import 'points.dart';

class User {
  int id;             // Unique identifier for the user
  String name;        // User name that can be changed
  List<Points> points;   // User points

  User(this.id, this.name, this.points);

  /// copyWith constructur
  User copyWith({String? name}) {
    return User(
      this.id,
      name ?? this.name,
      this.points,
    );
  }
}