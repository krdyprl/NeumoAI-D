import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/core/utils/formatters.dart';

void main() {
  test('formatIdDate renders Indonesian long date', () {
    expect(formatIdDate(DateTime(2026, 7, 31)), '31 Juli 2026');
  });

  test('greeting switches by hour', () {
    expect(greeting(DateTime(2026, 7, 31, 8)), 'Selamat pagi');
    expect(greeting(DateTime(2026, 7, 31, 12)), 'Selamat siang');
    expect(greeting(DateTime(2026, 7, 31, 16)), 'Selamat sore');
    expect(greeting(DateTime(2026, 7, 31, 21)), 'Selamat malam');
  });
}