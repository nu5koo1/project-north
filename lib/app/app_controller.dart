import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/storage/app_preferences_storage.dart';

class AppController extends ChangeNotifier {
  AppController(this._preferencesStorage);

  static const Locale englishLocale = Locale('en');
  static const Locale norwegianBokmalLocale = Locale('nb');

  final AppPreferencesStorage _preferencesStorage;

  Locale _locale = englishLocale;
  bool _isInitialized = false;

  Locale get locale => _locale;

  bool get isInitialized => _isInitialized;

  bool get isEnglish {
    return _locale.languageCode == englishLocale.languageCode;
  }

  bool get isNorwegianBokmal {
    return _locale.languageCode == norwegianBokmalLocale.languageCode;
  }

  Future<void> initialize() async {
    final savedLanguageCode = await _preferencesStorage.loadLanguageCode();

    if (savedLanguageCode != null) {
      _locale = _localeFromLanguageCode(savedLanguageCode);
    } else {
      _locale = _localeFromPlatform(PlatformDispatcher.instance.locale);
    }

    _isInitialized = true;
  }

  Future<void> setLocale(Locale locale) async {
    final supportedLocale = _localeFromLanguageCode(locale.languageCode);

    if (_locale == supportedLocale) {
      return;
    }

    final previousLocale = _locale;

    _locale = supportedLocale;
    notifyListeners();

    try {
      await _preferencesStorage.saveLanguageCode(supportedLocale.languageCode);
    } catch (_) {
      _locale = previousLocale;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> useEnglish() async {
    await setLocale(englishLocale);
  }

  Future<void> useNorwegianBokmal() async {
    await setLocale(norwegianBokmalLocale);
  }

  Locale _localeFromPlatform(Locale platformLocale) {
    return _localeFromLanguageCode(platformLocale.languageCode);
  }

  Locale _localeFromLanguageCode(String languageCode) {
    final normalizedLanguageCode = languageCode.trim().toLowerCase();

    if (normalizedLanguageCode == 'nb' ||
        normalizedLanguageCode == 'no' ||
        normalizedLanguageCode == 'nn') {
      return norwegianBokmalLocale;
    }

    return englishLocale;
  }
}
