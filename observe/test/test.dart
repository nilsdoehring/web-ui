#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'list_change_test.dart' as list_change_test;
import 'observe_test.dart' as observe_test;
import 'observe_path_test.dart' as observe_path_test;
import 'observable_list_test.dart' as observable_list_test;
import 'observable_map_test.dart' as observable_map_test;

main() {
  var args = new Options().arguments;
  var pattern = new RegExp(args.length > 0 ? args[0] : '.');

  useCompactVMConfiguration();

  void addGroup(testFile, testMain) {
    if (pattern.hasMatch(testFile)) {
      group(testFile.replaceAll('_test.dart', ':'), testMain);
    }
  }

  addGroup('list_change_test.dart', list_change_test.main);
  addGroup('observe_test.dart', observe_test.main);
  addGroup('observe_path_test.dart', observe_path_test.main);
  addGroup('observable_map_test.dart', observable_map_test.main);
  addGroup('observable_list_test.dart', observable_list_test.main);
}
