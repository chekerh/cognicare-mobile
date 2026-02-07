import 'package:flutter/foundation.dart';

/// Élément du panier : produit + quantité.
class CartItem {
  final String productId;
  final String title;
  final String price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get priceValue {
    final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double get subtotal => priceValue * quantity;
}

/// Fournisseur du panier — add, remove, update quantity.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  void addItem({
    required String productId,
    required String title,
    required String price,
    required String imageUrl,
  }) {
    for (final item in _items) {
      if (item.productId == productId) {
        item.quantity++;
        notifyListeners();
        return;
      }
    }
    _items.add(CartItem(
      productId: productId,
      title: title,
      price: price,
      imageUrl: imageUrl,
    ));
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    for (final item in _items) {
      if (item.productId == productId) {
        item.quantity = quantity;
        notifyListeners();
        return;
      }
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
