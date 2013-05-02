// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.observe;

/**
 * Converts the [Iterable] or [Map] to an [ObservableList] or [ObservableMap],
 * respectively.
 *
 * If [value] is not one of those collection types, or is already [Observable],
 * it will be returned unmodified.
 *
 * If [value] is a [Map], the resulting value will use the appropriate kind of
 * backing map: either [HashMap], [LinkedHashMap], or [SplayTreeMap].
 *
 * By default this performs a deep conversion, but you can set [deep] to false
 * for a shallow conversion. This does not handle circular data structures.
 */
// TODO(jmesserly): ObservableSet?
toObservable(value, {bool deep: true}) =>
    deep ? _toObservableDeep(value) : _toObservableShallow(value);

_toObserveShallow(value) {
  if (value is Observable) return value;
  if (value is Map) return new ObservableMap.from(value);
  if (value is Iterable) return new ObservableList.from(value);
  return value;
}

_toObservableDeep(value) {
  if (value is Observable) return value;
  if (value is Map) {
    var result = new ObservableMap._createFromType(value);
    value.forEach((k, v) {
      result[_toObservableDeep(k)] = _toObservableDeep(v);
    });
    return result;
  }
  if (value is Iterable) {
    return new ObservableList.from(value.map(_toObservableDeep));
  }
  return value;
}


/**
 * Interface representing an observable object. This is used by data in
 * model-view architectures to notify interested parties of [changes].
 *
 * This object does not require any specific technique to implement
 * observability.
 *
 * You can use [ObservableMixin] as a base class or mixin to implement this.
 */
abstract class Observable {
  // TODO(jmesserly): should this be synchronous, and allow libraries to build
  // the async batching?
  /**
   * The stream of change records to this object.
   *
   * Changes should be delivered in asynchronous batches by calling
   * [queueChangeRecords].
   * [deliverChangeRecords] can be called to force delivery.
   */
  Stream<List<ChangeRecord>> get changes;

  // TODO(jmesserly): remove these ASAP.
  /**
   * *Warning*: this method is temporary until dart2js supports mirrors.
   * Gets the value of a field or index. This should return null if it was
   * not found.
   */
  getValue(key);

  /**
   * *Warning*: this method is temporary until dart2js supports mirrors.
   * Sets the value of a field or index. This should have no effect if the field
   * was not found.
   */
  void setValue(key, Object value);
}

/**
 * Mixin for implementing [Observable].
 *
 * When a field, property, or indexable item is changed, a derived class should
 * call [notifyChange]. See that method for an example.
 */
abstract class ObservableMixin implements Observable {
  // TODO(jmesserly): this has way too much overhead. We probably need our own
  // stream.
  StreamController<List<ChangeRecord>> _observers;
  Stream<List<ChangeRecord>> _stream;
  List<ChangeRecord> _changes;

  Stream<List<ChangeRecord>> get changes {
    if (_observers == null) {
      _observers = new StreamController<List<ChangeRecord>>();
      _stream = _observers.stream.asBroadcastStream();
    }
    return _stream;
  }

  void _deliverChanges() {
    var changes = _changes;
    _changes = null;
    if (hasObservers && changes != null) {
      // TODO(jmesserly): make "changes" immutable
      _observers.add(changes);
    }
  }

  /**
   * True if this object has any observers, and should call [notifyChange] for
   * changes.
   */
  bool get hasObservers => _observers != null && _observers.hasListener;

  /**
   * Notify that a [key] of this object has been changed.
   *
   * The key can also represent a field or indexed value of the object or list.
   * The [kind] is one of the constants [ChangeRecord.INDEX],
   * [ChangeRecord.FIELD], [ChangeRecord.INSERT], or [ChangeRecord.REMOVE].
   *
   * The [oldValue] and [newValue] are also recorded. If the change wasn't an
   * insert or remove, and the two values are equal, no change will be recorded.
   * For INSERT, oldValue should be null. For REMOVE, newValue should be null.
   *
   * For convenience this returns [newValue]. This makes it easy to use in a
   * setter:
   *
   *     var _someField;
   *     get someField => _someField;
   *     set someField(value) {
   *       _someField = notifyChange('someField', _someField, value);
   *     }
   */
  Object notifyChange(key, Object oldValue, Object newValue,
      {int kind: ChangeRecord.FIELD}) {

    if (!hasObservers) return newValue;

    // If this is an assignment (and not insert/remove) then check if
    // the value actually changed. If not don't signal a change event.
    // This helps programmers avoid some common cases of cycles in their code.
    if ((kind & (ChangeRecord.INSERT | ChangeRecord.REMOVE)) == 0) {
      if (oldValue == newValue) return newValue;
    }

    if (_changes == null) {
      _changes = [];
      queueChangeRecords(_deliverChanges);
    }
    _changes.add(new ChangeRecord(key, oldValue, newValue, kind: kind));
    return newValue;
  }
}

/** Records a change to an [Observable]. */
class ChangeRecord {
  // Note: the target object is omitted because it makes it difficult
  // to proxy change records if you're using an observable kind to aid
  // your implementation.
  // However: if we allow one observer to get batched changes for multiple
  // objects, we'll need to add target.

  // Note: kind values were chosen for easy masking in the observable expression
  // implementation. However in [kind] it will only have one value.

  // TODO(jmesserly): is there any value in keeping FIELD and INDEX distinct?
  /** [kind] denoting set of a field. */
  static const FIELD = 1;

  /** [kind] denoting an in-place update event using `[]=`. */
  static const INDEX = 2;

  /**
   * [kind] denoting an insertion into a list. Insertions prepend in front of
   * the given index, so insert at 0 means an insertion at the beginning of the
   * list. The index will be provided in [key].
   */
  static const INSERT = INDEX | 4;

  /** [kind] denoting a remove from a list. */
  static const REMOVE = INDEX | 8;

  /** Whether the change was a [FIELD], [INDEX], [INSERT], or [REMOVE]. */
  final int kind;

  // TODO(jmesserly): for fields, is key a String or Symbol? Right now it's a
  // String.
  /**
   * The key that changed. The value depends on the [kind] of change:
   *
   * - [FIELD]: the field name that was set.
   * - [INDEX], [INSERT], and [REMOVE]: the index or key that was changed.
   *   This will be an integer for [ObservableList] but can be anything for
   *   [ObservableMap].
   */
  final key;

  /** The previous value of the member. */
  final oldValue;

  /** The new value of the member. */
  final newValue;

  ChangeRecord(this.key, this.oldValue, this.newValue,
      {this.kind: ChangeRecord.FIELD});

  // Note: these two methods are here mainly to make testing easier.
  bool operator ==(other) {
    return other is ChangeRecord && kind == other.kind && key == other.key &&
        oldValue == other.oldValue && newValue == other.newValue;
  }

  int get hashCode => _hash4(kind, key, oldValue, newValue);

  String toString() {
    // TODO(jmesserly): const map would be nice here, but it must be string
    // literal :(
    String typeStr;
    switch (kind) {
      case FIELD: typeStr = 'field'; break;
      case INDEX: typeStr = 'index'; break;
      case INSERT: typeStr = 'insert'; break;
      case REMOVE: typeStr = 'remove'; break;
    }
    return '#<ChangeRecord $typeStr $key from $oldValue to $newValue>';
  }
}

// TODO(jmesserly): helpers to combine hash codes. Reuse these from somewhere.
int _hash2(x, y) => x.hashCode * 31 + y.hashCode;

int _hash3(x, y, z) => _hash2(_hash2(x, y), z);

int _hash4(w, x, y, z) => _hash2(_hash2(w, x), _hash2(y, z));


/**
 * Synchronously deliver [Observable.changes] for all observables.
 * If new changes are added as a result of delivery, this will keep running
 * until all pending change records are delivered.
 */
// TODO(jmesserly): this is a bit different from the ES Harmony version, which
// allows delivery of changes to a particular observer:
// http://wiki.ecmascript.org/doku.php?id=harmony:observe#object.deliverchangerecords
// However the binding system needs delivery of everything, along the lines of:
// https://github.com/toolkitchen/mdv/blob/stable/src/model.js#L19
// https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js#L590
// TODO(jmesserly): in the future, we can use this to trigger dirty checking.
void deliverChangeRecords() {
  if (_deliverCallbacks == null) return;

  while (_deliverCallbacks.length > 0) {
    var deliverCallbacks = _deliverCallbacks;
    // Use empty list so [queueChangeRecords] don't reschedule this method.
    _deliverCallbacks = [];

    for (var deliver in deliverCallbacks) {
      try {
        deliver();
      } catch (e, s) {
        // Schedule the error to be top-leveled later.
        new Completer().completeError(e, s);
      }
    }
  }

  // Use null list so [queueChangeRecords] will reschedule this method.
  _deliverCallbacks = null;
}

/** Queues an action to happen during the [deliverChangeRecords] timeslice. */
void queueChangeRecords(void deliverChanges()) {
  if (_deliverCallbacks == null) {
    _deliverCallbacks = [];
    runAsync(deliverChangeRecords);
  }
  _deliverCallbacks.add(deliverChanges);
}

List<Function> _deliverCallbacks;
