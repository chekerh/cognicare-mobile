import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _background = Color(0xFFF8FAFC);

/// Écran « New post » style Facebook : navigation pleine page, header, user, tags, champ texte, barre d’actions (Gallery, etc.).
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _controller = TextEditingController();
  bool _isPosting = false;
  String? _selectedImagePath;
  int? _selectedTagIndex;

  List<({String label, IconData icon})> _getTags(AppLocalizations loc) => [
    (label: loc.tagMilestone, icon: Icons.emoji_events_outlined),
    (label: loc.tagTip, icon: Icons.lightbulb_outline),
    (label: loc.tagQuestion, icon: Icons.help_outline),
    (label: loc.tagFeeling, icon: Icons.mood_outlined),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return null;
    final tempDir = await getTemporaryDirectory();
    final name = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File('${tempDir.path}/$name');
    await File(xFile.path).copy(savedFile.path);
    return savedFile.path;
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.postEmptyError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final feed = Provider.of<CommunityFeedProvider>(context, listen: false);
    final user = auth.user;

    try {
      await feed.addPost(
        authorName: user?.fullName ?? 'Anonymous',
        authorId: user?.id ?? '',
        text: text,
        imagePath: _selectedImagePath,
      );
    } catch (e) {
      setState(() => _isPosting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Failed to share post'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = false);
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.postSharedSuccess),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          loc.createPostTitle,
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.text),
            onPressed: () {
              // Menu options
            },
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Partie haute scrollable : user, tags, aperçu image
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _primary.withOpacity(0.4),
                          child: Text(
                            (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user?.fullName ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _getTags(loc).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final tag = _getTags(loc)[i];
                          final selected = _selectedTagIndex == i;
                          return FilterChip(
                            selected: selected,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tag.icon, size: 18, color: selected ? Colors.white : AppTheme.text),
                                const SizedBox(width: 6),
                                Text(tag.label),
                              ],
                            ),
                            onSelected: (v) => setState(() => _selectedTagIndex = v ? i : null),
                            selectedColor: _primary,
                            checkmarkColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        },
                      ),
                    ),
                    if (_selectedImagePath != null) ...[
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImagePath!),
                              width: double.infinity,
                              height: 240,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                            onPressed: () => setState(() => _selectedImagePath = null),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Partie fixe en bas : champ texte + actions + bouton Post
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.text.withOpacity(0.1))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: loc.postHintText,
                      hintStyle: TextStyle(
                        color: AppTheme.text.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: _background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 16, color: AppTheme.text),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _bottomAction(Icons.photo_library_outlined, loc.postActionGallery, () async {
                          final path = await _pickImage();
                          if (path != null && mounted) setState(() => _selectedImagePath = path);
                        }),
                        _bottomAction(Icons.emoji_emotions_outlined, loc.postActionFeeling, () {}),
                        _bottomAction(Icons.place_outlined, loc.postActionLocation, () {}),
                        _bottomAction(Icons.star_outline, loc.postActionLifeEvent, () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: AppTheme.text,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(loc.postButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: _primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: AppTheme.text.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
