const List<String> _badWordsEsBase = [
  'asesinar',
  'asesinato',
  'cabron',
  'cabrón',
  'caca',
  'cago',
  'cerote',
  'chinga',
  'chingada',
  'chingar',
  'cono',
  'coño',
  'cojones',
  'culo',
  'droga',
  'estupido',
  'estúpido',
  'follar',
  'gilipollas',
  'idiota',
  'hijo de puta',
  'hijueputa',
  'hostia',
  'joder',
  'jodido',
  'marica',
  'maricon',
  'maricón',
  'matar',
  'mierda',
  'mrd',
  'odio',
  'paja',
  'pajero',
  'pendejo',
  'perra',
  'pinche',
  'polla',
  'porno',
  'pornografía',
  'prostituta',
  'puta',
  'puto',
  'retrasado',
  'semen',
  'spam',
  'suicidar',
  'suicidio',
  'teta',
  'violacion',
  'violación',
  'violencia',
  'zorra',
];

final List<String> badWordsEs = _generatePlurals(_badWordsEsBase);

List<String> _generatePlurals(List<String> baseWords) {
  final Set<String> result = {};
  for (final word in baseWords) {
    result.add(word); // Añadir palabra original
    
    // Plurales genéricos terminados en vocal o consonante
    if (word.endsWith('a') || word.endsWith('e') || word.endsWith('i') || word.endsWith('o') || word.endsWith('u') || 
        word.endsWith('á') || word.endsWith('é') || word.endsWith('í') || word.endsWith('ó') || word.endsWith('ú')) {
      result.add('${word}s');
    } else {
      result.add('${word}es');
      result.add('${word}s'); // Por si acaso hay anglicismos
    }
    
    // Palabras que pierden tilde al hacerse plurales (ej: cabrón -> cabrones)
    if (word.endsWith('ón')) {
      final withoutAccent = word.substring(0, word.length - 2) + 'on';
      result.add('${withoutAccent}es');
    }
  }
  return result.toList();
}
