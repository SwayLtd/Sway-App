// lib/features/search/utils/levenshtein_similarity.dart

// Fonction simple de calcul de similarité (par exemple, basé sur la distance de Levenshtein)
int levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  List<List<int>> matrix =
      List.generate(s.length + 1, (_) => List<int>.filled(t.length + 1, 0));

  for (int i = 0; i <= s.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= t.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= s.length; i++) {
    for (int j = 1; j <= t.length; j++) {
      int cost = s[i - 1] == t[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  return matrix[s.length][t.length];
}

double similarity(String s, String t) {
  int maxLen = s.length > t.length ? s.length : t.length;
  if (maxLen == 0) return 1.0;
  return 1.0 - (levenshtein(s.toLowerCase(), t.toLowerCase()) / maxLen);
}
