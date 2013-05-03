// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [HtmlDocument] API. */
class HtmlDocumentExtension extends NodeExtension {
  HtmlDocumentExtension(HtmlDocument node) : super(node);

  HtmlDocument get node => super.node;

  // Note: used to polyfill <template>
  HtmlDocument _templateContentsOwner;
}
