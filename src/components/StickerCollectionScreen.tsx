import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Star, Award, Sparkles, Gift } from 'lucide-react';

interface StickerCollectionScreenProps {
  navigateTo: (screen: string) => void;
  collectedStickers: string[];
}

export default function StickerCollectionScreen({ navigateTo, collectedStickers }: StickerCollectionScreenProps) {
  const [selectedCategory, setSelectedCategory] = useState('all');

  // Complete sticker collection with detailed info
  const stickerCategories = [
    {
      id: 'achievement',
      title: 'Achievement Stickers',
      description: 'Reward setelah menyelesaikan tes',
      color: 'bg-yellow-100',
      borderColor: 'border-yellow-300',
      stickers: [
        { 
          id: 'cognitive-test-complete', 
          name: 'Brain Explorer', 
          emoji: '🧠', 
          description: 'Selesaikan tes kognitif', 
          rarity: 'common',
          earned: collectedStickers.includes('cognitive-test-complete'),
          earnedDate: '2024-01-12'
        },
        { 
          id: 'logic-master', 
          name: 'Logic Master', 
          emoji: '💡', 
          description: 'Master tes logika', 
          rarity: 'epic',
          earned: collectedStickers.includes('logic-master') 
        },
        { 
          id: 'attention-expert', 
          name: 'Attention Expert', 
          emoji: '👁️', 
          description: 'Expert dalam tes perhatian', 
          rarity: 'rare',
          earned: collectedStickers.includes('attention-expert') 
        },
        { 
          id: 'memory-champion', 
          name: 'Memory Champion', 
          emoji: '🧩', 
          description: 'Juara tes memori', 
          rarity: 'epic',
          earned: collectedStickers.includes('memory-champion')
        },
        { 
          id: 'linguistic-test-complete', 
          name: 'Language Star', 
          emoji: '🗣️', 
          description: 'Selesaikan tes bahasa', 
          rarity: 'common',
          earned: collectedStickers.includes('linguistic-test-complete') 
        },
        { 
          id: 'receptive-master', 
          name: 'Receptive Master', 
          emoji: '👂', 
          description: 'Master bahasa reseptif', 
          rarity: 'rare',
          earned: collectedStickers.includes('receptive-master') 
        },
        { 
          id: 'expressive-star', 
          name: 'Expressive Star', 
          emoji: '💬', 
          description: 'Bintang bahasa ekspresif', 
          rarity: 'rare',
          earned: collectedStickers.includes('expressive-star') 
        },
        { 
          id: 'phonemic-expert', 
          name: 'Phonemic Expert', 
          emoji: '🔤', 
          description: 'Expert dalam fonemik', 
          rarity: 'epic',
          earned: collectedStickers.includes('phonemic-expert') 
        },
        { 
          id: 'animal-mbti-complete', 
          name: 'Personality Explorer', 
          emoji: '🦁', 
          description: 'Temukan kepribadian hewan', 
          rarity: 'legendary',
          earned: collectedStickers.includes('animal-mbti-complete') 
        }
      ]
    },
    {
      id: 'game',
      title: 'Game Stickers',
      description: 'Pencapaian dari berbagai game',
      color: 'bg-green-100',
      borderColor: 'border-green-300',
      stickers: [
        { 
          id: 'memory-master', 
          name: 'Memory Master', 
          emoji: '🧠', 
          description: 'Selesaikan memory game!', 
          rarity: 'rare',
          earned: collectedStickers.includes('memory-master')
        },
        { 
          id: 'word-master', 
          name: 'Word Master', 
          emoji: '📝', 
          description: 'Ahli dalam word puzzle!', 
          rarity: 'rare',
          earned: collectedStickers.includes('word-master') 
        },
        { 
          id: 'puzzle-master', 
          name: 'Puzzle Master', 
          emoji: '🧩', 
          description: 'Master puzzle game!', 
          rarity: 'epic',
          earned: collectedStickers.includes('puzzle-master') 
        },
        { 
          id: 'artist-star', 
          name: 'Artist Star', 
          emoji: '🎨', 
          description: 'Selesaikan coloring game!', 
          rarity: 'common',
          earned: collectedStickers.includes('artist-star') 
        },
        { 
          id: 'motor-master', 
          name: 'Motor Master', 
          emoji: '🏃', 
          description: 'Master tes motorik!', 
          rarity: 'legendary',
          earned: collectedStickers.includes('motor-master') 
        },
        { 
          id: 'motor-star', 
          name: 'Motor Star', 
          emoji: '⭐', 
          description: 'Bintang tes motorik!', 
          rarity: 'rare',
          earned: collectedStickers.includes('motor-star') 
        },
        { 
          id: 'motor-participant', 
          name: 'Motor Participant', 
          emoji: '🏃‍♂️', 
          description: 'Ikut serta tes motorik!', 
          rarity: 'common',
          earned: collectedStickers.includes('motor-participant') 
        },
        { 
          id: 'tips-explorer', 
          name: 'Tips Explorer', 
          emoji: '💡', 
          description: 'Belajar dari tips motorik!', 
          rarity: 'common',
          earned: collectedStickers.includes('tips-explorer') 
        }
      ]
    },
    {
      id: 'character',
      title: 'Fun Character Stickers',
      description: 'Koleksi karakter lucu',
      color: 'bg-purple-100',
      borderColor: 'border-purple-300',
      stickers: [
        { 
          id: 'panda-buddy', 
          name: 'Panda Buddy', 
          emoji: '🐼', 
          description: 'Teman panda imut', 
          rarity: 'common',
          earned: collectedStickers.includes('panda-buddy'),
          earnedDate: '2024-01-10'
        },
        { 
          id: 'unicorn-magic', 
          name: 'Unicorn Magic', 
          emoji: '🦄', 
          description: 'Keajaiban unicorn', 
          rarity: 'legendary',
          earned: collectedStickers.includes('unicorn-magic') 
        },
        { 
          id: 'cool-penguin', 
          name: 'Cool Penguin', 
          emoji: '🐧', 
          description: 'Penguin keren', 
          rarity: 'rare',
          earned: collectedStickers.includes('cool-penguin') 
        },
        { 
          id: 'tiger-champ', 
          name: 'Tiger Champ', 
          emoji: '🐯', 
          description: 'Juara harimau', 
          rarity: 'epic',
          earned: collectedStickers.includes('tiger-champ') 
        },
        { 
          id: 'happy-frog', 
          name: 'Happy Frog', 
          emoji: '🐸', 
          description: 'Katak bahagia', 
          rarity: 'common',
          earned: collectedStickers.includes('happy-frog') 
        }
      ]
    },
    {
      id: 'progress',
      title: 'Progress Stickers',
      description: 'Milestone pencapaian khusus',
      color: 'bg-blue-100',
      borderColor: 'border-blue-300',
      stickers: [
        { 
          id: 'level-up', 
          name: 'Level Up!', 
          emoji: '🎯', 
          description: 'Naik level!', 
          rarity: 'rare',
          earned: collectedStickers.includes('level-up'),
          earnedDate: '2024-01-16'
        },
        { 
          id: 'first-test', 
          name: 'First Test Completed', 
          emoji: '🥇', 
          description: 'Tes pertama selesai', 
          rarity: 'common',
          earned: collectedStickers.includes('first-test') 
        },
        { 
          id: 'five-days-streak', 
          name: '5 Days Streak', 
          emoji: '🌟', 
          description: 'Belajar 5 hari berturut', 
          rarity: 'epic',
          earned: collectedStickers.includes('five-days-streak') 
        },
        { 
          id: 'hot-streak', 
          name: 'Hot Streak!', 
          emoji: '🔥', 
          description: 'Sedang on fire!', 
          rarity: 'legendary',
          earned: collectedStickers.includes('hot-streak') 
        },
        { 
          id: 'all-tests-done', 
          name: 'All Tests Done!', 
          emoji: '🎉', 
          description: 'Semua tes selesai!', 
          rarity: 'legendary',
          earned: collectedStickers.includes('all-tests-done') 
        }
      ]
    }
  ];

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case 'common': return 'border-gray-300 bg-gray-50';
      case 'rare': return 'border-blue-400 bg-blue-50';
      case 'epic': return 'border-purple-400 bg-purple-50';
      case 'legendary': return 'border-yellow-400 bg-gradient-to-br from-yellow-100 to-orange-100';
      default: return 'border-gray-300 bg-gray-50';
    }
  };

  const getRarityBadgeColor = (rarity: string) => {
    switch (rarity) {
      case 'common': return 'bg-gray-500 text-white';
      case 'rare': return 'bg-blue-500 text-white';
      case 'epic': return 'bg-purple-500 text-white';
      case 'legendary': return 'bg-gradient-to-r from-yellow-500 to-orange-500 text-white';
      default: return 'bg-gray-500 text-white';
    }
  };

  const allStickers = stickerCategories.flatMap(category => 
    category.stickers.map(sticker => ({ ...sticker, category: category.id }))
  );

  const filteredStickers = selectedCategory === 'all' 
    ? allStickers 
    : allStickers.filter(sticker => sticker.category === selectedCategory);

  const totalStickers = allStickers.length;
  const earnedStickers = allStickers.filter(sticker => sticker.earned).length;
  const completionPercentage = Math.round((earnedStickers / totalStickers) * 100);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-pink-400 via-purple-500 to-indigo-500 px-6 pt-14 pb-8">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo('profile')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-xl">Koleksi Stiker</h1>
          <div className="w-10" />
        </div>

        {/* Collection Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/15 backdrop-blur-sm rounded-3xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-white font-heading font-bold text-2xl">
                {earnedStickers}/{totalStickers}
              </h2>
              <p className="text-pink-100 font-body">Stiker Terkumpul</p>
            </div>
            <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center">
              <Award className="w-8 h-8 text-white" />
            </div>
          </div>
          
          {/* Progress Bar */}
          <div className="w-full h-3 bg-white/20 rounded-full overflow-hidden mb-2">
            <motion.div
              className="h-3 bg-white rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${completionPercentage}%` }}
              transition={{ duration: 1, delay: 0.5 }}
            />
          </div>
          <div className="flex justify-between text-pink-100 text-sm font-body">
            <span>Progress Koleksi</span>
            <span>{completionPercentage}% Lengkap</span>
          </div>
        </motion.div>
      </div>

      <div className="px-6 -mt-4 pb-24">
        {/* Category Filter */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-4 shadow-sm mb-6"
        >
          <div className="flex space-x-2 overflow-x-auto pb-2">
            <motion.button
              onClick={() => setSelectedCategory('all')}
              className={`flex-shrink-0 px-4 py-2 rounded-xl text-sm font-body font-medium transition-all ${
                selectedCategory === 'all'
                  ? 'bg-purple-500 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
              whileTap={{ scale: 0.95 }}
            >
              <div className="flex items-center space-x-2">
                <Sparkles className="w-4 h-4" />
                <span>Semua</span>
              </div>
            </motion.button>
            {stickerCategories.map((category) => (
              <motion.button
                key={category.id}
                onClick={() => setSelectedCategory(category.id)}
                className={`flex-shrink-0 px-4 py-2 rounded-xl text-sm font-body font-medium transition-all ${
                  selectedCategory === category.id
                    ? 'bg-purple-500 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
                whileTap={{ scale: 0.95 }}
              >
                {category.title.split(' ')[0]}
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* Stickers Grid */}
        <div className="grid grid-cols-2 gap-4">
          {filteredStickers.map((sticker, index) => (
            <motion.div
              key={sticker.id}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: index * 0.05 }}
              className={`relative rounded-3xl p-6 border-3 transition-all ${
                sticker.earned 
                  ? `${getRarityColor(sticker.rarity)} shadow-lg`
                  : 'border-gray-200 bg-gray-50 opacity-60'
              }`}
            >
              {/* Rarity Badge */}
              <div className={`absolute top-2 right-2 px-2 py-1 rounded-full text-xs font-body font-bold ${getRarityBadgeColor(sticker.rarity)}`}>
                {sticker.rarity.toUpperCase()}
              </div>

              {/* Earned Badge */}
              {sticker.earned && (
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.5 + index * 0.05 }}
                  className="absolute top-2 left-2 w-8 h-8 bg-green-500 rounded-full flex items-center justify-center"
                >
                  <Star className="w-5 h-5 text-white fill-current" />
                </motion.div>
              )}

              {/* Sticker Content */}
              <div className="text-center">
                <div className={`text-6xl mb-4 ${sticker.earned ? '' : 'grayscale opacity-50'}`}>
                  {sticker.earned ? sticker.emoji : '❓'}
                </div>
                
                <h3 className={`font-heading font-bold text-base mb-2 ${
                  sticker.earned ? 'text-gray-900' : 'text-gray-400'
                }`}>
                  {sticker.earned ? sticker.name : 'Locked'}
                </h3>
                
                <p className={`font-body text-sm leading-tight ${
                  sticker.earned ? 'text-gray-600' : 'text-gray-400'
                }`}>
                  {sticker.earned ? sticker.description : 'Complete challenges to unlock'}
                </p>

                {/* Earned Date */}
                {sticker.earned && sticker.earnedDate && (
                  <div className="mt-3 bg-white/80 rounded-lg py-1 px-2">
                    <span className="text-xs font-body text-gray-500">
                      Diperoleh: {new Date(sticker.earnedDate).toLocaleDateString('id-ID')}
                    </span>
                  </div>
                )}
              </div>

              {/* Special Effects for Legendary */}
              {sticker.earned && sticker.rarity === 'legendary' && (
                <motion.div
                  className="absolute inset-0 rounded-3xl"
                  animate={{
                    boxShadow: [
                      '0 0 20px rgba(255, 215, 0, 0.3)',
                      '0 0 40px rgba(255, 215, 0, 0.5)',
                      '0 0 20px rgba(255, 215, 0, 0.3)'
                    ]
                  }}
                  transition={{ duration: 2, repeat: Infinity }}
                />
              )}
            </motion.div>
          ))}
        </div>

        {/* Empty State */}
        {filteredStickers.filter(s => s.earned).length === 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center py-12"
          >
            <div className="text-6xl mb-4">🎯</div>
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-2">
              Belum Ada Stiker Terkumpul
            </h3>
            <p className="text-gray-600 font-body text-sm mb-6">
              Mulai mengerjakan tes dan game untuk mengumpulkan stiker keren!
            </p>
            <motion.button
              onClick={() => navigateTo('home')}
              className="bg-purple-500 text-white px-6 py-3 rounded-2xl font-body font-semibold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Mulai Kumpulkan
            </motion.button>
          </motion.div>
        )}

        {/* Collection Milestone */}
        {completionPercentage >= 25 && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 1 }}
            className="bg-gradient-to-r from-yellow-400 to-orange-500 rounded-2xl p-6 mt-8 text-white text-center"
          >
            <div className="text-4xl mb-3">🎉</div>
            <h3 className="font-heading font-bold text-lg mb-2">
              Hebat! Kamu Collector Sejati!
            </h3>
            <p className="font-body text-yellow-100 text-sm">
              {completionPercentage >= 75 ? 'Master Collector!' : 
               completionPercentage >= 50 ? 'Great Collector!' : 
               'Good Collector!'}
            </p>
          </motion.div>
        )}
      </div>
    </div>
  );
}