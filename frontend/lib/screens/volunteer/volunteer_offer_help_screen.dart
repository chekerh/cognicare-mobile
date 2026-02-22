import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

const Color _brandBlue = Color(0xFF2563EB);
const Color _bgLight = Color(0xFFF0F9FF);

/// Proposer mon Aide — type d'aide, quand, message, diffuser.
class VolunteerOfferHelpScreen extends StatefulWidget {
  const VolunteerOfferHelpScreen({super.key});

  @override
  State<VolunteerOfferHelpScreen> createState() => _VolunteerOfferHelpScreenState();
}

class _VolunteerOfferHelpScreenState extends State<VolunteerOfferHelpScreen> {
  int _helpTypeIndex = 0; // 0 Courses, 1 Transport, 2 Garde, 3 Autre
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<({String label, IconData icon})> _getHelpTypes(BuildContext context) {
    return [
      (label: AppLocalizations.of(context)!.groceriesLabel, icon: Icons.shopping_cart),
      (label: AppLocalizations.of(context)!.transportLabel, icon: Icons.directions_car),
      (label: AppLocalizations.of(context)!.childcareLabel, icon: Icons.child_care),
      (label: AppLocalizations.of(context)!.otherLabel, icon: Icons.more_horiz),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        left: true,
        right: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios, color: Color(0xFF475569), size: 22),
                  ),
                  Expanded(child: Text(AppLocalizations.of(context)!.offerHelpTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: _brandBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.back_hand, size: 80, color: _brandBlue),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                AppLocalizations.of(context)!.offerHelpSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.helpTypeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: List.generate(4, (i) {
                              final selected = _helpTypeIndex == i;
                              final item = _getHelpTypes(context)[i];
                              return GestureDetector(
                                onTap: () => setState(() => _helpTypeIndex = i),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected ? _brandBlue.withOpacity(0.08) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: selected ? _brandBlue : Colors.grey.shade200, width: selected ? 2 : 1),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(item.icon, size: 28, color: selected ? _brandBlue : Colors.grey),
                                      const SizedBox(height: 8),
                                      Text(item.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: selected ? _brandBlue : Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.whenLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: _brandBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppLocalizations.of(context)!.dateLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                            Text(AppLocalizations.of(context)!.todayValueLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule, color: _brandBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppLocalizations.of(context)!.timeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                            Text(AppLocalizations.of(context)!.asapLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.customMessageLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "Précisez vos disponibilités ou un détail particulier...",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.offerBroadcastedMessage), behavior: SnackBarBehavior.floating));
                        context.pop();
                      },
                      icon: const Icon(Icons.send, size: 22, color: Colors.white),
                      label: Text(AppLocalizations.of(context)!.broadcastOfferButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        shadowColor: _brandBlue.withOpacity(0.5),
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

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
