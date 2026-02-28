// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/user.dart' as app_user;
import '../../services/availability_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/children_service.dart';
import '../../services/healthcare_service.dart';
import '../../utils/constants.dart';
import 'child_profile_setup_screen.dart';

// Aligné sur le HTML Family Member Dashboard
const Color _primary = Color(0xFFA3D9E5);
const Color _primaryDark = Color(0xFF7BBCCB);
const Color _cardLight = Color(0xFFFFFFFF);
const Color _slate600 = Color(0xFF475569);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate500 = Color(0xFF64748B);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate300 = Color(0xFFCBD5E1);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green600 = Color(0xFF16A34A);

/// Même gris foncé que "Commande Confirmée" (boutons, icônes d'accent)
const Color _accentColor = Color(0xFF212121);

/// Données d'un bénévole affiché sur l'accueil famille.
class _VolunteerCardData {
  final String id;
  final String name;
  final String avatarUrl;
  final String specialization;
  final String location;

  const _VolunteerCardData({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.specialization,
    required this.location,
  });
}

/// Family Member Dashboard — design aligné sur le HTML fourni.
/// Bonjour Sarah, carte Jouer avec Léo, Progrès du jour, Chat Famille / Suivi Médical, activité récente.
class FamilyMemberDashboardScreen extends StatefulWidget {
  const FamilyMemberDashboardScreen({super.key});

  @override
  State<FamilyMemberDashboardScreen> createState() =>
      _FamilyMemberDashboardScreenState();
}

class _FamilyMemberDashboardScreenState
    extends State<FamilyMemberDashboardScreen> {
  List<_VolunteerCardData>? _volunteerCards;
  bool _loadingVolunteers = false;
  String? _volunteerError;

  List<app_user.User>? _healthcareUsers;
  bool _healthcareLoading = false;
  String? _healthcareError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkChildProfileComplete());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().initialize();
    });
    _loadVolunteerAvailabilities();
    _loadHealthcareUsers();
  }

  Future<void> _loadHealthcareUsers() async {
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

  static String _healthcareRoleToLabel(String role) {
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

  Future<void> _loadVolunteerAvailabilities() async {
    setState(() {
      _loadingVolunteers = true;
      _volunteerError = null;
    });
    try {
      final service = AvailabilityService();
      final list = await service.listForFamilies();
      if (!mounted) return;
      setState(() {
        _volunteerCards = list.map((a) {
          final dateStr = a.dates.isNotEmpty
              ? a.dates.length == 1
                  ? a.dates.first
                  : '${a.dates.first} – ${a.dates.last}'
              : '';
          final timeStr = '${a.startTime} – ${a.endTime}';
          final pic = a.volunteerProfilePic;
          final avatarUrl = (pic.isNotEmpty && !pic.startsWith('http'))
              ? '${AppConstants.baseUrl}$pic'
              : pic;
          return _VolunteerCardData(
            id: a.volunteerId,
            name: a.volunteerName,
            avatarUrl: avatarUrl,
            specialization: dateStr.isNotEmpty
                ? 'Disponible $dateStr, $timeStr'
                : 'Disponible $timeStr',
            location: '',
          );
        }).toList();
        _loadingVolunteers = false;
        _volunteerError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVolunteers = false;
        _volunteerError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _checkChildProfileComplete() async {
    final complete = await ChildProfileSetupScreen.isProfileComplete();
    if (complete) return;
    if (!mounted) return;
    final ctx = context;
    final loc = AppLocalizations.of(ctx)!;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.childProfileAlertTitle),
        content: Text(loc.childProfileAlertMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.childProfileAlertLaterButton),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              context.push(AppConstants.familyChildProfileSetupRoute);
            },
            child: Text(loc.childProfileAlertCompleteButton),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithVolunteer(
      BuildContext context, _VolunteerCardData v) async {
    try {
      final chatService = ChatService();
      final conv = await chatService.getOrCreateConversation(v.id);
      if (!mounted) return;
      final uri = Uri(
        path: AppConstants.familyPrivateChatRoute,
        queryParameters: <String, String>{
          'id': v.id,
          'name': v.name,
          if (v.avatarUrl.isNotEmpty) 'imageUrl': v.avatarUrl,
          'conversationId': conv.id,
        },
      );
      if (!mounted) return;
      context.push(uri.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? 'Sarah';

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, userName),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      _buildPlayWithLeoCard(context),
                      const SizedBox(height: 24),
                      _buildDailyRoutineCard(context),
                      const SizedBox(height: 24),
                      _buildProgressSummaryCard(context),
                      const SizedBox(height: 24),
                      _buildTwoColumnCards(context),
                      const SizedBox(height: 24),
                      _buildVolunteersSection(context),
                      const SizedBox(height: 24),
                      _buildHealthcareSection(context),
                      SizedBox(height: 24 + bottomPadding + 60),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Membre de la famille',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => context.push(AppConstants.familyNotificationsRoute),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_rounded,
                    color: _slate800, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayWithLeoCard(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: () => context.push(AppConstants.familyGamesSelectionRoute),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jouer avec Cogni',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lancer une session de thérapie ludique',
                      style: TextStyle(
                        fontSize: 14,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyRoutineCard(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: () async {
          try {
            final childrenService = ChildrenService(
              getToken: () => AuthService().getStoredToken(),
            );
            final children = await childrenService.getChildren();

            if (!mounted) return;

            if (children.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Veuillez d\'abord ajouter un profil d\'enfant'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            // Prendre le premier enfant
            final firstChild = children.first;

            context.push(
              '/family/child-daily-routine',
              extra: {'childId': firstChild.id},
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accentColor,
                      _primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '📅',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routine & Rappels',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Voir les tâches quotidiennes de votre enfant',
                      style: TextStyle(
                        fontSize: 14,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _accentColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummaryCard(BuildContext context) {
    return _Card(
      child: InkWell(
        onTap: () async {
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final childrenService = ChildrenService(
              getToken: () async => authProvider.accessToken,
            );
            final children = await childrenService.getChildren();
            if (!mounted) return;
            if (children.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Veuillez d\'abord ajouter un profil d\'enfant'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            final firstChild = children.first;
            context.push(
              AppConstants.familyChildProgressSummaryRoute,
              extra: {
                'childId': firstChild.id,
                'childName': firstChild.fullName,
              },
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _green100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.show_chart_rounded,
                      color: _green600, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé de progrès',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Progression par plan et tâches complétées',
                      style: TextStyle(
                        fontSize: 14,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _accentColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumnCards(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Card(
              child: InkWell(
                onTap: () => context.go(AppConstants.familyFamiliesRoute),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _green100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.forum_rounded,
                            color: _green600, size: 20),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Chat Famille',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _slate800,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Messages',
                        style: TextStyle(fontSize: 10, color: _slate500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Card(
              child: InkWell(
                onTap: () => context.push(AppConstants.familyCalendarRoute),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: _slate800, size: 20),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Planning',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _slate800,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rendez-vous & routine',
                        style: TextStyle(fontSize: 10, color: _slate500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Bénévoles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _slate800,
            ),
          ),
        ),
        if (_loadingVolunteers)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_volunteerError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Text(_volunteerError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _slate500)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadVolunteerAvailabilities,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          )
        else if (_volunteerCards == null || _volunteerCards!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Aucun bénévole disponible pour le moment.\nLes disponibilités publiées apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _slate500),
              ),
            ),
          )
        else
          ..._volunteerCards!.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildVolunteerCard(context, v),
              )),
      ],
    );
  }

  Widget _buildHealthcareSection(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            loc.healthcareProfessionalsLabel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _slate800,
            ),
          ),
        ),
        if (_healthcareLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_healthcareError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Text(_healthcareError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _slate500)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadHealthcareUsers,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          )
        else if (_healthcareUsers == null || _healthcareUsers!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Aucun professionnel de santé pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _slate500),
              ),
            ),
          )
        else
          ..._healthcareUsers!.map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildHealthcareCard(context, user),
              )),
      ],
    );
  }

  String _healthcareImageUrl(String? profilePic) {
    if (profilePic == null || profilePic.isEmpty) return '';
    if (profilePic.startsWith('http')) return profilePic;
    final base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;
    return profilePic.startsWith('/') ? '$base$profilePic' : '$base/$profilePic';
  }

  Widget _buildHealthcareCard(BuildContext context, app_user.User user) {
    final imageUrl = _healthcareImageUrl(user.profilePic);
    final specialization = _healthcareRoleToLabel(user.role);
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: imageUrl.isEmpty
                      ? Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 28),
                        )
                      : Image.network(
                          imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _slate800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 16, color: _accentColor),
                              SizedBox(width: 4),
                              Text(
                                'VÉRIFIÉ',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _accentColor,
                                    letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization,
                        style: const TextStyle(fontSize: 13, color: _slate500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: _slate400),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'CogniCare',
                              style: TextStyle(fontSize: 12, color: _slate500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(AppConstants.familyExpertBookingRoute,
                          extra: {
                            'expertId': user.id,
                            'name': user.fullName,
                            'specialization': specialization,
                            'location': 'CogniCare',
                            'imageUrl': imageUrl,
                          });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.bookConsultation),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    context.push(
                      Uri(
                        path: AppConstants.familyPrivateChatRoute,
                        queryParameters: <String, String>{
                          'id': user.id,
                          'name': user.fullName,
                          if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
                        },
                      ).toString(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate800,
                    side: const BorderSide(color: _slate300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.messageLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(BuildContext context, _VolunteerCardData v) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.network(
                    v.avatarUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context.push(
                                  AppConstants.familyVolunteerProfileRoute,
                                  extra: <String, dynamic>{
                                    'id': v.id,
                                    'name': v.name,
                                    'avatarUrl': v.avatarUrl,
                                    'specialization': v.specialization,
                                    'location': v.location,
                                  },
                                );
                              },
                              child: Text(
                                v.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _slate800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 16, color: _accentColor),
                              SizedBox(width: 4),
                              Text(
                                'VÉRIFIÉ',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _accentColor,
                                    letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.specialization,
                        style: const TextStyle(fontSize: 13, color: _slate500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (v.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: _slate400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                v.location,
                                style: const TextStyle(
                                    fontSize: 12, color: _slate500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openChatWithVolunteer(context, v),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Demander de l\'aide'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _openChatWithVolunteer(context, v),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate800,
                    side: const BorderSide(color: _slate300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
