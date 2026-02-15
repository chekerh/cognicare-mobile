import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../services/donation_service.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/location_map_widget.dart';
import '../../widgets/location_search_field.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _primaryDark = Color(0xFF7FBAC4);
const Color _bgLight = Color(0xFFF0F7FF);

/// Écran « Proposer un don » — aligné sur le design HTML : photos, titre, catégorie, état, description, localisation.
class ProposeDonationScreen extends StatefulWidget {
  const ProposeDonationScreen({super.key});

  @override
  State<ProposeDonationScreen> createState() => _ProposeDonationScreenState();
}

class _ProposeDonationScreenState extends State<ProposeDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final List<File> _photos = [];
  static const int _maxPhotos = 5;
  int _categoryIndex = -1; // -1 = non sélectionné, 0=Vêtements, 1=Mobilier, 2=Éveil
  int _conditionIndex = 1; // 0=Neuf, 1=Très bon état, 2=Bon état
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  double? _mapLat;
  double? _mapLng;
  bool _mapLoading = false;
  final GeocodingService _geocoding = GeocodingService();

  static const List<String> _categories = ['Vêtements', 'Mobilier', "Matériel d'éveil"];
  static const List<String> _conditions = ['Neuf', 'Très bon état', 'Bon état'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _geocodeLocation() async {
    final address = _locationController.text.trim();
    if (address.isEmpty) return;
    setState(() {
      _mapLoading = true;
      _mapLat = null;
      _mapLng = null;
    });
    // Essayer geocode direct, puis searchSuggestions en secours (ex: "ariana" → première suggestion)
    GeocodingResult? result = await _geocoding.geocode(address);
    if (result == null) {
      final suggestions = await _geocoding.searchSuggestions(address);
      result = suggestions.isNotEmpty ? suggestions.first : null;
    }
    if (!mounted) return;
    setState(() {
      _mapLoading = false;
      _mapLat = result?.latitude;
      _mapLng = result?.longitude;
    });
    if (result != null) {
      _locationController.text = result.displayName;
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Adresse introuvable. Essayez une adresse plus précise (ex: Ariana, Tunisie ou Paris, France)',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= _maxPhotos) return;
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (!mounted) return;
      setState(() {
        for (final x in picked) {
          if (_photos.length >= _maxPhotos) break;
          _photos.add(File(x.path));
        }
      });
    } catch (_) {}
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.donationFormCategory),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = DonationService();
      final imageUrls = <String>[];
      for (final photo in _photos) {
        final url = await service.uploadImage(photo);
        imageUrls.add(url);
      }

      await service.createDonation(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryIndex,
        condition: _conditionIndex,
        location: _locationController.text.trim(),
        imageUrls: imageUrls,
        isOffer: true,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(loc.donationProposedSuccess),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                  children: [
                    _buildPhotosSection(),
                    const SizedBox(height: 24),
                    _buildDetailsCard(loc),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(loc),
                    const SizedBox(height: 16),
                    _buildLocationCard(loc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildPublishButton(loc),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgLight.withOpacity(0.8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _primary),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
          ),
          const Expanded(
            child: Text(
              'Proposer un don',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111418),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajouter des photos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickPhotos,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
              ),
              child: _photos.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, size: 48, color: _primary),
                        const SizedBox(height: 8),
                        const Text('Cliquez pour ajouter des photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _primary)),
                        const SizedBox(height: 4),
                        Text('Jusqu\'à $_maxPhotos photos', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i < _photos.length) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_photos[i], fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return GestureDetector(
                          onTap: _pickPhotos,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _primary.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.add, color: _primary, size: 32),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.donationFormTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Ex: Vêtements sensoriels, Lit médicalisé...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primary.withOpacity(0.2), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? loc.donationFormTitleRequired : null,
          ),
          const SizedBox(height: 20),
          const Text('Catégorie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<int>(
              value: _categoryIndex >= 0 ? _categoryIndex : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: const Text('Sélectionner une catégorie'),
              items: List.generate(_categories.length, (i) => DropdownMenuItem(value: i, child: Text(_categories[i]))),
              onChanged: (v) => setState(() => _categoryIndex = v ?? -1),
            ),
          ),
          const SizedBox(height: 20),
          const Text('État de l\'objet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_conditions.length, (i) {
              final selected = _conditionIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _conditionIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _primary.withOpacity(0.1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: selected ? _primary : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _conditions[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? _primary : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.donationFormDescription,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Décrivez l\'objet et comment il peut aider un enfant avec des besoins spécifiques...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primary.withOpacity(0.2), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? loc.donationFormDescriptionRequired : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Mentionner les bénéfices sensoriels ou ergonomiques aide les autres parents.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Localisation du retrait', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 12),
          LocationSearchField(
            controller: _locationController,
            onLocationSelected: (result) {
              setState(() {
                _mapLat = result.latitude;
                _mapLng = result.longitude;
                _mapLoading = false;
              });
            },
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              if (_mapLoading) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    child: Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Chargement de la carte...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (_mapLat != null && _mapLng != null) {
                return LocationMapWidget(
                  latitude: _mapLat!,
                  longitude: _mapLng!,
                  height: 200,
                  borderRadius: BorderRadius.circular(12),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: InkWell(
                    onTap: _geocodeLocation,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Appuyez pour afficher la carte',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_bgLight, _bgLight.withOpacity(0)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                const BoxShadow(color: _primaryDark, offset: Offset(0, 4), blurRadius: 0),
                BoxShadow(color: _primary.withOpacity(0.3), offset: const Offset(0, 8), blurRadius: 15),
              ],
            ),
            child: _isSubmitting
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Publier mon don',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
