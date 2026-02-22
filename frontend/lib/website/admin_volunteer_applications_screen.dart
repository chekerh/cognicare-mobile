import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../utils/theme.dart';
import 'admin_volunteer_application_detail_screen.dart';

class AdminVolunteerApplicationsScreen extends StatefulWidget {
  const AdminVolunteerApplicationsScreen({super.key});

  @override
  State<AdminVolunteerApplicationsScreen> createState() =>
      _AdminVolunteerApplicationsScreenState();
}

class _AdminVolunteerApplicationsScreenState
    extends State<AdminVolunteerApplicationsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _error;
  String _filter = 'pending'; // pending | approved | denied

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await _adminService.getVolunteerApplications(status: _filter);
      if (mounted) setState(() => _applications = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Candidatures bénévoles',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'pending',
                        label: Text('En attente'),
                        icon: Icon(Icons.schedule)),
                    ButtonSegment(
                        value: 'approved',
                        label: Text('Approuvées'),
                        icon: Icon(Icons.check_circle)),
                    ButtonSegment(
                        value: 'denied',
                        label: Text('Refusées'),
                        icon: Icon(Icons.cancel)),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (Set<String> s) {
                    setState(() => _filter = s.first);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _load,
                                child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : _applications.isEmpty
                        ? const Center(child: Text('Aucune candidature'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _applications.length,
                              itemBuilder: (context, i) {
                                final app = _applications[i];
                                final id = app['id'] as String? ?? '';
                                final user =
                                    app['user'] as Map<String, dynamic>?;
                                final name =
                                    user?['fullName'] as String? ?? 'N/A';
                                final email = user?['email'] as String? ?? '';
                                final status =
                                    app['status'] as String? ?? 'pending';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: status == 'approved'
                                          ? Colors.green
                                          : status == 'denied'
                                              ? Colors.red
                                              : Colors.orange,
                                      child: Icon(
                                        status == 'approved'
                                            ? Icons.check
                                            : status == 'denied'
                                                ? Icons.close
                                                : Icons.pending,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(name),
                                    subtitle: Text(email),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              AdminVolunteerApplicationDetailScreen(
                                            applicationId: id,
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
