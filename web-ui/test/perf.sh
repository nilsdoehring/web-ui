#!/bin/bash
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# bail on error
set -e
TEST_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
PERF_DIR="$TEST_DIR/perf"
WEB_UI_HOME=$(dirname $TEST_DIR)
DART_FLAGS="--checked"
TEST_PATTERN=$1

if [[ ! -e $PERF_DIR/input/example ]]; then
  ln -s $WEB_UI_HOME/example/ $PERF_DIR/input/example
fi


pushd $PERF_DIR
dart $DART_FLAGS perf.dart $TEST_PATTERN
popd
