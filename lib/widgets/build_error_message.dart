import 'package:flutter/material.dart';
import '../localization.dart';

/// Shown in release builds in place of a widget that failed to build (Flutter
/// would otherwise leave an empty grey box). It can end up anywhere in the
/// tree, so it brings its own text direction and Material, and it never shows
/// error details.
class BuildErrorMessage extends StatelessWidget {
  const BuildErrorMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: languageNotifier.value == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              translate('Something went wrong. Please restart the app.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
