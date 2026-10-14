// =============================================================================
// APP THEME (fabbrica) — Metodo Villa · skill seeding-visivo-mobile
// -----------------------------------------------------------------------------
// La "fabbrica" del tema: data una palette (un set di token colore), produce i
// due ThemeData (chiaro e scuro). Tutti i preset (default, outdoor, ...) sono
// istanze di AppPalette: hanno percio' lo STESSO SET DI TOKEN e differiscono
// SOLO nei valori. E' il gemello mobile dello skin CSS web (skin-*.css).
//
// COME SI USA: copiare questo file + un file palette (palette-default.dart o
// palette-outdoor.dart) + tokens.dart in `lib/theme/` del progetto, poi:
//   MaterialApp(
//     theme:      AppTheme.light(kDefaultPalette),
//     darkTheme:  AppTheme.dark(kDefaultPalette),
//     themeMode:  ThemeMode.system,
//   )
//
// CORREZIONI DAL VIVO applicate qui (vedi 18-design-mobile.md sez. 2.2 e 3):
//   - UN solo accento: il FAB e le azioni primarie usano `primary`, MAI un
//     secondo colore. `tertiary` esiste ma e' di supporto, con parsimonia.
//   - I *Container sono versioni TENUI dell'accento (~10% alpha), non colori
//     pieni saturi.
//   - I colori di stato (success/warning/info) vivono in AppStatusColors e si
//     usano a sfondo tenue + bordo, mai a blocco pieno.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Set di token colore di un preset (skin). Ogni token ha la variante chiara e
/// scura. Tutti i preset sono `AppPalette`: stesso set di token, valori diversi.
@immutable
class AppPalette {
  const AppPalette({
    required this.name,
    // Accento unico (azioni, FAB, voce attiva).
    required this.primaryLight,
    required this.primaryDark,
    required this.onPrimaryLight,
    required this.onPrimaryDark,
    // Colore di supporto: parsimonia, MAI secondo bottone d'azione concorrente.
    required this.tertiaryLight,
    required this.tertiaryDark,
    // Superfici: sfondo schermata + superficie di card/fogli.
    required this.backgroundLight,
    required this.backgroundDark,
    required this.surfaceLight,
    required this.surfaceDark,
    // Testo: alto (principale) e medio (secondario, leggibile non sbiadito).
    required this.onSurfaceLight,
    required this.onSurfaceDark,
    required this.onSurfaceVariantLight,
    required this.onSurfaceVariantDark,
    // Severita' (severity coding).
    required this.errorLight,
    required this.errorDark,
    required this.successLight,
    required this.successDark,
    required this.warningLight,
    required this.warningDark,
    required this.infoLight,
    required this.infoDark,
    // Bordi/divisori.
    required this.outlineLight,
    required this.outlineDark,
  });

  final String name;

  final Color primaryLight;
  final Color primaryDark;
  final Color onPrimaryLight;
  final Color onPrimaryDark;

  final Color tertiaryLight;
  final Color tertiaryDark;

  final Color backgroundLight;
  final Color backgroundDark;
  final Color surfaceLight;
  final Color surfaceDark;

  final Color onSurfaceLight;
  final Color onSurfaceDark;
  final Color onSurfaceVariantLight;
  final Color onSurfaceVariantDark;

  final Color errorLight;
  final Color errorDark;
  final Color successLight;
  final Color successDark;
  final Color warningLight;
  final Color warningDark;
  final Color infoLight;
  final Color infoDark;

  final Color outlineLight;
  final Color outlineDark;
}

/// Le severita' del severity coding (vedi 16-design-core.md, principio 3).
enum Severity { error, warning, success, info, neutral }

/// Colori di stato esposti come estensione del tema (success/warning/info non
/// esistono nel ColorScheme standard di Material: li aggiungiamo qui, cosi' i
/// widget li leggono SEMPRE dal tema, mai a mano).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  /// Risolve una severita' nel colore giusto (error viene dal ColorScheme).
  Color resolve(Severity s, ColorScheme scheme) {
    switch (s) {
      case Severity.error:
        return scheme.error;
      case Severity.warning:
        return warning;
      case Severity.success:
        return success;
      case Severity.info:
        return info;
      case Severity.neutral:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  AppStatusColors copyWith({Color? success, Color? warning, Color? info}) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// La fabbrica del tema. `AppTheme.light(palette)` / `AppTheme.dark(palette)`.
class AppTheme {
  AppTheme._();

  static ThemeData light(AppPalette p) => _build(p, Brightness.light);
  static ThemeData dark(AppPalette p) => _build(p, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness b) {
    final bool isLight = b == Brightness.light;

    final Color primary = isLight ? p.primaryLight : p.primaryDark;
    final Color onPrimary = isLight ? p.onPrimaryLight : p.onPrimaryDark;
    final Color tertiary = isLight ? p.tertiaryLight : p.tertiaryDark;
    final Color background = isLight ? p.backgroundLight : p.backgroundDark;
    final Color surface = isLight ? p.surfaceLight : p.surfaceDark;
    final Color onSurface = isLight ? p.onSurfaceLight : p.onSurfaceDark;
    final Color onSurfaceVariant =
        isLight ? p.onSurfaceVariantLight : p.onSurfaceVariantDark;
    final Color error = isLight ? p.errorLight : p.errorDark;
    final Color outline = isLight ? p.outlineLight : p.outlineDark;

    // Partiamo da uno schema armonico generato dall'accento, poi forziamo i
    // token che vogliamo controllare (M3-friendly, niente campi mancanti).
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: b,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      // Container TENUE dell'accento, non un secondo colore pieno.
      primaryContainer: primary.withValues(alpha: 0.12),
      onPrimaryContainer: primary,
      tertiary: tertiary,
      error: error,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
    );

    final AppStatusColors status = AppStatusColors(
      success: isLight ? p.successLight : p.successDark,
      warning: isLight ? p.warningLight : p.warningDark,
      info: isLight ? p.infoLight : p.infoDark,
    );

    final TextTheme textTheme = _buildTextTheme(onSurface, onSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: <ThemeExtension<dynamic>>[status],
      textTheme: textTheme,

      // Barra superiore: piatta, ombra solo allo scroll.
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.low,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      // Card: elevazione bassa, raggio standard.
      cardTheme: CardThemeData(
        color: surface,
        elevation: AppElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      // Navigazione inferiore: voce attiva sul primary, tipo fisso.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.high,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
      ),

      // FAB: USA IL PRIMARY (un solo accento), mai un secondo colore.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: AppElevation.medium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      // Bottoni: bersaglio >= 48dp, raggio sobrio.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: AppElevation.low,
          minimumSize: const Size(
            AppTouchTarget.minimum,
            AppTouchTarget.minimum,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(
            AppTouchTarget.minimum,
            AppTouchTarget.minimum,
          ),
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(
            AppTouchTarget.minimum,
            AppTouchTarget.minimum,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Campi di testo: contorno tenue, focus nell'accento.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
      ),

      // Chip: superficie tenue, raggio piccolo.
      chipTheme: ChipThemeData(
        backgroundColor: primary.withValues(alpha: 0.10),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // Foglio inferiore: angoli alti arrotondati, elevazione alta.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: AppElevation.high,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // Finestra di dialogo.
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: AppElevation.high,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Snackbar: flottante.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        actionTextColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      dividerTheme: DividerThemeData(color: outline, thickness: 1),

      // Gli altri sotto-temi (switch/checkbox/radio/slider/tab/tooltip/progress)
      // seguono lo stesso schema: colori dal `scheme`, misure dai token.
    );
  }

  /// Scala tipografica a ruoli, costruita con Inter via google_fonts.
  /// I numeri/dati usano un carattere monospazio: vedi `dataTextStyle`.
  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    final TextTheme base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      displayMedium: base.displayMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      displaySmall: base.displaySmall?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: onSurface),
      bodySmall: base.bodySmall?.copyWith(color: onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(color: onSurfaceVariant),
    );
  }

  /// Stile per i DATI numerici che si confrontano (importi, misure, codici):
  /// carattere monospazio, cosi' le cifre restano allineate. Gemello di
  /// `tabular-nums` del web. Uso: `Text(value, style: AppTheme.dataTextStyle(context))`.
  static TextStyle dataTextStyle(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.onSurface;
    return GoogleFonts.robotoMono(color: color, fontWeight: FontWeight.w500);
  }
}
