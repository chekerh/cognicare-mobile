import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

/// Étape 3/3 — Commande confirmée. Design HTML.
const Color _primary = Color(0xFFADD8E6);
const Color _brandBlue = Color(0xFF2563EB);

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.address,
  });

  final String orderId;
  final String address;

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
                    _buildSuccessGraphic(),
                    const SizedBox(height: 32),
                    Text(
                      'Commande Confirmée !',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Votre commande #$orderId est en cours de préparation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDetailsCard(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 4,
                          shadowColor: _brandBlue.withOpacity(0.4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Suivre ma commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go(AppConstants.familyMarketRoute),
                      child: Text(
                        'Retour à la boutique',
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

  Widget _buildSuccessGraphic() {
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
              BoxShadow(color: _brandBlue.withOpacity(0.3), blurRadius: 24),
            ],
          ),
          child: Center(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBxLi3orbHizk7ckWGJn-wDDnoiT68bQFAdQE-2k2Qbu6NU4QC3FrichU0ktckfBVTFKt3T7FN6J8FUnmaTDnkva4rGz0dNbR0Gsw4ChyoCA4H_RlQK9XF3MquE-uTTTFPzQQHNRyqOrbamEu0RcvMHe3sT5w0BJF9ipV-6DObg4ysAlFyJFoGYBfshDRWvsHoIoYaF4p5_k-uChYJ8cBjDxHYEQz_10CPUh8lqiyDYebcgVq9o-nETukSZoBuEuPkDZYSoTpZNBn8',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 80, color: _brandBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
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
                  color: _brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_shipping, color: _brandBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Livraison estimée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    color: _brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_on, color: _brandBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adresse de livraison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
