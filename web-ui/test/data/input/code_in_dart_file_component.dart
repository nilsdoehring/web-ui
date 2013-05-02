// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_in_dart_file_component;

import 'package:web_ui/web_ui.dart';

// Note: this component is intentionally not marked observable, so we can
// verify the fix for https://github.com/dart-lang/web-ui/issues/236.
class MyComponent extends WebComponent {
  String field = "hello";

  void sayHello(String name) => print('hello $name!');
}
