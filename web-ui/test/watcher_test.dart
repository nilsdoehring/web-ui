// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Tests for the watcher library. */
library watcher_test;

import 'dart:collection';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/watcher.dart';

main() {
  useCompactVMConfiguration();

  group('core', () {
    test('simple watcher ', () {
      int x = 0;
      int valueSeen = null;
      var stop = watch(() => x, expectAsync1((_) { valueSeen = x; }));
      x = 22;
      dispatch();
      expect(valueSeen, equals(22));
      stop(); // cleanup
    });

    test('changes seen only on dispatch', () {
      int x = 0;
      int valueSeen = null;
      var stop = watch(() => x, expectAsync1((_) { valueSeen = x; }));
      x = 22; // not seen
      expect(valueSeen, isNull);
      x = 23;
      dispatch();
      expect(valueSeen, equals(23));
      stop(); // cleanup
    });

    test('changes not seen after unregistering', () {
      int x = 0;
      bool valuesSeen = false;
      var stop = watch(() => x, expectAsync1((_) { valuesSeen = true; }));
      x = 22;
      dispatch();
      stop();

      // nothing dispatched afterwards
      valuesSeen = false;
      x = 1;
      dispatch();
      expect(valuesSeen, isFalse);
    });

    test('unregister twice is ok', () {
      int x = 0;
      bool valuesSeen = false;
      var stop = watch(() => x, expectAsync1((_) { valuesSeen = true; }));
      x = 22;
      dispatch();
      stop();
      stop(); // unnecessary, but safe to call it again.
      valuesSeen = false;
      x = 1;
      dispatch();
      expect(valuesSeen, isFalse);
    });

    test('many changes seen', () {
      int x = 0;
      var valuesSeen = [];
      var stop = watch(() => x,
          expectAsync1((_) => valuesSeen.add(x), count: 3));
      x = 22;
      dispatch();
      x = 11;
      x = 12;
      dispatch();
      x = 14;
      dispatch();
      stop();
      expect(valuesSeen, orderedEquals([22, 12, 14]));
    });

    test('watch event shows old and new values', () {
      int x = 0;
      var oldValue;
      var newValue;
      var stop = watch(() => x, expectAsync1((e) {
        oldValue = e.oldValue;
        newValue = e.newValue;
      }, count: 3));
      x = 1;
      dispatch();
      expect(oldValue, 0);
      expect(newValue, 1);
      x = 3;
      x = 12;
      dispatch();
      expect(oldValue, 1);
      expect(newValue, 12);
      x = 14;
      dispatch();
      expect(oldValue, 12);
      expect(newValue, 14);
      stop();
    });
  });

  group('fields', () {
    test('watch changes to shallow fields', () {
      B b = new B(3);
      int value = null;
      var stop = watch(() => b.c,
        expectAsync1((_) { value = b.c; }, count: 2));
      b.c = 5;
      dispatch();
      expect(value, equals(5));
      b.c = 6;
      dispatch();
      expect(value, equals(6));
      stop();
    });

    test('watch changes to deep fields', () {
      A a = new A();
      int value = null;
      var stop = watch(() => a.b.c,
        expectAsync1((_) { value = a.b.c; }, count: 2));
      a.b.c = 5;
      dispatch();
      expect(value, equals(5));
      a.b.c = 6;
      dispatch();
      expect(value, equals(6));
      stop();
    });

    test('watch changes to deep fields, change within', () {
      A a = new A();
      B b1 = a.b;
      B b2 = new B(2);
      int value = 3;
      var stop = watch(() => a.b.c,
        expectAsync1((_) { value = a.b.c; }, count: 2));
      expect(value, equals(3));
      dispatch();
      a.b = b2;
      dispatch();
      expect(value, equals(2));
      b2.c = 6;
      dispatch();
      expect(value, equals(6));
      b1.c = 16;
      dispatch();
      expect(value, equals(6)); // no change
      stop();
    });
  });

  group('lists', () {
    test('watch changes to lists', () {
      var list = [1, 2, 3];
      var copy = [1, 2, 3];
      var stop = watch(list, expectAsync1((_) {
        copy.clear();
        copy.addAll(list);
      }, count: 2));
      expect(copy, orderedEquals([1, 2, 3]));
      list[1] = 42;
      dispatch();
      expect(copy, orderedEquals([1, 42, 3]));
      list.removeLast();
      dispatch();
      expect(copy, orderedEquals([1, 42]));
      stop();
    });

    test('watch on lists is shallow only', () {
      var list = [new B(4)];
      // callback is not invoked (count: 0)
      var stop = watch(list, expectAsync1((_) {}, count: 0));
      dispatch();
      list[0].c = 42;
      dispatch();
      stop();
    });

    test('watch event shows old and new list values', () {
      var list = [1, 2, 3];
      var before;
      var after;
      var stop = watchAndInvoke(list, expectAsync1((e) {
        before = e.oldValue;
        after = e.newValue;
      }, count: 3));
      expect(before, isNull);
      expect(after, orderedEquals([1, 2, 3]));
      list[1] = 42;
      dispatch();
      expect(before, orderedEquals([1, 2, 3]));
      expect(after, orderedEquals([1, 42, 3]));
      list.removeLast();
      dispatch();
      expect(before, orderedEquals([1, 42, 3]));
      expect(after, orderedEquals([1, 42]));
      stop();
    });
  });

  group('maps', () {
    test('watch changes to maps', () {
      var map = {"a" : 1, "b" : 2, "c" : 3};
      var copy = {"a" : 1, "b" : 2, "c" : 3};
      var stop = watch(map, expectAsync1((_) {
        copy.clear();
        map.forEach((var key, var value) => copy[key] = value);
      }, count: 2));
      expect(copy, equals({"a" : 1, "b" : 2, "c" : 3}));
      map["b"] = 42;
      dispatch();
      expect(copy, equals({"a" : 1, "b" : 42, "c" : 3}));
      map.remove("c");
      dispatch();
      expect(copy, equals({"a" : 1, "b" : 42}));
      stop();
    });

    test('watch on map is shallow only', () {
      var map = {"a" : new B(4)};
      // callback is not invoked (count: 0)
      var stop = watch(map, expectAsync1((_) {}, count: 0));
      dispatch();
      map["a"].c = 42;
      dispatch();
      stop();
    });

    test('watch event shows old and new map values order dependant', () {
      var map = {"a" : 1, "b" : 2, "c" : 3};
      var before;
      var after;
      var stop = watchAndInvoke(map, expectAsync1((e) {
        before = e.oldValue;
        after = e.newValue;
      }, count: 4));
      expect(before, isNull);
      expect(after, equals({"a" : 1, "b" : 2, "c" : 3}));
      map["b"] = 42;
      dispatch();
      expect(before, equals({"a" : 1, "b" : 2, "c" : 3}));
      expect(after, equals({"a" : 1, "b" : 42, "c" : 3}));
      map.remove("c");
      dispatch();
      expect(before, equals({"a" : 1, "b" : 42, "c" : 3}));
      expect(after, equals({"a" : 1, "b" : 42}));
      map.remove("a");
      map["a"] = 1;
      dispatch();
      // Order of keys matter.
      expect(before, equals({"a" : 1, "b" : 42}));
      expect(after, equals({"b" : 42, "a" : 1}));
      stop();
    });

    test('watch event differentiates null values order dependant', () {
      var map = {"a" : 1, "b" : 2, "c" : null};
      var before;
      var after;
      var stop = watchAndInvoke(map, expectAsync1((e) {
        before = e.oldValue;
        after = e.newValue;
      }, count: 2));
      expect(before, isNull);
      expect(after, equals({"a" : 1, "b" : 2, "c" :  null}));
      map["a"] = null;
      map["c"] = 3;
      dispatch();
      expect(before, equals({"a" : 1, "b" : 2, "c" : null}));
      expect(after, equals({"a" : null, "b" : 2, "c" : 3}));
      stop();
    });

    test('watch event differentiates null values order independant', () {
      var map = new HashMap.from({"a" : 1, "b" : 2, "c" : null});
      var before;
      var after;
      var stop = watchAndInvoke(map, expectAsync1((e) {
        before = e.oldValue;
        after = e.newValue;
      }, count: 2));
      expect(before, isNull);
      expect(after, equals(new HashMap.from({"a" : 1, "b" : 2, "c" :  null})));
      map["a"] = null;
      map["c"] = 3;
      dispatch();
      expect(before, equals(new HashMap.from({"a" : 1, "b" : 2, "c" : null})));
      expect(after, equals(new HashMap.from({"a" : null, "b" : 2, "c" : 3})));
      stop();
    });
 
    test('watch event shows old and new map values order independant', () {
      var map = new HashMap.from({"a" : 1, "b" : 2, "c" : 3});
      var before;
      var after;
      var stop = watchAndInvoke(map, expectAsync1((e) {
        before = e.oldValue;
        after = e.newValue;
      }, count: 2));
      expect(before, isNull);
      expect(after, equals(new HashMap.from({"a" : 1, "b" : 2, "c" : 3})));
      map["b"] = 42;
      dispatch();
      expect(before, equals(new HashMap.from({"a" : 1, "b" : 2, "c" : 3})));
      expect(after, equals(new HashMap.from({"a" : 1, "b" : 42, "c" : 3})));
      map.remove("a");
      map["a"] = 1;
      dispatch();
      // Order of keys don't matter.
      stop();
    });
  });

  test('related watchers', () {
    var stop1, stop2;
    int value = 0, val1 = 0, val2 = 0;
    var callback1 = expectAsync1((e) {
      val1 = value;
      stop2(); // stop the other watcher
    });
    var callback2 = expectAsync1((e) {
      val2 = value;
      stop1(); // stop the other watcher
    });
    stop1 = watch(() => value, callback1);
    stop2 = watch(() => value, callback2);
    value = 1;
    dispatch();

    // Watchers are called in the order they were added: callback1 is called,
    // but callback2 was not
    expect(val1, 1);
    expect(val2, 0);
    stop1();

    // Add watchers in the opposite order to check that callback2 is called
    // first in that case.
    stop2 = watch(() => value, callback2);
    stop1 = watch(() => value, callback1);
    value = 2;
    dispatch();

    // callback2 is called, but callback1 is not.
    expect(val1, 1);
    expect(val2, 2);
    stop2();
  });
}

class A {
  B b = new B(3);
}

class B {
  int c;
  B(this.c);
}
