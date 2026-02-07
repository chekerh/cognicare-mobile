import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _marketPrimary = Color(0xFFADD8E6);
const Color _marketBackground = Color(0xFFF8FAFC);

/// Marketplace — écran de produits spécialisés (secteur famille).
class FamilyMarketScreen extends StatefulWidget {
  const FamilyMarketScreen({super.key});

  @override
  State<FamilyMarketScreen> createState() => _FamilyMarketScreenState();
}

class _FamilyMarketScreenState extends State<FamilyMarketScreen> {
  String? _selectedCategoryKey;

  List<String> _getCategories(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [loc.allItems, loc.sensory, loc.motorSkills, loc.cognitive];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    _selectedCategoryKey ??= loc.allItems;
    return Scaffold(
      backgroundColor: _marketBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecommendedSection(),
                    const SizedBox(height: 40),
                    _buildNewArrivalsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final categories = _getCategories(context);
    return Container(
      padding: EdgeInsets.fromLTRB(24, padding.top + 8, 24, 24),
      decoration: BoxDecoration(
        color: _marketPrimary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.marketplaceTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.marketplaceSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.text,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _headerButton(Icons.shopping_cart_outlined, onTap: () => context.push(AppConstants.familyCartRoute)),
                  const SizedBox(width: 12),
                  _headerButton(Icons.search),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat == _selectedCategoryKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryKey = cat),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E293B)
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.text,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.text, size: 22),
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 24),
                const SizedBox(width: 8),
                Text(
                  '${loc.recommendedFor} Leo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                loc.seeAll,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _recommendedCard(
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBxLi3orbHizk7ckWGJn-wDDnoiT68bQFAdQE-2k2Qbu6NU4QC3FrichU0ktckfBVTFKt3T7FN6J8FUnmaTDnkva4rGz0dNbR0Gsw4ChyoCA4H_RlQK9XF3MquE-uTTTFPzQQHNRyqOrbamEu0RcvMHe3sT5w0BJF9ipV-6DObg4ysAlFyJFoGYBfshDRWvsHoIoYaF4p5_k-uChYJ8cBjDxHYEQz_10CPUh8lqiyDYebcgVq9o-nETukSZoBuEuPkDZYSoTpZNBn8',
                badge: 'TOP MATCH',
                badgeColor: Colors.blue,
                title: 'Couverture Lestée',
                description: 'Supports calming & focus during therapy sessions.',
                price: '75,00 €',
              ),
              const SizedBox(width: 16),
              _recommendedCard(
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC-uOu2EBOideyKHZ3aHAnGgnePHDk-aH6Fn6t1m634WaIxnwJ2ssK7fki_vUzPAf4W8UTWCUrZLh4fbZeiC2Bk7dTSEiknBKSh6kA551PEZJTZZOmhyUvupWr7Y6lsE-6OjTrcEDmNnlqWObalWPLMqyLkVfH0qEw7y96UMsAkT5A9gYlNgPPfOWUhW7Wjao3Q1ZpBKNTV4gUagr5_xE0cdOMEeTe295mZVWEZAAo82wsYT5WrvFms0CzRjIDdo-peE31HgMpt_sg',
                badge: 'SKILL BUILDER',
                badgeColor: Colors.green,
                title: 'Tactile Learning Blocks',
                description: 'Helps develop fine motor skills and texture recognition.',
                price: '\$29.99',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recommendedCard({
    required String imageUrl,
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
    required String price,
  }) {
    return InkWell(
      onTap: () {
        context.push(
          AppConstants.familyProductDetailRoute,
          extra: {
            'productId': 'rec_${title.toLowerCase().replaceAll(' ', '_')}',
            'title': title,
            'price': price,
            'imageUrl': imageUrl,
            'description': description,
            'badge': badge,
            'badgeColorValue': badgeColor.value,
          },
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.text.withOpacity(0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  context.push(
                    AppConstants.familyProductDetailRoute,
                    extra: {
                      'productId': 'rec_${title.toLowerCase().replaceAll(' ', '_')}',
                      'title': title,
                      'price': price,
                      'imageUrl': imageUrl,
                      'description': description,
                      'badge': badge,
                      'badgeColorValue': badgeColor.value,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _marketPrimary,
                  foregroundColor: AppTheme.text,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.buyNow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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

  Widget _buildNewArrivalsSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.newArrivals,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            IconButton(
              icon: Icon(Icons.filter_list, color: AppTheme.text.withOpacity(0.5)),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
          children: [
            _newArrivalCard(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCeBsd9Ar7OH6_rpkgbIasudntV5c7-dfpPEF2Zx-tP_NzyapqFy5A8YnkTUv4HfUSGhiYKjXGuBoRlAkbjAcg1BtrEvGumxx90s0d9mH6oKuqsnB_pqO0OKnglxWSayd-95w5vYhjVLCNGvGkVDpUxYWV6l00wFP6RJxjrnW8hhtfVXOgGTg1TtQgwrn145xVOElSf9t8EyuPEbfV8K2z6tc8dP4LEYGiFd93LYLpOWtAf7hdzEY_scWuDTMWw30NG2JBDn65KgiQ',
              title: 'Wooden Busy Board',
              price: '\$34.50',
            ),
            _newArrivalCard(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBABVPEASU4jCLRG7bhZN43VBiFisEWfpqL_AtTIkJbQw5aiK8pLuG0kgWP_OSjVaAAUI7F9B-WUKymT1ZCVRmZPd9MZton4Lww285Y4vWbrZoKCEhgScmr8B2GsE9AFmfWTqostXiEy-ZO9Txouc9xbblaTqbJXo_0yBl3FUkJ5UGa3rQAWEMlc_68cKSs9sWvq0GHKXizppuHryIbdBAfESY-l2WvUUsAEj932Jz3gTzq5wIXDSdXiXdkVcbg_tJ30gfgVeAL340',
              title: 'Chewelry Pendant',
              price: '\$12.00',
            ),
            _newArrivalCard(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC91Fd-UC3F0OSuK7WYyf-FAXG_H6CQOD2uuEMt-S6janyTZ8wXm2tnVqmwaymPBhXF8yP7zhpqhdB6ISSo0L-dJaBkh_2FZ5HnrG9LgvwX85YJMFJzigNKka5MxLHVXJR_jC5UfAkKCQWBJIebIT4x1CjklkDlq0auaCwPG3fR8oj4Fcdn2DB4pr2VZGEcuOChw0dEIG8lT85o80KSrhlyKfkttcpXpvKsodsdbsBNE-2tSIogtZzGt9WZm7eugV3YVUHjBWPZ5so',
              title: 'Stepping Stones',
              price: '\$58.00',
            ),
            _newArrivalCard(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDGGBbMr_3IRSdC00G26z3PNobjejfKyE-QWCVKNcJX_I0ePxJ3jz9Au9eEgApDmgp29b-CbKp-I5Qh8IqYcfiPxKjy5fmwDen_WYL7vcGk5JiqtllJRnLO0HRVQ_2TdqRQW_BtBLa2ffc0TAqWLyM-_2hMa7BBDPtFOaazRgZdUxAZYgfzNnlsIHxZbNkDhp-4yn5HTo53QYK2w69BA5lm9JLSypSfS4kOdhBJVft-f2W4vIwwqVJtNh6SGR24eWBfZe7P20jmGAw',
              title: 'Junior QuietHub',
              price: '\$24.99',
            ),
          ],
        ),
      ],
    );
  }

  Widget _newArrivalCard({
    required String imageUrl,
    required String title,
    required String price,
  }) {
    return InkWell(
      onTap: () {
        context.push(
          AppConstants.familyProductDetailRoute,
          extra: {
            'productId': 'new_${title.toLowerCase().replaceAll(' ', '_')}',
            'title': title,
            'price': price,
            'imageUrl': imageUrl,
            'description': _getDescriptionForProduct(title),
          },
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
            SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push(
                  AppConstants.familyProductDetailRoute,
                  extra: {
                    'productId': 'new_${title.toLowerCase().replaceAll(' ', '_')}',
                    'title': title,
                    'price': price,
                    'imageUrl': imageUrl,
                    'description': _getDescriptionForProduct(title),
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                backgroundColor: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.quickBuy,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _getDescriptionForProduct(String title) {
    switch (title) {
      case 'Wooden Busy Board':
        return 'Tableau d\'activités en bois avec multiples éléments interactifs pour développer la motricité fine et la coordination œil-main.';
      case 'Chewelry Pendant':
        return 'Pendentif masticable sûr et discret, conçu pour répondre aux besoins sensoriels oraux tout en étant élégant et portable.';
      case 'Stepping Stones':
        return 'Pierres d\'équilibre colorées pour améliorer la coordination, l\'équilibre et la force musculaire à travers le jeu actif.';
      case 'Junior QuietHub':
        return 'Casque antibruit adapté aux enfants, offrant une réduction sonore pour créer un environnement calme et apaisant.';
      default:
        return 'Produit de qualité conçu pour soutenir le développement et le bien-être.';
    }
  }
}
