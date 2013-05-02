// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:observe/observe.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

main() {
  group('observePath', observePathTests);
}

observePathTests() {

  test('Degenerate Values', () {
    expect(observePath(null, '').value, null);
    expect(observePath(123, '').value, 123);
    expect(observePath(123, 'foo.bar.baz').value, null);

    // shouldn't throw:
    observePath(123, '').values.listen(() {}).cancel();
    observePath(null, '').value = null;
    observePath(123, '').value = 42;
    observePath(123, 'foo.bar.baz').value = 42;

    var foo = {};
    expect(observePath(foo, '').value, foo);

    foo = new Object();
    expect(observePath(foo, '').value, foo);

    expect(observePath(foo, 'a/3!'), null);
  });

  test('get value at path ObservableBox', () {
    var obj = new ObservableBox(new ObservableBox(new ObservableBox(1)));

    expect(observePath(obj, '').value, obj);
    expect(observePath(obj, 'value').value, obj.value);
    expect(observePath(obj, 'value.value').value, obj.value.value);
    expect(observePath(obj, 'value.value.value').value, 1);

    obj.value.value.value = 2;
    expect(observePath(obj, 'value.value.value').value, 2);

    obj.value.value = new ObservableBox(3);
    expect(observePath(obj, 'value.value.value').value, 3);

    obj.value = new ObservableBox(4);
    expect(observePath(obj, 'value.value.value').value, null);
    expect(observePath(obj, 'value.value').value, 4);
  });


  test('get value at path ObservableMap', () {
    var obj = toObservable({'a': {'b': {'c': 1}}});

    expect(observePath(obj, '').value, obj);
    expect(observePath(obj, 'a').value, obj['a']);
    expect(observePath(obj, 'a.b').value, obj['a']['b']);
    expect(observePath(obj, 'a.b.c').value, 1);

    obj['a']['b']['c'] = 2;
    expect(observePath(obj, 'a.b.c').value, 2);

    obj['a']['b'] = toObservable({'c': 3});
    expect(observePath(obj, 'a.b.c').value, 3);

    obj['a'] = toObservable({'b': 4});
    expect(observePath(obj, 'a.b.c').value, null);
    expect(observePath(obj, 'a.b').value, 4);
  });

  test('set value at path', () {
    var obj = toObservable({});
    observePath(obj, 'foo').value = 3;
    expect(obj['foo'], 3);

    var bar = toObservable({ 'baz': 3 });
    observePath(obj, 'bar').value = bar;
    expect(obj['bar'], bar);

    observePath(obj, 'bar.baz.bat').value = 'not here';
    expect(observePath(obj, 'bar.baz.bat').value, null);
  });

  test('set value back to same', () {
    var obj = toObservable({});
    var path = observePath(obj, 'foo');
    var values = [];
    path.values.listen((v) { values.add(v); });

    path.value = 3;
    expect(obj['foo'], 3);
    expect(path.value, 3);

    observePath(obj, 'foo').value = 2;
    deliverChangeRecords();
    expect(path.value, 2);
    expect(observePath(obj, 'foo').value, 2);

    observePath(obj, 'foo').value = 3;
    deliverChangeRecords();
    expect(path.value, 3);

    deliverChangeRecords();
    expect(values, [2, 3]);
  });

  test('Observe and Unobserve - Paths', () {
    var arr = toObservable({});

    arr['foo'] = 'bar';
    var fooValues = [];
    var fooPath = observePath(arr, 'foo');
    var fooSub = fooPath.values.listen((v) {
      fooValues.add(v);
    });
    arr['foo'] = 'baz';
    arr['bat'] = 'bag';
    var batValues = [];
    var batPath = observePath(arr, 'bat');
    var batSub = batPath.values.listen((v) {
      batValues.add(v);
    });

    deliverChangeRecords();
    expect(fooValues, ['baz']);
    expect(batValues, []);

    arr['foo'] = 'bar';
    fooSub.cancel();
    arr['bat'] = 'boo';
    batSub.cancel();
    arr['bat'] = 'boot';

    deliverChangeRecords();
    expect(fooValues, ['baz']);
    expect(batValues, []);
  });

  test('Path Value With Indices', () {
    var model = toObservable([]);
    observePath(model, '0').values.listen(expectAsync1((v) {
      expect(v, 123);
    }));
    model.add(123);
  });

  test('Path Observation', () {
    var model = new TestModel('a', new TestModel('b',
        new TestModel('c', 'hello, world')));

    var path = observePath(model, 'a.b.c');
    var lastValue = null;
    var sub = path.values.listen((v) { lastValue = v; });

    model.value.value.value = 'hello, mom';

    expect(lastValue, null);
    deliverChangeRecords();
    expect(lastValue, 'hello, mom');

    model.value.value = new TestModel('c', 'hello, dad');
    deliverChangeRecords();
    expect(lastValue, 'hello, dad');

    model.value = new TestModel('b', new TestModel('c', 'hello, you'));
    deliverChangeRecords();
    expect(lastValue, 'hello, you');

    model.value.value = 1;
    deliverChangeRecords();
    expect(lastValue, null);

    // Stop observing
    sub.cancel();

    model.value.value = new TestModel('c',
        'hello, back again -- but not observing');
    deliverChangeRecords();
    expect(lastValue, null);

    // Resume observing
    sub = path.values.listen((v) { lastValue = v; });

    model.value.value.value = 'hello. Back for reals';
    deliverChangeRecords();
    expect(lastValue, 'hello. Back for reals');
  });

  test('observe map', () {
    var model = toObservable({'a': 1});
    var path = observePath(model, 'a');

    var values = [path.value];
    var sub = path.values.listen((v) { values.add(v); });
    expect(values, [1]);

    model['a'] = 2;
    deliverChangeRecords();
    expect(values, [1, 2]);

    sub.cancel();
    model['a'] = 3;
    deliverChangeRecords();
    expect(values, [1, 2]);
  });
}

class TestModel extends ObservableMixin {
  final String fieldName;
  var _value;

  TestModel(this.fieldName, [initialValue]) : _value = initialValue;

  get value => _value;

  void set value(newValue) {
    if (hasObservers) {
      notifyChange(fieldName, _value, newValue);
    }
    _value = newValue;
  }

  getValue(key) {
    if (key == fieldName) return value;
    return null;
  }
  void setValue(key, newValue) {
    if (key == fieldName) value = newValue;
  }

  toString() => '#<$runtimeType $fieldName: $_value>';
}

_record(key, oldValue, newValue, [kind = ChangeRecord.FIELD]) =>
    new ChangeRecord(key, oldValue, newValue, kind: kind);
