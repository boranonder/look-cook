enum RecipeCategory {
  pizza('Pizza', '🍕'),
  tatli('Tatlı', '🍰'),
  dondurma('Dondurma', '🍦'),
  sokakLezzetleri('Sokak Lezzetleri', '🌭'),
  burger('Burger', '🍔'),
  doner('Döner', '🌯'),
  kebap('Kebap', '🥙'),
  tavuk('Tavuk', '🍗'),
  pide('Pide', '🥖'),
  lahmacun('Lahmacun', '🫓'),
  evYemekleri('Ev Yemekleri', '🏠'),
  kofte('Köfte', '🍖'),
  salata('Salata', '🥗'),
  vejeteryan('Vejeteryan', '🥬'),
  sushiUzakdogu('Sushi & Uzakdoğu', '🍣'),
  manti('Mantı', '🥟'),
  makarna('Makarna', '🍝'),
  denizUrunleri('Deniz Ürünleri', '🦞'),
  izgara('Izgara', '🔥'),
  tantuni('Tantuni', '🌮'),
  pilav('Pilav', '🍚'),
  meze('Meze', '🧆'),
  tostSandvic('Tost & Sandviç', '🥪'),
  pastaneFirin('Pastane & Fırın', '🥐'),
  kahve('Kahve', '☕'),
  kahvaltiBorek('Kahvaltı & Börek', '🥯'),
  dunyaMutfagi('Dünya Mutfağı', '🌍'),
  corba('Çorba', '🍲');

  const RecipeCategory(this.displayName, this.emoji);

  final String displayName;
  final String emoji;

  static RecipeCategory fromString(String value) {
    return RecipeCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => RecipeCategory.evYemekleri,
    );
  }
}

class CategoryColors {
  static const Map<RecipeCategory, List<int>> categoryGradients = {
    RecipeCategory.pizza: [0xFFFF6B6B, 0xFFFF8E53],
    RecipeCategory.tatli: [0xFFFFB8B8, 0xFFFF6B9D],
    RecipeCategory.dondurma: [0xFF9F7AEA, 0xFF805AD5],
    RecipeCategory.sokakLezzetleri: [0xFFED8936, 0xFFDD6B20],
    RecipeCategory.burger: [0xFF4ECDC4, 0xFF44A08D],
    RecipeCategory.doner: [0xFF6C5CE7, 0xFFA29BFE],
    RecipeCategory.kebap: [0xFFFFD93D, 0xFFFF6B95],
    RecipeCategory.tavuk: [0xFFFFB347, 0xFFFFCC02],
    RecipeCategory.pide: [0xFF74B9FF, 0xFF0984E3],
    RecipeCategory.lahmacun: [0xFFFF6B6B, 0xFFFF8E53],
    RecipeCategory.evYemekleri: [0xFF55A3FF, 0xFF003D82],
    RecipeCategory.kofte: [0xFFD69E2E, 0xFFB7791F],
    RecipeCategory.salata: [0xFF00B894, 0xFF00CEC9],
    RecipeCategory.vejeteryan: [0xFF48BB78, 0xFF38A169],
    RecipeCategory.sushiUzakdogu: [0xFFE53E3E, 0xFFC53030],
    RecipeCategory.manti: [0xFF805AD5, 0xFF6B46C1],
    RecipeCategory.makarna: [0xFFFFD93D, 0xFFFF8F00],
    RecipeCategory.denizUrunleri: [0xFF38B2AC, 0xFF319795],
    RecipeCategory.izgara: [0xFFFF7675, 0xFFD63031],
    RecipeCategory.tantuni: [0xFFE53E3E, 0xFFC53030],
    RecipeCategory.pilav: [0xFFFFE066, 0xFFFFAB00],
    RecipeCategory.meze: [0xFFFF7675, 0xFFE17055],
    RecipeCategory.tostSandvic: [0xFFED8936, 0xFFDD6B20],
    RecipeCategory.pastaneFirin: [0xFFD53F8C, 0xFFB83280],
    RecipeCategory.kahve: [0xFF744210, 0xFF5F370E],
    RecipeCategory.kahvaltiBorek: [0xFF74B9FF, 0xFF6C5CE7],
    RecipeCategory.dunyaMutfagi: [0xFF3182CE, 0xFF2C5282],
    RecipeCategory.corba: [0xFFFFAB00, 0xFFFF6348],
  };
}
