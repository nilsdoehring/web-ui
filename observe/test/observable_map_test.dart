// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:observe/observe.dart';

main() {
  // TODO(jmesserly): need all standard Map API tests.

  group('observe length', () {

    ObservableMap map;
    List<ChangeRecord> changes;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      changes = null;
      map.changes.listen((records) {
        changes = records.where((r) => r.key == 'length' &&
            r.kind == ChangeRecord.FIELD).toList();
      });
    });

    _change(x, y) => _record('length', x, y);

    test('add item changes length', () {
      map['d'] = 4;
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangeRecords();
      expect(changes, [_change(3, 4)]);
    });

    test('putIfAbsent changes length', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangeRecords();
      expect(changes, [_change(3, 4)]);
    });

    test('remove changes length', () {
      map.remove('c');
      map.remove('a');
      expect(map, {'b': 2});
      deliverChangeRecords();
      expect(changes, [_change(3, 2), _change(2, 1)]);
    });

    test('remove non-existent item does not change length', () {
      map.remove('d');
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangeRecords();
      expect(changes, null);
    });

    test('set existing item does not change length', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      deliverChangeRecords();
      expect(changes, []);
    });

    test('clear changes length', () {
      map.clear();
      expect(map, {});
      deliverChangeRecords();
      expect(changes, [_change(3, 0)]);
    });
  });

  group('observe item', () {

    ObservableMap map;
    List<ChangeRecord> changes;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      changes = null;
      map.changes.listen((records) {
        changes = records.where((r) => r.key == 'b' &&
            (r.kind & ChangeRecord.INDEX) != 0).toList();
      });
    });

    _change(x, y, {kind: ChangeRecord.INDEX}) => _record('b', x, y, kind);

    test('putIfAbsent new item does not change existing item', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangeRecords();
      expect(changes, []);
    });

    test('set item to null', () {
      map['b'] = null;
      expect(map, {'a': 1, 'b': null, 'c': 3});
      deliverChangeRecords();
      expect(changes, [_change(2, null)]);
    });

    test('set item to value', () {
      map['b'] = 777;
      expect(map, {'a': 1, 'b': 777, 'c': 3});
      deliverChangeRecords();
      expect(changes, [_change(2, 777)]);
    });

    test('putIfAbsent does not change if already there', () {
      map.putIfAbsent('b', () => 1234);
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangeRecords();
      expect(changes, null);
    });

    test('change a different item', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      deliverChangeRecords();
      expect(changes, []);
    });

    test('change the item', () {
      map['b'] = 9001;
      map['b'] = 42;
      expect(map, {'a': 1, 'b': 42, 'c': 3});
      deliverChangeRecords();
      expect(changes, [_change(2, 9001), _change(9001, 42)]);
    });

    test('remove other items', () {
      map.remove('a');
      expect(map, {'b': 2, 'c': 3});
      deliverChangeRecords();
      expect(changes, []);
    });

    test('remove the item', () {
      map.remove('b');
      expect(map, {'a': 1, 'c': 3});
      deliverChangeRecords();
      expect(changes, [_change(2, null, kind: ChangeRecord.REMOVE)]);
    });

    test('remove and add back', () {
      map.remove('b');
      map['b'] = 2;
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangeRecords();
      expect(changes, [
        _change(2, null, kind: ChangeRecord.REMOVE),
        _change(null, 2, kind: ChangeRecord.INSERT)
      ]);
    });
  });

  test('toString', () {
    var map = toObservable({'a': 1, 'b': 2});
    expect(map.toString(), '{a: 1, b: 2}');
  });

  group('change records', () {
    List<ChangeRecord> records;
    ObservableMap map;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2});
      records = null;
      map.changes.first.then((r) { records = r; });
    });

    test('read operations', () {
      expect(map.length, 2);
      expect(map.isEmpty, false);
      expect(map['a'], 1);
      expect(map.containsKey(2), false);
      expect(map.containsValue(2), true);
      expect(map.containsKey('b'), true);
      expect(map.keys.toList(), ['a', 'b']);
      expect(map.values.toList(), [1, 2]);
      var copy = {};
      map.forEach((k, v) { copy[k] = v; });
      expect(copy, {'a': 1, 'b': 2});
      deliverChangeRecords();

      // no change from read-only operators
      expect(records, null);
    });

    test('putIfAbsent', () {
      map.putIfAbsent('a', () => 42);
      expect(map, {'a': 1, 'b': 2});

      map.putIfAbsent('c', () => 3);
      expect(map, {'a': 1, 'b': 2, 'c': 3});

      deliverChangeRecords();
      expect(records, [
        _record('length', 2, 3),
        _record('c', null, 3, ChangeRecord.INSERT),
      ]);
    });

    test('[]=', () {
      map['a'] = 42;
      expect(map, {'a': 42, 'b': 2});

      map['c'] = 3;
      expect(map, {'a': 42, 'b': 2, 'c': 3});

      deliverChangeRecords();
      expect(records, [
        _record('a', 1, 42, ChangeRecord.INDEX),
        _record('length', 2, 3),
        _record('c', null, 3, ChangeRecord.INSERT)
      ]);
    });

    test('remove', () {
      map.remove('b');
      expect(map, {'a': 1});

      deliverChangeRecords();
      expect(records, [
        _record('b',  2, null, ChangeRecord.REMOVE),
        _record('length', 2, 1),
      ]);
    });

    test('clear', () {
      map.clear();
      expect(map, {});

      deliverChangeRecords();
      expect(records, [
        _record('a',  1, null, ChangeRecord.REMOVE),
        _record('b',  2, null, ChangeRecord.REMOVE),
        _record('length', 2, 0),
      ]);
    });
  });
}

_record(key, oldValue, newValue, [kind = ChangeRecord.FIELD]) =>
    new ChangeRecord(key, oldValue, newValue, kind: kind);
