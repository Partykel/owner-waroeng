# Owner Waroeng — revisi Tahap 1, usulan 02

27 September 2026. **Pratinjau revisi siap ditinjau; persetujuan penerapan ke Flutter masih pending.** Tidak ada perubahan produksi atau database dari pekerjaan ini.

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
