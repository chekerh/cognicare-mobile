import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../utils/constants.dart';

// Stitch design tokens (from HTML)
const Color _primary = Color(0xFFa3dae1);
const Color _primarySoft = Color(0xFFf0f9fa);
const Color _primaryDark = Color(0xFF7bc5ce);
const Color _background = Color(0xFFf8fdfd);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);
const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 Mo

/// Care Provider Type values (must match backend enum).
const List<String> _careProviderTypeValues = [
  'speech_therapist',
  'occupational_therapist',
  'psychologist',
  'doctor',
  'ergotherapist',
  'caregiver',
  'organization_leader',
  'other',
];

/// Label and optional description for each Care Provider Type.
const Map<String, ({String label, String? description})> _careProviderTypeInfo = {
  'speech_therapist': (label: 'Orthophoniste', description: 'Spécialiste du langage et de la déglutition'),
  'occupational_therapist': (label: 'Ergothérapeute (réadaptation)', description: 'Réadaptation et activités de la vie quotidienne'),
  'psychologist': (label: 'Psychologue', description: 'Santé mentale et soutien cognitif'),
  'doctor': (label: 'Médecin / Docteur', description: 'Professionnel de santé médical'),
  'ergotherapist': (label: 'Ergothérapeute (handicaps physiques)', description: 'Spécialiste du traitement des handicaps physiques'),
  'caregiver': (label: 'Aidant (bénévole)', description: 'Bénévole avec formations ou expérience'),
  'organization_leader': (label: 'Responsable d\'organisation', description: 'Direction d\'une structure d\'aide'),
  'other': (label: 'Autre', description: 'Autre rôle d\'aidant'),
};

bool _isHealthcareType(String? type) =>
    type != null && ['speech_therapist', 'occupational_therapist', 'psychologist', 'doctor', 'ergotherapist'].contains(type);
bool _isCaregiverType(String? type) => type == 'caregiver';
bool _isOrganizationLeaderType(String? type) => type == 'organization_leader';
bool _isOtherType(String? type) => type == 'other';

/// Specialties for Healthcare Provider.
const List<String> _specialties = [
  'Ergothérapie',
  'Orthophonie',
  'Psychologie',
  'Médecine / Docteur',
  'Kinésithérapie',
  'Psychomotricité',
  'Autre',
];

/// Candidature bénévole / Care Provider – design Stitch (Pièces justificatives, type d'aidant, options).
class VolunteerApplicationScreen extends StatefulWidget {
  const VolunteerApplicationScreen({super.key});

  @override
  State<VolunteerApplicationScreen> createState() =>
      _VolunteerApplicationScreenState();
}

class _VolunteerApplicationScreenState extends State<VolunteerApplicationScreen> {
  final VolunteerService _volunteerService = VolunteerService();

  Map<String, dynamic>? _application;
  bool _loading = true;
  String? _error;

  File? _fileId;
  File? _fileCertificate;
  File? _fileOther;
  String? _errorId;
  String? _errorCertificate;
  String? _errorOther;

  bool _notSpecialistNoDiploma = false;
  bool _wantsPaidVolunteer = false;

  /// Care Provider flow: type (backend value) + optional specialty / org fields.
  String? _careProviderType;
  String? _specialty;
  final _organizationNameController = TextEditingController();
  final _organizationRoleController = TextEditingController();

  bool _uploading = false;
  bool _submitting = false;
  String _lastUploadType = 'id';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    _load();
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _organizationRoleController.dispose();
    super.dispose();
  }

  bool get _isCareProviderFlow {
    final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
    return role != null && AppConstants.isCareProviderRole(role);
  }

  /// Effective type for Care Provider flow. Null when not yet selected (required step).
  String? get _effectiveCareProviderType => _careProviderType;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = await _volunteerService.getMyApplication();
      if (mounted) {
        setState(() {
          _application = app;
          final type = app['careProviderType'] as String?;
          if (type != null && _careProviderTypeValues.contains(type)) {
            _careProviderType = type;
          }
          _specialty = app['specialty'] as String?;
          final orgName = app['organizationName'] as String?;
          final orgRole = app['organizationRole'] as String?;
          if (orgName != null && _organizationNameController.text.isEmpty) {
            _organizationNameController.text = orgName;
          }
          if (orgRole != null && _organizationRoleController.text.isEmpty) {
            _organizationRoleController.text = orgRole;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _documents =>
      _application?['documents'] as List<dynamic>? ?? [];

  String? _fileNameForType(String type) {
    for (final d in _documents) {
      final doc = d as Map<String, dynamic>? ?? {};
      if ((doc['type'] as String? ?? '') == type) {
        return doc['fileName'] as String?;
      }
    }
    return null;
  }

  Future<void> _pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) {
      if (mounted) {
        _showErrorDialog(
          title: 'Fichier non accessible',
          message: 'Le fichier sélectionné n\'est pas accessible sur cet appareil.',
          suggestions: ['Vérifiez les permissions', 'Réessayez avec un autre fichier'],
        );
      }
      return;
    }
    final f = File(path);
    if (!await f.exists()) {
      if (mounted) {
        _showErrorDialog(
          title: 'Fichier introuvable',
          message: 'Le fichier n\'existe plus ou a été déplacé.',
          suggestions: ['Sélectionnez un autre fichier'],
        );
      }
      return;
    }

    final extension = path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp', 'pdf'].contains(extension)) {
      if (mounted) {
        _showErrorDialog(
          title: 'Type de fichier invalide',
          message: 'Le format .$extension n\'est pas accepté.',
          suggestions: ['Formats acceptés : JPG, JPEG, PNG, WebP, PDF'],
        );
      }
      return;
    }

    final size = await f.length();
    if (size > _maxFileSizeBytes) {
      final msg =
          'Fichier trop lourd (${(size / 1024 / 1024).toStringAsFixed(1)} Mo). Max. 5 Mo.';
      setState(() {
        if (type == 'id') _errorId = msg;
        if (type == 'certificate') _errorCertificate = msg;
        if (type == 'other') _errorOther = msg;
      });
      return;
    }

    setState(() {
      if (type == 'id') {
        _fileId = f;
        _errorId = null;
      }
      if (type == 'certificate') {
        _fileCertificate = f;
        _errorCertificate = null;
      }
      if (type == 'other') {
        _fileOther = f;
        _errorOther = null;
      }
    });

    await _uploadDocument(f, type);
  }

  Future<void> _uploadDocument(File file, String type) async {
    setState(() => _uploading = true);
    _lastUploadType = type;
    try {
      await _volunteerService.uploadDocument(file: file, type: type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document enregistré')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          if (type == 'id') _errorId = err;
          if (type == 'certificate') _errorCertificate = err;
          if (type == 'other') _errorOther = err;
        });
        _showErrorDialog(
          title: 'Erreur d\'upload',
          message: err,
          suggestions: [
            'Vérifiez votre connexion',
            'Réessayez avec un autre fichier',
          ],
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showErrorDialog({
    required String title,
    required String message,
    required List<String> suggestions,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ...suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickFile(_lastUploadType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmitCareProvider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir votre type d\'aidant.')),
      );
      return;
    }
    final hasId = _fileId != null || _fileNameForType('id') != null;
    final hasCert = _fileCertificate != null || _fileNameForType('certificate') != null;
    final hasOther = _fileOther != null || _fileNameForType('other') != null;
    if (!hasId && !hasCert && !hasOther) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargez au moins un document (pièce d\'identité recommandée).')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_careProviderType != null) {
        await _volunteerService.updateApplicationMe(
          careProviderType: _careProviderType!,
          specialty: _isHealthcareType(_careProviderType) ? (_specialty ?? _specialties.first) : null,
          organizationName: _isOrganizationLeaderType(_careProviderType)
              ? (_organizationNameController.text.trim().isEmpty ? null : _organizationNameController.text.trim())
              : null,
          organizationRole: _isOrganizationLeaderType(_careProviderType)
              ? (_organizationRoleController.text.trim().isEmpty ? null : _organizationRoleController.text.trim())
              : null,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidature enregistrée. Merci !')),
        );
        context.go(AppConstants.volunteerFormationsRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).user?.role;
    if (AppConstants.isFamilyRole(role)) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'Cette page est réservée aux bénévoles et aidants.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: _textPrimary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppConstants.familyDashboardRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_loading && _application == null) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: _primary),
                const SizedBox(height: 16),
                Text(
                  'Chargement…',
                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final status = _application?['status'] as String? ?? 'pending';
    final deniedReason = _application?['deniedReason'] as String?;

    if (status == 'approved') {
      return _buildStatusScaffold(
        child: _buildApprovedMessage(),
      );
    }
    if (status == 'denied') {
      return _buildStatusScaffold(
        child: _buildDeniedMessage(deniedReason),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCareProviderTypeSection(),
                    if (_showNotSpecialistCheckbox) ...[
                      const SizedBox(height: 16),
                      _buildNotSpecialistCard(),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle(),
                    const SizedBox(height: 16),
                    _buildUploadCard(
                      title: 'Pièce d\'identité',
                      subtitle: 'PDF, JPG ou PNG (max. 5 Mo)',
                      icon: Icons.badge_outlined,
                      file: _fileId,
                      serverFileName: _fileNameForType('id'),
                      error: _errorId,
                      type: 'id',
                    ),
                    const SizedBox(height: 16),
                    _buildUploadCard(
                      title: _documentTitleCertificate(),
                      subtitle: _errorCertificate ?? (_isCaregiverType(_careProviderType) ? 'Formation gratuite incluse dans l\'app' : 'PDF, JPG ou PNG (max. 5 Mo)'),
                      icon: Icons.school_outlined,
                      file: _fileCertificate,
                      serverFileName: _fileNameForType('certificate'),
                      error: _errorCertificate,
                      type: 'certificate',
                      optionalBadge: _isCaregiverType(_careProviderType) ? 'OPTIONNEL' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildUploadCard(
                      title: _documentTitleOther(),
                      subtitle: _documentSubtitleOther(),
                      icon: Icons.description_outlined,
                      file: _fileOther,
                      serverFileName: _fileNameForType('other'),
                      error: _errorOther,
                      type: 'other',
                    ),
                    const SizedBox(height: 24),
                    _buildPaidVolunteerSwitch(),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                    _buildDisclaimer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusScaffold({required Widget child}) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _textSecondary),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppConstants.volunteerFormationsRoute),
        ),
        title: const Text(
          'Candidature',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  Widget _buildApprovedMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
            const SizedBox(height: 16),
            const Text(
              'Votre candidature a été approuvée. Vous pouvez accéder à toutes les fonctionnalités bénévole.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeniedMessage(String? reason) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Candidature refusée',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
              ],
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(reason, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 12),
            const Text(
              'Vous pouvez suivre une formation qualifiante pour postuler à nouveau.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push(AppConstants.coursesRoute),
              icon: const Icon(Icons.school),
              label: const Text('Voir les formations qualifiantes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _textSecondary),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppConstants.volunteerFormationsRoute),
              ),
              const Text(
                'Candidature',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _progressDot(active: true),
              const SizedBox(width: 32),
              _progressDot(active: true),
              const SizedBox(width: 32),
              _progressDot(active: false),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('PROFIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.15, color: _textSecondary)),
              Text('DOCUMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.15, color: _textPrimary)),
              Text('VALIDATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.15, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressDot({required bool active}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _primary : _textSecondary.withOpacity(0.3),
        boxShadow: active
            ? [
                BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 4, spreadRadius: 2),
              ]
            : null,
      ),
    );
  }

  bool get _showNotSpecialistCheckbox =>
      _isCaregiverType(_effectiveCareProviderType);

  /// Type d'aidant requis avant soumission (la section est toujours affichée).
  bool get _canSubmitCareProvider => _careProviderType != null;

  String _profileSubtitle() {
    if (_effectiveCareProviderType == null) {
      return 'Choisissez d\'abord votre type d\'aidant ci-dessus.';
    }
    if (_isHealthcareType(_effectiveCareProviderType)) {
      return 'Veuillez télécharger les documents nécessaires pour valider votre profil de professionnel de santé (diplômes, certifications).';
    }
    if (_isOrganizationLeaderType(_effectiveCareProviderType)) {
      return 'Veuillez télécharger les documents de votre organisation (agréments, attestation de fonction).';
    }
    if (_isCaregiverType(_effectiveCareProviderType)) {
      return 'Veuillez télécharger les documents nécessaires pour valider votre profil d\'aidant (formations, attestations).';
    }
    return 'Veuillez télécharger une pièce d\'identité et tout document complémentaire utile.';
  }

  String _documentTitleCertificate() {
    if (_effectiveCareProviderType == null) return 'Certificat / Diplôme';
    if (_isHealthcareType(_effectiveCareProviderType)) {
      return 'Diplômes / Certifications professionnelles';
    }
    if (_isOrganizationLeaderType(_effectiveCareProviderType)) {
      return 'Documents de l\'organisation';
    }
    if (_isCaregiverType(_effectiveCareProviderType)) {
      return _notSpecialistNoDiploma
          ? 'Attestations de formation (optionnel)'
          : 'Certificat / Diplôme ou attestations de formation';
    }
    return 'Document complémentaire (optionnel)';
  }

  String _documentTitleOther() {
    if (_effectiveCareProviderType == null) return 'Autre document';
    if (_isHealthcareType(_effectiveCareProviderType)) {
      return 'Autre document professionnel';
    }
    if (_isOrganizationLeaderType(_effectiveCareProviderType)) {
      return 'Autre document (statuts, agréments, etc.)';
    }
    if (_isCaregiverType(_effectiveCareProviderType)) {
      return 'Autre document';
    }
    return 'Autre document justificatif';
  }

  String _documentSubtitleOther() {
    if (_effectiveCareProviderType == null) return 'Recommandations, CV, etc.';
    if (_isHealthcareType(_effectiveCareProviderType)) {
      return 'Recommandations, CV, attestations.';
    }
    if (_isOrganizationLeaderType(_effectiveCareProviderType)) {
      return 'Recommandations, CV, etc.';
    }
    if (_isCaregiverType(_effectiveCareProviderType)) {
      return 'Recommandations, CV, attestations de formation.';
    }
    return 'Tout document soutenant votre profil d\'aidant.';
  }

  Widget _buildCareProviderTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'aidant',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Précisez votre domaine d\'expertise ou de bénévolat.',
          style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 26, color: _primary),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _careProviderType,
                    isExpanded: true,
                    hint: Text(
                      'Sélectionner votre rôle...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textSecondary),
                    ),
                    icon: Icon(Icons.unfold_more, color: _textSecondary),
                    items: _careProviderTypeValues.map((type) {
                      final info = _careProviderTypeInfo[type] ?? (label: type, description: null);
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(info.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _careProviderType = v;
                      if (v != null && _isHealthcareType(v) && _specialty == null) {
                        _specialty = _specialties.first;
                      }
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isHealthcareType(_careProviderType)) ...[
          const SizedBox(height: 16),
          const Text('Spécialité', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _specialty ?? _specialties.first,
                isExpanded: true,
                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _specialty = v),
              ),
            ),
          ),
        ],
        if (_isOrganizationLeaderType(_careProviderType)) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _organizationNameController,
            decoration: InputDecoration(
              labelText: 'Nom de l\'organisation',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              filled: true,
              fillColor: _cardBg,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _organizationRoleController,
            decoration: InputDecoration(
              labelText: 'Fonction / Titre',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              filled: true,
              fillColor: _cardBg,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pièces justificatives',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Formats acceptés : PDF, PNG ou JPG.',
                    style: TextStyle(fontSize: 14, color: _textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Max 5 Mo',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _textSecondary, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotSpecialistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Icon(Icons.volunteer_activism_outlined, color: _primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Je ne suis pas un spécialiste',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accédez au programme de formation',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notSpecialistNoDiploma,
                onChanged: (v) => setState(() => _notSpecialistNoDiploma = v),
                activeColor: _primary,
              ),
            ],
          ),
          if (_notSpecialistNoDiploma) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: _primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucun souci ! Nous proposons des formations gratuites dans l\'application pour vous accompagner dans votre parcours de bénévole.',
                      style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    String? serverFileName,
    required String? error,
    required String type,
    String? optionalBadge,
  }) {
    final hasError = error != null && error.isNotEmpty;
    final hasFile = file != null || (serverFileName != null && serverFileName.isNotEmpty);
    final displaySubtitle = hasFile
        ? (file != null ? file.path.split(RegExp(r'[/\\]')).last : serverFileName)
        : subtitle;

    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _uploading ? null : () => _pickFile(type),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasError ? Colors.red.shade200 : const Color(0xFFE2E8F0),
              width: 2,
            ),
            color: hasError ? Colors.red.shade50.withOpacity(0.3) : _cardBg,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasError ? _cardBg : _primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasError ? Icons.error_outline : icon,
                  color: hasError ? Colors.red : _primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary),
                          ),
                        ),
                        if (optionalBadge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              optionalBadge,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.amber.shade700, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displaySubtitle ?? subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasError ? Colors.red : _textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                hasError
                    ? Icons.error
                    : hasFile
                        ? Icons.check_circle
                        : (type == 'other' ? Icons.add_circle_outline : Icons.cloud_upload_outlined),
                color: hasError ? Colors.red : _textSecondary.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaidVolunteerSwitch() {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.payments_outlined, color: Colors.amber.shade700, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Volontaire rémunéré',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                  ),
                  Text(
                    'Selon critères d\'éligibilité',
                    style: TextStyle(fontSize: 11, color: _textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _wantsPaidVolunteer,
              onChanged: (v) => setState(() => _wantsPaidVolunteer = v),
              activeColor: _primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Material(
      color: _primary,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: _primary.withOpacity(0.4),
      child: InkWell(
        onTap: (_submitting || _uploading || !_canSubmitCareProvider) ? null : _submit,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: _submitting || _uploading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Soumettre ma candidature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.5),
          children: [
            const TextSpan(text: 'En soumettant votre profil, vous adhérez à notre '),
            TextSpan(
              text: 'Charte Éthique',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: _primary.withOpacity(0.6),
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
