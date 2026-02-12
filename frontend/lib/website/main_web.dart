import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'admin_volunteer_applications_screen.dart';
import '../utils/theme.dart';

void main() {
  runApp(const CogniCareWebsite());
}

class CogniCareWebsite extends StatelessWidget {
  const CogniCareWebsite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniCare - Cognitive Health Management',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-users': (context) => const UserManagementScreen(),
        '/admin-volunteers': (context) => const AdminVolunteerApplicationsScreen(),
      },
    );
  }
}
