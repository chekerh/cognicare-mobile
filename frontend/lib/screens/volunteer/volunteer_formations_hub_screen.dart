import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/courses_service.dart';
import '../../services/training_service.dart';
import '../../services/volunteer_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFa3dae1);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);

/// Volunteer Service Hub - Formations: first screen after volunteer login.
/// Sections: Formation en cours, Catalogue, Mes Certifications.
class VolunteerFormationsHubScreen extends StatefulWidget {
  const VolunteerFormationsHubScreen({super.key});

  @override
  State<VolunteerFormationsHubScreen> createState() =>
      _VolunteerFormationsHubScreenState();
}

class _VolunteerFormationsHubScreenState
    extends State<VolunteerFormationsHubScreen> {
  final CoursesService _coursesService = CoursesService();
  final VolunteerService _volunteerService = VolunteerService();
  final TrainingService _trainingService = TrainingService();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrollments = [];
  List<Map<String, dynamic>> _trainingCourses = [];
  Map<String, dynamic>? _application;
  bool _loading = true;
  String? _error;
  bool _catalogQualificationOnly = false;
  String? _catalogCourseType;
  bool _catalogHasCertification = false;
  bool _insightsLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _coursesService.getCourses(
          qualificationOnly: _catalogQualificationOnly,
          courseType: _catalogCourseType,
          hasCertification: _catalogHasCertification,
        ),
        _coursesService.myEnrollments(),
        _volunteerService.getMyApplication(),
      ]);
      List<Map<String, dynamic>> trainingList = [];
      try {
        trainingList = await _trainingService.getCourses();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _courses = results[0] as List<Map<String, dynamic>>;
          _enrollments = results[1] as List<Map<String, dynamic>>;
          _application = results[2] as Map<String, dynamic>?;
          _trainingCourses = trainingList;
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

  bool get _trainingCertified =>
      _application?['trainingCertified'] == true;

  bool get _hasCompletedQualificationCourse {
    for (final e in _enrollments) {
      final status = e['status'] as String?;
      final progress = (e['progressPercent'] as num?)?.toInt() ?? 0;
      final course = e['course'] as Map<String, dynamic>?;
      final isQualif = course?['isQualificationCourse'] == true;
      if (isQualif && status == 'completed' && progress >= 100) return true;
    }
    return false;
  }

  bool _isEnrolled(String courseId) {
    return _enrollments.any((e) => e['courseId'] == courseId);
  }

  /// First in-progress or enrolled (not completed) enrollment for "Formation en cours".
  Map<String, dynamic>? get _courseInProgress {
    for (final e in _enrollments) {
      final status = e['status'] as String?;
      final progress = (e['progressPercent'] as num?)?.toInt() ?? 0;
      if (status != 'completed' && progress < 100) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _primary,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildCourseInProgress()),
                        SliverToBoxAdapter(child: _buildCertificationTestCard()),
                        SliverToBoxAdapter(child: _buildAiInsightsCard()),
                        SliverToBoxAdapter(child: _buildAutismTrainingSection()),
                        SliverToBoxAdapter(child: _buildCatalogSection()),
                        SliverToBoxAdapter(
                            child: _buildCertificationsSection()),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Volunteer Service Hub',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.code, color: _textSecondary, size: 22),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'Formations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.school_rounded, color: _primary, size: 28),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Développez vos compétences d\'accompagnement.',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInProgress() {
    final enrollment = _courseInProgress;
    if (enrollment == null) {
      return const SizedBox.shrink();
    }

    final course = enrollment['course'] as Map<String, dynamic>?;
    final title = course?['title'] as String? ?? 'Formation';
    final progress = (enrollment['progressPercent'] as num?)?.toInt() ?? 0;
    const moduleCount = 5;
    final currentModule = (progress / 20).ceil().clamp(1, moduleCount);
    const moduleLabels = [
      'Introduction',
      'Fondements',
      'Pratique',
      'Interactions sociales',
      'Conclusion',
    ];
    final moduleLabel = currentModule <= moduleLabels.length
        ? moduleLabels[currentModule - 1]
        : 'Module $currentModule';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'FORMATION EN COURS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.psychology_outlined,
                          color: _primary, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Module $currentModule sur $moduleCount : $moduleLabel',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: _primary.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress% COMPLÉTÉ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationTestCard() {
    if (_trainingCertified) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Certification obtenue. Accès Agenda et Messages débloqué.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_hasCompletedQualificationCourse) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Material(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          child: InkWell(
            onTap: () => context.push(AppConstants.volunteerCertificationTestRoute),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.quiz, color: _primary, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test de certification',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Formation qualifiante terminée. Passez le test pour débloquer Agenda et Messages.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: _textSecondary),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showAiInsights() async {
    if (_insightsLoading) return;
    setState(() => _insightsLoading = true);
    try {
      final data = await _volunteerService.getCertificationTestInsights();
      if (!mounted) return;
      final summary = data['summary'] as String? ?? '';
      final recs = data['recommendations'] as List<dynamic>? ?? [];
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: _cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _primary, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Recommandations personnalisées',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 15,
                  color: _textPrimary,
                  height: 1.4,
                ),
              ),
              if (recs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'À faire :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...recs.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: _primary)),
                          Expanded(
                            child: Text(
                              r is String ? r : '$r',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _insightsLoading = false);
    }
  }

  Widget _buildAiInsightsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.04),
        child: InkWell(
          onTap: _insightsLoading ? null : _showAiInsights,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _insightsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: _primary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, color: _primary, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommandations AI',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _insightsLoading
                            ? 'Chargement...'
                            : 'Voir votre résumé et conseils personnalisés',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_insightsLoading)
                  const Icon(Icons.chevron_right, color: _textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section "Formation Autisme" — cours issus du module Training (contenu scrapé, approuvé).
  Widget _buildAutismTrainingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Formation Autisme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              if (_trainingCourses.isNotEmpty)
                TextButton(
                  onPressed: () => context.push(AppConstants.volunteerTrainingRoute),
                  child: const Text('Voir tout', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Cours pour aidants (sources officielles : WHO, TEACCH, NAS, etc.)',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 12),
          if (_trainingCourses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Aucun cours disponible pour le moment. Les formations seront ajoutées après validation par les professionnels.',
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),
            )
          else
            ..._trainingCourses.take(3).map((c) {
              final id = c['id'] as String? ?? '';
              final title = c['title'] as String? ?? 'Cours';
              final desc = c['description'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.04),
                  child: InkWell(
                    onTap: () => context.push(
                      AppConstants.volunteerTrainingCourseRoute,
                      extra: {'courseId': id, 'title': title},
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school_rounded, color: _primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary,
                                  ),
                                ),
                                if (desc != null && desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    desc.length > 80 ? '${desc.substring(0, 80)}...' : desc,
                                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: _textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCatalogSection() {
    const catalogItems = [
      (
        'Communication non-verbale',
        Icons.chat_bubble_outline,
        '15 min',
        'Débutant',
        Color(0xFF3B82F6)
      ),
      (
        'Gestion des crises sensorielles',
        Icons.flash_on_outlined,
        '25 min',
        'Avancé',
        Color(0xFFF59E0B)
      ),
      (
        'Activités ludiques adaptées',
        Icons.extension_outlined,
        '20 min',
        'Intermédiaire',
        Color(0xFF8B5CF6)
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catalogue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Tous'),
                selected: !_catalogQualificationOnly,
                onSelected: (selected) {
                  if (selected && _catalogQualificationOnly) {
                    setState(() => _catalogQualificationOnly = false);
                    _load();
                  }
                },
                selectedColor: _primary.withOpacity(0.3),
              ),
              ChoiceChip(
                label: const Text('Qualifiantes'),
                selected: _catalogQualificationOnly,
                onSelected: (selected) {
                  if (selected && !_catalogQualificationOnly) {
                    setState(() => _catalogQualificationOnly = true);
                    _load();
                  }
                },
                selectedColor: _primary.withOpacity(0.3),
              ),
              ChoiceChip(
                label: const Text('Avec certification'),
                selected: _catalogHasCertification,
                onSelected: (selected) {
                  if (selected != _catalogHasCertification) {
                    setState(() => _catalogHasCertification = selected);
                    _load();
                  }
                },
                selectedColor: _primary.withOpacity(0.3),
              ),
              ChoiceChip(
                label: const Text('Débutant'),
                selected: _catalogCourseType == 'basic',
                onSelected: (selected) {
                  if (selected && _catalogCourseType != 'basic') {
                    setState(() => _catalogCourseType = 'basic');
                    _load();
                  } else if (!selected && _catalogCourseType == 'basic') {
                    setState(() => _catalogCourseType = null);
                    _load();
                  }
                },
                selectedColor: _primary.withOpacity(0.3),
              ),
              ChoiceChip(
                label: const Text('Avancé'),
                selected: _catalogCourseType == 'advanced',
                onSelected: (selected) {
                  if (selected && _catalogCourseType != 'advanced') {
                    setState(() => _catalogCourseType = 'advanced');
                    _load();
                  } else if (!selected && _catalogCourseType == 'advanced') {
                    setState(() => _catalogCourseType = null);
                    _load();
                  }
                },
                selectedColor: _primary.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._courses.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final id = c['id'] as String? ?? '';
            final title = c['title'] as String? ?? 'Cours';
            final fallback = catalogItems[i % catalogItems.length];
            final duration = fallback.$3;
            final difficulty = fallback.$4;
            final iconColor = fallback.$5;
            final icon = fallback.$2;
            final enrolled = _isEnrolled(id);
            final List<String> parts = [];
            if (c['location'] != null && (c['location'] as String).isNotEmpty) parts.add(c['location'] as String);
            if (c['price'] != null && (c['price'] as String).isNotEmpty) parts.add(c['price'] as String);
            if (c['startDate'] != null) {
              try {
                final d = DateTime.parse(c['startDate'] as String);
                parts.add('${d.day}/${d.month}/${d.year}');
              } catch (_) {}
            }
            final subtitle = parts.isEmpty ? null : parts.join(' · ');
            return _CatalogCard(
              title: title,
              duration: duration,
              difficulty: difficulty,
              icon: icon,
              iconColor: iconColor,
              enrolled: enrolled,
              subtitle: subtitle,
              onTap: () => context.push(AppConstants.coursesRoute),
            );
          }),
          if (_courses.isEmpty)
            ...catalogItems.map((item) => _CatalogCard(
                  title: item.$1,
                  duration: item.$3,
                  difficulty: item.$4,
                  icon: item.$2,
                  iconColor: item.$5,
                  enrolled: false,
                  onTap: () => context.push(AppConstants.coursesRoute),
                )),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection() {
    const certs = [
      ('Mentor Niveau 1', Icons.star_rounded, Color(0xFFFBBF24), true),
      (
        'Inclusion Sociale',
        Icons.check_circle_rounded,
        Color(0xFF22C55E),
        true
      ),
      ('Expert Cognitif', Icons.lock_outline, Color(0xFF94A3B8), false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes Certifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: certs
                .map((c) => _CertificationBadge(c.$1, c.$2, c.$3, c.$4))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final String title;
  final String duration;
  final String difficulty;
  final IconData icon;
  final Color iconColor;
  final bool enrolled;
  final String? subtitle;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.icon,
    required this.iconColor,
    required this.enrolled,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.04),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            duration,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              difficulty,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: _textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificationBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const _CertificationBadge(this.label, this.icon, this.color, this.unlocked);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: unlocked ? color.withOpacity(0.2) : color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked ? color : color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: unlocked ? color : color.withOpacity(0.6),
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
