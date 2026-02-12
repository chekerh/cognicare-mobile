import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/sticker_book_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/gamification_helper.dart';
import '../../services/gamification_service.dart';

const Color _primary = Color(0xFF2B8CEE);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF617589);

enum _BasketCategory { food, toys }

class _SortItem {
  final String imageUrl;
  final _BasketCategory category;

  const _SortItem({required this.imageUrl, required this.category});
}

/// Basket Sort Challenge — glisser l'objet dans le bon panier (Food / Toys).
class BasketSortScreen extends StatefulWidget {
  const BasketSortScreen({super.key});

  @override
  State<BasketSortScreen> createState() => _BasketSortScreenState();
}

class _BasketSortScreenState extends State<BasketSortScreen> {
  /// Images adaptées au jeu : nourriture (Food) et jouets (Toys).
  static const List<_SortItem> _items = [
    // 1. Pomme → Food
    _SortItem(
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDSzNDFIdXybA63B3hyJlf3_60pXxXpy0pc4oW4bO__FjO3PcbgMI1q59HegYo2OBPmBP6BIRxX407O2iodwQiGh-w1o7juvNqTGtP4L7nbgtGYPKJYYjiPPjl-1oBJGH76EN7exYxdHGDj9qg9g_770p7BfWH2hjwgoaYf_dHtoeSGizCJesYJYKqjoemfVcWHMJcw_o-f70eNlQ45xC7D0h7EpWl77GTJA7Ha2lGqLbijZVG6iAt8CT7uY3WyT0v7ikvgPABbMbU',
      category: _BasketCategory.food,
    ),
    // 2. Ballon → Toys
    _SortItem(
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Football_%28soccer_ball%29.svg/240px-Football_%28soccer_ball%29.svg.png',
      category: _BasketCategory.toys,
    ),
    // 3. Banane → Food
    _SortItem(
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/8a/Banana-Single.jpg',
      category: _BasketCategory.food,
    ),
    // 4. Peluche → Toys
    _SortItem(
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Teddy_bear_holding_heart.jpg/240px-Teddy_bear_holding_heart.jpg',
      category: _BasketCategory.toys,
    ),
  ];

  int _currentIndex = 0;
  int _completedCount = 0;
  bool _gameFinished = false;
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
  }

  void _onDroppedCorrect() {
    if (_gameFinished) return;
    setState(() {
      _completedCount++;
      if (_currentIndex + 1 >= _items.length) {
        _gameFinished = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final timeSpent = _gameStartTime != null
              ? DateTime.now().difference(_gameStartTime!).inSeconds
              : null;
          await recordGameCompletion(
            context: context,
            levelKey: 'basket_sort',
            gameType: GameType.basket_sort,
            timeSpentSeconds: timeSpent,
            metrics: {'itemsSorted': _items.length},
          );
          if (!context.mounted) return;
          final provider = Provider.of<StickerBookProvider>(context, listen: false);
          final stickerIndex = provider.unlockedCount - 1;
          if (!context.mounted) return;
          context.push(AppConstants.familyGameSuccessRoute, extra: {
            'stickerIndex': stickerIndex,
            'gameRoute': AppConstants.familyBasketSortRoute,
          });
        });
      } else {
        _currentIndex++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bravo),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _onDroppedWrong() {
    if (_gameFinished) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.tryAgain),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    loc.homeForObjects,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.dragItemToBasket,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildProgress(),
            const SizedBox(height: 24),
            Expanded(
              child: _gameFinished
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDraggableItem(loc),
                        _buildBaskets(loc),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: _textDark, size: 28),
          ),
          Expanded(
            child: Text(
              loc.gameBasketSort,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: _textDark, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final filled = i < _completedCount;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 48,
            height: 12,
            decoration: BoxDecoration(
              color: filled ? _primary : _primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDraggableItem(AppLocalizations loc) {
    final item = _items[_currentIndex];

    return Draggable<_BasketCategory>(
      data: item.category,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 64),
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _itemCard(item),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _itemCard(item),
          const SizedBox(height: 16),
          Icon(Icons.drag_indicator, color: _primary.withOpacity(0.5), size: 40),
        ],
      ),
    );
  }

  Widget _itemCard(_SortItem item) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.2), width: 4),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 64),
        ),
      ),
    );
  }

  Widget _buildBaskets(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: _BasketTarget(
              category: _BasketCategory.food,
              label: loc.food,
              icon: Icons.restaurant,
              onAccept: _onDroppedCorrect,
              onWrong: _onDroppedWrong,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _BasketTarget(
              category: _BasketCategory.toys,
              label: loc.toys,
              icon: Icons.smart_toy,
              onAccept: _onDroppedCorrect,
              onWrong: _onDroppedWrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketTarget extends StatelessWidget {
  const _BasketTarget({
    required this.category,
    required this.label,
    required this.icon,
    required this.onAccept,
    required this.onWrong,
  });

  final _BasketCategory category;
  final String label;
  final IconData icon;
  final VoidCallback onAccept;
  final VoidCallback onWrong;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_BasketCategory>(
      onAcceptWithDetails: (details) {
        if (details.data == category) {
          onAccept();
        } else {
          onWrong();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHovering ? _primary.withOpacity(0.15) : _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? _primary : _primary.withOpacity(0.3),
              width: 4,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_basket_outlined, color: _primary, size: 48),
              const SizedBox(height: 8),
              Icon(icon, color: _primary, size: 40),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
