class Category{
  final int? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Constructor
  Category({
    this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// copyWith constructur
  Category copyWith({String? name}) {
    return Category({
      id: this.id,
      name ?? this.name,
    });
  }
}