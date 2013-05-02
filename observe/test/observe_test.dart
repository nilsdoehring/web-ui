// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:observe/observe.dart';

main() {
  // Note: to test the basic Observable system, we use ObservableBox due to its
  // simplicity.

  group('ObservableBox', () {
    test('no observers', () {
      var t = new ObservableBox<int>(123);
      expect(t.value, 123);
      t.value = 42;
      expect(t.value, 42);
      expect(t.hasObservers, false);
    });

    test('listen adds an observer', () {
      var t = new ObservableBox<int>(123);
      expect(t.hasObservers, false);

      t.changes.listen((n) {});
      expect(t.hasObservers, true);
    });

    test('changes delived async', () {
      var t = new ObservableBox<int>(123);
      int called = 0;

      t.changes.listen(expectAsync1((records) {
        called++;
        expect(records, [_record('value', 123, 41), _record('value', 41, 42)]);
      }));
      t.value = 41;
      t.value = 42;
      expect(called, 0);
    });

    test('cause changes in handler', () {
      var t = new ObservableBox<int>(123);
      t.changes.listen(expectAsync1((records) {
        expect(records.length, 1);
        var record = records[0];
        if (record.oldValue == 123) {
          expect(record.newValue, 42);
          // Cause another change
          t.value = 777;
        } else {
          expect(record.oldValue, 42);
          expect(record.newValue, 777);
        }
      }, count: 2));

      t.value = 42;
    });

    test('multiple observers', () {
      var t = new ObservableBox<int>(123);

      verifyRecords(records) {
        expect(records, [_record('value', 123, 41), _record('value', 41, 42)]);
      };

      t.changes.listen(expectAsync1(verifyRecords));
      t.changes.listen(expectAsync1(verifyRecords));

      t.value = 41;
      t.value = 42;
    });

    test('deliverChangeRecords', () {
      var t = new ObservableBox<int>(123);
      var records = [];
      t.changes.listen((r) { records.addAll(r); });
      t.value = 41;
      t.value = 42;
      expect(records, [], reason: 'changes delived async');

      deliverChangeRecords();
      expect(records, [_record('value', 123, 41), _record('value', 41, 42)]);
      records.clear();

      t.value = 777;
      expect(records, [], reason: 'changes delived async');

      deliverChangeRecords();
      expect(records, [_record('value', 42, 777)]);

      // Has no effect if there are no changes
      deliverChangeRecords();
      expect(records, [_record('value', 42, 777)]);
    });

    test('cancel listening', () {
      var t = new ObservableBox<int>(123);
      var sub;
      sub = t.changes.listen(expectAsync1((records) {
        expect(records, [_record('value', 123, 42)]);
        sub.cancel();
        t.value = 777;
      }));
      t.value = 42;
    });
  });

  // We only really support equality on these for testing purposes.
  // However we need .hashCode because we've implemented operator ==.
  test('ChangeRecord.hashCode', () {
    var a = _record('a',  1, null, ChangeRecord.REMOVE);
    var b = _record('a',  1, null, ChangeRecord.REMOVE);
    var c = _record('b',  1, null, ChangeRecord.REMOVE);
    expect(a.hashCode, b.hashCode, reason: 'a == b');
    expect(b.hashCode, isNot(equals(c.hashCode)), reason: 'b != c');
  });
}

_record(key, oldValue, newValue, [kind = ChangeRecord.FIELD]) =>
    new ChangeRecord(key, oldValue, newValue, kind: kind);
