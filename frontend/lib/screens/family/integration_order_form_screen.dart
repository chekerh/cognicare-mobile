import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

// Design premium aligné sur le HTML (CogniCare Premium Checkout)
const Color _primary = Color(0xFFA3DAE1);
const Color _brandBlue = Color(0xFF5FB8C4);
const Color _background = Color(0xFFF8FAFC);
const Color _textDark = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);

/// Formulaire de commande dans l'app. Les données sont envoyées au backend qui les enregistre
/// et les transmet au site (formActionUrl) sans ouvrir le site.
class IntegrationOrderFormScreen extends StatefulWidget {
  final String websiteSlug;
  final String externalId;
  final String productName;
  final String price;
  final String imageUrl;

  const IntegrationOrderFormScreen({
    super.key,
    required this.websiteSlug,
    required this.externalId,
    required this.productName,
    required this.price,
    this.imageUrl = '',
  });

  static IntegrationOrderFormScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    return IntegrationOrderFormScreen(
      websiteSlug: e['websiteSlug'] as String? ?? '',
      externalId: e['externalId'] as String? ?? '',
      productName: e['productName'] as String? ?? '',
      price: e['price'] as String? ?? '',
      imageUrl: e['imageUrl'] as String? ?? '',
    );
  }

  @override
  State<IntegrationOrderFormScreen> createState() =>
      _IntegrationOrderFormScreenState();
}

class _IntegrationOrderFormScreenState extends State<IntegrationOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  int _quantity = 1;
  String _country = 'Tunisie';
  bool _billingSameAsDelivery = true;
  bool _submitting = false;
  String? _error;

  static const String _shippingCost = '7,500 DT';

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _emailController.text = user.email;
      final parts = user.fullName.split(' ');
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final base = AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;
      final url =
          '$base${AppConstants.integrationsOrdersEndpoint(widget.websiteSlug)}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'externalId': widget.externalId,
          'quantity': _quantity,
          'productName': widget.productName,
          'formData': {
            'email': _emailController.text.trim(),
            'country': _country,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'fullName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
            'address': _addressController.text.trim(),
            'postalCode': _postalCodeController.text.trim(),
            'city': _cityController.text.trim(),
            'phone': _phoneController.text.trim(),
            'shippingMethod': 'Standard',
            'shippingCost': _shippingCost,
            'paymentMethod': 'Paiement à la livraison',
            'billingSameAsDelivery': _billingSameAsDelivery.toString(),
            'price': widget.price,
          },
        }),
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        final message =
            data['message'] as String? ?? 'Commande enregistrée avec succès.';
        // Expliquer comment la commande sera traitée
        final String detail = status == 'sent'
            ? 'Votre commande a été envoyée au marchand (ex. BioHerbs).\n\n'
              'Il vous contactera par email ou téléphone pour confirmer la livraison et le paiement.'
            : 'Votre commande est enregistrée dans l’application.\n\n'
              'Le marchand pourra la consulter et vous recontactera pour organiser la livraison.';
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Commande enregistrée'),
            content: SingleChildScrollView(
              child: Text(detail),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppConstants.familyMarketRoute);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _error = 'Erreur: ${response.statusCode}';
          _submitting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _buildProductCard(),
                      const SizedBox(height: 24),
                      _buildDeliverySection(),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildConfirmButton(),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Paiement sécurisé par cryptage SSL',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    foregroundColor: _textDark,
                  ),
                ),
                const Text(
                  'Commander',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 24),
              painter: _WaveClipPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 96,
                  height: 96,
                  color: const Color(0xFFF8FAFC),
                  child: widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.shopping_bag_rounded,
                            size: 40,
                            color: _textMuted,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_rounded,
                          size: 40,
                          color: _textMuted,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _brandBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quantité',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: _quantity > 1 ? _textMuted : _textMuted.withOpacity(0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_rounded),
                      color: _primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_shipping_rounded, size: 20, color: _primary),
            SizedBox(width: 8),
            Text(
              'Détails de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFloatingField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdownCountry(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFloatingField(
                      controller: _firstNameController,
                      label: 'Prénom (optionnel)',
                      hint: 'Prénom',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFloatingField(
                      controller: _lastNameController,
                      label: 'Nom',
                      hint: 'Nom',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFloatingField(
                controller: _addressController,
                label: 'Adresse',
                hint: 'Rue, numéro...',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildFloatingField(
                      controller: _postalCodeController,
                      label: 'Code postal (facultatif)',
                      hint: '8000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildFloatingField(
                      controller: _cityController,
                      label: 'Ville',
                      hint: 'Nabeul, Tunis...',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFloatingField(
                controller: _phoneController,
                label: 'Téléphone',
                hint: '+216 20 00 00 00',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              _buildShippingMethod(),
              const SizedBox(height: 16),
              _buildPaymentMethod(),
              const SizedBox(height: 16),
              _buildBillingAddress(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCountry() {
    return DropdownButtonFormField<String>(
      value: _country,
      decoration: InputDecoration(
        labelText: 'Pays / région',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Tunisie', child: Text('Tunisie')),
        DropdownMenuItem(value: 'France', child: Text('France')),
      ],
      onChanged: (v) => setState(() => _country = v ?? 'Tunisie'),
    );
  }

  Widget _buildShippingMethod() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mode d\'expédition',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          Row(
            children: [
              const Text('Standard', style: TextStyle(color: _textDark)),
              const SizedBox(width: 8),
              Text(
                _shippingCost,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _brandBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, size: 22, color: _primary),
          const SizedBox(width: 12),
          const Text(
            'Paiement à la livraison',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse de facturation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<bool>(
          title: const Text('Identique à l\'adresse de livraison'),
          value: true,
          groupValue: _billingSameAsDelivery,
          onChanged: (v) => setState(() => _billingSameAsDelivery = v ?? true),
          activeColor: _primary,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          title: const Text('Utiliser une adresse de facturation différente'),
          value: false,
          groupValue: _billingSameAsDelivery,
          onChanged: (v) => setState(() => _billingSameAsDelivery = v ?? false),
          activeColor: _primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildFloatingField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textMuted,
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Material(
      color: _primary,
      borderRadius: BorderRadius.circular(32),
      shadowColor: _primary.withOpacity(0.5),
      elevation: 8,
      child: InkWell(
        onTap: _submitting ? null : _submit,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: _submitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: _textDark,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _textDark, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Confirmer la commande',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WaveClipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _background;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
