// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.observe;

// This code is inspired by ChangeSummary:
// https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js
// ...which underlies MDV. Since we don't need the functionality of
// ChangeSummary, we just implement [observePath] and the ability to get/set
// a value on an observed path. This allows our implementation to be much
// simpler.

// TODO(jmesserly): should we make these types stronger, and require
// Observable objects? Currently, it is fine to say something like:
//     var path = observePath(123, '');
//     print(path.value); // "123"
//
// Furthermore this degenerate case is allowed:
//     var path = observePath(123, 'foo.bar.baz.qux');
//     print(path.value); // "null"
//
// Here we see that any invalid (i.e. not Observable) value will break the
// path chain without producing an error or exception.
//
// Now the real question: should we do this? For the former case, the behavior
// is correct but we could chose to handle it in the dart:html bindings layer.
// For the latter case, it might be better to throw an error so users can find
// the problem.

/**
 * Observes [path] on [object] for changes. If parsing was successful, returns
 * an object that can be used to get the changes and get/set the value at this
 * path. See [PathObserver.values] and [PathObserver.value].
 */
 PathObserver observePath(object, String path) {
  if (!_isPathValid(path)) return null;

  var segments = [];
  for (var segment in path.trim().split('.')) {
    if (segment == '') continue;
    var index = int.parse(segment, onError: (_) {});
    segments.add(index != null ? index : segment);
  }

  // TODO(jmesserly): if the path is empty, or the object is! Observable, we
  // can optimize the PathObserver to be more lightweight.

  // TODO(jmesserly): freeze segments list.
  return new PathObserver._(object, segments);
}

// TODO(jmesserly): the primary reason to have this object exposed is because
// we have get/set for value. Ideally "observePath" could just return the
// stream.
/**
 * A data path on an object, which can be observed. For example: `foo.bar.baz`.
 * This object is returned by [observePath].
 */
class PathObserver {
  /** The object being observed. */
  final object;

  /**
   * The path segments. This will be a list of strings or integers.
   */
  final List path;

  // TODO(jmesserly): same issue here as ObservableMixin: is there an easier
  // way to get a broadcast stream?
  StreamController _values;
  Stream _valueStream;

  _PropertyObserver _observer, _lastObserver;

  Object _lastValue;
  bool _scheduled = false;

  PathObserver._(this.object, this.path) {
    _values = new StreamController(onListen: _observe, onCancel: _unobserve);
    _valueStream = _values.stream.asBroadcastStream();

    // Create the property observer linked list.
    // Note that the structure of a path can't change after it is initially
    // constructed, even though the objects along the path can change.
    for (int i = path.length - 1; i >= 0; i--) {
      _observer = new _PropertyObserver(this, path[i], _observer);
      if (_lastObserver == null) _lastObserver = _observer;
    }
  }

  // TODO(jmesserly): use broadcast stream here. Need to check how it handles
  // onListen/onCancel.
  // TODO(jmesserly): should this be a change record with the old value?
  /**
   * Gets the values that were observed at this path.
   * These are delivered asynchronously during [deliverChangeRecords].
   */
  Stream get values => _valueStream;

  /** Force synchronous delivery of [values]. */
  void _deliverValues() {
    _scheduled = false;

    var newValue = value;
    if (!identical(_lastValue, newValue)) {
      _values.add(newValue);
      _lastValue = newValue;
    }
  }

  void _observe() {
    if (_observer != null) {
      _lastValue = value;
      _observer.observe();
    }
  }

  void _unobserve() {
    if (_observer != null) _observer.unobserve();
  }

  void _notifyChange() {
    if (_scheduled) return;
    _scheduled = true;

    // TODO(jmesserly): should we have a guarenteed order with respect to other
    // paths? If so, we could implement this fairly easily by sorting instances
    // of this class by birth order before delivery.
    queueChangeRecords(_deliverValues);
  }

  /** Gets the last reported value at this path. */
  get value {
    if (path.length == 0) return object;
    _observer.ensureValue(object);
    return _lastObserver.value;
  }

  /** Sets the value at this path. */
  void set value(Object value) {
    // TODO(jmesserly): throw if property cannot be set?
    // MDV seems tolerant of these error.
    if (path.length == 0) return;
    _observer.ensureValue(object);
    var last = _lastObserver;
    if (_setObjectProperty(last._object, last._property, value)) {
      // Technically, this would get updated asynchronously via a change record.
      // However, it is nice if calling the getter will yield the same value
      // that was just set. So we use this opportunity to update our cache.
      last.value = value;
    }
  }
}

// TODO(jmesserly): these should go away in favor of mirrors!
_getObjectProperty(object, property) {
  if (object is List && property is int) {
    if (property >= 0 && property < object.length) {
      return object[property];
    } else {
      return null;
    }
  }

  // TODO(jmesserly): what about length?
  if (object is Map) return object[property];

  if (object is Observable) return object.getValue(property);

  return null;
}

bool _setObjectProperty(object, property, value) {
  if (object is List && property is int) {
    object[property] = value;
  } else if (object is Map) {
    object[property] = value;
  } else if (object is Observable) {
    (object as Observable).setValue(property, value);
  } else {
    return false;
  }
  return true;
}


class _PropertyObserver {
  final PathObserver _path;
  final _property;
  final _PropertyObserver _next;

  // TODO(jmesserly): would be nice not to store both of these.
  Object _object;
  Object _value;
  StreamSubscription _sub;

  _PropertyObserver(this._path, this._property, this._next);

  get value => _value;

  void set value(Object newValue) {
    _value = newValue;
    if (_next != null) {
      if (_sub != null) _next.unobserve();
      _next.ensureValue(_value);
      if (_sub != null) _next.observe();
    }
  }

  void ensureValue(object) {
    // If we're observing, values should be up to date already.
    if (_sub != null) return;

    _object = object;
    value = _getObjectProperty(object, _property);
  }

  void observe() {
    if (_object is Observable) {
      assert(_sub == null);
      _sub = (_object as Observable).changes.listen(_onChange);
    }
    if (_next != null) _next.observe();
  }

  void unobserve() {
    if (_sub == null) return;

    _sub.cancel();
    _sub = null;
    if (_next != null) _next.unobserve();
  }

  void _onChange(List<ChangeRecord> changes) {
    for (var change in changes.reversed) {
      if (_property == change.key) {
        value = change.newValue;
        _path._notifyChange();
        return;
      }
    }
  }
}

// From: https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js

const _pathIndentPart = r'[$a-z0-9_]+[$a-z0-9_\d]*';
final _pathRegExp = new RegExp('^'
    '(?:#?' + _pathIndentPart + ')?'
    '(?:'
      '(?:\\.' + _pathIndentPart + ')'
    ')*'
    r'$', caseSensitive: false);

final _spacesRegExp = new RegExp('\\s');

bool _isPathValid(String s) {
  s = s.replaceAll(_spacesRegExp, '');

  if (s == '') return true;
  if (s[0] == '.') return false;
  return _pathRegExp.hasMatch(s);
}
