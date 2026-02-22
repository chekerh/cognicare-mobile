import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class AdminVolunteerApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const AdminVolunteerApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<AdminVolunteerApplicationDetailScreen> createState() =>
      _AdminVolunteerApplicationDetailScreenState();
}

class _AdminVolunteerApplicationDetailScreenState
    extends State<AdminVolunteerApplicationDetailScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

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
      final app =
          await _adminService.getVolunteerApplication(widget.applicationId);
      if (mounted) {
        setState(() => _application = app);
        final userId = app['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          try {
            final list = await _adminService.getVolunteerCourseEnrollments(
                userId: userId);
            if (mounted) setState(() => _enrollments = list);
          } catch (_) {
            if (mounted) setState(() => _enrollments = []);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(String decision, {String? deniedReason}) async {
    setState(() => _actionLoading = true);
    try {
      await _adminService.reviewVolunteerApplication(
        widget.applicationId,
        decision: decision,
        deniedReason: deniedReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decision == 'approved'
                ? 'Candidature approuvée'
                : 'Candidature refusée'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showDenyDialog() {
    final reasonController = TextEditingController(
      text:
          'Votre candidature n\'a pas été retenue. Vous pouvez suivre notre formation qualifiante pour repostuler.',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la candidature'),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message au bénévole (obligatoire)',
            hintText:
                'Indiquez la raison et le lien vers la formation qualifiante si souhaité.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez indiquer un message')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _review('denied', deniedReason: reason);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _application == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          title: const Text('Détail candidature',
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          title: const Text('Détail candidature',
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final app = _application!;
    final user = app['user'] as Map<String, dynamic>?;
    final name = user?['fullName'] as String? ?? 'N/A';
    final email = user?['email'] as String? ?? '';
    final phone = user?['phone'] as String? ?? '';
    final status = app['status'] as String? ?? 'pending';
    final documents = app['documents'] as List<dynamic>? ?? [];
    final deniedReason = app['deniedReason'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Détail candidature',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            status == 'approved'
                                ? 'Approuvée'
                                : status == 'denied'
                                    ? 'Refusée'
                                    : 'En attente',
                          ),
                          backgroundColor: status == 'approved'
                              ? Colors.green.withOpacity(0.2)
                              : status == 'denied'
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Email: $email'),
                    if (phone.isNotEmpty) Text('Téléphone: $phone'),
                  ],
                ),
              ),
            ),
            if (deniedReason != null && deniedReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Raison du refus',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(deniedReason),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (documents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun document déposé.'),
                ),
              )
            else
              ...documents.map<Widget>((d) {
                final doc = d as Map<String, dynamic>? ?? {};
                final type = doc['type'] as String? ?? 'other';
                final url = doc['url'] as String? ?? '';
                final fileName = doc['fileName'] as String? ?? 'Document';
                final fullUrl = url.startsWith('http')
                    ? url
                    : '${AppConstants.baseUrl}$url';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      (doc['mimeType'] as String? ?? '').contains('pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color: AppTheme.primary,
                    ),
                    title: Text(fileName),
                    subtitle: Text(type == 'id'
                        ? 'Pièce d\'identité'
                        : type == 'certificate'
                            ? 'Certificat'
                            : 'Autre'),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openUrl(fullUrl),
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 16),
            const Text('Formations suivies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_enrollments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune inscription à une formation.'),
                ),
              )
            else
              ..._enrollments.map<Widget>((e) {
                final course = e['course'] as Map<String, dynamic>?;
                final title = course?['title'] as String? ?? 'Cours';
                final progress = (e['progressPercent'] as num?)?.toInt() ?? 0;
                final statusEnroll = e['status'] as String? ?? 'enrolled';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.2),
                      child: Icon(
                        statusEnroll == 'completed'
                            ? Icons.check_circle
                            : Icons.school,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(title),
                    subtitle: Text(
                        '$progress% • ${statusEnroll == 'completed' ? 'Terminé' : 'En cours'}'),
                  ),
                );
              }),
            if (status == 'pending') ...[
              const SizedBox(height: 24),
              if (_actionLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _review('approved'),
                        icon: const Icon(Icons.check),
                        label: const Text('Approuver'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showDenyDialog,
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
