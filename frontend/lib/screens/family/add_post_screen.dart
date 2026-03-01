import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFA3DAE1);
const Color _backgroundLight = Color(0xFFF5F9FA);

/// Écran « Nouvelle Publication » : design Stitch (header, user + Public, cartes catégorie, zone texte type glass, Galerie/Humeur/Lieu, bouton Publier).
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _controller = TextEditingController();
  bool _isPosting = false;
  String? _selectedImagePath;
  int _selectedCategoryIndex = 0;

  static const List<({String label, IconData icon, Color color})> _categories = [
    (label: 'Milestone', icon: Icons.emoji_events, color: Color(0xFFFEF3C7)),
    (label: 'Tip', icon: Icons.lightbulb_outline, color: Color(0xFFDBEAFE)),
    (label: 'Question', icon: Icons.help_outline, color: Color(0xFFF3E8FF)),
  ];

  static const List<Color> _categoryIconColors = [
    Color(0xFFEAB308),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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
        const SnackBar(
          content: Text('Partagez votre expérience pour publier.'),
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
          content: Text(e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Échec de la publication'),
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
      const SnackBar(
        content: Text('Publication partagée dans la communauté.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final initial = (user?.fullName ?? 'U').substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.text, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Nouvelle Publication',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.text, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // User row: avatar + status dot, name, Public
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _primary.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.public, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              'PUBLIC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Category cards grid (3)
              Row(
                children: List.generate(3, (i) {
                  final cat = _categories[i];
                  final isActive = _selectedCategoryIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 2 ? 0 : 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategoryIndex = i),
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isActive ? _primary : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: _primary.withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cat.color,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    size: 24,
                                    color: _categoryIconColors[i],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Glass-style content container
              Container(
                constraints: const BoxConstraints(minHeight: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 8,
                      minLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience...',
                        hintStyle: TextStyle(
                          color: AppTheme.text.withOpacity(0.5),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppTheme.text.withOpacity(0.12),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _actionButton(Icons.image_outlined, 'Galerie', () async {
                            final path = await _pickImage();
                            if (path != null && mounted) {
                              setState(() => _selectedImagePath = path);
                            }
                          }),
                          _actionButton(Icons.mood_outlined, 'Humeur', () {}),
                          _actionButton(Icons.location_on_outlined, 'Lieu', () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedImagePath != null) ...[
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_selectedImagePath!),
                        width: double.infinity,
                        height: 200,
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
              const SizedBox(height: 32),
              // Publier button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isPosting ? null : _submit,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isPosting
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Publier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
