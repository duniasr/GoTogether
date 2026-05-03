const Map<String, String> categoryTranslations = {
  'Todos': 'All',
  'All': 'All',
  'Deporte': 'Sports',
  'Naturaleza': 'Nature',
  'Estudio': 'Study',
  'Ocio': 'Leisure',
  'Cultura': 'Culture',
  'Gastronomía': 'Gastronomy',
  'Fiesta': 'Party',
  'Voluntariado': 'Volunteering',
  'Viajes': 'Travel',
  'Videojuegos': 'Videogames',
  'Música': 'Music',
  'Networking': 'Networking',
  'Otros': 'Other',
  'Other': 'Other',
};

const Map<String, String> statusTranslations = {
  'abierta': 'Open',
  'cerrada': 'Closed',
  'cancelada': 'Cancelled',
};

String translateCategory(String cat) {
  return categoryTranslations[cat] ?? cat;
}

String translateStatus(String status) {
  return statusTranslations[status] ?? status;
}
