// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Collects several functions used by all performance tests, and reexports the
 * base classes from which all benchmarks extend.
 */
library perf_common;

import 'dart:html';
export 'package:benchmark_harness/benchmark_harness.dart';
export 'async_benchmark.dart';

void perfDone(num score) {
  var str = (score > 100) ? score.toStringAsFixed(0) : score.toStringAsFixed(2);
  print('benchmark-score: $str');
  window.postMessage('done', '*');
}
