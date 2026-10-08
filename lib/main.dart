// ignore_for_file: curly_braces_in_flow_control_structures, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'ahead_shell_app.dart' as ahead;

void main() => runApp(const ahead.AheadShellApp());

class AheadApp extends StatelessWidget {
  const AheadApp({super.key});
  static const blue = Color(0xFF3867F2),
      navy = Color(0xFF202944),
      coral = Color(0xFFFF7868),
      background = Color(0xFFF7F8FC);
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AHEAD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: background,
            colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue),
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(blue))),
        home: const LoginPage(),
      );
  static OutlineInputBorder _border([Color color = const Color(0xFFE2E6EF)]) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color));
}

class Session {
  static String? name, field;
}

const _eyebrow = TextStyle(
    color: AheadApp.coral,
    fontWeight: FontWeight.w800,
    fontSize: 11,
    letterSpacing: 1.2);
const _title =
    TextStyle(color: AheadApp.navy, fontSize: 30, fontWeight: FontWeight.w800);

class AheadLogo extends StatelessWidget {
  const AheadLogo({super.key, this.small = false});
  final bool small;
  @override
  Widget build(BuildContext c) {
    final s = small ? 30.0 : 46.0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: s,
          height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AheadApp.coral,
              borderRadius: BorderRadius.circular(small ? 9 : 14)),
          child: Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: small ? 17 : 26,
                  fontWeight: FontWeight.w800))),
      const SizedBox(width: 9),
      Text('AHEAD',
          style: TextStyle(
              color: AheadApp.blue,
              fontWeight: FontWeight.w800,
              fontSize: small ? 19 : 26))
    ]);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.notice});
  final String? notice;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final key = GlobalKey<FormState>(),
      email = TextEditingController(),
      password = TextEditingController();
  bool hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void login() {
    if (!key.currentState!.validate()) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => HomePage(
                name: Session.name ?? 'Siswa', field: Session.field ?? 'IPA')));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                          key: key,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(child: AheadLogo()),
                                const SizedBox(height: 56),
                                const Text('SELAMAT DATANG', style: _eyebrow),
                                const SizedBox(height: 11),
                                const Text('Masuk untuk belajar.',
                                    style: _title),
                                const SizedBox(height: 9),
                                const Text(
                                    'Lanjutkan tujuan belajarmu hari ini.',
                                    style: TextStyle(color: Color(0xFF6D768B))),
                                if (widget.notice != null) ...[
                                  const SizedBox(height: 20),
                                  _Notice(widget.notice!)
                                ],
                                const SizedBox(height: 30),
                                TextFormField(
                                    controller: email,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon:
                                            Icon(Icons.mail_outline_rounded)),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Email tidak boleh kosong'
                                            : !v.contains('@')
                                                ? 'Masukkan email yang valid'
                                                : null),
                                const SizedBox(height: 17),
                                TextFormField(
                                    controller: password,
                                    obscureText: hidden,
                                    decoration: InputDecoration(
                                        labelText: 'Kata sandi',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                            onPressed: () => setState(
                                                () => hidden = !hidden),
                                            icon: Icon(hidden
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined))),
                                    validator: (v) => v == null || v.length < 6
                                        ? 'Kata sandi minimal 6 karakter'
                                        : null),
                                const SizedBox(height: 25),
                                PrimaryButton('Masuk', login),
                                const SizedBox(height: 17),
                                Center(
                                    child: TextButton(
                                        onPressed: () => Navigator.push(
                                            c,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterPage())),
                                        child: const Text(
                                            'Belum punya akun? Daftar sekarang',
                                            style: TextStyle(
                                                color: AheadApp.blue,
                                                fontWeight: FontWeight.w700))))
                              ])))))));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final key = GlobalKey<FormState>(),
      name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool hp = true, hc = true;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void next() {
    if (key.currentState!.validate())
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => FieldPage(name: name.text.trim())));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          backgroundColor: AheadApp.background,
          title: const AheadLogo(small: true)),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 34),
              child: Form(
                  key: key,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BUAT AKUN', style: _eyebrow),
                        const SizedBox(height: 11),
                        const Text('Yuk, kenalan dulu.', style: _title),
                        const SizedBox(height: 9),
                        const Text(
                            'Isi data di bawah untuk mulai belajar bersama AHEAD.',
                            style: TextStyle(color: Color(0xFF6D768B))),
                        const SizedBox(height: 30),
                        TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                                prefixIcon: Icon(Icons.person_outline_rounded)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama tidak boleh kosong'
                                : null),
                        const SizedBox(height: 17),
                        TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Masukkan email yang valid'
                                : null),
                        const SizedBox(height: 17),
                        TextFormField(
                            controller: password,
                            obscureText: hp,
                            decoration: InputDecoration(
                                labelText: 'Kata sandi',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                    onPressed: () => setState(() => hp = !hp),
                                    icon: Icon(hp
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined))),
                            validator: (v) => v == null || v.length < 6
                                ? 'Kata sandi minimal 6 karakter'
                                : null),
                        const SizedBox(height: 17),
                        TextFormField(
                            controller: confirm,
                            obscureText: hc,
                            decoration: InputDecoration(
                                labelText: 'Konfirmasi kata sandi',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_outlined),
                                suffixIcon: IconButton(
                                    onPressed: () => setState(() => hc = !hc),
                                    icon: Icon(hc
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined))),
                            validator: (v) => v != password.text
                                ? 'Kata sandi belum sama'
                                : null),
                        const SizedBox(height: 26),
                        PrimaryButton('Lanjut pilih jurusan', next)
                      ])))));
}

class FieldPage extends StatelessWidget {
  const FieldPage({super.key, required this.name});
  final String name;
  void finish(BuildContext c, String field) {
    Session.name = name;
    Session.field = field;
    Navigator.pushAndRemoveUntil(
        c,
        MaterialPageRoute(
            builder: (_) => const LoginPage(
                notice: 'Pendaftaran berhasil. Silakan masuk dengan akunmu.')),
        (r) => false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          backgroundColor: AheadApp.background,
          title: const AheadLogo(small: true)),
      body: Padding(
          padding: const EdgeInsets.all(28),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $name', style: _title),
            const SizedBox(height: 9),
            const Text(
                'Pilih jurusanmu. Setelah itu, kamu akan kembali ke halaman masuk.',
                style: TextStyle(color: Color(0xFF6D768B), height: 1.5)),
            const SizedBox(height: 34),
            FieldCard(
                'IPA',
                'Ilmu Pengetahuan Alam',
                'Matematika, Fisika, Kimia, dan Biologi',
                Icons.science_outlined,
                const Color(0xFFE7F1FF),
                () => finish(c, 'IPA')),
            const SizedBox(height: 15),
            FieldCard(
                'IPS',
                'Ilmu Pengetahuan Sosial',
                'Ekonomi, Geografi, Sosiologi, dan Sejarah',
                Icons.public_outlined,
                const Color(0xFFFFF1DF),
                () => finish(c, 'IPS'))
          ])));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.name, required this.field});
  final String name, field;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  void select(int i) {
    if (i == 4) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
    } else {
      setState(() => index = i);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: const AheadLogo(small: true),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                    child: Text('Halo, ${widget.name.split(' ').first}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF687188)))))
          ]),
      body: index == 0 ? materials() : secondary(),
      bottomNavigationBar: BottomNav(index, select));
  Widget materials() {
    final list = widget.field == 'IPS' ? ips : ipa;
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 105),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TodayBanner(),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pilih materimu',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AheadApp.navy)),
              const SizedBox(height: 4),
              Text('Materi untuk jurusan ${widget.field}',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6D768B)))
            ]),
            const Icon(Icons.arrow_forward_rounded, color: AheadApp.blue)
          ]),
          const SizedBox(height: 16),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: .96),
              itemBuilder: (c, i) => SubjectCard(list[i]))
        ]));
  }

  Widget secondary() {
    final p = [
      ('Latihan', Icons.edit_note_rounded),
      ('Ujian', Icons.assignment_outlined),
      ('Profil', Icons.person_outline_rounded)
    ][index - 1];
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
              color: Color(0xFFE8EDFF), shape: BoxShape.circle),
          child: Icon(p.$2, color: AheadApp.blue, size: 39)),
      const SizedBox(height: 21),
      Text(p.$1,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: AheadApp.navy)),
      const SizedBox(height: 8),
      const Text('Halaman ini siap dikembangkan untuk pengalaman belajarmu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6D768B)))
    ]));
  }
}

class TodayBanner extends StatelessWidget {
  @override
  Widget build(BuildContext c) => Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: const Color(0xFFE8EDFF),
          borderRadius: BorderRadius.circular(10)),
      child: Stack(children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BELAJAR HARI INI',
              style: TextStyle(
                  color: Color(0xFF566DBD),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.1)),
          SizedBox(height: 13),
          Text('Hari ini mau\nbelajar apa?',
              style: TextStyle(
                  fontSize: 31,
                  height: 1.16,
                  fontWeight: FontWeight.w800,
                  color: AheadApp.navy)),
          SizedBox(height: 11),
          SizedBox(
              width: 205,
              child: Text(
                  'Pilih materi yang ingin kamu kuasai, lalu mulai pelan-pelan.',
                  style: TextStyle(
                      color: Color(0xFF5E6B86), fontSize: 13, height: 1.4)))
        ]),
        Positioned(
            right: 2,
            bottom: 7,
            child: Transform.rotate(
                angle: .15,
                child: Container(
                    width: 88,
                    height: 108,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AheadApp.coral,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0xFFCAD4FF), offset: Offset(8, 9))
                        ]),
                    child: const Text('A',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800))))),
        const Positioned(
            right: 0,
            top: 8,
            child: Icon(Icons.circle_outlined,
                color: Color(0xFF64D6BB), size: 27)),
        const Positioned(
            right: 83,
            top: 4,
            child: Icon(Icons.star_rounded, color: Color(0xFFFFC24C), size: 23))
      ]));
}

class Subject {
  const Subject(
      this.num, this.title, this.topic, this.icon, this.bg, this.ibg, this.ic);
  final String num, title, topic;
  final IconData icon;
  final Color bg, ibg, ic;
}

const ipa = [
  Subject('01', 'Matematika', 'Aljabar dan fungsi', Icons.calculate_outlined,
      Color(0xFFEDF6FF), Color(0xFFD0E9FF), Color(0xFF2780C5)),
  Subject('02', 'Fisika', 'Gerak lurus', Icons.bolt_outlined, Color(0xFFFFF6E3),
      Color(0xFFFFE3A8), Color(0xFFB77B00)),
  Subject('03', 'Biologi', 'Sel dan jaringan', Icons.eco_outlined,
      Color(0xFFECF9F3), Color(0xFFC9EFDF), Color(0xFF20966F)),
  Subject('04', 'Kimia', 'Struktur atom', Icons.science_outlined,
      Color(0xFFFFF0ED), Color(0xFFFFD2CC), Color(0xFFD55A4A))
];
const ips = [
  Subject(
      '01',
      'Ekonomi',
      'Kebutuhan manusia',
      Icons.account_balance_wallet_outlined,
      Color(0xFFECF9F3),
      Color(0xFFC9EFDF),
      Color(0xFF218263)),
  Subject('02', 'Sosiologi', 'Interaksi sosial', Icons.people_outline_rounded,
      Color(0xFFFFF0ED), Color(0xFFFFD2CC), Color(0xFFC84E40)),
  Subject('03', 'Geografi', 'Dinamika litosfer', Icons.public_outlined,
      Color(0xFFEDF6FF), Color(0xFFD0E9FF), Color(0xFF2384C5)),
  Subject('04', 'Sejarah', 'Masa kolonial', Icons.history_edu_outlined,
      Color(0xFFFFF6E3), Color(0xFFFFE3A8), Color(0xFFAF7608))
];

class SubjectCard extends StatelessWidget {
  const SubjectCard(this.s, {super.key});
  final Subject s;
  @override
  Widget build(BuildContext c) => Material(
      color: s.bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text('Materi ${s.title} akan segera dibuka.'))),
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.num,
                              style: const TextStyle(
                                  color: Color(0xFF8792AA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: s.ibg, shape: BoxShape.circle),
                              child: Icon(s.icon, color: s.ic, size: 20))
                        ]),
                    const Spacer(),
                    Text(s.title,
                        style: const TextStyle(
                            color: AheadApp.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(s.topic,
                        style: const TextStyle(
                            color: Color(0xFF66728A), fontSize: 11)),
                    const SizedBox(height: 8),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 18, color: AheadApp.blue))
                  ]))));
}

class BottomNav extends StatelessWidget {
  const BottomNav(this.i, this.on, {super.key});
  final int i;
  final ValueChanged<int> on;
  @override
  Widget build(BuildContext c) => SafeArea(
      top: false,
      child: Container(
          height: 78,
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8EBF2)))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Nav(Icons.home_outlined, 'Materi', i == 0, () => on(0)),
            Nav(Icons.edit_note_outlined, 'Latihan', i == 1, () => on(1)),
            GestureDetector(
                onTap: () => on(0),
                child: Transform.translate(
                    offset: const Offset(0, -23),
                    child: Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: AheadApp.coral,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 6)),
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4))
                            ]),
                        child: const Text('A',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800))))),
            Nav(Icons.assignment_outlined, 'Ujian', i == 2, () => on(2)),
            Nav(Icons.person_outline_rounded, 'Profil', i == 3, () => on(3))
          ])));
}

class Nav extends StatelessWidget {
  const Nav(this.icon, this.label, this.active, this.tap, {super.key});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback tap;
  @override
  Widget build(BuildContext c) {
    final color = active ? AheadApp.blue : const Color(0xFF98A0B2);
    return InkResponse(
        onTap: tap,
        child: SizedBox(
            width: 56,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500))
            ])));
  }
}

class FieldCard extends StatelessWidget {
  const FieldCard(
      this.title, this.sub, this.detail, this.icon, this.color, this.tap,
      {super.key});
  final String title, sub, detail;
  final IconData icon;
  final Color color;
  final VoidCallback tap;
  @override
  Widget build(BuildContext c) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE3E7EF)),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: AheadApp.blue)),
                const SizedBox(width: 15),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20,
                              color: AheadApp.navy,
                              fontWeight: FontWeight.w800)),
                      Text(sub,
                          style: const TextStyle(
                              color: AheadApp.blue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(detail,
                          style: const TextStyle(
                              color: Color(0xFF6D768B), fontSize: 11))
                    ])),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Color(0xFF99A3B6))
              ]))));
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, this.tap, {super.key});
  final String label;
  final VoidCallback tap;
  @override
  Widget build(BuildContext c) => SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
          onPressed: tap,
          style: ElevatedButton.styleFrom(
              backgroundColor: AheadApp.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Icon(Icons.arrow_forward_rounded)
          ])));
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext c) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: const Color(0xFFE8FAF3),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(color: Color(0xFF19745A), fontSize: 13)));
}
