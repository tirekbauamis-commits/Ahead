# Setup Login Google AHEAD

Login Google AHEAD sudah memakai paket Flutter `google_sign_in` dan endpoint backend `POST /auth/google`. Agar benar-benar membuka pilihan akun Google, aplikasi membutuhkan OAuth Client ID resmi dari Google Cloud.

## 1. Buat OAuth Client ID Web

Di Google Cloud Console:

1. Buka `APIs & Services` > `Credentials`.
2. Klik `Create Credentials` > `OAuth client ID`.
3. Pilih `Web application`.
4. Tambahkan Authorized JavaScript origins:

```text
http://localhost:64800
```

5. Copy Client ID yang berakhiran:

```text
.apps.googleusercontent.com
```

6. Isi ke file:

```text
C:\ahead_app\backend\.env
```

pada bagian:

```env
GOOGLE_CLIENT_ID=client_id_google_web_di_sini
```

Atau jalankan helper ini, lalu tempel Client ID:

```text
C:\ahead_app\ISI_GOOGLE_CLIENT_ID.bat
```

7. Jalankan ulang aplikasi lewat:

```text
C:\ahead_app\JALANKAN_AHEAD.bat
```

Di Flutter web/Chrome, tombol Google akan memakai popup resmi Google. Jika ada beberapa akun Google aktif di browser, Google akan menampilkan pemilihan akun.

## 2. Agar tampil seperti gambar Android

Tampilan daftar akun gelap seperti contoh adalah account picker native Android. Untuk mendapat tampilan itu:

1. Buat OAuth Client ID tambahan dengan tipe `Android`.
2. Isi package name Android:

```text
com.example.ahead_app
```

3. Isi SHA-1 certificate fingerprint dari debug keystore.
4. Jalankan aplikasi ke perangkat Android atau emulator, bukan Chrome web.

Perintah melihat SHA-1 biasanya:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Setelah konfigurasi Android benar, paket `google_sign_in` akan membuka account picker Google native seperti contoh.

## Catatan

Client ID tidak bisa dibuat otomatis dari kode karena harus berasal dari akun Google Cloud pemilik aplikasi. Tanpa `GOOGLE_CLIENT_ID`, Google akan menolak login dan aplikasi tidak bisa menerima `id_token` resmi.
