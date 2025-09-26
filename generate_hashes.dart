import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final codes = ['P4H1P', 'P4H2P', 'P4H3P', 'P4H4P', 'P4H5P', 'P4H6P', 'P4H7P', 'P4H8P', 'P4H9P', 'P4H10P'];
  
  for (final code in codes) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    print('\'${digest.toString()}\', // $code');
  }
}
