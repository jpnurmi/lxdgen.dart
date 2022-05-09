import 'package:code_builder/code_builder.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';

List<Class> parseDefinitions(YamlMap definitions) {
  final cache = <String, Class>{};

  String typeRef(String typeName) => 'Lxd$typeName';

  String parseType(YamlMap property) {
    String? parseTypeRef(String? ref) {
      if (ref == null) return null;
      return typeRef(RegExp('#/definitions/(.*)').firstMatch(ref)!.group(1)!);
    }

    String parseArrayType(YamlMap property) {
      return 'List<${parseType(property['items'])}>';
    }

    final type = property['type'];
    switch (type) {
      case 'array':
        return parseArrayType(property);
      case 'boolean':
        return 'bool';
      case 'integer':
        return 'int';
      case 'number':
        return 'double';
      case 'object':
        return 'Map<String, dynamic>';
      case 'string':
        return 'String';
      default:
        return parseTypeRef(property[r'$ref']) ?? type;
    }
  }

  List<String> parseDocs(MapEntry property) {
    final title = property.value['title'] as String?;
    final description = property.value['description'] as String?;
    return ([title, description].whereType<String>().join('\n\n')).split('\n');
  }

  String parseName(MapEntry property) {
    final name = property.key as String;
    if (name == 'class') return 'klass';
    return name.camelCase;
  }

  for (final def in definitions.entries) {
    cache[def.key] ??= Class((b) => b
      ..name = typeRef(def.key)
      ..docs.addAll(parseDocs(def).map((d) => '/// $d'))
      ..fields.addAll([
        for (final property in def.entries('properties'))
          Field((b) => b
            ..name = parseName(property)
            ..modifier = FieldModifier.final$
            ..type = refer(parseType(property.value))
            ..docs.addAll(parseDocs(property).map((d) => '/// $d')))
      ]));
  }
  return cache.values.toList();
}

extension YamlMapEntry<K, V> on MapEntry<K, V> {
  Iterable<MapEntry<K, V>> entries(String key) {
    return (value as YamlMap)[key]?.entries ?? [];
  }
}
