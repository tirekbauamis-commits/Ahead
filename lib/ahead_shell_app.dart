// ignore_for_file: curly_braces_in_flow_control_structures, prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_string_interpolations, use_key_in_widget_constructors, use_build_context_synchronously, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'account_storage_stub.dart'
    if (dart.library.html) 'account_storage_web.dart'
    if (dart.library.io) 'account_storage_io.dart';
import 'auth_api_stub.dart'
    if (dart.library.html) 'auth_api_web.dart'
    if (dart.library.io) 'auth_api_io.dart';
import 'google_sign_in_web_button.dart' as google_web;

const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

class AheadShellApp extends StatelessWidget {
  const AheadShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: aheadStore.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AHEAD',
          debugShowCheckedModeBanner: false,
          theme: _appTheme(Brightness.light),
          darkTheme: _appTheme(Brightness.dark),
          themeMode: mode,
          home: const SplashPage(),
        );
      },
    );
  }

  ThemeData _appTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AheadColors.blue,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Inter', 'Roboto', 'Arial'],
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF111827) : AheadColors.bg,
      cardColor: dark ? const Color(0xFF1F2937) : Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF243043) : Colors.white,
        hintStyle: TextStyle(
            color: dark ? const Color(0xFFB6C2D2) : AheadColors.muted),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: dark ? const Color(0xFFF8FAFC) : AheadColors.text,
            displayColor: dark ? Colors.white : AheadColors.navy,
          ),
    );
  }
}

class AheadColors {
  static const blue = Color(0xFF0758D8);
  static const blue2 = Color(0xFF2B6BF0);
  static const cyan = Color(0xFF03BFEA);
  static const navy = Color(0xFF101B34);
  static const text = Color(0xFF1E2638);
  static const muted = Color(0xFF647086);
  static const bg = Color(0xFFF4F7FB);
  static const card = Colors.white;
  static const softBlue = Color(0xFFE9F0FF);
  static const line = Color(0xFFE7EBF2);
  static const peach = Color(0xFFFFD8CE);
  static const danger = Color(0xFFB31818);
  static const success = Color(0xFF16B886);
}

final AheadStore aheadStore = AheadStore();

class AheadUser {
  AheadUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordDigest,
    required this.classLevel,
    required this.major,
    this.provider = 'email',
    this.photoUrl,
  });

  final int id;
  String name;
  String email;
  String passwordDigest;
  String classLevel;
  String major;
  String provider;
  String? photoUrl;

  final Map<int, int> materialProgress = {};
  final Map<int, int> materialRatings = {};
  final Set<int> savedMaterialIds = {};
  final List<PracticeResult> practiceResults = [];
  final List<ExamResult> examResults = [];
  final List<ExamScheduleItem> examSchedules = [];
  final List<StudyPlanItem> studyPlans = [];
  final List<NoteItem> notes = [];
  final List<String> history = [];
  final List<AppNotification> notifications = [];
  final List<AiMessage> aiMessages = [];

  int get materialMastery {
    if (materialProgress.isEmpty) return 0;
    final total =
        materialProgress.values.fold<int>(0, (sum, value) => sum + value);
    return (total / materialProgress.length).round().clamp(0, 100);
  }

  int get practiceScore {
    if (practiceResults.isEmpty) return 0;
    final total = practiceResults.fold<int>(0, (sum, item) => sum + item.score);
    return (total / practiceResults.length).round().clamp(0, 100);
  }

  int get examScore {
    if (examResults.isEmpty) return 0;
    final total = examResults.fold<int>(0, (sum, item) => sum + item.score);
    return (total / examResults.length).round().clamp(0, 100);
  }

  int get consistency => history.isEmpty ? 0 : min(100, history.length * 12);

  int get streakDays {
    if (history.isEmpty) return 0;
    return min(30, history.length);
  }

  int get aheadScore {
    final parts = [materialMastery, practiceScore, examScore, consistency];
    return (parts.fold<int>(0, (sum, value) => sum + value) / parts.length)
        .round();
  }
}

class SubjectItem {
  const SubjectItem(this.id, this.name, this.category, this.description,
      this.icon, this.tint);

  final int id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color tint;
}

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.content,
    required this.classLevel,
  });

  final int id;
  final int subjectId;
  final String title;
  final String description;
  final String content;
  final String classLevel;
}

class MaterialSlide {
  const MaterialSlide({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class QuestionItem {
  const QuestionItem({
    required this.id,
    required this.subjectId,
    required this.materialId,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
  });

  final int id;
  final int subjectId;
  final int materialId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String difficulty;
}

class ExamItem {
  const ExamItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.subjectId,
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final int durationMinutes;
  final int totalQuestions;
  final int subjectId;
}

class PracticeResult {
  PracticeResult({
    required this.title,
    required this.subjectId,
    required this.mode,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.durationMinutes,
    required this.createdAt,
    required this.answers,
    required this.confidences,
    required this.essayAnswers,
    this.rating,
  });

  final String title;
  final int subjectId;
  final String mode;
  final int score;
  final int correct;
  final int wrong;
  final int durationMinutes;
  final DateTime createdAt;
  final Map<int, int> answers;
  final Map<int, String> confidences;
  final Map<int, String> essayAnswers;
  int? rating;
}

enum PracticeMode {
  multipleChoice,
  essay,
}

extension PracticeModeLabel on PracticeMode {
  String get label =>
      this == PracticeMode.multipleChoice ? 'Pilihan Ganda' : 'Essay';
}

class ExamResult {
  ExamResult({
    required this.exam,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.durationMinutes,
    required this.createdAt,
  });

  final ExamItem exam;
  final int score;
  final int correct;
  final int wrong;
  final int unanswered;
  final int durationMinutes;
  final DateTime createdAt;
}

class ExamScheduleItem {
  ExamScheduleItem({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.type,
    required this.date,
    this.notes = '',
  });

  final String id;
  String title;
  int subjectId;
  String type;
  DateTime date;
  String notes;

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  DateTime get countdownTarget {
    final dateOnly = date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0 &&
        date.microsecond == 0;
    if (!dateOnly) return date;
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  String get dayLabel {
    if (daysLeft < 0) return 'Lewat ${daysLeft.abs()} hari';
    if (daysLeft == 0) return 'Hari ini';
    return '$daysLeft hari lagi';
  }

  Duration get remaining => countdownTarget.difference(DateTime.now());

  String get liveCountdownLabel => formatScheduleCountdown(remaining);
}

String formatScheduleCountdown(Duration remaining) {
  final late = remaining.isNegative;
  final duration = late ? -remaining : remaining;
  final totalDays = duration.inDays;
  final months = totalDays ~/ 30;
  final weeks = (totalDays % 30) ~/ 7;
  final days = totalDays % 7;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final parts = <String>[];

  if (months > 0) parts.add('$months bulan');
  if (weeks > 0) parts.add('$weeks minggu');
  if (days > 0) parts.add('$days hari');
  if (hours > 0 || parts.isNotEmpty) parts.add('$hours jam');
  if (minutes > 0 || parts.isNotEmpty) parts.add('$minutes menit');
  parts.add('$seconds detik');

  final text = parts.join(' ');
  return late ? 'Lewat $text' : '$text lagi';
}

class StudyPlanItem {
  StudyPlanItem(this.title, this.subject, this.date, this.duration,
      {this.completed = false});

  final String title;
  final String subject;
  final DateTime date;
  final int duration;
  bool completed;
}

class NoteItem {
  NoteItem(this.title, this.content, this.createdAt);

  String title;
  String content;
  DateTime createdAt;
}

class AppNotification {
  AppNotification(this.title, this.message, this.createdAt,
      {this.isRead = false});

  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
}

class AiMessage {
  const AiMessage(this.role, this.message);

  final String role;
  final String message;
}

class AiToolItem {
  const AiToolItem();
}

class AheadStore {
  final List<AheadUser> _users = [];
  final _storage = createAccountStorage();
  final _api = createAuthApi();
  AheadUser? currentUser;
  String? _authToken;
  int _nextUserId = 1;
  String? _resetEmail;
  String? _resetCode;
  bool _loaded = false;
  final ValueNotifier<int> revision = ValueNotifier(0);
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  String get _themeModeName =>
      themeMode.value == ThemeMode.dark ? 'dark' : 'light';

  void toggleThemeMode() {
    themeMode.value =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _queueSave();
  }

  final subjects = const [
    SubjectItem(
        1,
        'Biologi',
        'IPA',
        'Keanekaragaman hayati Indonesia, pelestarian lingkungan, perubahan lingkungan, global warming, virus dan peranannya.',
        Icons.eco_outlined,
        Color(0xFFDFF7EA)),
    SubjectItem(
        2,
        'Kimia',
        'IPA',
        'Kimia hijau, metode ilmiah, struktur atom, dan hukum-hukum dasar kimia.',
        Icons.science_outlined,
        Color(0xFFE7E3FF)),
    SubjectItem(
        3,
        'Fisika',
        'IPA',
        'Metode ilmiah, pengukuran fisik, energi terbarukan, dan pemanasan global.',
        Icons.bolt_outlined,
        Color(0xFFFFE9D8)),
    SubjectItem(
        4,
        'Sejarah',
        'IPS',
        'Pengantar ilmu sejarah, manusia, ruang dan waktu, jalur rempah, dan sejarah Indonesia awal.',
        Icons.history_edu_outlined,
        Color(0xFFFFE3DC)),
    SubjectItem(
        5,
        'Sosiologi',
        'IPS',
        'Fungsi sosiologi, gejala sosial, identitas diri, tindakan sosial, dan interaksi sosial.',
        Icons.groups_2_outlined,
        Color(0xFFE0E7FF)),
    SubjectItem(
        6,
        'Ekonomi',
        'IPS',
        'Konsep ilmu ekonomi, kelangkaan, kebutuhan manusia, pasar, dan lembaga keuangan.',
        Icons.payments_outlined,
        Color(0xFFFFF0C8)),
    SubjectItem(
        7,
        'Geografi',
        'IPS',
        'Konsep, prinsip, pendekatan geografi, peta, penginderaan jauh, dan SIG.',
        Icons.public_outlined,
        Color(0xFFDFF5FF)),
  ];

  late final List<MaterialItem> materials = [
    const MaterialItem(
      id: 1,
      subjectId: 1,
      title: 'Keanekaragaman Hayati Indonesia',
      description: 'Flora, fauna, ekosistem, dan upaya pelestarian.',
      classLevel: 'X',
      content:
          'Indonesia memiliki keanekaragaman hayati sangat tinggi karena berada di wilayah tropis, diapit dua benua dan dua samudra, serta memiliki banyak tipe ekosistem seperti hutan hujan, mangrove, savana, dan terumbu karang.\n\nTingkat keanekaragaman dapat dilihat pada gen, spesies, dan ekosistem. Contohnya variasi padi termasuk keanekaragaman gen, komodo dan orang utan termasuk keanekaragaman spesies, sedangkan hutan hujan dan padang lamun termasuk keanekaragaman ekosistem.\n\nPelestarian dilakukan dengan konservasi in-situ seperti taman nasional dan cagar alam, serta ex-situ seperti kebun raya, bank benih, dan penangkaran. Kesalahan umum siswa adalah menganggap pelestarian hanya melarang pemanfaatan, padahal prinsip pentingnya adalah pemanfaatan berkelanjutan agar alam tetap pulih.',
    ),
    const MaterialItem(
      id: 2,
      subjectId: 1,
      title: 'Virus dan Peranannya',
      description: 'Ciri virus, replikasi, dampak, dan manfaatnya.',
      classLevel: 'X',
      content:
          'Virus adalah partikel aseluler, artinya tidak tersusun atas sel seperti makhluk hidup lain. Struktur utamanya berupa materi genetik DNA atau RNA yang dibungkus kapsid protein, dan pada beberapa virus terdapat selubung tambahan.\n\nVirus hanya dapat bereplikasi di dalam sel hidup karena tidak memiliki organel dan metabolisme sendiri. Daur reproduksinya dapat berupa litik, ketika sel inang pecah, atau lisogenik, ketika materi genetik virus menyisip lebih dulu pada inang.\n\nPeranan virus tidak selalu merugikan. Virus dapat menyebabkan influenza, demam berdarah, atau Covid-19, tetapi juga dipakai dalam penelitian genetika, pembuatan vaksin, dan terapi tertentu. Kata kunci yang perlu diingat: aseluler, inang, kapsid, replikasi, litik, dan lisogenik.',
    ),
    const MaterialItem(
      id: 3,
      subjectId: 2,
      title: 'Kimia Hijau',
      description: 'Prinsip green chemistry untuk pembangunan berkelanjutan.',
      classLevel: 'X',
      content:
          'Kimia hijau adalah pendekatan kimia yang merancang bahan dan proses agar lebih aman bagi manusia dan lingkungan. Fokusnya bukan hanya membersihkan limbah, tetapi mencegah limbah sejak awal.\n\nPrinsip pentingnya meliputi pencegahan limbah, efisiensi atom, penggunaan pelarut yang lebih aman, hemat energi, bahan baku terbarukan, katalis, dan produk yang mudah terurai. Contohnya memakai katalis agar reaksi lebih efisien atau mengganti pelarut berbahaya dengan air jika memungkinkan.\n\nDalam soal, perhatikan apakah tindakan yang dilakukan mengurangi bahaya dari sumbernya. Kesalahan umum adalah mengira kimia hijau sama dengan daur ulang saja, padahal kimia hijau mencakup desain proses sejak tahap awal.',
    ),
    const MaterialItem(
      id: 4,
      subjectId: 2,
      title: 'Struktur Atom',
      description: 'Partikel penyusun atom dan model atom.',
      classLevel: 'X',
      content:
          'Atom tersusun atas inti atom dan elektron. Inti atom berisi proton bermuatan positif dan neutron tidak bermuatan, sedangkan elektron bermuatan negatif bergerak di sekitar inti pada tingkat energi tertentu.\n\nNomor atom menunjukkan jumlah proton. Nomor massa menunjukkan jumlah proton ditambah neutron. Pada atom netral, jumlah proton sama dengan jumlah elektron. Jika elektron lepas atau bertambah, atom berubah menjadi ion.\n\nKonfigurasi elektron membantu menjelaskan kecenderungan unsur berikatan, letak unsur dalam tabel periodik, dan sifat kimianya. Kesalahan umum adalah menukar nomor atom dengan nomor massa. Ingat: nomor atom = proton, nomor massa = proton + neutron.',
    ),
    const MaterialItem(
      id: 5,
      subjectId: 3,
      title: 'Besaran dan Satuan',
      description: 'Pengukuran fisik, besaran pokok, turunan, dan alat ukur.',
      classLevel: 'X',
      content:
          'Besaran fisika adalah sesuatu yang dapat diukur, memiliki nilai, dan dinyatakan dengan satuan. Besaran pokok dalam SI antara lain panjang, massa, waktu, suhu, kuat arus, jumlah zat, dan intensitas cahaya. Besaran turunan dibentuk dari gabungan besaran pokok, misalnya kecepatan, gaya, dan massa jenis.\n\nPengukuran harus memperhatikan alat ukur, skala terkecil, ketelitian, dan angka penting. Contohnya jangka sorong lebih teliti daripada penggaris untuk mengukur diameter benda kecil.\n\nDalam soal pengukuran, tulis dulu satuan yang digunakan dan ubah ke SI jika perlu. Kesalahan umum adalah menghitung dengan satuan campur, misalnya cm dan m digabung tanpa konversi.',
    ),
    const MaterialItem(
      id: 6,
      subjectId: 3,
      title: 'Energi Terbarukan',
      description:
          'Sumber energi alternatif dan kaitannya dengan pemanasan global.',
      classLevel: 'X',
      content:
          'Energi terbarukan berasal dari sumber yang dapat pulih secara alami dalam waktu relatif singkat, seperti matahari, angin, air, panas bumi, dan biomassa. Energi ini penting karena cadangan energi fosil terbatas dan pembakarannya menghasilkan gas rumah kaca.\n\nContoh penerapannya adalah panel surya untuk mengubah cahaya menjadi listrik, turbin angin untuk memanfaatkan energi gerak udara, PLTA dari aliran air, dan panas bumi dari aktivitas geotermal.\n\nKelebihannya adalah emisi lebih rendah dan sumbernya berkelanjutan. Tantangannya meliputi biaya awal, lokasi, cuaca, dan penyimpanan energi. Hubungkan materi ini dengan pemanasan global: semakin rendah emisi, semakin kecil kontribusi terhadap peningkatan suhu bumi.',
    ),
    const MaterialItem(
      id: 7,
      subjectId: 4,
      title: 'Pengantar Ilmu Sejarah',
      description: 'Manusia, ruang, waktu, dan cara berpikir sejarah.',
      classLevel: 'X',
      content:
          'Sejarah adalah ilmu yang mempelajari kehidupan manusia pada masa lalu berdasarkan sumber yang dapat ditelusuri dan diuji. Sejarah bukan sekadar menghafal tanggal, tetapi memahami perubahan, keberlanjutan, sebab, akibat, dan sudut pandang pelaku sejarah.\n\nTiga unsur penting sejarah adalah manusia, ruang, dan waktu. Manusia menjadi pelaku peristiwa, ruang menunjukkan tempat peristiwa terjadi, dan waktu menjelaskan urutan serta konteks peristiwa.\n\nSumber sejarah dapat berupa lisan, tulisan, benda, audio visual, atau digital. Dalam analisis sejarah, bias sumber perlu diperhatikan. Pertanyaan kunci: siapa pelakunya, di mana, kapan, mengapa terjadi, dan apa dampaknya.',
    ),
    const MaterialItem(
      id: 8,
      subjectId: 4,
      title: 'Jalur Rempah Indonesia',
      description:
          'Perdagangan rempah dan perkembangan sejarah Indonesia awal.',
      classLevel: 'X',
      content:
          'Jalur rempah adalah jaringan perdagangan rempah yang menghubungkan Nusantara dengan India, Tiongkok, Timur Tengah, hingga Eropa. Rempah seperti cengkih, pala, lada, dan kayu manis sangat bernilai karena digunakan untuk makanan, obat, pengawetan, dan simbol status.\n\nJalur ini membentuk kota pelabuhan, mempertemukan pedagang dari berbagai bangsa, dan mendorong pertukaran budaya, bahasa, agama, teknologi, serta politik. Karena rempah bernilai tinggi, banyak kekuatan asing tertarik menguasai sumber dan jalur perdagangannya.\n\nDalam soal, jangan hanya melihat jalur rempah sebagai kegiatan ekonomi. Dampaknya luas: perdagangan, migrasi, budaya, munculnya jaringan kekuasaan, dan perubahan masyarakat pesisir.',
    ),
    const MaterialItem(
      id: 9,
      subjectId: 5,
      title: 'Gejala Sosial dan Identitas Diri',
      description: 'Fungsi sosiologi, tindakan sosial, dan interaksi sosial.',
      classLevel: 'X',
      content:
          'Sosiologi mempelajari masyarakat, interaksi sosial, dan gejala sosial. Gejala sosial adalah peristiwa atau pola perilaku yang muncul dari hubungan antarindividu atau kelompok, misalnya kerja sama, konflik, perubahan gaya hidup, atau penyimpangan sosial.\n\nIdentitas diri terbentuk melalui proses sosialisasi, yaitu pembelajaran nilai dan norma dari keluarga, sekolah, teman sebaya, media, dan masyarakat. Tindakan sosial terjadi ketika seseorang bertindak dengan mempertimbangkan orang lain.\n\nSaat menganalisis kasus, cari pelaku, bentuk interaksi, nilai atau norma yang terlibat, faktor penyebab, dan dampaknya. Kesalahan umum adalah menjawab dengan opini pribadi tanpa menghubungkannya ke konsep sosial.',
    ),
    const MaterialItem(
      id: 10,
      subjectId: 6,
      title: 'Masalah Ekonomi',
      description: 'Kelangkaan sumber daya dan pemenuhan kebutuhan manusia.',
      classLevel: 'X',
      content:
          'Masalah ekonomi muncul karena kebutuhan manusia tidak terbatas, sedangkan sumber daya untuk memenuhinya terbatas. Kondisi ini disebut kelangkaan. Karena ada kelangkaan, manusia harus memilih dan menyusun skala prioritas.\n\nPilihan ekonomi menimbulkan biaya peluang, yaitu nilai dari pilihan terbaik yang dikorbankan. Contohnya jika uang dipakai membeli buku, kesempatan membeli barang lain harus ditunda.\n\nKegiatan ekonomi terdiri dari produksi, distribusi, dan konsumsi. Dalam soal, perhatikan kata kunci kebutuhan, keinginan, kelangkaan, prioritas, dan biaya peluang. Jawaban yang baik menjelaskan alasan memilih, bukan hanya menyebut pilihan.',
    ),
    const MaterialItem(
      id: 11,
      subjectId: 6,
      title: 'Pasar dan Lembaga Keuangan',
      description: 'Mekanisme pasar, bank, dan lembaga keuangan non-bank.',
      classLevel: 'X',
      content:
          'Pasar adalah tempat atau mekanisme bertemunya permintaan dan penawaran. Harga terbentuk melalui interaksi pembeli dan penjual. Jika permintaan naik sementara penawaran tetap, harga cenderung naik. Jika penawaran naik sementara permintaan tetap, harga cenderung turun.\n\nLembaga keuangan membantu mengalirkan dana dari pihak yang memiliki kelebihan dana kepada pihak yang membutuhkan dana. Bank menghimpun simpanan dan menyalurkan kredit. Lembaga non-bank meliputi koperasi, asuransi, pegadaian, dana pensiun, dan pasar modal.\n\nDalam soal, bedakan fungsi pasar sebagai pembentuk harga dan fungsi lembaga keuangan sebagai perantara dana. Keduanya saling mendukung aktivitas ekonomi.',
    ),
    const MaterialItem(
      id: 12,
      subjectId: 7,
      title: 'Konsep Dasar Geografi',
      description:
          'Konsep, prinsip, pendekatan, peta, penginderaan jauh, dan SIG.',
      classLevel: 'X',
      content:
          'Geografi mempelajari gejala geosfer dengan sudut pandang keruangan, lingkungan, dan kewilayahan. Objek kajiannya mencakup litosfer, atmosfer, hidrosfer, biosfer, dan antroposfer.\n\nKonsep dasar geografi meliputi lokasi, jarak, keterjangkauan, pola, morfologi, aglomerasi, nilai guna, interaksi, diferensiasi area, dan keterkaitan ruang. Prinsip geografi meliputi persebaran, interelasi, deskripsi, dan korologi.\n\nPeta menyajikan informasi lokasi dan karakter wilayah. Penginderaan jauh memperoleh data dari sensor seperti satelit. SIG mengolah, menyimpan, menganalisis, dan menampilkan data spasial. Dalam soal, tentukan dulu fenomenanya, lokasinya, pola persebarannya, lalu hubungan antarwilayahnya.',
    ),
    const MaterialItem(
      id: 13,
      subjectId: 1,
      title: 'Pelestarian Lingkungan',
      description:
          'Konservasi, daya dukung, pencemaran, dan pemulihan ekosistem.',
      classLevel: 'X',
      content:
          'Pelestarian lingkungan bertujuan menjaga keseimbangan antara kebutuhan manusia dan kemampuan alam untuk pulih. Konsep pentingnya meliputi daya dukung, daya tampung, konservasi, pencemaran, dan pemanfaatan berkelanjutan.\n\nPencemaran dapat terjadi di air, udara, dan tanah. Dampaknya tidak hanya merusak makhluk hidup, tetapi juga mengubah rantai makanan, menurunkan kesehatan manusia, dan melemahkan fungsi ekosistem.\n\nUpaya pelestarian dapat dilakukan melalui pengurangan limbah, restorasi habitat, reboisasi, penggunaan energi bersih, dan edukasi masyarakat. Dalam soal, cari hubungan antara aktivitas manusia, kerusakan lingkungan, dan solusi yang paling tepat.',
    ),
    const MaterialItem(
      id: 14,
      subjectId: 1,
      title: 'Perubahan Lingkungan dan Global Warming',
      description: 'Efek rumah kaca, perubahan iklim, dan adaptasi lingkungan.',
      classLevel: 'X',
      content:
          'Pemanasan global terjadi karena peningkatan gas rumah kaca seperti karbon dioksida, metana, dan dinitrogen oksida. Gas ini menahan panas di atmosfer sehingga suhu rata-rata bumi meningkat.\n\nDampaknya meliputi cuaca ekstrem, naiknya permukaan laut, terganggunya habitat, perubahan pola tanam, dan meningkatnya risiko penyakit. Perubahan lingkungan dapat dipicu oleh pembakaran bahan bakar fosil, deforestasi, industri, dan konsumsi berlebihan.\n\nMitigasi dilakukan dengan mengurangi penyebab, misalnya hemat energi dan energi terbarukan. Adaptasi dilakukan dengan menyesuaikan diri terhadap dampak, misalnya sistem peringatan dini dan tata kota tahan banjir.',
    ),
    const MaterialItem(
      id: 15,
      subjectId: 1,
      title: 'Klasifikasi Makhluk Hidup',
      description: 'Ciri makhluk hidup, taksonomi, dan kunci determinasi.',
      classLevel: 'X',
      content:
          'Klasifikasi makhluk hidup membantu ilmuwan mengelompokkan organisme berdasarkan persamaan dan perbedaan ciri. Tingkatan takson dimulai dari kingdom, filum atau divisi, kelas, ordo, famili, genus, sampai spesies.\n\nDasar klasifikasi dapat berupa struktur tubuh, cara memperoleh makanan, habitat, alat gerak, reproduksi, dan hubungan kekerabatan. Nama ilmiah memakai sistem binomial nomenclature, yaitu genus dan spesies.\n\nKunci determinasi digunakan untuk mengenali organisme melalui pilihan ciri yang berpasangan. Saat mengerjakan soal, perhatikan ciri pembeda yang paling spesifik agar tidak salah menentukan kelompok.',
    ),
    const MaterialItem(
      id: 16,
      subjectId: 2,
      title: 'Metode Ilmiah Kimia',
      description:
          'Observasi, hipotesis, variabel, eksperimen, dan kesimpulan.',
      classLevel: 'X',
      content:
          'Metode ilmiah adalah langkah sistematis untuk menjawab pertanyaan berdasarkan bukti. Tahapannya meliputi observasi, merumuskan masalah, membuat hipotesis, menentukan variabel, melakukan eksperimen, menganalisis data, dan menyusun kesimpulan.\n\nDalam eksperimen kimia, variabel bebas adalah faktor yang diubah, variabel terikat adalah hasil yang diamati, dan variabel kontrol adalah faktor yang dibuat tetap. Kesimpulan harus sesuai data, bukan sekadar dugaan.\n\nKeselamatan kerja penting karena bahan kimia dapat bersifat mudah terbakar, korosif, beracun, atau iritan. Simbol bahaya dan prosedur laboratorium harus dibaca sebelum percobaan.',
    ),
    const MaterialItem(
      id: 17,
      subjectId: 2,
      title: 'Hukum Dasar Kimia',
      description:
          'Kekekalan massa, perbandingan tetap, dan perhitungan sederhana.',
      classLevel: 'X',
      content:
          'Hukum dasar kimia menjelaskan pola kuantitatif dalam reaksi. Hukum kekekalan massa menyatakan bahwa massa total zat sebelum dan sesudah reaksi tetap sama jika sistem tertutup.\n\nHukum perbandingan tetap menyatakan bahwa suatu senyawa murni selalu memiliki perbandingan massa unsur penyusun yang tetap. Contohnya air selalu tersusun dari hidrogen dan oksigen dengan perbandingan tertentu.\n\nDalam soal, tuliskan data massa yang diketahui, cari hubungan perbandingan, lalu pastikan satuan sama. Kesalahan umum adalah menjumlahkan massa tanpa memperhatikan zat yang bereaksi dan sisa zat.',
    ),
    const MaterialItem(
      id: 18,
      subjectId: 2,
      title: 'Tabel Periodik Unsur',
      description:
          'Golongan, periode, sifat periodik, logam, nonlogam, dan metaloid.',
      classLevel: 'X',
      content:
          'Tabel periodik menyusun unsur berdasarkan nomor atom dan kemiripan sifat. Baris disebut periode, sedangkan kolom disebut golongan. Unsur segolongan biasanya memiliki elektron valensi yang mirip sehingga sifat kimianya juga mirip.\n\nSifat periodik meliputi jari-jari atom, energi ionisasi, elektronegativitas, dan afinitas elektron. Secara umum, sifat tersebut berubah teratur dari kiri ke kanan dan dari atas ke bawah.\n\nLogam cenderung mengkilap, menghantarkan listrik, dan mudah melepas elektron. Nonlogam cenderung menerima elektron. Metaloid memiliki sifat antara logam dan nonlogam.',
    ),
    const MaterialItem(
      id: 19,
      subjectId: 3,
      title: 'Metode Ilmiah Fisika',
      description: 'Pengamatan, model, eksperimen, data, dan grafik.',
      classLevel: 'X',
      content:
          'Fisika mempelajari gejala alam melalui pengamatan, pengukuran, model, dan eksperimen. Model digunakan untuk menyederhanakan kenyataan sehingga hubungan antarbesaran dapat dianalisis.\n\nData eksperimen dapat ditampilkan dalam tabel atau grafik. Grafik membantu melihat pola, misalnya hubungan linear, berbanding terbalik, atau perubahan yang tidak tetap.\n\nKesimpulan fisika harus didukung data dan satuan yang jelas. Jika hasil percobaan berbeda dari teori, periksa alat ukur, ketelitian, kesalahan paralaks, dan variabel yang belum dikontrol.',
    ),
    const MaterialItem(
      id: 20,
      subjectId: 3,
      title: 'Pemanasan Global',
      description:
          'Gas rumah kaca, radiasi, dampak suhu bumi, dan solusi energi.',
      classLevel: 'X',
      content:
          'Pemanasan global dalam fisika berkaitan dengan energi radiasi matahari dan kemampuan atmosfer menahan panas. Efek rumah kaca alami diperlukan, tetapi menjadi masalah ketika gas rumah kaca meningkat berlebihan.\n\nEnergi yang masuk dan keluar bumi harus seimbang. Jika panas lebih banyak tertahan, suhu rata-rata meningkat. Dampaknya dapat terlihat pada cuaca ekstrem, pencairan es, dan perubahan ekosistem.\n\nSolusi fisika berkaitan dengan efisiensi energi, teknologi energi terbarukan, transportasi rendah emisi, dan desain bangunan hemat energi. Dalam soal, hubungkan sumber energi dengan perubahan emisi.',
    ),
    const MaterialItem(
      id: 21,
      subjectId: 3,
      title: 'Gerak dan Gaya Dasar',
      description: 'Posisi, perpindahan, kecepatan, percepatan, dan gaya.',
      classLevel: 'X',
      content:
          'Gerak dipahami melalui posisi, jarak, perpindahan, kelajuan, kecepatan, dan percepatan. Jarak adalah panjang lintasan, sedangkan perpindahan adalah perubahan posisi dari titik awal ke titik akhir.\n\nKecepatan memperhatikan arah, sedangkan kelajuan hanya besar nilainya. Percepatan menunjukkan perubahan kecepatan tiap satuan waktu. Gaya dapat mengubah gerak, bentuk, atau arah benda.\n\nSaat mengerjakan soal, gambarkan situasi, tulis besaran yang diketahui, samakan satuan, lalu pilih rumus sesuai jenis gerak. Jangan menukar jarak dengan perpindahan jika soal menyebut arah.',
    ),
    const MaterialItem(
      id: 22,
      subjectId: 4,
      title: 'Manusia, Ruang, dan Waktu',
      description: 'Konsep dasar sejarah sebagai peristiwa yang berkonteks.',
      classLevel: 'X',
      content:
          'Sejarah selalu melibatkan manusia sebagai pelaku, ruang sebagai tempat, dan waktu sebagai urutan. Tanpa ketiga unsur ini, peristiwa sulit dianalisis secara historis.\n\nRuang memengaruhi kehidupan manusia melalui kondisi geografis, sumber daya, jalur perdagangan, dan hubungan dengan wilayah lain. Waktu membantu melihat perubahan, keberlanjutan, perkembangan, dan pengulangan peristiwa.\n\nDalam soal sejarah, jangan hanya menyebut tanggal. Jelaskan siapa pelakunya, di mana terjadi, kapan berlangsung, mengapa terjadi, dan bagaimana dampaknya terhadap masyarakat.',
    ),
    const MaterialItem(
      id: 23,
      subjectId: 4,
      title: 'Sumber Sejarah dan Penelitian',
      description: 'Heuristik, kritik sumber, interpretasi, dan historiografi.',
      classLevel: 'X',
      content:
          'Penelitian sejarah dimulai dari heuristik, yaitu mencari dan mengumpulkan sumber. Sumber dapat berupa tulisan, lisan, benda, visual, atau digital. Setelah itu dilakukan kritik sumber untuk menilai keaslian dan kredibilitasnya.\n\nInterpretasi adalah proses menafsirkan fakta sejarah agar menjadi penjelasan yang masuk akal. Historiografi adalah penulisan sejarah secara runtut berdasarkan hasil penelitian.\n\nBias sumber perlu diperhatikan karena setiap sumber dibuat dari sudut pandang tertentu. Jawaban yang baik membedakan fakta, pendapat, dan tafsir.',
    ),
    const MaterialItem(
      id: 24,
      subjectId: 4,
      title: 'Indonesia Masa Awal',
      description:
          'Masyarakat awal, migrasi, budaya, dan perkembangan Nusantara.',
      classLevel: 'X',
      content:
          'Perkembangan Indonesia masa awal dapat dipahami melalui kehidupan masyarakat praaksara, migrasi manusia, teknologi sederhana, pola hunian, dan sistem kepercayaan. Bukti sejarahnya berasal dari artefak, fosil, situs, dan tradisi lisan.\n\nMasyarakat awal menyesuaikan diri dengan alam melalui berburu, meramu, bercocok tanam, dan perdagangan sederhana. Perubahan teknologi membawa perubahan cara hidup.\n\nDalam soal, hubungkan bukti sejarah dengan pola kehidupan. Misalnya alat batu dapat menunjukkan aktivitas ekonomi, lingkungan, dan kemampuan teknologi masyarakat pada masa itu.',
    ),
    const MaterialItem(
      id: 25,
      subjectId: 5,
      title: 'Tindakan Sosial',
      description: 'Makna tindakan, tujuan pelaku, dan respons masyarakat.',
      classLevel: 'X',
      content:
          'Tindakan sosial adalah tindakan individu yang mempertimbangkan keberadaan orang lain. Artinya, tindakan tersebut memiliki makna sosial dan dapat memengaruhi atau dipengaruhi oleh respons orang lain.\n\nTindakan sosial dapat berorientasi tujuan, nilai, emosi, atau kebiasaan. Contohnya mengikuti aturan sekolah karena ingin tertib, membantu teman karena nilai solidaritas, atau memberi komentar karena dorongan emosi.\n\nSaat menganalisis kasus, cari pelaku, tujuan tindakan, pihak yang terlibat, norma yang berlaku, dan dampaknya. Jangan menjawab hanya berdasarkan suka atau tidak suka.',
    ),
    const MaterialItem(
      id: 26,
      subjectId: 5,
      title: 'Interaksi Sosial',
      description:
          'Kontak sosial, komunikasi, kerja sama, konflik, dan akomodasi.',
      classLevel: 'X',
      content:
          'Interaksi sosial terjadi ketika ada kontak sosial dan komunikasi. Kontak dapat langsung atau tidak langsung, sedangkan komunikasi melibatkan pesan, media, penerima, dan pemaknaan.\n\nBentuk interaksi sosial dapat bersifat asosiatif seperti kerja sama, akomodasi, dan asimilasi, atau disosiatif seperti persaingan, kontravensi, dan konflik.\n\nDalam soal, tentukan dulu bentuk interaksinya. Jika hubungan mengarah pada persatuan, biasanya termasuk asosiatif. Jika mengarah pada pertentangan atau persaingan, termasuk disosiatif.',
    ),
    const MaterialItem(
      id: 27,
      subjectId: 5,
      title: 'Nilai dan Norma Sosial',
      description: 'Pedoman perilaku, sanksi, keteraturan, dan penyimpangan.',
      classLevel: 'X',
      content:
          'Nilai sosial adalah sesuatu yang dianggap baik, penting, atau berharga oleh masyarakat. Norma sosial adalah aturan yang mengatur perilaku agar sesuai dengan nilai tersebut.\n\nNorma dapat berupa cara, kebiasaan, tata kelakuan, adat, atau hukum. Setiap norma memiliki sanksi yang berbeda, mulai dari teguran ringan sampai hukuman formal.\n\nPenyimpangan sosial terjadi ketika perilaku tidak sesuai dengan norma. Namun analisis sosiologi perlu melihat faktor penyebab, dampak, dan upaya pengendalian sosial secara objektif.',
    ),
    const MaterialItem(
      id: 28,
      subjectId: 5,
      title: 'Sosialisasi dan Pembentukan Identitas',
      description: 'Agen sosialisasi, peran, status, dan identitas diri.',
      classLevel: 'X',
      content:
          'Sosialisasi adalah proses belajar nilai, norma, peran, dan kebiasaan masyarakat. Agen sosialisasi meliputi keluarga, sekolah, teman sebaya, media massa, dan lingkungan kerja.\n\nIdentitas diri terbentuk melalui interaksi dengan lingkungan. Seseorang belajar menjadi anggota masyarakat melalui peran dan status yang dijalankan dalam kehidupan sehari-hari.\n\nDalam soal, perhatikan agen sosialisasi yang paling berpengaruh. Media sosial, misalnya, dapat membentuk gaya bahasa, pilihan pertemanan, dan cara seseorang menampilkan diri.',
    ),
    const MaterialItem(
      id: 29,
      subjectId: 6,
      title: 'Kebutuhan dan Skala Prioritas',
      description: 'Kebutuhan, keinginan, prioritas, dan pilihan ekonomi.',
      classLevel: 'X',
      content:
          'Kebutuhan adalah sesuatu yang harus dipenuhi agar manusia dapat hidup layak, sedangkan keinginan adalah hasrat yang tidak selalu mendesak. Karena sumber daya terbatas, manusia perlu menyusun skala prioritas.\n\nSkala prioritas membantu menentukan kebutuhan mana yang paling penting, paling mendesak, dan paling bermanfaat. Faktor yang memengaruhi kebutuhan meliputi usia, pendapatan, lingkungan, pendidikan, dan budaya.\n\nDalam soal ekonomi, bedakan kebutuhan primer, sekunder, dan tersier. Jawaban harus menjelaskan alasan pemilihan, bukan hanya menyebut barang yang dipilih.',
    ),
    const MaterialItem(
      id: 30,
      subjectId: 6,
      title: 'Biaya Peluang',
      description: 'Pilihan terbaik yang dikorbankan saat mengambil keputusan.',
      classLevel: 'X',
      content:
          'Biaya peluang adalah nilai dari pilihan terbaik yang harus dikorbankan ketika seseorang memilih satu alternatif. Konsep ini muncul karena manusia tidak bisa memenuhi semua kebutuhan sekaligus.\n\nContohnya siswa memilih mengikuti les matematika daripada bekerja paruh waktu. Biaya peluangnya adalah penghasilan atau pengalaman kerja yang dikorbankan.\n\nSaat menghitung biaya peluang, cari alternatif terbaik yang tidak dipilih. Jangan menjumlahkan semua alternatif yang ditinggalkan, karena biaya peluang hanya pilihan terbaik berikutnya.',
    ),
    const MaterialItem(
      id: 31,
      subjectId: 6,
      title: 'Kegiatan Produksi dan Konsumsi',
      description:
          'Produsen, konsumen, distribusi, nilai guna, dan faktor produksi.',
      classLevel: 'X',
      content:
          'Produksi adalah kegiatan menghasilkan atau menambah nilai guna barang dan jasa. Faktor produksi meliputi sumber daya alam, tenaga kerja, modal, dan kewirausahaan.\n\nDistribusi menyalurkan barang dari produsen ke konsumen. Konsumsi adalah kegiatan memakai atau menghabiskan nilai guna barang dan jasa untuk memenuhi kebutuhan.\n\nDalam soal, identifikasi pelaku ekonominya dulu: rumah tangga konsumen, produsen, pemerintah, atau masyarakat luar negeri. Lalu tentukan kegiatan ekonomi yang sedang terjadi.',
    ),
    const MaterialItem(
      id: 32,
      subjectId: 7,
      title: 'Peta dan Komponen Peta',
      description:
          'Skala, simbol, legenda, orientasi, koordinat, dan proyeksi.',
      classLevel: 'X',
      content:
          'Peta adalah gambaran permukaan bumi pada bidang datar dengan skala tertentu. Komponen peta meliputi judul, skala, legenda, simbol, orientasi, garis koordinat, inset, dan sumber peta.\n\nSkala menunjukkan perbandingan jarak di peta dengan jarak sebenarnya. Simbol membantu menyederhanakan objek, sedangkan legenda menjelaskan arti simbol.\n\nDalam soal peta, perhatikan satuan dan skala. Jika menghitung jarak sebenarnya, ubah jarak peta sesuai skala lalu konversi satuannya dengan teliti.',
    ),
    const MaterialItem(
      id: 33,
      subjectId: 7,
      title: 'Penginderaan Jauh',
      description:
          'Sensor, citra, resolusi, interpretasi, dan pemanfaatan data.',
      classLevel: 'X',
      content:
          'Penginderaan jauh adalah teknik memperoleh informasi objek tanpa kontak langsung, biasanya menggunakan sensor pada satelit atau pesawat. Data yang dihasilkan dapat berupa citra foto atau nonfoto.\n\nInterpretasi citra memperhatikan rona, warna, bentuk, ukuran, tekstur, pola, bayangan, situs, dan asosiasi. Resolusi menentukan detail objek yang dapat diamati.\n\nPenginderaan jauh digunakan untuk pemetaan hutan, perubahan lahan, bencana, cuaca, pertanian, dan tata kota. Dalam soal, cocokkan ciri citra dengan objek yang paling mungkin.',
    ),
    const MaterialItem(
      id: 34,
      subjectId: 7,
      title: 'Sistem Informasi Geografis',
      description: 'Input, pengolahan, analisis, dan penyajian data spasial.',
      classLevel: 'X',
      content:
          'Sistem Informasi Geografis atau SIG adalah sistem untuk mengumpulkan, menyimpan, mengolah, menganalisis, dan menampilkan data spasial. Data spasial menunjukkan lokasi, sedangkan data atribut menjelaskan karakteristik objek.\n\nTahap kerja SIG meliputi input data, manajemen data, analisis, dan output berupa peta, tabel, grafik, atau model. Analisis SIG dapat membantu menentukan lokasi sekolah, jalur evakuasi, atau zona rawan bencana.\n\nDalam soal, cari hubungan antara data lokasi dan tujuan analisis. SIG tidak hanya menggambar peta, tetapi membantu mengambil keputusan berbasis ruang.',
    ),
    const MaterialItem(
      id: 35,
      subjectId: 7,
      title: 'Pendekatan Geografi',
      description: 'Pendekatan keruangan, ekologi, dan kompleks wilayah.',
      classLevel: 'X',
      content:
          'Pendekatan geografi membantu menganalisis fenomena geosfer. Pendekatan keruangan menekankan lokasi, persebaran, pola, jarak, dan interaksi antarwilayah.\n\nPendekatan ekologi melihat hubungan antara manusia dan lingkungan. Pendekatan kompleks wilayah menggabungkan keruangan dan ekologi untuk memahami karakter wilayah secara menyeluruh.\n\nDalam soal, tentukan fokus analisisnya. Jika menanyakan persebaran, gunakan keruangan. Jika menanyakan hubungan manusia-lingkungan, gunakan ekologi. Jika membandingkan wilayah, gunakan kompleks wilayah.',
    ),
  ];

  late final List<QuestionItem> questions = _buildQuestions();

  List<QuestionItem> _buildQuestions() {
    var id = 1;
    final items = <QuestionItem>[];
    for (final material in materials) {
      final concepts = _conceptsForMaterial(material.id);
      for (var i = 0; i < 20; i++) {
        final concept = concepts[i % concepts.length];
        final correct =
            '$concept berkaitan langsung dengan ${material.description.toLowerCase()}';
        final distractors = [
          '$concept tidak perlu dipahami pada materi kelas 10.',
          '$concept hanya membahas hafalan tanpa hubungan dengan topik.',
          '$concept berarti semua data dan bukti boleh diabaikan.',
          '$concept selalu sama untuk semua mata pelajaran tanpa konteks.',
        ];
        final correctIndex = i % 5;
        final options = List<String>.from(distractors);
        options.insert(correctIndex, correct);
        items.add(QuestionItem(
          id: id++,
          subjectId: material.subjectId,
          materialId: material.id,
          question:
              'Pada materi ${material.title}, pernyataan paling tepat tentang $concept adalah...',
          options: options,
          correctIndex: correctIndex,
          explanation:
              '$concept menjadi kata kunci pada ${material.title}. Pahami kaitannya dengan materi utama: ${material.description}',
          difficulty: i < 7 ? 'Dasar' : (i < 14 ? 'Menengah' : 'Lanjutan'),
        ));
      }
    }
    return items;
  }

  List<String> _conceptsForMaterial(int materialId) {
    const data = {
      1: [
        'keanekaragaman hayati',
        'konservasi in-situ',
        'konservasi ex-situ',
        'ekosistem',
        'pelestarian lingkungan',
      ],
      2: ['virus', 'replikasi virus', 'sel inang', 'peranan virus', 'penyakit'],
      3: [
        'kimia hijau',
        'pencegahan limbah',
        'efisiensi energi',
        'bahan aman',
        'keberlanjutan'
      ],
      4: [
        'proton',
        'neutron',
        'elektron',
        'nomor atom',
        'konfigurasi elektron'
      ],
      5: [
        'besaran pokok',
        'satuan SI',
        'alat ukur',
        'angka penting',
        'ketelitian'
      ],
      6: [
        'energi matahari',
        'energi angin',
        'biomassa',
        'emisi',
        'pemanasan global'
      ],
      7: ['manusia', 'ruang', 'waktu', 'sumber sejarah', 'kronologi'],
      8: ['jalur rempah', 'perdagangan', 'Nusantara', 'akulturasi', 'maritim'],
      9: [
        'gejala sosial',
        'identitas diri',
        'tindakan sosial',
        'interaksi sosial',
        'nilai dan norma'
      ],
      10: [
        'kelangkaan',
        'kebutuhan',
        'skala prioritas',
        'pilihan',
        'biaya peluang'
      ],
      11: ['pasar', 'permintaan', 'penawaran', 'bank', 'lembaga keuangan'],
      12: [
        'konsep geografi',
        'prinsip geografi',
        'peta',
        'penginderaan jauh',
        'SIG'
      ],
      13: [
        'pelestarian',
        'daya dukung',
        'pencemaran',
        'restorasi',
        'ekosistem'
      ],
      14: ['efek rumah kaca', 'iklim', 'mitigasi', 'adaptasi', 'emisi'],
      15: [
        'taksonomi',
        'spesies',
        'genus',
        'kunci determinasi',
        'ciri organisme'
      ],
      16: [
        'observasi',
        'hipotesis',
        'variabel',
        'eksperimen',
        'keselamatan kerja'
      ],
      17: [
        'kekekalan massa',
        'perbandingan tetap',
        'massa zat',
        'reaksi',
        'data percobaan'
      ],
      18: [
        'golongan',
        'periode',
        'elektron valensi',
        'sifat periodik',
        'unsur'
      ],
      19: [
        'model fisika',
        'grafik',
        'data',
        'pengukuran',
        'kesalahan percobaan'
      ],
      20: ['radiasi', 'gas rumah kaca', 'suhu bumi', 'energi', 'efisiensi'],
      21: ['jarak', 'perpindahan', 'kecepatan', 'percepatan', 'gaya'],
      22: ['manusia', 'ruang', 'waktu', 'perubahan', 'keberlanjutan'],
      23: [
        'heuristik',
        'kritik sumber',
        'interpretasi',
        'historiografi',
        'bias sumber'
      ],
      24: ['praaksara', 'artefak', 'migrasi', 'teknologi', 'pola hunian'],
      25: ['tindakan sosial', 'makna', 'tujuan', 'nilai', 'respons sosial'],
      26: ['kontak sosial', 'komunikasi', 'kerja sama', 'konflik', 'akomodasi'],
      27: ['nilai sosial', 'norma', 'sanksi', 'penyimpangan', 'keteraturan'],
      28: ['sosialisasi', 'identitas', 'agen sosialisasi', 'peran', 'status'],
      29: ['kebutuhan', 'keinginan', 'prioritas', 'primer', 'sekunder'],
      30: [
        'biaya peluang',
        'alternatif',
        'pilihan',
        'pengorbanan',
        'keputusan'
      ],
      31: [
        'produksi',
        'distribusi',
        'konsumsi',
        'nilai guna',
        'faktor produksi'
      ],
      32: ['skala', 'legenda', 'simbol', 'koordinat', 'orientasi'],
      33: ['sensor', 'citra', 'resolusi', 'interpretasi', 'pemanfaatan'],
      34: ['data spasial', 'atribut', 'analisis SIG', 'overlay', 'output peta'],
      35: [
        'keruangan',
        'ekologi',
        'kompleks wilayah',
        'persebaran',
        'interaksi'
      ],
    };
    return data[materialId] ??
        ['konsep utama', 'contoh', 'analisis', 'data', 'simpulan'];
  }

  late final List<ExamItem> exams = [
    const ExamItem(
      id: 1,
      title: 'Simulasi PAS IPA Kelas X',
      description:
          'Ujian terpadu Biologi, Kimia, dan Fisika untuk mengukur kesiapan akhir semester.',
      type: 'UAS',
      durationMinutes: 90,
      totalQuestions: 50,
      subjectId: 1,
    ),
    const ExamItem(
      id: 2,
      title: 'Simulasi Biologi Kelas X',
      description: 'Keanekaragaman hayati, lingkungan, dan virus.',
      type: 'UTS',
      durationMinutes: 45,
      totalQuestions: 25,
      subjectId: 1,
    ),
    const ExamItem(
      id: 3,
      title: 'Asesmen Sumatif Fisika',
      description: 'Pengukuran, energi terbarukan, dan pemanasan global.',
      type: 'Sumatif',
      durationMinutes: 30,
      totalQuestions: 20,
      subjectId: 3,
    ),
    const ExamItem(
      id: 4,
      title: 'Simulasi PAS IPS Kelas X',
      description:
          'Ujian terpadu Sejarah, Sosiologi, Ekonomi, dan Geografi kelas X.',
      type: 'UAS',
      durationMinutes: 90,
      totalQuestions: 50,
      subjectId: 4,
    ),
    const ExamItem(
      id: 5,
      title: 'Simulasi Ekonomi Kelas X',
      description: 'Kelangkaan, kebutuhan, pasar, dan lembaga keuangan.',
      type: 'UTS',
      durationMinutes: 45,
      totalQuestions: 25,
      subjectId: 6,
    ),
    const ExamItem(
      id: 6,
      title: 'Asesmen Sumatif Geografi',
      description: 'Konsep geografi, peta, penginderaan jauh, dan SIG.',
      type: 'Sumatif',
      durationMinutes: 30,
      totalQuestions: 20,
      subjectId: 7,
    ),
  ];

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await _storage.read();
      if (raw == null || raw.trim().isEmpty) {
        _loaded = true;
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _loaded = true;
        return;
      }
      final data = _asMap(decoded);
      themeMode.value = _asString(data['themeMode'], 'light') == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      _users
        ..clear()
        ..addAll(_asList(data['users'])
            .whereType<Map>()
            .map((item) => _userFromJson(_asMap(item))));
      final maxId = _users.fold<int>(0, (value, user) => max(value, user.id));
      _nextUserId = max(_asInt(data['nextUserId'], maxId + 1), maxId + 1);
    } catch (_) {
      // Corrupt local data should not block the app from opening.
    } finally {
      _loaded = true;
    }
  }

  void persistNow() => _queueSave();

  void _queueSave() {
    if (!_loaded) return;
    revision.value++;
    unawaited(_save());
  }

  Future<void> _save() async {
    final data = {
      'version': 2,
      'nextUserId': _nextUserId,
      'themeMode': _themeModeName,
      'users': _users.map(_userToJson).toList(),
    };
    await _storage.write(jsonEncode(data));
  }

  Map<String, Object?> _userToJson(AheadUser user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'passwordDigest': user.passwordDigest,
        'classLevel': user.classLevel,
        'major': user.major,
        'provider': user.provider,
        'photoUrl': user.photoUrl,
        'materialProgress':
            user.materialProgress.map((key, value) => MapEntry('$key', value)),
        'materialRatings':
            user.materialRatings.map((key, value) => MapEntry('$key', value)),
        'savedMaterialIds': user.savedMaterialIds.toList(),
        'practiceResults': user.practiceResults.map(_practiceToJson).toList(),
        'examResults': user.examResults.map(_examToJson).toList(),
        'examSchedules': user.examSchedules.map(_scheduleToJson).toList(),
        'studyPlans': user.studyPlans.map(_studyPlanToJson).toList(),
        'notes': user.notes.map(_noteToJson).toList(),
        'history': user.history,
        'notifications': user.notifications.map(_notificationToJson).toList(),
        'aiMessages': user.aiMessages.map(_aiMessageToJson).toList(),
      };

  AheadUser _userFromJson(Map<String, dynamic> json) {
    final user = AheadUser(
      id: _asInt(json['id'], _nextUserId++),
      name: _asString(json['name'], 'Siswa'),
      email: _asString(json['email']).toLowerCase(),
      passwordDigest: _asString(json['passwordDigest']),
      classLevel: _asString(json['classLevel'], 'Kelas X'),
      major: _asString(json['major'], 'IPA') == 'IPS' ? 'IPS' : 'IPA',
      provider: _asString(json['provider'], 'email'),
      photoUrl: _nullableString(json['photoUrl']),
    );
    user.materialProgress.addAll(_intIntMap(json['materialProgress']));
    user.materialRatings.addAll(_intIntMap(json['materialRatings']));
    user.savedMaterialIds.addAll(_asList(json['savedMaterialIds'])
        .map((item) => _asInt(item))
        .where((item) => item > 0));
    user.practiceResults.addAll(_asList(json['practiceResults'])
        .whereType<Map>()
        .map((item) => _practiceFromJson(_asMap(item))));
    user.examResults.addAll(_asList(json['examResults'])
        .whereType<Map>()
        .map((item) => _examFromJson(_asMap(item))));
    user.examSchedules.addAll(_asList(json['examSchedules'])
        .whereType<Map>()
        .map((item) => _scheduleFromJson(_asMap(item))));
    user.studyPlans.addAll(_asList(json['studyPlans'])
        .whereType<Map>()
        .map((item) => _studyPlanFromJson(_asMap(item))));
    user.notes.addAll(_asList(json['notes'])
        .whereType<Map>()
        .map((item) => _noteFromJson(_asMap(item))));
    user.history.addAll(_asList(json['history']).map((item) => '$item'));
    user.notifications.addAll(_asList(json['notifications'])
        .whereType<Map>()
        .map((item) => _notificationFromJson(_asMap(item))));
    user.aiMessages.addAll(_asList(json['aiMessages'])
        .whereType<Map>()
        .map((item) => _aiMessageFromJson(_asMap(item))));
    return user;
  }

  Map<String, Object?> _practiceToJson(PracticeResult result) => {
        'title': result.title,
        'subjectId': result.subjectId,
        'mode': result.mode,
        'score': result.score,
        'correct': result.correct,
        'wrong': result.wrong,
        'durationMinutes': result.durationMinutes,
        'createdAt': result.createdAt.toIso8601String(),
        'answers': result.answers.map((key, value) => MapEntry('$key', value)),
        'confidences':
            result.confidences.map((key, value) => MapEntry('$key', value)),
        'essayAnswers':
            result.essayAnswers.map((key, value) => MapEntry('$key', value)),
        'rating': result.rating,
      };

  PracticeResult _practiceFromJson(Map<String, dynamic> json) => PracticeResult(
        title: _asString(json['title'], 'Latihan'),
        subjectId: _asInt(json['subjectId'], 1),
        mode: _asString(json['mode'], 'Pilihan Ganda'),
        score: _asInt(json['score']),
        correct: _asInt(json['correct']),
        wrong: _asInt(json['wrong']),
        durationMinutes: _asInt(json['durationMinutes']),
        createdAt: _asDate(json['createdAt']),
        answers: _intIntMap(json['answers']),
        confidences: _intStringMap(json['confidences']),
        essayAnswers: _intStringMap(json['essayAnswers']),
        rating: json['rating'] == null ? null : _asInt(json['rating']),
      );

  Map<String, Object?> _examToJson(ExamResult result) => {
        'examId': result.exam.id,
        'score': result.score,
        'correct': result.correct,
        'wrong': result.wrong,
        'unanswered': result.unanswered,
        'durationMinutes': result.durationMinutes,
        'createdAt': result.createdAt.toIso8601String(),
      };

  ExamResult _examFromJson(Map<String, dynamic> json) {
    final examId = _asInt(json['examId'], exams.first.id);
    final exam = exams.firstWhere((item) => item.id == examId,
        orElse: () => exams.first);
    return ExamResult(
      exam: exam,
      score: _asInt(json['score']),
      correct: _asInt(json['correct']),
      wrong: _asInt(json['wrong']),
      unanswered: _asInt(json['unanswered']),
      durationMinutes: _asInt(json['durationMinutes']),
      createdAt: _asDate(json['createdAt']),
    );
  }

  Map<String, Object?> _scheduleToJson(ExamScheduleItem item) => {
        'id': item.id,
        'title': item.title,
        'subjectId': item.subjectId,
        'type': item.type,
        'date': item.date.toIso8601String(),
        'notes': item.notes,
      };

  ExamScheduleItem _scheduleFromJson(Map<String, dynamic> json) =>
      ExamScheduleItem(
        id: _asString(json['id'] ?? json['client_id'],
            'schedule-${DateTime.now().microsecondsSinceEpoch}'),
        title: _asString(json['title'], 'Jadwal Ujian'),
        subjectId: _asInt(json['subjectId'] ?? json['subject_id'],
            subjectsForCurrentUser().first.id),
        type: _asString(json['type'] ?? json['exam_type'], 'UTS'),
        date: _asDate(json['date'] ?? json['exam_date']),
        notes: _asString(json['notes']),
      );

  Map<String, Object?> _studyPlanToJson(StudyPlanItem item) => {
        'title': item.title,
        'subject': item.subject,
        'date': item.date.toIso8601String(),
        'duration': item.duration,
        'completed': item.completed,
      };

  StudyPlanItem _studyPlanFromJson(Map<String, dynamic> json) => StudyPlanItem(
        _asString(json['title'], 'Study Plan'),
        _asString(json['subject'], 'Belajar'),
        _asDate(json['date']),
        _asInt(json['duration'], 30),
        completed: json['completed'] == true,
      );

  Map<String, Object?> _noteToJson(NoteItem item) => {
        'title': item.title,
        'content': item.content,
        'createdAt': item.createdAt.toIso8601String(),
      };

  NoteItem _noteFromJson(Map<String, dynamic> json) => NoteItem(
        _asString(json['title'], 'Catatan'),
        _asString(json['content']),
        _asDate(json['createdAt']),
      );

  Map<String, Object?> _notificationToJson(AppNotification item) => {
        'title': item.title,
        'message': item.message,
        'createdAt': item.createdAt.toIso8601String(),
        'isRead': item.isRead,
      };

  AppNotification _notificationFromJson(Map<String, dynamic> json) =>
      AppNotification(
        _asString(json['title'], 'Notifikasi'),
        _asString(json['message']),
        _asDate(json['createdAt']),
        isRead: json['isRead'] == true,
      );

  Map<String, Object?> _aiMessageToJson(AiMessage item) => {
        'role': item.role,
        'message': item.message,
      };

  AiMessage _aiMessageFromJson(Map<String, dynamic> json) => AiMessage(
      _asString(json['role'], 'assistant'), _asString(json['message']));

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry('$key', item));
    }
    return {};
  }

  static List<dynamic> _asList(Object? value) =>
      value is List ? value : <dynamic>[];

  static int _asInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? fallback;
  }

  static String _asString(Object? value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = '$value';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = _asString(value);
    return text.isEmpty ? null : text;
  }

  static DateTime _asDate(Object? value) =>
      DateTime.tryParse(_asString(value)) ?? DateTime.now();

  static Map<int, int> _intIntMap(Object? value) {
    final result = <int, int>{};
    for (final entry in _asMap(value).entries) {
      final key = int.tryParse(entry.key);
      if (key != null) result[key] = _asInt(entry.value);
    }
    return result;
  }

  static Map<int, String> _intStringMap(Object? value) {
    final result = <int, String>{};
    for (final entry in _asMap(value).entries) {
      final key = int.tryParse(entry.key);
      if (key != null) result[key] = _asString(entry.value);
    }
    return result;
  }

  String _digest(String email, String password) {
    return '${email.trim().toLowerCase()}::${password.length}::${password.codeUnits.fold<int>(17, (a, b) => (a * 31 + b) & 0x7fffffff)}';
  }

  AheadUser _upsertApiUser(Map<String, dynamic> data, {String? password}) {
    final email = _asString(data['email']).toLowerCase();
    final incomingName = _asString(data['name'], 'Siswa');
    final matches = _users.where((user) => user.email == email);
    final user = matches.isNotEmpty
        ? matches.first
        : AheadUser(
            id: _asInt(data['id'], _nextUserId++),
            name: incomingName,
            email: email,
            passwordDigest: '',
            classLevel: _asString(data['class'], 'Kelas X'),
            major: _asString(data['major'], 'IPA') == 'IPS' ? 'IPS' : 'IPA',
            provider: _asString(data['provider'], 'email'),
            photoUrl: _nullableString(data['profile_photo']),
          );
    if (matches.isEmpty) _users.add(user);
    user.name = _bestDisplayName(
      currentName: user.name,
      incomingName: incomingName,
      email: email,
    );
    user.classLevel = _asString(data['class'], user.classLevel);
    user.major = _asString(data['major'], user.major) == 'IPS' ? 'IPS' : 'IPA';
    user.provider = _asString(data['provider'], user.provider);
    user.photoUrl = _nullableString(data['profile_photo']) ?? user.photoUrl;
    if (password != null && password.isNotEmpty) {
      user.passwordDigest = _digest(email, password);
    }
    return user;
  }

  Future<void> _syncSchedulesWithApi() async {
    final token = _authToken;
    final user = currentUser;
    if (token == null || token.isEmpty || user == null) return;
    try {
      final response = await _api.get('/schedules', token: token);
      final remote = _asList(response['data'])
          .whereType<Map>()
          .map((item) => _scheduleFromJson(_asMap(item)))
          .toList();
      final remoteIds = remote.map((item) => item.id).toSet();
      for (final item in remote) {
        _upsertLocalSchedule(item);
      }
      final localSnapshot = List<ExamScheduleItem>.from(user.examSchedules);
      for (final item in localSnapshot) {
        if (!remoteIds.contains(item.id)) {
          await _pushScheduleToApi(item);
        }
      }
      _queueSave();
    } catch (_) {
      // Jadwal tetap tersimpan lokal saat API belum siap.
    }
  }

  void _upsertLocalSchedule(ExamScheduleItem item) {
    final user = currentUser;
    if (user == null) return;
    final index = user.examSchedules.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      user.examSchedules[index] = item;
    } else {
      user.examSchedules.add(item);
    }
  }

  Future<void> _pushScheduleToApi(ExamScheduleItem item) async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    await _api.post('/schedules', _scheduleToJson(item), token: token);
  }

  Future<void> _deleteScheduleFromApi(ExamScheduleItem item) async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    await _api.post('/schedules/delete', {'id': item.id}, token: token);
  }

  String _bestDisplayName({
    required String currentName,
    required String incomingName,
    required String email,
  }) {
    final current = currentName.trim();
    final incoming = incomingName.trim();
    final generated = _nameFromEmail(email);
    if (current.isNotEmpty &&
        current != 'Siswa' &&
        current != 'Siswa AHEAD' &&
        current != generated) {
      return current;
    }
    if (incoming.isNotEmpty) return incoming;
    return generated;
  }

  String _friendlyApiError(Object error) {
    if (error is AuthApiException) return error.message;
    final text = '$error';
    if (_isBackendOfflineError(error)) {
      return 'Backend API belum menyala. Jalankan file JALANKAN_AHEAD.bat dari folder C:\\ahead_app agar MySQL, API, dan Flutter aktif bersama.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  bool _isBackendOfflineError(Object error) {
    final text = error is AuthApiException ? error.message : '$error';
    return text.contains('Backend API belum menyala') ||
        text.contains('API tidak tersedia') ||
        text.contains('XMLHttpRequest') ||
        text.contains('ProgressEvent') ||
        text.contains('SocketException') ||
        text.contains('Failed to fetch') ||
        text.contains('Connection refused');
  }

  AheadUser _upsertOfflineUser({
    required String email,
    required String password,
    String? name,
    String classLevel = 'Kelas X',
    String major = 'IPA',
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final matches = _users.where((user) => user.email == normalizedEmail);
    final user = matches.isNotEmpty
        ? matches.first
        : AheadUser(
            id: _nextUserId++,
            name: (name == null || name.trim().isEmpty)
                ? _nameFromEmail(normalizedEmail)
                : name.trim(),
            email: normalizedEmail,
            passwordDigest: _digest(normalizedEmail, password),
            classLevel: classLevel,
            major: major == 'IPS' ? 'IPS' : 'IPA',
            provider: 'offline',
          );
    if (matches.isEmpty) _users.add(user);
    user.passwordDigest = _digest(normalizedEmail, password);
    if (name != null && name.trim().isNotEmpty) user.name = name.trim();
    user.classLevel = classLevel;
    user.major = major == 'IPS' ? 'IPS' : 'IPA';
    _authToken = null;
    currentUser = user;
    user.history.add('Login mode offline pada ${_shortDate(DateTime.now())}');
    _queueSave();
    return user;
  }

  String _nameFromEmail(String email) {
    final base = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    final words = base.split(' ').where((word) => word.trim().isNotEmpty).map(
        (word) => word.length <= 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}');
    return words.isEmpty ? 'Siswa AHEAD' : words.join(' ');
  }

  Future<String?> registerWithApi({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String classLevel,
    required String major,
  }) async {
    await ensureLoaded();
    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) return 'Nama wajib diisi.';
    if (!normalizedEmail.contains('@')) return 'Email tidak valid.';
    if (!_validPassword(password))
      return 'Password harus minimal 8 karakter, mengandung huruf besar dan angka.';
    if (password != confirmPassword) return 'Konfirmasi password belum sama.';
    if (classLevel == 'Kelas') return 'Kelas wajib dipilih.';
    try {
      await _api.post('/auth/register', {
        'name': trimmedName,
        'email': normalizedEmail,
        'password': password,
        'class': classLevel,
        'major': major,
      });
      final local = _users.where((user) => user.email == normalizedEmail);
      if (local.isEmpty) {
        final user = AheadUser(
          id: _nextUserId++,
          name: trimmedName,
          email: normalizedEmail,
          passwordDigest: _digest(normalizedEmail, password),
          classLevel: classLevel,
          major: major,
        );
        _users.add(user);
        user.history.add('Daftar akun pada ${_shortDate(DateTime.now())}');
      } else {
        final user = local.first;
        user.name = trimmedName;
        user.passwordDigest = _digest(normalizedEmail, password);
        user.classLevel = classLevel;
        user.major = major;
        user.history
            .add('Memperbarui data daftar pada ${_shortDate(DateTime.now())}');
      }
      _authToken = null;
      currentUser = null;
      _queueSave();
      return null;
    } catch (error) {
      if (_isBackendOfflineError(error)) {
        if (_users.any((user) => user.email == normalizedEmail)) {
          return 'Email sudah terdaftar. Silakan login.';
        }
        final user = AheadUser(
          id: _nextUserId++,
          name: trimmedName,
          email: normalizedEmail,
          passwordDigest: _digest(normalizedEmail, password),
          classLevel: classLevel,
          major: major,
          provider: 'offline',
        );
        _users.add(user);
        _authToken = null;
        currentUser = null;
        user.history
            .add('Daftar akun offline pada ${_shortDate(DateTime.now())}');
        _queueSave();
        return null;
      }
      return _friendlyApiError(error);
    }
  }

  Future<String?> loginWithApi(String email, String password) async {
    await ensureLoaded();
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _api.post('/auth/login', {
        'email': normalizedEmail,
        'password': password,
      });
      final user = _upsertApiUser(_asMap(response['user']), password: password);
      _authToken = _asString(response['token']);
      currentUser = user;
      user.history.add('Login pada ${_shortDate(DateTime.now())}');
      await _syncSchedulesWithApi();
      _queueSave();
      return null;
    } catch (error) {
      final localResult = login(email, password);
      if (localResult == null) {
        _authToken = null;
        return null;
      }
      if (_isBackendOfflineError(error)) {
        if (!localResult.contains('Akun tidak ditemukan')) return localResult;
        if (!normalizedEmail.contains('@')) return 'Email tidak valid.';
        if (!_validPassword(password)) {
          return 'Password harus minimal 8 karakter, mengandung huruf besar dan angka.';
        }
        _upsertOfflineUser(email: normalizedEmail, password: password);
        return null;
      }
      return _friendlyApiError(error);
    }
  }

  Future<String?> loginWithGoogleToken({
    required String idToken,
    String? major,
  }) async {
    await ensureLoaded();
    try {
      final body = <String, Object?>{'id_token': idToken};
      if (major != null) body['major'] = major;
      final response = await _api.post('/auth/google', body);
      final user = _upsertApiUser(_asMap(response['user']));
      _authToken = _asString(response['token']);
      currentUser = user;
      user.history.add('Login Google pada ${_shortDate(DateTime.now())}');
      await _syncSchedulesWithApi();
      _queueSave();
      return null;
    } catch (error) {
      return _friendlyApiError(error);
    }
  }

  Future<String?> loginWithGoogleProfile({
    required String email,
    required String name,
    String? major,
    String? photoUrl,
  }) async {
    await ensureLoaded();
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.endsWith('@gmail.com') ||
        !normalizedEmail.contains('@')) {
      return 'Gunakan alamat Gmail yang valid untuk masuk dengan Google.';
    }
    final matches = _users.where((user) => user.email == normalizedEmail);
    final user = matches.isNotEmpty
        ? matches.first
        : AheadUser(
            id: _nextUserId++,
            name: name.trim().isEmpty
                ? _nameFromEmail(normalizedEmail)
                : name.trim(),
            email: normalizedEmail,
            passwordDigest: 'google::$normalizedEmail',
            classLevel: 'Kelas X',
            major: major == 'IPS' ? 'IPS' : 'IPA',
            provider: 'google',
            photoUrl: photoUrl,
          );
    if (matches.isEmpty) _users.add(user);
    user.name = _bestDisplayName(
      currentName: user.name,
      incomingName: name,
      email: normalizedEmail,
    );
    user.provider = 'google';
    user.classLevel = 'Kelas X';
    user.major = major == 'IPS' ? 'IPS' : user.major;
    if (photoUrl != null && photoUrl.isNotEmpty) user.photoUrl = photoUrl;
    _authToken = null;
    currentUser = user;
    user.history.add('Login Google pada ${_shortDate(DateTime.now())}');
    _queueSave();
    return null;
  }

  List<AheadUser> googleAccountChoices() {
    final items = _users
        .where((user) =>
            user.email.toLowerCase().endsWith('@gmail.com') ||
            user.provider == 'google')
        .toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<String?> createResetCodeWithApi(String email) async {
    await ensureLoaded();
    try {
      final response = await _api.post('/password/forgot', {
        'email': email.trim().toLowerCase(),
      });
      return _asString(response['dev_token']);
    } catch (error) {
      final localCode = createResetCode(email);
      if (localCode != null) return localCode;
      throw AuthApiException(_friendlyApiError(error));
    }
  }

  Future<String?> resetPasswordWithApi(String email, String code,
      String password, String confirmPassword) async {
    await ensureLoaded();
    if (!_validPassword(password))
      return 'Password baru belum memenuhi syarat.';
    if (password != confirmPassword) return 'Konfirmasi password belum sama.';
    final normalizedEmail = email.trim().toLowerCase();
    try {
      await _api.post('/password/reset', {
        'email': normalizedEmail,
        'token': code.trim(),
        'password': password,
      });
      final local = _users.where((user) => user.email == normalizedEmail);
      if (local.isNotEmpty) {
        local.first.passwordDigest = _digest(normalizedEmail, password);
        local.first.history
            .add('Password diubah pada ${_shortDate(DateTime.now())}');
        _queueSave();
      }
      return null;
    } catch (error) {
      final localResult = resetPassword(code, password, confirmPassword);
      if (localResult == null) return null;
      return _friendlyApiError(error);
    }
  }

  String? register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String classLevel,
    required String major,
  }) {
    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) return 'Nama wajib diisi.';
    if (!normalizedEmail.contains('@')) return 'Email tidak valid.';
    if (!_validPassword(password))
      return 'Password harus minimal 8 karakter, mengandung huruf besar dan angka.';
    if (password != confirmPassword) return 'Konfirmasi password belum sama.';
    if (classLevel == 'Kelas') return 'Kelas wajib dipilih.';
    if (_users.any((user) => user.email == normalizedEmail))
      return 'Email sudah terdaftar.';
    final user = AheadUser(
      id: _nextUserId++,
      name: trimmedName,
      email: normalizedEmail,
      passwordDigest: _digest(normalizedEmail, password),
      classLevel: classLevel,
      major: major,
    );
    _users.add(user);
    currentUser = user;
    user.history.add('Daftar akun pada ${_shortDate(DateTime.now())}');
    _queueSave();
    return null;
  }

  String? login(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    final matches = _users.where((user) => user.email == normalizedEmail);
    if (matches.isEmpty)
      return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
    final user = matches.first;
    if (user.passwordDigest != _digest(normalizedEmail, password))
      return 'Password salah.';
    currentUser = user;
    user.history.add('Login pada ${_shortDate(DateTime.now())}');
    _queueSave();
    return null;
  }

  void logout() {
    _authToken = null;
    currentUser = null;
    _queueSave();
  }

  bool _validPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  String? createResetCode(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_users.any((user) => user.email == normalizedEmail)) return null;
    _resetEmail = normalizedEmail;
    _resetCode = (100000 + Random().nextInt(899999)).toString();
    return _resetCode;
  }

  String? resetPassword(String code, String password, String confirmPassword) {
    if (_resetEmail == null || _resetCode == null)
      return 'Belum ada kode reset aktif.';
    if (code.trim() != _resetCode) return 'Kode reset salah.';
    if (!_validPassword(password))
      return 'Password baru belum memenuhi syarat.';
    if (password != confirmPassword) return 'Konfirmasi password belum sama.';
    final user = _users.firstWhere((item) => item.email == _resetEmail);
    user.passwordDigest = _digest(user.email, password);
    user.history.add('Password diubah pada ${_shortDate(DateTime.now())}');
    _resetEmail = null;
    _resetCode = null;
    _queueSave();
    return null;
  }

  SubjectItem subjectById(int id) =>
      subjects.firstWhere((item) => item.id == id);

  List<SubjectItem> subjectsForMajor(String major) =>
      subjects.where((item) => item.category == major).toList();

  List<SubjectItem> subjectsForCurrentUser() {
    final major = currentUser?.major ?? 'IPA';
    return subjectsForMajor(major);
  }

  List<MaterialItem> materialsForSubject(int subjectId) =>
      materials.where((item) => item.subjectId == subjectId).toList();

  List<MaterialItem> materialsForCurrentUser() {
    final allowed = subjectsForCurrentUser().map((item) => item.id).toSet();
    return materials.where((item) => allowed.contains(item.subjectId)).toList();
  }

  List<QuestionItem> questionsForSubject(int subjectId) =>
      questions.where((item) => item.subjectId == subjectId).toList();

  List<QuestionItem> questionsForMaterial(int materialId) =>
      questions.where((item) => item.materialId == materialId).toList();

  List<QuestionItem> questionsForCurrentUser() {
    final allowed = subjectsForCurrentUser().map((item) => item.id).toSet();
    return questions.where((item) => allowed.contains(item.subjectId)).toList();
  }

  List<ExamItem> examsForCurrentUser() {
    final allowed = subjectsForCurrentUser().map((item) => item.id).toSet();
    return exams.where((item) => allowed.contains(item.subjectId)).toList();
  }

  List<ExamScheduleItem> schedulesForCurrentUser() {
    final user = currentUser;
    if (user == null) return [];
    final allowed = subjectsForCurrentUser().map((item) => item.id).toSet();
    final items = user.examSchedules
        .where((item) => allowed.contains(item.subjectId))
        .toList();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  ExamScheduleItem? nextSchedule() {
    final upcoming =
        schedulesForCurrentUser().where((item) => item.daysLeft >= 0).toList();
    return upcoming.firstOrNull;
  }

  void saveSchedule(ExamScheduleItem item) {
    final user = currentUser;
    if (user == null) return;
    final index = user.examSchedules.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      user.examSchedules[index] = item;
      user.history.add('Memperbarui jadwal ${item.title}');
    } else {
      user.examSchedules.add(item);
      user.history.add('Menambahkan jadwal ${item.title}');
    }
    user.notifications.add(AppNotification(
      'Jadwal ${item.type}',
      '${item.title} untuk ${subjectById(item.subjectId).name} ${item.dayLabel}.',
      DateTime.now(),
    ));
    unawaited(_pushScheduleToApi(item));
    _queueSave();
  }

  void deleteSchedule(ExamScheduleItem item) {
    final user = currentUser;
    if (user == null) return;
    user.examSchedules.removeWhere((entry) => entry.id == item.id);
    user.history.add('Menghapus jadwal ${item.title}');
    unawaited(_deleteScheduleFromApi(item));
    _queueSave();
  }

  int readinessForSubject(int subjectId) {
    final user = currentUser;
    if (user == null) return 0;
    final subjectMaterials = materialsForSubject(subjectId);
    if (subjectMaterials.isEmpty) return 0;
    final materialScore = (subjectMaterials
                .map((item) => user.materialProgress[item.id] ?? 0)
                .fold<int>(0, (sum, value) => sum + value) /
            subjectMaterials.length)
        .round();
    final relatedPractice = user.practiceResults
        .where((item) => item.subjectId == subjectId)
        .map((item) => item.score)
        .toList();
    final practiceScore = relatedPractice.isEmpty
        ? 0
        : (relatedPractice.fold<int>(0, (sum, value) => sum + value) /
                relatedPractice.length)
            .round();
    return ((materialScore * .58) + (practiceScore * .42))
        .round()
        .clamp(0, 100);
  }

  MaterialItem? recommendedMaterial() {
    final user = currentUser;
    if (user == null) return null;
    final schedule = nextSchedule();
    final subjectId = schedule?.subjectId ??
        (user.practiceResults.isEmpty
            ? subjectsForCurrentUser().first.id
            : user.practiceResults.last.subjectId);
    final candidates = materialsForSubject(subjectId).toList();
    if (candidates.isEmpty) return materialsForCurrentUser().firstOrNull;
    candidates.sort((a, b) {
      final left = user.materialProgress[a.id] ?? 0;
      final right = user.materialProgress[b.id] ?? 0;
      return left.compareTo(right);
    });
    return candidates.first;
  }

  String recommendationReason() {
    final user = currentUser;
    if (user == null) return 'Mulai belajar untuk membuka rekomendasi.';
    final schedule = nextSchedule();
    final material = recommendedMaterial();
    if (material == null) return 'Materi jurusanmu belum tersedia.';
    final progress = user.materialProgress[material.id] ?? 0;
    if (schedule != null) {
      return '${schedule.title} ${schedule.dayLabel}. Fokuskan ${subjectById(material.subjectId).name} karena progres materi ini baru $progress%.';
    }
    if (user.practiceResults.isNotEmpty &&
        user.practiceResults.last.score < 80) {
      return 'Skor latihan terakhir ${user.practiceResults.last.score}%. Ulangi materi ini sebelum lanjut ke soal berikutnya.';
    }
    return 'Dipilih dari progres materi terendah di jurusan ${user.major}, supaya persiapanmu lebih rata.';
  }

  List<MaterialSlide> materialSlides(MaterialItem material) {
    final subject = subjectById(material.subjectId);
    final concepts = _conceptsForMaterial(material.id);
    final paragraphs = material.content
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    String paragraph(int index) => paragraphs.isEmpty
        ? material.description
        : paragraphs[index % paragraphs.length];
    String concept(int index) => concepts[index % concepts.length];
    const colors = [
      Color(0xFFEAF1FF),
      Color(0xFFFFF2D7),
      Color(0xFFEAFBF4),
      Color(0xFFFFECE7),
      Color(0xFFF0ECFF),
      Color(0xFFEAF8FF),
      Color(0xFFFFF6E8),
      Color(0xFFEFF7E9),
      Color(0xFFFFEEF5),
      Color(0xFFEFF2F7),
    ];

    return [
      MaterialSlide(
        title: 'Gambaran besar ${material.title}',
        body:
            '${paragraph(0)}\n\nPada slide awal ini, pahami dulu posisi materi ${material.title} dalam ${subject.name}. Tujuannya bukan menghafal semua kalimat, tetapi menangkap masalah utama, istilah penting, dan alasan materi ini perlu dipelajari siswa kelas ${material.classLevel}.',
        icon: Icons.explore_outlined,
        color: colors[0],
      ),
      MaterialSlide(
        title: 'Konsep inti yang wajib dikuasai',
        body:
            'Konsep utama pada materi ini adalah ${concept(0)}, ${concept(1)}, dan ${concept(2)}. Ketiganya saling berhubungan karena membantu kamu menjelaskan ${material.description.toLowerCase()} dengan bahasa yang runtut.\n\nSaat membaca soal, tandai kata kunci lebih dulu. Kalau kata kuncinya dekat dengan ${concept(0)}, jawaban biasanya menuntut definisi, contoh, atau hubungan sebab-akibat.',
        icon: Icons.lightbulb_outline_rounded,
        color: colors[1],
      ),
      MaterialSlide(
        title: 'Pendalaman materi',
        body:
            '${paragraph(1)}\n\nBagian pendalaman ini penting karena banyak soal tidak bertanya definisi langsung. Soal sering memberi kasus, lalu meminta kamu memilih konsep yang paling tepat. Hubungkan kasus dengan ${concept(3)} dan jelaskan dampaknya secara logis.',
        icon: Icons.manage_search_rounded,
        color: colors[2],
      ),
      MaterialSlide(
        title: 'Contoh penerapan di kehidupan nyata',
        body:
            'Contoh penerapan ${material.title} dapat ditemukan dari situasi sehari-hari, berita, data sekolah, lingkungan sekitar, atau fenomena masyarakat. Pada ${subject.name}, contoh yang baik selalu punya konteks, bukti, dan kesimpulan.\n\nCoba gunakan pola: peristiwa yang diamati, konsep yang cocok, alasan hubungan, lalu simpulan singkat.',
        icon: Icons.public_rounded,
        color: colors[3],
      ),
      MaterialSlide(
        title: 'Langkah memahami soal',
        body:
            'Gunakan empat langkah ini: baca pertanyaan sampai tuntas, garis bawahi kata kunci, hubungkan dengan ${concept(0)} atau ${concept(1)}, lalu pilih jawaban yang paling sesuai dengan konteks.\n\nKalau ada dua pilihan yang terlihat benar, cari pilihan yang paling lengkap menjelaskan sebab, proses, dan akibat. Hindari jawaban yang terlalu mutlak seperti selalu, pasti, atau tidak pernah jika konteksnya tidak mendukung.',
        icon: Icons.checklist_rtl_rounded,
        color: colors[4],
      ),
      MaterialSlide(
        title: 'Kesalahan umum yang harus dihindari',
        body:
            'Kesalahan yang sering terjadi adalah hanya menghafal istilah tanpa memahami perbedaannya. Misalnya ${concept(2)} sering tertukar dengan ${concept(3)} karena keduanya muncul dalam topik yang sama.\n\nCara menghindarinya: tulis definisi pendek, buat satu contoh, lalu jelaskan apa yang membedakan konsep tersebut dari konsep lain.',
        icon: Icons.warning_amber_rounded,
        color: colors[5],
      ),
      MaterialSlide(
        title: 'Mini cek pemahaman',
        body:
            'Jawab cepat dalam hati: apa arti ${concept(0)}? Kapan ${concept(1)} digunakan? Bagaimana ${concept(2)} memengaruhi ${material.description.toLowerCase()}?\n\nKalau tiga pertanyaan ini belum lancar, ulangi slide sebelumnya. Kalau sudah lancar, lanjutkan ke bagian rangkuman dan aplikasi soal.',
        icon: Icons.quiz_outlined,
        color: colors[6],
      ),
      MaterialSlide(
        title: 'Aplikasi ke soal pilihan ganda dan essay',
        body:
            'Untuk pilihan ganda, cari opsi yang paling sesuai dengan kata kunci soal. Untuk essay, jawab dengan struktur: konsep, penjelasan, contoh, dan kesimpulan.\n\nContoh kerangka essay: "${concept(0)} adalah ..., hal ini terlihat pada ..., sehingga dapat disimpulkan bahwa ...". Kerangka seperti ini membuat jawaban lebih rapi dan mudah dinilai.',
        icon: Icons.edit_note_rounded,
        color: colors[7],
      ),
      MaterialSlide(
        title: 'Rangkuman cepat',
        body:
            'Inti materi ${material.title}: ${material.description}. Kata kunci yang perlu kamu ingat adalah ${concept(0)}, ${concept(1)}, ${concept(2)}, ${concept(3)}, dan ${concept(4)}.\n\nJika diminta menjelaskan, jangan berhenti pada definisi. Tambahkan hubungan antar konsep dan contoh yang relevan agar jawabanmu terlihat matang.',
        icon: Icons.summarize_outlined,
        color: colors[8],
      ),
      MaterialSlide(
        title: 'Penutup belajar',
        body:
            'Sebelum menandai selesai, pastikan kamu bisa menjelaskan ${material.title} dengan kalimat sendiri selama satu menit. Jika masih bingung, ulangi slide yang membahas konsep inti dan kesalahan umum.\n\nSetelah selesai, beri rating pengalaman belajar supaya AHEAD bisa mencatat kualitas belajarmu dan membantu kamu memilih materi berikutnya.',
        icon: Icons.flag_circle_outlined,
        color: colors[9],
      ),
    ];
  }

  void openMaterial(MaterialItem item) {
    final user = currentUser;
    if (user == null) return;
    final current = user.materialProgress[item.id] ?? 0;
    user.materialProgress[item.id] = max(current, 35);
    user.history.add('Membuka materi ${item.title}');
    _queueSave();
  }

  void completeMaterial(MaterialItem item) {
    final user = currentUser;
    if (user == null) return;
    user.materialProgress[item.id] = 100;
    user.history.add('Menyelesaikan materi ${item.title}');
    _queueSave();
  }

  void rateMaterial(MaterialItem item, int rating) {
    final user = currentUser;
    if (user == null) return;
    user.materialRatings[item.id] = rating.clamp(1, 10);
    user.history
        .add('Memberi rating materi ${item.title} ${rating.clamp(1, 10)}/10');
    _queueSave();
  }

  void toggleSaved(MaterialItem item) {
    final user = currentUser;
    if (user == null) return;
    if (user.savedMaterialIds.contains(item.id)) {
      user.savedMaterialIds.remove(item.id);
    } else {
      user.savedMaterialIds.add(item.id);
    }
    _queueSave();
  }

  PracticeResult savePractice(
      String title,
      int subjectId,
      String mode,
      List<QuestionItem> usedQuestions,
      Map<int, int> answers,
      Map<int, String> confidences,
      Map<int, String> essayAnswers,
      int minutes) {
    final user = currentUser!;
    var correct = 0;
    for (final question in usedQuestions) {
      if (answers[question.id] == question.correctIndex) correct++;
    }
    final wrong = usedQuestions.length - correct;
    final score = ((correct / usedQuestions.length) * 100).round();
    final result = PracticeResult(
      title: title,
      subjectId: subjectId,
      mode: mode,
      score: score,
      correct: correct,
      wrong: wrong,
      durationMinutes: minutes,
      createdAt: DateTime.now(),
      answers: Map.of(answers),
      confidences: Map.of(confidences),
      essayAnswers: Map.of(essayAnswers),
    );
    user.practiceResults.add(result);
    user.history.add('Mengerjakan latihan $title dengan skor $score%');
    _queueSave();
    return result;
  }

  void ratePractice(PracticeResult result, int rating) {
    result.rating = rating.clamp(1, 10);
    currentUser?.history.add('Memberi rating latihan ${result.rating}/10');
    _queueSave();
  }

  ExamResult saveExam(ExamItem exam, List<QuestionItem> usedQuestions,
      Map<int, int> answers, int minutes) {
    final user = currentUser!;
    var correct = 0;
    var unanswered = 0;
    for (final question in usedQuestions) {
      final answer = answers[question.id];
      if (answer == null) {
        unanswered++;
      } else if (answer == question.correctIndex) {
        correct++;
      }
    }
    final wrong = usedQuestions.length - correct - unanswered;
    final score = ((correct / usedQuestions.length) * 100).round();
    final result = ExamResult(
      exam: exam,
      score: score,
      correct: correct,
      wrong: wrong,
      unanswered: unanswered,
      durationMinutes: minutes,
      createdAt: DateTime.now(),
    );
    user.examResults.add(result);
    user.history.add('Menyelesaikan ujian ${exam.title} dengan skor $score%');
    _queueSave();
    return result;
  }

  List<Object> search(String query, {String filter = 'Semua'}) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final includeAll = filter == 'Semua';
    return [
      if (includeAll &&
          ['ai', 'ahead ai', 'bantu', 'tanya', 'chat']
              .any((keyword) => keyword.contains(q) || q.contains(keyword)))
        const AiToolItem(),
      if (includeAll || filter == 'Materi')
        ...subjectsForCurrentUser().where((item) =>
            item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q)),
      if (includeAll || filter == 'Materi')
        ...materialsForCurrentUser().where((item) =>
            item.title.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.content.toLowerCase().contains(q)),
      if (includeAll || filter == 'Soal')
        ...questionsForCurrentUser().where((item) =>
            item.question.toLowerCase().contains(q) ||
            item.explanation.toLowerCase().contains(q) ||
            item.options.any((option) => option.toLowerCase().contains(q))),
      if (includeAll || filter == 'Ujian')
        ...examsForCurrentUser().where((item) =>
            item.title.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.type.toLowerCase().contains(q)),
      if (includeAll || filter == 'Ujian')
        ...schedulesForCurrentUser().where((item) =>
            item.title.toLowerCase().contains(q) ||
            item.type.toLowerCase().contains(q) ||
            subjectById(item.subjectId).name.toLowerCase().contains(q)),
    ];
  }

  String aiReply(String message) {
    final user = currentUser;
    user?.aiMessages.add(AiMessage('user', message));
    final q = message.toLowerCase();
    final reply = _generalTutorReply(message, q);
    user?.aiMessages.add(AiMessage('assistant', reply));
    _queueSave();
    return reply;
  }

  String _generalTutorReply(String original, String q) {
    final matchedQuestion = _matchedQuestion(q);
    if (matchedQuestion != null) {
      final answer = matchedQuestion.options[matchedQuestion.correctIndex];
      return 'Aku bantu bahas soal ini.\n\nJawaban yang paling tepat adalah $answer.\n\nPembahasannya: ${matchedQuestion.explanation}\n\nCara mikirnya: pahami kata kunci pada soal, cocokkan dengan konsep utama, lalu eliminasi opsi yang tidak sesuai. Kalau kamu kirim pilihan jawabanmu, aku bisa bantu cek kenapa pilihan itu benar atau salah.';
    }

    if (_hasAny(q, ['senyawa', 'molekul', 'unsur', 'atom', 'ion'])) {
      return 'Senyawa adalah zat yang terbentuk dari dua atau lebih unsur berbeda yang bergabung secara kimia dengan perbandingan tetap.\n\nContoh mudahnya air, H2O. Air tersusun dari hidrogen dan oksigen. Sifat air berbeda dari sifat hidrogen maupun oksigen karena setelah berikatan, partikelnya membentuk zat baru.\n\nCara membedakannya:\n1. Unsur hanya punya satu jenis atom, misalnya Fe atau O2.\n2. Senyawa punya beberapa unsur yang berikatan, misalnya H2O, CO2, NaCl.\n3. Campuran tidak punya ikatan kimia tetap, misalnya air gula atau udara.\n\nKalau kamu tanya senyawa tertentu, kirim rumus atau namanya, nanti aku jelaskan penyusun, jenis ikatan, dan sifatnya.';
    }

    if (_hasAny(q, ['asam', 'basa', 'ph', 'garam'])) {
      return 'Asam dan basa bisa dipahami dari ion yang dihasilkan di air. Asam cenderung menghasilkan ion H+, sedangkan basa menghasilkan ion OH-.\n\nContoh: HCl termasuk asam karena di air menghasilkan H+. NaOH termasuk basa karena menghasilkan OH-. Kalau asam dan basa bereaksi, biasanya terjadi netralisasi yang menghasilkan garam dan air.\n\nPatokan cepat: pH kurang dari 7 bersifat asam, pH 7 netral, pH lebih dari 7 bersifat basa.';
    }

    if (_hasAny(q, ['reaksi', 'persamaan kimia', 'koefisien', 'setara'])) {
      return 'Untuk menyetarakan reaksi kimia, fokusnya adalah jumlah atom kiri dan kanan harus sama.\n\nLangkahnya:\n1. Tulis rumus reaktan dan produk.\n2. Hitung jumlah atom tiap unsur di kiri dan kanan.\n3. Ubah koefisien di depan rumus, jangan mengubah indeks kecil pada rumus.\n4. Cek ulang sampai semua unsur seimbang.\n\nContoh: H2 + O2 -> H2O belum setara. Dibuat menjadi 2H2 + O2 -> 2H2O, karena H dan O di kiri-kanan sudah sama.';
    }

    if (_hasAny(q, ['glbb', 'gerak lurus', 'kecepatan', 'percepatan'])) {
      return 'GLBB adalah gerak lurus berubah beraturan, artinya benda bergerak pada lintasan lurus dengan percepatan tetap.\n\nRumus penting:\nv = v0 + at\ns = v0t + 1/2 at^2\nv^2 = v0^2 + 2as\n\nKeterangan: v0 kecepatan awal, v kecepatan akhir, a percepatan, t waktu, dan s perpindahan. Biasanya soal GLBB bisa diselesaikan dengan menulis data yang diketahui dulu, lalu pilih rumus yang memuat besaran yang ditanya.';
    }

    if (_hasAny(q, ['energi', 'usaha', 'daya', 'kinetik', 'potensial'])) {
      return 'Energi adalah kemampuan melakukan usaha. Dalam fisika, dua bentuk yang sering muncul adalah energi kinetik dan energi potensial.\n\nEnergi kinetik: Ek = 1/2 mv^2, muncul karena benda bergerak.\nEnergi potensial gravitasi: Ep = mgh, muncul karena posisi benda pada ketinggian tertentu.\nUsaha: W = F x s, yaitu gaya yang menyebabkan perpindahan.\n\nKalau ada angka di soal, tuliskan diketahui dan ditanya dulu, baru masukkan ke rumus yang sesuai.';
    }

    if (_hasAny(q, ['fotosintesis', 'klorofil', 'tumbuhan'])) {
      return 'Fotosintesis adalah proses tumbuhan membuat makanan dengan bantuan cahaya matahari. Bahan utamanya karbon dioksida dan air, lalu menghasilkan glukosa dan oksigen.\n\nPersamaan sederhananya:\n6CO2 + 6H2O -> C6H12O6 + 6O2\n\nKlorofil berfungsi menangkap energi cahaya. Glukosa dipakai sebagai sumber energi tumbuhan, sedangkan oksigen dilepas ke lingkungan.';
    }

    if (_hasAny(q, ['virus', 'bakteri', 'penyakit'])) {
      return 'Virus berbeda dari bakteri. Virus ukurannya lebih kecil dan hanya bisa berkembang biak di dalam sel hidup. Bakteri adalah organisme sel tunggal yang bisa hidup dan berkembang biak sendiri pada kondisi tertentu.\n\nVirus dapat menyebabkan penyakit seperti influenza atau Covid-19, tetapi tidak semua virus selalu merugikan. Dalam biologi, virus dibahas melalui struktur, cara replikasi, dan perannya dalam kehidupan.';
    }

    if (_hasAny(
        q, ['persamaan kuadrat', 'akar', 'diskriminan', 'faktorisasi'])) {
      return 'Persamaan kuadrat berbentuk ax^2 + bx + c = 0. Untuk mencari akarnya, ada beberapa cara:\n\n1. Faktorisasi, jika bentuknya mudah dipecah.\n2. Rumus kuadrat: x = (-b +- akar(b^2 - 4ac)) / 2a.\n3. Melengkapkan kuadrat.\n\nDiskriminan D = b^2 - 4ac membantu melihat jenis akar. Jika D > 0 ada dua akar real, D = 0 satu akar kembar, dan D < 0 tidak punya akar real.';
    }

    if (_hasAny(q, ['sejarah', 'rempah', 'kerajaan', 'masa lalu'])) {
      return 'Dalam sejarah, hal penting bukan cuma menghafal peristiwa, tetapi memahami manusia, ruang, waktu, sebab, dan akibat.\n\nMisalnya jalur rempah dipelajari karena perdagangan rempah menghubungkan wilayah Nusantara dengan bangsa lain. Dampaknya tidak hanya ekonomi, tetapi juga budaya, politik, agama, dan perkembangan kota pelabuhan.';
    }

    if (_hasAny(q, ['ekonomi', 'kelangkaan', 'kebutuhan', 'pasar', 'uang'])) {
      return 'Ekonomi mempelajari cara manusia memenuhi kebutuhan dengan sumber daya yang terbatas. Konsep kuncinya adalah kelangkaan.\n\nKarena sumber daya terbatas, manusia harus memilih prioritas. Dari situ muncul biaya peluang, kegiatan produksi, konsumsi, distribusi, pasar, dan lembaga keuangan.';
    }

    if (_hasAny(q, ['sosiologi', 'interaksi', 'gejala sosial', 'masyarakat'])) {
      return 'Sosiologi mempelajari masyarakat dan hubungan sosial di dalamnya. Konsep pentingnya meliputi interaksi sosial, tindakan sosial, norma, nilai, identitas, dan gejala sosial.\n\nKalau ada contoh kasus, biasanya cara menjawabnya adalah mencari siapa pelakunya, bentuk interaksinya, nilai atau norma yang bekerja, lalu dampaknya bagi masyarakat.';
    }

    if (_hasAny(q, ['geografi', 'peta', 'sig', 'penginderaan jauh', 'ruang'])) {
      return 'Geografi mempelajari fenomena di permukaan bumi dengan sudut pandang keruangan, lingkungan, dan kewilayahan.\n\nPeta digunakan untuk menyajikan informasi lokasi. Penginderaan jauh mengumpulkan data dari jarak jauh, misalnya melalui satelit. SIG atau Sistem Informasi Geografis dipakai untuk mengolah dan menganalisis data spasial.';
    }

    if (_hasAny(q, [
      'soal',
      'jawaban',
      'pilihan ganda',
      'essay',
      'esai',
      'cara ngerjain'
    ])) {
      return 'Bisa, kirim soal lengkapnya ya. Kalau ada pilihan ganda, kirim juga opsi A sampai E.\n\nNanti aku bantu dengan format:\n1. Menentukan konsep yang dipakai.\n2. Membahas langkah penyelesaian.\n3. Menunjukkan jawaban benar.\n4. Menjelaskan kenapa opsi lain salah.\n\nKalau essay, aku juga bisa bantu susun jawaban yang runtut dan mudah dipahami.';
    }

    final material = _matchedMaterial(q);
    if (material != null) {
      final subject = subjectById(material.subjectId);
      return 'Bisa. Pertanyaanmu mengarah ke ${subject.name}, terutama materi ${material.title}.\n\nIntinya: ${material.content}\n\nPenjelasan sederhananya: ${material.description}. Kalau ini muncul di soal, cari kata kunci utamanya dulu, lalu hubungkan dengan konsep sebab-akibatnya. Kamu boleh kirim contoh soal atau bagian yang bikin bingung, nanti aku uraikan langkahnya pelan-pelan.';
    }

    if (_hasAny(q,
        ['apa itu', 'jelaskan', 'gimana', 'bagaimana', 'kenapa', 'mengapa'])) {
      return _openTutorReply(original, q);
    }

    return _openTutorReply(original, q);
  }

  bool _hasAny(String source, List<String> keywords) =>
      keywords.any(source.contains);

  MaterialItem? _matchedMaterial(String q) {
    final queryTokens = _importantTokens(q).toSet();
    if (queryTokens.isEmpty) return null;
    MaterialItem? best;
    var bestScore = 0;
    for (final item in materialsForCurrentUser()) {
      final title = item.title.toLowerCase();
      var score = q.contains(title) ? 6 : 0;
      final titleTokens = _importantTokens(item.title).toSet();
      final detailTokens =
          _importantTokens('${item.description} ${item.content}').toSet();
      score += titleTokens.intersection(queryTokens).length * 3;
      score += detailTokens.intersection(queryTokens).length;
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return bestScore >= 4 ? best : null;
  }

  QuestionItem? _matchedQuestion(String q) {
    final queryTokens = _importantTokens(q).toSet();
    if (queryTokens.length < 3) return null;
    QuestionItem? best;
    var bestScore = 0;
    for (final item in questionsForCurrentUser()) {
      var score = q.contains(item.question.toLowerCase()) ? 8 : 0;
      final questionTokens =
          _importantTokens('${item.question} ${item.options.join(' ')}')
              .toSet();
      score += questionTokens.intersection(queryTokens).length;
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return bestScore >= 5 ? best : null;
  }

  List<String> _importantTokens(String text) {
    const ignored = {
      'yang',
      'dan',
      'atau',
      'dengan',
      'untuk',
      'dari',
      'pada',
      'dalam',
      'materi',
      'soal',
      'cara',
      'gimana',
      'bagaimana',
      'kenapa',
      'mengapa',
      'jelaskan',
      'adalah',
      'kelas',
      'tentang',
      'ini',
      'itu',
      'apa',
      'aku',
      'saya',
      'tolong',
      'bantu',
      'dong',
      'ya',
    };
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((word) => word.length > 3 && !ignored.contains(word))
        .toList();
  }

  String _openTutorReply(String original, String q) {
    final keywords = _importantTokens(q).take(5).toList();
    final keywordText = keywords.isEmpty ? original : keywords.join(', ');
    return 'Aku tangkap pertanyaanmu tentang "$original".\n\nKata kunci yang perlu diperjelas: $keywordText.\n\nCara menjawabnya:\n1. Tentukan dulu konsep utama dari pertanyaan.\n2. Pisahkan data yang diketahui dan hal yang ditanyakan.\n3. Pakai definisi, rumus, atau hubungan sebab-akibat yang sesuai.\n4. Tutup dengan contoh supaya lebih mudah diingat.\n\nKirim istilah yang lebih spesifik, rumus, atau teks soal lengkapnya. Nanti aku jawab langsung sesuai pertanyaan itu, bukan sekadar mengarah ke menu aplikasi.';
  }

  static String _shortDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  static String shortDate(DateTime date) => _shortDate(date);
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    await aheadStore.ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AheadColors.blue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AheadLogo(size: 76, showText: false),
            SizedBox(height: 18),
            Text('AHEAD',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('Prepare Today. Stay AHEAD.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.notice});

  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    final result = await aheadStore.loginWithApi(email.text, password.text);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        error = result;
        loading = false;
      });
      return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 34),
          const Center(child: AheadWordmark()),
          const SizedBox(height: 72),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                  color: AheadColors.navy,
                  fontSize: 36,
                  height: 1.14,
                  fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: 'Selamat Datang\n'),
                TextSpan(text: 'di '),
                TextSpan(
                    text: 'AHEAD', style: TextStyle(color: AheadColors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Siapkan dirimu sebelum hari ujian.',
              style: TextStyle(color: AheadColors.navy, fontSize: 16)),
          if (widget.notice != null) ...[
            const SizedBox(height: 18),
            InfoBox(widget.notice!)
          ],
          if (error != null) ...[const SizedBox(height: 18), ErrorBox(error!)],
          const SizedBox(height: 32),
          AheadTextField(
              controller: email,
              hint: 'Email atau Username',
              icon: Icons.mail_outline_rounded),
          const SizedBox(height: 14),
          AheadTextField(
            controller: password,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: hidden,
            trailing: IconButton(
              onPressed: () => setState(() => hidden = !hidden),
              icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AheadColors.muted),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Lupa password?',
                  style: TextStyle(
                      color: AheadColors.blue, fontWeight: FontWeight.w700)),
            ),
          ),
          AheadButton(
              label: loading ? 'Memproses...' : 'Masuk',
              icon: Icons.arrow_forward_rounded,
              onPressed: loading ? () {} : () => submit()),
          const SizedBox(height: 24),
          const OrDivider(),
          const SizedBox(height: 24),
          GoogleAuthButton(
            label: 'Masuk dengan Google',
            onError: (message) => setState(() => error = message),
            onSuccess: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MainShell())),
          ),
          const SizedBox(height: 28),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                const Text('Belum punya akun?',
                    style: TextStyle(color: AheadColors.navy)),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Daftar Sekarang',
                      style: TextStyle(
                          color: AheadColors.blue,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 56),
          const Center(child: BottomBranding()),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String classLevel = 'Kelas X';
  String major = 'IPA';
  bool hidden = true;
  bool confirmHidden = true;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    final result = await aheadStore.registerWithApi(
      name: name.text,
      email: email.text,
      password: password.text,
      confirmPassword: confirm.text,
      classLevel: classLevel,
      major: major,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        error = result;
        loading = false;
      });
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginScreen(
              notice:
                  'Akun berhasil dibuat. Silakan login ulang dengan email dan password yang baru didaftarkan.')),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AheadColors.blue),
          ),
          const SizedBox(height: 16),
          const Text('Daftar Akun AHEAD',
              style: TextStyle(
                  color: AheadColors.navy,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text(
              'Bergabunglah dan mulai perjalanan belajarmu bersama AHEAD.',
              style: TextStyle(color: AheadColors.muted, height: 1.45)),
          if (error != null) ...[const SizedBox(height: 16), ErrorBox(error!)],
          const SizedBox(height: 24),
          AheadTextField(
              controller: name,
              hint: 'Nama lengkap',
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          AheadTextField(
              controller: email,
              hint: 'Email',
              icon: Icons.mail_outline_rounded),
          const SizedBox(height: 14),
          AheadTextField(
            controller: password,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: hidden,
            trailing: IconButton(
              onPressed: () => setState(() => hidden = !hidden),
              icon: Icon(hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
          ),
          const SizedBox(height: 14),
          AheadTextField(
            controller: confirm,
            hint: 'Konfirmasi password',
            icon: Icons.lock_outline_rounded,
            obscureText: confirmHidden,
            trailing: IconButton(
              onPressed: () => setState(() => confirmHidden = !confirmHidden),
              icon: Icon(confirmHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
          ),
          const SizedBox(height: 14),
          AheadSelect(
            value: classLevel,
            items: const ['Kelas X'],
            icon: Icons.school_outlined,
            onChanged: (value) =>
                setState(() => classLevel = value ?? 'Kelas X'),
          ),
          const SizedBox(height: 22),
          const Text('Pilih kategori belajarmu',
              style: TextStyle(
                  color: AheadColors.navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: ChoiceCard(
                      title: 'IPA',
                      subtitle: 'Ilmu Pengetahuan Alam',
                      icon: Icons.science_outlined,
                      selected: major == 'IPA',
                      onTap: () => setState(() => major = 'IPA'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ChoiceCard(
                      title: 'IPS',
                      subtitle: 'Ilmu Pengetahuan Sosial',
                      icon: Icons.groups_2_outlined,
                      selected: major == 'IPS',
                      onTap: () => setState(() => major = 'IPS'))),
            ],
          ),
          const SizedBox(height: 18),
          const PasswordRules(),
          const SizedBox(height: 24),
          AheadButton(
              label: loading ? 'Menyimpan...' : 'Daftar',
              icon: Icons.arrow_forward_rounded,
              onPressed: loading ? () {} : () => submit()),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sudah punya akun? Masuk',
                  style: TextStyle(
                      color: AheadColors.blue, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  int step = 0;
  bool loading = false;
  String? message;
  String? error;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> requestCode() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final generated = await aheadStore.createResetCodeWithApi(email.text);
      if (!mounted) return;
      setState(() {
        error = null;
        message = generated == null || generated.isEmpty
            ? 'Kode reset sudah dibuat. Cek email kamu.'
            : 'Kode reset mode lokal: $generated. Di produksi, kode ini dikirim via email/SMTP.';
        step = 1;
        loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        error = '$err';
        loading = false;
      });
      return;
    }
  }

  Future<void> reset() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    final result = await aheadStore.resetPasswordWithApi(
        email.text, code.text, password.text, confirm.text);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        error = result;
        loading = false;
      });
      return;
    }
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const LoginScreen(
                notice: 'Password berhasil diubah. Silakan masuk kembali.')),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AheadColors.blue)),
          const SizedBox(height: 18),
          const Text('Lupa Password',
              style: TextStyle(
                  color: AheadColors.navy,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
              'Masukkan email, verifikasi kode, lalu buat password baru.',
              style: TextStyle(color: AheadColors.muted, height: 1.45)),
          if (message != null) ...[
            const SizedBox(height: 16),
            InfoBox(message!)
          ],
          if (error != null) ...[const SizedBox(height: 16), ErrorBox(error!)],
          const SizedBox(height: 24),
          if (step == 0) ...[
            AheadTextField(
                controller: email,
                hint: 'Email akun AHEAD',
                icon: Icons.mail_outline_rounded),
            const SizedBox(height: 18),
            AheadButton(
                label: loading ? 'Mengirim...' : 'Kirim Kode',
                icon: Icons.send_rounded,
                onPressed: loading ? () {} : () => requestCode()),
          ] else ...[
            AheadTextField(
                controller: code, hint: 'Kode OTP', icon: Icons.pin_outlined),
            const SizedBox(height: 14),
            AheadTextField(
                controller: password,
                hint: 'Password baru',
                icon: Icons.lock_outline_rounded,
                obscureText: true),
            const SizedBox(height: 14),
            AheadTextField(
                controller: confirm,
                hint: 'Konfirmasi password baru',
                icon: Icons.lock_outline_rounded,
                obscureText: true),
            const SizedBox(height: 18),
            AheadButton(
                label: loading ? 'Menyimpan...' : 'Reset Password',
                icon: Icons.check_rounded,
                onPressed: loading ? () {} : () => reset()),
          ],
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index = widget.initialIndex;

  void _storeListener() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    aheadStore.revision.addListener(_storeListener);
  }

  @override
  void dispose() {
    aheadStore.revision.removeListener(_storeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser;
    if (user == null) return const LoginScreen();
    final pages = [
      HomeDashboard(onTab: (value) => setState(() => index = value)),
      const LearnPage(),
      const PracticePage(),
      const ExamPage(),
      ProfilePage(onTab: (value) => setState(() => index = value)),
    ];
    final titles = ['Beranda', 'Belajar', 'Latihan', 'Ujian', 'Profil'];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AheadTopBar(
                title: titles[index],
                onProfile: () => setState(() => index = 4)),
            Expanded(child: pages[index]),
          ],
        ),
      ),
      bottomNavigationBar: AheadBottomNav(
        index: index,
        onChanged: (value) => setState(() => index = value),
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    final schedule = aheadStore.nextSchedule();
    return AheadScroll(
      children: [
        Text('${_greeting()}, ${user.name.split(' ').first}',
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Siap belajar hari ini?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 18),
        SearchEntry(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen()))),
        const SizedBox(height: 18),
        ScoreCard(user: user),
        const SizedBox(height: 18),
        schedule == null
            ? EmptyCard(
                icon: Icons.event_available_outlined,
                title: 'Belum ada jadwal ujian',
                message:
                    'Tambahkan jadwal agar rekomendasi materi dan latihan bisa menyesuaikan target terdekat.',
                action: 'Tambah Jadwal',
                onPressed: () => openPage(context, const StudyPlanPage()),
              )
            : UpcomingScheduleCard(
                schedule: schedule,
              ),
        if (schedule != null) ...[
          const SizedBox(height: 12),
          ScheduleCountdownSummary(schedule: schedule),
        ],
        const SizedBox(height: 18),
        HomeFocusGrid(onTab: onTab),
        const SizedBox(height: 18),
        RecommendationCard(onPressed: () => onTab(1)),
        const SizedBox(height: 18),
        ContinueLearningCard(onTab: onTab),
        const SizedBox(height: 18),
        TodayTargetCard(user: user),
        const SizedBox(height: 18),
        StreakCard(user: user),
        const SizedBox(height: 22),
        SectionHeader(
            title: 'Eksplorasi Materi',
            action: 'Lihat Semua',
            onTap: () => onTab(1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final subject = aheadStore.subjectsForCurrentUser()[i];
              return SmallSubjectCard(subject: subject);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: aheadStore.subjectsForCurrentUser().length,
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 16) return 'Selamat siang';
    return 'Selamat malam';
  }
}

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    final ordered = aheadStore.subjectsForCurrentUser();
    return AheadScroll(
      children: [
        Text('KURIKULUM MERDEKA X',
            style: TextStyle(
                color: AheadColors.blue,
                letterSpacing: .8,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Pilih Fokus\nBelajarmu',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 29,
                height: 1.15,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        SearchEntry(
            label: 'Cari mata pelajaran atau topik...',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen()))),
        const SizedBox(height: 18),
        FocusCard(
            active: true,
            title:
                user.major == 'IPS' ? 'Sosial & Humaniora' : 'Sains & Eksakta',
            subtitle: user.major == 'IPS'
                ? 'Sejarah, Sosiologi, Ekonomi, Geografi'
                : 'Biologi, Kimia, Fisika',
            icon: user.major == 'IPS'
                ? Icons.groups_2_outlined
                : Icons.science_outlined),
        const SizedBox(height: 14),
        AiMaterialMenuCard(),
        const SizedBox(height: 22),
        SectionHeader(
            title: 'Mata Pelajaran Kelas 10',
            action: '${ordered.length} Modul ${user.major}'),
        const SizedBox(height: 12),
        ...ordered.map((subject) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SubjectListCard(subject: subject),
            )),
      ],
    );
  }
}

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    final materials = aheadStore.materialsForCurrentUser();
    return AheadScroll(
      children: [
        Text('Latihan Soal',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        Text('Pilih materi dulu, lalu tentukan tipe latihanmu.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 18),
        PracticeIntroCard(),
        const SizedBox(height: 18),
        user.practiceResults.isEmpty
            ? WarningCard()
            : AnalysisCard(result: user.practiceResults.last),
        const SizedBox(height: 22),
        SectionHeader(title: 'Pilih Materi untuk Dilatih'),
        const SizedBox(height: 12),
        ...materials.map((material) => PracticeMaterialCard(
              material: material,
              index: materials.indexOf(material),
            )),
      ],
    );
  }
}

class ExamPage extends StatelessWidget {
  const ExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final exams = aheadStore.examsForCurrentUser();
    final featured = exams.first;
    final subjectNames =
        aheadStore.subjectsForCurrentUser().map((item) => item.name).toList();
    return AheadScroll(
      children: [
        Text('Pusat Ujian',
            style: TextStyle(
                fontSize: 24, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 10),
        Text(
            'Pilih modul ujian yang ingin kamu persiapkan, lalu mulai latihan.',
            style: TextStyle(
                fontSize: 20,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 26),
        FeaturedExamCard(exam: featured),
        const SizedBox(height: 22),
        TopicChips(labels: ['Semua Ujian', ...subjectNames]),
        const SizedBox(height: 18),
        ...exams.skip(1).map((exam) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: ExamListCard(exam: exam),
            )),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    return AheadScroll(
      children: [
        AheadCard(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                      radius: 44,
                      backgroundColor: AheadColors.softBlue,
                      child: Icon(Icons.person_rounded,
                          size: 48, color: AheadColors.blue)),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: AheadColors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.local_fire_department_rounded,
                        size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(user.name,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  AheadPill('${user.classLevel}', AheadColors.softBlue),
                  AheadPill(user.major, const Color(0xFFDCE6FF)),
                  AheadPill('${user.streakDays} Hari', AheadColors.peach),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                      child: StatTile(
                          title: 'AHEAD Score',
                          value: '${user.aheadScore}%',
                          suffix: 'Target 85%')),
                  const SizedBox(width: 14),
                  Expanded(
                      child: StatTile(
                          title: 'Status Ujian',
                          value: user.examResults.isEmpty
                              ? 'Belum Ada'
                              : 'Siap Ujian',
                          suffix: '')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Menu Utama',
            style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AheadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                  icon: Icons.trending_up_rounded,
                  title: 'Progres Saya',
                  subtitle: 'Analisis detail & breakdown AHEAD Score',
                  badge: 'Detail',
                  onTap: () => openPage(context, const ProgressPage())),
              MenuRow(
                  icon: Icons.event_note_outlined,
                  title: 'Jadwal Ujian',
                  subtitle: 'Target ujian yang tersinkron ke rekomendasi',
                  dot: true,
                  onTap: () => openPage(context, const StudyPlanPage())),
              MenuRow(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Materi Tersimpan',
                  subtitle: 'Materi pelajaran yang disimpan',
                  badge: '${user.savedMaterialIds.length}',
                  onTap: () => openPage(context, const SavedMaterialsPage())),
              MenuRow(
                  icon: Icons.notes_rounded,
                  title: 'Catatan',
                  subtitle: 'Catatan belajar & rumus cepat',
                  onTap: () => openPage(context, const NotesPage())),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Pengaturan & Aktivitas',
            style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        AheadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MenuRow(
                  icon: Icons.history_rounded,
                  title: 'Riwayat',
                  subtitle: 'Riwayat aktivitas & ujian',
                  onTap: () => openPage(context, const HistoryPage())),
              MenuRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifikasi',
                  subtitle: 'Pengingat & info jadwal',
                  badge: '${user.notifications.where((n) => !n.isRead).length}',
                  onTap: () => openPage(context, const NotificationsPage())),
              MenuRow(
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan & Preferensi',
                  subtitle: 'Akun, target & preferensi aplikasi',
                  onTap: () => openPage(context, const SettingsPage())),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 64,
          child: ElevatedButton.icon(
            onPressed: () {
              aheadStore.logout();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD3CF),
                foregroundColor: AheadColors.danger,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar Akun',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class MaterialDetailPage extends StatefulWidget {
  const MaterialDetailPage({super.key, required this.material});

  final MaterialItem material;

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> {
  late final PageController _slideController = PageController();
  int _slideIndex = 0;

  @override
  void initState() {
    super.initState();
    aheadStore.openMaterial(widget.material);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(widget.material.subjectId);
    final user = aheadStore.currentUser!;
    final progress = user.materialProgress[widget.material.id] ?? 0;
    final saved = user.savedMaterialIds.contains(widget.material.id);
    final slides = aheadStore.materialSlides(widget.material);
    final isLastSlide = _slideIndex == slides.length - 1;
    final rating = user.materialRatings[widget.material.id];
    return DetailScaffold(
      title: widget.material.title,
      child: AheadScroll(
        children: [
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBox(icon: subject.icon),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(subject.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18))),
                    IconButton(
                      onPressed: () => setState(
                          () => aheadStore.toggleSaved(widget.material)),
                      icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: AheadColors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(widget.material.description,
                    style:
                        const TextStyle(color: AheadColors.muted, height: 1.5)),
                const SizedBox(height: 18),
                AheadProgress(value: progress / 100),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MaterialSlideDeck(
            slides: slides,
            controller: _slideController,
            currentIndex: _slideIndex,
            onChanged: (value) => setState(() => _slideIndex = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AheadOutlineButton(
                  label: 'Sebelumnya',
                  icon: Icons.arrow_back_rounded,
                  onPressed: _slideIndex == 0
                      ? () {}
                      : () => _slideController.previousPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AheadButton(
                  label: isLastSlide ? 'Selesai' : 'Selanjutnya',
                  icon: isLastSlide
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: isLastSlide
                      ? () {
                          aheadStore.completeMaterial(widget.material);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MainShell(initialIndex: 1)),
                            (_) => false,
                          );
                        }
                      : () => _slideController.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          ),
                ),
              ),
            ],
          ),
          if (isLastSlide) ...[
            const SizedBox(height: 16),
            RatingExperienceCard(
              title: 'Rating Pengalaman Belajar',
              message: 'Beri nilai 1-10 untuk pengalaman belajar materi ini.',
              rating: rating,
              onChanged: (value) {
                setState(() => aheadStore.rateMaterial(widget.material, value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Rating belajar tersimpan: $value/10.')));
              },
            ),
            const SizedBox(height: 16),
            AheadOutlineButton(
              label: 'Kembali ke Menu Materi',
              icon: Icons.menu_book_outlined,
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const MainShell(initialIndex: 1)),
                (_) => false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PracticeSetupPage extends StatefulWidget {
  const PracticeSetupPage({
    super.key,
    required this.title,
    required this.subjectId,
    required this.minutes,
    this.materialId,
  });

  final String title;
  final int subjectId;
  final int minutes;
  final int? materialId;

  @override
  State<PracticeSetupPage> createState() => _PracticeSetupPageState();
}

class _PracticeSetupPageState extends State<PracticeSetupPage> {
  PracticeMode mode = PracticeMode.multipleChoice;

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(widget.subjectId);
    final questionCount = widget.materialId == null
        ? aheadStore.questionsForSubject(widget.subjectId).take(20).length
        : aheadStore.questionsForMaterial(widget.materialId!).take(20).length;
    return DetailScaffold(
      title: 'Mulai Latihan',
      child: AheadScroll(
        children: [
          AheadCard(
            color: subject.tint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconBox(icon: subject.icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('${subject.name} - $questionCount soal tersedia',
                            style: const TextStyle(color: AheadColors.muted)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                    'Pilih tipe latihan, lalu konfirmasi kesiapanmu sebelum timer dimulai.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceCard(
                  title: 'Pilihan Ganda',
                  subtitle: 'Otomatis dinilai',
                  icon: Icons.checklist_rounded,
                  selected: mode == PracticeMode.multipleChoice,
                  onTap: () =>
                      setState(() => mode = PracticeMode.multipleChoice),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceCard(
                  title: 'Essay',
                  subtitle: 'Jawab singkat',
                  icon: Icons.edit_note_rounded,
                  selected: mode == PracticeMode.essay,
                  onTap: () => setState(() => mode = PracticeMode.essay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Konfirmasi Latihan',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                    'Timer berjalan ${widget.minutes} menit. Jawaban dan tingkat keyakinanmu akan disimpan ke progres akun.',
                    style: const TextStyle(
                        color: AheadColors.muted, height: 1.45)),
                const SizedBox(height: 18),
                AheadButton(
                  label: 'Yakin Banget',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PracticeQuestionPage(
                        title: widget.title,
                        subjectId: widget.subjectId,
                        materialId: widget.materialId,
                        mode: mode,
                        durationMinutes: widget.minutes,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AheadOutlineButton(
                  label: 'Nggak Yakin',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeQuestionPage extends StatefulWidget {
  const PracticeQuestionPage({
    super.key,
    required this.title,
    required this.subjectId,
    this.materialId,
    required this.mode,
    required this.durationMinutes,
  });

  final String title;
  final int subjectId;
  final int? materialId;
  final PracticeMode mode;
  final int durationMinutes;

  @override
  State<PracticeQuestionPage> createState() => _PracticeQuestionPageState();
}

class _PracticeQuestionPageState extends State<PracticeQuestionPage> {
  late final questions = widget.materialId != null &&
          aheadStore.questionsForMaterial(widget.materialId!).isNotEmpty
      ? aheadStore.questionsForMaterial(widget.materialId!).take(20).toList()
      : aheadStore.questionsForSubject(widget.subjectId).isEmpty
          ? aheadStore.questionsForCurrentUser().take(20).toList()
          : aheadStore.questionsForSubject(widget.subjectId).take(20).toList();
  final answers = <int, int>{};
  final confidences = <int, String>{};
  final essayControllers = <int, TextEditingController>{};
  int index = 0;
  late int remaining = widget.durationMinutes * 60;
  Timer? timer;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || finished) return;
      if (remaining <= 1) {
        setState(() => remaining = 0);
        finish();
      } else {
        setState(() => remaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final controller in essayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void finish() {
    if (finished || !mounted) return;
    finished = true;
    timer?.cancel();
    final essayAnswers = <int, String>{};
    if (widget.mode == PracticeMode.essay) {
      for (final question in questions) {
        final text = essayControllers[question.id]?.text.trim() ?? '';
        essayAnswers[question.id] = text;
        answers[question.id] =
            _essayLooksCorrect(question, text) ? question.correctIndex : -1;
      }
    }
    final usedMinutes =
        max(1, widget.durationMinutes - (remaining / 60).floor());
    final result = aheadStore.savePractice(
      widget.title,
      widget.subjectId,
      widget.mode.label,
      questions,
      answers,
      confidences,
      essayAnswers,
      usedMinutes,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PracticeResultPage(result: result, questions: questions),
      ),
    );
  }

  bool _essayLooksCorrect(QuestionItem question, String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    final correct = question.options[question.correctIndex]
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    return correct
        .split(' ')
        .where((part) => part.length > 2)
        .any((part) => normalized.contains(part));
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[index];
    final timerText =
        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
    return DetailScaffold(
      title: 'Latihan',
      child: AheadScroll(
        children: [
          Row(
            children: [
              Expanded(
                  child: AheadProgress(value: (index + 1) / questions.length)),
              const SizedBox(width: 12),
              AheadPill(timerText, AheadColors.peach),
            ],
          ),
          const SizedBox(height: 16),
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AheadPill(widget.mode.label, AheadColors.softBlue),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Soal ${index + 1}/${questions.length}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: AheadColors.blue,
                                fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 18),
                Text(question.question,
                    style: TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 18),
                if (widget.mode == PracticeMode.multipleChoice)
                  ...List.generate(question.options.length, (i) {
                    final selected = answers[question.id] == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OptionTile(
                        label: String.fromCharCode(65 + i),
                        text: question.options[i],
                        selected: selected,
                        onTap: () => setState(() => answers[question.id] = i),
                      ),
                    );
                  })
                else
                  TextField(
                    controller: essayControllers.putIfAbsent(
                        question.id, () => TextEditingController()),
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Tulis jawaban essay singkatmu di sini...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AheadColors.line)),
                    ),
                  ),
                const SizedBox(height: 10),
                ConfidenceBar(
                  selected: confidences[question.id] ?? 'Cukup Yakin',
                  onChanged: (value) =>
                      setState(() => confidences[question.id] = value),
                ),
                const SizedBox(height: 18),
                AheadButton(
                  label:
                      index == questions.length - 1 ? 'Selesai' : 'Selanjutnya',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (index < questions.length - 1) {
                      setState(() => index++);
                    } else {
                      finish();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeResultPage extends StatefulWidget {
  const PracticeResultPage(
      {super.key, required this.result, required this.questions});

  final PracticeResult result;
  final List<QuestionItem> questions;

  @override
  State<PracticeResultPage> createState() => _PracticeResultPageState();
}

class _PracticeResultPageState extends State<PracticeResultPage> {
  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Hasil Latihan',
      child: AheadScroll(
        children: [
          ResultHero(score: widget.result.score, title: widget.result.title),
          const SizedBox(height: 16),
          ResultBreakdown(items: {
            'Mode': widget.result.mode,
            'Benar': widget.result.correct.toString(),
            'Salah': widget.result.wrong.toString(),
            'Durasi': '${widget.result.durationMinutes} menit',
            'Persentase': '${widget.result.score}%',
          }),
          const SizedBox(height: 16),
          ResultAnswerStatusList(
              questions: widget.questions, answers: widget.result.answers),
          const SizedBox(height: 16),
          RatingExperienceCard(
            rating: widget.result.rating,
            onChanged: (value) {
              setState(() => aheadStore.ratePractice(widget.result, value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Rating latihan disimpan: $value/10')));
            },
          ),
          const SizedBox(height: 16),
          AheadButton(
              label: 'Lihat Pembahasan',
              icon: Icons.menu_book_rounded,
              onPressed: () => openPage(
                  context,
                  ExplanationPage(
                      questions: widget.questions,
                      answers: widget.result.answers,
                      essayAnswers: widget.result.essayAnswers))),
          const SizedBox(height: 10),
          AheadOutlineButton(
              label: 'Selesai',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MainShell(initialIndex: 2)),
                  (_) => false)),
        ],
      ),
    );
  }
}

class ExamDetailPage extends StatelessWidget {
  const ExamDetailPage({super.key, required this.exam});

  final ExamItem exam;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Detail Ujian',
      child: AheadScroll(
        children: [
          FeaturedExamCard(exam: exam, compact: true),
          const SizedBox(height: 18),
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Konfirmasi Mulai',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(
                    'Timer berjalan selama ${exam.durationMinutes} menit. Jawaban akan disimpan saat kamu menyelesaikan ujian.',
                    style:
                        const TextStyle(color: AheadColors.muted, height: 1.5)),
                const SizedBox(height: 18),
                AheadButton(
                    label: 'Mulai Ujian',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ExamQuestionPage(exam: exam)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExamQuestionPage extends StatefulWidget {
  const ExamQuestionPage({super.key, required this.exam});

  final ExamItem exam;

  @override
  State<ExamQuestionPage> createState() => _ExamQuestionPageState();
}

class _ExamQuestionPageState extends State<ExamQuestionPage> {
  late final questions = aheadStore
          .questionsForSubject(widget.exam.subjectId)
          .isEmpty
      ? aheadStore.questionsForCurrentUser().take(20).toList()
      : aheadStore.questionsForSubject(widget.exam.subjectId).take(20).toList();
  final answers = <int, int>{};
  int index = 0;
  late int remaining = widget.exam.durationMinutes * 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining <= 0) {
        finish();
      } else {
        setState(() => remaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void finish() {
    timer?.cancel();
    final result = aheadStore.saveExam(
        widget.exam, questions, answers, widget.exam.durationMinutes);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ExamResultPage(
                result: result, questions: questions, answers: answers)));
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[index];
    return DetailScaffold(
      title: 'Pengerjaan Ujian',
      child: AheadScroll(
        children: [
          Row(
            children: [
              Expanded(
                  child: AheadProgress(value: (index + 1) / questions.length)),
              const SizedBox(width: 12),
              AheadPill(
                  '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  AheadColors.peach),
            ],
          ),
          const SizedBox(height: 16),
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soal ${index + 1}/${questions.length}',
                    style: const TextStyle(
                        color: AheadColors.blue, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Text(question.question,
                    style: TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 18),
                ...List.generate(
                    question.options.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OptionTile(
                              label: String.fromCharCode(65 + i),
                              text: question.options[i],
                              selected: answers[question.id] == i,
                              onTap: () =>
                                  setState(() => answers[question.id] = i)),
                        )),
                const SizedBox(height: 18),
                AheadButton(
                  label: index == questions.length - 1
                      ? 'Selesaikan Ujian'
                      : 'Soal Berikutnya',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => index == questions.length - 1
                      ? finish()
                      : setState(() => index++),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExamResultPage extends StatelessWidget {
  const ExamResultPage(
      {super.key,
      required this.result,
      required this.questions,
      required this.answers});

  final ExamResult result;
  final List<QuestionItem> questions;
  final Map<int, int> answers;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Hasil Ujian',
      child: AheadScroll(
        children: [
          ResultHero(score: result.score, title: result.exam.title),
          const SizedBox(height: 16),
          ResultBreakdown(items: {
            'Benar': result.correct.toString(),
            'Salah': result.wrong.toString(),
            'Kosong': result.unanswered.toString(),
            'Waktu': '${result.durationMinutes} menit',
          }),
          const SizedBox(height: 16),
          ResultAnswerStatusList(questions: questions, answers: answers),
          const SizedBox(height: 16),
          AheadButton(
              label: 'Pembahasan Ujian',
              icon: Icons.menu_book_rounded,
              onPressed: () => openPage(context,
                  ExplanationPage(questions: questions, answers: answers))),
          const SizedBox(height: 10),
          AheadOutlineButton(
              label: 'Selesai',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MainShell(initialIndex: 3)),
                  (_) => false)),
        ],
      ),
    );
  }
}

class ExplanationPage extends StatelessWidget {
  const ExplanationPage(
      {super.key,
      required this.questions,
      required this.answers,
      this.essayAnswers = const {}});

  final List<QuestionItem> questions;
  final Map<int, int> answers;
  final Map<int, String> essayAnswers;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Pembahasan',
      child: AheadScroll(
        children: questions.map((question) {
          final answer = answers[question.id];
          final correct = answer == question.correctIndex;
          final answerText = _answerText(question, answer);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AheadCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    AheadPill(
                      correct ? 'Benar' : 'Perlu Ditinjau',
                      correct
                          ? const Color(0xFFDFF7EA)
                          : const Color(0xFFFFE1DD),
                      textColor: correct
                          ? const Color(0xFF087A55)
                          : AheadColors.danger,
                    ),
                    const Spacer(),
                    Text(question.difficulty,
                        style: const TextStyle(
                            color: AheadColors.muted,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  Text(question.question,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 14),
                  AnswerReviewTile(
                      title: 'Jawaban kamu',
                      value: answerText,
                      color: correct
                          ? const Color(0xFFE8F8F1)
                          : const Color(0xFFFFF0EF),
                      icon: correct
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined),
                  const SizedBox(height: 10),
                  AnswerReviewTile(
                      title: 'Jawaban benar',
                      value: question.options[question.correctIndex],
                      color: const Color(0xFFEAF1FF),
                      icon: Icons.lightbulb_outline_rounded),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AheadColors.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pembahasan Singkat',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AheadColors.navy)),
                        const SizedBox(height: 6),
                        Text(question.explanation,
                            style: const TextStyle(
                                color: AheadColors.text, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _answerText(QuestionItem question, int? answer) {
    if (answer == null) return 'Kosong';
    if (answer >= 0 && answer < question.options.length) {
      return question.options[answer];
    }
    final essay = essayAnswers[question.id]?.trim();
    return essay == null || essay.isEmpty ? 'Kosong' : essay;
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  List<Object> results = [];
  String filter = 'Semua';
  final filters = const ['Semua', 'Materi', 'Soal', 'Ujian'];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void runSearch() {
    setState(
        () => results = aheadStore.search(controller.text, filter: filter));
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Pencarian',
      child: AheadScroll(
        children: [
          AheadTextField(
            controller: controller,
            hint: 'Cari materi, soal, atau ujian...',
            icon: Icons.search_rounded,
            onChanged: (_) => runSearch(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final item = filters[i];
                return ChoiceChip(
                  label: Text(item),
                  selected: filter == item,
                  onSelected: (_) {
                    filter = item;
                    runSearch();
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: filters.length,
            ),
          ),
          const SizedBox(height: 18),
          if (controller.text.isNotEmpty && results.isEmpty)
            const EmptyCard(
                icon: Icons.search_off_rounded,
                title: 'Tidak ditemukan.',
                message: 'Coba gunakan kata kunci lain.',
                action: null)
          else
            ...results.map((item) => SearchResultTile(item: item)),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    final empty = user.history.length <= 1 &&
        user.practiceResults.isEmpty &&
        user.examResults.isEmpty &&
        user.materialProgress.isEmpty;
    return DetailScaffold(
      title: 'Progres',
      child: AheadScroll(
        children: [
          ScoreCard(user: user, showAnalysisAction: false),
          const SizedBox(height: 18),
          if (empty)
            const EmptyCard(
                icon: Icons.trending_up_rounded,
                title: 'Belum ada data progres.',
                message: 'Mulai belajar untuk melihat perkembanganmu.',
                action: null)
          else
            ResultBreakdown(items: {
              'Progres Materi': '${user.materialMastery}%',
              'Latihan': '${user.practiceScore}%',
              'Ujian': '${user.examScore}%',
              'Streak': '${user.streakDays} hari',
            }),
          if (!empty) ...[
            const SizedBox(height: 16),
            ConsistencyInsightCard(user: user),
          ],
        ],
      ),
    );
  }
}

class StudyPlanPage extends StatefulWidget {
  const StudyPlanPage({super.key});

  @override
  State<StudyPlanPage> createState() => _StudyPlanPageState();
}

class _StudyPlanPageState extends State<StudyPlanPage> {
  @override
  Widget build(BuildContext context) {
    final schedules = aheadStore.schedulesForCurrentUser();
    return DetailScaffold(
      title: 'Jadwal Ujian',
      action: IconButton(
          onPressed: () => _openScheduleForm(),
          icon: const Icon(Icons.add_rounded, color: AheadColors.blue)),
      child: AheadScroll(
        children: [
          AheadCard(
            color: const Color(0xFFEAF8F1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Pusat Target Ujian',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text(
                    'Jadwal yang kamu buat akan dipakai untuk rekomendasi materi, latihan, dan analisis kesiapan.',
                    style: TextStyle(color: AheadColors.text, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (schedules.isEmpty)
            EmptyCard(
                icon: Icons.event_note_outlined,
                title: 'Belum ada jadwal ujian.',
                message:
                    'Tambahkan jadwal UTS, UAS, atau asesmen supaya sistem bisa menyusun prioritas belajar.',
                action: 'Tambah Jadwal',
                onPressed: () => _openScheduleForm())
          else
            ...schedules.map((schedule) => ScheduleTile(
                  schedule: schedule,
                  onEdit: () => _openScheduleForm(existing: schedule),
                  onDelete: () => _confirmDelete(schedule),
                )),
        ],
      ),
    );
  }

  void _openScheduleForm({ExamScheduleItem? existing}) {
    final subjects = aheadStore.subjectsForCurrentUser();
    final title = TextEditingController(text: existing?.title ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    var selectedSubjectId = existing?.subjectId ?? subjects.first.id;
    var selectedType = existing?.type ?? 'UTS';
    var selectedDate =
        existing?.date ?? DateTime.now().add(const Duration(days: 7));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Tambah Jadwal Ujian' : 'Edit Jadwal'),
        content: StatefulBuilder(builder: (context, setDialogState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: title,
                    decoration: const InputDecoration(
                        labelText: 'Nama ujian',
                        prefixIcon: Icon(Icons.title_rounded))),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(
                      labelText: 'Mata pelajaran',
                      prefixIcon: Icon(Icons.menu_book_outlined)),
                  items: subjects
                      .map((subject) => DropdownMenuItem(
                          value: subject.id, child: Text(subject.name)))
                      .toList(),
                  onChanged: (value) => setDialogState(
                      () => selectedSubjectId = value ?? selectedSubjectId),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                      labelText: 'Jenis ujian',
                      prefixIcon: Icon(Icons.quiz_outlined)),
                  items: const ['UTS', 'UAS', 'Sumatif', 'Diagnostik']
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setDialogState(
                      () => selectedType = value ?? selectedType),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(AheadStore.shortDate(selectedDate)),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: notes,
                    decoration: const InputDecoration(
                        labelText: 'Catatan singkat',
                        prefixIcon: Icon(Icons.notes_outlined))),
              ],
            ),
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isNotEmpty) {
                aheadStore.saveSchedule(ExamScheduleItem(
                  id: existing?.id ??
                      'schedule-${DateTime.now().microsecondsSinceEpoch}',
                  title: title.text.trim(),
                  subjectId: selectedSubjectId,
                  type: selectedType,
                  date: selectedDate,
                  notes: notes.text.trim(),
                ));
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ExamScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text('Jadwal ${schedule.title} akan dihapus dari akun ini.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              aheadStore.deleteSchedule(schedule);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class SavedMaterialsPage extends StatefulWidget {
  const SavedMaterialsPage({super.key});

  @override
  State<SavedMaterialsPage> createState() => _SavedMaterialsPageState();
}

class _SavedMaterialsPageState extends State<SavedMaterialsPage> {
  @override
  Widget build(BuildContext context) {
    final ids = aheadStore.currentUser!.savedMaterialIds;
    final saved =
        aheadStore.materials.where((item) => ids.contains(item.id)).toList();
    return DetailScaffold(
      title: 'Materi Tersimpan',
      child: AheadScroll(
        children: [
          if (saved.isEmpty)
            const EmptyCard(
                icon: Icons.bookmark_border_rounded,
                title: 'Belum ada materi tersimpan.',
                message:
                    'Simpan materi favoritmu agar mudah ditemukan kembali.',
                action: null)
          else
            ...saved.map((item) => SavedMaterialTile(
                  material: item,
                  onRemove: () {
                    setState(() => aheadStore.toggleSaved(item));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${item.title} dihapus dari simpanan.')));
                  },
                )),
        ],
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  Widget build(BuildContext context) {
    final notes = aheadStore.currentUser!.notes;
    return DetailScaffold(
      title: 'Catatan',
      action: IconButton(
          onPressed: _addNote,
          icon: const Icon(Icons.add_rounded, color: AheadColors.blue)),
      child: AheadScroll(
        children: [
          if (notes.isEmpty)
            EmptyCard(
                icon: Icons.notes_rounded,
                title: 'Belum ada catatan.',
                message: 'Buat catatan belajar pertamamu.',
                action: 'Tambah Catatan',
                onPressed: _addNote)
          else
            ...notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AheadCard(
                      child: ListTile(
                          title: Text(note.title),
                          subtitle: Text(note.content),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () {
                                setState(() => notes.remove(note));
                                aheadStore.persistNow();
                              }))),
                )),
        ],
      ),
    );
  }

  void _addNote() {
    final title = TextEditingController();
    final content = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Judul')),
            TextField(
                controller: content,
                decoration: const InputDecoration(labelText: 'Isi')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isNotEmpty) {
                aheadStore.currentUser!.notes.add(NoteItem(
                    title.text.trim(), content.text.trim(), DateTime.now()));
                aheadStore.persistNow();
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = aheadStore.currentUser!.history;
    return DetailScaffold(
      title: 'Riwayat',
      child: AheadScroll(
        children: [
          if (history.isEmpty)
            const EmptyCard(
                icon: Icons.history_rounded,
                title: 'Belum ada riwayat aktivitas.',
                message: 'Aktivitas latihan dan ujianmu akan muncul di sini.',
                action: null)
          else
            ...history.reversed.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AheadCard(
                      child: ListTile(
                          leading: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AheadColors.blue),
                          title: Text(item))),
                )),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = aheadStore.currentUser!.notifications;
    return DetailScaffold(
      title: 'Notifikasi',
      child: AheadScroll(
        children: [
          if (notifications.isEmpty)
            const EmptyCard(
                icon: Icons.notifications_none_rounded,
                title: 'Belum ada notifikasi.',
                message: 'Info jadwal dan pengingat akan muncul di sini.',
                action: null)
          else
            ...notifications.map((item) => AheadCard(
                child: ListTile(
                    title: Text(item.title), subtitle: Text(item.message)))),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final name = TextEditingController(text: aheadStore.currentUser!.name);
  bool studyNotifications = true;
  bool focusMode = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    return DetailScaffold(
      title: 'Pengaturan',
      child: AheadScroll(
        children: [
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Akun',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                AheadTextField(
                    controller: name,
                    hint: 'Nama',
                    icon: Icons.person_outline_rounded),
                const SizedBox(height: 12),
                Text('Email: ${user.email}',
                    style: const TextStyle(color: AheadColors.muted)),
                const SizedBox(height: 18),
                AheadButton(
                  label: 'Simpan Perubahan',
                  icon: Icons.save_outlined,
                  onPressed: () {
                    setState(() => user.name = name.text.trim().isEmpty
                        ? user.name
                        : name.text.trim());
                    aheadStore.persistNow();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pengaturan disimpan.')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AheadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preferensi Belajar',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                SwitchListTile(
                    value: studyNotifications,
                    onChanged: (value) =>
                        setState(() => studyNotifications = value),
                    title: const Text('Notifikasi jadwal belajar')),
                SwitchListTile(
                    value: focusMode,
                    onChanged: (value) => setState(() => focusMode = value),
                    title: const Text('Mode fokus saat ujian')),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: aheadStore.themeMode,
                  builder: (context, mode, _) {
                    return SwitchListTile(
                        value: mode == ThemeMode.dark,
                        onChanged: (_) {
                          setState(() => aheadStore.toggleThemeMode());
                        },
                        title: const Text('Mode malam'),
                        subtitle: const Text('Ubah tampilan siang dan malam'));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = aheadStore.currentUser!.aiMessages;
    return DetailScaffold(
      title: 'AHEAD AI',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (messages.isEmpty)
                  const EmptyCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AHEAD AI',
                      message:
                          'Tanyakan apa saja seputar pelajaran, konsep, rumus, atau soal. AHEAD AI akan menjawab seperti tutor belajar.',
                      action: null)
                else
                  ...messages.map((message) => ChatBubble(message: message)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                    child: AheadTextField(
                        controller: input,
                        hint: 'Tanya materi atau kirim soal...',
                        icon: Icons.chat_bubble_outline_rounded)),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    if (input.text.trim().isEmpty) return;
                    aheadStore.aiReply(input.text.trim());
                    input.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailScaffold extends StatelessWidget {
  const DetailScaffold(
      {super.key, required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded)),
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900))),
                  if (action != null) action!,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class AheadTopBar extends StatelessWidget {
  const AheadTopBar(
      {super.key, required this.title, this.onBack, required this.onProfile});

  final String title;
  final VoidCallback? onBack;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(bottom: BorderSide(color: Color(0x08000000)))),
      child: Row(
        children: [
          if (onBack == null)
            const AheadLogo(size: 30)
          else
            IconButton(
              tooltip: 'Kembali',
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_rounded,
                  color: dark ? Colors.white : AheadColors.navy),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(34, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF243043) : AheadColors.softBlue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: dark ? Colors.white : AheadColors.blue)),
          ),
          const Spacer(),
          IconButton(
              tooltip: dark ? 'Mode siang' : 'Mode malam',
              onPressed: aheadStore.toggleThemeMode,
              icon: Icon(
                  dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
          IconButton(
              onPressed: () => openPage(context, const NotificationsPage()),
              icon: const Icon(Icons.notifications_none_rounded)),
          FilledButton(
            onPressed: onProfile,
            style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                backgroundColor: AheadColors.blue),
            child:
                const Icon(Icons.person_outline_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AheadBottomNav extends StatelessWidget {
  const AheadBottomNav(
      {super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (Icons.home_outlined, 'Beranda'),
      (Icons.menu_book_outlined, 'Belajar'),
      (Icons.handyman_outlined, 'Latihan'),
      (Icons.quiz_outlined, 'Ujian'),
      (Icons.account_circle_outlined, 'Profil'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: const Border(top: BorderSide(color: AheadColors.line))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = i == index;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                    color: active ? AheadColors.softBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].$1,
                        color: active
                            ? AheadColors.blue
                            : (dark ? Colors.white70 : AheadColors.navy),
                        size: 22),
                    const SizedBox(height: 4),
                    Text(items[i].$2,
                        style: TextStyle(
                            fontSize: 11,
                            color: active
                                ? AheadColors.blue
                                : (dark ? Colors.white70 : AheadColors.navy),
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 36),
              child: Stack(
                children: [
                  Positioned(
                    right: -80,
                    bottom: -80,
                    child: Container(
                        width: 220,
                        height: 220,
                        decoration: const BoxDecoration(
                            color: Color(0xFFEAF5FF), shape: BoxShape.circle)),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AheadScroll extends StatelessWidget {
  const AheadScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
      children: children,
    );
  }
}

class AheadCard extends StatelessWidget {
  const AheadCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.color,
      this.border});

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).cardColor;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        border: border,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: child,
    );
  }
}

class AheadButton extends StatelessWidget {
  const AheadButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
            backgroundColor: AheadColors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}

class AheadOutlineButton extends StatelessWidget {
  const AheadOutlineButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF91BBFF)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        icon: Icon(icon, color: AheadColors.blue),
        label: Text(label,
            style: const TextStyle(
                color: AheadColors.blue, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class GoogleAuthButton extends StatefulWidget {
  const GoogleAuthButton({
    super.key,
    required this.label,
    required this.onError,
    required this.onSuccess,
    this.major,
  });

  final String label;
  final String? major;
  final ValueChanged<String> onError;
  final VoidCallback onSuccess;

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  static Future<void>? _initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  late final Future<void> _ready = _prepare();
  bool busy = false;

  Future<void> _prepare() async {
    if (googleClientId.isEmpty) return;
    _initialization ??= GoogleSignIn.instance.initialize(
      clientId: googleClientId,
      serverClientId: googleClientId,
    );
    await _initialization;
    _subscription ??= GoogleSignIn.instance.authenticationEvents
        .listen(_handleAuthenticationEvent)
      ..onError((error) => widget.onError(_googleErrorMessage(error)));
    await GoogleSignIn.instance.attemptLightweightAuthentication();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthenticationEvent(
      GoogleSignInAuthenticationEvent event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      await _submitGoogleAccount(event.user);
    }
  }

  Future<void> _startNativeGoogleSignIn() async {
    if (busy) return;
    if (googleClientId.isEmpty) {
      await _showGoogleSetupDialog();
      return;
    }
    setState(() => busy = true);
    try {
      await _ready;
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        widget.onError(
            'Di Flutter Web, gunakan tombol Google resmi yang muncul di bawah tombol ini.');
        return;
      }
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();
      await _submitGoogleAccount(account);
    } on GoogleSignInException catch (error) {
      widget.onError(_googleErrorMessage(error));
    } catch (error) {
      widget.onError('$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _submitGoogleAccount(GoogleSignInAccount account) async {
    if (busy && !GoogleSignIn.instance.supportsAuthenticate()) return;
    if (mounted) setState(() => busy = true);
    try {
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        widget.onError('Token Google tidak tersedia. Coba masuk ulang.');
        return;
      }
      final result = await aheadStore.loginWithGoogleToken(
        idToken: idToken,
        major: widget.major,
      );
      if (!mounted) return;
      if (result != null) {
        final fallback = await aheadStore.loginWithGoogleProfile(
          email: account.email,
          name: account.displayName ?? '',
          major: widget.major,
          photoUrl: account.photoUrl,
        );
        if (!mounted) return;
        if (fallback != null) {
          widget.onError(result);
          return;
        }
      }
      widget.onSuccess();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _googleErrorMessage(Object error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Login Google dibatalkan.';
      }
      return 'Login Google gagal: ${error.description ?? error.code.name}';
    }
    return '$error'.replaceFirst('Exception: ', '');
  }

  Future<void> _showGoogleSetupDialog() {
    return showConfigDialog(
      context,
      'Google Sign-In belum siap',
      'Agar muncul pilihan akun Gmail resmi, isi GOOGLE_CLIENT_ID dari Google Cloud di backend/.env, lalu jalankan ulang lewat JALANKAN_AHEAD.bat. Setelah aktif, aplikasi akan memaksa pilih akun ulang sebelum login.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (googleClientId.isEmpty) {
      return AheadOutlineButton(
        label: busy ? 'Memproses Google...' : widget.label,
        icon: Icons.g_mobiledata_rounded,
        onPressed: busy ? () {} : _startNativeGoogleSignIn,
      );
    }
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AheadOutlineButton(
            label: 'Menyiapkan Google...',
            icon: Icons.g_mobiledata_rounded,
            onPressed: () {},
          );
        }
        if (snapshot.hasError) {
          return AheadOutlineButton(
            label: widget.label,
            icon: Icons.g_mobiledata_rounded,
            onPressed: () =>
                widget.onError(_googleErrorMessage(snapshot.error!)),
          );
        }
        if (kIsWeb && !GoogleSignIn.instance.supportsAuthenticate()) {
          return Column(
            children: [
              AheadOutlineButton(
                label: busy ? 'Memproses Google...' : widget.label,
                icon: Icons.g_mobiledata_rounded,
                onPressed: busy ? () {} : _startNativeGoogleSignIn,
              ),
              const SizedBox(height: 10),
              Center(child: google_web.renderGoogleSignInButton()),
            ],
          );
        }
        return AheadOutlineButton(
          label: busy ? 'Memproses Google...' : widget.label,
          icon: Icons.g_mobiledata_rounded,
          onPressed: busy ? () {} : _startNativeGoogleSignIn,
        );
      },
    );
  }
}

class AheadTextField extends StatelessWidget {
  const AheadTextField(
      {super.key,
      required this.controller,
      required this.hint,
      required this.icon,
      this.obscureText = false,
      this.trailing,
      this.onChanged});

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AheadColors.muted),
        suffixIcon: trailing,
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8E4F5))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8E4F5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AheadColors.blue)),
      ),
    );
  }
}

class AheadSelect extends StatelessWidget {
  const AheadSelect(
      {super.key,
      required this.value,
      required this.items,
      required this.icon,
      required this.onChanged});

  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AheadColors.muted),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8E4F5))),
      ),
    );
  }
}

class AheadLogo extends StatelessWidget {
  const AheadLogo({super.key, required this.size, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Colors.white : AheadColors.navy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size, size), painter: AheadLogoPainter()),
        if (showText) ...[
          SizedBox(width: size > 40 ? 10 : 7),
          Text('AHEAD',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontSize: size > 50 ? 28 : 19)),
        ],
      ],
    );
  }
}

class AheadLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          const LinearGradient(colors: [AheadColors.cyan, AheadColors.blue])
              .createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(size.width * .50, size.height * .05)
      ..lineTo(size.width * .88, size.height * .90)
      ..lineTo(size.width * .70, size.height * .90)
      ..lineTo(size.width * .58, size.height * .62)
      ..lineTo(size.width * .33, size.height * .62)
      ..lineTo(size.width * .22, size.height * .90)
      ..lineTo(size.width * .04, size.height * .90)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
        Offset(size.width * .36, size.height * .50),
        Offset(size.width * .68, size.height * .50),
        Paint()
          ..color = Colors.white
          ..strokeWidth = size.width * .08
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(size.width * .50, size.height * .16),
        Offset(size.width * .50, size.height * .78),
        Paint()
          ..color = Colors.white.withValues(alpha: .72)
          ..strokeWidth = size.width * .055
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AheadWordmark extends StatelessWidget {
  const AheadWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AheadLogo(size: 74),
        SizedBox(height: 8),
        Text('Prepare Today. Stay AHEAD.',
            style: TextStyle(color: AheadColors.navy, fontSize: 12)),
      ],
    );
  }
}

class BottomBranding extends StatelessWidget {
  const BottomBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('A H E A D',
            style: TextStyle(
                color: AheadColors.blue,
                letterSpacing: 4,
                fontWeight: FontWeight.w900)),
        SizedBox(height: 6),
        Text('Prepare Today. Stay AHEAD.',
            style: TextStyle(color: AheadColors.navy, fontSize: 12)),
      ],
    );
  }
}

class ScoreCard extends StatelessWidget {
  const ScoreCard(
      {super.key, required this.user, this.showAnalysisAction = true});

  final AheadUser user;
  final bool showAnalysisAction;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('INDEKS KESIAPAN\nUJIAN',
                      style: TextStyle(
                          color: AheadColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7))),
              AheadPill(
                  user.practiceResults.isEmpty
                      ? '0% minggu ini'
                      : '+${user.practiceScore}% minggu ini',
                  const Color(0xFFDDE2FF)),
            ],
          ),
          const SizedBox(height: 12),
          Text('AHEAD Score',
              style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          Row(
            children: [
              CircularScore(value: user.aheadScore),
              const SizedBox(width: 20),
              Expanded(
                child: Wrap(
                  runSpacing: 10,
                  children: [
                    MetricText(
                        'Penguasaan\nMateri', '${user.materialMastery}%'),
                    MetricText('Latihan', '${user.practiceScore}%'),
                    MetricText('Ujian', '${user.examScore}%'),
                    MetricText('Konsistensi', '${user.consistency}%'),
                  ],
                ),
              ),
            ],
          ),
          if (showAnalysisAction) ...[
            const SizedBox(height: 18),
            AheadOutlineButton(
                label: 'Lihat Analisis Mendalam',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => openPage(context, const ProgressPage())),
          ],
        ],
      ),
    );
  }
}

class CircularScore extends StatelessWidget {
  const CircularScore({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
              value: max(.01, value / 100),
              strokeWidth: 7,
              backgroundColor: const Color(0xFFE7ECF4),
              color: AheadColors.blue),
          Text('$value%',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class MetricText extends StatelessWidget {
  const MetricText(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AheadColors.muted, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.menu_book_outlined, 'Materi', 1),
      (Icons.handyman_outlined, 'Latihan', 2),
      (Icons.quiz_outlined, 'Ujian', 3),
      (Icons.trending_up_rounded, 'Progres', -1),
    ];
    return Row(
      children: actions.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => item.$3 == -1
                  ? openPage(context, const ProgressPage())
                  : onTab(item.$3),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 12)
                    ]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: AheadColors.softBlue,
                            borderRadius: BorderRadius.circular(10)),
                        child:
                            Icon(item.$1, color: AheadColors.blue, size: 18)),
                    const SizedBox(height: 7),
                    Text(item.$2,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class HomeFocusGrid extends StatelessWidget {
  const HomeFocusGrid({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.calendar_month_outlined,
        'Jadwal Ujian',
        'Atur target dekat',
        const Color(0xFFE9F0FF),
        () => openPage(context, const StudyPlanPage())
      ),
      (
        Icons.psychology_alt_outlined,
        'Latihan Adaptif',
        'Soal sesuai jurusan',
        const Color(0xFFFFEDEA),
        () => onTab(2)
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 12.0;
      final cardWidth = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: items.map((item) {
          return SizedBox(
            width: cardWidth,
            height: 104,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: item.$5,
              child: AheadCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.$4,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.$1, color: AheadColors.blue, size: 19),
                    ),
                    const Spacer(),
                    Text(item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(item.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AheadColors.muted)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.action,
      this.onPressed});

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon: icon, color: AheadColors.softBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text(message,
                    style:
                        const TextStyle(color: AheadColors.muted, height: 1.4)),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                      width: 170,
                      height: 42,
                      child: FilledButton(
                          onPressed: onPressed, child: Text(action!))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AheadCard(
      color: const Color(0xFFFFF0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AheadColors.danger),
              SizedBox(width: 10),
              Expanded(
                  child: Text('ANALISIS KESALAHAN',
                      style: TextStyle(
                          color: AheadColors.danger,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: .7))),
              AheadPill('Perlu Perhatian', Color(0xFFFFDDE0)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Belum ada data latihan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
              'Kerjakan latihan pertama agar AHEAD dapat menganalisis topik yang perlu diperkuat.',
              style: TextStyle(color: AheadColors.text, height: 1.45)),
        ],
      ),
    );
  }
}

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.result});

  final PracticeResult result;

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(result.subjectId);
    final confidence = result.confidences.values.isEmpty
        ? 'belum tercatat'
        : result.confidences.values.last;
    return AheadCard(
      color: const Color(0xFFFFF0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.analytics_outlined, color: AheadColors.danger),
            SizedBox(width: 10),
            Text('ANALISIS LATIHAN TERAKHIR',
                style: TextStyle(
                    color: AheadColors.danger,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: .7)),
          ]),
          const SizedBox(height: 12),
          Text('${subject.name}: ${result.score}%',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
              'Benar ${result.correct}, salah ${result.wrong}. Keyakinan terakhir: $confidence. Gunakan pembahasan untuk melihat pola kesalahan.',
              style: const TextStyle(color: AheadColors.text, height: 1.45)),
        ],
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final material = aheadStore.recommendedMaterial();
    final subject =
        material == null ? null : aheadStore.subjectById(material.subjectId);
    return AheadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REKOMENDASI CERDAS',
              style: TextStyle(
                  color: AheadColors.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(material?.title ?? 'Mulai dari materi jurusanmu',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          if (subject != null) AheadPill(subject.name, subject.tint),
          if (subject != null) const SizedBox(height: 8),
          Text(aheadStore.recommendationReason(),
              style: const TextStyle(color: AheadColors.muted, height: 1.45)),
          const SizedBox(height: 14),
          AheadButton(
              label: 'Mulai Belajar Sekarang',
              icon: Icons.play_arrow_rounded,
              onPressed: material == null
                  ? onPressed
                  : () => openPage(
                      context, MaterialDetailPage(material: material))),
        ],
      ),
    );
  }
}

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    if (user.materialProgress.isEmpty) {
      return EmptyCard(
          icon: Icons.menu_book_outlined,
          title: 'Belum ada materi yang sedang dipelajari.',
          message: 'Mulai belajar untuk melihat progresmu di sini.',
          action: 'Buka Materi',
          onPressed: () => onTab(1));
    }
    final entry = user.materialProgress.entries.first;
    final material =
        aheadStore.materials.firstWhere((item) => item.id == entry.key);
    return AheadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LANJUTKAN BELAJAR',
              style: TextStyle(color: AheadColors.muted, fontSize: 12)),
          const SizedBox(height: 12),
          MaterialTile(material: material),
          const SizedBox(height: 8),
          AheadProgress(value: entry.value / 100),
        ],
      ),
    );
  }
}

class TodayTargetCard extends StatelessWidget {
  const TodayTargetCard({super.key, required this.user});

  final AheadUser user;

  @override
  Widget build(BuildContext context) {
    final minutes = user.history.isEmpty ? 0 : min(20, user.history.length * 5);
    return AheadCard(
      child: Column(
        children: [
          Row(
            children: [
              const IconBox(icon: Icons.flag_outlined),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Target Hari Ini',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16))),
              Text('$minutes/20 min',
                  style: const TextStyle(
                      color: AheadColors.blue, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          AheadProgress(value: minutes / 20),
          const SizedBox(height: 14),
          if (minutes == 0)
            const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Checklist kosong. Mulai aktivitas belajar untuk mengisinya.',
                    style: TextStyle(color: AheadColors.muted)))
          else
            const ChecklistText('Belajar minimal 20 menit'),
        ],
      ),
    );
  }
}

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.user});

  final AheadUser user;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFFF720D), size: 34),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${user.streakDays} Days Streak',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Konsisten menuju ujian kelas 10',
                  style: TextStyle(color: AheadColors.muted, fontSize: 12)),
            ]),
          ),
          AheadPill(user.streakDays == 0 ? 'Mulai Hari Ini' : 'Level Rajin',
              AheadColors.peach),
        ],
      ),
    );
  }
}

class SmallSubjectCard extends StatelessWidget {
  const SmallSubjectCard({super.key, required this.subject});

  final SubjectItem subject;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openPage(context, SubjectDetailPage(subject: subject)),
      child: Container(
        width: 126,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 12)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBox(icon: subject.icon),
          const Spacer(),
          Text(subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800)),
          Text('${aheadStore.materialsForSubject(subject.id).length} Modul',
              style: const TextStyle(color: AheadColors.muted, fontSize: 11)),
        ]),
      ),
    );
  }
}

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key, required this.subject});

  final SubjectItem subject;

  @override
  Widget build(BuildContext context) {
    final materials = aheadStore.materialsForSubject(subject.id);
    return DetailScaffold(
      title: subject.name,
      child: AheadScroll(
        children: [
          AheadCard(
              child: Text(subject.description,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.45))),
          const SizedBox(height: 16),
          ...materials.map((item) => MaterialTile(material: item)),
          if (materials.isEmpty)
            const EmptyCard(
                icon: Icons.menu_book_outlined,
                title: 'Materi belum tersedia.',
                message: 'Materi sistem dapat ditambahkan dari backend.',
                action: null),
        ],
      ),
    );
  }
}

class SubjectListCard extends StatelessWidget {
  const SubjectListCard({super.key, required this.subject});

  final SubjectItem subject;

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    final subjectMaterials = aheadStore.materialsForSubject(subject.id);
    final progress = subjectMaterials.isEmpty
        ? 0
        : (subjectMaterials
                    .map((m) => user.materialProgress[m.id] ?? 0)
                    .fold<int>(0, (a, b) => a + b) /
                subjectMaterials.length)
            .round();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openPage(context, SubjectDetailPage(subject: subject)),
      child: AheadCard(
        child: Column(
          children: [
            Row(
              children: [
                IconBox(icon: subject.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(subject.name,
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface))),
                          if (subject.id == 1)
                            const AheadPill('Wajib', AheadColors.softBlue)
                        ]),
                        const SizedBox(height: 4),
                        Text(subject.description,
                            style: const TextStyle(
                                color: AheadColors.muted, fontSize: 12)),
                      ]),
                ),
                const Icon(Icons.bookmark_border_rounded,
                    color: AheadColors.muted),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Penguasaan Materi', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Text('$progress%',
                  style: const TextStyle(
                      color: AheadColors.blue, fontWeight: FontWeight.w900))
            ]),
            const SizedBox(height: 8),
            AheadProgress(value: progress / 100),
          ],
        ),
      ),
    );
  }
}

class MaterialTile extends StatelessWidget {
  const MaterialTile({super.key, required this.material});

  final MaterialItem material;

  @override
  Widget build(BuildContext context) {
    final progress = aheadStore.currentUser!.materialProgress[material.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => openPage(context, MaterialDetailPage(material: material)),
        child: AheadCard(
          child: Row(
            children: [
              const IconBox(icon: Icons.article_outlined),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(material.title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(material.description,
                        style: const TextStyle(
                            color: AheadColors.muted, fontSize: 12))
                  ])),
              Text('$progress%',
                  style: const TextStyle(
                      color: AheadColors.blue, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusCard extends StatelessWidget {
  const FocusCard(
      {super.key,
      required this.active,
      required this.title,
      required this.subtitle,
      required this.icon});

  final bool active;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: active ? AheadColors.blue2 : const Color(0xFFDCE6FF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 6))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(
              icon: icon,
              color: active ? Colors.white24 : const Color(0xFFC5D3F0),
              iconColor: active ? Colors.white : AheadColors.muted),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  color: active ? Colors.white : AheadColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: active ? Colors.white70 : AheadColors.muted,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class AiMaterialMenuCard extends StatelessWidget {
  const AiMaterialMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      color: const Color(0xFFFFF4D8),
      child: Row(
        children: [
          const IconBox(
              icon: Icons.auto_awesome_outlined,
              color: Color(0xFFFFE4A8),
              iconColor: Color(0xFF9A5A00)),
          const SizedBox(width: 12),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AHEAD AI',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AheadColors.navy)),
              SizedBox(height: 4),
              Text('Tanya konsep, rumus, soal, atau materi apa pun.',
                  style: TextStyle(color: AheadColors.text, height: 1.35)),
            ]),
          ),
          IconButton(
              tooltip: 'Buka AHEAD AI',
              onPressed: () => openPage(context, const AiPage()),
              icon: const Icon(Icons.arrow_forward_rounded,
                  color: AheadColors.blue)),
        ],
      ),
    );
  }
}

class PracticeIntroCard extends StatelessWidget {
  const PracticeIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      color: const Color(0xFFEAF8F1),
      child: Row(
        children: const [
          IconBox(
              icon: Icons.route_outlined,
              color: Color(0xFFD7F2E5),
              iconColor: Color(0xFF087A55)),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Alur Latihan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text(
                  'Pilih materi, pilih Pilihan Ganda atau Essay, lalu kerjakan 20 soal.',
                  style: TextStyle(color: AheadColors.text, height: 1.35)),
            ]),
          ),
        ],
      ),
    );
  }
}

class PracticeMaterialCard extends StatelessWidget {
  const PracticeMaterialCard({
    super.key,
    required this.material,
    required this.index,
  });

  final MaterialItem material;
  final int index;

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(material.subjectId);
    final progress = aheadStore.currentUser!.materialProgress[material.id] ?? 0;
    final count = aheadStore.questionsForMaterial(material.id).length;
    final accent = _practiceAccent(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => startPractice(
          context,
          material.title,
          material.subjectId,
          materialId: material.id,
          minutes: 20,
        ),
        child: AheadCard(
          color: Color.lerp(accent, Colors.white, .78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconBox(icon: subject.icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(material.title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AheadColors.navy)),
                      Text(subject.name,
                          style: const TextStyle(color: AheadColors.muted)),
                    ],
                  ),
                ),
                AheadPill('$count soal', Colors.white),
              ]),
              const SizedBox(height: 12),
              Text(material.description,
                  style: const TextStyle(color: AheadColors.text, height: 1.4)),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Progres materi', style: TextStyle(fontSize: 12)),
                const Spacer(),
                Text('$progress%',
                    style: const TextStyle(
                        color: AheadColors.blue, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 8),
              AheadProgress(value: progress / 100, color: accent),
              const SizedBox(height: 14),
              FilledButton.icon(
                  onPressed: () => startPractice(
                        context,
                        material.title,
                        material.subjectId,
                        materialId: material.id,
                        minutes: 20,
                      ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Pilih Materi Ini')),
            ],
          ),
        ),
      ),
    );
  }

  Color _practiceAccent(int value) {
    const colors = [
      Color(0xFF16B886),
      Color(0xFFF97316),
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFFE11D48),
      Color(0xFF84CC16),
      Color(0xFFF59E0B),
    ];
    return colors[value % colors.length];
  }
}

class PracticeCard extends StatelessWidget {
  const PracticeCard(
      {super.key,
      required this.title,
      required this.subjectId,
      required this.minutes,
      required this.color});

  final String title;
  final int subjectId;
  final int minutes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(subjectId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AheadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              AheadPill(subject.name, AheadColors.softBlue),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 15),
              Text(' $minutes Menit', style: const TextStyle(fontSize: 11))
            ]),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                'Topik: ${aheadStore.materialsForSubject(subjectId).firstOrNull?.title ?? subject.description}',
                style: const TextStyle(color: AheadColors.text)),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('Level: ${subjectId == 1 ? 'Menengah' : 'Lanjutan'}',
                  style:
                      const TextStyle(color: AheadColors.muted, fontSize: 11)),
              const Spacer(),
              FilledButton(
                  onPressed: () => startPractice(context, title, subjectId,
                      minutes: minutes),
                  child: const Text('Mulai'))
            ]),
          ],
        ),
      ),
    );
  }
}

class FeaturedExamCard extends StatelessWidget {
  const FeaturedExamCard({super.key, required this.exam, this.compact = false});

  final ExamItem exam;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: const Color(0xFFDCE3FF),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconBox(
                icon: Icons.military_tech_outlined,
                color: AheadColors.blue,
                iconColor: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('REKOMENDASI UTAMA',
                    style: TextStyle(
                        color: AheadColors.navy,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900))),
            AheadPill('${exam.durationMinutes} Menit', AheadColors.blue,
                textColor: Colors.white)
          ]),
          const SizedBox(height: 14),
          Text(exam.title,
              style: const TextStyle(fontSize: 22, color: AheadColors.navy)),
          const SizedBox(height: 18),
          Text(exam.description,
              style: const TextStyle(
                  fontSize: 17, height: 1.45, color: AheadColors.navy)),
          const SizedBox(height: 22),
          Row(children: [
            Text('${exam.totalQuestions} Soal Pilihan Ganda',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AheadColors.navy)),
            const Spacer(),
            FilledButton(
                onPressed: () => openPage(context, ExamDetailPage(exam: exam)),
                child: const Text('Mulai Ujian'))
          ]),
        ],
      ),
    );
  }
}

class ExamListCard extends StatelessWidget {
  const ExamListCard({super.key, required this.exam});

  final ExamItem exam;

  @override
  Widget build(BuildContext context) {
    final user = aheadStore.currentUser!;
    final subject = aheadStore.subjectById(exam.subjectId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final readiness = exam.id == 4 ? 0 : user.materialMastery;
    return AheadCard(
      color: dark
          ? Color.lerp(subject.tint, const Color(0xFF111827), .78)!
          : Colors.white,
      border: Border.all(
          color: dark
              ? const Color(0xFF334155)
              : Color.lerp(subject.tint, AheadColors.blue, .18)!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    subject.tint,
                    Color.lerp(subject.tint, AheadColors.blue, .45)!,
                  ],
                ),
              ),
              child: Icon(subject.icon, color: AheadColors.blue, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    AheadPill(
                        exam.type,
                        exam.id == 3
                            ? AheadColors.peach
                            : AheadColors.softBlue),
                    AheadPill(subject.name, subject.tint,
                        textColor: AheadColors.navy),
                  ]),
                  const SizedBox(height: 10),
                  Text(exam.title,
                      style: TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Text(exam.description,
                      style: TextStyle(
                          color: dark
                              ? const Color(0xFFC7D2FE)
                              : AheadColors.muted,
                          height: 1.35))
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            const Text('Kesiapan Materi'),
            const Spacer(),
            Text(readiness == 0 ? 'Belum Dimulai' : '$readiness%',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AheadColors.blue))
          ]),
          const SizedBox(height: 8),
          AheadProgress(
              value: readiness / 100,
              color: exam.id == 3 ? const Color(0xFFC23300) : AheadColors.blue),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E293B) : AheadColors.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Icon(Icons.format_list_numbered_rounded,
                  size: 18, color: AheadColors.blue),
              Text(' ${exam.totalQuestions} soal'),
              const SizedBox(width: 16),
              Icon(Icons.schedule_rounded, size: 18, color: AheadColors.blue),
              Text(' ${exam.durationMinutes} menit'),
              const Spacer(),
              FilledButton.icon(
                  onPressed: () =>
                      openPage(context, ExamDetailPage(exam: exam)),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Mulai'))
            ]),
          ),
        ],
      ),
    );
  }
}

class ResultHero extends StatelessWidget {
  const ResultHero({super.key, required this.score, required this.title});

  final int score;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      color: AheadColors.softBlue,
      child: Column(
        children: [
          CircularScore(value: score),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class ResultBreakdown extends StatelessWidget {
  const ResultBreakdown({super.key, required this.items});

  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      child: Column(
        children: items.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text(entry.key),
                    const Spacer(),
                    Text(entry.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AheadColors.blue))
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

class ResultAnswerStatusList extends StatelessWidget {
  const ResultAnswerStatusList({
    super.key,
    required this.questions,
    required this.answers,
  });

  final List<QuestionItem> questions;
  final Map<int, int> answers;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Jawaban',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(questions.length, (index) {
              final question = questions[index];
              final answer = answers[question.id];
              final correct = answer == question.correctIndex;
              final empty = answer == null;
              return Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: empty
                      ? const Color(0xFFE9EDF3)
                      : correct
                          ? const Color(0xFFDFF7EA)
                          : const Color(0xFFFFE1DD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: empty
                        ? AheadColors.line
                        : correct
                            ? AheadColors.success
                            : AheadColors.danger,
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: empty
                        ? AheadColors.muted
                        : correct
                            ? const Color(0xFF087A55)
                            : AheadColors.danger,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class SearchEntry extends StatelessWidget {
  const SearchEntry(
      {super.key,
      required this.onTap,
      this.label = 'Cari materi, soal, atau ujian...'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AheadColors.line)),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: AheadColors.muted),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: AheadColors.muted))),
          const Icon(Icons.tune_rounded, color: AheadColors.muted)
        ]),
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  const ChoiceCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.selected,
      required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AheadColors.blue : const Color(0xFFD8E4F5),
                width: selected ? 2 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AheadColors.blue),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
          Text(subtitle,
              style: const TextStyle(color: AheadColors.muted, fontSize: 11))
        ]),
      ),
    );
  }
}

class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key});

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      color: const Color(0xFFF0F7FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Password harus memenuhi:',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AheadColors.navy)),
          SizedBox(height: 8),
          ChecklistText('Minimal 8 karakter'),
          ChecklistText('Mengandung huruf besar'),
          ChecklistText('Mengandung angka'),
        ],
      ),
    );
  }
}

class ChecklistText extends StatelessWidget {
  const ChecklistText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          const Icon(Icons.check_box_rounded,
              color: AheadColors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: const TextStyle(color: AheadColors.text)))
        ]),
      );
}

class AheadPill extends StatelessWidget {
  const AheadPill(this.text, this.color, {super.key, this.textColor});

  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Text(text,
          style: TextStyle(
              color: textColor ?? AheadColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox(
      {super.key,
      required this.icon,
      this.color = AheadColors.softBlue,
      this.iconColor = AheadColors.blue});

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor));
  }
}

class AheadProgress extends StatelessWidget {
  const AheadProgress(
      {super.key, required this.value, this.color = AheadColors.blue});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 7,
          backgroundColor: const Color(0xFFE9EDF3),
          color: color),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key, required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900))),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!))
    ]);
  }
}

class TopicChips extends StatelessWidget {
  const TopicChips({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) => Chip(
            label: Text(labels[i]),
            backgroundColor:
                i == 0 ? AheadColors.blue : const Color(0xFFE9EDF2),
            labelStyle: TextStyle(
                color: i == 0
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface)),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: labels.length,
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile(
      {super.key,
      required this.label,
      required this.text,
      required this.selected,
      required this.onTap});

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF1FF)
                : Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF111827)
                    : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AheadColors.blue : AheadColors.line,
                width: selected ? 2 : 1)),
        child: Row(children: [
          CircleAvatar(
              radius: 13,
              backgroundColor:
                  selected ? AheadColors.blue : const Color(0xFFE9EDF3),
              child: Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : AheadColors.navy,
                      fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)))
        ]),
      ),
    );
  }
}

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar(
      {super.key, required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ['Menebak', 'Cukup Yakin', 'Sangat Yakin'];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: dark ? const Color(0xFF111827) : const Color(0xFFF2F5FA),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Text('Seberapa yakin kamu dengan jawabanmu?',
            style: TextStyle(fontSize: 11)),
        const SizedBox(height: 10),
        Row(
            children: options.map((option) {
          final active = selected == option;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFDCE3FF)
                        : dark
                            ? const Color(0xFF1F2937)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: active ? AheadColors.blue : AheadColors.line),
                  ),
                  child: Text(option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: active
                              ? AheadColors.blue
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              active ? FontWeight.w900 : FontWeight.w500)),
                ),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key,
      required this.title,
      required this.value,
      required this.suffix});

  final String title;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827)
              : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AheadColors.blue)),
        if (suffix.isNotEmpty)
          Text(suffix,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface))
      ]),
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.badge,
      this.dot = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 16,
      leading: IconBox(
          icon: icon,
          color: icon == Icons.bookmark_border_rounded
              ? AheadColors.peach
              : const Color(0xFFE9EDF3),
          iconColor: AheadColors.navy),
      title: Text(title,
          style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(subtitle),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) const Icon(Icons.circle, color: AheadColors.blue, size: 10),
        if (badge != null)
          AheadPill(
              badge!, badge == '0' ? const Color(0xFFE9EDF3) : AheadColors.blue,
              textColor: badge == '0' ? AheadColors.navy : Colors.white),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded)
      ]),
    );
  }
}

class PlanTile extends StatelessWidget {
  const PlanTile({super.key, required this.plan, required this.onChanged});

  final StudyPlanItem plan;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AheadCard(
        child: CheckboxListTile(
          value: plan.completed,
          onChanged: (value) {
            plan.completed = value ?? false;
            onChanged();
          },
          title: Text(plan.title),
          subtitle: Text('${plan.subject} - ${plan.duration} menit'),
        ),
      ),
    );
  }
}

class ScheduleTile extends StatelessWidget {
  const ScheduleTile({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  final ExamScheduleItem schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(schedule.subjectId);
    final readiness = aheadStore.readinessForSubject(schedule.subjectId);
    final urgent = schedule.daysLeft <= 7 && schedule.daysLeft >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: urgent
                ? const [Color(0xFFFFE0C2), Color(0xFFFFF7EC)]
                : const [Color(0xFFFFF1D6), Color(0xFFFFFFFF)],
          ),
          border: Border.all(color: const Color(0xFFFFC36B)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1AFF8A00), blurRadius: 24, offset: Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFFFF6B2A),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x55FF6B2A),
                          blurRadius: 18,
                          offset: Offset(0, 8))
                    ]),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900)),
                    Text('${subject.name} - ${schedule.type}',
                        style: const TextStyle(color: AheadColors.muted)),
                  ],
                ),
              ),
              LiveScheduleCountdownPill(
                schedule: schedule,
                color:
                    schedule.daysLeft <= 3 ? AheadColors.peach : subject.tint,
                textColor: AheadColors.navy,
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xC7FFFFFF),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.whatshot_rounded, color: Color(0xFFFF5A1F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        schedule.daysLeft < 0
                            ? 'Jadwal ini sudah lewat. Evaluasi hasilmu dan susun target berikutnya.'
                            : schedule.daysLeft == 0
                                ? 'Hari ujian tiba. Tenang, baca ulang catatan inti, lalu mulai dengan percaya diri.'
                                : 'Masih ada ${schedule.daysLeft} hari untuk membakar semangat belajar dan menutup materi yang belum kuat.',
                        style: const TextStyle(
                            color: AheadColors.text,
                            height: 1.35,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            if (schedule.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(schedule.notes,
                  style: const TextStyle(color: AheadColors.text, height: 1.4)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              const Text('Kesiapan materi', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Text('$readiness%',
                  style: const TextStyle(
                      color: AheadColors.blue, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            AheadProgress(value: readiness / 100),
            const SizedBox(height: 14),
            Row(children: [
              OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit')),
              const SizedBox(width: 8),
              IconButton(
                  tooltip: 'Hapus jadwal',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AheadColors.danger)),
              const Spacer(),
              Text('Timeline ujian',
                  style: TextStyle(
                      color: Colors.deepOrange.shade700,
                      fontWeight: FontWeight.w900)),
            ]),
          ],
        ),
      ),
    );
  }
}

class SavedMaterialTile extends StatelessWidget {
  const SavedMaterialTile({
    super.key,
    required this.material,
    required this.onRemove,
  });

  final MaterialItem material;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final progress = aheadStore.currentUser!.materialProgress[material.id] ?? 0;
    final subject = aheadStore.subjectById(material.subjectId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AheadCard(
        child: Row(
          children: [
            IconBox(icon: subject.icon, color: subject.tint),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () =>
                    openPage(context, MaterialDetailPage(material: material)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material.title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('${subject.name} - $progress% selesai',
                        style: const TextStyle(
                            color: AheadColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
            IconButton(
                tooltip: 'Hapus dari simpanan',
                onPressed: onRemove,
                icon: const Icon(Icons.bookmark_remove_outlined,
                    color: AheadColors.danger)),
          ],
        ),
      ),
    );
  }
}

class ConsistencyInsightCard extends StatelessWidget {
  const ConsistencyInsightCard({super.key, required this.user});

  final AheadUser user;

  @override
  Widget build(BuildContext context) {
    final schedule = aheadStore.nextSchedule();
    final lastPractice = user.practiceResults.lastOrNull;
    final savedCount = user.savedMaterialIds.length;
    final message = schedule == null
        ? 'Belum ada target ujian. Tambahkan jadwal agar konsistensi bisa dibaca terhadap deadline.'
        : '${schedule.title} ${schedule.dayLabel}; kesiapan ${aheadStore.readinessForSubject(schedule.subjectId)}%.';
    return AheadCard(
      color: const Color(0xFFF0F7FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis Konsistensi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          InsightRow(
              icon: Icons.event_available_outlined,
              title: 'Target terdekat',
              value: message),
          InsightRow(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Latihan terakhir',
              value: lastPractice == null
                  ? 'Belum ada latihan yang selesai.'
                  : '${lastPractice.title}: ${lastPractice.score}% (${lastPractice.mode})'),
          InsightRow(
              icon: Icons.bookmark_border_rounded,
              title: 'Materi tersimpan',
              value: '$savedCount materi siap dipelajari ulang.'),
        ],
      ),
    );
  }
}

class InsightRow extends StatelessWidget {
  const InsightRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AheadColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(value,
                  style:
                      const TextStyle(color: AheadColors.muted, height: 1.35)),
            ]),
          ),
        ],
      ),
    );
  }
}

class LiveScheduleCountdownPill extends StatefulWidget {
  const LiveScheduleCountdownPill({
    super.key,
    required this.schedule,
    required this.color,
    this.textColor,
  });

  final ExamScheduleItem schedule;
  final Color color;
  final Color? textColor;

  @override
  State<LiveScheduleCountdownPill> createState() =>
      _LiveScheduleCountdownPillState();
}

class _LiveScheduleCountdownPillState extends State<LiveScheduleCountdownPill> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: widget.color, borderRadius: BorderRadius.circular(18)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.schedule.liveCountdownLabel,
            maxLines: 1,
            style: TextStyle(
                color: widget.textColor ?? AheadColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class LiveScheduleCountdownText extends StatefulWidget {
  const LiveScheduleCountdownText({
    super.key,
    required this.schedule,
    this.style,
  });

  final ExamScheduleItem schedule;
  final TextStyle? style;

  @override
  State<LiveScheduleCountdownText> createState() =>
      _LiveScheduleCountdownTextState();
}

class _LiveScheduleCountdownTextState extends State<LiveScheduleCountdownText> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.schedule.liveCountdownLabel, style: widget.style);
  }
}

class MaterialSlideDeck extends StatelessWidget {
  const MaterialSlideDeck({
    super.key,
    required this.slides,
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<MaterialSlide> slides;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Materi Belajar',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            AheadPill('Slide ${currentIndex + 1}/${slides.length}',
                dark ? const Color(0xFF334155) : AheadColors.softBlue,
                textColor: dark ? Colors.white : AheadColors.blue),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              final slide = slides[index];
              final color = dark
                  ? Color.lerp(slide.color, const Color(0xFF111827), .72)!
                  : slide.color;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: AheadCard(
                  color: color,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBox(icon: slide.icon, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                slide.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 1.18,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide.body,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.58,
                            color: dark
                                ? const Color(0xFFE5E7EB)
                                : AheadColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(slides.length, (index) {
            final active = index == currentIndex;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                margin:
                    EdgeInsets.only(right: index == slides.length - 1 ? 0 : 5),
                decoration: BoxDecoration(
                  color: active
                      ? AheadColors.blue
                      : (dark ? const Color(0xFF334155) : AheadColors.line),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RatingExperienceCard extends StatelessWidget {
  const RatingExperienceCard({
    super.key,
    required this.rating,
    required this.onChanged,
    this.title = 'Rating Pengalaman Latihan',
    this.message = 'Beri nilai 1-10 agar evaluasi latihan ikut tersimpan.',
  });

  final int? rating;
  final ValueChanged<int> onChanged;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AheadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AheadColors.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(10, (index) {
              final value = index + 1;
              final active = rating != null && value <= rating!;
              return IconButton(
                tooltip: 'Rating $value',
                onPressed: () => onChanged(value),
                icon: Icon(
                  active ? Icons.star_rounded : Icons.star_border_rounded,
                  color: active ? const Color(0xFFFFB200) : AheadColors.muted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class AnswerReviewTile extends StatelessWidget {
  const AnswerReviewTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AheadColors.navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AheadColors.navy)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AheadColors.text)),
            ]),
          ),
        ],
      ),
    );
  }
}

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.item});

  final Object item;

  @override
  Widget build(BuildContext context) {
    if (item is AiToolItem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AheadCard(
          color: const Color(0xFFFFF4D8),
          child: Row(
            children: [
              const IconBox(
                  icon: Icons.auto_awesome_outlined,
                  color: Color(0xFFFFE4A8),
                  iconColor: Color(0xFF9A5A00)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AHEAD AI',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      Text('Tanya konsep, rumus, atau soal pelajaran.',
                          style: TextStyle(color: AheadColors.muted)),
                    ]),
              ),
              IconButton(
                  tooltip: 'Buka AHEAD AI',
                  onPressed: () => openPage(context, const AiPage()),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: AheadColors.blue)),
            ],
          ),
        ),
      );
    }
    if (item is SubjectItem) {
      final subject = item as SubjectItem;
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SubjectListCard(subject: subject));
    }
    if (item is MaterialItem) {
      return MaterialTile(material: item as MaterialItem);
    }
    if (item is QuestionItem) {
      final question = item as QuestionItem;
      final subject = aheadStore.subjectById(question.subjectId);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AheadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                AheadPill('Soal ${subject.name}', subject.tint),
                const Spacer(),
                Text(question.difficulty,
                    style: const TextStyle(color: AheadColors.muted)),
              ]),
              const SizedBox(height: 10),
              Text(question.question,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => startPractice(
                    context, 'Latihan ${subject.name}', question.subjectId),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Latih Soal Serupa'),
              ),
            ],
          ),
        ),
      );
    }
    if (item is ExamScheduleItem) {
      final schedule = item as ExamScheduleItem;
      return ScheduleTile(
        schedule: schedule,
        onEdit: () => openPage(context, const StudyPlanPage()),
        onDelete: () => openPage(context, const StudyPlanPage()),
      );
    }
    final exam = item as ExamItem;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ExamListCard(exam: exam));
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
            color: user ? AheadColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(14)),
        child: Text(message.message,
            style: TextStyle(color: user ? Colors.white : AheadColors.text)),
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF7EF),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: Color(0xFF10653E))));
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: AheadColors.danger)));
}

class UpcomingScheduleCard extends StatelessWidget {
  const UpcomingScheduleCard({
    super.key,
    required this.schedule,
  });

  final ExamScheduleItem schedule;

  @override
  Widget build(BuildContext context) {
    final subject = aheadStore.subjectById(schedule.subjectId);
    final readiness = aheadStore.readinessForSubject(schedule.subjectId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30B91C1C), blurRadius: 24, offset: Offset(0, 10))
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            right: -18,
            bottom: -24,
            child: IgnorePointer(child: AnimatedFireCorner(size: 118)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const IconBox(
                  icon: Icons.event_available_outlined,
                  color: Color(0x33FFFFFF),
                  iconColor: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('UJIAN TERDEKAT',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 48),
              LiveScheduleCountdownPill(
                schedule: schedule,
                color: Colors.white,
                textColor: const Color(0xFFB91C1C),
              ),
            ]),
            const SizedBox(height: 14),
            Text(schedule.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('${subject.name} - ${schedule.type}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Kesiapan',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$readiness%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            AheadProgress(value: readiness / 100, color: Colors.white),
          ]),
        ],
      ),
    );
  }
}

class AnimatedFireCorner extends StatefulWidget {
  const AnimatedFireCorner({super.key, this.size = 72});

  final double size;

  @override
  State<AnimatedFireCorner> createState() => _AnimatedFireCornerState();
}

class _AnimatedFireCornerState extends State<AnimatedFireCorner>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        final size = widget.size;
        return Transform.scale(
          scale: .96 + value * .07,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size * .88,
                  height: size * .88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD166).withValues(alpha: .42),
                        const Color(0xFFFF6B2A).withValues(alpha: .22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -3 - value * 4),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFFFD166).withValues(alpha: .95),
                    size: size * .68,
                  ),
                ),
                Transform.translate(
                  offset: Offset(-size * .05, value * 3),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF7A1A).withValues(alpha: .86),
                    size: size * .86,
                  ),
                ),
                Transform.translate(
                  offset: Offset(size * .08, size * .1),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFF991B1B).withValues(alpha: .68),
                    size: size * .72,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ScheduleCountdownSummary extends StatelessWidget {
  const ScheduleCountdownSummary({super.key, required this.schedule});

  final ExamScheduleItem schedule;

  @override
  Widget build(BuildContext context) {
    final days = schedule.daysLeft;
    final caption = days < 0
        ? 'Jadwal ini sudah lewat. Pakai hasilnya untuk evaluasi target berikutnya.'
        : days == 0
            ? 'Hari ujian tiba. Fokus ke review singkat dan jaga tenang.'
            : 'Timeline persiapan menuju ${schedule.title}.';
    return AheadCard(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF30131A)
          : const Color(0xFFFFF1F2),
      border: Border.all(color: const Color(0xFFFFCDD2)),
      child: Row(
        children: [
          const IconBox(
              icon: Icons.hourglass_bottom_rounded,
              color: Color(0xFFFFD6D9),
              iconColor: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LiveScheduleCountdownText(
                schedule: schedule,
                style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(caption,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.35)),
            ]),
          ),
        ],
      ),
    );
  }
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

void startPractice(BuildContext context, String title, int subjectId,
    {int minutes = 10, int? materialId}) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PracticeSetupPage(
              title: title,
              subjectId: subjectId,
              minutes: minutes,
              materialId: materialId)));
}

void openPage(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

Future<void> showConfigDialog(
    BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'))
      ],
    ),
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau', style: TextStyle(color: AheadColors.muted))),
          Expanded(child: Divider()),
        ],
      );
}
