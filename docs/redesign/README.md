# Owner Waroeng — desain disetujui dan diterapkan

29 September 2026. Arah desain revisi 02 disetujui, lalu diterapkan ke aplikasi Flutter. Bagian pratinjau di bawah tetap mencatat keputusan Tahap 1; hasil produksi dicatat pada bagian Tahap 2.

## Lihat dan coba

- [Pratinjau interaktif](preview.html), atau http://127.0.0.1:8765/docs/redesign/preview.html ketika server lokal berjalan.
- Server dari root: `python -m http.server 8765 --bind 127.0.0.1`. HTML juga dapat dibuka langsung; font dan suara tidak membutuhkan jaringan.
- Screenshot browser: [oranye](preview-orange-v2.png), [ungu](preview-purple-v2.png), [Pengaturan](preview-settings-v2.png).
- [Pratinjau lama](preview-v1.html) dan [inventaris/rencana awal](README-v1.md) dipertahankan untuk perbandingan. Keputusan visual di halaman ini menggantikan usulan lama.

Coba pilihan tema, lebar 320/360/412, dan teks 100/130/200%. Klik gear atau **Suara & tampilan** untuk nada sukses dan mute. Simulasi simpan dapat dipilih Berhasil/Gagal; mencoba ulang mempertahankan pilihan. Semua data fiktif dan preferensi pratinjau hilang saat reload.

## Keputusan dan perubahan

Pengguna menilai usulan pertama terlalu dipaksakan, generik, dan membosankan. Revisi memilih **rapi dan premium seperti aplikasi keuangan**, dengan respons visual dan klik halus. Penggunaan utama: mencatat langsung saat melayani. Empat tab tetap Beranda, Produk, Riwayat, Laporan; Gear dan Kelola Produk tetap tersedia.

- Ringkasan usaha memakai bidang gelap kontras, angka utama tegas, dan informasi sekunder dengan bobot lebih rendah. Bingkai berulang dikurangi pada peringatan stok dan ranking.
- Catat penjualan menjadi aksi utama; Beli stok/Pengeluaran menggunakan permukaan netral. Barang dipilih mendapat latar aksen ringan dan subtotal bertanda centang.
- Pencarian mempertahankan pilihan; total dan simpan tetap terlihat, catatan opsional. Simpan dikunci selama proses dan gagal tidak menghapus input.
- Dua tema tetap Klasik — Ungu dan Forui — Oranye. Bidang ringkasan gelap merupakan bagian kedua tema terang, bukan tambahan mode gelap.

## Design system

| Token/perilaku | Spesifikasi pratinjau |
|---|---|
| Permukaan | Putih; kontrol #F2F3F6; pemisah #E5E7EB |
| Teks | Utama #19212E; sekunder #596273 |
| Forui | Aksi #B84009; pilihan #FFF0E7; ringkasan #202835 |
| Klasik | Aksi #6543C5; pilihan #F1ECFF; ringkasan #282236 |
| Tipografi | Noto Sans lokal; badan 14; judul 16–20; angka utama sekitar 34 pada 100%; angka tabular |
| Jarak/radius | Gutter 16; jarak 4/8/12/16/20/24; kontrol 10–12; ringkasan 18 |
| Sentuh | Minimal 48 × 48; label ikon penting; fokus terlihat |
| Gerak | Tekanan tombol 120 ms, perubahan warna 160 ms; hormati reduced motion |
| Suara | Sine pendek 520 Hz untuk tombol; 660/880 Hz untuk sukses, envelope lembut |

Suara default aktif, dapat dimatikan; tidak diputar saat membuka halaman, scroll, atau mengetik. Sukses berbunyi hanya setelah simulasi berhasil. Kegagalan audio tidak memblokir UI. Preferensi suara aplikasi final harus disimpan lokal dan perilaku silent mode diperiksa di Android; belum diimplementasikan di Tahap 1.

Ikon masih SVG skematis; produksi menggunakan AppIcon dengan Material/Phosphor sesuai tema. Flaticon ditinjau sebagai referensi tanpa unduhan aset. Font produksi offline tetap dipertahankan; tidak ada dependensi baru.

## Sumber

- [Diskusi desain POS](https://stackoverflow.com/questions/1108799/pos-ui-design-development-what-should-be-included-avoided), dibaca lewat akun Chrome pengguna: masukan tentang kecepatan, feedback, dan konteks kerja. Diskusi lama/opini, bukan bukti tren visual terbaru.
- [Grid Feature Cards dari bookmark pengguna](https://21st.dev/@efferd/components/grid-feature-cards): inspirasi hierarki/pembagian bidang. Tidak menyalin kode React atau efek shader ke kasir.
- UI UX Pro Max: pencarian `finance dashboard refined interactive --design-system` menghasilkan pola pemasaran yang tidak dipakai. Pencarian lanjutan `minimalism high contrast dashboard --domain style` dipakai untuk kontras dan hierarki dengan adaptasi mobile.
- Context7 `/mdn/content`: user gesture/resume dan gain envelope, sesuai [panduan Web Audio MDN](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Best_practices). Suara disintesis lokal.

## Verifikasi yang dijalankan

- `python docs/redesign/check_preview.py`: ID unik, referensi ikon, aset offline, sintaks JavaScript lulus.
- `node docs/redesign/check_interactions.cjs`: retensi pilihan saat cari, pengiriman ganda, penguncian simpan, snapshot hasil gagal, sukses, mute, keranjang kosong lulus. Menggunakan DOM stub; dilengkapi pemeriksaan browser.
- Chrome: 18 kombinasi dua tema, lebar 320/360/412, teks 100/130/200% pada panel dashboard/penjualan; tidak ditemukan overflow horizontal atau tombol/select di bawah 48 CSS px. [Hasil pengukuran](preview-v2-layout-checks.json).
- Chrome: dropdown dibuka dan Sembako dipilih; validasi kategori kosong; tambah Perawatan rumah tanpa produk; cari Biskuit dan tambah unit menghasilkan Rp19.000; gagal simpan mempertahankan nilai; dialog Pengaturan, mute/aktif, dan pilihan tema bekerja.
- Viewport browser 320 × 740 dan teks 200%: dialog Pengaturan terbuka, dapat digulir, tanpa overflow horizontal. Viewport dikembalikan setelah pemeriksaan.
- Screenshot kedua tema dan Pengaturan direkam dari browser. Pemicu suara diuji; kualitas dan volume speaker pengguna belum dinilai melalui pendengaran manusia.

Flutter analyze/test/build/emulator tidak dijalankan ulang karena perubahan hanya artefak Tahap 1. CSS bukan logical pixel Flutter. Keyboard Android, pembaca layar, persistensi tema/suara, database dan restore tetap memerlukan verifikasi produksi setelah persetujuan.

## Setelah persetujuan visual

Tema/komponen → dashboard → transaksi → produk/stok → laporan → Pengaturan/backup. Inventaris route/overlay serta temuan awal tetap tersedia di arsip. Bug pemetaan rentang laporan dan target restock 38 × 38 belum diperbaiki dalam revisi ini.

Pertahankan versi library, Riverpod, router, aturan stok, histori, kategori, database dan backup. Gunakan Context7 untuk API terpasang. Uji tema produksi 320/360/412, teks besar, dropdown, keyboard, dan scroll; kemudian formatter/analyze/full tests/APK/emulator. Jangan scaffolding atau mengubah skema untuk layout.

### Tambahan revisi: grafik dan keberhasilan penjualan

Dashboard memakai grafik batang pemasukan tujuh hari, dengan label hari, nilai ribuan rupiah, dan tinggi relatif terhadap skala 500 ribu. Penjualan sukses membuka dialog ringkas dengan animasi masuk 180 ms dan centang tergambar 420 ms, total, serta tombol Lanjutkan. Jalur gagal tidak membuka dialog sukses; animasi dapat diulang pada simpan berikutnya. Reduced motion menonaktifkan animasi tetapi mempertahankan centang dan pesan. Ini masih perilaku pratinjau; produksi baru menampilkan sukses setelah commit berhasil.

Grafik batang naik satu per satu dari kiri ke kanan, masing-masing 350 ms (total tujuh batang 2.450 ms), dengan easing lembut saat minimal 35% grafik masuk layar. Animasi dapat diulang setelah grafik sepenuhnya keluar layar, tidak diulang hanya karena sedikit bergeser. Reduced motion menampilkan batang statis.

Karakter memakai spritesheet asli cuteGirl dengan timing frame bawaan, satu putaran setelah animationend batang paling kanan. Setiap rangkaian animasi grafik selesai, karakter melompat satu kali; scroll ulang dapat memutar karakter lagi. Keluar dari grafik membatalkan lompatan yang sedang berlangsung. Karakter hilang setelah putaran selesai. Karakter berdiri tepat di atas batang paling kanan dengan ruang lompat di sisi kanan keterangan, tanpa padding atas yang merenggangkan seluruh grafik. Nilai berada di bawah label hari agar tidak tertutup karakter; label dapat membungkus. Reduced motion tidak memutar karakter.
## Tahap 2 - aplikasi Flutter

Rute utama sekarang empat tab tetap: Beranda, Produk, Riwayat, Laporan. Form penjualan, pengeluaran/restok, tambah/edit produk, monitor stok, rincian laporan, dan Pengaturan memakai alur layar penuh. Dasbor memakai ringkasan kontras dan aksi penjualan utama; stok, ranking, dan grafik tetap mudah dibaca. Dua tema tetap Klasik - Ungu dan Forui - Oranye, memakai font/ikon offline dan pilihan tersimpan.

Grafik Flutter memakai tujuh batang 350 ms berurutan dan karakter satu putaran 1.930 ms setelah batang ketujuh selesai. Karakter keluar sendiri; menggulir grafik sepenuhnya keluar lalu masuk memulai urutan baru. Dialog penjualan tampil sesudah commit, dengan masuk 180 ms dan centang 420 ms. Teks/harga disusun agar muat pada layar sempit. Reduced motion menampilkan grafik dan centang statis tanpa karakter.

Karakter produksi kini berdiri di batang dengan pemasukan tertinggi, bukan selalu batang terakhir. Jika nilai tertinggi sama, batang paling kanan dipilih. Warna aksen penuh mengikuti batang terpilih; label satuan bergeser ke sisi lain dan membatasi lebar agar tidak tertutup karakter pada layar sempit.

Nada tombol dan nada sukses berasal dari WAV lokal. Sakelar suara tersimpan di perangkat dan menghormati mode senyap Android. Backup JSON tetap menyimpan tema dan data usaha; pilihan suara tetap lokal setelah pemulihan. Laporan bulanan membuka empat rentang tepat: 1-7, 8-14, 15-21, 22-akhir bulan. Penyimpanan produk edit menunggu muat selesai dan menyediakan coba lagi saat gagal; kontrol restok berukuran sentuh minimal 48 logical pixels.

Screenshot nyata emulator: [dashboard oranye](screenshots/stage2/orange-dashboard.png), [grafik dan karakter](screenshots/stage2/orange-celebration.png), [dashboard ungu](screenshots/stage2/purple-dashboard.png), [Pengaturan ungu](screenshots/stage2/purple-settings.png), [penjualan sukses](screenshots/stage2/purple-sale-success.png), [laporan](screenshots/stage2/purple-report-month.png). Screenshot berasal dari `tool/verify_redesign_android.dart` dengan database uji terpisah. Tema ungu juga dicek setelah proses aplikasi dihentikan dan dibuka lagi.

Verifikasi produksi: widget layout kedua tema pada 320/360/412 logical pixels dan teks 200%, tes timing grafik, tes alur transaksi sukses/gagal, tes laporan rentang tanggal, dan backup SQLite terisolasi. `tool/verify_backup_android.dart` mencetak `BACKUP_ANDROID_CHECK_PASS` pada emulator untuk round trip, pemulihan, relasi, dan rollback. Pada emulator, backup JSON disimpan lewat pemilih dokumen Android, transaksi baru menurunkan stok contoh dari 40 ke 39, lalu pemulihan file mengembalikannya ke 40. Ini memakai data uji, bukan database usaha pengguna. Pilihan tema dan sakelar suara bertahan setelah proses aplikasi dihentikan dan dibuka ulang. Keluaran audio fisik pada mode senyap belum diukur langsung; kode native memeriksa mode dering, volume, dan status aplikasi.

Pemeriksaan akhir 29 September 2026: `dart format lib test tool` selesai; `flutter analyze --no-pub` tanpa temuan; `flutter test --no-pub --reporter expanded` lulus 110 tes; `flutter build apk --release --no-pub` menghasilkan APK 62,7 MB. `python test/category_sql_test.py` lulus 2 tes; `python docs/redesign/check_preview.py` dan `node docs/redesign/check_interactions.cjs` lulus. Sesudah pengujian Android dengan database terisolasi, `flutter run --no-pub -d emulator-5554 -t lib/main.dart --no-resident` memasang dan menjalankan kembali entrypoint normal tanpa menghapus data aplikasi. Perubahan posisi karakter juga diperiksa pada emulator saat batang tertinggi berada di kiri; karakter berada di atas batang itu dan label satuan tetap terbaca.
