// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to [TemplateElement]s for MDV. */
class TemplateElementExtension extends TemplateExtension {

  TemplateElementExtension(TemplateElement node) : super(node);

  TemplateElement get node => super.node;

  // For real TemplateElement use the actual DOM .content field instead of
  // our polyfilled expando.
  DocumentFragment get content => node.content;
}
