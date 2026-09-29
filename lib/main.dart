import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:forui/forui.dart';
import 'shared/theme/app_theme.dart';
import 'app/router.dart';
import 'core/services/notification_service.dart';
import 'features/settings/settings_provider.dart';
import 'shared/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await initializeDateFormatting('id_ID', null);
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans',
    ], await rootBundle.loadString('assets/fonts/noto_sans/OFL.txt'));
  });
  final container = ProviderContainer();
  await container.read(themePreferenceProvider.future);
  await container.read(soundPreferenceProvider.future);
  runApp(
    UncontrolledProviderScope(container: container, child: const GhepekInApp()),
  );
}

class GhepekInApp extends ConsumerWidget {
  const GhepekInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePreferenceProvider).value ?? 'forui';
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: buildAppTheme(selected == 'classic'),
      builder: (context, child) => FTheme(
        data: selected == 'classic' ? classicForuiTheme : ownerTheme,
        child: child!,
      ),
      routerConfig: router,
    );
  }
}
