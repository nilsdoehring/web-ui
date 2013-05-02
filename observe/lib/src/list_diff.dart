// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.observe;

// Note: most of this code is a port of:
// https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js
//
// It contains the logic for computing List diffs. Because this algorithm is
// fairly separable from the rest of the code, it gets put in this file.

/**
 * Summarize changes to [list]. This takes the changes in aggregate and computes
 * the minimal "splices"--add/remove/update operations--that are necessary
 * to reach the final state of the list.
 *
 * The return value is a [List] of [ListChangeDelta], where each delta is
 * conceptually a tuple of:
 *
 *   <index, removed, addedCount>
 *
 * These are returned in ascending index order.
 *
 * Lacking individual splice mutation information, the minimal set of
 * splices can be synthesized given the previous state and final state of an
 * array. The basic approach is to calculate the edit distance matrix and
 * choose the shortest path through it.
 *
 * Complexity is `O(l * p)`, where `l` is the length of the current list and
 * `p` is the length of the old list.
 */
List<ListChangeDelta> summarizeListChanges(List list,
    List<ChangeRecord> records) {

  // TODO(jmesserly): should we cut out the middle man, and produce
  // ListChangeDeltas straight from ObservableList? Then it's just a matter of
  // summarizing them. That's probably a lot faster than this approach.
  var diff = new _ListChangeSummary.fromRecords(list, records);

  var initialSplices = _createInitialSplicesFromDiff(list, diff);
  var splices = [];
  for (var splice in initialSplices) {
    var calculatedSplices = _calcSplices(list, splice.index,
        splice.index + splice.addedCount, splice.removed, 0,
        splice.removed.length);

    splices.addAll(calculatedSplices);
  }

  return splices;
}

/**
 * A summary of an individual change to a [List].
 *
 * Each delta represents that at the [index], [removed] sequence of items were
 * removed, and counting forward from [index], [addedCount] items were added.
 *
 * See also: [summarizeListChanges].
 */
class ListChangeDelta {
  /** The index of the change. */
  final int index;

  List _removed;

  // Note: conceptually final, but for convenience we increment it as we build
  // the object. It will be "frozen" by the time it is returned the the user.
  int _addedCount = 0;

  ListChangeDelta(this.index, {List removed, int addedCount: 0})
      : _removed = removed != null ? removed : [],
        _addedCount = addedCount;

  // TODO(jmesserly): freeze remove list before handing it out?
  /** The items removed, if any. Otherwise this will be an empty list. */
  List get removed => _removed;

  /** The number of items added. */
  int get addedCount => _addedCount;

  String toString() => '#<$runtimeType index: $index, '
      'removed: $removed, addedCount: $addedCount>';
}

// Note: This function is *based* on the computation of the Levenshtein
// "edit" distance. The one change is that "updates" are treated as two
// edits - not one. With List splices, an update is really a delete
// followed by an add. By retaining this, we optimize for "keeping" the
// maximum array items in the original array. For example:
//
//   'xxxx123' -> '123yyyy'
//
// With 1-edit updates, the shortest path would be just to update all seven
// characters. With 2-edit updates, we delete 4, leave 3, and add 4. This
// leaves the substring '123' intact.
List<List<int>> _calcEditDistances(List current, int currentStart,
    int currentEnd, List old, int oldStart, int oldEnd) {
  // "Deletion" columns
  var rowCount = oldEnd - oldStart + 1;
  var columnCount = currentEnd - currentStart + 1;
  var distances = new List(rowCount);

  // "Addition" rows. Initialize null column.
  for (var i = 0; i < rowCount; i++) {
    distances[i] = new List(columnCount);
    distances[i][0] = i;
  }

  // Initialize null row
  for (var j = 0; j < columnCount; j++) {
    distances[0][j] = j;
  }

  for (var i = 1; i < rowCount; i++) {
    for (var j = 1; j < columnCount; j++) {
      if (identical(old[oldStart + i - 1], current[currentStart + j - 1])) {
        distances[i][j] = distances[i - 1][j - 1];
      } else {
        var north = distances[i - 1][j] + 1;
        var west = distances[i][j - 1] + 1;
        distances[i][j] = math.min(north, west);
      }
    }
  }

  return distances;
}

const _EDIT_LEAVE = 0;
const _EDIT_UPDATE = 1;
const _EDIT_ADD = 2;
const _EDIT_DELETE = 3;

// This starts at the final weight, and walks "backward" by finding
// the minimum previous weight recursively until the origin of the weight
// matrix.
List<int> _spliceOperationsFromEditDistances(List<List<int>> distances) {
  var i = distances.length - 1;
  var j = distances[0].length - 1;
  var current = distances[i][j];
  var edits = [];
  while (i > 0 || j > 0) {
    if (i == 0) {
      edits.add(_EDIT_ADD);
      j--;
      continue;
    }
    if (j == 0) {
      edits.add(_EDIT_DELETE);
      i--;
      continue;
    }
    var northWest = distances[i - 1][j - 1];
    var west = distances[i - 1][j];
    var north = distances[i][j - 1];

    var min = math.min(math.min(west, north), northWest);

    if (min == northWest) {
      if (northWest == current) {
        edits.add(_EDIT_LEAVE);
      } else {
        edits.add(_EDIT_UPDATE);
        current = northWest;
      }
      i--;
      j--;
    } else if (min == west) {
      edits.add(_EDIT_DELETE);
      i--;
      current = west;
    } else {
      edits.add(_EDIT_ADD);
      j--;
      current = north;
    }
  }

  return edits.reversed.toList();
}

int _sharedPrefix(List arr1, List arr2, int searchLength) {
  for (var i = 0; i < searchLength; i++) {
    if (!identical(arr1[i], arr2[i])) {
      return i;
    }
  }
  return searchLength;
}

int _sharedSuffix(List arr1, List arr2, int searchLength) {
  var index1 = arr1.length;
  var index2 = arr2.length;
  var count = 0;
  while (count < searchLength && identical(arr1[--index1], arr2[--index2])) {
    count++;
  }
  return count;
}

/**
 * Lacking individual splice mutation information, the minimal set of
 * splices can be synthesized given the previous state and final state of an
 * array. The basic approach is to calculate the edit distance matrix and
 * choose the shortest path through it.
 *
 * Complexity: O(l * p)
 *   l: The length of the current array
 *   p: The length of the old array
 */
List<ListChangeDelta> _calcSplices(List current, int currentStart,
    int currentEnd, List old, int oldStart, int oldEnd) {

  var prefixCount = 0;
  var suffixCount = 0;

  var minLength = math.min(currentEnd - currentStart, oldEnd - oldStart);
  if (currentStart == 0 && oldStart == 0) {
    prefixCount = _sharedPrefix(current, old, minLength);
  }

  if (currentEnd == current.length && oldEnd == old.length) {
    suffixCount = _sharedSuffix(current, old, minLength - prefixCount);
  }

  currentStart += prefixCount;
  oldStart += prefixCount;
  currentEnd -= suffixCount;
  oldEnd -= suffixCount;

  if (currentEnd - currentStart == 0 && oldEnd - oldStart == 0) {
    return const [];
  }

  if (currentStart == currentEnd) {
    var splice = new ListChangeDelta(currentStart);
    while (oldStart < oldEnd) {
      splice.removed.add(old[oldStart++]);
    }

    return [splice ];
  } else if (oldStart == oldEnd)
    return [new ListChangeDelta(currentStart,
        addedCount: currentEnd - currentStart)];

  var ops = _spliceOperationsFromEditDistances(
      _calcEditDistances(current, currentStart, currentEnd, old, oldStart,
          oldEnd));

  ListChangeDelta splice = null;
  var splices = <ListChangeDelta>[];
  var index = currentStart;
  var oldIndex = oldStart;
  for (var i = 0; i < ops.length; i++) {
    switch(ops[i]) {
      case _EDIT_LEAVE:
        if (splice != null) {
          splices.add(splice);
          splice = null;
        }

        index++;
        oldIndex++;
        break;
      case _EDIT_UPDATE:
        if (splice == null) splice = new ListChangeDelta(index);

        splice._addedCount++;
        index++;

        splice.removed.add(old[oldIndex]);
        oldIndex++;
        break;
      case _EDIT_ADD:
        if (splice == null) splice = new ListChangeDelta(index);

        splice._addedCount++;
        index++;
        break;
      case _EDIT_DELETE:
        if (splice == null) splice = new ListChangeDelta(index);

        splice.removed.add(old[oldIndex]);
        oldIndex++;
        break;
    }
  }

  if (splice != null) {
    splices.add(splice);
  }
  return splices;
}

List<ListChangeDelta> _createInitialSplicesFromDiff(List list,
    _ListChangeSummary diff) {

  var oldLength = diff.oldFields['length'];
  if (oldLength == null) oldLength = list.length;

  ListChangeDelta lengthChange = null;
  if (list.length > oldLength) {
    lengthChange = new ListChangeDelta(oldLength,
        addedCount: list.length - oldLength);
  } else if (list.length < oldLength) {
    lengthChange = new ListChangeDelta(list.length,
        removed: new List(oldLength - list.length));
  }

  var indicesChanged = new SplayTreeMap<int, Object>();
  for (var properties in [diff.added, diff.removed, diff.items]) {
    for (var index in properties.keys) {
      if (index.isNaN || index < 0 || index >= oldLength) {
        continue;
      }

      var oldValue = diff.oldItems[index];
      if (index < list.length) {
        indicesChanged[index] = oldValue;
      } else {
        lengthChange.removed[index - list.length] = diff.oldItems[index];
      }
    }
  }

  var splices = <ListChangeDelta>[];
  ListChangeDelta current = null;

  for (var index in indicesChanged.keys) {
    if (current != null) {
      if (current.index + current.removed.length == index) {
        current.removed.add(indicesChanged[index]);
        continue;
      }

      current._addedCount = math.min(list.length, current.index +
          current.removed.length) - current.index;
      splices.add(current);
      current = null;
    }

    current = new ListChangeDelta(index, removed: [indicesChanged[index]]);
  }

  if (current != null) {
    current._addedCount = math.min(
        list.length, current.index + current.removed.length) - current.index;

    if (lengthChange != null) {
      if (current.index + current.removed.length == lengthChange.index) {
        // Join splices
        current._addedCount = current.addedCount + lengthChange.addedCount;
        current.removed.addAll(lengthChange.removed);
        splices.add(current);
      } else {
        splices.add(current);
        splices.add(lengthChange);
      }
    } else {
      splices.add(current);
    }
  } else if (lengthChange != null) {
    splices.add(lengthChange);
  }

  return splices;
}


class _ListChangeSummary {
  final Map added = new LinkedHashMap();
  final Map removed = new LinkedHashMap();
  final Map items = new LinkedHashMap();
  final Map oldFields = new LinkedHashMap();
  final Map oldItems = new LinkedHashMap();

  _ListChangeSummary.fromRecords(List list, List<ChangeRecord> records) {

    for (var record in records) {
      var key = record.key;
      if (record.kind == ChangeRecord.FIELD) {
        oldFields.putIfAbsent(key, () => record.oldValue);
        continue;
      }

      oldItems.putIfAbsent(key, () => record.oldValue);

      if (record.kind == ChangeRecord.INSERT) {
        removed.remove(key);
        added[key] = record.newValue;
      } else if (record.kind == ChangeRecord.REMOVE) {
        if (added.containsKey(key)) {
          added.remove(key);
          oldItems.remove(key);
        } else {
          items.remove(key);
          removed[key] = null;
        }
      } else if (record.kind == ChangeRecord.INDEX) {
        // TODO(jmesserly): arguably our ObservableList should not do this.
        removed.remove(key);
        var update = added.containsKey(key) ? added : items;
        update[key] = record.newValue;
      }
    }
  }

  bool get isEmpty => added.isEmpty && removed.isEmpty && items.isEmpty;
}
