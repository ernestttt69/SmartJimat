class TranslationHelper {
  static const Map<String, String> translations = {
    // Main Groups
    'BARANGAN SEGAR': 'Fresh Goods',
    'BARANGAN KERING': 'Dry Goods',
    'MAKANAN': 'Food',
    'MINUMAN': 'Beverages',

    // Categories
    'SAYUR-SAYURAN': 'Vegetables',
    'BUAH-BUAHAN': 'Fruits',
    'AYAM': 'Chicken',
    'DAGING': 'Meat',
    'IKAN': 'Fish',
    'TELUR': 'Eggs',
    'SUSU': 'Milk',
    'BERAS': 'Rice',
    'MINYAK MASAK': 'Cooking Oil',
    'GULA': 'Sugar',
    'TEPUNG': 'Flour',
    'ROTI': 'Bread',

    // Add more when needed
  };

  static String translate(String malayText) {
    final key = malayText.trim().toUpperCase();

    return translations[key] ?? malayText;
  }
}