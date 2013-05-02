// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/** Common functions used by TodoMVC tests. */
library todomvc_common;

import 'dart:html';
import 'package:web_ui/watcher.dart';

void markChecked(item) {
  var node = document.queryAll('input[type=checkbox]')[item + 1];
  node.dispatchEvent(new MouseEvent('click', detail: 1));
}

void checkAll() {
  var node = document.queryAll('input[type=checkbox]')[0];
  node.dispatchEvent(new MouseEvent('click', detail: 1));
}

void clearCompleted() {
  var node = document.query('#clear-completed');
  node.dispatchEvent(new MouseEvent('click', detail: 1));
}

var _newTodo = (() => document.query('#new-todo'))();
var _form = (() => document.query('#__e-0'))();

void addNote(String note) {
  _newTodo.value = note;
  _form.dispatchEvent(new Event('submit'));
  dispatch();
}
