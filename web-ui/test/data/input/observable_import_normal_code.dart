// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a test for the issue #367. We need to make sure that we can import
 * a normal (untransformed) Dart file from one that is @observable.
 */

library observable_import_normal_code;

import 'observable_imported_normal_code.dart';

@observable var theQuestion;

findTheQuestion() {
  theQuestion = 'Something whose answer is $theAnswer';
}
