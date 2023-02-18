import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Shadow11 = Color(0xff001787);
  static const Shadow10 = Color(0xff00119e);
  static const Shadow9 = Color(0xff0009b3);
  static const Shadow8 = Color(0xff0200c7);
  static const Shadow7 = Color(0xff0e00d7);
  static const Shadow6 = Color(0xff2a13e4);
  static const Shadow5 = Color(0xff4b30ed);
  static const Shadow4 = Color(0xff7057f5);
  static const Shadow3 = Color(0xff9b86fa);
  static const Shadow2 = Color(0xffc8bbfd);
  static const Shadow1 = Color(0xffded6fe);
  static const Shadow0 = Color(0xfff4f2ff);

  static const Ocean11 = Color(0xff005687);
  static const Ocean10 = Color(0xff006d9e);
  static const Ocean9 = Color(0xff0087b3);
  static const Ocean8 = Color(0xff00a1c7);
  static const Ocean7 = Color(0xff00b9d7);
  static const Ocean6 = Color(0xff13d0e4);
  static const Ocean5 = Color(0xff30e2ed);
  static const Ocean4 = Color(0xff57eff5);
  static const Ocean3 = Color(0xff86f7fa);
  static const Ocean2 = Color(0xffbbfdfd);
  static const Ocean1 = Color(0xffd6fefe);
  static const Ocean0 = Color(0xfff2ffff);

  static const Lavender11 = Color(0xff170085);
  static const Lavender10 = Color(0xff23009e);
  static const Lavender9 = Color(0xff3300b3);
  static const Lavender8 = Color(0xff4400c7);
  static const Lavender7 = Color(0xff5500d7);
  static const Lavender6 = Color(0xff6f13e4);
  static const Lavender5 = Color(0xff8a30ed);
  static const Lavender4 = Color(0xffa557f5);
  static const Lavender3 = Color(0xffc186fa);
  static const Lavender2 = Color(0xffdebbfd);
  static const Lavender1 = Color(0xffebd6fe);
  static const Lavender0 = Color(0xfff9f2ff);

  static const Rose11 = Color(0xff7f0054);
  static const Rose10 = Color(0xff97005c);
  static const Rose9 = Color(0xffaf0060);
  static const Rose8 = Color(0xffc30060);
  static const Rose7 = Color(0xffd4005d);
  static const Rose6 = Color(0xffe21365);
  static const Rose5 = Color(0xffec3074);
  static const Rose4 = Color(0xfff4568b);
  static const Rose3 = Color(0xfff985aa);
  static const Rose2 = Color(0xfffdbbcf);
  static const Rose1 = Color(0xfffed6e2);
  static const Rose0 = Color(0xfffff2f6);

  static const Neutral8 = Color(0xff121212);
  static const Neutral7 = Color(0xde000000);
  static const Neutral6 = Color(0x99000000);
  static const Neutral5 = Color(0x61000000);
  static const Neutral4 = Color(0x1f000000);
  static const Neutral3 = Color(0x1fffffff);
  static const Neutral2 = Color(0x61ffffff);
  static const Neutral1 = Color(0xbdffffff);
  static const Neutral0 = Color(0xffffffff);

  static const gold1 = Color(0xffFFCC00);
  static const gold2 = Color(0xffFF5C00);
  static const btNetplay = Color(0xff6188FF);

  static const Color notWhite = Color(0xFFEDF0F2);
  static const Color nearlyWhite = Color(0xFFFEFEFE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Colors.black;
  static const Color nearlyBlack = Color(0xFF213333);
  static const Color grey = Color(0xFF3A5160);
  static const Color dark_grey = Color(0xFF313A44);
  static const Color nearlyDarkBlue = Color(0xFF2633C5);

  static const Color darkText = Color(0xFF253840);
  static const Color darkerText = Color(0xFF17262A);
  static const Color lightText = Color(0xFF4A6572);
  static const Color deactivatedText = Color(0xFF767676);
  static const Color dismissibleBackground = Color(0xFF364A54);
  static const Color chipBackground = Color(0xFFEEF1F3);
  static const Color spacer = Color(0xFFF2F2F2);
  static const String fontName = 'lato';

  static const Color mainText = Color(0xFFE8EAED);
  static const Color secondText = Color(0xFF9AA0A6);
  static const Color surface1 = Color(0xFF1e1e1e);

  static const Color primary = const Color(0xFF4caf50);
  static const Color primaryContainer = const Color(0xFF087f23);
  static const Color secondary = const Color(0xFFf44336);
  static const Color secondaryContainer = const Color(0xFFba000d);
  static const Color surface = const Color(0xFF121212);
  static const Color background = const Color(0xFF121212);
  static const Color error = const Color(0xFFCF6679);
  static const Color onPrimary = Colors.black;
  static const Color onSecondary = Colors.black;
  static const Color onSurface = Colors.white;
  static const Color onBackground = Colors.white;
  static const Color onError = Colors.black;

  static ColorScheme darkColorScheme = ColorScheme(
    primary: primary,
    primaryContainer: primaryContainer,
    secondary: secondary,
    secondaryContainer: secondaryContainer,
    surface: surface,
    background: background,
    error: error,
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    onSurface: onSurface,
    onBackground: onBackground,
    onError: onError,
    brightness: Brightness.dark,
  );

  static ThemeData darkTheme = ThemeData.from(colorScheme: darkColorScheme);

  static const TextTheme textTheme = TextTheme(
    headline4: display1,
    headline5: headline,
    headline6: title,
    subtitle2: subtitle,
    bodyText2: body2,
    bodyText1: body1,
    caption: caption,
  );

  static const TextStyle display1 = TextStyle(
    // h4 -> display1
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 36,
    letterSpacing: 0.4,
    height: 0.9,
    color: darkerText,
  );

  static const TextStyle headline = TextStyle(
    // h5 -> headline
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.27,
    color: darkerText,
  );

  static const TextStyle title = TextStyle(
    // h6 -> title
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 0.18,
    color: darkerText,
  );

  static const TextStyle subtitle = TextStyle(
    // subtitle2 -> subtitle
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.04,
    color: darkText,
  );

  static const TextStyle body2 = TextStyle(
    // body1 -> body2
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.2,
    color: darkText,
  );

  static const TextStyle body1 = TextStyle(
    // body2 -> body1
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.05,
    color: darkText,
  );

  static const TextStyle caption = TextStyle(
    // Caption -> caption
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
    color: lightText, // was lightText
  );
}
