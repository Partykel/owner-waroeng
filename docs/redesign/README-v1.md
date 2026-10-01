> Arsip usulan 01. Keputusan terbaru ada di README.md.

# Owner Waroeng - usulan redesign, Tahap 1

Status: **menunggu satu persetujuan arah desain**. Dibuat 26 September 2026.
Belum ada perubahan kode produksi oleh pekerjaan redesign ini.

## Lihat dan coba

- [Pratinjau interaktif](preview.html): buka langsung di Chrome; seluruh aset lokal. Alternatif: dari root proyek jalankan `python -m http.server 8765 --bind 127.0.0.1`, lalu buka `http://127.0.0.1:8765/docs/redesign/preview.html`.
- [Forui - Oranye](preview-orange.png) dan [Klasik - Ungu](preview-purple.png).
- [Hasil ukuran panel prototipe](preview-layout-checks.json).
- Tampilan aplikasi Android terpasang saat observasi: [dashboard](current-dashboard.png), [bagian bawah dashboard](current-dashboard-lower.png), [penjualan](current-sale.png), [laporan](current-reports.png).

Prototipe HTML adalah alat persetujuan visual, bukan implementasi Flutter atau bukti tes aplikasi. Data fiktif hanya berada di memori halaman. Refresh mengembalikannya. Tema, lebar, ukuran teks, pencarian, pilihan produk, jumlah, filter kategori, dialog kategori, dan simulasi simpan dapat dicoba. Tombol menuju layar di luar dua preview membuka penjelasan alurnya. Browser tidak mengakses SQLite atau file backup pengguna.

## Keputusan desain yang diminta

**Rekomendasi: Kasir Ringkas.** Ringkasan usaha ringkas, tindakan Catat penjualan yang paling menonjol, Beli stok dan Pengeluaran sebagai tindakan sekunder, peringatan stok yang bisa dibuka, produk terlaris sebelum grafik. Empat tab bawah: Beranda, Produk, Riwayat, Laporan. Gear tetap di kanan atas dan akses Kelola Produk tetap tersedia. Form transaksi fokus pada pencarian produk, jumlah, daftar Dipilih, catatan opsional yang bisa dibuka, dan total + tombol simpan.

**Alternatif: Beranda Familiar.** Hierarki dan komponen sama, tetapi navigasi menggunakan pintasan berlabel pada beranda tanpa tab bawah. Lebih dekat dengan aplikasi sekarang, dengan biaya tambahan kembali ke beranda untuk pindah bagian. Bisa dibandingkan menggunakan pemilih Arah navigasi pada preview.

Kedua arah berlaku pada **kedua tema**, bukan memilih salah satu tema untuk dihapus. Klasik mempertahankan ungu dan ikon Material; Forui mempertahankan oranye dan Phosphor. Preview memakai satu font Noto Sans lokal dan ikon SVG skematis; implementasi mempertahankan font offline produksi (termasuk Inter Forui) serta AppIcon. Perbedaan font/glyph final harus diperiksa pada Flutter.

Usulan label **Selisih** menggantikan label Laba Bersih, dengan keterangan `pemasukan − pengeluaran`. Perhitungan tidak berubah. Ini memperjelas angka yang memang dihitung aplikasi, bukan menambahkan perhitungan akuntansi baru.

## Pemeriksaan awal dan dasar rancangan

- Branch `version-1.1`; working tree sudah memiliki banyak perubahan tracked/untracked. Tidak dilakukan reset, checkout, staging, commit massal, penggantian dependensi, atau scaffolding.
- AGENTS.md, pubspec.yaml, lockfile, router, tema, AppIcon, seluruh kelas layar, jalur dialog/menu, serta bagian provider/repository yang relevan diperiksa.
- Terpasang: Flutter 3.41.7, Dart 3.11.5; lockfile: flutter_riverpod 3.3.1, go_router 17.2.1, Forui 0.21.3, phosphor_flutter 2.1.0, file_picker 13.1.0.
- Skill routing: using-agent-skills; desain: UI UX Pro Max; implementasi setelah persetujuan: flutter-expert + incremental-implementation; review: code-review-and-quality. Ponytail full: gunakan alur dan dependensi yang ada, perubahan sekecil yang lengkap. Mode ini tidak membuktikan kesehatan hook otomatis.
- Pencarian UI UX Pro Max `retail POS mobile dashboard --design-system` dan percobaan lebih fokus `inventory management dashboard --design-system` menghasilkan pola situs pemasaran yang kurang cocok. Tidak mengadopsi hero pemasaran, social proof, pasangan font web, atau palet baru. Panduan flat/minimal, hierarki, kontras, target sentuh, dan komponen konsisten tetap relevan. Ini adaptasi desain manual, bukan klaim pencarian menemukan desain kasir yang tepat.
- Pencarian `responsive form keyboard --stack flutter` mendukung LayoutBuilder, Form dan validasi. Panduan versi skill tidak dijadikan sumber API Riverpod.
- Context7 resolve Flutter → `/flutter/website`, lalu query responsive layout, keyboard, SafeArea, navigasi dan aksesibilitas. Sumber resmi: [layout adaptif](https://docs.flutter.dev/ui/adaptive-responsive), [aksesibilitas](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility). API sesuai SDK terpasang harus diverifikasi lagi ketika digunakan pada Tahap 2.

## Inventaris seluruh cakupan

Ada 11 route dengan 10 kelas layar. Tidak ditemukan `showModalBottomSheet` di `lib/`; overlay yang ada berupa dialog, menu, dropdown, pemilih tanggal, snackbar, dan pemilih berkas Android.

| Layar / route | Tindakan dan overlay sekarang | Rancangan dan batas perilaku |
|---|---|---|
| Dashboard `/` | 3 angka, grafik 7 hari, 3 terlaris; dropdown kategori; tambah kategori; pintasan produk/stok/riwayat/laporan/settings; penjualan/pengeluaran; refresh | Ringkasan padat → tindakan transaksi → stok → terlaris → grafik; tab bawah; gear dan Kelola Produk tetap ada |
| Terlaris, bagian dashboard | Semua kategori, Tanpa kategori, kategori tersimpan; dialog tambah dengan validasi/saving/error | Filter mengikuti isi, dibatasi lebar tersedia; Tambah kategori di samping, membungkus ke baris berikut pada teks besar; kategori kosong tetap tersimpan |
| Produk `/products` | Cari nama; urut nama/stok/status/terlaris; tambah; tap edit; menu dan tombol edit/hapus; dialog dampak penghapusan | Cari dan urut langsung di atas daftar; kategori terbaca; aksi hapus sekunder; teks tentang histori dipindah ke konfirmasi; akses Monitor Stok |
| Produk baru `/products/new` | Nama, ketik/pilih kategori, jual/modal, info stok nol, minimum, satuan; simpan | Kelompok Identitas, Harga, Persediaan; inline error, fokus kesalahan pertama; stok awal tetap nol |
| Edit `/products/:id/edit` | Memuat data, tidak ditemukan, ubah semua field, hapus dengan dampak | Form bersama; stok hanya info; perubahan harga tidak mengubah transaksi lama; soft delete dipertahankan |
| Monitor `/low-stock` | Produk habis/menipis; semua/habis/menipis; 5 urutan; refresh; semua aman | Label Semua diperjelas menjadi Semua peringatan; keadaan loading/error tetap punya app bar/back/retry; akses Beli Stok |
| Penjualan `/sale/new` | Produk stok tersedia; +/-; catatan; total; simpan | Cari nama, Semua/Dipilih, +/- 48px dengan nama produk, jumlah dan subtotal jelas; catatan bisa dibuka; total dan simpan di area aman |
| Pengeluaran `/expense/new` | Stok/Operasional/Lainnya; nominal untuk nonstok; daftar restok; total modal; tambah produk baru | Jenis mudah dibedakan; pintasan Beli stok membuka jenis stok dari awal; cari produk restok; tampilkan total sekali; validasi nominal tetap |
| Riwayat `/transactions` | Semua/Pemasukan/Pengeluaran; tanggal/reset; daftar; geser hapus + konfirmasi | Filter membungkus; tambah akses tombol/menu untuk tindakan hapus yang sudah ada; konfirmasi jelaskan pengaruh pembalikan stok; gagal tidak menghilangkan baris |
| Laporan `/reports` | Harian/Mingguan/Bulanan, tanggal/hari ini, kartu menuju detail | Rentang tanggal eksplisit; setiap label periode harus sesuai parameter route; hindari tautan berbeda yang membuka agregasi sama |
| Detail `/reports/detail` | Ringkasan, grafik untuk mingguan/bulanan, transaksi; loading/error/kosong | Angka dan rentang di awal, transaksi sesudahnya; rincian angka besar membungkus; retry; rumus dan harga historis tetap |
| Pengaturan `/settings` | 2 pilihan tema; Simpan Backup; Pulihkan Backup; ekspor salinan sebelum restore; sinkron ulang notifikasi | Bagian Tampilan dan Backup Data; kartu preview tema dengan indikator terpilih; pesan hasil dekat tindakan dan dibacakan |
| Backup / restore, dalam settings | Android save/open picker; ringkasan + konfirmasi penggantian; progress; batal; gagal; berhasil | Tetap JSON v1, validasi sebelum perubahan, salinan lama, atomic restore, kunci penulisan, refresh provider, tema backup, notifikasi pascacommit. Tidak menambah login/cloud |

Overlay lengkap: dialog tambah kategori; konfirmasi hapus produk dari daftar dan form edit; konfirmasi hapus transaksi; konfirmasi restore; date picker riwayat/laporan; dropdown kategori dashboard dan satuan produk; popup kategori form; urutan produk; menu produk; urutan stok; menu dashboard layar kecil; pemilih file/simpan native Android. Snackbar dan pesan inline tetap termasuk review.

## Temuan: bedakan bukti dan dugaan

Tidak ada perbaikan produksi pada Tahap 1. Temuan ini menjadi acceptance criteria Tahap 2; jangan menyatakan bug telah diperbaiki.

| Prioritas / jenis | Bukti dan akar penyebab | Tindakan / tes yang direncanakan |
|---|---|---|
| Tinggi, bug pemetaan laporan terkonfirmasi dari kode | `report_screen.dart` mengirim `_selectedPeriod` untuk semua kartu; di tab Bulanan, Minggu 1–4 mengirim baseDate dan period bulanan yang sama. `report_detail_screen.dart::_getDateRange` lalu memilih seluruh bulan. Kartu harian dalam tab Mingguan juga tetap mengirim period mingguan | Benahi label/parameter navigasi agar sesuai rentang nyata, gunakan agregasi yang sudah ada. Fixture pada batas hari/minggu/bulan dan assert parameter + angka. Jangan mengubah rumus laporan |
| Sedang, cacat aksesibilitas terkonfirmasi dari kode | `add_expense_screen.dart::_buildStepperButton` menetapkan Ink 38×38 tanpa perluasan hit area; ikon +/- penjualan dan restok tanpa tooltip/semantic nama produk | Kontrol minimal 48×48, tooltip dan semantics; widget accessibility guideline test pada kedua tema |
| Sedang, masalah kegunaan terlihat | Screenshot dashboard terpasang memperlihatkan FAB menutupi filter kategori pada posisi awal. Pengguna dapat menggulir agar terjangkau, jadi bukan klaim filter selalu tak bisa digunakan | Tindakan dalam layout normal + ruang bawah untuk navigasi, uji tap filter sebelum/sesudah scroll |
| Sedang, masalah kegunaan | `add_sale_screen.dart` hanya list produk tersedia, tidak ada pencarian; catatan dua baris selalu mengambil area footer | Cari nama, tab Dipilih, catatan opsional bisa dibuka; tes query tidak menghapus pilihan |
| Sedang, masalah kegunaan | Dashboard mempunyai 5 ikon kanan pada lebar ≥400; pada layar lebih kecil sudah ada menu lainnya. Banner dan grafik mendahului terlaris | Tab berlabel, susunan informasi baru; pertahankan akses semua route |
| Sedang, masalah feedback dari kode | Beberapa error menampilkan `error.toString()`; trend error menjadi `SizedBox(height:40)`; monitor loading/error tanpa app bar; edit produk `_loadProduct` belum menangani repository error | Pesan ramah, retry, back tetap ada; uji injected load failures. Dampak exception edit perlu reproduksi terisolasi sebelum diberi label bug runtime |
| Sedang, masalah kegunaan | Riwayat mengandalkan gestur geser untuk hapus; konfirmasi generik tidak menjelaskan pengaruh stok | Sediakan menu aksesibel untuk aksi yang sama; jelaskan pembalikan stok; tetap rollback bila tidak cukup |
| Rendah, preferensi visual | Banner bergradasi, bayangan, radius dan kartu berulang menghabiskan ruang | Permukaan netral, border tipis, dekorasi terbatas. Bukan klaim bahwa gradasi merupakan bug |
| Belum terkonfirmasi | Potensi overflow row filter/stepper/angka besar dan footer saat keyboard atau font besar | Belum dites dalam Flutter terbaru pada 320/360/412 dan skala besar. Jangan menyimpulkan aman dari preview HTML |

Observasi Android memakai APK yang sudah terpasang pada emulator Medium_Phone_API_36.1; tidak dibangun ulang di Tahap 1, sehingga bukan bukti kecocokan setiap byte dengan working tree. Dashboard atas/bawah, penjualan, dan tab laporan bulanan diperiksa tanpa menyimpan transaksi, menghapus, atau restore. Screenshot crash dropdown lama tidak dipakai sebagai bukti crash masih ada sekarang.

## Spesifikasi komponen dan perilaku

- Token jarak 4/8/12/16/24; gutter HP 16; lebar konten tablet dibatasi. Radius kontrol 12, kartu 16. Gunakan ThemeData/AppPalette, bukan warna ad-hoc pada setiap layar.
- Ukuran dasar badan 14–16, judul layar 18–20, angka utama 28; angka tabular bila font mendukung. Jangan mengecilkan angka otomatis agar muat; bungkus label/angka besar dan susun kolom pada constraint sempit.
- Preview: tinta #242721, teks sekunder #64655e, permukaan putih; aksen oranye #a94312 / ungu #5853c4. Warna aksen final dipetakan melalui token tema yang ada, kontras teks normal ≥4.5:1 dan kontrol penting ≥3:1. Hijau hanya status positif; merah hanya error/destruktif, bukan semua pengeluaran.
- AppIcon: satu keluarga per tema, glyph dekoratif dikecualikan dari pembacaan, ikon tindakan diberi tooltip + label semantik; state selected/disabled/busy tersedia. Sentuh minimal 48 logical px, tanpa mengecilkan target saat 320px.
- Reuse AppButton, AppTextField, EmptyState, SummaryCard, AppIcon dan buildAppTheme. Tambah shared widget hanya jika benar-benar digunakan beberapa layar. Jangan membuat framework desain baru.
- LayoutBuilder/Wrap untuk constraint, SafeArea dan scrolling yang memperhitungkan keyboard. Footer total + simpan berada dalam alokasi layout, bukan mengambang menutup input. Keyboard dapat ditutup lewat aksi Done/scroll; validasi menggulir ke field pertama yang bermasalah.
- Bottom navigation hanya pada 4 halaman utama. Form dan detail memakai back, tanpa tab bawah untuk mencegah kehilangan draft. Draft hanya di memori; bila sudah berubah, konfirmasi Tinggalkan / Lanjutkan mengisi. Tidak menambah penyimpanan draft permanen.
- Transaksi tidak mendapat fitur pembayaran, diskon, barcode, pelanggan, atau cetak struk. Beli stok tetap harga modal produk yang sudah ada. Produk baru tetap stok 0 sampai dibeli lewat Beli Stok.
- Pilihan tema segera berlaku dan tersimpan sebagaimana sekarang. Pertahankan Material typography geometry, fontSize dan TextBaseline.alphabetic sebelum inherit:false. Backup memulihkan tema sesuai file.

| Keadaan | Perilaku bersama |
|---|---|
| Kosong | Bedakan belum ada data, hasil pencarian nihil, kategori nihil, dan periode nihil. Berikan tindakan yang sesuai, bukan pesan error |
| Loading | Indikator berlabel, navigasi tetap tersedia, jangan menampilkan nol palsu sebagai hasil final |
| Gagal | Pesan yang dapat ditindaklanjuti + Coba lagi; simpan input; error teknis tidak menggantikan pesan utama |
| Validasi | Pesan dekat input, jangan hanya warna; submit fokus/scroll ke kesalahan pertama; nilai uang finite dan aturan yang ada tetap |
| Menyimpan | Kunci aksi terkait dan pengiriman ganda; tampilkan Menyimpan…; tidak mengizinkan meninggalkan restore yang sedang diterapkan |
| Konfirmasi | Hapus dan restore menyebut objek/dampak, Batal jelas; restore wajib ringkasan tanggal/jumlah/tema + Ganti dan Pulihkan |
| Sukses | Tampilkan setelah commit atau file selesai ditulis; refresh tampilan, live region. Kegagalan notifikasi pascacommit dipisahkan dari kegagalan data |
| Batal | Pemilih file/tanggal/dialog tidak mengubah data; jangan tampilkan kesalahan palsu |

## Urutan implementasi setelah persetujuan

1. Rekam baseline diff; buat checkpoint terpilah bila aman tanpa mengikutsertakan file lokal/rahasia. Token dan komponen bersama + shell navigasi. Uji buildAppTheme dua tema termasuk baseline/fontSize.
2. Dashboard, filter terlaris dan dialog kategori. Uji buka/pilih dropdown, kategori kosong/panjang dan refresh.
3. Penjualan, pengeluaran/Beli Stok. Uji pencarian, pilihan tetap saat filter berubah, stok, validasi, error, busy, keyboard dan draft. Repository tetap.
4. Produk, form bersama, monitor stok. Uji edit, soft delete dibatalkan/berhasil/gagal dalam fixture, kategori dan target sentuh.
5. Riwayat dan laporan/detail. Benahi pemetaan periode yang terkonfirmasi; uji rentang/angka fixture, harga historis, kategori perubahan, dan hapus transaksi gagal tetap tampil.
6. Pengaturan/tema/backup. Uji kedua tema termasuk restart, batal picker, korup/versi unsupported, round trip, rollback dan salinan pemulihan menggunakan database terisolasi.
7. Review akhir scoped diff, formatter, analyze, seluruh tes, build APK; emulator kedua tema, setiap halaman digulir sampai bawah dan semua dialog/form penting dibuka. Dokumentasi dan screenshot aktual Flutter, daftar keterbatasan yang tersisa.

Matriks widget: kedua tema × 320/360/412 × textScale 1.0/1.3/2.0, memakai buildAppTheme dan konfigurasi produksi yang relevan. Sertakan nama panjang, angka besar, loading/error/empty, keyboard, safe areas, seluruh bagian bawah, dropdown terbuka lalu dipilih. Ukur aksesibilitas dan periksa TalkBack jika tersedia. Tes mutasi menggunakan database temporer/in-memory, tidak memakai data usaha terpasang.

## Verifikasi Tahap 1

Benar-benar dilakukan: inspeksi kode dan lockfile; Flutter --version; pencarian skill dan Context7; menyalakan emulator tanpa wipe; navigasi baca-saja dan screenshot di atas; membuka prototipe di Chrome; pengukuran 18 kombinasi dua tema × 3 lebar × 3 ukuran teks (tidak ada overflow horizontal pada panel utama atau kontrol terlihat di bawah 48 CSS px); interaksi pencarian, jumlah (Rp11.000 → Rp14.500), tab Dipilih, simulasi saving/sukses, filter Snack, validasi kategori kosong, kategori baru tanpa penjualan.

CSS px pada preview bukan pembuktian logical pixels Flutter, pembaca layar Android, atau keyboard Android. Tidak menjalankan formatter Flutter/analyze/flutter test/build APK untuk redesign pada tahap dokumentasi ini; semua merupakan gerbang Tahap 2. Belum ada screenshot hasil redesign Flutter, karena persetujuan belum diberikan. Pemeriksaan lama dari audit lain tidak dihitung sebagai hasil Tahap 1 ini.

Pemeriksaan artefak yang dapat diulang: `python docs/redesign/check_preview.py` (memerlukan Node yang sudah terpasang untuk `node --check`). Lulus: ID unik, referensi ikon valid, aset font lokal, sintaks JavaScript. Review visual teks 200% juga memperbaiki pemisahan angka utama dan ruang judul di prototipe; pemeriksaan overflow saja tidak cukup menilai keterbacaan. `git diff --check` lulus, dengan peringatan normalisasi LF/CRLF pada perubahan yang sudah ada.
