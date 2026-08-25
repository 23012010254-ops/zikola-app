class StickerInfo {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String rarity;

  const StickerInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.rarity = 'common',
  });

  int get pointCost {
    switch (rarity) {
      case 'mythical': return 300;
      case 'legend':
      case 'legendary': return 40;
      case 'epic': return 30;
      case 'rare': return 20;
      default: return 10;
    }
  }
}

class StickerDatabase {
  static const Map<String, StickerInfo> stickers = {
    // Achievement Stickers
    'cognitive-test-complete': StickerInfo(id: 'cognitive-test-complete', name: 'Brain Explorer', emoji: '🧠', description: 'Selesaikan tes kognitif', rarity: 'common'),
    'logic-master': StickerInfo(id: 'logic-master', name: 'Logic Master', emoji: '💡', description: 'Master tes logika', rarity: 'epic'),
    'attention-expert': StickerInfo(id: 'attention-expert', name: 'Attention Expert', emoji: '👁️', description: 'Expert dalam tes perhatian', rarity: 'rare'),
    'memory-champion': StickerInfo(id: 'memory-champion', name: 'Memory Champion', emoji: '🧩', description: 'Juara tes memori', rarity: 'epic'),
    'linguistic-test-complete': StickerInfo(id: 'linguistic-test-complete', name: 'Language Star', emoji: '🗣️', description: 'Selesaikan tes bahasa', rarity: 'common'),
    'receptive-master': StickerInfo(id: 'receptive-master', name: 'Receptive Master', emoji: '👂', description: 'Master bahasa reseptif', rarity: 'rare'),
    'expressive-star': StickerInfo(id: 'expressive-star', name: 'Expressive Star', emoji: '💬', description: 'Bintang bahasa ekspresif', rarity: 'rare'),
    'phonemic-expert': StickerInfo(id: 'phonemic-expert', name: 'Phonemic Expert', emoji: '🔤', description: 'Expert dalam fonemik', rarity: 'epic'),
    'animal-mbti-complete': StickerInfo(id: 'animal-mbti-complete', name: 'Personality Explorer', emoji: '🦁', description: 'Temukan kepribadian hewan', rarity: 'legendary'),

    // Game Stickers
    'memory-master': StickerInfo(id: 'memory-master', name: 'Memory Master', emoji: '🧠', description: 'Selesaikan memory game!', rarity: 'rare'),
    'word-master': StickerInfo(id: 'word-master', name: 'Word Master', emoji: '📝', description: 'Ahli dalam word puzzle!', rarity: 'rare'),
    'number-master': StickerInfo(id: 'number-master', name: 'Number Master', emoji: '🔢', description: 'Master urutan angka!', rarity: 'epic'),
    'number-explorer': StickerInfo(id: 'number-explorer', name: 'Number Explorer', emoji: '🧮', description: 'Penjelajah angka!', rarity: 'common'),
    'pattern-master': StickerInfo(id: 'pattern-master', name: 'Pattern Master', emoji: '🎯', description: 'Ahli mengenali pola!', rarity: 'legendary'),
    'pattern-explorer': StickerInfo(id: 'pattern-explorer', name: 'Pattern Explorer', emoji: '👁️', description: 'Mata tajam!', rarity: 'rare'),
    'puzzle-master': StickerInfo(id: 'puzzle-master', name: 'Puzzle Master', emoji: '🧩', description: 'Master puzzle game!', rarity: 'epic'),
    'artist-star': StickerInfo(id: 'artist-star', name: 'Artist Star', emoji: '🎨', description: 'Selesaikan coloring game!', rarity: 'common'),
    'motor-master': StickerInfo(id: 'motor-master', name: 'Motor Master', emoji: '🏃', description: 'Master tes motorik!', rarity: 'legendary'),
    'motor-star': StickerInfo(id: 'motor-star', name: 'Motor Star', emoji: '⭐', description: 'Bintang tes motorik!', rarity: 'rare'),
    'motor-participant': StickerInfo(id: 'motor-participant', name: 'Motor Participant', emoji: '🏃‍♂️', description: 'Ikut serta tes motorik!', rarity: 'common'),
    'tips-explorer': StickerInfo(id: 'tips-explorer', name: 'Tips Explorer', emoji: '💡', description: 'Belajar dari tips motorik!', rarity: 'common'),

    // Math Shooter Stickers
    'cognitive-shooter': StickerInfo(id: 'cognitive-shooter', name: 'Cognitive Shooter', emoji: '🎯', description: 'Penembak kognitif!', rarity: 'common'),
    'math-sharpshooter': StickerInfo(id: 'math-sharpshooter', name: 'Math Sharpshooter', emoji: '🏹', description: 'Penembak jitu matematika!', rarity: 'legendary'),
    'target-master': StickerInfo(id: 'target-master', name: 'Target Master', emoji: '🎯', description: 'Master menembak target!', rarity: 'epic'),
    'level-champion': StickerInfo(id: 'level-champion', name: 'Level Champion', emoji: '🏆', description: 'Juara level tertinggi!', rarity: 'rare'),

    // Alien Shooter Stickers
    'alien-hunter': StickerInfo(id: 'alien-hunter', name: 'Alien Hunter', emoji: '🛸', description: 'Pemburu alien!', rarity: 'common'),
    'alien-master': StickerInfo(id: 'alien-master', name: 'Alien Master', emoji: '👽', description: 'Master pertahanan alien!', rarity: 'legendary'),
    'space-commander': StickerInfo(id: 'space-commander', name: 'Space Commander', emoji: '🚀', description: 'Komandan ruang angkasa!', rarity: 'epic'),
    'galaxy-champion': StickerInfo(id: 'galaxy-champion', name: 'Galaxy Champion', emoji: '🌌', description: 'Juara galaksi!', rarity: 'rare'),
    'alien-test-complete': StickerInfo(id: 'alien-test-complete', name: 'Earth Defender', emoji: '🌍', description: 'Pembela bumi!', rarity: 'rare'),
    'level-master': StickerInfo(id: 'level-master', name: 'Level Master', emoji: '⭐', description: 'Master level!', rarity: 'epic'),

    // Desert Tank Stickers
    'desert-commander': StickerInfo(id: 'desert-commander', name: 'Desert Commander', emoji: '🚗', description: 'Komandan tank gurun!', rarity: 'common'),
    'logic-genius': StickerInfo(id: 'logic-genius', name: 'Logic Genius', emoji: '💡', description: 'Jenius logika!', rarity: 'epic'),
    'abstract-master': StickerInfo(id: 'abstract-master', name: 'Abstract Master', emoji: '🔮', description: 'Master pemikiran abstrak!', rarity: 'rare'),
    'reasoning-expert': StickerInfo(id: 'reasoning-expert', name: 'Reasoning Expert', emoji: '🎯', description: 'Ahli penalaran!', rarity: 'epic'),
    'tank-destroyer': StickerInfo(id: 'tank-destroyer', name: 'Tank Destroyer', emoji: '💥', description: 'Penghancur tank!', rarity: 'rare'),
    'desert-survivor': StickerInfo(id: 'desert-survivor', name: 'Desert Survivor', emoji: '🏜️', description: 'Penyintas gurun!', rarity: 'common'),

    // Desert Road & Story Stickers  
    'road-master': StickerInfo(id: 'road-master', name: 'Road Master', emoji: '🚗', description: 'Master jalan gurun!', rarity: 'rare'),
    'road-champion': StickerInfo(id: 'road-champion', name: 'Road Champion', emoji: '🏆', description: 'Juara logika jalan!', rarity: 'epic'),
    'story-builder': StickerInfo(id: 'story-builder', name: 'Story Builder', emoji: '📖', description: 'Pembangun cerita!', rarity: 'common'),
    'sentence-master': StickerInfo(id: 'sentence-master', name: 'Sentence Master', emoji: '✍️', description: 'Master kalimat!', rarity: 'epic'),
    'story-teller': StickerInfo(id: 'story-teller', name: 'Story Teller', emoji: '📚', description: 'Pencerita ulung!', rarity: 'rare'),
    'grammar-expert': StickerInfo(id: 'grammar-expert', name: 'Grammar Expert', emoji: '✏️', description: 'Ahli tata bahasa!', rarity: 'legendary'),
    'story-builder-complete': StickerInfo(id: 'story-builder-complete', name: 'Story Complete', emoji: '🎯', description: 'Selesaikan story builder!', rarity: 'rare'),

    // Character Stickers
    'panda-buddy': StickerInfo(id: 'panda-buddy', name: 'Panda Buddy', emoji: '🐼', description: 'Teman panda imut', rarity: 'common'),
    'unicorn-magic': StickerInfo(id: 'unicorn-magic', name: 'Unicorn Magic', emoji: '🦄', description: 'Keajaiban unicorn', rarity: 'legendary'),
    'cool-penguin': StickerInfo(id: 'cool-penguin', name: 'Cool Penguin', emoji: '🐧', description: 'Penguin keren', rarity: 'rare'),
    'tiger-champ': StickerInfo(id: 'tiger-champ', name: 'Tiger Champ', emoji: '🐯', description: 'Juara harimau', rarity: 'epic'),
    'happy-frog': StickerInfo(id: 'happy-frog', name: 'Happy Frog', emoji: '🐸', description: 'Katak bahagia', rarity: 'common'),

    // Progress Stickers
    'level-up': StickerInfo(id: 'level-up', name: 'Level Up!', emoji: '🎯', description: 'Naik level!', rarity: 'rare'),
    'first-test': StickerInfo(id: 'first-test', name: 'First Test Completed', emoji: '🥇', description: 'Tes pertama selesai', rarity: 'common'),
    'five-days-streak': StickerInfo(id: 'five-days-streak', name: '5 Days Streak', emoji: '🌟', description: 'Belajar 5 hari berturut', rarity: 'epic'),
    'hot-streak': StickerInfo(id: 'hot-streak', name: 'Hot Streak!', emoji: '🔥', description: 'Sedang on fire!', rarity: 'legend'),
    'all-tests-done': StickerInfo(id: 'all-tests-done', name: 'All Tests Done!', emoji: '🎉', description: 'Semua tes selesai!', rarity: 'legend'),

    // Mythical Stickers (300 Pts)
    'dragon-emperor': StickerInfo(id: 'dragon-emperor', name: 'Dragon Emperor', emoji: '🐉', description: 'Kekuatan naga legendaris!', rarity: 'mythical'),
    'phoenix-soul': StickerInfo(id: 'phoenix-soul', name: 'Phoenix Soul', emoji: '🐦‍🔥', description: 'Semangat yang tak pernah padam!', rarity: 'mythical'),
    'cosmic-crystal': StickerInfo(id: 'cosmic-crystal', name: 'Cosmic Crystal', emoji: '💎', description: 'Energi dari seluruh galaksi!', rarity: 'mythical'),
    'eternal-crown': StickerInfo(id: 'eternal-crown', name: 'Eternal Crown', emoji: '👑', description: 'Raja dari segala permainan!', rarity: 'mythical'),
    'supernova-star': StickerInfo(id: 'supernova-star', name: 'Supernova Star', emoji: '💥', description: 'Ledakan bintang yang dahsyat!', rarity: 'mythical'),
  };

  static StickerInfo? getSticker(String id) => stickers[id];
}
