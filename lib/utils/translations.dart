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

// Helper to mock translation for dynamic content (titles/descriptions)
String translateDynamic(String text) {
  final lang = AppLocalizations.localeNotifier.value.languageCode;
  if (lang == 'es') return text;
  
  // Very basic mock translation for demonstration
  final mocks = {
    'Partido de Fútbol': 'Football Match',
    'Senderismo por el Teide': 'Hiking through Teide',
    'Estudiar para el examen': 'Study for the exam',
    'Cena en el centro': 'Dinner downtown',
    'Visita al museo': 'Museum visit',
    'Fiesta de disfraces': 'Costume party',
    'Limpieza de playa': 'Beach cleanup',
    'Viaje a la nieve': 'Trip to the snow',
    'Torneo de Valorant': 'Valorant tournament',
    'Concierto de Rock': 'Rock concert',
    'Charla sobre IA': 'Talk about AI',
    'Intercambio de idiomas': 'Language exchange',
    'Tarde de juegos de mesa': 'Board games afternoon',
    'Clase de Yoga': 'Yoga Class',
    'Taller de cocina': 'Cooking Workshop',
    'Salida en bici': 'Bike ride',
    'Barbacoa en el campo': 'Country BBQ',
    'Ruta de tapas': 'Tapas route',
  };
  
  return mocks[text] ?? text;
}
