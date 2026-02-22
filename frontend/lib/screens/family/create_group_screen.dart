import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA8DADC);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF8FAFC);

/// Écran pour créer un groupe (type Messenger) : nom + sélection des participants.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<FamilyUser> _families = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chatService = ChatService();
      final list = await chatService.getFamiliesToContact();
      if (!mounted) return;
      setState(() {
        _families = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donnez un nom au groupe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un participant.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final chatService = ChatService();
      final participantIds = _selectedIds.where((id) => id.trim().isNotEmpty).toList();
      final conv = await chatService.createGroup(name, participantIds);
      if (!mounted) return;
      setState(() => _creating = false);
      final convId = conv['id']?.toString() ?? '';
      final convName = conv['name']?.toString() ?? name;
      final createdParticipants =
          (conv['participantIds'] is List ? (conv['participantIds'] as List).length : (_selectedIds.length + 1));
      context.go(
        Uri(
          path: AppConstants.familyGroupChatRoute,
          queryParameters: {
            'name': convName,
            'members': '$createdParticipants',
            'id': convId,
            'isGroup': '1',
          },
        ).toString(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text('Créer un groupe'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom du groupe',
                hintText: 'Ex: Famille Martin',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Ajouter des participants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _textMuted)),
                            const SizedBox(height: 16),
                            TextButton(onPressed: _loadFamilies, child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : _families.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune autre famille à ajouter.',
                              style: TextStyle(color: _textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _families.length,
                            itemBuilder: (context, index) {
                              final f = _families[index];
                              final disabled = f.id.trim().isEmpty;
                              final selected = _selectedIds.contains(f.id);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CheckboxListTile(
                                  value: selected,
                                  onChanged: disabled
                                      ? null
                                      : (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedIds.add(f.id);
                                      } else {
                                        _selectedIds.remove(f.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    f.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor: _primary.withOpacity(0.3),
                                    backgroundImage: f.profilePic != null &&
                                            f.profilePic!.isNotEmpty &&
                                            f.profilePic!.startsWith('http')
                                        ? NetworkImage(f.profilePic!)
                                        : null,
                                    child: f.profilePic == null ||
                                            f.profilePic!.isEmpty ||
                                            !f.profilePic!.startsWith('http')
                                        ? Text(
                                            f.fullName.isNotEmpty ? f.fullName[0].toUpperCase() : '?',
                                            style: const TextStyle(color: _textPrimary),
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _creating ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _creating
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Créer le groupe (${_selectedIds.length + 1} participants)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
