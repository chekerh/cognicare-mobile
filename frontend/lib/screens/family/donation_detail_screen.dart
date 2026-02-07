import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF0F7FF);

/// Page détail d'une annonce de don — design aligné sur le HTML fourni.
class DonationDetailScreen extends StatelessWidget {
  const DonationDetailScreen({super.key, this.title, this.description, this.fullDescription, this.conditionIndex = 0, this.categoryIndex = 0, this.imageUrl = '', this.location = '', this.distanceText, this.donorName, this.donorAvatarUrl, this.donorRating});

  final String? title;
  final String? description;
  final String? fullDescription;
  final int conditionIndex;
  final int categoryIndex;
  final String imageUrl;
  final String location;
  final String? distanceText;
  final String? donorName;
  final String? donorAvatarUrl;
  final double? donorRating;

  static Map<String, dynamic> _extraFromState(GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    return extra ?? {};
  }

  factory DonationDetailScreen.fromState(GoRouterState state) {
    final e = _extraFromState(state);
    return DonationDetailScreen(
      title: e['title'] as String?,
      description: e['description'] as String?,
      fullDescription: e['fullDescription'] as String?,
      conditionIndex: e['conditionIndex'] as int? ?? 0,
      categoryIndex: e['categoryIndex'] as int? ?? 0,
      imageUrl: e['imageUrl'] as String? ?? '',
      location: e['location'] as String? ?? '',
      distanceText: e['distanceText'] as String?,
      donorName: e['donorName'] as String?,
      donorAvatarUrl: e['donorAvatarUrl'] as String?,
      donorRating: (e['donorRating'] as num?)?.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final conditionLabels = [loc.veryGoodCondition, loc.goodCondition, loc.likeNew];
    final conditionColors = [Colors.green, Colors.amber, Colors.green];
    final categoryLabels = [loc.all, loc.mobility, loc.earlyLearning, loc.clothing];
    final displayDescription = (fullDescription ?? description ?? '').trim().isNotEmpty ? (fullDescription ?? description)! : (description ?? '');
    final donor = donorName ?? 'Sophie M.';
    final rating = donorRating ?? 4.9;
    final avatarUrl = donorAvatarUrl ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuCxbVRWBSYTDKId85kQAuSX5JA8c-eT0A5QUwJLIg_p5WszXzBgyevGPwH63Pjo19KKDvjOwP5gbClRYgouv7Wd56Ik5ZNe0eIB0pB5B31FWEzA4zVWO9n7lznIK4Oo4Pr16H2N2DBZPkq7liRPNHSuB16JQMVa2qKn1BdONq1iyaNCZ51EaDzu7uAJT_2cR14x2M12f0MFgq1FluiBC0utFUxdv0uDnI843xsSa_IUY_sygaC2DL0mGixfoSkCsnIOhP809UKt19Q';
    final distance = distanceText ?? '2 km';

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImage(context, imageUrl),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: Transform.translate(
                        offset: const Offset(0, -40),
                        child: _buildCard(
                          context,
                          loc: loc,
                          title: title ?? '',
                          description: displayDescription,
                          conditionLabel: conditionLabels[conditionIndex.clamp(0, 2)],
                          conditionColor: conditionColors[conditionIndex.clamp(0, 2)],
                          categoryLabel: categoryIndex >= 0 && categoryIndex < categoryLabels.length ? categoryLabels[categoryIndex] : loc.clothing,
                          donorName: donor,
                          donorAvatarUrl: avatarUrl,
                          rating: rating,
                          location: location,
                          distanceText: distance,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context, loc),
          ],
        ),
      ),
    );
  }

  void _shareDonation() {
    final donor = donorName ?? 'Donateur';
    final t = title ?? '';
    final shareText = '$t — $donor\n$location\n\n— CogniCare Le Cercle du Don';
    Share.share(shareText, subject: t.isNotEmpty ? t : 'Annonce de don');
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, color: _primary, size: 20),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _shareDonation,
                icon: const Icon(Icons.share, color: _primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.report_outlined, color: _primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String url) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 64),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.favorite, color: Colors.red, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required AppLocalizations loc,
    required String title,
    required String description,
    required String conditionLabel,
    required Color conditionColor,
    required String categoryLabel,
    required String donorName,
    required String donorAvatarUrl,
    required double rating,
    required String location,
    required String distanceText,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: conditionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  conditionLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: conditionColor.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoryLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(donorAvatarUrl),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.donatedBy,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      donorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: _primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              Text(
                'À $distanceText ${loc.distanceFromYou}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 128,
              color: Colors.grey.shade100,
              child: Center(
                child: Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgLight.withOpacity(0), _bgLight],
        ),
      ),
      child: Material(
        elevation: 8,
        shadowColor: _primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        color: _primary,
        child: InkWell(
          onTap: () {
            context.push(AppConstants.familyDonationChatRoute, extra: {
              'donorName': donorName ?? 'Sophie M.',
              'donationTitle': title ?? '',
              'donorAvatarUrl': donorAvatarUrl,
              'donationImageUrl': imageUrl,
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  loc.contactDonor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
