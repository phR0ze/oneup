class Points {
  final int id;               // Unique identifier for the user
  final int value;            // Points value
  final int userId;           // User ID to which the point belongs
  final int categoryId;       // Category ID to which the point belongs
  final String categoryName;  // Category Name to which the point belongs

  Points(this.id, this.value, this.userId, this.categoryId, this.categoryName);
}