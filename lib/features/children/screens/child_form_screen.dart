import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/widgets/neumo_field.dart';
import '../../../core/widgets/neumo_segmented.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/child.dart';
import '../../../models/enums.dart';
import '../../../models/vaccination.dart';
import '../../../state/app_providers.dart';

class ChildFormScreen extends ConsumerStatefulWidget {
  const ChildFormScreen({super.key, this.childId});

  final String? childId;

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  static const _emojis = ['👦', '👧', '👶', '🤗', '👼', '🤱'];

  final _name = TextEditingController();
  final _birthWeight = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _medicalHistory = TextEditingController();

  Gender _gender = Gender.male;
  String _birthDate = '2023-01-01';
  String _emoji = '👦';
  final List<Vaccination> _vaccinations = [];
  final _vaccineName = TextEditingController();

  bool get _isEdit => widget.childId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final child = ref.read(childrenProvider).valueOrNull?.where((c) => c.id == widget.childId).firstOrNull;
      if (child != null) {
        _name.text = child.name;
        _birthWeight.text = child.birthWeight.toString();
        _weight.text = child.weight.toString();
        _height.text = child.height.toString();
        _medicalHistory.text = child.medicalHistory;
        _gender = child.gender;
        _birthDate = child.birthDate;
        _emoji = child.emoji;
        _vaccinations.addAll(child.vaccinations);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _birthWeight.dispose();
    _weight.dispose();
    _height.dispose();
    _medicalHistory.dispose();
    _vaccineName.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2023),
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _addVaccine() {
    final name = _vaccineName.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _vaccinations.add(Vaccination(
        id: 'v${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        date: _birthDate,
        done: false,
      ));
      _vaccineName.clear();
    });
  }

  Future<void> _save() async {
    final child = Child(
      id: widget.childId ?? 'c${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim().isEmpty ? 'Tanpa Nama' : _name.text.trim(),
      gender: _gender,
      birthDate: _birthDate,
      birthWeight: double.tryParse(_birthWeight.text) ?? 0,
      weight: double.tryParse(_weight.text) ?? 0,
      height: double.tryParse(_height.text) ?? 0,
      emoji: _emoji,
      medicalHistory: _medicalHistory.text.trim(),
      vaccinations: List.of(_vaccinations),
    );
    if (_isEdit) {
      await ref.read(childrenProvider.notifier).updateChild(child);
    } else {
      await ref.read(childrenProvider.notifier).add(child);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInk
        : AppColors.lightInk;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          NeumoTopBar(title: _isEdit ? 'Edit Anak' : 'Tambah Anak'),
          Expanded(
            child: ListView(
              padding: pagePadding,
              children: [
                Text('Data Anak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 16),
                NeumoField(label: 'Nama lengkap', controller: _name, placeholder: 'Nama anak'),
                const SizedBox(height: 16),
                const Text('Jenis kelamin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightInk)),
                const SizedBox(height: 8),
                NeumoSegmented<Gender>(
                  options: const [(Gender.male, 'Laki-laki'), (Gender.female, 'Perempuan')],
                  value: _gender,
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: NeumoField(label: 'Tanggal lahir', value: _birthDate, onChanged: (_) {}, placeholder: _birthDate),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: NeumoField(label: 'Berat lahir (kg)', controller: _birthWeight, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: NeumoField(label: 'Berat (kg)', controller: _weight, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 16),
                NeumoField(label: 'Tinggi (cm)', controller: _height, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                NeumoField(label: 'Riwayat medis', controller: _medicalHistory, hint: 'Contoh: alergi, riwayat ISPA'),
                const SizedBox(height: 24),
                Text('Pilih emoji', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final e in _emojis)
                    GestureDetector(
                      onTap: () => setState(() => _emoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _emoji == e ? AppColors.lightPrimarySoft : Colors.transparent,
                          border: Border.all(color: _emoji == e ? AppColors.primary : AppColors.lightBorder),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ]),
                const SizedBox(height: 24),
                Text('Vaksinasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 8),
                for (final v in _vaccinations)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: v.done,
                    title: Text(v.name, style: const TextStyle(fontSize: 14)),
                    onChanged: (on) => setState(() {
                      final i = _vaccinations.indexOf(v);
                      if (i >= 0) {
                        _vaccinations[i] = Vaccination(id: v.id, name: v.name, date: v.date, done: on ?? v.done);
                      }
                    }),
                  ),
                Row(children: [
                  Expanded(child: NeumoField(controller: _vaccineName, placeholder: 'Nama vaksin')),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _addVaccine, icon: const Icon(Icons.add_circle, color: AppColors.primary)),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumoButton(expand: true, size: NeumoSize.lg, label: 'Simpan', onPressed: _save),
          ),
        ]),
      ),
    );
  }
}
