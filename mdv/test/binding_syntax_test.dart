// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library binding_syntax_test;

import 'dart:async';
import 'dart:html';
import 'package:mdv/mdv.dart';
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/syntax.js

main() {
  useHtmlConfiguration();
  group('Syntax', syntaxTests);
}

syntaxTests() {
  var testDiv;

  setUp(() {
    document.body.nodes.add(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  createTestHtml(s) {
    var div = new DivElement();
    div.innerHtml = s;
    testDiv.nodes.add(div);

    for (var node in div.queryAll('*')) {
      if (mdv(node) is TemplateExtension) TemplateExtension.decorate(node);
    }

    return div;
  }

  recursivelySetTemplateModel(element, model) {
    for (var node in element.queryAll('*')) {
      if (mdv(node) is TemplateExtension) mdv(node).model = model;
    }
  }

  test('Registration', () {
    var model = toObservable({ 'foo': 'bar'});

    var testSyntax = new TestBindingSyntax();
    TemplateExtension.syntax['Test'] = testSyntax;

    var div = createTestHtml(
        '<template bind syntax="Test">{{ foo }}' +
        '<template bind>{{ foo }}</template></template>');
    recursivelySetTemplateModel(div, model);
    deliverChangeRecords();
    expect(div.nodes.length, 4);
    expect(div.nodes.last.text, 'bar');
    expect(div.nodes[2].tagName, 'TEMPLATE');
    expect(div.nodes[2].attributes['syntax'], 'Test');

    expect(testSyntax.log, [
      [model, 'foo', 'text', null],
      [model, '', 'bind', 'TEMPLATE'],
      [model, 'foo', 'text', null],
    ]);

    TemplateExtension.syntax.remove('Test');
  });

  test('Basic', () {
    var model = toObservable({ 'foo': 2, 'bar': 4 });

    TemplateExtension.syntax['2x'] = new TimesTwoSyntax();

    var div = createTestHtml(
        '<template bind syntax="2x">'
        '{{ foo }} + {{ 2x: bar }} + {{ 4x: bar }}</template>');
    recursivelySetTemplateModel(div, model);
    deliverChangeRecords();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, '2 + 8 + ');

    model['foo'] = 4;
    model['bar'] = 8;
    deliverChangeRecords();
    expect(div.nodes.last.text, '4 + 16 + ');

    TemplateExtension.syntax.remove('2x');
  });

  test('Different Sub-Template Syntax', () {
    var model = toObservable({'foo': 'bar'});

    TemplateExtension.syntax['Test'] = new TestBindingSyntax();
    TemplateExtension.syntax['Test2'] = new TestBindingSyntax();

    var div = createTestHtml(
        '<template bind syntax="Test">{{ foo }}'
        '<template bind syntax="Test2">{{ foo }}</template></template>');
    recursivelySetTemplateModel(div, model);
    deliverChangeRecords();
    expect(div.nodes.length, 4);
    expect(div.nodes.last.text, 'bar');
    expect(div.nodes[2].tagName, 'TEMPLATE');
    expect(div.nodes[2].attributes['syntax'], 'Test2');

    var testLog = TemplateExtension.syntax['Test'].log;
    var test2Log = TemplateExtension.syntax['Test2'].log;

    expect(testLog, [
      [model, 'foo', 'text', null],
      [model, '', 'bind', 'TEMPLATE']
    ]);

    expect(test2Log, [[model, 'foo', 'text', null]]);

    TemplateExtension.syntax.remove('Test');
    TemplateExtension.syntax.remove('Test2');
  });
}

class TestBindingSyntax extends CustomBindingSyntax {
  var log = [];

  getBinding(model, String path, String name, Node node) {
    log.add([model, path, name, node is Element ? node.tagName : null]);
  }
}

class TimesTwoSyntax extends CustomBindingSyntax {
  getBinding(model, path, name, node) {
    path = path.trim();
    if (!path.startsWith('2x:')) return null;

    path = path.substring(3);
    return new CompoundBinding((values) => values['value'] * 2)
        ..bind('value', model, path);
  }
}
