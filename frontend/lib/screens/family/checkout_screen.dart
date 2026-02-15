import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/cart_provider.dart';
import '../../services/notification_service.dart';
import '../../services/notifications_feed_service.dart';
import '../../services/paypal_service.dart';
import '../../utils/constants.dart';

/// Étape 2/3 — Paiement et livraison. Même bleu de fond que l'écran Commande confirmée (#ADD8E6).
const Color _primary = Color(0xFFADD8E6);
const Color _accentColor = Color(0xFF212121);
const Color _textPrimary = Color(0xFF1E293B);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: "Leo's Parent");
  final _streetController = TextEditingController(text: '123 Harmony Lane');
  final _cityController = TextEditingController(text: 'San Francisco');
  final _zipController = TextEditingController(text: '94103');
  final _cardController = TextEditingController(text: '**** **** **** 4242');
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  int _paymentMethod = 0; // 0: Card, 1: Apple Pay, 2: PayPal

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _confirmPay(BuildContext context, CartProvider cart) {
    if (_paymentMethod == 2) {
      _processPayPalPayment(context, cart);
      return;
    }
    if (_paymentMethod != 0) {
      _processPayment(context, cart);
      return;
    }
    // Paiement carte : vérifier que tous les champs sont remplis
    final card = _cardController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();
    if (card.isEmpty || expiry.isEmpty || cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs (numéro de carte, date d\'expiration, CVV).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      _processPayment(context, cart);
    }
  }

  Future<void> _processPayPalPayment(BuildContext context, CartProvider cart) async {
    final total = cart.subtotal;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le panier est vide.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final amountStr = total.toStringAsFixed(2);
    try {
      final result = await PaypalService().createOrder(amount: amountStr, currencyCode: 'USD');
      final launched = await launchUrl(Uri.parse(result.approvalUrl), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir PayPal.'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      _showPayPalWaitingDialog(context, cart, result.orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPayPalWaitingDialog(BuildContext context, CartProvider cart, String orderId) {
    final address = '${_streetController.text}, ${_zipController.text} ${_cityController.text}';
    final totalStr = '\$${cart.subtotal.toStringAsFixed(2)}';
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PayPalWaitingDialog(
        orderId: orderId,
        onVerified: () async {
          try {
            final status = await PaypalService().getOrderStatus(orderId);
            if (status.status == 'COMPLETED') {
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop(true);
              final amountStr = '\$${cart.subtotal.toStringAsFixed(2)}';
              try {
                await NotificationsFeedService().createNotification(
                  type: 'order_confirmed',
                  title: 'Paiement confirmé',
                  description: 'Commande #$orderId • $amountStr',
                );
              } catch (_) {}
              final imageUrl = cart.items.isNotEmpty ? cart.items.first.imageUrl : null;
              cart.clear();
              ctx.push(
                AppConstants.familyOrderConfirmationRoute,
                extra: { 'orderId': orderId, 'address': address, if (imageUrl != null) 'imageUrl': imageUrl },
              );
            } else {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Paiement pas encore finalisé (statut: ${status.status}). Réessayez après avoir payé sur PayPal.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    final orderId = '${DateTime.now().millisecondsSinceEpoch}'.substring(5);
    final address = '${_streetController.text}, ${_zipController.text} ${_cityController.text}';
    final totalStr = '\$${cart.subtotal.toStringAsFixed(2)}';
    NotificationService().showPaymentConfirmation(
      orderId: orderId,
      amount: totalStr,
    );
    try {
      await NotificationsFeedService().createNotification(
        type: 'order_confirmed',
        title: 'Paiement confirmé',
        description: 'Commande #$orderId • $totalStr',
      );
    } catch (_) {}
    final imageUrl = cart.items.isNotEmpty ? cart.items.first.imageUrl : null;
    cart.clear();
    if (!context.mounted) return;
    context.push(
      AppConstants.familyOrderConfirmationRoute,
      extra: {
        'orderId': orderId,
        'address': address,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            final total = cart.subtotal;
            final totalStr = '\$${total.toStringAsFixed(2)}';
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildShippingSection(),
                          const SizedBox(height: 24),
                          _buildPaymentSection(),
                          const SizedBox(height: 24),
                          _buildOrderSummary(totalStr),
                          const SizedBox(height: 24),
                          _buildConfirmButton(context, cart),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 20),
              ),
            ),
          ),
          const Spacer(),
          const Column(
            children: [
              Text('Checkout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
              Text('STEP 2 OF 3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textPrimary, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: _accentColor.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          _inputField('Full Name', _nameController),
          const SizedBox(height: 16),
          _inputField('Street Address', _streetController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _inputField('City', _cityController)),
              const SizedBox(width: 16),
              Expanded(child: _inputField('Zip Code', _zipController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textPrimary.withOpacity(0.6)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: _accentColor.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _paymentOption(0, Icons.credit_card, 'Card'),
              const SizedBox(width: 12),
              _paymentOption(1, Icons.apple, 'Apple Pay'),
              const SizedBox(width: 12),
              _paymentOption(2, Icons.account_balance_wallet, 'PayPal'),
            ],
          ),
          if (_paymentMethod == 0) ...[
            const SizedBox(height: 24),
            _inputField('Card Number', _cardController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _inputField('Expiry (MM/YY)', _expiryController)),
                const SizedBox(width: 16),
                Expanded(child: _inputField('CVV', _cvvController)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentOption(int index, IconData icon, String label) {
    final selected = _paymentMethod == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _accentColor.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _accentColor : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? _accentColor : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(String totalStr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: _textPrimary)), Text(totalStr, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shipping', style: TextStyle(color: _textPrimary)), Text('Free', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700))]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(totalStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))]),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, CartProvider cart) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _confirmPay(context, cart),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 8,
          shadowColor: Colors.black26,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Confirm & Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(width: 12),
            Icon(Icons.lock, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PayPalWaitingDialog extends StatelessWidget {
  final String orderId;
  final VoidCallback onVerified;

  const _PayPalWaitingDialog({required this.orderId, required this.onVerified});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paiement PayPal'),
      content: const Text(
        'Un navigateur a été ouvert pour finaliser le paiement. '
        'Une fois le paiement effectué sur PayPal, appuyez sur « Vérifier le paiement » ci-dessous.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: onVerified,
          child: const Text('Vérifier le paiement'),
        ),
      ],
    );
  }
}
