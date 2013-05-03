// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): more commentary here.
/**
 * This library provides access to Model-Driven-Views APIs on HTML elements.
 * More information can be found at: <https://github.com/toolkitchen/mdv>.
 */
library mdv;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math' as math;
import 'package:observe/observe.dart';

// TODO(jmesserly): use libraries instead of parts.
part 'src/bindings.dart';
part 'src/element.dart';
part 'src/html_document.dart';
part 'src/input_element.dart';
part 'src/node.dart';
part 'src/template.dart';
part 'src/template_element.dart';
part 'src/text.dart';

// TODO(jmesserly): we probably need dart:html to provide expandos to
// workaround O(N) lookup in the VM.

// The expando for storing our MDV wrappers.
//
// In general, we need state associated with the nodes. Rather than having a
// bunch of individual expandos, we keep one per node.
//
// Aside from the potentially helping performance, it also keeps things simpler
// if we decide to integrate it into the DOM later, and means less code needs to
// worry about expandos.
final Expando _mdv = new Expando('mdv');

mdv(node) {
  var wrapper = _mdv[node];
  if (wrapper != null) return wrapper;

  if (node is HtmlDocument) {
    wrapper = new HtmlDocumentExtension(node);
  } else if (node is InputElement) {
    wrapper = new InputElementExtension(node);
  } else if (node is TemplateElement) {
    wrapper = new TemplateElementExtension(node);
  } else if (node is Element) {
    if (_isTemplate(node)) {
      wrapper = new TemplateExtension(node);
    } else {
      wrapper = new ElementExtension(node);
    }
  } else if (node is Text) {
    wrapper = new TextExtension(node);
  } else if (node is Node) {
    wrapper = new NodeExtension(node);
  } else {
    // TODO(jmesserly): this happens for things like CompountBinding.
    return node;
  }

  _mdv[node] = wrapper;
  return wrapper;
}


// TODO(jmesserly): const set would be better
const _TABLE_TAGS = const {
  'caption': null,
  'col': null,
  'colgroup': null,
  'tbody': null,
  'td': null,
  'tfoot': null,
  'th': null,
  'thead': null,
  'tr': null,
};

bool _isAttributeTemplate(Element node) =>
    node.attributes.containsKey('template') &&
    (node.localName == 'option' || _TABLE_TAGS.containsKey(node.localName));

/**
 * Returns true if this node is a template.
 *
 * A node is a template if [tagName] is TEMPLATE, or the node has the
 * 'template' attribute and this tag supports attribute form for backwards
 * compatibility with existing HTML parsers. The nodes that can use attribute
 * form are table elments (THEAD, TBODY, TFOOT, TH, TR, TD, CAPTION, COLGROUP
 * and COL) and OPTION.
 */
bool _isTemplate(Node node) {
  return node is Element &&
      (node.tagName == 'TEMPLATE' || _isAttributeTemplate(node));
}
