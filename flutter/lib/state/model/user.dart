import 'points.dart';

class User {
  final int id;             // Unique identifier for the user
  final String name;        // User name that can be changed
  final List<Points> points;   // User points

  User(this.id, this.name, this.points);
}