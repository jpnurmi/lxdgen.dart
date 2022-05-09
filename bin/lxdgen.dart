import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:lxdgen/lxdgen.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || !File(args.first).existsSync()) {
    print('Usage: lxdgen <path/to/lxd/rest-api.yaml> [filter]');
    exit(1);
  }

  final data = File(args.first).readAsStringSync();
  final doc = await loadYaml(data);
  final defitions = parseDefinitions(doc['definitions']);
  final lib = generate(defitions, args.skip(1));
  print(DartFormatter().format('${lib.accept(DartEmitter.scoped())}'));
}
