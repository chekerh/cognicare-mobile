import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart' as app_user;
import '../../providers/auth_provider.dart';
import '../../services/healthcare_service.dart';
import '../../services/children_service.dart';
import '../../services/volunteer_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFa3dae1);

String _fullImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}

String _roleToSpecializationLabel(String role) {
  switch (role) {
    case 'doctor':
      return 'Médecin';
    case 'psychologist':
      return 'Pédopsychiatre / Psychologue';
    case 'speech_therapist':
      return 'Orthophoniste';
    case 'occupational_therapist':
      return 'Ergothérapeute';
    default:
      return role;
  }
}

/// Tableau de bord bénévole — Points Impact, Missions, Compétences, Professionnels de santé (contact), Planning.
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  List<app_user.User>? _healthcareUsers;
  bool _healthcareLoading = false;
  String? _healthcareError;

  List<ChildModel>? _children;
  bool _childrenLoading = false;
  String? _childrenError;

  bool _showQuickMenu = false;
  Map<String, dynamic>? _application;
  bool _applicationLoading = true;

  Future<void> _loadApplication() async {
    try {
      final app = await VolunteerService().getMyApplication();
      if (mounted) setState(() {
        _application = app;
        _applicationLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _applicationLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadApplication();
    _loadHealthcare();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (AppConstants.isSpecialistRole(user?.role)) {
      _loadChildren();
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      _childrenLoading = true;
      _childrenError = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final list =
          await ChildrenService(getToken: () async => authProvider.accessToken)
              .getOrganizationChildren();
      if (!mounted) return;
      setState(() {
        _children = list;
        _childrenLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _childrenError = e.toString().replaceFirst('Exception: ', '');
        _childrenLoading = false;
      });
    }
  }

  Future<void> _loadHealthcare() async {
    setState(() {
      _healthcareLoading = true;
      _healthcareError = null;
    });
    try {
      final list = await HealthcareService().getHealthcareProfessionals();
      if (!mounted) return;
      setState(() {
        _healthcareUsers = list;
        _healthcareLoading = false;
        _healthcareError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthcareUsers = null;
        _healthcareLoading = false;
        _healthcareError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget _buildApprovalPendingContent(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty,
                    size: 64, color: _primary.withOpacity(0.7)),
                const SizedBox(height: 24),
                Text(
                  loc.volunteerApprovalPendingTitle,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.volunteerApprovalPendingMessage,
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push(AppConstants.volunteerApplicationRoute),
                  icon: const Icon(Icons.description_outlined, size: 20),
                  label: Text(loc.volunteerApprovalPendingGoToApplication),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _application?['status'] == 'approved';
    if (!_applicationLoading && !isApproved) {
      return _buildApprovalPendingContent(context);
    }
    final user = Provider.of<AuthProvider>(context).user;
    final userRole = user?.role;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            top: true,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildPlanningSection(context)),
                      SliverToBoxAdapter(child: _buildStatsCards()),
                      SliverToBoxAdapter(child: _buildSkillsSection(context)),
                      if (AppConstants.isSpecialistRole(userRole))
                        SliverToBoxAdapter(child: _buildPatientsSection(context)),
                      SliverToBoxAdapter(child: _buildHealthcareSection(context)),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showQuickMenu)
            GestureDetector(
              onTap: () => setState(() => _showQuickMenu = false),
              child: Container(
                color: Colors.white.withOpacity(0.1),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          if (_showQuickMenu)
            Positioned(
              bottom: 100,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _quickActionRow(context, 'Rapport de Mission', Icons.description, () {
                    setState(() => _showQuickMenu = false);
                    context.push(AppConstants.volunteerMissionReportRoute);
                  }),
                  const SizedBox(height: 24),
                  _quickActionRow(context, 'Proposer Aide', Icons.favorite_border, () {
                    setState(() => _showQuickMenu = false);
                    context.push(AppConstants.volunteerOfferHelpRoute);
                  }),
                  const SizedBox(height: 24),
                  _quickActionRow(context, 'Nouvelle Disponibilité', Icons.event_available, () {
                    setState(() => _showQuickMenu = false);
                    context.push(AppConstants.volunteerNewAvailabilityRoute);
                  }),
                  const SizedBox(height: 20),
                  Material(
                    color: _primary,
                    borderRadius: BorderRadius.circular(999),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => setState(() => _showQuickMenu = false),
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.close, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickActionRow(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: Icon(icon, color: _primary, size: 26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes Patients',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          if (_childrenLoading)
            const Center(child: CircularProgressIndicator())
          else if (_childrenError != null)
            Text('Erreur: $_childrenError',
                style: const TextStyle(color: Colors.red))
          else if (_children == null || _children!.isEmpty)
            Text(
              'Aucun patient trouvé dans votre organisation.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _children!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final child = _children![index];
                return _buildPatientCard(context, child);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, ChildModel child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _primary.withOpacity(0.1),
            child: const Icon(Icons.child_care, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'DN: ${child.dateOfBirth}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.star,
              iconColor: _primary,
              label: 'Points Impact',
              value: '1,250',
              bgColor: _primary.withOpacity(0.1),
              borderColor: _primary.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => context.go(AppConstants.volunteerMissionsRoute),
              borderRadius: BorderRadius.circular(16),
              child: _statCard(
                icon: Icons.volunteer_activism,
                iconColor: Colors.green.shade600,
                label: 'Missions',
                value: '24',
                bgColor: Colors.green.shade50,
                borderColor: Colors.green.shade100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final skills = [
      (Icons.psychology, Colors.amber.shade500, Colors.amber.shade100, 'TDAH'),
      (
        Icons.palette,
        Colors.blue.shade500,
        Colors.blue.shade100,
        'Art Thérapie'
      ),
      (
        Icons.menu_book,
        Colors.purple.shade500,
        Colors.purple.shade100,
        'Lecture'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mes Compétences',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () {},
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: skills.length,
              itemBuilder: (context, i) {
                final s = skills[i];
                return Container(
                  width: 128,
                  margin:
                      EdgeInsets.only(right: i < skills.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration:
                            BoxDecoration(color: s.$3, shape: BoxShape.circle),
                        child: Icon(s.$1, color: s.$2, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(s.$4,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthcareSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professionnels de santé',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacter un expert pour échanger ou poser vos questions.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (_healthcareLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_healthcareError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(_healthcareError!,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: _loadHealthcare,
                      child: const Text('Réessayer')),
                ],
              ),
            )
          else if (_healthcareUsers == null || _healthcareUsers!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucun professionnel pour le moment.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            )
          else
            ...List.generate(_healthcareUsers!.length * 2 - 1, (i) {
              if (i.isOdd) return const SizedBox(height: 16);
              return _healthcareContactCard(context, _healthcareUsers![i ~/ 2]);
            }),
        ],
      ),
    );
  }

  Widget _healthcareContactCard(BuildContext context, app_user.User user) {
    final imageUrl = (user.profilePic != null && user.profilePic!.isNotEmpty)
        ? _fullImageUrl(user.profilePic!)
        : '';
    final specialization = _roleToSpecializationLabel(user.role);
    const size = 40.0;
    final avatar = imageUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _avatarPlaceholder(size, user.fullName),
            ),
          )
        : _avatarPlaceholder(size, user.fullName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('CogniCare',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    specialization,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _primary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            specialization,
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade700, height: 1.5),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  shadowColor: _primary.withOpacity(0.3),
                  child: InkWell(
                    onTap: () {
                      final uri = Uri(
                        path: AppConstants.volunteerPrivateChatRoute,
                        queryParameters: {
                          'id': user.id.toString(),
                          'name': user.fullName,
                          if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
                        },
                      );
                      context.push(uri.toString());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text('Message',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(double size, String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
        ),
      ),
    );
  }

  Widget _buildPlanningSection(BuildContext context) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const dates = ['12', '13', '14', '15', '16', '17', '18'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mon Planning',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () => context.push(AppConstants.volunteerAgendaRoute),
                child: const Text('Détails',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                          7,
                          (i) => Text(weekdays[i],
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500))),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final isToday = i == 2;
                        return Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: isToday
                              ? const BoxDecoration(
                                  color: _primary, shape: BoxShape.circle)
                              : null,
                          child: Text(
                            dates[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isToday
                                  ? Colors.white
                                  : (i == 3
                                      ? const Color(0xFF1E293B)
                                      : Colors.grey.shade500),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: _primary,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Prochaine intervention',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B))),
                                const SizedBox(height: 2),
                                Text('Mercredi 14, 16:30 avec Lucas',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Material(
                  color: _primary,
                  borderRadius: BorderRadius.circular(999),
                  elevation: 2,
                  shadowColor: _primary.withOpacity(0.3),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _showQuickMenu = !_showQuickMenu),
                    borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
