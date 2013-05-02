// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.observe;

/**
 * Represents an observable list of model values. If any items are added,
 * removed, or replaced, then observers that are listening to [changes]
 * will be notified.
 */
class ObservableList<E> extends _ListBaseWorkaround with ObservableMixin
    implements List<E> {

  /** The inner [List<E>] with the actual storage. */
  final List<E> _list;

  /**
   * Creates an observable list of the given [length].
   *
   * If no [length] argument is supplied an extendable list of
   * length 0 is created.
   *
   * If a [length] argument is supplied, a fixed size list of that
   * length is created.
   */
  ObservableList([int length])
      : _list = length != null ? new List<E>(length) : <E>[];

  /**
   * Creates an observable list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   */
  factory ObservableList.from(Iterable<E> other) =>
      new ObservableList<E>()..addAll(other);

  // TODO(jmesserly): remove once we have mirrors
  getValue(key) => key == 'length' ? length : null;
  setValue(key, value) {
    if (key == 'length') length = value;
  }

  int get length => _list.length;

  set length(int value) {
    int len = _list.length;
    if (len == value) return;

    // Produce notifications if needed
    if (hasObservers) {
      if (value < len) {
        // Remove items, then adjust length. Note the reverse order.
        for (int i = len - 1; i >= value; i--) {
          notifyChange(i, _list[i], null, kind: ChangeRecord.REMOVE);
        }
        notifyChange('length', len, value);
      } else {
        // Adjust length then add items
        notifyChange('length', len, value);
        for (int i = len; i < value; i++) {
          notifyChange(i, null, null, kind: ChangeRecord.INSERT);
        }
      }
    }

    _list.length = value;
  }

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) {
    var oldValue = _list[index];
    if (hasObservers) {
      notifyChange(index, oldValue, value, kind: ChangeRecord.INDEX);
    }
    _list[index] = value;
  }

  // The following methods are here so that we can provide nice change events
  // (insertions and removals). If we use the mixin implementation, we would
  // only report changes on indices.
  // TODO(jmesserly): do we need this now that we have [summarizeListChanges]?

  void add(E value) {
    int len = _list.length;
    if (hasObservers) {
      notifyChange('length', len, len + 1, kind: ChangeRecord.FIELD);
      notifyChange(len, null, value, kind: ChangeRecord.INSERT);
    }

    _list.add(value);
  }

  void addAll(Iterable<E> iterable) {
    for (E element in iterable) {
      add(element);
    }
  }

  bool remove(Object element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeRange(i, 1);
        return true;
      }
    }
    return false;
  }

  void removeRange(int start, int end) {
    _rangeCheck(start, end);
    if (hasObservers) {
      for (int i = start; i < end; i++) {
        notifyChange(i, this[i], null, kind: ChangeRecord.REMOVE);
      }
    }
    int length = end - start;
    setRange(start, this.length - length, this, end);
    this.length -= length;
  }

  void insertAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    // TODO(floitsch): we can probably detect more cases.
    if (iterable is! List && iterable is! Set) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    this.length += insertionLength;
    setRange(index + insertionLength, this.length, this, index);

    if (hasObservers) {
      for (E element in iterable) {
        notifyChange(index, _list[index], element, kind: ChangeRecord.INSERT);
        _list[index++] = element;
      }
    } else {
      setAll(index, iterable);
    }
  }

  void insert(int index, E element) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == this.length) {
      add(element);
      return;
    }
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    this.length++;
    setRange(index + 1, this.length, this, index);
    notifyChange(index, _list[index], element, kind: ChangeRecord.INSERT);
    _list[index] = element;
  }


  E removeAt(int index) {
    E result = this[index];
    removeRange(index, index + 1);
    return result;
  }

  void _rangeCheck(int start, int end) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
  }
}


// TODO(jmesserly): bogus type to workaround spurious VM bug with generic base
// class and mixins. Can we remove now that we aren't in a package?
abstract class _ListBaseWorkaround extends ListBase<dynamic> {}
