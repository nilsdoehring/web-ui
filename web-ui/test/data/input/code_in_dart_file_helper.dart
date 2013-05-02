// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_in_dart_file_helper;

import 'dart:html';
import 'package:unittest/unittest.dart';

// Make sure we can import the Dart file and use it.
import 'code_in_dart_file_component.dart';

useMyComponent() {
  var component = query('div[is=my-component]').xtag;
  expect(component, new isInstanceOf<MyComponent>());

  (component as MyComponent).sayHello('world');
}
