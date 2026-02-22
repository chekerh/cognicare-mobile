// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../services/availability_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/children_service.dart';
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
  State<FamilyMemberDashboardScreen> createState() => _FamilyMemberDashboardScreenState();
}

class _FamilyMemberDashboardScreenState extends State<FamilyMemberDashboardScreen> {
  List<_VolunteerCardData>? _volunteerCards;
  bool _loadingVolunteers = false;
  String? _volunteerError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkChildProfileComplete());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().initialize();
    });
    _loadVolunteerAvailabilities();
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
          final l10n = AppLocalizations.of(context)!;
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
            specialization: dateStr.isNotEmpty ? 'Disponible $dateStr, $timeStr' : 'Disponible $timeStr',
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

  Future<void> _openChatWithVolunteer(BuildContext context, _VolunteerCardData v) async {
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
                  _buildProgressSection(context),
                  const SizedBox(height: 24),
                  _buildTwoColumnCards(context),
                  const SizedBox(height: 24),
                  _buildVolunteersSection(context),
                  const SizedBox(height: 24),
                  _buildRecentActivityCard(context),
                  const SizedBox(height: 100),
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
              Text(
                AppLocalizations.of(context)!.helloUser(userName),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _slate600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.familyMemberRole,
                style: const TextStyle(
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
                child: const Icon(Icons.notifications_rounded, color: _slate800, size: 24),
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
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.playWithLeo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.launchPlayTherapy,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: _primary, size: 18),
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
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.pleaseAddChildProfileFirst),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.routineAndReminders,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.viewChildDailyTasks,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: _accentColor, size: 18),
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
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final childrenService = ChildrenService(
              getToken: () async => authProvider.accessToken,
            );
            final children = await childrenService.getChildren();
            if (!mounted) return;
            if (children.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez d\'abord ajouter un profil d\'enfant'),
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
                  child: Icon(Icons.show_chart_rounded, color: _green600, size: 32),
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
              const Icon(Icons.arrow_forward_ios_rounded, color: _accentColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    const days = ['LUN', 'MAR', 'MER', 'JEU', 'VEN'];
    const heights = [48.0, 80.0, 112.0, 64.0, 96.0];
    const hasStar = [true, true, true, false, false];
    const isCurrent = [false, false, true, false, false];

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.dailyProgress,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _slate800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.childAgeLabel('Léo', '6'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: heights[i],
                          decoration: BoxDecoration(
                            color: hasStar[i]
                                ? (isCurrent[i] ? _primary : _primary.withOpacity(0.2))
                                : _slate300.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: hasStar[i]
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: isCurrent[i] ? Colors.white : _primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent[i] ? _primary : _slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: _slate500),
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context)!.starsNeededForChallenge('2'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _slate800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Card(
                child: InkWell(
                  onTap: () => context.go(AppConstants.familyFamiliesRoute),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: _green100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.forum_rounded, color: _green600, size: 22),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.familyChat,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.newMessagesCount('2'),
                          style: const TextStyle(fontSize: 12, color: _slate500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Card(
                child: InkWell(
                  onTap: () => context.push(AppConstants.familyPatientRecordRoute),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: _accentColor, size: 22),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.medicalTracking,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.nextAppointmentLabel,
                          style: const TextStyle(fontSize: 12, color: _slate500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVolunteersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            AppLocalizations.of(context)!.volunteersLabel,
            style: const TextStyle(
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
                  Text(_volunteerError!, textAlign: TextAlign.center, style: const TextStyle(color: _slate500)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadVolunteerAvailabilities,
                    child: Text(AppLocalizations.of(context)!.retryButton),
                  ),
                ],
              ),
            ),
          )
        else if (_volunteerCards == null || _volunteerCards!.isEmpty)
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noVolunteersAvailable,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _slate500),
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
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
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
                              Icon(Icons.verified_rounded, size: 16, color: _accentColor),
                              SizedBox(width: 4),
                              Text(
                                'VÉRIFIÉ',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor, letterSpacing: 0.5),
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
                            const Icon(Icons.location_on_outlined, size: 14, color: _slate400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                v.location,
                                style: const TextStyle(fontSize: 12, color: _slate500),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.askForHelp),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _openChatWithVolunteer(context, v),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate800,
                    side: const BorderSide(color: _slate300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.messagesLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: _accentColor,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: _slate800, height: 1.3),
                children: [
                  TextSpan(
                    text: 'Dr. Martin ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'a mis à jour le programme de motricité fine.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Il y a 2h',
            style: TextStyle(
              fontSize: 10,
              color: _slate500,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
