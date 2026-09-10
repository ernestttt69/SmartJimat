import 'cart_item.dart';

class StoreProductPrice {
  final CartItem cartItem;
  final double unitPrice;

  StoreProductPrice({
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

  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  StoreComparison({
    required this.premiseCode,
    required this.premiseName,
    required this.address,
    required this.premiseType,
    required this.state,
    required this.products,
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

  bool get hasLocation {
    return latitude != null &&
        longitude != null;
  }

  bool get isNearby {
    if (distanceKm == null) {
      return false;
    }

    return distanceKm! <= 10;
  }
}