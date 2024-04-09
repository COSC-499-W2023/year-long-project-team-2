import 'package:flutter/cupertino.dart';

/* 
  Use groupedBackgroundColor for the background color of any list views or grouped content.
  Use backgroundColor for the background color of any other content.
*/

const Color groupedBackgroundColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFEEEEEE), // Light grey for light mode
  darkColor: Color(0xFF222222), // Dark grey for dark mode
);

const Color backgroundColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF), // White for light mode
  darkColor: Color(0xFF000000), // Black for dark mode
);

const Color detailsBackgroundColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF), // White for light mode
  darkColor: Color(0xFF222222), // Black for dark mode
);

/* 
  Theme Colours
  Use accentColor for any primary action buttons or links.
  Use secondaryColor for any secondary action buttons or links.
  Use tertiaryColor for any tertiary action buttons or links.
  Use quaternaryColor for any quaternary action buttons or links.
*/

final CupertinoDynamicColor accentColor = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 52, 140, 162),
  darkColor: Color.fromARGB(255, 52, 140, 162),
);

final CupertinoDynamicColor secondaryColor =
    CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 157, 206, 196),
  darkColor: Color.fromARGB(255, 157, 206, 196),
);

final CupertinoDynamicColor tertiaryColor =
    CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 191, 215, 210),
  darkColor: Color.fromARGB(255, 191, 215, 210),
);

final CupertinoDynamicColor quaternaryColor =
    CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 212, 226, 223),
  darkColor: Color.fromARGB(255, 212, 226, 223),
);

/* 
  Complementary colours
  Use complementary colours or any other labels such as tag colours.
*/

final CupertinoDynamicColor yellow = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 249, 207, 84),
  darkColor: Color.fromARGB(255, 249, 207, 84),
);

final CupertinoDynamicColor orange = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 255, 140, 91),
  darkColor: Color.fromARGB(255, 255, 140, 91),
);

final CupertinoDynamicColor blue = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 66, 169, 244),
  darkColor: Color.fromARGB(255, 66, 169, 244),
);

final CupertinoDynamicColor babyPink = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 255, 131, 131),
  darkColor: Color.fromARGB(255, 255, 131, 131),
);

final CupertinoDynamicColor Cyan = CupertinoDynamicColor.withBrightness(
  color: Color.fromARGB(255, 5, 183, 207),
  darkColor: Color.fromARGB(255, 5, 183, 207),
);


/*

  Text Colours

  Use existing cupertino label colours for text colours.

  CupertinoColors.label - Use for text that contains primary content.
  CupertinoColors.secondaryLabel - Use for text that contains secondary content.
  CupertinoColors.tertiaryLabel - Use for text that contains tertiary content.
  CupertinoColors.quaternaryLabel - Use for text that contains quaternary content.

*/


// ranges from 0.0 to 1.0

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}
