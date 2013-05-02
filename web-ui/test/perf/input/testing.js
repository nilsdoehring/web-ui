// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

if (window.layoutTestController) {
  window.layoutTestController.dumpAsText();
  window.layoutTestController.waitUntilDone();
}

function messageHandler(e) {
  if (e.data == 'done' && window.layoutTestController) {
    window.layoutTestController.notifyDone();
  }
}

window.addEventListener('message', messageHandler, false);

function errorHandler(e) {
  if (window.layoutTestController) {
    window.layoutTestController.notifyDone();
  }
  window.console.log('FAIL');
}

window.addEventListener('error', errorHandler, false);
