// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Element] API. */
class ElementExtension extends NodeExtension {
  ElementExtension(Element node) : super(node);

  Element get node => super.node;

  Map<String, _Binding> _attributeBindings;

  // TODO(jmesserly): should path be optional, and default to empty path?
  // It is used that way in at least one path in JS TemplateElement tests
  // (see "BindImperative" test in original JS code).
  void bind(String name, model, String path) {
    if (_attributeBindings == null) {
      _attributeBindings = new Map<String, _Binding>();
    }

    node.attributes.remove(name);

    _ChangeHandler changed;
    if (name.endsWith('?')) {
      name = name.substring(0, name.length - 1);

      changed = (value) {
        if (_templateBooleanConversion(value)) {
          node.attributes[name] = '';
        } else {
          node.attributes.remove(name);
        }
      };
    } else {
      changed = (value) {
        // TODO(jmesserly): escape value if needed to protect against XSS.
        node.attributes[name] = value == null ? '' : '$value';
      };
    }

    unbind(name);

    _attributeBindings[name] = new _Binding(model, path, changed);
  }

  void unbind(String name) {
    if (_attributeBindings != null) {
      var binding = _attributeBindings.remove(name);
      if (binding != null) binding.dispose();
    }
  }

  void unbindAll() {
    if (_attributeBindings != null) {
      for (var binding in _attributeBindings.values) {
        binding.dispose();
      }
      _attributeBindings = null;
    }
  }
}
