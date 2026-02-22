import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/reminders_service.dart';
import '../../l10n/app_localizations.dart';

// Couleurs alignées avec le dashboard famille
const Color _primary = Color(0xFFA3D9E5);
const Color _primaryDark = Color(0xFF7BBCCB);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate600 = Color(0xFF475569);

class MedicineVerificationScreen extends StatefulWidget {
  final String reminderId;
  final String taskTitle;
  final String? taskDescription;

  const MedicineVerificationScreen({
    super.key,
    required this.reminderId,
    required this.taskTitle,
    this.taskDescription,
  });

  @override
  State<MedicineVerificationScreen> createState() => _MedicineVerificationScreenState();
}

class _MedicineVerificationScreenState extends State<MedicineVerificationScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _isSubmitting = false;
  Map<String, dynamic>? _verificationResult;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = photo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.photoSelectionError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoRequiredError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );

      // Marquer la tâche comme complétée avec preuve photo
      final result = await remindersService.completeTaskWithProof(
        reminderId: widget.reminderId,
        completed: true,
        date: DateTime.now(),
        proofImagePath: _capturedImage!.path,
      );
      
      debugPrint('Verification Result: $result');

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _verificationResult = result['reminder']?['completionHistory']?.last;
      });

      // Message de succès ou d'avertissement selon le statut AI
      final status = _verificationResult?['verificationStatus'];
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.analysisComplete;
      Color bgColor = Colors.blueGrey;
      
      if (status == 'VALID') {
        message = l10n.verificationSuccessMsg;
        bgColor = Colors.green;
      } else if (status == 'UNCERTAIN') {
        message = l10n.verificationUncertainMsg;
        bgColor = Colors.orange;
      } else if (status == 'INVALID') {
        message = l10n.verificationInvalidMsg;
        bgColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // On ne ferme plus automatiquement (Supprimé Future.delayed)
      // car l'utilisateur veut lire les métadonnées (nom, dosage, expiration)
      // affichées dans la carte de résultat.
      // Il cliquera sur "Fermer" manuellement.
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.unknownError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: _isSubmitting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: _primaryDark),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.verifyingStatus,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Medicine icon with animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899).withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '💊',
                                      style: TextStyle(fontSize: 80),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Title
                          Text(
                            widget.taskTitle,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          if (widget.taskDescription != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.taskDescription!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                  const Row(
                                  children: [
                                    Icon(Icons.camera_alt, color: _primaryDark, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Vérification par photo',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.medicineVerificationInstructions,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInstructionStep(
                                  '1',
                                  AppLocalizations.of(context)!.stepPrepareMedicine,
                                  Icons.medication,
                                ),
                                const SizedBox(height: 8),
                                _buildInstructionStep(
                                  '2',
                                  AppLocalizations.of(context)!.stepTakeWithWater,
                                  Icons.water_drop,
                                ),
                                const SizedBox(height: 8),
                                _buildInstructionStep(
                                  '3',
                                  AppLocalizations.of(context)!.stepTakeSelfie,
                                  Icons.photo_camera,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Photo preview or capture button
                          if (_capturedImage != null)
                            _buildPhotoPreview()
                          else
                            _buildCaptureButton(),
                          
                          const SizedBox(height: 24),
                          
                          if (_capturedImage != null && _verificationResult == null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitVerification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.validateIntakeButton,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          if (_verificationResult != null)
                            _buildAIResultCard(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResultCard() {
    final status = _verificationResult?['verificationStatus'];
    final metadata = _verificationResult?['verificationMetadata'];
    final l10n = AppLocalizations.of(context)!;
    final reasoning = metadata?['reasoning'] ?? l10n.analysisComplete;

    Color color;
    IconData icon;
    String statusTitle;

    switch (status) {
      case 'VALID':
        color = Colors.green;
        icon = Icons.check_circle;
        statusTitle = l10n.verificationFailedTitle; // Actually means Success in the code context above
        break;
      case 'UNCERTAIN':
        color = Colors.orange;
        icon = Icons.warning;
        statusTitle = l10n.verificationUncertainTitle;
        break;
      case 'INVALID':
        color = Colors.red;
        icon = Icons.error;
        statusTitle = l10n.verificationInvalidTitle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        statusTitle = l10n.verificationUnknownStatus;
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            statusTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reasoning,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E293B),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status != 'VALID' && metadata != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMetadataRow(l10n.labelMedicineRead, metadata['medicineName'] ?? l10n.notDetected),
                  const SizedBox(height: 8),
                  _buildMetadataRow(l10n.labelDosage, metadata['dosage'] ?? l10n.notDetected),
                  const SizedBox(height: 8),
                  _buildMetadataRow(l10n.labelExpiration, metadata['expiryDate'] ?? l10n.notVisible),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                status == 'VALID' ? l10n.confirmAndCloseButton : l10n.understoodAndCloseButton,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.medicineVerificationTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 30, color: _primaryDark),
                  ),
                   const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.cameraLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _slate800),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library, size: 30, color: _primaryDark),
                  ),
                   const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.galleryLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _slate800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(_capturedImage!.path),
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retakeButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryDark,
                  side: const BorderSide(color: _primaryDark),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
