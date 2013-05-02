// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.observe;

// TODO(jmesserly): this needs to be faster. We currently require multiple
// lookups per key to get the old value.
// TODO(jmesserly): this doesn't implement the precise interfaces like
// LinkedHashMap, SplayTreeMap or HashMap. However it can use them for the
// backing store.

/**
 * Represents an observable map of model values. If any items are added,
 * removed, or replaced, then observers that are listening to [changes]
 * will be notified.
 */
class ObservableMap<K, V> extends ObservableMixin implements Map<K, V> {
  final Map<K, V> _map;

  /** Creates an observable map. */
  ObservableMap() : _map = new HashMap<K, V>();

  /** Creates a new observable map using a [LinkedHashMap]. */
  ObservableMap.linked() : _map = new LinkedHashMap<K, V>();

  /** Creates a new observable map using a [SplayTreeMap]. */
  ObservableMap.sorted() : _map = new SplayTreeMap<K, V>();

  /**
   * Creates an observable map that contains all key value pairs of [other].
   * It will attempt to use the same backing map type if the other map is a
   * [LinkedHashMap], [SplayTreeMap], or [HashMap]. Otherwise it defaults to
   * [HashMap].
   *
   * Note this will perform a shallow conversion. If you want a deep conversion
   * you should use [toObservable].
   */
  factory ObservableMap.from(Map<K, V> other) {
    var result = new ObservableMap<K, V>._createFromType(other);
    other.forEach((K key, V value) { result[key] = value; });
    return result;
  }

  factory ObservableMap._createFromType(Map<K, V> other) {
    ObservableMap result;
    if (other is SplayTreeMap) {
      result = new ObservableMap<K, V>.sorted();
    } else if (other is LinkedHashMap) {
      result = new ObservableMap<K, V>.linked();
    } else {
      result = new ObservableMap<K, V>();
    }
    return result;
  }

  Iterable<K> get keys => _map.keys;

  Iterable<V> get values => _map.values;

  int get length =>_map.length;

  bool get isEmpty => length == 0;

  bool containsValue(V value) => _map.containsValue(value);

  bool containsKey(K key) => _map.containsKey(key);

  V operator [](K key) => _map[key];

  void operator []=(K key, V value) {
    int len = _map.length;
    V oldValue = _map[key];
    _map[key] = value;
    if (hasObservers) {
      if (len != _map.length) {
        notifyChange('length', len, _map.length);
        notifyChange(key, oldValue, value, kind: ChangeRecord.INSERT);
      } else if (oldValue != value) {
        notifyChange(key, oldValue, value, kind: ChangeRecord.INDEX);
      }
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int len = _map.length;
    V result = _map.putIfAbsent(key, ifAbsent);
    if (hasObservers && len != _map.length) {
      notifyChange('length', len, _map.length);
      notifyChange(key, null, result, kind: ChangeRecord.INSERT);
    }
    return result;
  }

  V remove(K key) {
    int len = _map.length;
    V result =  _map.remove(key);
    if (hasObservers && len != _map.length) {
      notifyChange(key, result, null, kind: ChangeRecord.REMOVE);
      notifyChange('length', len, _map.length);
    }
    return result;
  }

  void clear() {
    int len = _map.length;
    if (hasObservers && len > 0) {
      _map.forEach((key, value) {
        notifyChange(key, value, null, kind: ChangeRecord.REMOVE);
      });
      notifyChange('length', len, 0);
    }
    _map.clear();
  }

  void forEach(void f(K key, V value)) => _map.forEach(f);

  String toString() => Maps.mapToString(this);
}
