/// One sticker in the sticker book. First 4 are "Animal Friends", rest are "Coming Soon".
class StickerDefinition {
  const StickerDefinition({
    required this.id,
    required this.nameKey,
    this.skillKey,
    this.imageUrl,
  });

  final String id;
  final String nameKey;
  final String? skillKey;
  final String? imageUrl;

  bool get isComingSoon => imageUrl == null;
}

/// Predefined stickers: 4 animal friends + 8 coming soon slots.
const List<StickerDefinition> kStickerDefinitions = [
  StickerDefinition(
    id: 'leo_lion',
    nameKey: 'stickerLeoTheLion',
    skillKey: 'stickerSortingChamp',
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB_ITRTUKA2tfUb21pkun57Il48EiaFq90kh5CYagkohUaET51Opm7jaD0hnyY5k7Mc0rSC_ak8r7zQYTmKkAaYransyc-5JZgfAYzmhehHVmQnOyOu5hqkXJaovzWmMlCDHgOtpBd8R1ZdPiPjwMJ_4BosCdpsREkolj9aPnhLuNQsqsOtJA34yBRdQCrYrk9Fg3c_EuTq2DFzjW-G9Ju_zncAsautHyfUVZwW6DQW6Z9K_2uueUHzpN9r94tt2fVl1MyWMqPej_Y',
  ),
  StickerDefinition(
    id: 'happy_hippo',
    nameKey: 'stickerHappyHippo',
    skillKey: 'stickerMemoryMaster',
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDoJ4jKvs16lJnsifZmhc4CARAv-fVizSecMcEfb_PyPo6xNEF0gkvp_4khBp7LNbwDSCwqjJNsGvbMLeUHtv8ZXkgqauhoemCobqNn7WNcEw3T_BJeUpJ1gM5F_3tujZasFhUkmKvCYKZPyfYewpBlpiMmWX4gb_BgJ_O19L4XJjyPa-bMGHlDqI2yfN15loY6OY1R292THjnVDouW9adgLuG4zfWWWdpYOBB0Qo4VdMegEQ-n5QyC5A14-vcg18lHB2-8Hq67Bhw',
  ),
  StickerDefinition(
    id: 'brave_bear',
    nameKey: 'stickerBraveBear',
    skillKey: 'stickerPatternPro',
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4U3czQ7wwhUXDeV2L1OlynT44cZGpnWrYO2CRzpVQvgIaa5MbJ-nQgKq2A5bBU-PGNh-HvknwvyVow3cUnMj4F4IHCutpwYTlSsvhVDpDY452JS9HoJMPFbT8iocQUjjYLIorqDn5xgiGSPMMykAckW5-Lg-yzMgxAWyCnPM_ofRlCk93am0Iq4LWcSHVj0BrCkKFa9kHj7_GB-R96ulCn7WNWa16ZqG-_roHa5QbPiyipB3rHkPaqhLgcwJRoTNgVPnlhNCW46g',
  ),
  StickerDefinition(
    id: 'smarty_paws',
    nameKey: 'stickerSmartyPaws',
    skillKey: 'stickerFocusStar',
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDek7H4Rox_sAFCCyLISsBv0qXi71hBiqkMl3HuMPXva99bM_KD74mnfCb30EtPLzBCu4-JMk9Kg6upq3zyUeUVQ7B6v0mciUyY5sJYchbAfM4JZMpeRsBgAqF3Dsrv4L4cxz5RwextPLcT9Q7DmMXTDiMFocUGer2bf4R8efF4gZa74a5sGqY3jDqp1VSp_Ry4IoU_NeAo08BjuEgBpBEZWbVDFEojzPB4v6rJqXsaEPbYkVlmZtj9sl_TqwQorHBBj787boxKjf0',
  ),
  StickerDefinition(id: 'coming_5', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_6', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_7', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_8', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_9', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_10', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_11', nameKey: 'stickerComingSoon'),
  StickerDefinition(id: 'coming_12', nameKey: 'stickerComingSoon'),
];

const int kTotalStickers = 12;
const int kNextRewardTarget = 16; // "12/16" style progress for next reward
