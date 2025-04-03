import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler (Koyu Tema)
  static const Color primaryDark = Color(0xFF121212);    // Taste app benzeri koyu arka plan
  static const Color surfaceDark = Color(0xFF1C1C1C);    // Biraz daha açık siyah
  static const Color accentDark = Color(0xFFBFE429);    // Lime yeşili accent (Koyu tema için)
  
  // Metin renkleri (Koyu Tema)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);    // Beyaz
  static const Color textSecondaryDark = Color(0xFFBDBDBD);  // Açık Gri

  // Ana renkler (Açık Tema)
  static const Color primaryLight = Color(0xFFF8F8F2);   // Göz dostu krem-beyaz
  static const Color surfaceLight = Color(0xFFF2F2EC);   // Hafif krem-gri yüzey
  static const Color accentLight = Color(0xFF6C8C03);   // Daha koyu yeşil accent (Açık tema için)

  // Metin renkleri (Açık Tema)
  static const Color textPrimaryLight = Color(0xFF212121);   // Koyu siyah yerine daha yumuşak
  static const Color textSecondaryLight = Color(0xFF757575); // Koyu Gri


  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: primaryDark,
    brightness: Brightness.dark,
    primaryColor: accentDark, // Değişti: accentDark
    fontFamily: 'LeagueSpartan',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      displayMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      displaySmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      headlineLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      headlineMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      headlineSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      titleLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      titleMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryDark),
      titleSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textSecondaryDark), // Belki ikincil renk?
      bodyLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryDark),
      bodyMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryDark),
      bodySmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textSecondaryDark),
      labelLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryDark),
      labelMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryDark),
      labelSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textSecondaryDark),
    ),
    colorScheme: const ColorScheme.dark(
      primary: accentDark, // Değişti: accentDark
      secondary: accentDark, // Genellikle primary ile aynı veya benzer
      surface: surfaceDark,
      background: primaryDark,
      error: Colors.redAccent,
      onPrimary: textPrimaryDark, // Düğme metni vb. için accent üzerinde
      onSecondary: textPrimaryDark,
      onSurface: textPrimaryDark,
      onBackground: textPrimaryDark,
      onError: textPrimaryDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark, // Değişti: surfaceDark (veya primaryDark)
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimaryDark), // AppBar ikon rengi
      titleTextStyle: TextStyle( // AppBar başlık stili
        color: textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'LeagueSpartan',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark, // Değişti: surfaceDark (veya primaryDark)
      selectedItemColor: accentDark, // Değişti: accentDark
      unselectedItemColor: textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      surfaceTintColor: Colors.transparent, // Ekstra gölgeyi kaldır
    ),
    listTileTheme: const ListTileThemeData( // ListTile için genel tema
      iconColor: textSecondaryDark,
      textColor: textPrimaryDark,
      tileColor: primaryDark, // Arka plan rengi
    ),
    inputDecorationTheme: InputDecorationTheme( // Genel InputDecoration teması
       fillColor: surfaceDark, // Input field arka planı
       filled: true,
       hintStyle: const TextStyle(color: textSecondaryDark),
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(10.0),
         borderSide: BorderSide.none,
       ),
       focusedBorder: OutlineInputBorder( // Odaklanıldığında çerçeve
         borderRadius: BorderRadius.circular(10.0),
         borderSide: const BorderSide(color: accentDark, width: 1.5),
       ),
       enabledBorder: OutlineInputBorder( // Etkin durumda çerçeve (opsiyonel)
         borderRadius: BorderRadius.circular(10.0),
         borderSide: BorderSide.none,
       ),
       prefixIconColor: textSecondaryDark, // İkon rengi
       contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
    iconTheme: const IconThemeData( // Genel ikon teması
      color: textSecondaryDark,
    ),
    textButtonTheme: TextButtonThemeData( // TextButton Teması
      style: TextButton.styleFrom(
        foregroundColor: accentDark, // Metin rengi
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData( // ElevatedButton Teması
       style: ElevatedButton.styleFrom(
         backgroundColor: accentDark, // Arka plan rengi
         foregroundColor: textPrimaryDark, // Metin rengi
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(10.0),
         ),
         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
         textStyle: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.w700,
            fontSize: 16,
         )
       ),
    ),
    snackBarTheme: const SnackBarThemeData( // SnackBar teması
        backgroundColor: surfaceDark,
        contentTextStyle: TextStyle(color: textPrimaryDark),
        actionTextColor: accentDark,
    ),
     // Diğer widget temalarını buraya ekleyebilirsiniz (örn: sliderTheme, dialogTheme vb.)
  );

  // ----------- AÇIK TEMA -----------
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: primaryLight,
    brightness: Brightness.light,
    primaryColor: accentLight, // Değişti: accentLight
    fontFamily: 'LeagueSpartan',
     textTheme: const TextTheme(
       displayLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       displayMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       displaySmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       headlineLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       headlineMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       headlineSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       titleLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       titleMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w700, color: textPrimaryLight),
       titleSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textSecondaryLight),
       bodyLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryLight),
       bodyMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryLight),
       bodySmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textSecondaryLight),
       labelLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryLight),
       labelMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textPrimaryLight),
       labelSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.w400, color: textSecondaryLight),
    ),
    colorScheme: const ColorScheme.light(
      primary: accentLight, // Değişti: accentLight
      secondary: accentLight,
      surface: surfaceLight,
      background: primaryLight,
      error: Colors.red,
      onPrimary: Colors.white, 
      onSecondary: Colors.white,
      onSurface: textPrimaryLight,
      onBackground: textPrimaryLight,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: accentLight,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'LeagueSpartan',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryLight, // Saf beyaz yerine, krem-beyaz tema rengi
      selectedItemColor: accentLight,
      unselectedItemColor: textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardTheme(
      color: surfaceLight, // Saf beyaz yerine hafif krem-gri
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 0.5)
      ),
      surfaceTintColor: Colors.transparent,
    ),
     listTileTheme: const ListTileThemeData(
      iconColor: accentLight,
      textColor: textPrimaryLight,
      tileColor: primaryLight, // Saf beyaz yerine krem-beyaz
    ),
    inputDecorationTheme: InputDecorationTheme(
       fillColor: surfaceLight, // Saf beyaz yerine hafif krem-gri
       filled: true,
       hintStyle: const TextStyle(color: textSecondaryLight),
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(10.0),
         borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
       ),
       focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(10.0),
         borderSide: const BorderSide(color: accentLight, width: 1.5),
       ),
       enabledBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(10.0),
         borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
       ),
       prefixIconColor: accentLight,
       contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
     iconTheme: const IconThemeData(
      color: accentLight,
    ),
     textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
       style: ElevatedButton.styleFrom(
         backgroundColor: accentLight,
         foregroundColor: Colors.white,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(10.0),
         ),
         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.w700,
            fontSize: 16,
         )
       ),
    ),
    snackBarTheme: SnackBarThemeData( // SnackBar teması (Açık)
        backgroundColor: surfaceLight,
        contentTextStyle: TextStyle(color: textPrimaryLight),
        actionTextColor: accentLight,
        shape: RoundedRectangleBorder( // Kenarlık ekleyebiliriz
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Colors.grey.shade300, width: 1)),
        elevation: 1,
    ),
    // Diğer widget temalarını buraya ekleyebilirsiniz
  );


  // Custom Input Decoration (Her iki tema için de kullanılabilir veya özelleştirilebilir)
  static InputDecoration searchInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textSecondaryDark),
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: textSecondaryDark)
          : null,
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
} 