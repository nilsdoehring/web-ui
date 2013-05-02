// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe_model;

import 'package:web_ui/observe.dart';

@observable
class Model {
  int x = 0;
  int y = 0;
}
