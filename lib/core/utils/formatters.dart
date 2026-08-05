const List<String> _idMonths = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String formatIdDate(DateTime d) => '${d.day} ${_idMonths[d.month - 1]} ${d.year}';

String greeting(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 19) return 'Selamat sore';
  return 'Selamat malam';
}

String formatRecordTime(int seconds) {
  final clamped = seconds.clamp(0, 59);
  return '0:0$clamped';
}

String formatWeight(double w) => '${w.toStringAsFixed(1)} kg';
String formatHeight(double h) => '${h.toStringAsFixed(0)} cm';
