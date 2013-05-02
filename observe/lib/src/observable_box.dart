// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.observe;

/**
 * An observable box that holds a value. Use this if you want to store a single
 * value. For other cases, it is better to use [ObservableList],
 * [ObservableMap], or a custom [Observable] implementation based on
 * [ObservableMixin].
 */
class ObservableBox<T> extends ObservableMixin {
  T _value;

  ObservableBox([T initialValue]) : _value = initialValue;

  T get value => _value;

  void set value(T newValue) {
    if (hasObservers) {
      notifyChange('value', _value, newValue);
    }
    _value = newValue;
  }

  String toString() => '#<$runtimeType value: $value>';

  getValue(key) {
    if (key == 'value') return value;
    return null;
  }
  void setValue(key, newValue) {
    if (key == 'value') value = newValue;
  }
}
