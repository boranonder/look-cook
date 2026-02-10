import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('tr');

  Locale get currentLocale => _currentLocale;

  void changeLanguage(String languageCode) {
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  bool get isTurkish => _currentLocale.languageCode == 'tr';
  bool get isEnglish => _currentLocale.languageCode == 'en';
}