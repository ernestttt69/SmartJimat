class Product {
  final int itemCode;
  final String item;
  final String unit;
  final String itemGroup;
  final String itemCategory;

  Product({
    required this.itemCode,
    required this.item,
    required this.unit,
    required this.itemGroup,
    required this.itemCategory,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      itemCode: map['item_code'] ?? 0,
      item: map['item']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      itemGroup: map['item_group']?.toString() ?? '',
      itemCategory: map['item_category']?.toString() ?? '',
    );
  }
}