// https://codewithandrea.com/articles/flutter-localization-build-context-extension/
// flutter gen-l10n

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this); // AppLocalizations is generated by flutter_gen
}
