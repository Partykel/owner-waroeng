import 'package:ghepek_in/shared/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriod = 'harian';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reports),
        actions: [
          IconButton(
            icon: const AppIcon(PhosphorIconsRegular.calendar),
            tooltip: 'Pilih tanggal',
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const AppIcon(PhosphorIconsRegular.calendarDot),
            tooltip: 'Kembali ke hari ini',
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _buildDateBanner(),
          _buildPeriodSelector(),
          ..._buildReportContent(),
        ],
      ),
    );
  }

  Widget _buildDateBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          const AppIcon(PhosphorIconsRegular.calendarCheck, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Periode dasar: ${DateFormatter.formatFull(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final period in const {
            'harian': 'Harian',
            'mingguan': 'Mingguan',
            'bulanan': 'Bulanan',
          }.entries)
            ChoiceChip(
              label: Text(period.value),
              selected: _selectedPeriod == period.key,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => setState(() => _selectedPeriod = period.key),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildReportContent() {
    final baseDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    switch (_selectedPeriod) {
      case 'mingguan':
        return <Widget>[
          _buildPeriodCard(
            title: '7 hari hingga tanggal dipilih',
            subtitle: _rangeLabel(
              baseDate.subtract(const Duration(days: 6)),
              baseDate,
            ),
            onTap: () =>
                _navigateToDetail(baseDate, '7 hari hingga tanggal dipilih'),
          ),
          const SizedBox(height: 12),
          _buildPeriodCard(
            title: '7 hari hingga enam hari sebelumnya',
            subtitle: DateFormatter.formatFull(
              baseDate.subtract(const Duration(days: 6)),
            ),
            onTap: () => _navigateToDetail(
              baseDate.subtract(const Duration(days: 6)),
              '7 hari hingga enam hari sebelumnya',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ringkasan Harian',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(7, (index) {
            final date = baseDate.subtract(Duration(days: 6 - index));
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPeriodCard(
                title: DateFormatter.formatRelative(date),
                subtitle: DateFormatter.formatFull(date),
                onTap: () => _navigateToDetail(
                  date,
                  DateFormatter.formatFull(date),
                  period: 'harian',
                ),
              ),
            );
          }),
        ];

      case 'bulanan':
        final monthLabel = DateFormatter.formatMonthYear(baseDate);
        return <Widget>[
          _buildPeriodCard(
            title: 'Bulan $monthLabel',
            subtitle: 'Data transaksi pada bulan yang dipilih',
            onTap: () => _navigateToDetail(baseDate, 'Bulan $monthLabel'),
          ),
          const SizedBox(height: 12),
          _buildPeriodCard(
            title: 'Rangkuman Mingguan',
            subtitle: '4 minggu dalam bulan terpilih',
            onTap: () => _navigateToDetail(baseDate, 'Rangkuman Mingguan'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mingguan Bulan Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (index) {
            final weekLabel = 'Minggu ${index + 1}';
            final start = DateTime(
              baseDate.year,
              baseDate.month,
              1 + index * 7,
            );
            final end = index == 3
                ? DateTime(baseDate.year, baseDate.month + 1, 0)
                : DateTime(baseDate.year, baseDate.month, 7 + index * 7);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPeriodCard(
                title: weekLabel,
                subtitle: _rangeLabel(start, end),
                onTap: () => _navigateToDetail(
                  end,
                  weekLabel,
                  period: 'mingguan',
                  startDate: start,
                  endDate: end,
                ),
              ),
            );
          }),
        ];

      default:
        return <Widget>[
          _buildPeriodCard(
            title: 'Tanggal Dipilih',
            subtitle: DateFormatter.formatFull(baseDate),
            onTap: () => _navigateToDetail(baseDate, 'Tanggal Dipilih'),
          ),
          const SizedBox(height: 12),
          _buildPeriodCard(
            title: 'Sehari Sebelumnya',
            subtitle: DateFormatter.formatFull(
              baseDate.subtract(const Duration(days: 1)),
            ),
            onTap: () => _navigateToDetail(
              baseDate.subtract(const Duration(days: 1)),
              'Sehari Sebelumnya',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '7 Hari Terakhir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(7, (index) {
            final date = baseDate.subtract(Duration(days: 6 - index));
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPeriodCard(
                title: DateFormatter.formatRelative(date),
                subtitle: DateFormatter.formatFull(date),
                onTap: () => _navigateToDetail(
                  date,
                  DateFormatter.formatFull(date),
                  period: 'harian',
                ),
              ),
            );
          }),
        ];
    }
  }

  Widget _buildPeriodCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const AppIcon(PhosphorIconsRegular.caretRight),
        onTap: onTap,
      ),
    );
  }

  String _iso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _rangeLabel(DateTime start, DateTime end) =>
      '${DateFormatter.formatFull(start)} - ${DateFormatter.formatFull(end)}';

  void _navigateToDetail(
    DateTime date,
    String label, {
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    context.push(
      '/reports/detail',
      extra: {
        'period': period ?? _selectedPeriod,
        'date': _iso(date),
        'label': label,
        if (startDate != null) 'startDate': _iso(startDate),
        if (endDate != null) 'endDate': _iso(endDate),
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }
}
