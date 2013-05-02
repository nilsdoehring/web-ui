// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for linked_list. */
library test.linked_list_test;

import 'package:unittest/unittest.dart';
import 'package:web_ui/src/linked_list.dart';

var list;
var one;
var two;
var five;

void setup() {
  list = new LinkedList<int>();
  one = list.add(1);
  two = list.add(2);
  list.addAll([3, 4]);
  five = list.add(5);
  list.add(6);
}

main() {
  test('list is iterable', () {
    setup();
    expect(list.join(', '), '1, 2, 3, 4, 5, 6');
  });

  test('iterate and remove current', () {
    setup();
    var res = [];
    for (var x in list) {
      if (x == 5) {
        five.remove();
      } else {
        res.add(x);
      }
    }
    expect(res, orderedEquals([1, 2, 3, 4, 6]));
  });

  test('iterate and remove immediately next node', () {
    setup();
    var res = [];
    for (var x in list) {
      if (x == 1) {
        two.remove();
      }
      res.add(x);
    }
    expect(res, orderedEquals([1, 3, 4, 5, 6]));
  });

  test('iterate and remove something in the future', () {
    setup();
    var res = [];
    for (var x in list) {
      if (x == 1) {
        two.remove();
        five.remove();
      }
      res.add(x);
    }
    expect(res, orderedEquals([1, 3, 4, 6]));
  });

  test('iterate and remove both the current and next node', () {
    setup();
    var res = [];
    for (var x in list) {
      if (x == 1) {
        one.remove();
        two.remove();
        five.remove();
      }
      res.add(x);

    }
    expect(res, orderedEquals([1, 3, 4, 6]));
  });

  test('head/tail are null after removing all items', () {
    list = new LinkedList<int>();
    var item1 = list.add(1);
    var item2 = list.add(2);
    expect(list.length, 2);
    expect(list.head, item1);
    expect(list.tail, item2);

    item1.remove();
    expect(list.length, 1);
    expect(list.head, item2);
    expect(list.tail, item2);

    item2.remove();
    expect(list.length, 0);
    expect(list.head, null);
    expect(list.tail, null);
  });
}
