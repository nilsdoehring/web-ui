// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/src/dart_parser.dart';
import 'package:web_ui/src/observable_transform.dart';

testClause(String clauses, String expected) {
  test(clauses, () {

    var className = 'MyClass';
    if (clauses.contains('<T>')) className += '<T>';

    var code = '''
        class $className $clauses {
          @observable var field;
        }''';

    var edit = transformObservables(parseDartCode('<test>', code, null));
    expect(edit, isNotNull);
    var output = (edit.commit()..build('<test>')).text;

    var classPos = output.indexOf(className) + className.length;
    var actualClauses = output.substring(classPos, output.indexOf('{'))
        .trim().replaceAll('  ', ' ');

    expect(actualClauses, expected);
  });
}

main() {
  useCompactVMConfiguration();

  group('adds "with Observable" given', () {
    testClause('', 'extends Observable');
    testClause('extends Base', 'extends Base with Observable');
    testClause('extends Base<T>', 'extends Base<T> with Observable');
    testClause('extends Base with Mixin',
        'extends Base with Mixin, Observable');
    testClause('extends Base with Mixin<T>',
        'extends Base with Mixin<T>, Observable');
    testClause('extends Base with Mixin, Mixin2',
        'extends Base with Mixin, Mixin2, Observable');
    testClause('implements Interface',
        'extends Observable implements Interface');
    testClause('implements Interface<T>',
        'extends Observable implements Interface<T>');
    testClause('extends Base implements Interface',
        'extends Base with Observable implements Interface');
    testClause('extends Base with Mixin implements Interface, Interface2',
        'extends Base with Mixin, Observable implements Interface, Interface2');
  });
}
