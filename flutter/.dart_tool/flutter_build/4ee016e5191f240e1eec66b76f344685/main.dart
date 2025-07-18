// @dart=2.17
// Flutter web bootstrap script for package:solidity/main.dart.
//
// Generated file. Do not edit.
//

// ignore_for_file: type=lint

import 'dart:ui' as ui;
import 'dart:async';

import 'package:solidity/main.dart' as entrypoint;
import 'web_plugin_registrant.dart' as pluginRegistrant;

typedef _UnaryFunction = dynamic Function(List<String> args);
typedef _NullaryFunction = dynamic Function();

Future<void> main() async {
  await ui.webOnlyWarmupEngine(
    runApp: () {
      if (entrypoint.main is _UnaryFunction) {
        return (entrypoint.main as _UnaryFunction)(<String>[]);
      }
      return (entrypoint.main as _NullaryFunction)();
    },
    registerPlugins: () {
      pluginRegistrant.registerPlugins();
    },
  );
}
