# Repository Guidelines

## Project Structure & Module Organization

owner waroeng (formerly Ghepek.in) is an offline Flutter cashier and inventory app for culinary businesses. The app was renamed starting with version `1.1.0+2`, developed on branch `version-1.1`. `lib/main.dart` initializes notifications and Indonesian date formatting; `lib/app/router.dart` defines navigation.

Keep this `AGENTS.md` updated whenever project context, conventions, structure, or development workflows change.

Follow Ponytail full for implementation: reuse existing flows and dependencies, make the smallest complete change, and verify behavior. Following these instructions does not establish that the plugin's automatic hooks are healthy.

- `lib/features/`: product, transaction, dashboard, and report features; keep screens, models, providers, and repositories within their feature where applicable.
- `lib/core/`: SQLite setup and migrations, notification services, and formatting utilities.
- `lib/shared/`: reusable widgets and visual constants.
- `test/`: unit tests and widget tests, including the application smoke test.
- `android/`: Android configuration and native resources under `app/src/main/res/`. Offline Noto Sans fonts and their license are bundled under `assets/fonts/noto_sans/`.

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

Use `AppStrings.appName` for the display name in Flutter and keep the Android manifest label in sync as `owner waroeng`. Retain the internal Dart package `ghepek_in`, Android application ID `com.ghepek_in`, database filename `ghepek_in.db`, and notification channel ID `ghepek_in_alerts` so branding changes preserve installation and data continuity.

Product assignments are stored in `products.category`; existing products default to an empty string, displayed as `Tanpa kategori`. SQLite schema v4 adds `product_categories` for categories created independently of products, with case-insensitive unique names and the four initial choices. The dashboard's `Tambah kategori` button beside the content-sized filter opens a validated dialog; saved categories persist without products and become available in all product forms. Available choices combine saved categories with categories already assigned to products. The shared add/edit product form serves both Kelola Produk and Beli Stok > Tambah Produk Baru. Owners can type a custom category or select an existing name; blank clears the product's category. Categories are separate from expense types (`stok`, `operasional`, `lainnya`). The dashboard filter applies before the top-three sales limit; `null` means all categories and `''` means uncategorized. Category changes refresh the ranking and use the product's current category, including historical sales. Preserve soft-deleted products in sales history.

The UI uses Forui 0.21.3 with a Material theme bridge in `lib/main.dart` and preset `ajcbfc` adapted in `lib/shared/theme/app_theme.dart`: neutral base, orange accent, Noto Sans headings, bundled Forui Inter body text, Phosphor icons, and medium control radii. Use `phosphor_flutter` icons and shared `AppColors` tokens. Keep existing Material screen flows. The installed CLI does not support `init --preset`; do not overwrite `main.dart` with CLI scaffolding. Newer Forui releases may require a newer Flutter SDK; verify compatibility before upgrading.

## Settings, themes, and backups

`lib/features/settings/` owns `/settings`, theme preference, JSON validation, and backup/restore. The dashboard gear retains all existing shortcuts. Schema v5 adds `app_settings`; `theme` is `classic` (original purple/Material glyphs) or `forui` (orange/Phosphor), defaulting to `forui`. Startup loads the preference before rendering. Use `AppPalette.of(context)` and `AppIcon` for dynamic visuals; global themes live in `lib/shared/theme/app_theme.dart`. Keep Material/Forui TextStyle inherit values consistent to avoid animated text assertions.

Backup format v1 accepts schema v5 only, with identity `com.ghepek_in`, app version, UTC export time, theme, all five business tables (including soft-deleted products), and AUTOINCREMENT high-water marks. Keep backup appVersion in sync with pubspec.yaml. JSON is unencrypted; 20 MiB and 100,000 rows per table are the current limits. Android save/open uses file_picker and the system document picker. Cancel is a no-op; show save success only after the plugin completes writing.

Restore validates the entire document and relationships, then requires explicit UI replacement confirmation. `BackupService.restore` writes and verifies a durable pre-restore JSON snapshot in the private database `recovery/` directory before deleting/inserting within one SQLite transaction, including theme. Failed writes roll back; existing business repositories reject writes during restoration. The settings page can export the latest pre-restore snapshot for recovery; these private snapshots do not survive uninstall. Notifications refresh after commit; a notification failure must not be reported as a failed database restore. Never test destructive restore against the user's live database.

Checks: `flutter test` includes isolated SQLite round trips, migration, validation, mid-restore rollback, recovery-copy failure, narrow-screen theme switching and cancel paths. `flutter run -d emulator-5554 -t tool/verify_backup_android.dart --no-resident` runs the native Android backup check against an in-memory database and new temporary directory; reinstall/run lib/main.dart afterward. Keep Noto Sans OFL bundled and registered with Flutter's license registry.

## Integrity audit safeguards

Repository writes reject non-finite monetary values. Deleting a stock purchase requires enough current stock to reverse every adjustment; otherwise the transaction rolls back and the history row stays visible with an error. Post-commit notification failures must not turn a saved sale/expense into a failed save. History refreshes after saves; low-stock and sold-count providers follow product invalidation. Category lookup keys follow SQLite ASCII NOCASE so distinct non-ASCII category names remain selectable.

Recovery snapshots are written and verified as `.tmp` before renaming to `.json`; recovery selection skips corrupt/unreadable files. Regression checks live in `test/provider_integrity_test.dart`, `test/repository_integrity_test.dart`, `test/history_delete_failure_test.dart`, and `test/backup_service_test.dart`. Repository tests use a fresh temporary SQLite database, never the installed business database.

Normalized text themes must retain `TextBaseline.alphabetic`; Material ListTile requires a baseline even when TextStyle inheritance is disabled. Both themes are covered by the history deletion widget regression.

Resolve Material typography geometry (`typography.englishLike.merge`) before setting TextStyle inherit:false. Retaining only a baseline is insufficient: dense DropdownButton requires a non-null titleMedium.fontSize. Dashboard category tests must use buildAppTheme for both classic and Forui, including the 320px category controls; plain MaterialApp defaults missed the classic dropdown crash.

## UI/UX redesign proposal (pending approval)

Stage 1 revision 02 lives in `docs/redesign/README.md` and `docs/redesign/preview.html`; `preview-v1.html` and `README-v1.md` preserve the superseded proposal for comparison. The user chose a premium finance-like visual direction, clear surfaces/contrast, subtle interactive feedback, soft button clicks plus a success tone, and four bottom destinations (Beranda, Produk, Riwayat, Laporan). Both classic purple and Forui orange remain. This is a revision of the prototype only; approval to apply the final visual direction throughout Flutter is still pending. Do not infer that approval from instructions to apply the Stage 1 revision plan.

The offline prototype uses fictional data, local Noto Sans, schematic SVG icons, and synthesized Web Audio; it does not access business data. Settings has working theme choices and a sound switch; preferences are session-only in the prototype. Production sound preference/persistence and Android silent-mode behavior must be verified during the approved settings slice. No Flaticon assets or new dependencies were added. `preview-*-v2.png` are browser screenshots; `current-*` are the previously installed Android app.

Run `python docs/redesign/check_preview.py` and `node docs/redesign/check_interactions.cjs` for prototype checks. `preview-v2-layout-checks.json` records 18 browser panel combinations; it is not Flutter verification. Preserve AppIcon, offline fonts, production typography fixes, routes/repositories, and all data safeguards. Update the design documentation with every accepted revision.

Stage 1 identified a report navigation mismatch: monthly week cards currently pass the same monthly period/date; daily cards inside the weekly tab retain the weekly period. Record this as an unresolved UI routing bug, not as a fixed report calculation. Restock quantity targets are currently 38x38. Address confirmed defects with focused regression tests during the relevant approved implementation slice. Flutter verification must use production themes at 320/360/412 and large text; HTML measurements do not replace it.

Stage 1 preview additionally shows a seven-day income bar chart with day/value labels and an animated success dialog (180 ms entrance, 420 ms checkmark) after successful simulated sale saves only. Reduced motion keeps the static confirmation. `check_interactions.cjs` covers failure exclusion and repeat success; production must trigger this feedback only after database commit.

Stage 1 bar chart uses native IntersectionObserver (35% visibility) and sequential left-to-right bottom-up CSS animations (350 ms per bar, delays 0-2100 ms; 2450 ms total). Reset only after full exit to avoid scroll jitter; reduced motion disables animation, and unsupported observers leave the chart static.

Stage 1 chart celebration reuses the supplied cuteGirl spritesheet and original frame timing, plays one cycle after each rightmost bar animationend, then hides; full chart exit cancels any active celebration. The character stands on the rightmost bar cap; the jump uses the space to the right of the caption without full-width top padding, and values sit below day labels to avoid overlap. Reduced motion skips the character. There is no app-launch limit; every completed chart animation may trigger the celebration.
