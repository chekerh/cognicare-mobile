import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Rapports / Insights : lien vers Analyse comparative et liste des rapports.
class HealthcareReportsScreen extends StatelessWidget {
  const HealthcareReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.reportsLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.reportsDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _card(
                      context,
                      icon: Icons.insights,
                      title: AppLocalizations.of(context)!.aiComparativeAnalysisLabel,
                      subtitle: AppLocalizations.of(context)!.aiComparativeAnalysisSubtitle,
                      onTap: () => context.push(AppConstants.healthcareComparativeRoute),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      context,
                      icon: Icons.analytics,
                      title: AppLocalizations.of(context)!.medicalReportsLabel,
                      subtitle: AppLocalizations.of(context)!.medicalReportsSubtitle,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _card(
                      context,
                      icon: Icons.summarize,
                      title: AppLocalizations.of(context)!.lastAiSummariesLabel,
                      subtitle: AppLocalizations.of(context)!.lastAiSummariesSubtitle,
                      onTap: () {},
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _brand, size: 26),
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
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
