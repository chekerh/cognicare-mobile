import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/courses_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFF3B82F6);
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
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;
  String? _error;

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
      final courses = await _coursesService.getCourses(qualificationOnly: false);
      final enrollments = await _coursesService.myEnrollments();
      if (mounted) {
        setState(() {
          _courses = courses;
          _enrollments = enrollments;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                        SliverToBoxAdapter(child: _buildCatalogSection()),
                        SliverToBoxAdapter(child: _buildCertificationsSection()),
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
              child: Text(AppLocalizations.of(context)!.retryButton),
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
              Text(
                AppLocalizations.of(context)!.volunteerServiceHub,
                style: const TextStyle(
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
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.formationsLabel,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.school_rounded, color: _primary, size: 28),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.developSkillsSubtitle,
            style: const TextStyle(
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_outlined, color: _primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.noFormationInProgress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final course = enrollment['course'] as Map<String, dynamic>?;
    final title = course?['title'] as String? ?? 'Formation';
    final progress = (enrollment['progressPercent'] as num?)?.toInt() ?? 0;
    const moduleCount = 5;
    final currentModule = (progress / 20).ceil().clamp(1, moduleCount);
    final moduleLabels = [
      AppLocalizations.of(context)!.introModule,
      AppLocalizations.of(context)!.foundationModule,
      AppLocalizations.of(context)!.practiceModule,
      AppLocalizations.of(context)!.socialInteractionsModule,
      AppLocalizations.of(context)!.conclusionModule,
    ];
    final moduleLabel =
        currentModule <= moduleLabels.length
            ? moduleLabels[currentModule - 1]
            : 'Module $currentModule';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.formationInProgress,
              style: const TextStyle(
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
                            AppLocalizations.of(context)!.moduleProgressLabel(currentModule, moduleCount, moduleLabel),
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
                  AppLocalizations.of(context)!.completedPercent(progress),
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

  Widget _buildCatalogSection() {
    final l = AppLocalizations.of(context)!;
    final catalogItems = [
      (AppLocalizations.of(context)!.nonVerbalCommunication, Icons.chat_bubble_outline, '15 min',
          l.beginnerLevel, const Color(0xFF3B82F6)),
      (AppLocalizations.of(context)!.sensoryCrisisManagement, Icons.flash_on_outlined, '25 min',
          l.advancedLevel, const Color(0xFFF59E0B)),
      (AppLocalizations.of(context)!.adaptedPlayActivities, Icons.extension_outlined, '20 min',
          l.intermediateLevel, const Color(0xFF8B5CF6)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.catalogueLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 18, color: _primary),
                label: Text(
                  AppLocalizations.of(context)!.filterLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
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
            return _CatalogCard(
              title: title,
              duration: duration,
              difficulty: difficulty,
              icon: icon,
              iconColor: iconColor,
              enrolled: enrolled,
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
    final l = AppLocalizations.of(context)!;
    final certs = [
      (l.mentorLevel1, Icons.star_rounded, const Color(0xFFFBBF24), true),
      (l.socialInclusion, Icons.check_circle_rounded, const Color(0xFF22C55E),
          true),
      (l.cognitiveExpert, Icons.lock_outline, const Color(0xFF94A3B8), false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.myCertifications,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: certs.map((c) => _CertificationBadge(c.$1, c.$2, c.$3, c.$4)).toList(),
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
  final VoidCallback onTap;

  const _CatalogCard({
    required this.title,
    required this.duration,
    required this.difficulty,
    required this.icon,
    required this.iconColor,
    required this.enrolled,
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
                const Icon(Icons.arrow_forward_ios, size: 14, color: _textSecondary),
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
