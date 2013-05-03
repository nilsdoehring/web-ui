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
// https://github.com/toolkitchen/mdv/blob/master/tests/element_bindings.js

main() {
  useHtmlConfiguration();
  group('Element Bindings', elementBindingTests);
}

elementBindingTests() {
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
    var template = new Element.html('<template bind>{{a}} and {{b}}');
    testDiv.nodes.add(template);
    var model = toObservable({'a': 1, 'b': 2});
    mdv(template).model = model;
    deliverChangeRecords();
    var text = testDiv.nodes[1];
    expect(text.text, '1 and 2');

    model['a'] = 3;
    deliverChangeRecords();
    expect(text.text, '3 and 2');
  });

  test('SimpleBinding', () {
    var el = new DivElement();
    var model = toObservable({'a': '1'});
    mdv(el).bind('foo', model, 'a');
    deliverChangeRecords();
    expect(el.attributes['foo'], '1');

    model['a'] = '2';
    deliverChangeRecords();
    expect(el.attributes['foo'], '2');

    model['a'] = 232.2;
    deliverChangeRecords();
    expect(el.attributes['foo'], '232.2');

    model['a'] = 232;
    deliverChangeRecords();
    expect(el.attributes['foo'], '232');

    model['a'] = null;
    deliverChangeRecords();
    expect(el.attributes['foo'], '');
  });

  test('SimpleBindingWithDashes', () {
    var el = new DivElement();
    var model = toObservable({'a': '1'});
    mdv(el).bind('foo-bar', model, 'a');
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '1');

    model['a'] = '2';
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '2');
  });

  test('SimpleBindingWithComment', () {
    var el = new DivElement();
    el.innerHtml = '<!-- Comment -->';
    var model = toObservable({'a': '1'});
    mdv(el).bind('foo-bar', model, 'a');
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '1');

    model['a'] = '2';
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '2');
  });

  test('PlaceHolderBindingText', () {
    var model = toObservable({
      'adj': 'cruel',
      'noun': 'world'
    });

    var el = new DivElement();
    el.text = 'dummy';
    el.nodes.first.text = 'Hello {{ adj }} {{noun}}!';
    var template = new Element.html('<template bind>');
    template.content.nodes.add(el);
    testDiv.nodes.add(template);
    mdv(template).model = model;

    deliverChangeRecords();
    el = testDiv.nodes[1].nodes.first;
    expect(el.text, 'Hello cruel world!');

    model['adj'] = 'happy';
    deliverChangeRecords();
    expect(el.text, 'Hello happy world!');
  });

  test('InputElementTextBinding', () {
    var model = toObservable({'val': 'ping'});

    var el = new InputElement();
    mdv(el).bind('value', model, 'val');
    deliverChangeRecords();
    expect(el.value, 'ping');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(model['val'], 'pong');

    // Try a deep path.
    model = toObservable({'a': {'b': {'c': 'ping'}}});

    mdv(el).bind('value', model, 'a.b.c');
    deliverChangeRecords();
    expect(el.value, 'ping');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(observePath(model, 'a.b.c').value, 'pong');

    // Start with the model property being absent.
    model['a']['b'].remove('c');
    deliverChangeRecords();
    expect(el.value, '');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(observePath(model, 'a.b.c').value, 'pong');
    deliverChangeRecords();

    // Model property unreachable (and unsettable).
    model['a'].remove('b');
    deliverChangeRecords();
    expect(el.value, '');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(observePath(model, 'a.b.c').value, null);
  });

  test('InputElementCheckbox', () {
    var model = toObservable({'val': true});

    var el = new InputElement();
    testDiv.nodes.add(el);
    el.type = 'checkbox';
    mdv(el).bind('checked', model, 'val');
    deliverChangeRecords();
    expect(el.checked, true);

    model['val'] = false;
    deliverChangeRecords();
    expect(el.checked, false);

    el.click();
    expect(model['val'], true);

    el.click();
    expect(model['val'], false);
  });

  test('InputElementRadio', () {
    var model = toObservable({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var container = testDiv;

    var el1 = new InputElement();
    testDiv.nodes.add(el1);
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    mdv(el1).bind('checked', model, 'val1');

    var el2 = new InputElement();
    testDiv.nodes.add(el2);
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    mdv(el2).bind('checked', model, 'val2');

    var el3 = new InputElement();
    testDiv.nodes.add(el3);
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    mdv(el3).bind('checked', model, 'val3');

    var el4 = new InputElement();
    testDiv.nodes.add(el4);
    el4.type = 'radio';
    el4.name = 'othergroup';
    mdv(el4).bind('checked', model, 'val4');

    deliverChangeRecords();
    expect(el1.checked, true);
    expect(el2.checked, false);
    expect(el3.checked, false);
    expect(el4.checked, true);

    model['val1'] = false;
    model['val2'] = true;
    deliverChangeRecords();
    expect(el1.checked, false);
    expect(el2.checked, true);
    expect(el3.checked, false);
    expect(el4.checked, true);

    el1.checked = true;
    dispatchEvent('change', el1);
    expect(model['val1'], true);
    expect(model['val2'], false);
    expect(model['val3'], false);
    expect(model['val4'], true);

    el3.checked = true;
    dispatchEvent('change', el3);
    expect(model['val1'], false);
    expect(model['val2'], false);
    expect(model['val3'], true);
    expect(model['val4'], true);
  });

  test('InputElementRadioMultipleForms', () {
    var model = toObservable({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var form1 = new FormElement();
    testDiv.nodes.add(form1);
    var form2 = new FormElement();
    testDiv.nodes.add(form2);

    var el1 = new InputElement();
    form1.nodes.add(el1);
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    mdv(el1).bind('checked', model, 'val1');

    var el2 = new InputElement();
    form1.nodes.add(el2);
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    mdv(el2).bind('checked', model, 'val2');

    var el3 = new InputElement();
    form2.nodes.add(el3);
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    mdv(el3).bind('checked', model, 'val3');

    var el4 = new InputElement();
    form2.nodes.add(el4);
    el4.type = 'radio';
    el4.name = RADIO_GROUP_NAME;
    mdv(el4).bind('checked', model, 'val4');

    deliverChangeRecords();
    expect(el1.checked, true);
    expect(el2.checked, false);
    expect(el3.checked, false);
    expect(el4.checked, true);

    el2.checked = true;
    dispatchEvent('change', el2);
    expect(model['val1'], false);
    expect(model['val2'], true);

    // Radio buttons in form2 should be unaffected
    expect(model['val3'], false);
    expect(model['val4'], true);

    el3.checked = true;
    dispatchEvent('change', el3);
    expect(model['val3'], true);
    expect(model['val4'], false);

    // Radio buttons in form1 should be unaffected
    expect(model['val1'], false);
    expect(model['val2'], true);
  });

  test('BindToChecked', () {
    var div = new DivElement();
    testDiv.nodes.add(div);
    var child = new DivElement();
    div.nodes.add(child);
    var input = new InputElement();
    child.nodes.add(input);
    input.type = 'checkbox';

    var model = toObservable({'a': {'b': false}});
    mdv(input).bind('checked', model, 'a.b');

    input.click();
    expect(model['a']['b'], true);

    input.click();
    expect(model['a']['b'], false);
  });

  test('MultipleReferences', () {
    var el = new DivElement();
    var template = new Element.html('<template bind>');
    template.content.nodes.add(el);
    testDiv.nodes.add(template);

    var model = toObservable({'foo': 'bar'});
    el.attributes['foo'] = '{{foo}} {{foo}}';
    mdv(template).model = model;

    deliverChangeRecords();
    el = testDiv.nodes[1];
    expect(el.attributes['foo'], 'bar bar');
  });
}
