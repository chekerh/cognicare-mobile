import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Patient Record — design aligné sur le HTML (Clinical Notes + Hardware).
/// Header blanc, profil Leo Richardson, onglets sticky Analytics / Clinical Notes / Hardware.
const Color _primary = Color(0xFF3994EF);
const Color _textPrimary = Color(0xFF111418);
const Color _textMuted = Color(0xFF617589);
const Color _brandLightBlue = Color(0xFFF0F7FF);
const Color _brandLightBlueHardware = Color(0xFFE0F2FE);
const Color _green = Color(0xFF078838);

class ClinicalPatientRecordScreen extends StatefulWidget {
  const ClinicalPatientRecordScreen({super.key});

  @override
  State<ClinicalPatientRecordScreen> createState() =>
      _ClinicalPatientRecordScreenState();
}

class _ClinicalPatientRecordScreenState
    extends State<ClinicalPatientRecordScreen> {
  int _selectedTab = 0; // 0: Analytics, 1: Clinical Notes, 2: Hardware

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildProfileHero(),
            _buildTabs(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildAnalyticsContent()
                  : _selectedTab == 1
                      ? _buildClinicalNotesContent()
                      : _buildHardwareContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Header blanc : back, titre centré, more_vert (HTML).
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child:
                    Icon(Icons.arrow_back_ios, color: _textPrimary, size: 22),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Patient Record',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: -0.015,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, color: _textPrimary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: _primary.withOpacity(0.1),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: const NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBFc6lI-lkS_dw3NZk-NOK4LgmBlv-PL5zv9j2ddCSeQYL9xPiguHqQvCIM8ejyFK_bFT3QuD0toZkojipCz3ACUPr5SmwnJ8y2paNtyvEG7DzssaQxvcFYEyD1iF2xKhgtEvjHmtJuhfz6Wutb8a7pM_QBu4sBit--d4ZuitIGsATGC4L1LmbzG5O9xxd-KitHDDsx3EeP4E3mCg-r5kFYrTqB_OMUUBDQvTUUGKSUlbTQwmkqaJTS97Zn6HrNy5iDOgkQMuK5IpY',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Leo Richardson',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Age 7',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ID: #LR-2017-09',
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: const Text(
              'Diagnosis: Autism Spectrum Disorder (ASD)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          _tab('Analytics', 0),
          _tab('Clinical Notes', 1),
          _tab('Hardware', 2),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.only(top: 16, bottom: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: active ? _primary : _textMuted,
              letterSpacing: 0.015,
            ),
          ),
        ),
      ),
    );
  }

  /// Onglet Analytics : Cognitive Progress (existant).
  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCognitiveProgress(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Onglet Clinical Notes : fond #f0f7ff, Medical Observations, timeline, Pi footer.
  Widget _buildClinicalNotesContent() {
    return SingleChildScrollView(
      child: Container(
        color: _brandLightBlue,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Observations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 24),
            _buildClinicalNotesTimeline(),
            const SizedBox(height: 24),
            _buildPiFooterClinical(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _clinicalNotes = [
    {
      'tag': 'BEHAVIORAL',
      'tagColor': Color(0xFF2563EB),
      'tagBg': Color(0xFFDBEAFE),
      'date': 'Oct 24, 2023 • 10:45 AM',
      'text':
          'Leo showed improved response time during spatial reasoning games. Distraction levels were significantly lower than the previous session. Responded well to positive reinforcement.',
      'author': 'Dr. Sarah Jenkins',
    },
    {
      'tag': 'MEDICAL',
      'tagColor': Color(0xFF059669),
      'tagBg': Color(0xFFD1FAE5),
      'date': 'Oct 22, 2023 • 02:15 PM',
      'text':
          'Quarterly medication review. Dosage for current prescription remains effective with no reported side effects from the school environment. Appetite remains stable.',
      'author': 'Dr. Michael Chen',
    },
    {
      'tag': 'THERAPY',
      'tagColor': Color(0xFF7C3AED),
      'tagBg': Color(0xFFEDE9FE),
      'date': 'Oct 19, 2023 • 09:00 AM',
      'text':
          'Occupational therapy session. Focused on fine motor skills using tactile materials. Leo was engaged for 25 minutes consecutively, a new milestone for this specific task.',
      'author': 'Elena Rodriguez, OT',
    },
  ];

  Widget _buildClinicalNotesTimeline() {
    return Stack(
      children: [
        Positioned(
          left: 23,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: Colors.grey.shade300,
          ),
        ),
        Column(
          children: List.generate(_clinicalNotes.length, (i) {
            final note = _clinicalNotes[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: note['tagBg'] as Color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  note['tag'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: note['tagColor'] as Color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note['date'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textMuted,
                                  ),
                                ),
                              ),
                              Icon(Icons.more_horiz,
                                  color: Colors.grey.shade400, size: 22),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note['text'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textPrimary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person,
                                      size: 14, color: _textMuted),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  note['author'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _textMuted,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPiFooterClinical() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings_input_component,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raspberry Pi v4 Node',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Clinical sync active',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet Hardware : fond #E0F2FE, Device Health, Sleep, HRV, Pi détail.
  Widget _buildHardwareContent() {
    return SingleChildScrollView(
      child: Container(
        color: _brandLightBlueHardware,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceHealthSection(),
            const SizedBox(height: 24),
            _buildSleepCyclesCard(),
            const SizedBox(height: 24),
            _buildHrvCard(),
            const SizedBox(height: 24),
            _buildPiFooterHardware(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Device Health',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CONNECTED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _hardwareMetricCard(
                icon: Icons.battery_5_bar,
                label: 'Battery Life',
                value: '84%',
                sub: 'HEALTHY',
                subColor: _green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _hardwareMetricCard(
                icon: Icons.wifi,
                label: 'Signal Strength',
                value: '-54',
                valueSuffix: ' dBm',
                sub: 'EXCELLENT',
                subColor: _primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hardwareMetricCard({
    required IconData icon,
    required String label,
    required String value,
    String? valueSuffix,
    required String sub,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 32),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              if (valueSuffix != null)
                Text(
                  valueSuffix,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCyclesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SLEEP CYCLES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Deep Sleep: 3h 45m',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 16, color: _primary),
                    SizedBox(width: 4),
                    Text(
                      'Past 24h',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _SleepBarChartPainter(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _brandLightBlueHardware,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIGHT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DEEP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
              const Text(
                '11PM - 7AM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHrvCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEART RATE VARIABILITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '48 ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        'ms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 16, color: _green),
                        SizedBox(width: 4),
                        Text(
                          '+5.2%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'WEEKLY AVG',
                    style: TextStyle(
                      fontSize: 10,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _HrvLineChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MON',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textMuted)),
              Text('WED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textMuted)),
              Text('FRI',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _textMuted)),
              Text('TODAY',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPiFooterHardware() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.memory, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raspberry Pi v4 Node',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Firmware: v2.4.1 (Stable)',
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _primary.withOpacity(0.1))),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CPU Temp',
                          style: TextStyle(fontSize: 12, color: _textMuted)),
                      Text('42°C',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Latency',
                          style: TextStyle(fontSize: 12, color: _textMuted)),
                      Text('24ms',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Data Rate',
                        style: TextStyle(fontSize: 12, color: _textMuted)),
                    Text('128 kbps',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Uptime',
                        style: TextStyle(fontSize: 12, color: _textMuted)),
                    Text('14d 6h',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCognitiveProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cognitive Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE SYNC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ATTENTION & FOCUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                          children: [
                            TextSpan(text: '82'),
                            TextSpan(
                              text: '/100',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up, size: 16, color: _green),
                            SizedBox(width: 4),
                            Text(
                              '+12%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'MONTHLY TREND',
                        style: TextStyle(
                          fontSize: 10,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _ChartPainter(),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('W1',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _textMuted)),
                  Text('W2',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _textMuted)),
                  Text('CURRENT',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _primary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bar chart sommeil (LIGHT / DEEP) — aligné sur le SVG HTML.
class _SleepBarChartPainter extends CustomPainter {
  static const Color _primary = Color(0xFF3994EF);
  static const Color _light = Color(0xFFE0F2FE);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const gap = 8.0;
    const rx = 4.0;
    // Barres approximatives comme dans le HTML (LIGHT / DEEP alternées)
    final segments = [
      (20.0, 80.0, _light),
      (40.0, 40.0, _primary),
      (25.0, 70.0, _light),
      (50.0, 50.0, _primary),
      (28.0, 72.0, _light),
      (55.0, 30.0, _primary),
    ];
    var x = 8.0;
    for (final s in segments) {
      final (width, height, color) = s;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h - height, width.clamp(20.0, w - 16), height),
        const Radius.circular(rx),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      x += width + gap;
      if (x > w - 20) break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Courbe HRV (ligne + dégradé sous la courbe).
class _HrvLineChartPainter extends CustomPainter {
  static const Color _primary = Color(0xFF3994EF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pts = [0.6, 0.55, 0.65, 0.45, 0.5, 0.4, 0.42, 0.35, 0.38, 0.3, 0.32];
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = (i / (pts.length - 1)) * w;
      final y = pts[i] * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = _primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_primary.withOpacity(0.15), _primary.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartPainter extends CustomPainter {
  static const Color _primary = Color(0xFF3994EF);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * 0.73);
    path.lineTo(w * 0.08, h * 0.14);
    path.lineTo(w * 0.23, h * 0.27);
    path.lineTo(w * 0.38, h * 0.62);
    path.lineTo(w * 0.54, h * 0.22);
    path.lineTo(w * 0.69, h * 0.67);
    path.lineTo(w * 0.85, h * 0.08);
    path.lineTo(w, h * 0.07);
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _primary.withOpacity(0.2),
          _primary.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
