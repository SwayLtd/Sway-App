String capitalizeEachWord(String input) {
  // Sépare la chaîne par espaces
  final words = input.split(' ');
  // Capitalise le premier caractère de chaque mot
  final capitalizedWords = words.map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).toList();
  // Recolle le tout
  return capitalizedWords.join(' ');
}

String capitalizeFirst(String input) {
  if (input.isEmpty) return input;
  // On pourrait .trim() si on veut ignorer d'éventuels espaces de début/fin
  return input[0].toUpperCase() + input.substring(1);
}
