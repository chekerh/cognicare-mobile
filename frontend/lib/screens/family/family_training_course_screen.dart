import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/training_cache_provider.dart';
import '../../services/training_service.dart';

// Aligné sur le HTML Premium : primary #3fb1c1, gradient, cards style iOS
const Color _primary = Color(0xFF3fb1c1);
const Color _secondary = Color(0xFFa3dae1);
const Color _bgLight = Color(0xFFf8fdfe);
const Color _slate800 = Color(0xFF1e293b);
const Color _slate600 = Color(0xFF475569);
const Color _slate400 = Color(0xFF94A3B8);

/// Course content: premium UI with header, progress bar, content cards, "Commencer le quiz" CTA.
class FamilyTrainingCourseScreen extends StatefulWidget {
  const FamilyTrainingCourseScreen({
    super.key,
    required this.courseId,
    this.title = 'Cours',
    this.moduleLabel,
  });

  final String courseId;
  final String title;
  /// Optional e.g. "Module 1" for header
  final String? moduleLabel;

  @override
  State<FamilyTrainingCourseScreen> createState() =>
      _FamilyTrainingCourseScreenState();
}

class _FamilyTrainingCourseScreenState extends State<FamilyTrainingCourseScreen> {
  final TrainingService _service = TrainingService();
  Map<String, dynamic>? _course;
  bool _loading = true;
  String? _error;
  bool _markingComplete = false;

  String get _courseId => widget.courseId;
  String get _title => widget.title;
  String get _moduleLabel => widget.moduleLabel ?? 'Module 1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = _courseId;
    if (id.isEmpty) {
      setState(() => _error = 'Cours inconnu');
      return;
    }
    final cache = Provider.of<TrainingCacheProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _error = null;
      _course = cache.getCachedCourse(id);
    });
    if (_course != null) setState(() => _loading = false);
    try {
      final course = await cache.getCourse(id);
      if (mounted) {
        setState(() {
          _course = course;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  bool get _hasQuiz {
    final q = _course?['quiz'];
    return q is List<dynamic> && q.isNotEmpty;
  }

  /// Progress 0.0..1.0 (affiché à 35% avant quiz, ou selon progression réelle si dispo)
  double get _progress => 0.35;

  Future<void> _onContinue() async {
    final id = _courseId;
    if (id.isEmpty || !_hasQuiz) return;
    setState(() => _markingComplete = true);
    try {
      await _service.markContentCompleted(id);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        final isUnauthorized = msg.toLowerCase().contains('unauthorized') ||
            msg.toLowerCase().contains('session expirée');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUnauthorized
                  ? 'Reconnectez-vous pour enregistrer votre progression.'
                  : msg,
            ),
            backgroundColor: isUnauthorized ? Colors.orange.shade700 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _markingComplete = false);
    final path = GoRouterState.of(context).uri.path;
    final quizPath = path.replaceFirst(RegExp(r'/course$'), '/quiz');
    final extra = <String, dynamic>{
      'courseId': id,
      'title': _title,
    };
    final quiz = _course?['quiz'];
    if (quiz is List<dynamic> && quiz.isNotEmpty) {
      extra['quiz'] = quiz;
    }
    context.push(quizPath, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bgLight,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: _slate800)))
              : Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(topPadding)),
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFf0f9fa),
                                  Color(0xFFa3dae1),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_course?['description'] != null &&
                                    (_course!['description'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Text(
                                      _course!['description'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: _slate600,
                                      ),
                                    ),
                                  ),
                                ..._buildSectionCards(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24 + bottomPadding,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildContinueButton(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.chevron_left, color: _slate800, size: 28),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _moduleLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 200,
                        child: Text(
                          _title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _slate800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.more_horiz, color: _slate400, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionCards() {
    final rawSections = _course?['contentSections'];
    final sections = rawSections is List<dynamic> ? rawSections : <dynamic>[];
    final list = <Widget>[];
    final sectionIcons = [
      Icons.psychology,
      Icons.auto_awesome_motion,
      Icons.lightbulb_outline,
      Icons.menu_book,
      Icons.favorite_border,
    ];
    for (var i = 0; i < sections.length; i++) {
      final item = sections[i];
      if (item is! Map<String, dynamic>) continue;
      final s = item;
      final title = s['title'] as String?;
      final content = s['content'] as String?;
      final rawListItems = s['listItems'];
      final listItems = rawListItems is List<dynamic> ? rawListItems : null;
      final premiumTip = s['premiumTip'] as String? ?? s['tip'] as String?;
      final videoUrl = s['videoUrl'] as String?;
      final rawDefs = s['definitions'];
      final definitionsMap = rawDefs is Map<String, dynamic> ? rawDefs : null;
      final definitionsList = rawDefs is List<dynamic> ? rawDefs : null;

      final hasTitle = title != null && title.isNotEmpty;
      final hasContent = content != null && content.isNotEmpty;
      final hasList = listItems != null && listItems.isNotEmpty;
      final hasTip = premiumTip != null && premiumTip.isNotEmpty;
      final hasDefs = (definitionsMap != null && definitionsMap.isNotEmpty) ||
          (definitionsList != null && definitionsList.isNotEmpty);
      final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

      if (!hasTitle && !hasContent && !hasList && !hasTip && !hasDefs && !hasVideo) continue;

      final icon = sectionIcons[i % sectionIcons.length];
      list.add(
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: _primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _slate800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasContent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    content!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: _slate600,
                    ),
                  ),
                ),
              if (hasList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: listItems!
                        .map<Widget>((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, color: _primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _slate600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (hasTip)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: _primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CONSEIL PREMIUM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        premiumTip!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _slate600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasDefs) ...[
                if (definitionsMap != null)
                  ...definitionsMap.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: _slate600, height: 1.5),
                          children: [
                            TextSpan(
                              text: '${e.key}: ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: _slate800),
                            ),
                            TextSpan(text: e.value.toString()),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (definitionsList != null)
                  for (final item in definitionsList)
                    if (item is Map<String, dynamic>) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 15, color: _slate600, height: 1.5),
                            children: [
                              TextSpan(
                                text: '${item['term'] ?? item['key'] ?? ''}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _slate800,
                                ),
                              ),
                              TextSpan(
                                text: (item['definition'] ?? item['value'] ?? item['def'] ?? '').toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
              ],
              if (hasVideo)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Icon(Icons.video_library, color: _primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            videoUrl!,
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    if (list.isEmpty) {
      list.add(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'Contenu à venir.',
            style: TextStyle(color: _slate600, fontSize: 15),
          ),
        ),
      );
    }
    return list;
  }

  Widget _buildContinueButton() {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: _primary.withOpacity(0.4),
      color: _primary,
      child: InkWell(
        onTap: (_markingComplete || !_hasQuiz) ? null : _onContinue,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: _markingComplete
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hasQuiz ? 'Commencer le quiz' : 'Quiz à venir',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}
