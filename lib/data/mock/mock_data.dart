import '../../models/app_notification.dart';
import '../../models/article.dart';
import '../../models/child.dart';
import '../../models/enums.dart';
import '../../models/growth_record.dart';
import '../../models/health_center.dart';
import '../../models/profile.dart';
import '../../models/screening.dart';
import '../../models/vaccination.dart';

abstract final class MockData {
  static const profile = Profile(
    name: 'Ibu Sari',
    email: 'ibu.sari@gmail.com',
    phone: '+62 812-3456-7890',
    emoji: '👩',
    role: 'Orang Tua',
  );

  static const children = <Child>[
    Child(
      id: 'c1',
      name: 'Arya Putra',
      gender: Gender.male,
      birthDate: '2023-03-14',
      birthWeight: 3.2,
      weight: 13.5,
      height: 92,
      emoji: '👦',
      medicalHistory: 'Tidak ada alergi. Riwayat ISPA ringan saat usia 1 tahun.',
      vaccinations: [
        Vaccination(id: 'v1', name: 'BCG', date: '2023-03-20', done: true),
        Vaccination(id: 'v2', name: 'DPT-HB-Hib 1', date: '2023-06-14', done: true),
        Vaccination(id: 'v3', name: 'Campak Rubella', date: '2024-03-14', done: true),
        Vaccination(id: 'v4', name: 'Booster DPT', date: '2026-09-01', done: false),
      ],
    ),
    Child(
      id: 'c2',
      name: 'Anya Putri',
      gender: Gender.female,
      birthDate: '2025-11-02',
      birthWeight: 3.0,
      weight: 8.2,
      height: 71,
      emoji: '👧',
      medicalHistory: 'Lahir cukup bulan. Tidak ada riwayat penyakit kronis.',
      vaccinations: [
        Vaccination(id: 'v5', name: 'BCG', date: '2025-11-08', done: true),
        Vaccination(id: 'v6', name: 'Polio 1', date: '2025-12-02', done: true),
        Vaccination(id: 'v7', name: 'DPT-HB-Hib 2', date: '2026-07-01', done: false),
      ],
    ),
  ];

  static const screenings = <Screening>[
    Screening(
      id: 's1', childId: 'c1', date: '2026-07-31T09:14:00',
      symptoms: ['batuk', 'demam', 'sesak'], audioDuration: 5,
      riskLevel: RiskLevel.high, disease: 'Pneumonia', confidence: 87,
      status: SyncStatus.synced,
    ),
    Screening(
      id: 's2', childId: 'c1', date: '2026-07-30T14:00:00',
      symptoms: ['batuk', 'pilek'], audioDuration: 4,
      riskLevel: RiskLevel.medium, disease: 'Pneumonia', confidence: 62,
      status: SyncStatus.synced,
    ),
    Screening(
      id: 's3', childId: 'c1', date: '2026-03-20T10:00:00',
      symptoms: ['batuk'], audioDuration: 3,
      riskLevel: RiskLevel.low, disease: 'Pneumonia', confidence: 18,
      status: SyncStatus.synced,
    ),
    Screening(
      id: 's4', childId: 'c2', date: '2026-07-10T08:30:00',
      symptoms: ['demam', 'batuk'], audioDuration: 4,
      riskLevel: RiskLevel.low, disease: 'Pneumonia', confidence: 22,
      status: SyncStatus.synced,
    ),
  ];

  static const articles = <Article>[
    Article(id: 'a1', title: 'Kenali 4 Tanda Bahaya Napas Cepat pada Anak', category: 'Pneumonia', readTime: '4 menit', tag: 'Penting'),
    Article(id: 'a2', title: 'Kapan Batuk Si Kecil Bisa Jadi Gejala Pneumonia?', category: 'Pneumonia', readTime: '5 menit', tag: 'Edukasi'),
    Article(id: 'a3', title: 'Panduan Menghitung Napas per Menit Sesuai Usia', category: 'Deteksi', readTime: '3 menit', tag: 'Panduan'),
    Article(id: 'a4', title: 'Pneumonia vs Batuk Biasa: Apa Bedanya?', category: 'Pneumonia', readTime: '6 menit', tag: 'Edukasi'),
    Article(id: 'a5', title: 'Nutrisi untuk Memperkuat Daya Tahan Anak', category: 'Gizi', readTime: '4 menit', tag: 'Tips'),
    Article(id: 'a6', title: 'Pertolongan Pertama saat Anak Sesak Napas', category: 'Darurat', readTime: '3 menit', tag: 'Darurat'),
  ];

  static const notifications = <AppNotification>[
    AppNotification(id: 'n1', type: NotifType.ai, title: 'Hasil skrining Arya tersedia', body: 'AI mendeteksi indikasi pneumonia dengan kepercayaan 87%. Lihat rekomendasi dokter.', time: '09.14', read: false),
    AppNotification(id: 'n2', type: NotifType.medical, title: 'Saran dari dr. Rina', body: 'Segera bawa Arya ke puskesmas terdekat untuk pemeriksaan lanjutan.', time: '10.20', read: false),
    AppNotification(id: 'n3', type: NotifType.vaccination, title: 'Jadwal vaksinasi Anya', body: 'DPT-HB-Hib 2 dijadwalkan 1 Agustus. Jangan lupa kunjungi posyandu.', time: 'Kemarin', read: true),
    AppNotification(id: 'n4', type: NotifType.reminder, title: 'Waktunya skrining ulang', body: 'Sudah 30 hari sejak skrining terakhir Arya. Lakukan pemantauan rutin.', time: '3 hari lalu', read: true),
  ];

  static const centers = <HealthCenter>[
    HealthCenter(id: 'h1', name: 'Puskesmas Kedungkandang', distance: '1,2 km', address: 'Jl. Mayjen Sungkono No.54', rating: 4.6, open: true),
    HealthCenter(id: 'h2', name: 'RSIA Melati Husada', distance: '2,8 km', address: 'Jl. Kapten Tendean No.21', rating: 4.8, open: true),
    HealthCenter(id: 'h3', name: 'Puskesmas Bareng', distance: '3,1 km', address: 'Jl. Kerto Raharjo No.12', rating: 4.5, open: false),
  ];

  static const growth = <String, List<GrowthRecord>>{
    'c1': [
      GrowthRecord(month: 'Agu', weight: 13.8, height: 91),
      GrowthRecord(month: 'Sep', weight: 13.4, height: 91.5),
      GrowthRecord(month: 'Okt', weight: 13.1, height: 92),
      GrowthRecord(month: 'Nov', weight: 12.9, height: 92.5),
      GrowthRecord(month: 'Des', weight: 13.0, height: 93),
      GrowthRecord(month: 'Jan', weight: 13.3, height: 93.5),
      GrowthRecord(month: 'Feb', weight: 13.5, height: 94),
    ],
    'c2': [
      GrowthRecord(month: 'Jan', weight: 7.9, height: 69),
      GrowthRecord(month: 'Feb', weight: 8.0, height: 70),
      GrowthRecord(month: 'Mar', weight: 8.1, height: 70.5),
      GrowthRecord(month: 'Apr', weight: 8.2, height: 71),
    ],
  };
}
