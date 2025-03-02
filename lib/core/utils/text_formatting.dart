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

String formatNumber(int number) {
  if (number >= 1000000) {
    double value = number / 1000000;
    // Affiche sans décimales si entier, sinon 1 décimale
    return value == value.toInt()
        ? '${value.toInt()}M'
        : '${value.toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    double value = number / 1000;
    return value == value.toInt()
        ? '${value.toInt()}K'
        : '${value.toStringAsFixed(1)}K';
  } else {
    return number.toString();
  }
}
