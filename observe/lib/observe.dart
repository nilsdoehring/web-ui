// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * *Warning*: this library is experimental, and APIs are subject to change.
 *
 * This library is used to observe changes to [Observable] types. It also
 * has helpers to implement [Observable] objects.
 *
 * For example:
 *
 *     class Monster extends ObservableMixin {
 *       int _health = 100;
 *       static const _HEALTH = 'health';
 *       get health => _health;
 *       set health(value) {
 *         _health = notifyChange(_HEALTH, _health, value);
 *       }
 *       void damage(int amount) {
 *         print('$this takes $amount damage!');
 *         health -= amount;
 *       }
 *       toString() => 'Monster';
 *
 *       // These methods are temporary until dart2js supports mirrors.
 *       getValue(key) {
 *         if (key == _HEALTH) return health;
 *         return null;
 *       }
 *       setValue(key, val) {
 *         if (key == _HEALTH) health = val;
 *       }
 *     }
 *
 *     main() {
 *       var obj = new Monster();
 *       obj.changes.listen((records) {
 *         print('Changes to $obj were: $records');
 *       });
 *       // Asynchronously schedules delivery of these changes
 *       obj.damage(10);
 *       obj.damage(20);
 *       print('done!');
 *     }
 */
library observe;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

// TODO(jmesserly): use libraries instead of parts.
part 'src/list_diff.dart';
part 'src/observe_path.dart';
part 'src/observable.dart';
part 'src/observable_box.dart';
part 'src/observable_list.dart';
part 'src/observable_map.dart';
