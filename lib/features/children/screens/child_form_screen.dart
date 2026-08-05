import 'package:flutter/material.dart';

class ChildFormScreen extends StatelessWidget {
  const ChildFormScreen({super.key, this.childId});
  final String? childId;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Form Anak')));
}