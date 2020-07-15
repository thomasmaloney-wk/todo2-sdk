class Todo {
  /// Account identifier.
  final String accountID;

  /// Short description of item. Serves as the title.
  final String description;

  /// Unique identifier. Assigned by server.
  final String id;

  /// Whether or not this item has been marked as completed.
  final bool isCompleted;

  /// Whether or not everyone can see this item (public) 
  /// or only the owner can (private)
  final bool isPublic;

  /// Notes
  final String notes;

  /// Unique user identifier of the user who created this item.
  final String userID;

  Todo(
    {String this.accountID,
    String this.description: '',
    String this.id,
    bool this.isCompleted: false,
    bool this.isPublic: false,
    String this.notes: '',
    String this.userID});

  Todo change(
    {String description, bool isCompleted, bool isPublic, String notes}) {
      final rDesc = description ?? this.description;
      final rCompleted = isCompleted ?? this.isCompleted;
      final rPublic = isPublic ?? this.isPublic;
      final rNotes = notes ?? this.notes;

      return Todo(
        accountID: accountID,
        description: rDesc,
        id: id,
        isCompleted: rCompleted,
        isPublic: rPublic,
        notes: rNotes,
        userID: userID);
    }
}