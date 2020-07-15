import 'dart:async';

import 'package:frugal/frugal.dart' as frugal;
import 'package:messaging_sdk/messaging_sdk.dart' as messaging_sdk;
import 'package:todo_transport/todo_transport.dart' as todo_frugal;

import 'package:todo2_sdk/src/models.dart';
import 'package:todo2_sdk/src/todo_sdk.dart';

class WdeskTodoSdk implements TodoSdk {
  static Todo decode(todo_frugal.Todo serviceTodo) {
    return Todo(
      accountID: serviceTodo.accountID,
      id: serviceTodo.id,
      description: serviceTodo.description,
      isCompleted: serviceTodo.isCompleted,
      isPublic: serviceTodo.isPublic,
      notes: serviceTodo.notes,
      userID: serviceTodo.userID
    );
  }

  static todo_frugal.Todo encode(Todo clientTodo) {
    return todo_frugal.Todo()
        ..description = clientTodo.description
        ..id = clientTodo.id
        ..isCompleted = clientTodo.isCompleted
        ..isPublic = clientTodo.isPublic
        ..notes = clientTodo.notes
        ..userID = clientTodo.userID ?? null;
  }

  final messaging_sdk.NatsMessagingClient _natsMessagingClient;
  Completer<todo_frugal.FTodoServiceClient> _todoSdkCompleter = Completer();
  todo_frugal.TodosSubscriber _todosSubscriber;

  StreamController<Todo> _todoCreated = StreamController.broadcast();
  StreamController<Todo> _todoDeleted = StreamController.broadcast();
  StreamController<Todo> _todoUpdated = StreamController.broadcast();

  WdeskTodoSdk(messaging_sdk.NatsMessagingClient this._natsMessagingClient) {
    _initialize();
  }

  @override
  Stream<Todo> get todoCreated => _todoCreated.stream;

  @override
  Stream<Todo> get todoDeleted => _todoDeleted.stream;

  @override
  Stream<Todo> get todoUpdated => _todoUpdated.stream;

  String get _accountResourceId =>
      _natsMessagingClient.authSession.context.accountResourceId;

  String get _membershipResourceId =>
      _natsMessagingClient.authSession.context.membershipResourceId;

  String get _userResourceId =>
      _natsMessagingClient.authSession.context.userResourceId;

  /// Create a to-do.
  @override
  Future<Todo> createTodo(Todo clientTodo) async {
    todo_frugal.FTodoServiceClient service = await _getTodoSdk();
    frugal.FContext ctx = _natsMessagingClient.createFContext();
    todo_frugal.Todo created = 
        await service.createTodo(ctx, encode(clientTodo));
    return decode(created);
  }

  /// Delete a to-do.
  @override
  Future<Null> deleteTodo(String todoId) async {
    todo_frugal.FTodoServiceClient service = await _getTodoSdk();
    frugal.FContext ctx = _natsMessagingClient.createFContext();
    await service.deleteTodo(ctx, todoId);
  }

  /// Query for to-dos.
  @override
  Future<List<Todo>> queryTodos(
    {bool includeComplete: false,
    bool includeIncomplete: false,
    bool includePrivate: false,
    bool includePublic: false}) async {
      todo_frugal.FTodoServiceClient service = await _getTodoSdk();
      frugal.FContext ctx = _natsMessagingClient.createFContext();
      todo_frugal.TodoQueryParams params = todo_frugal.TodoQueryParams()
        ..includeComplete = includeComplete
        ..includeIncomplete = includeIncomplete
        ..includePrivate = includePrivate
        ..includePublic = includePublic;
      
      List<todo_frugal.Todo> todos = await service.queryTodos(ctx, params);
      return todos.map((todo) => decode(todo)).toList();
  }

  /// Update a to-do.
  @override
  Future<Todo> updateTodo(Todo todo) async {
    todo_frugal.FTodoServiceClient service = await _getTodoSdk();
    frugal.FContext ctx = _natsMessagingClient.createFContext();
    todo_frugal.Todo serviceTodo = encode(todo);
    todo_frugal.Todo updated = await service.updateTodo(ctx, serviceTodo);
    return decode(updated);
  }

  @override
  bool userCanAccess(Todo todo) =>
      todo.isPublic || todo.userID == _userResourceId;

  _initialize() async {
    // Set up an RPC client.
    final service =
        messaging_sdk.newServiceDescriptor(natsSubject: 'v1.todo-service');
    final rpcProvider = _natsMessagingClient.newClient(service);
    await rpcProvider.transport.open();

    final todoClient = todo_frugal.FTodoServiceClient(rpcProvider);
    _todoSdkCompleter.complete(todoClient);

    // Obtain a subscriber
    final pubSubProvider = await _natsMessagingClient.newPubSubProvider();
    _todosSubscriber = todo_frugal.TodosSubscriber(pubSubProvider);

    // Subscribe to the to-do events
    _subscribe();
  }

  // The RPC client is obtained asynchronously. RPC methods will use this to
  // ensure that the client is available before trying to use it.
  Future<todo_frugal.FTodoServiceClient> _getTodoSdk() => _todoSdkCompleter.future;

  void _subscribe() {
    _todosSubscriber
        .subscribeTodoCreated(_accountResourceId, _membershipResourceId, 
            (frugal.FContext context, todo_frugal.Todo todo) {
        _todoCreated.add(decode(todo));
    });

    _todosSubscriber
        .subscribeTodoDeleted(_accountResourceId, _membershipResourceId, 
            (frugal.FContext context, todo_frugal.Todo todo) {
        _todoDeleted.add(decode(todo));
    });

    _todosSubscriber
        .subscribeTodoUpdated(_accountResourceId, _membershipResourceId, 
            (frugal.FContext context, todo_frugal.Todo todo) {
        _todoUpdated.add(decode(todo));
    });
  }

}