import 'cart_item.dart';

class StoreProductPrice {
  final CartItem cartItem;
  final double unitPrice;

  const StoreProductPrice({
    required this.cartItem,
    required this.unitPrice,
  });

  double get subtotal {
    return unitPrice * cartItem.quantity;
  }
}

class StoreComparison {
  final int premiseCode;
  final String premiseName;
  final String address;
  final String premiseType;
  final String state;
  final List<StoreProductPrice> products;
  final List<CartItem> recordedItems;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  const StoreComparison({
    required this.premiseCode,
    required this.premiseName,
    required this.address,
    required this.premiseType,
    required this.state,
    required this.products,
    this.recordedItems = const [],
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  double get totalPrice {
    return products.fold(
      0,
          (total, product) =>
      total + product.subtotal,
    );
  }

  int get availableItemCount {
    return products.length;
  }

  int get pricedItemCount {
    return products.length;
  }

  int get coveredItemCount {
    return recordedItems.length;
  }

  Set<int> get recordedItemCodes {
    return recordedItems
        .map(
          (item) => item.product.itemCode,
    )
        .toSet();
  }

  Set<int> get pricedItemCodes {
    return products
        .map(
          (item) =>
      item.cartItem.product.itemCode,
    )
        .toSet();
  }

  List<CartItem> get unpricedItems {
    final pricedCodes = pricedItemCodes;

    return recordedItems
        .where(
          (item) =>
      !pricedCodes.contains(
        item.product.itemCode,
      ),
    )
        .toList();
  }
}