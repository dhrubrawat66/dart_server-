import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  test('it should return a 200 response', () async {
    final response = await get(Uri.parse('http://localhost:8080'));
    expect(response.statusCode, HttpStatus.ok);
  });
}
