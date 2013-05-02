// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library html_cleaner_test;

import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/src/html_cleaner.dart';
import 'package:web_ui/src/info.dart';
import 'package:web_ui/src/files.dart';
import 'package:web_ui/src/messages.dart';
import 'testing.dart';

main() {
  useCompactVMConfiguration();
  test('remove attributes with data bindings (1)', () {
    // Note: we use an id in all these tests so that the analyzer will not
    // inject one for us.
    var elem = parseSubtree('<div foo="{{bar}}" id="a"></div>');
    var info = analyzeElement(elem, new Messages.silent());
    expect(elem.outerHtml, '<div foo="{{bar}}" id="a"></div>');
    cleanHtmlNodes(info);
    expect(elem.outerHtml, '<div id="a"></div>');
  });

  test('remove attributes with data bindings (2)', () {
    var elem = parseSubtree('<div foo="{{bar}} baz" id="a"></div>');
    var info = analyzeElement(elem, new Messages.silent());
    expect(elem.outerHtml, '<div foo="{{bar}} baz" id="a"></div>');
    cleanHtmlNodes(info);
    expect(elem.outerHtml, '<div id="a"></div>');
  });

  test('preserve attributes with no data bindings', () {
    var elem = parseSubtree('<div foo="baz" id="a"></div>');
    var info = analyzeElement(elem, new Messages.silent());
    expect(elem.outerHtml, '<div foo="baz" id="a"></div>');
    cleanHtmlNodes(info);
    expect(elem.outerHtml, '<div foo="baz" id="a"></div>');
  });

  test("don't remove node for content with data bindings", () {
    var input = '<div id="a">hi {{x}} friend</div>';
    var elem = parseSubtree(input);
    var info = analyzeElement(elem, new Messages.silent());
    expect(elem.outerHtml, input);
    expect(elem.nodes.length, 1);
    expect(elem.nodes[0].value, 'hi {{x}} friend');
    cleanHtmlNodes(info);
    expect(elem.outerHtml, '<div id="a"></div>');
    expect(elem.nodes.length, 0);
  });

  test('hide template nodes and remove their children', () {
    var input = '<div><template id="a" iterate="x in y">'
      '<div></div></template></div>';
    var elem = parseSubtree(input);
    var info = analyzeElement(elem, new Messages.silent());
    expect(elem.outerHtml, input);
    cleanHtmlNodes(info);
    expect(elem.outerHtml,
        '<div><template id="a"></template></div>');
  });

  test('remove children of iterate nodes', () {
    var input = '<div template="" id="a" iterate="x in y"><div></div></div>';
    var elem = parseSubtree(input);
    var info = analyzeElement(elem, new Messages.silent());
    expect(elem.outerHtml, input);
    cleanHtmlNodes(info);
    expect(elem.outerHtml, '<div id="a"></div>');
  });

  test('remove element declarations', () {
    var input = '<html><head></head><body>'
      '<element name="x-foo" constructor="Foo"></element>'
      '<element name="x-bar" constructor="Bar42"></element>'
      '</body></html>';
    var doc = parse(input);
    var file = new SourceFile('main.html')..document = doc;
    var info = analyzeFiles([file])['main.html'];
    expect(doc.outerHtml, input);
    cleanHtmlNodes(info);
    expect(doc.outerHtml, '<html><head></head><body></body></html>');
  });
}
