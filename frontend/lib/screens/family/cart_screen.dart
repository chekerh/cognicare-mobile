import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';

/// Étape 1/3 — Panier. Design HTML CogniCare.
const Color _primary = Color(0xFFADD8E6);
const Color _vibrantBlue = Color(0xFF2563EB);
const Color _textPrimary = Color(0xFF1E293B);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            if (cart.items.isEmpty) {
              return _buildEmptyCart(context);
            }
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      ...cart.items.map((item) => _CartItemTile(item: item)),
                      const SizedBox(height: 24),
                      _buildPromoSection(),
                    ],
                  ),
                ),
                _buildBottomBar(context, cart),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: _vibrantBlue.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Votre panier est vide',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des produits depuis la boutique',
                  style: TextStyle(fontSize: 14, color: _textPrimary.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go(AppConstants.familyMarketRoute),
                  child: const Text('Voir la boutique'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.chevron_left, color: _textPrimary, size: 28),
              ),
            ),
          ),
          const Spacer(),
          const Column(
            children: [
              Text('Your Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
              Text('STEP 1 OF 3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textPrimary, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.sell, color: _textPrimary.withOpacity(0.7), size: 24),
              const SizedBox(width: 12),
              const Text('Apply Promo Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          Icon(Icons.chevron_right, color: _textPrimary.withOpacity(0.5), size: 24),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final total = cart.subtotal;
    final totalStr = '\$${total.toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: _vibrantBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            _summaryRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
            _summaryRow('Shipping', 'Free', isGreen: true),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                Text(totalStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppConstants.familyCheckoutRoute),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  shadowColor: _vibrantBlue.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Proceed to Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: _textPrimary.withOpacity(0.7))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isGreen ? Colors.green.shade700 : _textPrimary)),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final imageUrl = item.imageUrl.isNotEmpty
        ? item.imageUrl
        : 'https://lh3.googleusercontent.com/aida-public/AB6AXuBxLi3orbHizk7ckWGJn-wDDnoiT68bQFAdQE-2k2Qbu6NU4QC3FrichU0ktckfBVTFKt3T7FN6J8FUnmaTDnkva4rGz0dNbR0Gsw4ChyoCA4H_RlQK9XF3MquE-uTTTFPzQQHNRyqOrbamEu0RcvMHe3sT5w0BJF9ipV-6DObg4ysAlFyJFoGYBfshDRWvsHoIoYaF4p5_k-uChYJ8cBjDxHYEQz_10CPUh8lqiyDYebcgVq9o-nETukSZoBuEuPkDZYSoTpZNBn8';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => cart.removeItem(item.productId),
                      icon: Icon(Icons.delete, color: _textPrimary.withOpacity(0.6), size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _vibrantBlue)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => cart.updateQuantity(item.productId, item.quantity - 1),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.remove, size: 20, color: _textPrimary.withOpacity(0.6)),
                            ),
                          ),
                          SizedBox(width: 20, child: Center(child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))),
                          InkWell(
                            onTap: () => cart.updateQuantity(item.productId, item.quantity + 1),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.add, size: 20, color: _vibrantBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
