import 'dart:async';

import 'package:todo2_sdk/src/models.dart';

abstract class TodoSdk {
  /// Broadcast stream of "to-do created" events.
  Stream<Todo> get todoCreated;

  /// Broadcast stream of "to-do deleted" events.
  Stream<Todo> get todoDeleted;

  /// Broadcast stream of "to-do updated" events.
  Stream<Todo> get todoUpdated;

  /// Create a to-do.
  Future<Todo> createTodo(Todo todo);

  /// Delete a to-do.
  Future<Todo> deleteTodo(String todoID);

  /// Query for to-dos.
  Future<List<Todo>> queryTodos(
    {bool includeComplete: false,
    bool includeIncomplete: false,
    bool includePrivate: false,
    bool includePublic: false});

  /// Update a to-do.
  Future<Todo> updateTodo(Todo todo);

  /// Determine whether the current session's user
  /// can access this to-do.
  bool userCanAccess(Todo todo);
}