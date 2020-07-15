import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:uuid/uuid.dart';

import 'package:todo2_sdk/src/todo_sdk.dart';
import 'package:todo2_sdk/src/models.dart';

class LocalTodoSdk implements TodoSdk {
  static const String _localStorageKey = 'todo2-todos';

  Map<String, Todo> _todos = {};
  Uuid _uuid = Uuid();

  LocalTodoSdk() {
    _loadTodos();
  }

  // Pub/Sub will be handled manually by adding to these stream controllers
  // whenever they occur.
  
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
    _writeTodos();
    _todoCreated.add(created);
    return created;
  }

  /// Delete a to-do.
  @override
  Future<Null> deleteTodo(String todoID) async {
    Todo toDelete = _todos[todoID];
    if (toDelete == null) throw Exception('Todo not found: $todoID');
    _todos.remove(todoID);
    _writeTodos();
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
    _writeTodos();
    _todoUpdated.add(todo);
    return todo;
  }

  @override
  bool userCanAccess(Todo todo) => true;

  void _loadTodos() {
    _todos = {};
    if (window.localStorage.containsKey(_localStorageKey)) {
      Map<String, Map> source = 
          jsonDecode(window.localStorage[_localStorageKey]);
      
      source.forEach((id, todoMap) {
        _todos[id] = Todo(
          description: todoMap['description'],
          id: todoMap['id'],
          isCompleted: todoMap['isCompleted'],
          isPublic: todoMap['isPublic'],
          notes: todoMap['notes']);
      });
    }
  }

  void _writeTodos() {
    Map json = {};
    _todos.forEach((key, todo) {
      json[key] = {
        'description': todo.description,
        'id': todo.id,
        'isCompleted': todo.isCompleted,
        'isPublic': todo.isPublic,
        'notes': todo.notes
      };
    });
    window.localStorage[_localStorageKey] = jsonEncode(json);
  }
}