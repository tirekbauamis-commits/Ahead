CREATE DATABASE IF NOT EXISTS ahead_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ahead_db;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NULL,
  class VARCHAR(30) NOT NULL,
  major ENUM('IPA','IPS') NOT NULL,
  provider ENUM('email','google') NOT NULL DEFAULT 'email',
  google_id VARCHAR(180) NULL,
  profile_photo VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auth_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX (token_hash)
);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX (token)
);

CREATE TABLE IF NOT EXISTS subjects (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  category VARCHAR(80) NOT NULL,
  description TEXT NULL
);

CREATE TABLE IF NOT EXISTS materials (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  subject_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  content LONGTEXT NOT NULL,
  class_level VARCHAR(20) NOT NULL DEFAULT 'X',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS material_progress (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  material_id BIGINT UNSIGNED NOT NULL,
  progress TINYINT UNSIGNED NOT NULL DEFAULT 0,
  last_position VARCHAR(120) NULL,
  completed TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_user_material (user_id, material_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS questions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  subject_id BIGINT UNSIGNED NOT NULL,
  material_id BIGINT UNSIGNED NULL,
  question TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  option_d TEXT NOT NULL,
  option_e TEXT NOT NULL,
  correct_answer ENUM('A','B','C','D','E') NOT NULL,
  explanation TEXT NOT NULL,
  difficulty VARCHAR(40) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS practice_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  subject_id BIGINT UNSIGNED NOT NULL,
  score TINYINT UNSIGNED NOT NULL DEFAULT 0,
  correct_answers INT UNSIGNED NOT NULL DEFAULT 0,
  wrong_answers INT UNSIGNED NOT NULL DEFAULT 0,
  duration INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS practice_answers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  session_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  answer ENUM('A','B','C','D','E') NULL,
  confidence ENUM('Guessing','Fairly Sure','Very Sure') NULL,
  is_correct TINYINT(1) NOT NULL DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES practice_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS exams (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  type VARCHAR(60) NOT NULL,
  duration INT UNSIGNED NOT NULL,
  total_questions INT UNSIGNED NOT NULL,
  subject_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS exam_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  exam_id BIGINT UNSIGNED NOT NULL,
  score TINYINT UNSIGNED NOT NULL DEFAULT 0,
  correct_answers INT UNSIGNED NOT NULL DEFAULT 0,
  wrong_answers INT UNSIGNED NOT NULL DEFAULT 0,
  unanswered INT UNSIGNED NOT NULL DEFAULT 0,
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS exam_schedules (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  client_id VARCHAR(120) NOT NULL,
  title VARCHAR(180) NOT NULL,
  subject_id BIGINT UNSIGNED NOT NULL,
  exam_type VARCHAR(60) NOT NULL,
  exam_date DATE NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_user_client_schedule (user_id, client_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS exam_answers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  session_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  answer ENUM('A','B','C','D','E') NULL,
  is_correct TINYINT(1) NOT NULL DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS saved_materials (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  material_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_saved_material (user_id, material_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS notes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  content TEXT NOT NULL,
  material_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS study_plans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  subject_id BIGINT UNSIGNED NULL,
  date DATE NOT NULL,
  start_time TIME NULL,
  duration INT UNSIGNED NOT NULL,
  completed TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  message TEXT NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ai_conversations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(180) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ai_messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  role ENUM('system','user','assistant') NOT NULL,
  message LONGTEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id) ON DELETE CASCADE
);

INSERT INTO subjects (id, name, category, description) VALUES
  (1, 'Biologi', 'IPA', 'Keanekaragaman hayati, pelestarian lingkungan, perubahan lingkungan, global warming, virus dan peranannya'),
  (2, 'Kimia', 'IPA', 'Kimia hijau, metode ilmiah, struktur atom, dan hukum dasar kimia'),
  (3, 'Fisika', 'IPA', 'Metode ilmiah, pengukuran fisik, energi terbarukan, dan pemanasan global'),
  (4, 'Sejarah', 'IPS', 'Pengantar ilmu sejarah, manusia, ruang dan waktu, jalur rempah, dan sejarah Indonesia awal'),
  (5, 'Sosiologi', 'IPS', 'Gejala sosial, identitas diri, tindakan sosial, dan interaksi sosial'),
  (6, 'Ekonomi', 'IPS', 'Konsep ekonomi, kelangkaan, kebutuhan manusia, pasar, dan lembaga keuangan'),
  (7, 'Geografi', 'IPS', 'Konsep, prinsip, pendekatan geografi, peta, penginderaan jauh, dan SIG')
ON DUPLICATE KEY UPDATE name = VALUES(name), category = VALUES(category), description = VALUES(description);

INSERT INTO materials (id, subject_id, title, description, content, class_level) VALUES
  (1, 1, 'Keanekaragaman Hayati Indonesia', 'Flora, fauna, ekosistem, dan pelestarian.', 'Indonesia memiliki keanekaragaman hayati tinggi. Pelestarian dilakukan melalui konservasi in-situ, ex-situ, dan pemanfaatan berkelanjutan.', 'X'),
  (2, 1, 'Virus dan Peranannya', 'Ciri virus, replikasi, dampak, dan manfaat.', 'Virus adalah partikel aseluler yang bereplikasi di dalam sel hidup dan dapat berdampak negatif maupun bermanfaat dalam bioteknologi.', 'X'),
  (3, 2, 'Kimia Hijau', 'Prinsip green chemistry.', 'Kimia hijau menekankan pencegahan limbah, efisiensi energi, bahan aman, dan proses ramah lingkungan.', 'X'),
  (4, 2, 'Struktur Atom', 'Partikel penyusun atom dan model atom.', 'Atom tersusun dari proton, neutron, dan elektron. Struktur atom membantu menjelaskan sifat unsur.', 'X'),
  (5, 3, 'Besaran dan Satuan', 'Pengukuran fisik dan satuan SI.', 'Besaran fisika dapat diukur dan dinyatakan dengan angka serta satuan. Pengukuran memperhatikan ketelitian alat dan satuan SI.', 'X'),
  (6, 3, 'Energi Terbarukan', 'Energi alternatif dan pemanasan global.', 'Energi terbarukan berasal dari matahari, angin, air, panas bumi, dan biomassa untuk mengurangi emisi.', 'X'),
  (7, 4, 'Pengantar Ilmu Sejarah', 'Manusia, ruang, waktu, dan cara berpikir sejarah.', 'Sejarah mempelajari peristiwa masa lalu berdasarkan sumber yang dapat diuji.', 'X'),
  (8, 5, 'Gejala Sosial dan Identitas Diri', 'Fungsi sosiologi dan interaksi sosial.', 'Sosiologi membantu memahami gejala sosial, nilai, norma, identitas diri, dan interaksi.', 'X'),
  (9, 6, 'Masalah Ekonomi', 'Kelangkaan dan kebutuhan manusia.', 'Masalah ekonomi muncul karena kebutuhan tidak terbatas sedangkan sumber daya terbatas.', 'X'),
  (10, 7, 'Konsep Dasar Geografi', 'Konsep, prinsip, peta, penginderaan jauh, dan SIG.', 'Geografi mengkaji geosfer dalam konteks keruangan menggunakan peta, penginderaan jauh, dan SIG.', 'X')
ON DUPLICATE KEY UPDATE title = VALUES(title), description = VALUES(description), content = VALUES(content);

INSERT INTO questions (id, subject_id, material_id, question, option_a, option_b, option_c, option_d, option_e, correct_answer, explanation, difficulty) VALUES
  (1, 1, 1, 'Upaya pelestarian komodo di habitat aslinya disebut konservasi...', 'ex-situ', 'in-situ', 'domestikasi', 'urbanisasi', 'fragmentasi', 'B', 'Konservasi in-situ dilakukan di habitat asli makhluk hidup.', 'Menengah'),
  (2, 2, 3, 'Prinsip utama kimia hijau yang paling tepat adalah...', 'menghasilkan limbah sebanyak mungkin', 'mencegah limbah sejak awal proses', 'menggunakan bahan beracun', 'mengabaikan efisiensi energi', 'memakai pelarut berbahaya', 'B', 'Kimia hijau menekankan pencegahan limbah dan bahan aman.', 'Dasar'),
  (3, 3, 5, 'Besaran pokok SI untuk panjang memiliki satuan...', 'meter', 'newton', 'joule', 'watt', 'pascal', 'A', 'Panjang adalah besaran pokok dengan satuan SI meter.', 'Dasar'),
  (4, 4, 7, 'Unsur penting dalam kajian sejarah adalah...', 'manusia, ruang, dan waktu', 'harga, pasar, dan uang', 'massa, energi, dan gaya', 'atom, ion, dan molekul', 'peta, skala, dan legenda', 'A', 'Sejarah berkaitan dengan manusia sebagai pelaku, ruang sebagai tempat, dan waktu sebagai urutan peristiwa.', 'Dasar'),
  (5, 5, 8, 'Contoh interaksi sosial ditunjukkan oleh...', 'seseorang tidur sendirian', 'dua siswa berdiskusi tugas', 'batu jatuh dari tebing', 'air menguap karena panas', 'planet berotasi', 'B', 'Interaksi sosial terjadi ketika ada hubungan timbal balik antarindividu atau kelompok.', 'Dasar'),
  (6, 6, 9, 'Masalah ekonomi muncul karena...', 'kebutuhan terbatas dan sumber daya tidak terbatas', 'kebutuhan tidak terbatas dan sumber daya terbatas', 'semua barang tersedia gratis', 'tidak ada pilihan dalam hidup', 'harga selalu turun', 'B', 'Kelangkaan terjadi karena kebutuhan tidak terbatas sedangkan sumber daya terbatas.', 'Dasar'),
  (7, 7, 10, 'Alat yang digunakan untuk menyajikan informasi keruangan permukaan bumi adalah...', 'peta', 'neraca', 'mikroskop', 'termometer', 'kromatografi', 'A', 'Peta menyajikan informasi keruangan permukaan bumi dalam bidang datar dengan skala tertentu.', 'Dasar')
ON DUPLICATE KEY UPDATE question = VALUES(question), explanation = VALUES(explanation);

INSERT INTO exams (id, title, description, type, duration, total_questions, subject_id) VALUES
  (1, 'Simulasi PAS IPA Kelas X', 'Ujian terpadu Biologi, Kimia, dan Fisika kelas X.', 'UAS', 90, 50, 1),
  (2, 'Simulasi Biologi Kelas X', 'Keanekaragaman hayati, lingkungan, dan virus.', 'UTS', 45, 25, 1),
  (3, 'Asesmen Sumatif Fisika', 'Pengukuran, energi terbarukan, dan pemanasan global.', 'Sumatif', 30, 20, 3),
  (4, 'Simulasi PAS IPS Kelas X', 'Ujian terpadu Sejarah, Sosiologi, Ekonomi, dan Geografi kelas X.', 'UAS', 90, 50, 4),
  (5, 'Simulasi Ekonomi Kelas X', 'Kelangkaan, kebutuhan, pasar, dan lembaga keuangan.', 'UTS', 45, 25, 6),
  (6, 'Asesmen Sumatif Geografi', 'Konsep geografi, peta, penginderaan jauh, dan SIG.', 'Sumatif', 30, 20, 7)
ON DUPLICATE KEY UPDATE title = VALUES(title), description = VALUES(description);
