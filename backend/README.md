# Backend API AHEAD

Backend AHEAD dibuat dengan PHP native dan MySQL. API menangani autentikasi, data mata pelajaran/materi/ujian, ringkasan dashboard, serta route tutor lokal. Ikuti panduan lengkap aplikasi pada [README utama](../README.md).

## Persiapan

- PHP CLI tersedia di terminal atau melalui Laragon.
- MySQL aktif.
- Database `ahead_db` sudah dibuat dari `sql/schema.sql`.

Salin berkas contoh konfigurasi lalu isi nilai lokal:

```powershell
Copy-Item .env.example .env
```

Atur `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`, dan `JWT_SECRET` di `.env`. Jangan masukkan `.env` ke Git atau mengunggah kredensial ke repositori publik.

## Menjalankan API

Dari direktori utama proyek:

```powershell
php -S 127.0.0.1:8000 -t backend/public
```

Pemeriksaan kesehatan API:

```text
GET http://127.0.0.1:8000/health
```

Launcher aplikasi `JALANKAN_AHEAD.bat` dan `JALANKAN_AHEAD_HP.bat` juga menyiapkan API bersama MySQL dan Flutter.

## Endpoint

| Method | Path | Kegunaan |
| --- | --- | --- |
| `GET` | `/health` | Memeriksa status backend |
| `POST` | `/auth/register` | Membuat akun |
| `POST` | `/auth/login` | Login email/password |
| `POST` | `/auth/google` | Memverifikasi token Google |
| `POST` | `/auth/logout` | Mengakhiri sesi token |
| `POST` | `/password/forgot` | Membuat token reset password |
| `POST` | `/password/reset` | Mengganti password dengan token |
| `GET` | `/me` | Mengambil profil pengguna aktif |
| `GET` | `/state` | Mengambil cache aktivitas dan profil yang tersimpan pada akun |
| `POST` | `/state` | Menyinkronkan profil, progres, materi tersimpan, latihan, ujian, catatan, dan aktivitas |
| `GET` | `/subjects` | Mengambil daftar mata pelajaran |
| `GET` | `/materials` | Mengambil daftar materi |
| `GET` | `/exams` | Mengambil daftar ujian |
| `GET` | `/dashboard` | Mengambil ringkasan dashboard |
| `POST` | `/ai/chat` | Mendapatkan respons tutor lokal |

Endpoint yang memerlukan sesi memakai token autentikasi yang diterbitkan saat login.

## Integrasi dan batas fitur

- **Database:** skema tabel ada di `sql/schema.sql`; nama database default `ahead_db`.
- **Google Sign-In:** route `/auth/google` memverifikasi `id_token` dengan `GOOGLE_CLIENT_ID`. Login Google perlu Client ID OAuth resmi yang sesuai platform.
- **Reset password:** `/password/forgot` saat ini membuat token reset. Pada mode lokal respons menyertakan `dev_token`; kode belum mengirim email. Pengiriman email membutuhkan integrasi SMTP.
- **AHEAD AI:** `/ai/chat` mengembalikan `ai_local_tutor_reply` dengan mode `local_tutor`. Route ini belum memanggil Gemini, OpenAI, atau model cloud. Nilai `OPENAI_API_KEY` pada `.env.example` tidak mengaktifkan pemanggilan model pada implementasi sekarang.
- **Sinkronisasi akun:** Flutter menyimpan cache di perangkat dan mengirim perubahan akun ke `/state` setelah aktivitas saat token API aktif. Saat login, perubahan tertunda dari cache lokal dikirim; jika tidak ada perubahan lokal tertunda, data akun server dipulihkan. Jika API tidak tersedia, perubahan tetap tersimpan lokal dengan status tertunda dan dikirim lagi pada aktivitas berikutnya atau saat login API berikutnya. Jadwal ujian juga memakai endpoint `/schedules`.
- **Fallback aplikasi:** akun offline tetap hanya tersimpan pada perangkat sampai pengguna masuk kembali melalui API.

Lihat `../SETUP_GOOGLE_LOGIN.md` untuk langkah konfigurasi OAuth dan [README utama](../README.md) untuk menjalankan versi Web atau Android.