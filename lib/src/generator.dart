import 'package:code_builder/code_builder.dart';

bool _isList(Field f) => f.type?.symbol?.startsWith('List<') ?? false;
bool _isMap(Field f) => f.type?.symbol?.startsWith('Map<') ?? false;

Library generate(List<Class> defs, Iterable<String> filter) {
  bool accept(Class d) {
    return d.fields.isNotEmpty &&
        (filter.isEmpty ||
            filter.any((f) => d.name.toLowerCase().contains(f.toLowerCase())));
  }

  return Library((b) => b
    ..body.addAll(defs.where(accept).map((d) {
      return d.rebuild((b) => b
        ..name = d.name
        ..constructors.add(generateConstructor(d))
        ..annotations.replace([refer('immutable')])
        ..methods.addAll([
          generateEquals(d),
          generateHashCode(d),
          generateToString(d),
        ]));
    })));
}

Constructor generateConstructor(Class def) {
  assert(def.fields.isNotEmpty);

  return Constructor((b) => b
    ..constant = true
    ..optionalParameters.addAll(def.fields.map((f) => Parameter((b) => b
      ..name = f.name
      ..named = true
      ..toThis = true
      ..required = true))));
}

Method generateEquals(Class def) {
  assert(def.fields.isNotEmpty);

  final blocks = Block.of([
    const Code('if (identical(this, other)) return true;'),
    if (def.fields.any(_isList))
      const Code('final listEquals = const ListEquality().equals;'),
    if (def.fields.any(_isMap))
      const Code('final mapEquals = const MapEquality().equals;'),
    def.fields
        .fold<Expression>(refer('other').isA(refer(def.name)), (exp, f) {
          final property = refer(f.name);
          final other = refer('other').property(f.name);
          late final Expression cmp;
          if (_isList(f)) {
            cmp = refer('listEquals').call([property, other]);
          } else if (_isMap(f)) {
            cmp = refer('mapEquals').call([property, other]);
          } else {
            cmp = property.equalTo(other);
          }
          return exp.and(cmp);
        })
        .returned
        .statement,
  ]);

  return Method((b) => b
    ..annotations.add(refer('override'))
    ..returns = refer('bool')
    ..name = 'operator=='
    ..requiredParameters.add(Parameter((b) => b
      ..name = 'other'
      ..type = refer('Object')))
    ..body = blocks);
}

Method generateHashCode(Class def) {
  assert(def.fields.isNotEmpty);

  Expression singleHashCode(List<Field> fields) {
    return refer(fields.single.name).property('hashCode');
  }

  Expression fieldHashCode(Field field) {
    final f = refer(field.name);
    if (_isList(field)) {
      return refer('Object').property('hashAll').call([f]);
    }
    if (_isMap(field)) {
      return refer('Object').property('hashAll').call([f.property('entries')]);
    }
    return f;
  }

  Expression invokeObjectHash(List<Field> fields, {bool wrap = false}) {
    return InvokeExpression.newOf(
        refer('Object'), fields.map(fieldHashCode).toList(), {}, [], 'hash');
  }

  Expression invokeObjectHashAll(List<Field> fields) {
    return InvokeExpression.newOf(refer('Object'),
        [literalList(fields.map(fieldHashCode))], {}, [], 'hashAll');
  }

  final expression = def.fields.length == 1
      ? singleHashCode
      : def.fields.length <= 20
          ? invokeObjectHash
          : invokeObjectHashAll;

  return Method((b) => b
    ..annotations.add(refer('override'))
    ..returns = refer('int')
    ..type = MethodType.getter
    ..name = 'hashCode'
    ..body = expression(def.fields.asList()).returned.statement);
}

Method generateToString(Class def) {
  assert(def.fields.isNotEmpty);

  final fields = def.fields.map((f) => '${f.name}: \$${f.name}').join(', ');

  return Method((b) => b
    ..annotations.add(refer('override'))
    ..returns = refer('String')
    ..name = 'toString'
    ..body = refer('\'${def.name}($fields)\'').returned.statement);
}
