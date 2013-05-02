// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:observe/observe.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

main() {
  group('summarizeListChanges', listChangeTests);
}

// TODO(jmesserly): port or write array fuzzer tests
listChangeTests() {

  test('sequential adds', () {
    var model = toObservable([]);
    model.add(0);

    var summary;
    var sub = model.changes.listen((r) {
      summary = summarizeListChanges(model, r);
    });

    model.add(1);
    model.add(2);

    expect(summary, null);
    deliverChangeRecords();
    _checkSummary(summary, [_delta(1, [], 2)]);
  });

  test('List Splice Truncate And Expand With Length', () {
    var model = toObservable(['a', 'b', 'c', 'd', 'e']);

    var summary;
    var sub = model.changes.listen((r) {
      summary = summarizeListChanges(model, r);
    });

    model.length = 2;

    deliverChangeRecords();
    _checkSummary(summary, [_delta(2, ['c', 'd', 'e'], 0)]);
    summary = null;

    model.length = 5;

    deliverChangeRecords();
    _checkSummary(summary, [_delta(2, [], 3)]);
  });

  group('List deltas can be applied', () {

    var summary = null;

    observeArray(model) {
      model.changes.listen((records) {
        summary = summarizeListChanges(model, records);
      });
    }

    applyAndCheckDeltas(model, copy) {
      summary = null;
      deliverChangeRecords();

      // apply deltas to the copy
      for (var delta in summary) {
        for (int i = 0; i < delta.removed.length; i++) {
          copy.removeAt(delta.index);
        }
        for (int i = delta.addedCount - 1; i >= 0; i--) {
          copy.insert(delta.index, model[delta.index + i]);
        }
      }

      expect(copy, model);
    }

    test('Contained', () {
      var model = toObservable(['a', 'b']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(1);
      model.insertAll(0, ['c', 'd', 'e']);
      model.removeRange(1, 3);
      model.insert(1, 'f');

      applyAndCheckDeltas(model, copy);
    });

    test('Delete Empty', () {
      var model = toObservable([1]);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(0);
      model.insertAll(0, ['a', 'b', 'c']);

      applyAndCheckDeltas(model, copy);
    });

    test('Right Non Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(0, 1);
      model.insert(0, 'e');
      model.removeRange(2, 3);
      model.insertAll(2, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Left Non Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(3, 4);
      model.insertAll(3, ['f', 'g']);
      model.removeRange(0, 1);
      model.insert(0, 'e');

      applyAndCheckDeltas(model, copy);
    });

    test('Right Adjacent', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(1, 2);
      model.insert(3, 'e');
      model.removeRange(2, 3);
      model.insertAll(0, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Left Adjacent', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(2, 4);
      model.insert(2, 'e');

      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Right Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(1);
      model.insert(1, 'e');
      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Left Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']);
      // a b [e f g] d
      model.removeRange(1, 3);
      model.insertAll(1, ['h', 'i', 'j']);
      // a [h i j] f g d

      applyAndCheckDeltas(model, copy);
    });

    test('Prefix And Suffix One In', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.insert(0, 'z');
      model.add('z');

      applyAndCheckDeltas(model, copy);
    });

    test('Remove First', () {
      var model = toObservable([16, 15, 15]);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(0);

      applyAndCheckDeltas(model, copy);
    });

    test('Update Remove', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']);  // a b [e f g] d
      model[0] = 'h';
      model.removeAt(1);

      applyAndCheckDeltas(model, copy);
    });

    test('Remove Mid List', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(2);

      applyAndCheckDeltas(model, copy);
    });
  });

  group('edit distance', () {
    var summary = null;

    observeArray(model) {
      model.changes.listen((records) {
        summary = summarizeListChanges(model, records);
      });
    }

    assertEditDistance(orig, expectDistance) {
      summary = null;
      deliverChangeRecords();
      var actualDistance = 0;

      if (summary != null) {
        for (var delta in summary) {
          actualDistance += delta.addedCount + delta.removed.length;
        }
      }

      expect(actualDistance, expectDistance);
    }

    test('add items', () {
      var model = toObservable([]);
      observeArray(model);
      model.addAll([1, 2, 3]);
      assertEditDistance(model, 3);
    });

    test('trunacte and add, sharing a contiguous block', () {
      var model = toObservable(['x', 'x', 'x', 'x', '1', '2', '3']);
      observeArray(model);
      model.length = 0;
      model.addAll(['1', '2', '3', 'y', 'y', 'y', 'y']);
      assertEditDistance(model, 8);
    });

    test('truncate and add, sharing a discontiguous block', () {
      var model = toObservable(['1', '2', '3', '4', '5']);
      observeArray(model);
      model.length = 0;
      model.addAll(['a', '2', 'y', 'y', '4', '5', 'z', 'z']);
      assertEditDistance(model, 7);
    });

    test('insert at beginning and end', () {
      var model = toObservable([2, 3, 4]);
      observeArray(model);
      model.insert(0, 5);
      model[2] = 6;
      model.add(7);
      assertEditDistance(model, 4);
    });
  });
}

_delta(i, r, a) => new ListChangeDelta(i, removed: r, addedCount: a);

_checkSummary(List<ListChangeDelta> actual, List<ListChangeDelta> expected) {
  var msg = 'should be equal, actual: $actual expected: $expected';
  expect(actual.length, expected.length, reason: 'length $msg');
  for (var i = 0; i < actual.length; i++) {
    msg = 'should be equal at $i, actual: ${actual[i]} '
        'expected: ${expected[i]}';

    expect(actual[i].index, expected[i].index, reason: '.index $msg');
    expect(actual[i].removed, expected[i].removed, reason: '.removed $msg');
    expect(actual[i].addedCount, expected[i].addedCount,
        reason: '.addedCount $msg');
  }
}
