// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:observe/observe.dart';

main() {
  // TODO(jmesserly): need all standard List API tests.

  group('observe length', () {

    ObservableList list;
    List<ChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      list.changes.listen((records) {
        changes = records.where((r) => r.key == 'length' &&
            r.kind == ChangeRecord.FIELD).toList();
      });
    });

    _change(x, y) => _record('length', x, y);

    test('add changes length', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      deliverChangeRecords();
      expect(changes, [_change(3, 4)]);
    });

    test('removeRange changes length', () {
      list.add(4);
      list.removeRange(1, 3);
      expect(list, [1, 4]);
      deliverChangeRecords();
      expect(changes, [_change(3, 4), _change(4, 2)]);
    });

    test('length= changes length', () {
      list.length = 5;
      expect(list, [1, 2, 3, null, null]);
      deliverChangeRecords();
      expect(changes, [_change(3, 5)]);
    });

    test('[]= does not change length', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      deliverChangeRecords();
      expect(changes, []);
    });

    test('clear changes length', () {
      list.clear();
      expect(list, []);
      deliverChangeRecords();
      expect(changes, [_change(3, 0)]);
    });
  });

  group('observe index', () {
    ObservableList list;
    List<ChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      list.changes.listen((records) {
        changes = records.where((r) => r.key == 1 &&
            (r.kind & ChangeRecord.INDEX) != 0).toList();
      });
    });

    _change(x, y, [kind = ChangeRecord.INDEX]) => _record(1, x, y, kind);

    test('add does not change existing items', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      deliverChangeRecords();
      expect(changes, []);
    });

    test('[]= changes item', () {
      list[1] = 777;
      expect(list, [1, 777, 3]);
      deliverChangeRecords();
      expect(changes, [_change(2, 777)]);
    });

    test('[]= on a different item does not fire change', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      deliverChangeRecords();
      expect(changes, []);
    });

    test('set multiple times results in one change per set', () {
      list[1] = 777;
      list[1] = 42;
      expect(list, [1, 42, 3]);
      deliverChangeRecords();
      expect(changes, [_change(2, 777), _change(777, 42)]);
    });

    test('set length without truncating item means no change', () {
      list.length = 2;
      expect(list, [1, 2]);
      deliverChangeRecords();
      expect(changes, []);
    });

    test('truncate removes item', () {
      list.length = 1;
      expect(list, [1]);
      deliverChangeRecords();
      expect(changes, [_change(2, null, ChangeRecord.REMOVE)]);
    });

    test('truncate item and add back', () {
      list.length = 1;
      list.add(42);
      expect(list, [1, 42]);
      deliverChangeRecords();
      expect(changes, [
        _change(2, null, ChangeRecord.REMOVE),
        _change(null, 42, ChangeRecord.INSERT)
      ]);
    });

    test('truncate and add same item back', () {
      list.length = 1;
      list.add(2);
      expect(list, [1, 2]);
      deliverChangeRecords();
      expect(changes, [
        _change(2, null, ChangeRecord.REMOVE),
        _change(null, 2, ChangeRecord.INSERT)
      ]);
    });
  });

  test('toString', () {
    var list = toObservable([1, 2, 3]);
    expect(list.toString(), '[1, 2, 3]');
  });

  group('change records', () {

    List<ChangeRecord> records;
    ObservableList list;

    setUp(() {
      list = toObservable([1, 2, 3, 1, 3, 4]);
      records = null;
      list.changes.listen((r) { records = r; });
    });

    test('read operations', () {
      expect(list.length, 6);
      expect(list[0], 1);
      expect(list.indexOf(4), 5);
      expect(list.indexOf(1), 0);
      expect(list.indexOf(1, 1), 3);
      expect(list.lastIndexOf(1), 3);
      expect(list.last, 4);
      var copy = new List<int>();
      list.forEach((i) { copy.add(i); });
      expect(copy, orderedEquals([1, 2, 3, 1, 3, 4]));
      deliverChangeRecords();

      // no change from read-only operators
      expect(records, null);
    });

    test('add', () {
      list.add(5);
      list.add(6);
      expect(list, orderedEquals([1, 2, 3, 1, 3, 4, 5, 6]));

      deliverChangeRecords();
      expect(records, [
        _record('length', 6, 7),
        _record(6, null, 5, ChangeRecord.INSERT),
        _record('length', 7, 8),
        _record(7, null, 6, ChangeRecord.INSERT),
      ]);
    });

    test('[]=', () {
      list[1] = list.last;
      expect(list, orderedEquals([1, 4, 3, 1, 3, 4]));

      deliverChangeRecords();
      expect(records, [ _record(1, 2, 4, ChangeRecord.INDEX) ]);
    });

    test('removeLast', () {
      expect(list.removeLast(), 4);
      expect(list, orderedEquals([1, 2, 3, 1, 3]));

      deliverChangeRecords();
      expect(records, [
        _record(5,  4, null, ChangeRecord.REMOVE),
        _record('length', 6, 5),
      ]);
    });

    test('removeRange', () {
      list.removeRange(1, 4);
      expect(list, orderedEquals([1, 3, 4]));

      deliverChangeRecords();
      expect(records, [
        _record(1, 2, null, ChangeRecord.REMOVE),
        _record(2, 3, null, ChangeRecord.REMOVE),
        _record(3, 1, null, ChangeRecord.REMOVE),
        _record(1, 2, 3, ChangeRecord.INDEX),
        _record(2, 3, 4, ChangeRecord.INDEX),
        _record(5, 4, null, ChangeRecord.REMOVE),
        _record(4, 3, null, ChangeRecord.REMOVE),
        _record(3, 1, null, ChangeRecord.REMOVE),
        _record('length', 6, 3)
      ]);
    });

    test('sort', () {
      list.sort((x, y) => x - y);
      expect(list, orderedEquals([1, 1, 2, 3, 3, 4]));

      deliverChangeRecords();
      // TODO(jmesserly): this depends on implementation details of sort.
      expect(records, [
        _record(1, 2, 2, ChangeRecord.INDEX),
        _record(2, 3, 3, ChangeRecord.INDEX),
        _record(3, 1, 3, ChangeRecord.INDEX),
        _record(2, 3, 2, ChangeRecord.INDEX),
        _record(1, 2, 1, ChangeRecord.INDEX),
        _record(4, 3, 3, ChangeRecord.INDEX),
        _record(5, 4, 4, ChangeRecord.INDEX)
      ]);
    });

    test('clear', () {
      list.clear();
      expect(list, []);

      deliverChangeRecords();
      expect(records, [
        _record(5, 4, null, ChangeRecord.REMOVE),
        _record(4, 3, null, ChangeRecord.REMOVE),
        _record(3, 1, null, ChangeRecord.REMOVE),
        _record(2, 3, null, ChangeRecord.REMOVE),
        _record(1, 2, null, ChangeRecord.REMOVE),
        _record(0, 1, null, ChangeRecord.REMOVE),
        _record('length', 6, 0),
      ]);
    });
  });
}

_record(key, oldValue, newValue, [kind = ChangeRecord.FIELD]) =>
    new ChangeRecord(key, oldValue, newValue, kind: kind);
