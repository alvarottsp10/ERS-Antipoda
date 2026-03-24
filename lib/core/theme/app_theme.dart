import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const backgroundGrey = Color(0xFFF4F5F7);
  static const surfaceGrey = Color(0xFFE7E7E7);
  static const borderGrey = Color(0xFFC9C9C9);
  static const underlineDark = Color(0xFF7A7A7A);
  static const textDark = Color(0xFF2B2B2B);
  static const accentRed = Color(0xFFB1121D);

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: accentRed,
      onPrimary: Colors.white,
      secondary: accentRed,
      onSecondary: Colors.white,
      surface: surfaceGrey,
      onSurface: textDark,
      error: accentRed,
      onError: Colors.white,
      outline: borderGrey,
    );

    const underlineBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: underlineDark),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundGrey,
      canvasColor: surfaceGrey,
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentRed,
        selectionColor: Color(0x33B1121D),
        selectionHandleColor: accentRed,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        labelStyle: TextStyle(color: textDark),
        floatingLabelStyle: TextStyle(color: accentRed),
        prefixIconColor: textDark,
        suffixIconColor: textDark,
        border: underlineBorder,
        enabledBorder: underlineBorder,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accentRed, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accentRed),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accentRed, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceGrey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderGrey),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: surfaceGrey,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: textDark,
        dividerColor: borderGrey,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceGrey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderGrey),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: underlineBorder,
          enabledBorder: underlineBorder,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: accentRed, width: 1.5),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceGrey),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceGrey),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      iconTheme: const IconThemeData(color: textDark),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentRed,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentRed,
          side: const BorderSide(color: accentRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerColor: borderGrey,
    );
  }
}
