library main;

import 'dart:html';
import 'package:web_ui/observe.dart';
import 'common.dart';

main() {
  topLevelVar = "hello";
  window.postMessage('done', '*');
}

