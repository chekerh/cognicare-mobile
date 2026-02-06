import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Écran Market — marketplace (secteur famille).
/// Placeholder prêt à être remplacé par un écran Stitch ou une vraie implémentation.
class FamilyMarketScreen extends StatelessWidget {
  const FamilyMarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: const Text(
          'Market',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: AppTheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Marketplace',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Discover sensory tools, weighted blankets, and resources. This screen can be replaced by your Stitch design.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.text.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
