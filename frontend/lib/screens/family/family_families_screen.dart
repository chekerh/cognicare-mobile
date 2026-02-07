import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

/// Écran Chats — trois onglets (Persons, Families, Benevole) comme Suivi.
/// Design Community Messaging Inbox : search, Online Now, liste de conversations.
const Color _primary = Color(0xFFA8DADC);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF8FAFC);

class _Conversation {
  final String id;
  final String name;
  final String? subtitle;
  final String lastMessage;
  final String timeAgo;
  final String imageUrl;
  final bool unread;

  const _Conversation({
    required this.id,
    required this.name,
    this.subtitle,
    required this.lastMessage,
    required this.timeAgo,
    required this.imageUrl,
    this.unread = false,
  });
}

class FamilyFamiliesScreen extends StatefulWidget {
  const FamilyFamiliesScreen({super.key});

  @override
  State<FamilyFamiliesScreen> createState() => _FamilyFamiliesScreenState();
}

class _FamilyFamiliesScreenState extends State<FamilyFamiliesScreen> {
  int _selectedTab = 0; // 0: Persons, 1: Families, 2: Benevole
  String _searchQuery = '';

  static const List<_Conversation> _personsConversations = [
    _Conversation(
      id: 'anna',
      name: 'Anna Thompson',
      lastMessage: 'Can you check the care schedule for...',
      timeAgo: '12:45 PM',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDHJAf0azJKUkbzzz6Bcwb2M305SDecnBYT5aHcQAn4p0WGspqTqhAfndL8PqN0YaJPuhzhedZURfNPBsEyA5q5JuNQoeW3RQ7ieZH5ODqt6Y0BvSIi27ccQKlT-LZ9u6EqV6N1bKDTAkSY2gHKWSaKL5tmKNDIt2l4pwq-rFJiiH-wy205On3InigQi49JXfhe4fq000NhscuYo0p7o7rST5_jHuexYNJd2wjERuzBDpzolB-0uXvjbMBffGP9zgNLwJv1T5-2wXk',
      unread: true,
    ),
    _Conversation(
      id: 'james',
      name: 'James Miller',
      lastMessage: 'The groceries are delivered!',
      timeAgo: '10:20 AM',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDwXbZVZLfcWG-73m-ZegPbPhSS6oSgppaLxbxDsEMQp27zS8cGqxZ6YQp6Nj8gQDW_20_K11eRZAE1vJpG9wzropzgVqpClEd9MVztkzv44n13sm82yGClacQzBrMst9Qc-uR4jJPW47BQwhUuTLQwJKNUMz4uQORyX_hKRADOm_NHP5QNGMJ8BZkEXYsxc3oUBvI9U66ZTvRJoDufAqjg3WUVkb4JI2z1sDpUL29AvmFtGRBaUZUE-0ARmChWvNq_JgV3M-mahAE',
    ),
    _Conversation(
      id: 'robert',
      name: 'Robert Wilson',
      lastMessage: 'Thanks for the update on dad.',
      timeAgo: 'Wednesday',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDc34EjqUb0TtfRcPnzS80n9y3CL6BKQg6e7ct2LqvGJlo6D1ST3fR9Etx5XKt2RkYs3cJeyiPPtJbLnGm-xYi4p15JsGiJTFGAcCeMRvCPbfhDSNEtuK7xOzTbfPJ3w1wjCmW-e8mGY19oGQCDHzTpZuX1SIQK5wcBM5o3CQrVx30b-MmmWVmQ8oNbrut9U3JHSo2OBqM6fL2_sdHkLaOFFyHjFA7hsX9eOns7FMBi7boksi_AUVpLtlw7EuXExHX94ILqwjk3Nkg',
    ),
    _Conversation(
      id: 'emily',
      name: 'Emily Davis',
      lastMessage: "I'll be there by 5pm tomorrow.",
      timeAgo: 'Oct 24',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDszriLU7EcBb9N9Kol0oRVXcjK1PwAmtnkK9mE-dPMkvbw0IreIU_zF7BQMFiAbcX4pUyf1SkDQ-AsXLZUmjt45VEagdelyetj-0W1rmXZcF8JgLuSl9gJlEQPoIk0qnAglOhN3qMTrNxTvbk_pL6BeUiLZ0FyisORdKJHobC3Li83fcKCHgL4_OUslfxKu7N53c-f0ZTR0GVM6DZ5NvA79wFarTK8JvO5d0rnw_n-wZWxPu_bWlMFVw9nOh1fKeBo5LXNAc4bKOM',
    ),
    _Conversation(
      id: 'tom',
      name: 'Tom H.',
      lastMessage: 'See you at the therapy session.',
      timeAgo: 'Oct 22',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAvtxHTcUcFC4I7u4JJjR3Njam4tZCuCDQpQe63wniNL2lkjAIqyqDlQ0GqMHhKJ0kJg4NgT-IQ54UjQiExzyeGYsJZQzepnbPdwjWJVVmHzXaWqrCNkxR6FJjCKEtC2eNIkecDSDJXdTfx-LeSLzHTeIT3kucwQd-5vSNtybUkq7hW1h1B0U_pXcKBykz69Ckc77K1QUcqAcbX7sC21fpHIRNporbKK-v2Rg500svi31GYTirjpWpVniwCm8eC4z2DBtx5OVx7Mj4',
    ),
  ];

  static const List<_Conversation> _familiesConversations = [
    _Conversation(
      id: 'miller',
      name: 'The Miller Family',
      subtitle: '5 members',
      lastMessage: 'Thanks for the update! We\'ll try the same at home tomorrow.',
      timeAgo: 'Yesterday',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDwXbZVZLfcWG-73m-ZegPbPhSS6oSgppaLxbxDsEMQp27zS8cGqxZ6YQp6Nj8gQDW_20_K11eRZAE1vJpG9wzropzgVqpClEd9MVztkzv44n13sm82yGClacQzBrMst9Qc-uR4jJPW47BQwhUuTLQwJKNUMz4uQORyX_hKRADOm_NHP5QNGMJ8BZkEXYsxc3oUBvI9U66ZTvRJoDufAqjg3WUVkb4JI2z1sDpUL29AvmFtGRBaUZUE-0ARmChWvNq_JgV3M-mahAE',
    ),
    _Conversation(
      id: 'martin',
      name: 'Famille Martin',
      subtitle: '4 members',
      lastMessage: 'Prochaine séance jeudi 14h.',
      timeAgo: 'Wed',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBhVL3VBXE0i2BjxqAcOBoOmNLabgSEwQ0BSqK9KFpCHBv2gVAbNssAPwPM49W2ZcgK0DveLKCgKn4LHDW7CwQyhALhfcKd0oayPrE_XO4Be9N8zPzCIvmjuAift3-7jLgMTE3rSp5hW34kuA5wLOeyHQw9h54wLIl63mFxps6bcXG8xCeEm0DbntaNIHp9BEimURk2bALoBI_PHsPr_B1CyYtO9afJgcYput0wUxixP_NVLmRiB5V3z4mdBs77L9wN_LLzHlFzpDA',
    ),
    _Conversation(
      id: 'bernard',
      name: 'Famille Bernard',
      subtitle: '6 members',
      lastMessage: '2 nouveaux messages',
      timeAgo: 'Tue',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAsji4rq00CvgTjrqj0TV2CliKENsYqJ8-UKNkg5oIVkyVDAci-QgpIOdGG5GvJ5cR_wYg5VmEZBcvyDncmrD2XpaK4SzziL3TUXUwKYGJ4mYV9_R9TqIVOASBz2pwCSNTCfrKHj2pTWTtDqUPdG99b79SSBtFljzq3QamSOzNh8XX_LBZqq0_WmIFFCBIQE_GFJ8OIhXmdsaAAzzGZeWOG-4g3PeDVh8qphKET_B3HnUMAyUT0-idC3O-GsMaDuEqLhde_nfo53dI',
      unread: true,
    ),
  ];

  static const List<_Conversation> _benevoleConversations = [
    _Conversation(
      id: 'community',
      name: 'Community Care',
      subtitle: 'Support Team',
      lastMessage: 'Welcome to the family workspace!',
      timeAgo: 'Yesterday',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC8Tv2g9ilJqAJKRCiwgC1P3B1pbGWt_FJ7j4PDltZ5Cefa7FqEXuHjoBoTPIv_RCTD5Cz2FRItOVOQkFh2TiZyuiDdCfqFDhZDk2LSpKOI5yPstLzMuyCX9ryWoG7AiaC8KjbZjg4dLvlmHOmFkFwxPU4Ua4CNdQfmRoPd-NYzFZczC0lgf0p_SgrB0TkpQ14z5dN3n4ugxWrEvQhQ4wbF8hkEJWHUu7Am6ibxcUAI_EIReHqNiORhJjghtRXbFtucTHk3L1hGcEQ',
      unread: true,
    ),
    _Conversation(
      id: 'volunteer1',
      name: 'Équipe Bénévoles',
      subtitle: 'Volunteers',
      lastMessage: 'Session de soutien prévue ce weekend.',
      timeAgo: 'Oct 24',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDq4SZn2pgmfLRrOm6i91kyg4nx1XofXHba8yneHiAUbTDVssCW-EyE6Yxy9vugCIKinxGOMV_MDAk5Pw5ClDLj-yaRbklg9bzxwI9buksG3mJYX7fJxoBf056Yl049I5R7HB1j0WGVQCryoucfZHb8mU5j-1k9XwDh77SRHDDrKwAvg8xiRB-jLYp1EzCtMo0wLXDUQVQEyFBLfgbjcn5gB1WduHtkWg7MchvYuZFXKIzrGYNdEt1EFaO2f4BzkvGw6XBWMh3MrAc',
    ),
  ];

  static const List<Map<String, String>> _onlineNow = [
    {'name': 'Sarah J.', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDq4SZn2pgmfLRrOm6i91kyg4nx1XofXHba8yneHiAUbTDVssCW-EyE6Yxy9vugCIKinxGOMV_MDAk5Pw5ClDLj-yaRbklg9bzxwI9buksG3mJYX7fJxoBf056Yl049I5R7HB1j0WGVQCryoucfZHb8mU5j-1k9XwDh77SRHDDrKwAvg8xiRB-jLYp1EzCtMo0wLXDUQVQEyFBLfgbjcn5gB1WduHtkWg7MchvYuZFXKIzrGYNdEt1EFaO2f4BzkvGw6XBWMh3MrAc'},
    {'name': 'Elena', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBhVL3VBXE0i2BjxqAcOBoOmNLabgSEwQ0BSqK9KFpCHBv2gVAbNssAPwPM49W2ZcgK0DveLKCgKn4LHDW7CwQyhALhfcKd0oayPrE_XO4Be9N8zPzCIvmjuAift3-7jLgMTE3rSp5hW34kuA5wLOeyHQw9h54wLIl63mFxps6bcXG8xCeEm0DbntaNIHp9BEimURk2bALoBI_PHsPr_B1CyYtO9afJgcYput0wUxixP_NVLmRiB5V3z4mdBs77L9wN_LLzHlFzpDA'},
    {'name': 'Marcus', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAsji4rq00CvgTjrqj0TV2CliKENsYqJ8-UKNkg5oIVkyVDAci-QgpIOdGG5GvJ5cR_wYg5VmEZBcvyDncmrD2XpaK4SzziL3TUXUwKYGJ4mYV9_R9TqIVOASBz2pwCSNTCfrKHj2pTWTtDqUPdG99b79SSBtFljzq3QamSOzNh8XX_LBZqq0_WmIFFCBIQE_GFJ8OIhXmdsaAAzzGZeWOG-4g3PeDVh8qphKET_B3HnUMAyUT0-idC3O-GsMaDuEqLhde_nfo53dI'},
    {'name': 'David', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuATGLtJkH4eapa2uQ8y9o05fxfzui-Zg7gNykAgyOskh70eX3CYnoHpgC8s_YGtd5HUeQZxaTyD7DpQ9iAZF6-vImus_k_WhclQb46HW3j0xTBaHW_NcFzz_GCB59aLF8oVtFFnHHMg7zm1r3Mzm8LLRlOKQWL924GK4q0V2q7Ks0tBFkPxy3st6PvYQqPE1iw2htF7RN0Ovb_6kPIZXHSrqdQ18jCF95hEFbYobj61U9ctGPjsigWdU8oiFu71icD-FLYmzZT_bx8'},
    {'name': 'Chloe', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDsT0PPkoye8Y2_iqJxZFckG600cq6q4Aeq2o_ikCrCrEuei1XdeNjbRDfBrFNFX7nPKYbg2VnlfmJgVr7qHi41-pCuc7BRzWf9R-lelePkJpX5Gd7_yaLHT7q0N9Qo8c9D-ajGwaTRvukD0pyB6p21oBrTyPT1tmqP7nn4QBM2d3XW2Mop76XQUYcGrwDU1nddeC6PEovpDnsqKsRUu0Ysb7Uxh13mTlUktWqEzOfpC0LEIflhwlipD_NUgVsrs5gMBLRRXqvqmMo'},
  ];

  void _openChat(BuildContext context, _Conversation c) {
    if (_selectedTab == 0) {
      context.push(
        Uri(
          path: AppConstants.familyPrivateChatRoute,
          queryParameters: {
            'id': c.id,
            'name': c.name,
            if (c.imageUrl.isNotEmpty) 'imageUrl': c.imageUrl,
          },
        ).toString(),
      );
    } else {
      final membersMatch = RegExp(r'(\d+)').firstMatch(c.subtitle ?? '');
      final members = membersMatch != null ? membersMatch.group(1)! : '2';
      context.push(
        Uri(
          path: AppConstants.familyGroupChatRoute,
          queryParameters: {
            'name': c.name,
            'members': members,
            'id': c.id,
          },
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildOnlineNow(),
            _buildTabs(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Conversations',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Material(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.edit_note, color: _textMuted, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.transparent),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
          decoration: InputDecoration(
            hintText: 'Search family & friends',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineNow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'ONLINE NOW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: Builder(
            builder: (context) {
              final onlineFiltered = _searchQuery.isEmpty
                  ? _onlineNow
                  : _onlineNow
                      .where((u) => (u['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: onlineFiltered.length,
                itemBuilder: (context, index) {
                  final u = onlineFiltered[index];
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.network(
                            u['url']!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: _primary.withOpacity(0.3),
                              child: const Icon(Icons.person, size: 32),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      u['name']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _tab('Persons', 0),
          _tab('Families', 1),
          _tab('Benevole', 2),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.only(top: 16, bottom: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: active ? _primary : _textMuted,
              letterSpacing: 0.015,
            ),
          ),
        ),
      ),
    );
  }

  List<_Conversation> _filterBySearch(List<_Conversation> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Widget _buildContent() {
    final rawList = _selectedTab == 0
        ? _personsConversations
        : _selectedTab == 1
            ? _familiesConversations
            : _benevoleConversations;
    final list = _filterBySearch(rawList);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final c = list[index];
          return _ConversationTile(
            conversation: c,
            onTap: () => _openChat(context, c),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final _Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                conversation.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: _primary.withOpacity(0.3),
                  child: const Icon(Icons.person, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: conversation.unread ? FontWeight.bold : FontWeight.w500,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.w500,
                          color: conversation.unread ? _primary : _textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.normal,
                            color: conversation.unread ? _textPrimary : _textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
