# owner waroeng

Aplikasi kasir digital offline untuk UMKM kuliner berbasis Flutter.

Mulai versi 1.1, Ghepek.in berganti nama menjadi owner waroeng.

## Ringkasan fitur

- CRUD produk
- Kategori produk sendiri melalui tambah/edit produk, termasuk dari Beli Stok; filter kategori pada produk terlaris hari ini.
- Tombol Tambah kategori di samping filter dashboard untuk menyimpan kategori tanpa perlu membuat produk.
- Penjualan multi-produk
- Pengeluaran operasional dan restock
- Stok otomatis berkurang/bertambah
- Dashboard pemasukan, pengeluaran, laba bersih
- Grafik tren 7 hari
- Laporan harian, mingguan, bulanan
- Notifikasi stok menipis dan defisit
- Riwayat transaksi dengan hapus dan restore stok
- Pencarian dan sorting produk, termasuk terlaris hari ini

## Teknologi

- Flutter
- Riverpod
- go_router
- SQLite via sqflite
- fl_chart
- flutter_local_notifications

## Struktur singkat

- `lib/core` — database, service notifikasi, utilitas
- `lib/features/product` — manajemen produk
- `lib/features/transaction` — penjualan, pengeluaran, riwayat
- `lib/features/dashboard` — ringkasan utama
- `lib/features/report` — laporan periode

## Cara menjalankan

```bash
git clone https://github.com/Partykel/GhepekIn-OfflineStockApp.git
cd GhepekIn-OfflineStockApp
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk
```

## Catatan implementasi

- Data disimpan lokal di SQLite.
- Stok dan histori transaksi dihitung dari data transaksi, bukan field total yang diredundansi.
- Penghapusan transaksi penjualan akan mengembalikan stok.
- Penghapusan pengeluaran kategori `Beli Stok` juga mengembalikan stok.

## Pengembangan lanjutan

Jika ingin melanjutkan ke versi berikutnya, kandidat yang paling masuk akal adalah:

- export backup
- pencarian laporan lebih detail
- filter riwayat berdasarkan tanggal
- printer struk
- sinkronisasi cloud


### Pengaturan, tema, dan backup

Buka ikon gear di kanan atas dashboard. Pilih **Klasik - Ungu** atau **Forui - Oranye**; pilihan tersimpan dan berlaku pada seluruh halaman.

- **Simpan Backup**: pilih folder melalui dialog Android untuk menyimpan seluruh data usaha dan tema sebagai satu file JSON. File belum dienkripsi, jadi simpan di tempat pribadi.
- **Pulihkan Backup**: pilih JSON, periksa ringkasan, lalu konfirmasi. Data lokal dan tema diganti dengan isi backup, bukan digabung.
- Sebelum pemulihan, aplikasi menyimpan salinan data lama. Gunakan **Simpan Salinan Sebelum Pemulihan** untuk mengekspornya, kemudian pilih file itu lewat **Pulihkan Backup** bila diperlukan. Salinan internal hilang jika aplikasi dihapus.
- Backup format v1 mendukung skema v5, maksimal 20 MiB dan 100.000 baris per tabel. Pembatalan tidak mengubah data; kegagalan pemulihan database membatalkan seluruh perubahan.
