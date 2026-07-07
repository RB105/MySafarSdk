/// MySafar travel booking SDK.
///
/// Host app foydalanishi:
/// ```dart
/// await MySafarSdk.init(config: MySafarConfig(baseUrl: ..., skoteBaseUrl: ...));
/// runApp(const MySafarApp());            // to'liq app rejimi
/// // yoki host ichida: Navigator.push(... => const MySafarEmbed());
/// ```
library;

export 'src/api/analytics.dart';
export 'src/api/app.dart';
export 'src/api/callbacks.dart';
export 'src/api/config.dart';
export 'src/api/sdk.dart';
export 'src/api/token_store.dart';
