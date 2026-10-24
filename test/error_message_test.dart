import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/localization.dart';
import 'package:gym_app/widgets/build_error_message.dart';

void main() {
  const english = 'Something went wrong. Please restart the app.';

  tearDown(() => languageNotifier.value = 'en');

  testWidgets('build error message needs no app ancestors and is translated', (tester) async {
    await tester.pumpWidget(const BuildErrorMessage());
    expect(find.text(english), findsOneWidget);

    languageNotifier.value = 'ar';
    await tester.pumpWidget(const BuildErrorMessage(key: ValueKey('ar')));
    expect(find.text('حدث خطأ ما. يرجى إعادة تشغيل التطبيق.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replaces a widget that fails to build without showing the error', (tester) async {
    final original = ErrorWidget.builder;
    ErrorWidget.builder = (_) => const BuildErrorMessage();
    try {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (_) => throw StateError('secret details'))),
      ));
      expect(tester.takeException(), isStateError);
      expect(find.text(english), findsOneWidget);
      expect(find.textContaining('secret details'), findsNothing);
    } finally {
      ErrorWidget.builder = original;
    }
  });
}
