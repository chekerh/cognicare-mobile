import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/community_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../utils/constants.dart';

// Design aligné sur le HTML Stitch : premium community feed
const Color _volunteerPrimary = Color(0xFFa3dae1);
const Color _volunteerBg = Color(0xFFFDFEFF);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);
const Color _textSlate400 = Color(0xFF94A3B8);
const Color _borderSlate = Color(0xFFF1F5F9);

String _fullImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}

/// Fil communautaire bénévole — même données que le feed famille, UI différente.
/// Si [showHeader] est false, seul le contenu (carte + liste) est affiché (pour intégration dans la section Communauté).
class VolunteerCommunityFeedScreen extends StatefulWidget {
  const VolunteerCommunityFeedScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  State<VolunteerCommunityFeedScreen> createState() =>
      _VolunteerCommunityFeedScreenState();
}

class _VolunteerCommunityFeedScreenState
    extends State<VolunteerCommunityFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunityFeedProvider>(context, listen: false).loadFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = widget.showHeader;
    return Scaffold(
      backgroundColor: _volunteerBg,
      body: Consumer<CommunityFeedProvider>(
        builder: (context, feed, _) {
          if (!feed.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: _volunteerPrimary),
            );
          }
          final body = RefreshIndicator(
            onRefresh: () => feed.loadFromStorage(),
            color: _volunteerPrimary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCreatePostCard(context, feed)),
                if (feed.posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 56,
                            color: _volunteerPrimary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune publication pour le moment.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Soyez le premier à partager.',
                            style: TextStyle(
                              fontSize: 14,
                              color: _textMuted.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate(
                      feed.posts
                          .map((post) => _buildPostCard(context, post, feed))
                          .toList(),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
          if (showHeader) {
            return Column(
              children: [
                _buildHeaderWave(context),
                Expanded(child: body),
              ],
            );
          }
          return SizedBox.expand(child: body);
        },
      ),
    );
  }

  Widget _buildHeaderWave(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: _volunteerPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.elliptical(400, 28),
          bottomRight: Radius.elliptical(400, 28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: _volunteerPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CogniCare',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        border: Border.all(color: _volunteerPrimary, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSegmentTabs(context),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                'Community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppConstants.volunteerCommunityDonationsRoute),
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Donations',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppConstants.volunteerCommunityMarketRoute),
                borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Marketplace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard(BuildContext context, CommunityFeedProvider feed) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final name = auth.user?.fullName?.trim() ?? '';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _volunteerPrimary,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _volunteerPrimary.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _volunteerPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await context.push(AppConstants.volunteerCommunityCreatePostRoute);
                        if (!context.mounted) return;
                        feed.loadFromStorage();
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Share an experience...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textMuted.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _createPostAction(
                      icon: Icons.image_outlined,
                      label: 'Photo',
                      onTap: () async {
                        await context.push(AppConstants.volunteerCommunityCreatePostRoute);
                        if (!context.mounted) return;
                        feed.loadFromStorage();
                      },
                    ),
                    const SizedBox(width: 16),
                    _createPostAction(
                      icon: Icons.mood_outlined,
                      label: 'Feeling',
                      onTap: () async {
                        await context.push(AppConstants.volunteerCommunityCreatePostRoute);
                        if (!context.mounted) return;
                        feed.loadFromStorage();
                      },
                    ),
                  ],
                ),
                Material(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () async {
                      await context.push(AppConstants.volunteerCommunityCreatePostRoute);
                      if (!context.mounted) return;
                      feed.loadFromStorage();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _volunteerPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createPostAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _avatarColorFor(String name) {
    final i = name.hashCode.abs() % 4;
    switch (i) {
      case 0:
        return const Color(0xFFE0F2FE); // sky-50
      case 1:
        return const Color(0xFFF3E8FF); // purple-50
      case 2:
        return const Color(0xFFDCFCE7); // green-50
      default:
        return const Color(0xFFFEF3C7); // amber-50
    }
  }

  static Color _avatarTextColorFor(String name) {
    final i = name.hashCode.abs() % 4;
    switch (i) {
      case 0:
        return const Color(0xFF0EA5E9); // sky-500
      case 1:
        return const Color(0xFFA855F7); // purple-500
      case 2:
        return const Color(0xFF22C55E); // green-500
      default:
        return const Color(0xFFF59E0B); // amber-500
    }
  }

  Widget _buildPostCard(
    BuildContext context,
    CommunityPost post,
    CommunityFeedProvider feed,
  ) {
    final likeCount = feed.getLikeCount(post.id);
    final liked = feed.isLiked(post.id);
    final comments = feed.getComments(post.id);
    final avatarBg = _avatarColorFor(post.authorName);
    final avatarFg = _avatarTextColorFor(post.authorName);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _borderSlate.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _volunteerPrimary.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: avatarFg.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        post.authorName.isNotEmpty
                            ? post.authorName
                                .substring(0, 1)
                                .toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: avatarFg,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                            fontSize: 15,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post.timeAgo.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _textSlate400,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    color: _textSlate400,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                post.text,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            if (post.hasImage && post.imagePath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildPostImage(post.imagePath!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _borderSlate),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _actionChip(
                          icon: liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: '$likeCount',
                          color: liked
                              ? Colors.pink
                              : _volunteerPrimary,
                          onTap: () => feed.toggleLike(post.id),
                        ),
                        const SizedBox(width: 24),
                        _actionChip(
                          icon: Icons.chat_bubble_outline,
                          label: '${comments.length}',
                          color: _textSlate400,
                          onTap: () async {
                            await feed.loadCommentsForPost(post.id);
                            if (!context.mounted) return;
                            _showCommentsBottomSheet(
                                context, post.id, feed);
                          },
                        ),
                      ],
                    ),
                    _actionChip(
                      icon: Icons.share_outlined,
                      label: null,
                      color: _textSlate400,
                      onTap: () {
                        Share.share(
                          '${post.authorName}: ${post.text}\n\n— CogniCare Communauté',
                          subject: 'Publication CogniCare',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String? label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(String imagePath) {
    // Même logique que family : réseau seulement pour URL absolue ou chemin backend /uploads/
    final isNetwork = imagePath.startsWith('http') ||
        imagePath.startsWith('/uploads/');
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: isNetwork
          ? Image.network(
              imagePath.startsWith('http') ? imagePath : _fullImageUrl(imagePath),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 220,
                  color: _volunteerPrimary.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: _volunteerPrimary,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
          : Image.file(
              File(imagePath),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: _volunteerPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: _volunteerPrimary.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(
    BuildContext context,
    String postId,
    CommunityFeedProvider feed,
  ) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: _cardBg,
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
                    const Text(
                      'Commentaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: feed.getComments(postId).map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _volunteerPrimary.withOpacity(0.25),
                            child: Text(
                              (c.authorName.isNotEmpty
                                      ? c.authorName.substring(0, 1)
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  c.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          hintStyle: TextStyle(
                            color: _textMuted,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: _volunteerPrimary.withOpacity(0.3),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isEmpty) return;
                          feed.addComment(
                            postId,
                            auth.user?.fullName ?? 'Anonyme',
                            text,
                          );
                          controller.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: _volunteerPrimary,
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        feed.addComment(
                          postId,
                          auth.user?.fullName ?? 'Anonyme',
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
}
