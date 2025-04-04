class Points {
  final int id;         // Unique identifier for the user
  int value;            // Points value
  int userId;           // User ID to which the point belongs
  int categoryId;       // Category ID to which the point belongs
  String categoryName;  // Category Name to which the point belongs

  Points(this.id, this.value, this.userId, this.categoryId, this.categoryName);
}