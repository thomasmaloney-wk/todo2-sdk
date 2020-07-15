import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:todo2_sdk/src/todo_sdk.dart';
import 'package:todo2_sdk/src/models.dart';

class MockTodoSdk implements TodoSdk {

  Map<String, Todo> _todos = {};
  Uuid _uuid = Uuid();

  
  StreamController<Todo> _todoCreated = StreamController.broadcast();  
  StreamController<Todo> _todoDeleted = StreamController.broadcast();  
  StreamController<Todo> _todoUpdated = StreamController.broadcast();

  @override
  Stream<Todo> get todoCreated => _todoCreated.stream;

  @override
  Stream<Todo> get todoDeleted => _todoDeleted.stream;

  @override
  Stream<Todo> get todoUpdated => _todoUpdated.stream;

  // The CRUD ops are handled by converting Todos to Maps
  // and writing & reading them from local storage.

  ///Create a to-do
  @override
  Future<Todo> createTodo(Todo todo) async {
    Todo created = Todo(
        description: todo.description,
        id: _uuid.v4(),
        isCompleted: todo.isCompleted,
        isPublic: todo.isPublic,
        notes: todo.notes);
    _todos[created.id] = created;
    _todoCreated.add(created);
    return created;
  }

  /// Delete a to-do.
  @override
  Future<Null> deleteTodo(String todoID) async {
    Todo toDelete = _todos[todoID];
    if (toDelete == null) throw Exception('Todo not found: $todoID');
    _todos.remove(todoID);
    _todoDeleted.add(toDelete);
  }

  /// Query for to-dos.
  @override
  Future<List<Todo>> queryTodos(
      {bool includeComplete: false,
      bool includeIncomplete: false,
      bool includePrivate: false,
      bool includePublic: false}) async {
    if (!includeComplete &&
        !includeIncomplete &&
        !includePrivate &&
        !includePublic) return [];

    List<Todo> todos = [];
    for (var todo in _todos.values) {
      if (!includeComplete && todo.isCompleted) continue;
      if (!includeIncomplete && !todo.isCompleted) continue;
      if (!includePrivate && !todo.isPublic) continue;
      if (!includePublic && todo.isPublic) continue;
      todos.add(todo);
    }

    return todos;
  }

  /// Update a to-do.
  @override
  Future<Todo> updateTodo(Todo todo) async {
    _todos[todo.id] = todo;
    _todoUpdated.add(todo);
    return todo;
  }

  @override
  bool userCanAccess(Todo todo) => true;
}