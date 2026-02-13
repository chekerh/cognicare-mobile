import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/reminders_service.dart';

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

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
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
            content: Text('Erreur lors de la capture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez prendre une photo pour vérifier'),
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
      await remindersService.completeTaskWithProof(
        reminderId: widget.reminderId,
        completed: true,
        date: DateTime.now(),
        proofImagePath: _capturedImage!.path,
      );

      if (!mounted) return;

      // Message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Médicament vérifié ! Bravo !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Retour avec succès
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
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
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: _primaryDark),
                          SizedBox(height: 16),
                          Text(
                            'Vérification en cours...',
                            style: TextStyle(
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
                                  'Pour confirmer que tu as pris tes médicaments, prends une photo de toi en train de les prendre.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInstructionStep(
                                  '1',
                                  'Prépare tes médicaments',
                                  Icons.medication,
                                ),
                                const SizedBox(height: 8),
                                _buildInstructionStep(
                                  '2',
                                  'Prends-les avec de l\'eau',
                                  Icons.water_drop,
                                ),
                                const SizedBox(height: 8),
                                _buildInstructionStep(
                                  '3',
                                  'Prends une photo (selfie)',
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
                          
                          // Submit button
                          if (_capturedImage != null)
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
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Valider la prise',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
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
          const Expanded(
            child: Text(
              'Vérification Médicament',
              style: TextStyle(
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
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _primary,
            width: 2,
            style: BorderStyle.solid,
          ),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child:                 const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: _primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prendre une photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez pour ouvrir l\'appareil photo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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
                onPressed: _capturePhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Reprendre'),
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
