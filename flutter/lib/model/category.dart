class Category{
  int id;
  String name;

  // Constructor
  Category(this.id, this.name);

  /// copyWith constructur
  Category copyWith({String? name}) {
    return Category(
      this.id,
      name ?? this.name,
    );
  }
}