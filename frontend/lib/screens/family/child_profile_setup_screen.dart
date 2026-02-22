import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/children_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFF77CCD8);
const Color _bgLight = Color(0xFFA6D9E7);

/// Écran « Profil de l'enfant » — configuration médicale après signup famille.
class ChildProfileSetupScreen extends StatefulWidget {
  const ChildProfileSetupScreen({super.key});

  /// Clé de stockage pour vérifier si le profil est complété (dashboard).
  static const String storageKey = 'child_profile';

  /// Retourne true si le profil enfant a été enregistré avec un prénom renseigné.
  static Future<bool> isProfileComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null) return false;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').trim();
      return name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  State<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState extends State<ChildProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Léo');
  final _medicationsController = TextEditingController();
  final _specialNotesController = TextEditingController();

  int _ageYears = 4;
  String _gender = 'other'; // male | female | other
  final Set<int> _selectedMedicalCare = {
    0,
    2
  }; // 0: Orthophoniste, 1: Psychomotricien, 2: Ergothérapeute, 3: Pédiatre
  int _sensitivityLoudNoises = 2; // 0: Bas, 1: Moyen, 2: Haut
  int _sensitivityLight = 1; // 0: Bas, 1: Moyen, 2: Haut
  int _sensitivityTexture = 0; // 0: Bas, 1: Moyen, 2: Haut
  double _sleepHours = 10.5;
  bool _isSaving = false;

  static const List<({String label, IconData icon})> _medicalCareOptions = [
    (label: 'Orthophoniste', icon: Icons.psychology),
    (label: 'Psychomotricien', icon: Icons.accessibility_new),
    (label: 'Ergothérapeute', icon: Icons.precision_manufacturing),
    (label: 'Pédiatre', icon: Icons.medical_services),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _medicationsController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  /// Builds dateOfBirth as YYYY-MM-DD from age (1st Jan of birth year).
  static String _dateOfBirthFromAge(int ageYears) {
    final year = DateTime.now().year - ageYears;
    return '$year-01-01';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final fullName = _nameController.text.trim();
    final dateOfBirth = _dateOfBirthFromAge(_ageYears);
    const sensitivityLabels = ['Bas', 'Moyen', 'Haut'];
    final sensitivityText =
        'Bruit: ${sensitivityLabels[_sensitivityLoudNoises]}, '
        'Lumière: ${sensitivityLabels[_sensitivityLight]}, '
        'Texture: ${sensitivityLabels[_sensitivityTexture]}. '
        'Sommeil: $_sleepHours h.';
    final diagnosis = _selectedMedicalCare.isEmpty
        ? null
        : _selectedMedicalCare
            .map((i) => _medicalCareOptions[i].label)
            .join(', ');
    final medications = _medicationsController.text.trim();
    final medicalHistory = _specialNotesController.text.trim();
    final notes = sensitivityText;

    final dto = AddChildDto(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: _gender,
      diagnosis: diagnosis?.isNotEmpty == true ? diagnosis : null,
      medicalHistory: medicalHistory.isNotEmpty ? medicalHistory : null,
      medications: medications.isNotEmpty ? medications : null,
      notes: notes,
    );

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final childrenService =
          ChildrenService(getToken: () => AuthService().getStoredToken());
      await childrenService.addChild(dto);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : loc.childProfileSaved),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'name': fullName,
      'age': _ageYears,
      'medicalCare': _selectedMedicalCare.toList(),
      'medications': medications,
      'sensitivityLoudNoises': _sensitivityLoudNoises,
      'sensitivityLight': _sensitivityLight,
      'sensitivityTexture': _sensitivityTexture,
      'specialNotes': medicalHistory,
      'sleepHours': _sleepHours,
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          ChildProfileSetupScreen.storageKey, jsonEncode(data));
    } catch (_) {}

    setState(() => _isSaving = false);
    if (!mounted) return;
    context.go(AppConstants.familyDashboardRoute);
    messenger.showSnackBar(
      SnackBar(
        content: Text(loc.childProfileSaved),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: Column(
          children: [
            _buildHeader(loc),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 16),
                    _buildForm(loc),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.go(AppConstants.familyDashboardRoute),
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          Expanded(
            child: Text(
              loc.childProfileTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppConstants.familyDashboardRoute),
            child: Text(
              loc.childProfileSkipButton,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.child_care, color: Colors.white, size: 56),
          ),
          Positioned(
              top: -16,
              left: -8,
              child: Icon(Icons.star, color: Colors.yellow.shade300, size: 28)),
          Positioned(
              top: 8,
              right: -24,
              child:
                  Icon(Icons.extension, color: Colors.pink.shade300, size: 32)),
          Positioned(
              bottom: -8,
              right: -16,
              child: Icon(Icons.auto_awesome,
                  color: Colors.blue.shade300, size: 28)),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations loc) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.childProfileConfigTitle,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              loc.childProfileConfigSubtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildIdentitySection(loc),
            const SizedBox(height: 24),
            _buildMedicalCareSection(loc),
            const SizedBox(height: 24),
            _buildMedicationsSection(loc),
            const SizedBox(height: 24),
            _buildSensitivitiesSection(loc),
            const SizedBox(height: 24),
            _buildSpecialNotesSection(loc),
            const SizedBox(height: 24),
            _buildSleepSection(loc),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified, color: Colors.white),
                label: Text(
                  loc.childProfileSaveButton,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  loc.childProfileEncryptedNote,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitySection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.childProfileIdentityLabel,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: loc.childProfileFirstNameHint,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.childProfileNameRequired
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 56,
              constraints: const BoxConstraints(minWidth: 0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _ageYears > 1
                        ? () => setState(() => _ageYears--)
                        : null,
                    icon: const Icon(Icons.remove, color: _primary, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$_ageYears ${loc.childProfileYears}',
                          style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _ageYears < 18
                        ? () => setState(() => _ageYears++)
                        : null,
                    icon: const Icon(Icons.add, color: _primary, size: 20),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Genre (required by API)
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            labelText: 'Genre',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Garçon')),
            DropdownMenuItem(value: 'female', child: Text('Fille')),
            DropdownMenuItem(value: 'other', child: Text('Autre')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? 'other'),
        ),
      ],
    );
  }

  Widget _buildMedicalCareSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.childProfileMedicalCareLabel,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._medicalCareOptions.asMap().entries.map((e) {
              final selected = _selectedMedicalCare.contains(e.key);
              return ActionChip(
                avatar: Icon(e.value.icon,
                    size: 20, color: selected ? _primary : Colors.grey),
                label: Text(e.value.label,
                    style: TextStyle(
                        color: selected ? _primary : Colors.grey.shade600,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal)),
                onPressed: () => setState(() {
                  if (selected) {
                    _selectedMedicalCare.remove(e.key);
                  } else {
                    _selectedMedicalCare.add(e.key);
                  }
                }),
                backgroundColor:
                    selected ? _primary.withOpacity(0.1) : Colors.grey.shade100,
                side: BorderSide(
                    color: selected ? _primary : Colors.grey.shade300,
                    width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              );
            }),
            ActionChip(
              avatar: Icon(Icons.add, size: 20, color: Colors.grey.shade500),
              label: Text(loc.childProfileAddLabel,
                  style: TextStyle(color: Colors.grey.shade500)),
              onPressed: () {},
              backgroundColor: Colors.transparent,
              side: BorderSide(
                  color: Colors.grey.shade400,
                  width: 2,
                  style: BorderStyle.solid),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.childProfileMedicationsLabel,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _medicationsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: loc.childProfileMedicationsHint,
            suffixIcon:
                Icon(Icons.medication, color: Colors.grey.shade400, size: 22),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSensitivitiesSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.childProfileSensitivitiesLabel,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        _buildSensitivityCard(
            loc,
            loc.childProfileSensitivityLoudNoises,
            Icons.volume_up,
            _sensitivityLoudNoises,
            (v) => setState(() => _sensitivityLoudNoises = v)),
        const SizedBox(height: 12),
        _buildSensitivityCard(
            loc,
            loc.childProfileSensitivityLight,
            Icons.light_mode,
            _sensitivityLight,
            (v) => setState(() => _sensitivityLight = v)),
        const SizedBox(height: 12),
        _buildSensitivityCard(
            loc,
            loc.childProfileSensitivityTexture,
            Icons.texture,
            _sensitivityTexture,
            (v) => setState(() => _sensitivityTexture = v)),
      ],
    );
  }

  Widget _buildSensitivityCard(AppLocalizations loc, String label,
      IconData icon, int value, ValueChanged<int> onChanged) {
    const labels = ['Bas', 'Moyen', 'Haut'];
    final colors = [Colors.green, Colors.amber, Colors.red];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: _primary, size: 22),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155))),
                ],
              ),
              Text(
                labels[value],
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: colors[value].shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (i) {
              final selected = value == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: OutlinedButton(
                    onPressed: () => onChanged(i),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          selected ? _primary.withOpacity(0.2) : Colors.white,
                      foregroundColor:
                          selected ? _primary : Colors.grey.shade500,
                      side: BorderSide(
                          color: selected ? _primary : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(labels[i],
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialNotesSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.childProfileSpecialNotesLabel,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _specialNotesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: loc.childProfileSpecialNotesHint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.childProfileSleepLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500),
            ),
            Text(
              '$_sleepHours h',
              style:
                  const TextStyle(color: _primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primary,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: _primary,
            overlayColor: _primary.withOpacity(0.2),
          ),
          child: Slider(
            value: _sleepHours,
            min: 6,
            max: 14,
            divisions: 16,
            onChanged: (v) => setState(() => _sleepHours = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('6h',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500)),
            Text('${loc.childProfileTarget}: $_sleepHours h',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            Text('14h',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }
}
