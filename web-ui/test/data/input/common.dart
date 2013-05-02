// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common definitions used across several tests. */

@observable
library common;
import 'package:web_ui/observe.dart';

String topLevelVar = "hi";

bool cond = false;

bool get notCond => !cond;

List<String> loopItemList = toObservable(["a", "b"]);

List<String> initNullLoopItemList = null;
