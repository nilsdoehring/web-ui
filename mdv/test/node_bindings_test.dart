// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library node_bindings_test;

import 'dart:async';
import 'dart:html';
import 'package:mdv/mdv.dart';
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/node_bindings.js

main() {
  useHtmlConfiguration();
  group('Node Bindings', nodeBindingTests);
}

nodeBindingTests() {
  var testDiv;

  setUp(() {
    document.body.nodes.add(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  dispatchEvent(type, target) {
    target.dispatchEvent(new Event(type, cancelable: false));
  }

  test('Text', () {
    var text = new Text('hi');
    var model = toObservable({'a': 1});
    mdv(text).bind('text', model, 'a');
    expect(text.text, '1');

    model['a'] = 2;
    deliverChangeRecords();
    expect(text.text, '2');

    mdv(text).unbind('text');
    model['a'] = 3;
    deliverChangeRecords();
    expect(text.text, '2');

    // TODO(rafaelw): Throw on binding to unavailable property?
  });

  test('Element', () {
    var element = new DivElement();
    var model = toObservable({'a': 1, 'b': 2});
    mdv(element).bind('hidden?', model, 'a');
    mdv(element).bind('id', model, 'b');

    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, '2');

    model['a'] = null;
    deliverChangeRecords();
    expect(element.attributes, isNot(contains('hidden')),
        reason: 'null is false-y');

    model['a'] = false;
    deliverChangeRecords();
    expect(element.attributes, isNot(contains('hidden')));

    model['a'] = 'foo';
    model['b'] = 'x';
    deliverChangeRecords();
    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, 'x');
  });

  test('Text Input', () {
    var input = new InputElement();
    var model = toObservable({'x': 42});
    mdv(input).bind('value', model, 'x');
    expect(input.value, '42');

    model['x'] = 'Hi';
    expect(input.value, '42', reason: 'changes delivered async');
    deliverChangeRecords();
    expect(input.value, 'Hi');

    input.value = 'changed';
    dispatchEvent('input', input);
    expect(model['x'], 'changed');

    mdv(input).unbind('value');

    input.value = 'changed again';
    dispatchEvent('input', input);
    expect(model['x'], 'changed');

    mdv(input).bind('value', model, 'x');
    model['x'] = null;
    deliverChangeRecords();
    expect(input.value, '');
  });

  test('Radio Input', () {
    var input = new InputElement();
    input.type = 'radio';
    var model = toObservable({'x': true});
    mdv(input).bind('checked', model, 'x');
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true);
    deliverChangeRecords();
    expect(input.checked, false, reason: 'model change should update checked');

    input.checked = true;
    dispatchEvent('change', input);
    expect(model['x'], true, reason: 'input.checked should set model');

    mdv(input).unbind('checked');

    input.checked = false;
    dispatchEvent('change', input);
    expect(model['x'], true, reason: 'disconnected binding should not fire');
  });

  test('Checkbox Input', () {
    var input = new InputElement();
    testDiv.nodes.add(input);
    input.type = 'checkbox';
    var model = toObservable({'x': true});
    mdv(input).bind('checked', model, 'x');
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true, reason: 'changes delivered async');
    deliverChangeRecords();
    expect(input.checked, false);

    input.click();
    expect(model['x'], true);
    deliverChangeRecords();

    input.click();
    expect(model['x'], false);
  });
}
