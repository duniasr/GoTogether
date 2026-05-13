import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import '../l10n/app_localizations.dart';

String translateCategory(String cat) {
  final Map<String, String> categoryToKey = {
    'All': 'all',
    'Todos': 'all',
    'Deporte': 'sports',
    'Naturaleza': 'nature',
    'Estudio': 'study',
    'Ocio': 'leisure',
    'Cultura': 'culture',
    'Gastronomía': 'food',
    'Fiesta': 'party',
    'Voluntariado': 'volunteer',
    'Viajes': 'travel',
    'Videojuegos': 'games',
    'Música': 'music',
    'Networking': 'networking',
    'Otros': 'others',
    'Other': 'others',
  };

  final key = categoryToKey[cat] ?? cat.toLowerCase();
  return AppLocalizations.get(key);
}

String translateStatus(String status) {
  final Map<String, String> statusToKey = {
    'abierta': 'open',
    'cerrada': 'closed',
    'cancelada': 'cancelled',
  };
  
  final key = statusToKey[status] ?? status.toLowerCase();
  return AppLocalizations.get(key);
}

final GoogleTranslator _translator = GoogleTranslator();
final Map<String, String> _translationCache = {};

String _capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

Future<String> translateDynamicAsync(String text) async {
  final lang = AppLocalizations.localeNotifier.value.languageCode;
  if (text.trim().isEmpty) return text;
  
  final cacheKey = '${lang}_$text';
  if (_translationCache.containsKey(cacheKey)) {
    return _translationCache[cacheKey]!;
  }
  
  try {
    final translation = await _translator.translate(text, to: lang);
    final result = _capitalizeFirstLetter(translation.text);
    _translationCache[cacheKey] = result;
    return result;
  } catch (e) {
    return text;
  }
}

String translateDynamic(String text) {
  final lang = AppLocalizations.localeNotifier.value.languageCode;
  if (text.trim().isEmpty) return text;
  
  final cacheKey = '${lang}_$text';
  if (_translationCache.containsKey(cacheKey)) {
    return _translationCache[cacheKey]!;
  }
  
  // Fire and forget, useful for dialogs when text is already fetching
  translateDynamicAsync(text);
  return text;
}

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const TranslatedText(this.text, {super.key, this.style, this.maxLines, this.overflow, this.textAlign});

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  String _currentLang = '';

  @override
  void initState() {
    super.initState();
    _translatedText = widget.text;
    _currentLang = AppLocalizations.localeNotifier.value.languageCode;
    _loadTranslation();
    AppLocalizations.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translatedText = widget.text;
      _loadTranslation();
    }
  }

  @override
  void dispose() {
    AppLocalizations.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (_currentLang != AppLocalizations.localeNotifier.value.languageCode) {
      _currentLang = AppLocalizations.localeNotifier.value.languageCode;
      _loadTranslation();
    }
  }

  Future<void> _loadTranslation() async {
    final translated = await translateDynamicAsync(widget.text);
    if (mounted) {
      setState(() {
        _translatedText = translated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
