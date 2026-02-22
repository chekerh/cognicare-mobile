import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Éditeur de protocole pour un patient : objectif, planning hebdo, paramètres session, Smart Library.
class HealthcareProtocolEditorScreen extends StatelessWidget {
  const HealthcareProtocolEditorScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  final String? patientId;
  final String? patientName;

  static HealthcareProtocolEditorScreen fromState(GoRouterState state) {
    final id = state.uri.queryParameters['patientId'];
    final name = state.uri.queryParameters['patientName'];
    return HealthcareProtocolEditorScreen(
      patientId: id,
      patientName: name != null ? Uri.decodeComponent(name) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = patientName ?? 'Léo G.';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.protocolEditorLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _brand,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${AppLocalizations.of(context)!.drLabel('Martin')} • ${AppLocalizations.of(context)!.patientLabelWithColon} $name',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: _brand, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _objectiveCard(context),
            const SizedBox(height: 24),
            _weeklyPlanning(context),
            const SizedBox(height: 24),
            _sessionParams(context),
            const SizedBox(height: 24),
            _smartLibrary(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _objectiveCard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('LG', style: TextStyle(fontWeight: FontWeight.bold, color: _brand, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.mainObjectiveLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    l.oculomotorCoordinationLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _weeklyPlanning(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final days = [
      {'label': l.mondayLabel, 'active': false, 'slots': ['Bulles de Savon', '']},
      {'label': l.tuesdayLabel, 'active': true, 'slots': ['Tracé Magique', 'Rythmes Calmes']},
      {'label': l.wednesdayLabel, 'active': false, 'slots': ['', '']},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.weeklyPlanningLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, i) {
              final d = days[i] as Map<String, dynamic>;
              final active = d['active'] as bool;
              final slots = d['slots'] as List<String>;
              return Container(
                width: 128,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Text(
                      d['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active ? _brand : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...slots.map((s) {
                      if (s.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.grey),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? _brand : Colors.grey.shade200,
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.drag_indicator, size: 14, color: active ? _brand : Colors.grey),
                                ],
                              ),
                              Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${15} ${l.minAgo} • ${l.levelWithCount(3)}',
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sessionParams(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_suggest, color: _brand, size: 22),
                const SizedBox(width: 8),
                Text(
                  l.sessionParamsTitle('Tracé Magique'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l.clinicalDifficultyLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.levelWithCount(3), style: const TextStyle(fontWeight: FontWeight.bold, color: _brand, fontSize: 12)),
              ],
            ),
            Slider(
              value: 3,
              min: 1,
              max: 5,
              activeColor: _brand,
              onChanged: (_) {},
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.beginnerLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(l.expertLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.frequencyLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: l.oncePerDay,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: l.oncePerDay, child: Text(l.oncePerDay)),
                          DropdownMenuItem(value: l.twicePerDay, child: Text(l.twicePerDay)),
                        ],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.durationMinLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: '15',
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
      ),
    );
  }

  Widget _smartLibrary(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
      {'title': l.visualMemoryLabel, 'sub': l.cognitive, 'icon': Icons.psychology, 'color': Colors.purple},
      {'title': l.fineMotorSkillsLabel, 'sub': l.motorLabel, 'icon': Icons.pan_tool, 'color': Colors.amber},
      {'title': l.emotionsLabel, 'sub': l.socialLabel, 'icon': Icons.mood, 'color': Colors.pink},
      {'title': l.attentionLabel, 'sub': l.neuroLabel, 'icon': Icons.visibility, 'color': Colors.teal},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  l.smartLibraryLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.clinicallyValidatedLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _brand,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: items.map((e) {
            final color = e['color'] as Color;
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(e['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e['title'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              e['sub'] as String,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
