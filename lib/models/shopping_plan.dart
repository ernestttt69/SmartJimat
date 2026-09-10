import 'cart_item.dart';
import 'store_comparison.dart';

class ShoppingPlanItem {
  final CartItem cartItem;
  final double? unitPrice;

  const ShoppingPlanItem({
    required this.cartItem,
    required this.unitPrice,
  });

  bool get hasPrice {
    return unitPrice != null;
  }

  double get subtotal {
    if (unitPrice == null) {
      return 0;
    }

    return unitPrice! * cartItem.quantity;
  }
}

class ShoppingPlanStore {
  final StoreComparison store;
  final List<ShoppingPlanItem> items;

  const ShoppingPlanStore({
    required this.store,
    required this.items,
  });

  int get itemCount {
    return items.length;
  }

  int get pricedItemCount {
    return items
        .where(
          (item) => item.hasPrice,
    )
        .length;
  }

  double get subtotal {
    return items.fold(
      0,
          (total, item) =>
      total + item.subtotal,
    );
  }
}

class ShoppingPlan {
  final List<ShoppingPlanStore> stores;
  final int coveredItemCount;
  final int pricedItemCount;
  final int totalItemCount;
  final double knownPriceTotal;
  final double travelDistanceKm;
  final double valueScore;

  const ShoppingPlan({
    required this.stores,
    required this.coveredItemCount,
    required this.pricedItemCount,
    required this.totalItemCount,
    required this.knownPriceTotal,
    required this.travelDistanceKm,
    required this.valueScore,
  });

  int get storeCount {
    return stores.length;
  }

  bool get isComplete {
    return coveredItemCount >= totalItemCount;
  }

  int get missingItemCount {
    return totalItemCount - coveredItemCount;
  }
}