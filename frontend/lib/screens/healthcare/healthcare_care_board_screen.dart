import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFF2b8cee);

/// Collaborative Care Board pour un patient : équipe, timeline, chat équipe. Reçoit patientId et patientName.
class HealthcareCareBoardScreen extends StatelessWidget {
  const HealthcareCareBoardScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.diagnosis,
    this.age,
  });

  final String? patientId;
  final String? patientName;
  final String? diagnosis;
  final String? age;

  static HealthcareCareBoardScreen fromState(GoRouterState state) {
    final id = state.uri.queryParameters['patientId'];
    final name = state.uri.queryParameters['patientName'];
    final diag = state.uri.queryParameters['diagnosis'];
    final a = state.uri.queryParameters['age'];
    return HealthcareCareBoardScreen(
      patientId: id,
      patientName: name != null ? Uri.decodeComponent(name) : null,
      diagnosis: diag != null ? Uri.decodeComponent(diag) : null,
      age: a,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = patientName ?? 'Patient';
    final diag = diagnosis ?? 'ASD Level 1';
    final ageStr = age ?? '6y 4m';

    return Scaffold(
      backgroundColor: const Color(0xFFeef6ff),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Collaborative Care Board',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _patientHeader(name, diag, ageStr),
            const SizedBox(height: 20),
            _teamSection(context),
            const SizedBox(height: 20),
            _tabs(),
            const SizedBox(height: 16),
            _timelineSection(),
            const SizedBox(height: 20),
            _secureTeamChat(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (patientId != null && patientName != null) {
            context.push(
              '${AppConstants.healthcareProtocolEditorRoute}?patientId=$patientId&patientName=${Uri.encodeComponent(patientName!)}',
            );
          }
        },
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _patientHeader(String name, String diag, String ageStr) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: _primary.withOpacity(0.3),
          child: Text(
            name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      diag.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Age: $ageStr',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Multidisciplinary Team',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111418),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All',
                  style:
                      TextStyle(color: _primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _teamCard('Dr. Sarah Chen', 'Pediatrician'),
              _teamCard('Mark Rogers', 'Speech Therapy'),
              _teamCard('Elena Vance', 'Physiotherapist'),
              _addMemberCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamCard(String name, String role) {
    return Container(
      width: 128,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _primary.withOpacity(0.2),
            child: Text(
              name
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _primary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111418),
            ),
          ),
          Text(
            role,
            style: const TextStyle(
              fontSize: 10,
              color: _primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.chat_bubble_outline, size: 18, color: _primary),
        ],
      ),
    );
  }

  Widget _addMemberCard() {
    return Container(
      width: 128,
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add, color: Colors.grey, size: 32),
          SizedBox(height: 8),
          Text(
            'Invite Pro',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                'Timeline',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Files',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Goals',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _timelineItem(
          icon: Icons.psychology,
          iconColor: _primary,
          title: 'Speech Therapy Session',
          subtitle: 'Mark Rogers • 2h ago',
          tag: 'Updated',
          body:
              'Focus on articulation of "R" sounds. Leo responded well to visual prompts. Homework assigned: practice story cards daily.',
          tags: const ['Articulation', 'Storytelling'],
        ),
        _timelineItem(
          icon: Icons.medication,
          iconColor: Colors.amber,
          title: 'Medication Update',
          subtitle: 'Dr. Sarah Chen • Yesterday',
          body:
              'Reviewed current dosage. No side effects reported by parents. Maintain current protocol for 4 weeks.',
        ),
        _timelineItem(
          icon: Icons.fitness_center,
          iconColor: Colors.grey,
          title: 'Physio Assessment',
          subtitle: 'Elena Vance • Oct 12',
          body:
              'Assessment of fine motor skills. Recommended balance beam exercises twice weekly.',
        ),
      ],
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String body,
    String? tag,
    List<String>? tags,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              Container(
                width: 2,
                height: 80,
                color: _primary.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
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
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111418),
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  if (tags != null && tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secureTeamChat(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.forum, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Secure Team Chat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.lock,
                            size: 14, color: Colors.green.shade300),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dr. Chen: Have we seen improvement in motor skills since...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade300,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
