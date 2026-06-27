import 'dart:convert';
import 'dart:io';

List<String> _parseCsvLine(String line) {
  final values = <String>[];
  final current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      values.add(current.toString());
      current.clear();
      continue;
    }

    current.write(char);
  }

  values.add(current.toString());
  return values;
}

void _writeJsonMap(String path, Map<String, String> map) {
  final sortedKeys = map.keys.toList()..sort();
  final sortedMap = <String, String>{};
  for (final key in sortedKeys) {
    sortedMap[key] = map[key] ?? '';
  }

  final encoder = const JsonEncoder.withIndent('  ');
  final file = File(path);
  file.writeAsStringSync('${encoder.convert(sortedMap)}\n');
}

void main() {
  final csvFile = File('docs/translations/strings.csv');
  if (!csvFile.existsSync()) {
    throw Exception('Missing docs/translations/strings.csv. Run export first.');
  }

  final lines = const LineSplitter().convert(csvFile.readAsStringSync());
  if (lines.isEmpty) {
    throw Exception('CSV is empty');
  }

  final header = _parseCsvLine(lines.first);
  final keyIndex = header.indexOf('key');
  final enIndex = header.indexOf('en');
  final itIndex = header.indexOf('it');

  if (keyIndex < 0 || enIndex < 0 || itIndex < 0) {
    throw Exception('CSV must contain key,en,it columns');
  }

  final en = <String, String>{};
  final it = <String, String>{};

  for (final rawLine in lines.skip(1)) {
    if (rawLine.trim().isEmpty) continue;

    final row = _parseCsvLine(rawLine);
    if (row.length <= [keyIndex, enIndex, itIndex].reduce((a, b) => a > b ? a : b)) {
      continue;
    }

    final key = row[keyIndex].trim();
    if (key.isEmpty) continue;

    en[key] = row[enIndex];
    it[key] = row[itIndex];
  }

  _writeJsonMap('lang/en.json', en);
  _writeJsonMap('lang/it.json', it);

  stdout.writeln('Imported ${en.length} keys into lang/en.json and lang/it.json');
}
