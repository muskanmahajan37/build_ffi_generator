import 'package:dart_style/dart_style.dart';

import 'elements.dart';

final _dartfmt = DartFormatter();

String generateForFile(FfiFile file) {
  final into = StringBuffer()
    ..writeln('// auto-generated, DO NOT EDIT')
    ..writeln('// Instead, run pub run build_runner build')
    ..writeln()
    ..writeln("import 'dart:ffi';");

  _writeStructs(file, into);
  _writeTypedefs(file, into);
  _writeBindingsClass(file, into);

  return _dartfmt.format(into.toString());
}

void _writeStructs(FfiFile file, StringBuffer into) {
  for (final type in file.types) {
    if (type.definition is OpaqueStruct) {
      final name = type.name;
      into..writeln('class $name extends Struct {}');
    }
  }
}

void _writeTypedefs(FfiFile file, StringBuffer into) {
  for (final function in file.functions) {
    // Write native typedef
    into
      ..write('typedef ${function.nativeTypedefName} = ')
      ..write(function.returnType.nativeTypeName)
      ..write(' Function(');

    var first = true;
    for (final arg in function.arguments) {
      if (!first) {
        into.write(',');
      }

      into.write(arg.type.nativeTypeName);

      first = false;
    }

    into..writeln(');');

    // Write Dart typedef that can be called
    into
      ..write('typedef ${function.dartTypedefName} = ')
      ..write(function.returnType.dartName)
      ..write(' Function(');

    first = true;
    for (final arg in function.arguments) {
      if (!first) {
        into.write(',');
      }

      into.write(arg.type.dartName);

      first = false;
    }

    into..writeln(');');
  }
}

void _writeBindingsClass(FfiFile file, StringBuffer into) {
  into..writeln('class Bindings {');

  // Write fields to hold the functions
  for (final function in file.functions) {
    into.writeln('final ${function.dartTypedefName} ${function.name};');
  }

  // Write constructor
  into..writeln('Bindings(DynamicLibrary library): ');
  var first = true;

  for (final function in file.functions) {
    if (!first) {
      into..writeln(', ');
    }

    into
      ..writeln('${function.name} = library.lookupFunction')
      ..writeln('<${function.nativeTypedefName}, ${function.dartTypedefName}>')
      ..writeln("('${function.name}')");

    first = false;
  }

  into.writeln(';\n}');
}

extension on CType {
  String get nativeTypeName {
    if (this is IntType) {
      final typedThis = this as IntType;
      switch (typedThis.kind) {
        case IntKind.int8:
          return 'Int8';
        case IntKind.int16:
          return 'Int16';
        case IntKind.int32:
          return 'Int32';
        case IntKind.int64:
          return 'Int64';
        case IntKind.uint8:
          return 'Uint8';
        case IntKind.uint16:
          return 'Uint16';
        case IntKind.uint32:
          return 'Uint32';
        case IntKind.uint64:
          return 'Uint64';
        case IntKind.int:
          return 'IntPtr';
      }
    } else if (this is NamedType) {
      final inner = (this as NamedType).type;
      if (inner is OpaqueStruct) {
        return (this as NamedType).name;
      }
      return inner.nativeTypeName;
    } else if (this is PointerType) {
      return 'Pointer<${(this as PointerType).inner.nativeTypeName}>';
    }

    throw UnsupportedError('Not implemented: $runtimeType');
  }

  String get dartName {
    if (this is IntType) {
      return 'int';
    }

    return nativeTypeName;
  }
}

extension on CFunction {
  String get nativeTypedefName => '_${name}_native';
  String get dartTypedefName => '${name}_dart';
}
