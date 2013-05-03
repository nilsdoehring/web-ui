// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [Node] API. */
class NodeExtension {
  final Node node;

  NodeExtension(this.node);

  /**
   * Binds the attribute [name] to the [path] of the [model].
   * Path is a String of accessors such as `foo.bar.baz`.
   */
  void bind(String name, model, String path) {
    // TODO(jmesserly): should we throw instead?
    window.console.error('Unhandled binding to Node: '
        '$this $name $model $path');
  }

  /** Unbinds the attribute [name]. */
  void unbind(String name) {}

  /** Unbinds all bound attributes. */
  void unbindAll() {}

  TemplateInstance _templateInstance;

  int __instanceTerminatorCount;
  int get _instanceTerminatorCount {
    if (__instanceTerminatorCount == null) return 0;
    return __instanceTerminatorCount;
  }
  set _instanceTerminatorCount(int value) {
    if (value == 0) value = null;
    __instanceTerminatorCount = value;
  }

  /** Gets the template instance that instantiated this node, if any. */
  TemplateInstance get templateInstance =>
      _templateInstance != null ? _templateInstance :
      (node.parent != null ? mdv(node.parent).templateInstance : null);
}
