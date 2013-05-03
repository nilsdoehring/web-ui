// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to [Element]s that behave as templates. */
class TemplateExtension extends ElementExtension {
  var _model;
  _TemplateIterator _templateIterator;
  Element _templateInstanceRef;
  // Note: only used if `this is! TemplateElement`
  DocumentFragment _templateContent;
  bool _templateIsDecorated;

  TemplateExtension(Element node) : super(node);

  // TODO(jmesserly): should path be optional, and default to empty path?
  // It is used that way in at least one path in JS TemplateElement tests
  // (see "BindImperative" test in original JS code).
  void bind(String name, model, String path) {
    switch (name) {
      case 'bind':
      case 'repeat':
      case 'if':
        _ensureTemplate();
        if (_templateIterator == null) {
          _templateIterator = new _TemplateIterator(node);
        }
        _templateIterator.inputs.bind(name, model, path);
        return;
      default:
        super.bind(name, model, path);
    }
  }

  void unbind(String name) {
    switch (name) {
      case 'bind':
      case 'repeat':
      case 'if':
        _ensureTemplate();
        if (_templateIterator != null) {
          _templateIterator.inputs.unbind(name);
        }
        return;
      default:
        super.unbind(name);
    }
  }

  void unbindAll() {
    unbind('bind');
    unbind('repeat');
    unbind('if');
    super.unbindAll();
  }

  /**
   * Gets the template this node refers to.
   */
  Element get ref {
    _ensureTemplate();

    Element ref = null;
    var refId = node.attributes['ref'];
    if (refId != null) {
      ref = document.getElementById(refId);
    }

    return ref != null ? ref : _templateInstanceRef;
  }

  /**
   * Gets the content of this template.
   */
  DocumentFragment get content {
    _ensureTemplate();
    return _templateContent;
  }

  /**
   * Creates an instance of the template.
   */
  DocumentFragment createInstance() {
    _ensureTemplate();

    var template = ref;
    if (template == null) template = node;

    var instance = _createDeepCloneAndDecorateTemplates(
        mdv(template).content, node.attributes['syntax']);

    if (_instanceCreated != null) {
      _instanceCreated.add(instance);
    }
    return instance;
  }

  /**
   * The data model which is inherited through the tree.
   *
   * Setting this will destructive propagate the value to all descendant nodes,
   * and reinstantiate all of the nodes expanded by this template.
   *
   * Currently this does not support propagation through Shadow DOMs.
   */
  get model => _model;

  void set model(value) {
    _ensureTemplate();

    _model = value;
    _addBindings(node, model);
  }

  void _ensureTemplate() {
    TemplateExtension.decorate(node);
  }

  // These static methods eventually belong on TemplateElement

  static StreamController<DocumentFragment> _instanceCreated;

  /**
   * *Warning*: This is an implementation helper for Model-Driven Views and
   * should not be used in your code.
   *
   * This event is fired whenever a template is instantiated via
   * [createInstance].
   */
  // TODO(rafaelw): This is a hack, and is neccesary for the polyfill
  // because custom elements are not upgraded during clone()
  static Stream<DocumentFragment> get instanceCreated {
    if (_instanceCreated == null) {
      _instanceCreated = new StreamController<DocumentFragment>();
    }
    return _instanceCreated.stream;
  }

  /**
   * Ensures proper API and content model for template elements.
   *
   * [instanceRef] can be used to set the [Element.ref] property of [template],
   * and use the ref's content will be used as source when createInstance() is
   * invoked.
   *
   * Returns true if this template was just decorated, or false if it was
   * already decorated.
   */
  static bool decorate(Element template, [Element instanceRef]) {
    // == true check because it starts as a null field.
    if (mdv(template)._templateIsDecorated == true) return false;

    mdv(template)._templateIsDecorated = true;

    _injectStylesheet();

    // Create content
    if (template is! TemplateElement) {
      var doc = _getTemplateContentsOwner(template.document);
      mdv(template)._templateContent = doc.createDocumentFragment();
    }

    if (instanceRef != null) {
      mdv(template)._templateInstanceRef = instanceRef;
      return true; // content is empty.
    }

    if (template is TemplateElement) {
      _bootstrapTemplatesRecursivelyFrom(template.content);
    } else {
      _liftNonNativeTemplateChildrenIntoContent(template);
    }

    return true;
  }

  /**
   * This used to decorate recursively all templates from a given node.
   *
   * By default [decorate] will be called on templates lazily when certain
   * properties such as [model] are accessed, but it can be run eagerly to
   * decorate an entire tree recursively.
   */
  // TODO(rafaelw): Review whether this is the right public API.
  static void bootstrap(Node content) {
    _bootstrapTemplatesRecursivelyFrom(content);
  }

  static bool _initStyles;

  static void _injectStylesheet() {
    if (_initStyles == true) return;
    _initStyles = true;

    var style = new StyleElement();
    style.text = r'''
template,
thead[template],
tbody[template],
tfoot[template],
th[template],
tr[template],
td[template],
caption[template],
colgroup[template],
col[template],
option[template] {
  display: none;
}''';
    document.head.append(style);
  }

  /**
   * A mapping of names to Custom Syntax objects. See [CustomBindingSyntax] for
   * more information.
   */
  static Map<String, CustomBindingSyntax> syntax = {};
}
