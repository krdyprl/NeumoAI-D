class SymptomOption {
  const SymptomOption({required this.id, required this.label, required this.icon, required this.desc});

  final String id;
  final String label;
  final String icon;
  final String desc;
}

const symptoms = <SymptomOption>[
  SymptomOption(id: 'demam', label: 'Demam', icon: '🌡️', desc: 'Suhu > 37,5°C'),
  SymptomOption(id: 'batuk', label: 'Batuk', icon: '🤧', desc: 'Kering / berdahak'),
  SymptomOption(id: 'pilek', label: 'Pilek', icon: '🤧', desc: 'Hidung tersumbat'),
  SymptomOption(id: 'sesak', label: 'Sulit bernapas', icon: '😅💨', desc: 'Napas cepat/terdengar berat'),
  SymptomOption(id: 'nafsu', label: 'Kehilangan nafsu makan', icon: '🍽️', desc: 'Malas makan/minum'),
  SymptomOption(id: 'lemah', label: 'Tampak lemas', icon: '😴', desc: 'Kurang aktif dari biasanya'),
  SymptomOption(id: 'mengi', label: 'Suara mengi', icon: '🔊', desc: "Bunyi 'ngik' saat bernapas"),
  SymptomOption(id: 'muntah', label: 'Muntah', icon: '🤢', desc: 'Setelah batuk / saat makan'),
];
