# Repository Guidelines

## Project Structure & Module Organization

owner waroeng is an offline Flutter cashier and inventory app for culinary businesses. This display name applies from version `1.1.0+2` on branch `version-1.1`. `lib/main.dart` initializes notifications and Indonesian date formatting, then starts `OwnerWaroengApp`; `lib/app/router.dart` defines navigation.

Keep this `AGENTS.md` updated whenever project context, conventions, structure, or development workflows change.

Follow Ponytail full for implementation: reuse existing flows and dependencies, make the smallest complete change, and verify behavior. Following these instructions does not establish that the plugin's automatic hooks are healthy.

- `lib/features/`: product, transaction, dashboard, and report features; keep screens, models, providers, and repositories within their feature where applicable.
- `lib/core/`: SQLite setup and migrations, notification services, and formatting utilities.
- `lib/shared/`: reusable widgets and visual constants.
- `test/`: unit tests and widget tests, including the application smoke test.
- `android/`: Android configuration and native resources under `app/src/main/res/`. Offline Noto Sans fonts and their license are bundled under `assets/fonts/noto_sans/`.
- `README.md`, `PRD-owner-waroeng.md`, and `tutorial_install_owner_waroeng.md` are the current project and installation documents.

## Build, Test, and Development Commands

Run commands from the repository root with a Flutter SDK supporting Dart `^3.11.1`:

- `flutter pub get`: resolve dependencies after cloning or changing `pubspec.yaml`.
- `flutter run`: launch on a connected device or emulator.
- `flutter analyze`: check code using the configured Flutter lints.
- `dart format lib test`: format Dart source and tests; inspect the diff afterward.
- `flutter test`: run all tests.
- `flutter test test/widget_test.dart`: run the application smoke test.
- `python test/category_sql_test.py`: verify category migration and top-seller filtering against SQLite using Python's standard library.
- `flutter build apk`: build an Android APK.

## Coding Style & Naming Conventions

Use Dart formatting with two-space indentation. Name files `snake_case.dart`, classes `UpperCamelCase`, and members `lowerCamelCase`; prefix private members with `_`. Follow `analysis_options.yaml`, which includes `flutter_lints`. Reuse existing themes, widgets, and utilities before adding abstractions or dependencies. Keep related stock and transaction writes atomic.

## Testing Guidelines

Use `flutter_test` and name test files `*_test.dart`. Add focused regression tests for changed behavior. Initialize `id_ID` date data before tests that render or format dates. Run the full suite before submitting; no numeric coverage threshold is configured. For startup or UI changes, also verify on an Android emulator.

## Commit & Pull Request Guidelines

History uses short descriptive subjects such as `Add installation guide`; Conventional Commits are not established. Keep commits focused. PRs should explain behavior changes, list verification commands and results, link relevant issues, and include screenshots for UI changes. Preserve the `v1.0.0` checkpoint tag; develop version 1.1 on a separate branch.

## Configuration & Data Safety

Commit application dependency changes with `pubspec.lock`. Keep build output, local tool settings, signing keys, and secrets out of Git. Preserve existing SQLite data through versioned migrations rather than resetting the database.

Use `AppStrings.appName` for the display name in Flutter and keep the Android manifest label in sync as `owner waroeng`. On 30 September 2026 the owner chose permanent Android application ID `com.pendodol.ownerwaroeng` and requested that active internal names also match the new brand. The Dart package is `owner_waroeng`; Android namespace and the Kotlin package for `MainActivity` are `com.pendodol.ownerwaroeng`, under `android/app/src/main/kotlin/com/pendodol/ownerwaroeng/`. The database filename is `owner_waroeng.db`, the notification channel is `owner_waroeng_alerts`, and the Dart/native feedback channel is `com.pendodol.ownerwaroeng/feedback`. No business data has been stored in the previous installation, so no migration or backward identity compatibility is required. Do not delete existing files, reset databases, or change schema for this rename. Installation docs use `owner_waroeng` for the local clone directory, matching the active workspace. The renamed GitHub repository is `Partykel/owner-waroeng`; its `origin` uses SSH. Git history, IDE history, and generated caches may retain earlier names or workspace paths.

The release APK built after renaming the workspace verifies application ID `com.pendodol.ownerwaroeng`, display label `owner waroeng`, and launch activity `com.pendodol.ownerwaroeng.MainActivity`. The packaged APK no longer contains the previous app name, including in the generated plugin registrant URI. Git history, IDE changelists, ignored caches, and the unchanged GitHub remote URL can still contain earlier names; do not delete caches or rewrite history solely to conceal audit results.

Product assignments are stored in `products.category`; existing products default to an empty string, displayed as `Tanpa kategori`. SQLite schema v4 adds `product_categories` for categories created independently of products, with case-insensitive unique names and the four initial choices. The dashboard's `Tambah kategori` button beside the content-sized filter opens a validated dialog; saved categories persist without products and become available in all product forms. Available choices combine saved categories with categories already assigned to products. The shared add/edit product form serves both Kelola Produk and Beli Stok > Tambah Produk Baru. Owners can type a custom category or select an existing name; blank clears the product's category. Categories are separate from expense types (`stok`, `operasional`, `lainnya`). The dashboard filter applies before the top-three sales limit; `null` means all categories and `''` means uncategorized. Category changes refresh the ranking and use the product's current category, including historical sales. Preserve soft-deleted products in sales history.

The UI uses Forui 0.21.3 with a Material theme bridge in `lib/main.dart` and preset `ajcbfc` adapted in `lib/shared/theme/app_theme.dart`: neutral base, orange accent, Noto Sans headings, bundled Forui Inter body text, Phosphor icons, and medium control radii. Use `phosphor_flutter` icons and shared `AppColors` tokens. Keep existing Material screen flows. The installed CLI does not support `init --preset`; do not overwrite `main.dart` with CLI scaffolding. Newer Forui releases may require a newer Flutter SDK; verify compatibility before upgrading.

## Settings, themes, and backups

`lib/features/settings/` owns `/settings`, theme preference, JSON validation, and backup/restore. The dashboard gear retains all existing shortcuts. Schema v5 adds `app_settings`; `theme` is `classic` (original purple/Material glyphs) or `forui` (orange/Phosphor), defaulting to `forui`. Startup loads the preference before rendering. Use `AppPalette.of(context)` and `AppIcon` for dynamic visuals; global themes live in `lib/shared/theme/app_theme.dart`. Keep Material/Forui TextStyle inherit values consistent to avoid animated text assertions.

Backup format v1 accepts schema v5 only, with identity `com.pendodol.ownerwaroeng`, app version, UTC export time, theme, all five business tables (including soft-deleted products), and AUTOINCREMENT high-water marks. The owner has not stored business data in the previous installation; no identity migration or support for backups from the previous identity is required. Keep backup appVersion in sync with pubspec.yaml. JSON is unencrypted; 20 MiB and 100,000 rows per table are the current limits. Android save/open uses file_picker and the system document picker. Cancel is a no-op; show save success only after the plugin completes writing.

Restore validates the entire document and relationships, then requires explicit UI replacement confirmation. `BackupService.restore` writes and verifies a durable pre-restore JSON snapshot in the private database `recovery/` directory before deleting/inserting within one SQLite transaction, including theme. Failed writes roll back; existing business repositories reject writes during restoration. The settings page can export the latest pre-restore snapshot for recovery; these private snapshots do not survive uninstall. Notifications refresh after commit; a notification failure must not be reported as a failed database restore. Never test destructive restore against the user's live database.

Checks: `flutter test` includes isolated SQLite round trips, migration, validation, mid-restore rollback, recovery-copy failure, narrow-screen theme switching and cancel paths. `flutter run -d emulator-5554 -t tool/verify_backup_android.dart --no-resident` runs the native Android backup check against an in-memory database and new temporary directory; reinstall/run lib/main.dart afterward. Keep Noto Sans OFL bundled and registered with Flutter's license registry.

## Integrity audit safeguards

Repository writes reject non-finite monetary values. Deleting a stock purchase requires enough current stock to reverse every adjustment; otherwise the transaction rolls back and the history row stays visible with an error. Post-commit notification failures must not turn a saved sale/expense into a failed save. History refreshes after saves; low-stock and sold-count providers follow product invalidation. Category lookup keys follow SQLite ASCII NOCASE so distinct non-ASCII category names remain selectable.

Recovery snapshots are written and verified as `.tmp` before renaming to `.json`; recovery selection skips corrupt/unreadable files. Regression checks live in `test/provider_integrity_test.dart`, `test/repository_integrity_test.dart`, `test/history_delete_failure_test.dart`, and `test/backup_service_test.dart`. Repository tests use a fresh temporary SQLite database, never the installed business database.

Normalized text themes must retain `TextBaseline.alphabetic`; Material ListTile requires a baseline even when TextStyle inheritance is disabled. Both themes are covered by the history deletion widget regression.

Resolve Material typography geometry (`typography.englishLike.merge`) before setting TextStyle inherit:false. Retaining only a baseline is insufficient: dense DropdownButton requires a non-null titleMedium.fontSize. Dashboard category tests must use buildAppTheme for both classic and Forui, including the 320px category controls; plain MaterialApp defaults missed the classic dropdown crash.

## UI/UX redesign (Stage 2 approved and implemented)

The owner approved the Stage 1 revision 02 visual direction and instructed Stage 2 implementation on 28 September 2026. `docs/redesign/README.md` documents the accepted design; `preview.html` is the offline prototype. The checkpoint before Stage 2 is local commit `c38a941`, annotated tag `pre-redesign-stage2-20260928`. Do not revert later user changes to return to the prototype.

`lib/app/router.dart` provides four persistent bottom destinations: Beranda, Produk, Riwayat, Laporan. Settings, sale, expense/restock, product edit, low stock, and report detail open above them. `AppPalette`, `buildAppTheme`, `AppIcon`, and shared buttons apply both stored themes. Both use offline Noto Sans. Preserve theme IDs `classic`/`forui`, startup loading, TextStyle geometry/baseline, and minimum 48 logical pixel controls. Widget layout tests use production themes at 320/360/412 logical pixels and 200% text. New navigation must preserve access to Kelola Produk and all business flows.

Dashboard chart lives in `lib/features/dashboard/widgets/income_chart.dart`. Only nonzero native bars rise sequentially at 350 ms each; zero-value days do not consume animation slots. A single nonzero bar starts immediately when the chart enters view, regardless of its day position. The bundled `assets/animations/cuteGirl-spritesheet.png` plays its original 1,930 ms frame cycle once as soon as the highest-value bar completes its own rise; bars to its right keep animating. Its feet align with that bar's top, not inside the bar. Tied highest values choose the rightmost; the selected bar gets the full accent color. Keep the unit label clear of the sprite at narrow widths. Leaving the chart fully resets the sequence; later reentry may replay it. Reduced motion skips the celebration. Do not turn it into a continuous loop. Sale confirmation in `lib/shared/widgets/sale_success_dialog.dart` appears only after a committed sale, with a 180 ms dialog entrance and 420 ms checkmark; failed sales retain selections.

Android click/success tones are bundled under `android/app/src/main/res/raw/` and played by `MainActivity.kt` via `AppFeedback` only when its sound preference is on and Android is neither silent nor backgrounded. `sound` is stored in existing `app_settings`, defaults on, and remains local through JSON backup restore; backup v1 contains theme but no sound preference. Sound errors never change transaction success. Continue using existing backup validation, transaction barriers, and isolated databases for destructive verification.

Report daily cards open daily detail. Monthly cards divide days 1-7, 8-14, 15-21, and 22-end into distinct exact ranges; detail totals, chart, and rows use the selected range. Product edit save stays disabled until load completes; load failure offers retry. Restock steppers have 48 logical pixel touch targets. These were confirmed Stage 1 defects and have focused regressions. Keep transaction, stock, category, soft-delete, and backup rules unchanged.

Real Android screenshot evidence is under `docs/redesign/screenshots/stage2/`. `tool/verify_redesign_android.dart` seeds a separate temporary database path for emulator UI checks; it retains that test dataset between launches for theme persistence. `tool/verify_backup_android.dart` uses an in-memory database and temporary recovery directory. Run `lib/main.dart` after either test target to restore the normal installed entrypoint, without clearing application data. Never test restore on the owner's business database.
