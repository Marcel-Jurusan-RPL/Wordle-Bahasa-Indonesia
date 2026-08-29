# Wordle Bahasa Indonesia (Godot)

Game tebak kata ala Wordle, dengan daftar kata Bahasa Indonesia.

## Cara Menjalankan

1. Download & install [Godot Engine 4.x](https://godotengine.org/download) (versi 4.1 ke atas).
2. Buka Godot, pilih **Import**, lalu arahkan ke folder `wordle-godot` ini dan pilih file `project.godot`.
3. Setelah proyek terbuka, tekan tombol **Run** (F5) di pojok kanan atas.

## Cara Bermain

- Saat game pertama dibuka, papan **"Cara Bermain"** otomatis muncul. Tekan **Mulai Bermain** untuk memulai (bisa dibuka lagi kapan saja lewat tombol **?** di pojok atas).
- Tombol **🌙 / ☀️** di pojok kiri atas untuk beralih mode gelap/terang.
- Tebak kata 5 huruf dalam 6 kali percobaan.
- Ketik huruf lewat keyboard fisik atau tombol virtual di layar, lalu tekan **ENTER** untuk menebak.
- Warna setelah menebak:
  - **Hijau**: huruf benar & posisinya tepat.
  - **Kuning**: huruf ada di kata tapi posisinya salah.
  - **Abu-abu**: huruf tidak ada dalam kata.
- Setelah menang atau kalah, game **otomatis lanjut ke kata baru** setelah beberapa detik — skor dan streak tetap tersimpan (tidak direset).

## Sistem Skor & Streak

- Bagian atas layar hanya menampilkan **satu angka skor terkini** (bersih dan ringkas).
- Saat **menang/kalah**, detail lengkap muncul di layar: kata jawabannya, skor saat ini & skor terbaik, serta streak saat ini & streak terbaik.
- **Menang**: skor bertambah, streak naik 1. Semakin panjang streak, semakin besar bonus poin per kemenangan.
- **Kalah** (6 percobaan habis): skor berkurang 15 poin (minimal 0), dan streak kembali ke 0.
- Catatan: skor & streak hanya tersimpan selama aplikasi berjalan (belum disimpan permanen ke file/disk).

## Sumber Kosakata

Daftar kata (`WordList.gd`) berisi **14.042 kata 5-huruf** yang diekstrak dari **Kamus Besar Bahasa Indonesia (KBBI) v6.1.0** resmi, sumber: https://github.com/aryakdaniswara/kbbi-v6-wordlist

Karena diambil dari kamus resmi lengkap, sebagian kata mungkin jarang dipakai sehari-hari atau bersifat arkais/kedaerahan/istilah teknis. Kata jawaban dipilih acak dari daftar ini, dan tebakan Anda juga wajib ada di daftar ini (mirip Wordle asli yang memvalidasi kata lewat kamus).

Kalau ingin tingkat kesulitan lebih ramah pemula (hanya kata umum sehari-hari), beri tahu saya — daftarnya bisa dipersempit jadi beberapa ratus kata yang lebih familiar.

## Menambah/Mengubah Kata

Buka `WordList.gd`, cari array `WORDS`, lalu tambah/hapus kata 5 huruf (huruf kapital) sesuai kebutuhan.

## Kendala & Solusi

Game ini dikembangkan dengan bantuan AI (AI-assisted development), sehingga sebagian besar proses coding manual tidak menjadi kendala utama. Namun tetap ada beberapa tantangan dalam proses pengerjaannya:

1. **Menyusun instruksi (prompt) yang tepat ke AI**
   Menerjemahkan ide gameplay (aturan Wordle, sistem skor/streak, mode gelap-terang) menjadi instruksi yang cukup jelas dan detail agar hasil kode dari AI sesuai ekspektasi, terkadang perlu beberapa kali iterasi/penyempurnaan prompt.
   **Solusi:** Melakukan pendekatan bertahap — meminta AI membangun satu fitur inti dulu (mekanisme tebak kata), lalu menambahkan fitur lain (skor, streak, tema, keyboard virtual) secara bertahap sambil terus diuji.

2. **Memastikan kebenaran & kesesuaian hasil kode AI**
   Kode yang dihasilkan AI perlu tetap diverifikasi dan diuji langsung di Godot untuk memastikan tidak ada perilaku yang tidak diinginkan (misalnya validasi kata, logika warna huruf, atau reset state antar ronde).
   **Solusi:** Melakukan playtesting berulang pada tiap iterasi, serta meminta AI memperbaiki bagian yang belum sesuai berdasarkan hasil pengujian tersebut.

3. **Menyesuaikan sumber data kosakata**
   Daftar kata dari KBBI v6.1.0 sangat besar (14.042 kata) dan mencakup banyak kata yang jarang digunakan sehari-hari, arkais, atau istilah teknis/kedaerahan, sehingga bisa membuat game terasa sulit bagi pemain awam.
   **Solusi:** Kata jawaban dan validasi tebakan tetap memakai daftar KBBI resmi (agar konsisten dengan kamus), namun daftar ini dapat dipersempit ke depannya menjadi kata-kata yang lebih umum jika diperlukan.

## Video Gameplay
