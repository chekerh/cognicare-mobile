import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Consultation en cours (téléconsultation) : vitals, contrôles appel, tableau blanc. Reçoit consultationId et patientName.
class HealthcareConsultationScreen extends StatelessWidget {
  const HealthcareConsultationScreen({
    super.key,
    this.consultationId,
    this.patientName,
  });

  final String? consultationId;
  final String? patientName;

  static HealthcareConsultationScreen fromState(GoRouterState state) {
    final id = state.uri.queryParameters['consultationId'];
    final name = state.uri.queryParameters['patientName'];
    return HealthcareConsultationScreen(
      consultationId: id,
      patientName: name != null ? Uri.decodeComponent(name) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = patientName ?? 'Famille Bernard (Thomas)';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video area
            Container(
              color: const Color(0xFF1a1a1a),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuD7UK-27_U9qcTh_Yq6CXc8sgxzGWbKfgFrA-ocNeMWLPrjgpvl-k8yNAvTBC--9g9mrQaqd0LTjKyE0-dhEA5W79PYi9kstLJ6ATf-CC3fWaQfQZ_e_lQVLf7AhzwU5jk7DTsPl7DYobMFVSXmDi4bq0OfJMSXMHzz1L9YcPH-PXbJc0dwpngzu5p7Nlc8Ou2qq8K32Ey5-f0y8Md0XTvU8KyWS4cqb29Fqgb5oKVM-qoXBwZLTd_zpTcGtQyauaFVOXMIJuoYpSE',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1a1a1a),
                  child: const Center(
                    child: Icon(Icons.videocam_off, color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'CONSULTATION EN COURS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Vitals
            Positioned(
              top: 80,
              right: 16,
              child: Column(
                children: [
                  _vitalCard(Icons.favorite, '78', 'BPM', Colors.red),
                  const SizedBox(height: 8),
                  _vitalCard(Icons.directions_run, 'Faible', 'Mouv.', _brand),
                  const SizedBox(height: 8),
                  _vitalCard(Icons.air, '98%', 'SpO2', Colors.blue),
                ],
              ),
            ),
            // Self view
            Positioned(
              bottom: 180,
              right: 16,
              child: Container(
                width: 112,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC94yymM621K1w4W6RLwRY5VUqTDh3VPsu9vNicsEVtkRqINVMPXn-z09zSe87BuKOPH7uquq01Y0oC00dRPqaevDPZhSHjozgGa4xKktXWDmHCbrRIcQ_rhVlkqlIUY8Gwan1WFbZdzJmL9ZjuQAn0pPP4IP9vnN8E3aHlD5hDXeBdlp6y6NNDRgOdOkgrQxtvBTHwN-PiTNdN_OuLypgHYbY9QEI-DEUqfou-G197K9CAQ_VmryzesV99ikIThbUAupaOuzxeweM',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF2D7DA1),
                      child: Center(child: Icon(Icons.person, color: Colors.white, size: 48)),
                    ),
                  ),
                ),
              ),
            ),
            // Whiteboard button
            Positioned(
              bottom: 160,
              left: 16,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, color: _brand, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Tableau Blanc Partagé',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Call controls
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(Icons.videocam),
                  _controlButton(Icons.mic),
                  _endCallButton(context),
                  _controlButton(Icons.screen_share),
                  _controlButton(Icons.add_comment, isPrimary: true),
                ],
              ),
            ),
            // Notes FAB
            Positioned(
              bottom: 100,
              right: 16,
              child: Material(
                color: _primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {},
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.sticky_note_2, color: _brand, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalCard(IconData icon, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, {bool isPrimary = false}) {
    return Material(
      color: isPrimary ? _brand : Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _endCallButton(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => context.pop(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: const Icon(Icons.call_end, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
