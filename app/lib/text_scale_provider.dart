// text_scale_provider.dart
import 'package:flutter/cupertino.dart';

class TextScaleProvider extends ChangeNotifier {
  double _textScaleFactor = 1.0;

  double get textScaleFactor => _textScaleFactor;

  set textScaleFactor(double value) {
    _textScaleFactor = value;
    notifyListeners();
  }
}
