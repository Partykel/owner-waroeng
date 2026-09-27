import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../product/providers/product_provider.dart';
import '../transaction/providers/transaction_provider.dart';
import 'backup_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  bool _notificationSyncFailed = false;
  String? _message;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on FormatException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Proses gagal. Periksa berkas dan ruang penyimpanan, lalu coba lagi. Data usaha tidak diganti jika pemulihan gagal.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(Uint8List bytes, {bool recovery = false}) async {
    final stamp = DateFormat('yyyy-MM-dd-HHmmss').format(DateTime.now());
    final saved = await FilePicker.saveFile(
      fileName:
          'owner-waroeng-${recovery ? 'sebelum-pemulihan' : 'backup'}-$stamp.json',
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'Simpan Backup',
    );
    if (saved != null && mounted) {
      setState(
        () => _message = 'Backup berhasil disimpan ke lokasi yang dipilih.',
      );
    }
  }

  Future<void> _export() async {
    final service = await BackupService.open();
    await _save((await service.export()).encode());
  }

  Future<void> _exportRecovery() async {
    final service = await BackupService.open();
    final file = await service.latestRecovery();
    if (file == null) {
      if (mounted) {
        setState(() => _message = 'Belum ada salinan sebelum pemulihan.');
      }
      return;
    }
    final backup = await BackupData.read(file.openRead());
    await _save(backup.encode(), recovery: true);
  }

  Future<void> _restore() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Pilih Backup JSON',
      type: FileType.any,
    );
    if (file == null) return;
    final length = await file.length();
    if (length != null && length > BackupData.maxBytes) {
      throw const FormatException('Backup maksimal 20 MB.');
    }
    final backup = await BackupData.read(file.readAsByteStream());
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti data dengan backup?'),
        content: SingleChildScrollView(
          child: Text(
            'Dibuat: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(backup.createdAt.toLocal())}\n'
            '${backup.rows('products').length} produk (termasuk yang dihapus)\n'
            '${backup.rows('transactions').length} transaksi\n'
            'Tema: ${backup.theme == 'classic' ? 'Klasik — Ungu' : 'Forui — Oranye'}\n\n'
            'Seluruh data usaha dan pilihan tema saat ini akan diganti, bukan digabung. '
            'Salinan data lama akan disimpan di aplikasi sebelum pemulihan.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ganti dan Pulihkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final service = await BackupService.open();
    await service.restore(backup);
    if (!mounted) return;
    ref.invalidate(themePreferenceProvider);
    ref.invalidate(allProductsProvider);
    ref.invalidate(productCategoriesProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(todaySoldCountByProductProvider);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(sevenDayTrendProvider);
    ref.invalidate(addSaleProvider);
    ref.invalidate(addExpenseProvider);
    _notificationSyncFailed = false;
    // Notification delivery happens after commit and cannot roll back restored data.
    try {
      await NotificationService().resyncStockAlerts();
      if (mounted) {
        setState(
          () => _message =
              'Backup berhasil dipulihkan. Data usaha dan tema sudah diperbarui.',
        );
      }
    } catch (_) {
      _notificationSyncFailed = true;
      if (mounted) {
        setState(
          () => _message =
              'Data dan tema berhasil dipulihkan, tetapi notifikasi belum tersinkron. Gunakan Coba Sinkronkan Notifikasi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(themePreferenceProvider).value ?? 'forui';
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Tampilan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Pilih gaya aplikasi. Pilihan tersimpan di perangkat ini.',
              ),
              const SizedBox(height: 12),
              for (final entry in {
                'classic': 'Klasik — Ungu',
                'forui': 'Forui — Oranye',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    selected: selected == entry.key,
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await ref
                                  .read(themePreferenceProvider.notifier)
                                  .select(entry.key);
                            }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Theme(
                              data: buildAppTheme(entry.key == 'classic'),
                              child: Builder(
                                builder: (context) => Container(
                                  width: 64,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  child: AppIcon(
                                    PhosphorIconsRegular.storefront,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.value)),
                            if (selected == entry.key)
                              const AppIcon(
                                PhosphorIconsRegular.check,
                                semanticLabel: 'Tema aktif',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Backup Data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Simpan salinan produk, kategori, stok, transaksi, dan tema dalam satu file JSON. Pilih folder di luar aplikasi agar file tetap tersedia saat pindah HP atau aplikasi dihapus.',
              ),
              const SizedBox(height: 8),
              const Text(
                'File belum dienkripsi. Simpan di tempat pribadi. Pemulihan mengganti seluruh data usaha dan pilihan tema.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : () => _run(_export),
                icon: const AppIcon(PhosphorIconsRegular.downloadSimple),
                label: const Text('Simpan Backup'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(_restore),
                icon: const AppIcon(PhosphorIconsRegular.uploadSimple),
                label: const Text('Pulihkan Backup'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => _run(_exportRecovery),
                child: const Text('Simpan Salinan Sebelum Pemulihan'),
              ),
              if (_notificationSyncFailed)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await NotificationService().resyncStockAlerts();
                          _notificationSyncFailed = false;
                          if (mounted) {
                            setState(
                              () => _message =
                                  'Notifikasi stok sudah disinkronkan.',
                            );
                          }
                        }),
                  child: const Text('Coba Sinkronkan Notifikasi'),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(liveRegion: true, child: Text(_message!)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
