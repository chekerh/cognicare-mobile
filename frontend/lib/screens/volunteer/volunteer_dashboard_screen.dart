import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart' as app_user;
import '../../providers/auth_provider.dart';
import '../../services/healthcare_service.dart';
import '../../services/children_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFF89CFF0);

String _fullImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}

String _roleToSpecializationLabel(String role, BuildContext context) {
  final l = AppLocalizations.of(context)!;
  switch (role) {
    case 'doctor':
      return l.roleDoctorLabel;
    case 'psychologist':
      return l.rolePsychologistLabel;
    case 'speech_therapist':
      return l.roleSpeechTherapistLabel;
    case 'occupational_therapist':
      return l.roleOccupationalTherapistLabel;
    default:
      return role;
  }
}

String _formatDateOfBirth(String? raw) {
  if (raw == null || raw.isEmpty) return 'DN: —';
  try {
    final d = DateTime.tryParse(raw);
    if (d == null) return 'DN: $raw';
    return 'DN: ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return 'DN: ${raw.length > 12 ? '${raw.substring(0, 10)}…' : raw}';
  }
}

/// Tableau de bord bénévole — Points Impact, Missions, Compétences, Professionnels de santé (contact), Planning.
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  List<app_user.User>? _healthcareUsers;
  bool _healthcareLoading = false;
  String? _healthcareError;

  List<ChildModel>? _children;
  bool _childrenLoading = false;
  String? _childrenError;

  @override
  void initState() {
    super.initState();
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
      final list = await ChildrenService(getToken: () async => authProvider.accessToken).getOrganizationChildren();
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
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userRole = user?.role;
    final userName = (user?.fullName ?? '').split(' ').firstOrNull ?? 'Julien';
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, userName, userRole),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsCards()),
                  SliverToBoxAdapter(child: _buildSkillsSection(context)),
                  if (AppConstants.isSpecialistRole(userRole))
                    SliverToBoxAdapter(child: _buildPatientsSection(context)),
                  SliverToBoxAdapter(child: _buildHealthcareSection(context)),
                  SliverToBoxAdapter(child: _buildPlanningSection(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.myPatients,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              TextButton(
                onPressed: () => context.go(AppConstants.healthcareDashboardRoute),
                child: const Text('Espace pro / IA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_childrenLoading)
            const Center(child: CircularProgressIndicator())
          else if (_childrenError != null)
            Text('Error: $_childrenError', style: const TextStyle(color: Colors.red))
          else if (_children == null || _children!.isEmpty)
            Text(
              AppLocalizations.of(context)!.noPatientsFound,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  '${AppLocalizations.of(context)!.dobLabel}: ${_formatDateOfBirth(child.dateOfBirth).replaceFirst('DN: ', '')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, String? userRole) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.helloUser(userName),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.isSpecialistRole(userRole)
                          ? _roleToSpecializationLabel(userRole!, context)
                          : AppLocalizations.of(context)!.volunteerLabel,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppConstants.volunteerMissionsRoute),
                    child: Text(AppLocalizations.of(context)!.missionsLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppConstants.volunteerProfileRoute),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: _primary, width: 2),
                          ),
                          child: const Icon(Icons.person_outline, color: _primary, size: 28),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              label: AppLocalizations.of(context)!.impactPoints,
              value: '1,250',
              bgColor: _primary.withOpacity(0.1),
              borderColor: _primary.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statCard(
              icon: Icons.volunteer_activism,
              iconColor: Colors.green.shade600,
              label: AppLocalizations.of(context)!.missionsLabel,
              value: '24',
              bgColor: Colors.green.shade50,
              borderColor: Colors.green.shade100,
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final skills = [
      (Icons.psychology, Colors.amber.shade500, Colors.amber.shade100, AppLocalizations.of(context)!.tdah),
      (Icons.palette, Colors.blue.shade500, Colors.blue.shade100, AppLocalizations.of(context)!.artTherapy),
      (Icons.menu_book, Colors.purple.shade500, Colors.purple.shade100, AppLocalizations.of(context)!.reading),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.mySkills, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () {},
                child: Text(AppLocalizations.of(context)!.seeAll, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
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
                  margin: EdgeInsets.only(right: i < skills.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle),
                        child: Icon(s.$1, color: s.$2, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(s.$4, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
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
          Text(
            AppLocalizations.of(context)!.healthcareProfessionalsLabel,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.contactExpertSubtitle,
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
                  Text(_healthcareError!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _loadHealthcare, child: Text(AppLocalizations.of(context)!.retry)),
                ],
              ),
            )
          else if (_healthcareUsers == null || _healthcareUsers!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                AppLocalizations.of(context)!.noPatientsYet,
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
    final specialization = _roleToSpecializationLabel(user.role, context);
    const size = 40.0;
    final avatar = imageUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarPlaceholder(size, user.fullName),
            ),
          )
        : _avatarPlaceholder(size, user.fullName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('CogniCare', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  specialization,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            specialization,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(AppLocalizations.of(context)!.messageLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
        ),
      ),
    );
  }

  Widget _buildPlanningSection(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final weekdays = List.generate(7, (i) => DateFormat.E(locale).format(DateTime(2024, 3, 11 + i)));
    final dates = ['12', '13', '14', '15', '16', '17', '18'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.myPlanning, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () => context.go(AppConstants.volunteerAgendaRoute),
                child: Text(AppLocalizations.of(context)!.detailsLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) => Text(weekdays[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final isToday = i == 2;
                    return Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: isToday
                          ? const BoxDecoration(color: _primary, shape: BoxShape.circle)
                          : null,
                      child: Text(
                        dates[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? Colors.white : (i == 3 ? const Color(0xFF1E293B) : Colors.grey.shade500),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(width: 4, height: 32, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.nextIntervention, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Text(AppLocalizations.of(context)!.nextInterventionWith(DateFormat.MMMEd(locale).format(DateTime(2024, 3, 14)), '16:30', 'Lucas'), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
