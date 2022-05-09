# lxdgen.dart

An experimental tool that generates Dart data classes from LXD's Swagger file.

NOTE: [rest-api.yaml](https://github.com/lxc/lxd/blob/master/doc/rest-api.yaml)
does not contain information about which fields are required and which can be
nullable. Thus, this tool generates all fields as required and non-nullable, and
some manual adjustments may be required.

```sh
$ dart pub get
$ dart run bin/lxdgen.dart /path/to/lxd/doc/rest-api.yaml > types.dart
# or
$ dart run bin/lxdgen.dart /path/to/lxd/doc/rest-api.yaml LxdImage
```

```dart
@immutable
class LxdImage {
  const LxdImage({...});

  ...

  @override
  bool operator ==(Object other) {
    ...
  }

  @override
  int get hashCode {
    ...
  }

  @override
  String toString() {
    ...
  }
}
```
