import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../services/volunteer_service.dart';

const Color _primary = Color(0xFFA4D9E5);
const Color _background = Color(0xFFF8FAFC);
const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

class VolunteerApplicationScreen extends StatefulWidget {
  const VolunteerApplicationScreen({super.key});

  @override
  State<VolunteerApplicationScreen> createState() =>
      _VolunteerApplicationScreenState();
}

class _VolunteerApplicationScreenState extends State<VolunteerApplicationScreen> {
  final VolunteerService _volunteerService = VolunteerService();
  Map<String, dynamic>? _application;
  bool _loading = true;
  bool _uploading = false;
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
      final app = await _volunteerService.getMyApplication();
      if (mounted) setState(() => _application = app..remove('_id'));
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (mounted && messenger != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Fichier non accessible')));
      }
      return;
    }
    final f = File(path);
    if (!await f.exists()) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (mounted && messenger != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Fichier introuvable')));
      }
      return;
    }
    final length = await f.length();
    if (length > _maxFileSizeBytes) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (mounted && messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Taille max 5 Mo'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() => _uploading = true);
    try {
      await _volunteerService.uploadDocument(file: f, type: type);
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (mounted && messenger != null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Document ajouté'), backgroundColor: Colors.green),
          );
        }
        _load();
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (mounted && messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeDocument(int index) async {
    try {
      await _volunteerService.removeDocument(index);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (mounted && messenger != null) {
          messenger.showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _application == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _primary,
          title: const Text('Candidature bénévole'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _application?['status'] as String? ?? 'pending';
    final documents = _application?['documents'] as List<dynamic>? ?? [];
    final deniedReason = _application?['deniedReason'] as String?;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Candidature bénévole'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusChip(status),
                  const SizedBox(height: 24),
                  if (status == 'approved') ...[
                    _buildApprovedMessage(),
                  ] else if (status == 'denied') ...[
                    _buildDeniedMessage(deniedReason),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppConstants.coursesRoute),
                      icon: const Icon(Icons.school),
                      label: const Text('Voir les formations qualifiantes'),
                    ),
                  ] else ...[
                    _buildDocumentsSection(documents),
                    const SizedBox(height: 16),
                    const Text(
                      'Types acceptés : images (JPEG, PNG, WebP) ou PDF. Max 5 Mo par fichier.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (_uploading)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Upload en cours…',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approuvée';
        break;
      case 'denied':
        color = Colors.red;
        label = 'Refusée';
        break;
      default:
        color = Colors.orange;
        label = 'En attente';
    }
    return Center(
      child: Chip(
        backgroundColor: color.withOpacity(0.2),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildApprovedMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
            const SizedBox(height: 16),
            const Text(
              'Votre candidature a été approuvée. Vous pouvez accéder à toutes les fonctionnalités bénévole.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeniedMessage(String? reason) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Candidature refusée',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(reason, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 12),
            const Text(
              'Vous pouvez suivre une formation qualifiante pour postuler à nouveau.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(List<dynamic> documents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents déposés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(documents.length, (i) {
              final doc = documents[i] as Map<String, dynamic>? ?? {};
              final type = doc['type'] as String? ?? 'other';
              final fileName = doc['fileName'] as String? ?? 'Document ${i + 1}';
              return ListTile(
                leading: Icon(
                  (doc['mimeType'] as String? ?? '').contains('pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image,
                  color: _primary,
                ),
                title: Text(fileName),
                subtitle: Text(type == 'id' ? 'Pièce d\'identité' : type == 'certificate' ? 'Certificat' : 'Autre'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _uploading ? null : () => _removeDocument(i),
                ),
              );
            }),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Pièce d\'identité'),
                  onPressed: _uploading ? null : () => _pickAndUpload('id'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Certificat'),
                  onPressed: _uploading ? null : () => _pickAndUpload('certificate'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Autre'),
                  onPressed: _uploading ? null : () => _pickAndUpload('other'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
