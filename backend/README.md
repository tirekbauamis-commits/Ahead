# AHEAD Backend

Backend ini memakai PHP native dan MySQL Laragon. Backend wajib aktif agar login, register, lupa password, materi, latihan, ujian, progres, dan AHEAD AI bisa tersinkron ke database.

## Cara menjalankan

Cara paling aman adalah lewat launcher utama aplikasi:

```text
C:\ahead_app\JALANKAN_AHEAD.bat
```

Launcher tersebut otomatis mengecek MySQL, menyalakan API di `http://127.0.0.1:8000`, lalu menjalankan Flutter di `http://localhost:64800`.

Jika ingin menjalankan backend saja:

```powershell
php -S 127.0.0.1:8000 -t backend/public
```

## Setup Laragon

1. Pastikan MySQL Laragon aktif.
2. Import `backend\sql\schema.sql` ke database `ahead_db` jika tabel belum ada.
3. Copy `backend\.env.example` menjadi `backend\.env`.
4. Isi konfigurasi database, SMTP, Google OAuth, dan `OPENAI_API_KEY` sesuai kebutuhan.

## Endpoint

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/google`
- `POST /auth/logout`
- `POST /password/forgot`
- `POST /password/reset`
- `GET /me`
- `GET /subjects`
- `GET /materials`
- `GET /exams`
- `GET /dashboard`
- `POST /ai/chat`

Google OAuth memakai `id_token` yang diverifikasi backend menggunakan `GOOGLE_CLIENT_ID`. SMTP email dan OpenAI call membutuhkan konfigurasi `.env`; API key tidak dimasukkan ke Flutter.
