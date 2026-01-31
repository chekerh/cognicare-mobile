import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 60,
                vertical: 20,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'CogniCare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Admin Login Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin-login');
                    },
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: Text(isMobile ? 'Admin' : 'Admin Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 20,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 60,
                vertical: isMobile ? 40 : 80,
              ),
              child: Column(
                children: [
                  Text(
                    'CogniCare 🧠',
                    style: TextStyle(
                      fontSize: isMobile ? 36 : 64,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your companion for better cognitive health',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'CogniCare is a digital platform dedicated to supporting cognitive well-being and mental development in a simple, accessible, and personalized way. It helps users better understand, monitor, and improve their cognitive health through guided experiences designed for everyday life.',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: AppTheme.text.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'With an intuitive interface and a smooth user experience, CogniCare makes it easy to get started, follow your progress, and stay engaged over time. The app adapts to individual needs and preferences, offering a personalized journey for each user.',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: AppTheme.text.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 40 : 60),

                  // Download Buttons
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildDownloadButton(
                        icon: Icons.apple,
                        label: 'Download on the',
                        storeName: 'App Store',
                        onPressed: () => _launchURL('https://apps.apple.com/app/cognicare'),
                      ),
                      _buildDownloadButton(
                        icon: Icons.android,
                        label: 'Get it on',
                        storeName: 'Google Play',
                        onPressed: () => _launchURL('https://play.google.com/store/apps/details?id=com.cognicare.app'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 60,
                vertical: isMobile ? 40 : 60,
              ),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'Why Choose CogniCare?',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 42,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available in multiple languages, CogniCare is built to be inclusive and accessible to a wide audience. Whether you are using it for yourself or for a loved one, the platform provides a safe and supportive environment focused on long-term well-being.',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: AppTheme.text.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 30 : 50),
                  _buildFeaturesGrid(isMobile),
                  SizedBox(height: isMobile ? 30 : 50),
                  Text(
                    'CogniCare is more than an app — it\'s a step toward a healthier, sharper, and more balanced mind. 🧠✨',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: AppTheme.text,
              child: Column(
                children: [
                  const Text(
                    '© 2026 CogniCare. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String label,
    required String storeName,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.text,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isMobile) {
    return Wrap(
      spacing: 30,
      runSpacing: 30,
      alignment: WrapAlignment.center,
      children: [
        _buildFeatureCard(
          icon: Icons.spa,
          title: 'Simple & Accessible',
          description: 'Easy to get started with an intuitive interface designed for everyday use.',
          isMobile: isMobile,
        ),
        _buildFeatureCard(
          icon: Icons.trending_up,
          title: 'Track Your Progress',
          description: 'Follow your cognitive development journey and stay engaged over time.',
          isMobile: isMobile,
        ),
        _buildFeatureCard(
          icon: Icons.person_outline,
          title: 'Personalized Journey',
          description: 'The app adapts to your individual needs and preferences for a unique experience.',
          isMobile: isMobile,
        ),
        _buildFeatureCard(
          icon: Icons.language,
          title: 'Multi-Language Support',
          description: 'Available in English, French, and Arabic for inclusive and accessible care.',
          isMobile: isMobile,
        ),
        _buildFeatureCard(
          icon: Icons.favorite_outline,
          title: 'Safe & Supportive',
          description: 'A secure environment focused on your long-term well-being and mental health.',
          isMobile: isMobile,
        ),
        _buildFeatureCard(
          icon: Icons.psychology_outlined,
          title: 'Guided Experiences',
          description: 'Expertly designed activities to help you understand, monitor, and improve cognitive health.',
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.text.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
