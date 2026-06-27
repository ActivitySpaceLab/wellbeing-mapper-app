import 'dart:convert';
import 'dart:io';

String _escapeCsv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

Map<String, String> _readJsonMap(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw Exception('Missing file: $path');
  }
  final dynamic decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Expected JSON object in $path');
  }
  return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
}

void main() {
  final en = _readJsonMap('lang/en.json');
  final it = _readJsonMap('lang/it.json');

  final keys = <String>{...en.keys, ...it.keys}.toList()..sort();

  final buffer = StringBuffer();
  buffer.writeln('key,en,it,status,notes');

  for (final key in keys) {
    buffer.writeln([
      _escapeCsv(key),
      _escapeCsv(en[key] ?? ''),
      _escapeCsv(it[key] ?? ''),
      _escapeCsv(''),
      _escapeCsv(''),
    ].join(','));
  }

  final outFile = File('docs/translations/strings.csv');
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(buffer.toString());

  stdout.writeln('Exported ${keys.length} keys to ${outFile.path}');
}
