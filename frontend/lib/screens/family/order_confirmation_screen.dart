import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

/// Étape 3/3 — Commande confirmée. Design HTML.
const Color _primary = Color(0xFFADD8E6);
const Color _brandBlue = Color(0xFF2563EB);
/// Même couleur que le titre "Commande Confirmée !" (gris très foncé)
const Color _titleColor = Color(0xFF212121);

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.address,
    this.imageUrl,
  });

  final String orderId;
  final String address;
  /// URL de l'image du produit (premier du panier). Si null, affiche une icône par défaut.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _buildSuccessGraphic(context),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.orderConfirmedTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.orderPreparing(orderId),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDetailsCard(context),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _titleColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 4,
                          shadowColor: _titleColor.withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.trackMyOrder, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go(AppConstants.familyMarketRoute),
                      child: Text(
                        AppLocalizations.of(context)!.returnToStore,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessGraphic(BuildContext context) {
    final url = imageUrl != null && imageUrl!.isNotEmpty
        ? (imageUrl!.startsWith('http') ? imageUrl! : '${AppConstants.baseUrl}$imageUrl')
        : null;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 16,
          left: 16,
          child: Icon(Icons.star, color: Colors.amber.shade400, size: 32),
        ),
        const Positioned(
          top: 48,
          right: 24,
          child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        ),
        Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(color: _titleColor.withOpacity(0.2), blurRadius: 24),
            ],
          ),
          child: Center(
            child: url != null
                ? Image.network(
                    url,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 80, color: _titleColor),
                  )
                : const Icon(Icons.card_giftcard, size: 80, color: _titleColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final now = DateTime.now();
    final start = now.add(const Duration(days: 3));
    final end = now.add(const Duration(days: 5));
    String fmt(DateTime d) => '${_day(d.weekday)} ${d.day} ${_month(d.month)}';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: _brandBlue.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _titleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_shipping, color: _titleColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.estimatedDelivery, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${fmt(start)} — ${fmt(end)}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _titleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_on, color: _titleColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.shippingAddress, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(address, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _day(int w) {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[w];
  }

  String _month(int m) {
    const months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[m];
  }
}
