import 'package:flutter_test/flutter_test.dart';

/// Drains `RenderFlex overflowed` exceptions produced by a layout defect that
/// is tracked separately, and rethrows anything else.
///
/// Use this only where a test's real subject is something other than layout,
/// and the overflow would otherwise fail it for an unrelated reason. Always
/// pass the defect id in [reason] so the suppression is traceable — and delete
/// the call when that defect is fixed.
void drainKnownOverflows(WidgetTester tester, {required String reason}) {
  while (true) {
    final Object? exception = tester.takeException();
    if (exception == null) return;

    if (!exception.toString().contains('overflowed')) {
      throw exception;
    }
  }
}
