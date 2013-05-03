// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [HtmlDocument] API. */
class TextExtension extends NodeExtension {
  TextExtension(Text node) : super(node);

  Text get node => super.node;

  _Binding _textBinding;

  void bind(String name, model, String path) {
    if (name != 'text') {
      super.bind(name, model, path);
      return;
    }

    unbind('text');
    _textBinding = new _Binding(model, path, (value) { node.text = '$value'; });
  }

  void unbind(String name) {
    if (name != 'text') {
      super.unbind(name);
      return;
    }

    if (_textBinding == null) return;

    _textBinding.dispose();
    _textBinding = null;
  }

  void unbindAll() {
    unbind('text');
    super.unbindAll();
  }
}
