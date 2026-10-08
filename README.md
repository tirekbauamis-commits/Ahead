# AHEAD App

AHEAD adalah aplikasi belajar Flutter untuk siswa kelas 10 dengan login/register, pemilihan jurusan IPA/IPS, materi, latihan, ujian, analisis belajar, AHEAD AI, dan integrasi database MySQL lewat backend PHP.

## Cara menjalankan yang disarankan

Gunakan file ini setiap kali ingin membuka aplikasi:

```text
C:\ahead_app\JALANKAN_AHEAD.bat
```

Launcher tersebut akan:

- mengecek dan menyalakan MySQL Laragon jika belum aktif;
- mengecek dan menyalakan Backend API di `http://127.0.0.1:8000`;
- menjalankan Flutter web di port tetap `http://localhost:64800`;
- mengirim `GOOGLE_CLIENT_ID` dari `backend\.env` ke Flutter jika sudah diisi.

Port Flutter dibuat tetap agar data login browser dan konfigurasi Google OAuth tidak berubah-ubah setiap aplikasi dijalankan ulang.

## Database

Database yang dipakai adalah MySQL Laragon:

```text
Database: ahead_db
Host: 127.0.0.1
Port: 3306
User: root
Password: kosong
```

Schema SQL berada di:

```text
C:\ahead_app\backend\sql\schema.sql
```

## Google Login

Login Google asli membutuhkan OAuth Client ID dari Google Cloud. Setelah dibuat, isi:

```text
C:\ahead_app\backend\.env
```

pada bagian:

```env
GOOGLE_CLIENT_ID=isi_client_id_google_di_sini
```

Tambahkan origin berikut di Google Cloud OAuth:

```text
http://localhost:64800
```

Setelah itu jalankan lagi `JALANKAN_AHEAD.bat`.

Jika tidak ingin edit `.env` manual, jalankan:

```text
C:\ahead_app\ISI_GOOGLE_CLIENT_ID.bat
```

lalu tempel Client ID dari Google Cloud.

Panduan lengkap ada di:

```text
C:\ahead_app\SETUP_GOOGLE_LOGIN.md
```

## Catatan penting

Menutup tab Chrome tidak menghapus akun di database. Namun aplikasi tidak bisa login jika Backend API mati. Karena itu, selalu buka aplikasi lewat `JALANKAN_AHEAD.bat` supaya MySQL, API, dan Flutter aktif bersama.
