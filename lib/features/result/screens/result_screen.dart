import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, this.screeningId});
  final String? screeningId;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Hasil')));
}