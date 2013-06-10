// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library model;

import 'dart:json' as JSON;
import 'package:web_ui/observe.dart';
import 'package:web_ui/observe/html.dart';
import 'package:lawndart/lawndart.dart';

@observable
class ViewModel {
  bool isVisible(Todo todo) => todo != null &&
      ((showIncomplete && !todo.done) || (showDone && todo.done));

  bool get showIncomplete => locationHash != '#/completed';

  bool get showDone => locationHash != '#/active';
}

final ViewModel viewModel = new ViewModel();

// The real model:

@observable
class AppModel {
  final ObservableList<Todo> todos = new ObservableList<Todo>();
  Store _store = new Store('dart-todomvc', 'todos');
  
  AppModel(){
    _store.open()
      .then((_) => _store.all())
      .then((values) => values.forEach((value) {
        Todo todo = new Todo.deserialize(value);
        todos.add(todo);
        _observeTodo(todo);
      }));
  }
  
  bool get allChecked => todos.length > 0 && todos.every((Todo t) => t.done);

  set allChecked(bool value) => todos.forEach((Todo t) => t.done = value);

  int get doneCount =>
      todos.fold(0, (int count, Todo t) => count + (t.done ? 1 : 0));

  int get remaining => todos.length - doneCount;

  void clearDone() {
    todos.forEach((Todo todo){
      if(todo.done) { _unpersistTodo(todo); };
    });
    /* can't remove todo in List.forEach: ConcurrentModificationError */
    todos.removeWhere((todo) => todo.done);
  }
  
  void createTodo(String strTodo) {
    Todo todo = new Todo(strTodo);
    todo.index = new DateTime.now().millisecondsSinceEpoch.toString();
    
    todos.add(todo);
    _persistTodo(todo);
    _observeTodo(todo);
  }
  
  void _observeTodo(Todo todo) {
    observe(() => todo, (_) => _persistTodo(todo));
  }

  void _persistTodo(Todo todo){
    _store.save(todo.serialize(), todo.index);
  }

  void _unpersistTodo(Todo todo){
    _store.removeByKey(todo.index);
  }
  
  /* X Button click callback */
  void removeTodo(Todo todo){
    todos.remove(todo);
    _unpersistTodo(todo);
  }
}

final AppModel app = new AppModel();

@observable
class Todo {
  String task;
  bool done = false;
  String index = "1";

  Todo(this.task);
  
  Todo.deserialize(String json){
    Map map = JSON.parse(json) as Map;
    task = map['task'];
    done = map['done'];
    index = map['index'];
  }

  String serialize(){
    Map map = {
      'task':task,
      'done':done,
      'index':index
    };
    return JSON.stringify(map);
  }
}
