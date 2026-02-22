import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _adminService = AdminService();
  User? _adminUser;
  bool _isLoading = true;
  final Map<String, int> _userStats = {
    'total': 0,
    'family': 0,
    'doctor': 0,
    'volunteer': 0,
  };
  Map<String, dynamic>? _progressAiSummary;
  bool _progressAiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _loadUserStats();
    _loadProgressAiSummary();
  }

  Future<void> _loadProgressAiSummary() async {
    setState(() => _progressAiLoading = true);
    try {
      final data = await _adminService.getProgressAiAdminSummary();
      if (mounted) setState(() {
        _progressAiSummary = data;
        _progressAiLoading = false;
      });
    } catch (e) {
      debugPrint('Progress AI summary: $e');
      if (mounted) setState(() => _progressAiLoading = false);
    }
  }

  Future<void> _loadAdminProfile() async {
    try {
      final user = await _authService.getProfile();
      if (user.role != 'admin') {
        // Not an admin, redirect to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin-login');
        }
        return;
      }
      setState(() {
        _adminUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin-login');
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _userStats['total'] = users.length;
        _userStats['family'] = users.where((u) => u.role == 'family').length;
        _userStats['doctor'] = users.where((u) => u.role == 'doctor').length;
        _userStats['volunteer'] = users.where((u) => u.role == 'volunteer').length;
      });
    } catch (e) {
      // If fails, keep default values
      debugPrint('Failed to load user stats: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.clearStoredData();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_adminUser?.fullName ?? 'Admin'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _adminUser?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isMobile ? 2 : 4;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      icon: Icons.people,
                      title: 'Total Users',
                      value: '${_userStats['total']}',
                      color: AppTheme.primary,
                    ),
                    _buildStatCard(
                      icon: Icons.family_restroom,
                      title: 'Families',
                      value: '${_userStats['family']}',
                      color: AppTheme.secondary,
                    ),
                    _buildStatCard(
                      icon: Icons.medical_services,
                      title: 'Doctors',
                      value: '${_userStats['doctor']}',
                      color: AppTheme.accent,
                    ),
                    _buildStatCard(
                      icon: Icons.volunteer_activism,
                      title: 'Volunteers',
                      value: '${_userStats['volunteer']}',
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Progress AI Summary (aggregates, no PII)
            const Text(
              'Progress AI Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggregated plan counts across the platform (no personal data).',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            _progressAiLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _progressAiSummary != null
                    ? Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Total plans: ${_progressAiSummary!['totalPlans'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Children with at least one plan: ${_progressAiSummary!['childrenWithPlansCount'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_progressAiSummary!['planCountByType'] != null)
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: (_progressAiSummary!['planCountByType'] as Map<String, dynamic>)
                                      .entries
                                      .map((e) => Chip(
                                            label: Text('${e.key}: ${e.value}'),
                                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
            const SizedBox(height: 24),

            // Management Sections
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 16),

            _buildManagementCard(
              icon: Icons.people_outline,
              title: 'User Management',
              description: 'View and manage all users',
              onTap: () {
                Navigator.pushNamed(context, '/admin-users');
              },
            ),
            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.volunteer_activism,
              title: 'Volunteer Applications',
              description: 'Review and approve or deny volunteer applications',
              onTap: () {
                Navigator.pushNamed(context, '/admin-volunteers');
              },
            ),
            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              description: 'View platform statistics and reports',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics - Coming Soon')),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.settings_outlined,
              title: 'System Settings',
              description: 'Configure platform settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('System Settings - Coming Soon')),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.mail_outline,
              title: 'Email Templates',
              description: 'Manage email templates and notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email Templates - Coming Soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
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
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
