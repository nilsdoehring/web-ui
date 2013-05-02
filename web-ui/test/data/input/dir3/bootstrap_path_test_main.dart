library main;

import 'dart:html';
import '../common.dart';
main() {
  topLevelVar = 'hello';
  window.postMessage('done', '*');
}
