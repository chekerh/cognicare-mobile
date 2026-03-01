import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFADD8E6);
const Color _accent = Color(0xFF212121);

/// Formulaire de commande dans l'app (pas de navigation vers le site).
/// Les données sont envoyées au backend qui les enregistre puis les envoie au site.
class IntegrationOrderFormScreen extends StatefulWidget {
  final String websiteSlug;
  final String externalId;
  final String productName;
  final String price;

  const IntegrationOrderFormScreen({
    super.key,
    required this.websiteSlug,
    required this.externalId,
    required this.productName,
    required this.price,
  });

  static IntegrationOrderFormScreen fromState(GoRouterState state) {
    final e = (state.extra as Map<String, dynamic>?) ?? {};
    return IntegrationOrderFormScreen(
      websiteSlug: e['websiteSlug'] as String? ?? '',
      externalId: e['externalId'] as String? ?? '',
      productName: e['productName'] as String? ?? '',
      price: e['price'] as String? ?? '',
    );
  }

  @override
  State<IntegrationOrderFormScreen> createState() =>
      _IntegrationOrderFormScreenState();
}

class _IntegrationOrderFormScreenState extends State<IntegrationOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  int _quantity = 1;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'address': _addressController.text.trim(),
            'city': _cityController.text.trim(),
            'phone': _phoneController.text.trim(),
          },
        }),
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final message =
            data['message'] as String? ?? 'Commande enregistrée avec succès.';
        final status = data['status'] as String? ?? '';
        final sentToSiteAt = data['sentToSiteAt'] != null
            ? DateTime.tryParse(data['sentToSiteAt'] as String)
            : null;
        final cartUrl = data['cartUrl'] as String?;
        String detail = message;
        if (status == 'sent' && sentToSiteAt != null && cartUrl == null) {
          final dateStr = '${sentToSiteAt.day}/${sentToSiteAt.month}/${sentToSiteAt.year} à ${sentToSiteAt.hour}h${sentToSiteAt.minute.toString().padLeft(2, '0')}';
          detail = '$message\n\nEnvoyée au site le $dateStr.';
        } else if (status == 'received') {
          detail = '$message\n\n(Vérifier plus tard si le site a bien reçu la commande.)';
        }
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Commande enregistrée'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail),
                  if (cartUrl != null && cartUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Vous pouvez finaliser le paiement sur le site du marchand.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (cartUrl != null && cartUrl.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final uri = Uri.parse(cartUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) context.go(AppConstants.familyMarketRoute);
                  },
                  child: const Text('Ouvrir le panier'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppConstants.familyMarketRoute);
                },
                child: Text(cartUrl != null && cartUrl.isNotEmpty ? 'Fermer' : 'OK'),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: _accent,
        title: const Text('Commander'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prix: ${widget.price}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Quantité: ', style: TextStyle(fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text('$_quantity',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirmer la commande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
