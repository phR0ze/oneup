class CategoryOld{
  int id;
  String name;

  // Constructor
  CategoryOld(this.id, this.name);

  /// copyWith constructur
  CategoryOld copyWith({String? name}) {
    return CategoryOld(
      this.id,
      name ?? this.name,
    );
  }
}