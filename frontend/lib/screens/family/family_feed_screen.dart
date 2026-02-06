import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// Couleurs du design HTML Family Community Feed
const Color _feedPrimary = Color(0xFFA3D9E2);
const Color _feedSecondary = Color(0xFF7FBAC4);
const Color _feedBackground = Color(0xFFF8FAFC);

/// Construit l'URL complète pour une image du backend (ex. /uploads/posts/xxx.jpg).
String _fullImageUrl(String path) {
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : path;
}

/// Family Community Feed — aligné sur le design HTML fourni.
/// Header blanc (psychology + CogniCare), onglets Community/Marketplace/Experts,
/// carte Family Chat, partage, fil de posts, section From Marketplace.
class FamilyFeedScreen extends StatefulWidget {
  const FamilyFeedScreen({super.key});

  @override
  State<FamilyFeedScreen> createState() => _FamilyFeedScreenState();
}

class _FamilyFeedScreenState extends State<FamilyFeedScreen> {
  int _selectedTab = 0; // 0: Community, 1: Marketplace, 2: Experts

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 88;
    return Scaffold(
      backgroundColor: _feedBackground,
      body: Consumer<CommunityFeedProvider>(
        builder: (context, feedProvider, _) {
            if (!feedProvider.isLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                feedProvider.loadFromStorage();
              });
            }
            return CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(child: _buildTabs()),
                SliverToBoxAdapter(child: _buildFamilyChatCard()),
                SliverToBoxAdapter(child: _buildShareCard()),
                if (feedProvider.posts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 56,
                              color: _feedPrimary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noPostsYet,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.tapToShare,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.text.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                SliverList(
                  delegate: SliverChildListDelegate(
                    _buildFeedPostsFromProvider(context, feedProvider),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFromMarketplaceSection()),
                SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
              ],
            );
          },
        ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = MediaQuery.paddingOf(context);
          final horizontal = (padding.horizontal + 16).clamp(16.0, 24.0);
          return Container(
            color: _feedPrimary,
            padding: EdgeInsets.fromLTRB(horizontal, padding.top + 12, horizontal, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology, color: _feedPrimary, size: 22),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CogniCare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _headerButton(Icons.search),
                    const SizedBox(width: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _headerButton(Icons.notifications_outlined),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: _feedPrimary, width: 1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerButton(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 22),
      splashRadius: 22,
    );
  }

  Widget _buildTabs() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _feedPrimary,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          _tab(loc.community, 0),
          _tab(loc.marketplaceTitle, 1),
          _tab(loc.experts, 2),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: _feedSecondary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyChatCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.text.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 40,
              child: Stack(
                children: [
                  Positioned(left: 0, child: _avatarCircle('D', 20)),
                  Positioned(left: 32, child: _avatarCircle('M', 20)),
                  Positioned(
                    left: 64,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _feedPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '+2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.familyChat,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mom: "Check out this toy!"',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: _feedPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    AppLocalizations.of(context)!.open,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _feedSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarCircle(String letter, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _feedPrimary.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppTheme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    final user = Provider.of<AuthProvider>(context).user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppConstants.familyCreatePostRoute),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _feedPrimary.withOpacity(0.3),
                  child: Text(
                    (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _feedBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.shareExperiencePlaceholder,
                      style: TextStyle(
                        color: AppTheme.text.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.add_photo_alternate, color: _feedPrimary, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<(Color, String)> _tagColors = [
    (Color(0xFF3B82F6), 'blue'),
    (Color(0xFF9333EA), 'purple'),
    (Color(0xFF0D9488), 'teal'),
    (Color(0xFFEA580C), 'orange'),
  ];

  List<Widget> _buildFeedPostsFromProvider(
    BuildContext context,
    CommunityFeedProvider feedProvider,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return feedProvider.posts.map((post) {
      final tagStyles = post.tags.asMap().entries.map((e) {
        final c = _tagColors[e.key % _tagColors.length];
        return (c.$1, e.value);
      }).toList();
      final comments = feedProvider.getComments(post.id);
      final lastComment = comments.isNotEmpty
          ? '${comments.first.authorName}: ${comments.first.text}'
          : null;
      final currentUserId = authProvider.user?.id;
      final canDelete = currentUserId != null && currentUserId == post.authorId;
      return _buildPost(
        postId: post.id,
        name: post.authorName,
        time: post.timeAgo,
        text: post.text,
        tagStyles: tagStyles,
        likes: feedProvider.getLikeCount(post.id),
        comments: comments.length,
        liked: feedProvider.isLiked(post.id),
        hasImage: post.hasImage,
        imagePath: post.imagePath,
        lastComment: lastComment,
        onLikeTap: () => feedProvider.toggleLike(post.id),
        onCommentTap: () async {
          await feedProvider.loadCommentsForPost(post.id);
          if (context.mounted) {
            _showCommentsSheet(context, post.id, feedProvider, authProvider);
          }
        },
        canDelete: canDelete,
        onEditTap: canDelete
            ? () => _showEditPostDialog(context, post.id, post.text, feedProvider)
            : null,
        onDeleteTap: canDelete
            ? () async {
                final loc = AppLocalizations.of(context)!;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.deletePost),
                    content: Text(loc.deletePostConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(loc.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await feedProvider.deletePost(post.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.postDeleted),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            : null,
      );
    }).toList();
  }

  void _showEditPostDialog(
    BuildContext context,
    String postId,
    String initialText,
    CommunityFeedProvider feedProvider,
  ) {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialText);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.editPostTitle),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: loc.shareExperiencePlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await feedProvider.updatePost(postId, newText);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.postUpdated),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.errorLoadingProfile),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    String postId,
    CommunityFeedProvider feedProvider,
    AuthProvider authProvider,
  ) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
              MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.comments,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: feedProvider.getComments(postId).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final c = feedProvider.getComments(postId)[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: _feedPrimary.withOpacity(0.4),
                        child: Text(
                          c.authorName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        c.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.text,
                        ),
                      ),
                      subtitle: Text(
                        c.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.text.withOpacity(0.85),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _feedPrimary.withOpacity(0.3),
                      child: Text(
                        (authProvider.user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.writeComment,
                          hintStyle: TextStyle(
                            color: AppTheme.text.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppTheme.text.withOpacity(0.2)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isEmpty) return;
                          feedProvider.addComment(
                            postId,
                            authProvider.user?.fullName ?? 'Anonymous',
                            text,
                          );
                          controller.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: _feedPrimary),
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        feedProvider.addComment(
                          postId,
                          authProvider.user?.fullName ?? 'Anonymous',
                          text,
                        );
                        controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPost({
    required String postId,
    required String name,
    required String time,
    required String text,
    required List<(Color, String)> tagStyles,
    required int likes,
    required int comments,
    required bool liked,
    required VoidCallback onLikeTap,
    required VoidCallback onCommentTap,
    bool canDelete = false,
    VoidCallback? onEditTap,
    VoidCallback? onDeleteTap,
    bool hasImage = false,
    String? imagePath,
    String? lastComment,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.text.withOpacity(0.06)),
          bottom: BorderSide(color: AppTheme.text.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _feedPrimary.withOpacity(0.4),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: AppTheme.text.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (canDelete && (onEditTap != null || onDeleteTap != null))
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: AppTheme.text.withOpacity(0.5),
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'edit' && onEditTap != null) {
                      onEditTap();
                    } else if (value == 'delete' && onDeleteTap != null) {
                      onDeleteTap();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEditTap != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.editPost),
                          ],
                        ),
                      ),
                    if (onDeleteTap != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.deletePost),
                          ],
                        ),
                      ),
                  ],
                )
              else
                Icon(Icons.more_horiz, color: AppTheme.text.withOpacity(0.3), size: 22),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tagStyles.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: e.$1.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        e.$2,
                        style: TextStyle(
                          color: e.$1,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath != null
                    ? (imagePath.startsWith('http') || imagePath.startsWith('/uploads/')
                        ? Image.network(
                            imagePath.startsWith('http')
                                ? imagePath
                                : _fullImageUrl(imagePath),
                            width: double.infinity,
                            height: 256,
                            fit: BoxFit.cover,
                            cacheWidth: 800,
                            cacheHeight: 512,
                            loadingBuilder: (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 256,
                                color: _feedPrimary.withOpacity(0.15),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: _feedSecondary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 256,
                              color: _feedPrimary.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 72,
                                color: _feedPrimary.withOpacity(0.6),
                              ),
                            ),
                          )
                        : Image.file(
                            File(imagePath),
                            width: double.infinity,
                            height: 256,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 256,
                              color: _feedPrimary.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 72,
                                color: _feedPrimary.withOpacity(0.6),
                              ),
                            ),
                          ))
                    : Container(
                        height: 256,
                        decoration: BoxDecoration(
                          color: _feedPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.child_care,
                            size: 72,
                            color: _feedPrimary.withOpacity(0.6),
                          ),
                        ),
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onLikeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: liked ? Colors.red : AppTheme.text.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: liked ? Colors.red : AppTheme.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onCommentTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 22,
                          color: AppTheme.text.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$comments',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.share_outlined, size: 22, color: AppTheme.text.withOpacity(0.5)),
              ],
            ),
          ),
          if (lastComment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _feedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _feedSecondary.withOpacity(0.3),
                      child: const Text(
                        'S',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastComment,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.text.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFromMarketplaceSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.text.withOpacity(0.06)),
          bottom: BorderSide(color: AppTheme.text.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.fromMarketplace,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.viewAll,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _feedPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _marketplaceCard(AppLocalizations.of(context)!.weightedBlanket, '\$45.00'),
                _marketplaceCard(AppLocalizations.of(context)!.noiseCancelling, '\$129.00'),
                _marketplaceCard(AppLocalizations.of(context)!.visualTimer, '\$18.50'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketplaceCard(String title, String price) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: _feedPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                title.contains(AppLocalizations.of(context)!.weightedBlanket) || title.contains('Blanket') || title.contains('Couverture')
                    ? Icons.bed
                    : title.contains(AppLocalizations.of(context)!.noiseCancelling) || title.contains('Noise') || title.contains('Bruit')
                        ? Icons.headphones
                        : Icons.timer_outlined,
                size: 40,
                color: _feedPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: _feedSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
