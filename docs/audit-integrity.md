# Audit integritas owner waroeng

Audit selesai 2026-09-26 menggunakan code-review-and-quality, debugging-and-error-recovery, dan Ponytail full. Perubahan pengguna dipertahankan; tidak ada reset database, perubahan identitas instalasi, atau dependensi baru untuk audit.

## Bug terkonfirmasi dan perbaikan

| Tingkat | Akar penyebab dan dampak | Perbaikan | Regresi |
| --- | --- | --- | --- |
| Tinggi | Penghapusan pembelian menggunakan MAX(0, stock - qty). Beli 10, jual 8, hapus pembelian lalu penjualan menghasilkan stok 8 meski semua transaksi hilang. | Tolak pembalikan bila stok tidak cukup, dalam transaksi atomik. | repository_integrity_test: stok tetap 2 saat ditolak, kembali 0 setelah urutan pembatalan yang valid. |
| Tinggi | NaN/Infinity lolos perbandingan harga/nominal; Infinity terbukti tersimpan dan tidak dapat dienkode sebagai JSON. | Validasi isFinite di repository bersama dan formulir. | repository_integrity_test: create/update produk, penjualan, pengeluaran ditolak tanpa perubahan stok/data. |
| Tinggi | Persiapan notifikasi dapat melempar setelah commit; formulir menganggap penyimpanan gagal dan pengguna dapat mengulang transaksi. | Kegagalan notifikasi dipisahkan dari hasil commit. | provider_integrity_test: sale/expense tetap sukses dan hanya satu catatan tersimpan. |
| Sedang | File pemulihan terbaru dipilih hanya dari nama; file terpotong menutupi salinan lama yang valid. | Tulis/verifikasi .tmp sebelum rename; lewati JSON rusak/tidak terbaca. | backup_service_test dan pemeriksaan Android. |
| Sedang | TextStyle inherit:false kehilangan baseline bawaan; ListTile crash di tema klasik. | Baseline alfabetik pada normalisasi tema bersama. | history_delete_failure_test pada kedua tema. |
| Sedang | Riwayat dihapus secara visual sebelum operasi database selesai, tanpa penanganan kegagalan. | Tunggu penghapusan dalam confirmDismiss; bila gagal pertahankan baris dan tampilkan pesan. | history_delete_failure_test pada kedua tema. |
| Sedang | Riwayat tidak diinvalidate setelah penyimpanan; stok menipis tidak mengikuti perubahan produk. | Lengkapi invalidasi dan dependensi Riverpod, termasuk jumlah terjual. | provider_integrity_test: riwayat yang sedang diamati dan perubahan ambang stok. |
| Rendah | Unicode lowercasing UI tidak sesuai SQLite NOCASE ASCII; dua kategori berbeda menjadi satu pilihan. | Gunakan kunci ASCII yang sama dengan aturan database. | provider_integrity_test: kategori Unicode tetap terpisah, SNACK/Snack tetap digabung. |

## Verifikasi yang dijalankan

- dart format lib test tool: selesai.
- flutter test --no-pub: 72 tes lulus.
- flutter analyze --no-pub: tidak ada masalah.
- python test/category_sql_test.py: 2 tes lulus.
- Emulator emulator-5554: BACKUP_ANDROID_CHECK_PASS pada 2026-09-26; round trip, relasi, tema, recovery, salinan rusak, dan rollback. Seluruh penggantian data memakai SQLite in-memory dan direktori sementara baru.
- Log lokal: build/audit-tests.txt, build/audit-analyze.txt, build/audit-android.txt. Status PASS juga diperiksa langsung melalui logcat dan layar emulator.

- Aplikasi utama dipasang kembali. Dashboard dan riwayat terisi tampil pada kedua tema. Tema Forui tetap aktif setelah force-stop/relaunch; pilihan klasik semula dikembalikan setelah tes. Tidak ada penghapusan transaksi usaha untuk pemeriksaan UI ini.

## Batas pemeriksaan

Tidak ada bukti kegagalan atomisitas restore pada skenario yang diuji. Gangguan listrik/proses mati tepat saat penulisan berkas belum disimulasikan; rename dan flush bukan klaim jaminan terhadap seluruh kegagalan perangkat. Batas backup 20 MiB/100.000 baris per tabel adalah batas format yang sudah didokumentasikan, bukan bug baru. Audit ini tidak menyatakan aplikasi bebas dari seluruh kemungkinan bug.

## Koreksi setelah laporan pengguna

Screenshot pengguna membuktikan audit awal melewatkan crash dropdown Produk Terlaris pada tema klasik. Reproduksi dengan buildAppTheme(true) gagal di DropdownButton._denseButtonHeight karena titleMedium.fontSize null. Tes kategori sebelumnya memakai MaterialApp default, bukan tema produksi. Perbaikan menggabungkan geometri tipografi Material sebelum menonaktifkan inheritance. Tes kategori sekarang menjalankan seluruh alur filter dan penambahan kategori pada kedua tema, termasuk kontrol selebar 320px. Klaim awal verifikasi dashboard tidak mencakup bagian dropdown tersebut.

Verifikasi koreksi: 73 tes Flutter lulus, analyzer bersih. Emulator: dropdown dibuka pada tema klasik dan Forui, kategori Snack dipilih lalu direset ke semua kategori; dialog Tambah kategori dibuka dan dibatalkan. Bagian Produk Terlaris digulir hingga terlihat. Screenshot: build/dashboard-classic-fixed.png.
