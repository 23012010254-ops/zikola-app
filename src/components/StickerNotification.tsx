import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Star, Trophy, Sparkles } from 'lucide-react';

interface StickerNotificationProps {
  sticker: {
    id: string;
    name: string;
    emoji: string;
    description: string;
    rarity: string;
  } | null;
  onClose: () => void;
}

export default function StickerNotification({ sticker, onClose }: StickerNotificationProps) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    if (sticker) {
      setIsVisible(true);
      const timer = setTimeout(() => {
        setIsVisible(false);
        setTimeout(onClose, 500); // Wait for exit animation
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [sticker, onClose]);

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case 'common': return 'from-gray-400 to-gray-500';
      case 'rare': return 'from-blue-400 to-blue-600';
      case 'epic': return 'from-purple-400 to-purple-600';
      case 'legendary': return 'from-yellow-400 to-orange-500';
      default: return 'from-gray-400 to-gray-500';
    }
  };

  const getRarityBorder = (rarity: string) => {
    switch (rarity) {
      case 'common': return 'border-gray-300';
      case 'rare': return 'border-blue-400';
      case 'epic': return 'border-purple-400';
      case 'legendary': return 'border-yellow-400';
      default: return 'border-gray-300';
    }
  };

  if (!sticker) return null;

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ opacity: 0, scale: 0.5, y: -50 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.5, y: -50 }}
          transition={{ type: "spring", stiffness: 200, damping: 15 }}
          className="fixed top-20 left-1/2 transform -translate-x-1/2 z-50 max-w-sm mx-4"
        >
          <div className={`bg-white rounded-3xl p-6 shadow-2xl border-3 ${getRarityBorder(sticker.rarity)} relative overflow-hidden`}>
            {/* Background Glow Effect */}
            <div className={`absolute inset-0 bg-gradient-to-br ${getRarityColor(sticker.rarity)} opacity-10 rounded-3xl`} />
            
            {/* Sparkle Animation for Legendary */}
            {sticker.rarity === 'legendary' && (
              <>
                {[...Array(6)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="absolute w-1 h-1 bg-yellow-400 rounded-full"
                    style={{
                      left: `${20 + i * 12}%`,
                      top: `${15 + (i % 2) * 40}%`,
                    }}
                    animate={{
                      scale: [0, 1.5, 0],
                      opacity: [0, 1, 0],
                      rotate: [0, 180, 360],
                    }}
                    transition={{
                      duration: 2,
                      repeat: Infinity,
                      delay: i * 0.2,
                    }}
                  />
                ))}
              </>
            )}

            {/* Content */}
            <div className="relative text-center">
              {/* Header with Trophy */}
              <div className="flex items-center justify-center space-x-2 mb-4">
                <motion.div
                  animate={{ rotate: [0, -10, 10, -10, 0] }}
                  transition={{ duration: 0.5, repeat: 2 }}
                >
                  <Trophy className="w-6 h-6 text-yellow-500" />
                </motion.div>
                <h3 className="text-gray-900 font-heading font-bold text-lg">
                  Stiker Baru!
                </h3>
                <motion.div
                  animate={{ rotate: [0, 10, -10, 10, 0] }}
                  transition={{ duration: 0.5, repeat: 2, delay: 0.1 }}
                >
                  <Sparkles className="w-6 h-6 text-purple-500" />
                </motion.div>
              </div>

              {/* Sticker Emoji */}
              <motion.div
                className="text-6xl mb-4"
                animate={{ 
                  scale: [1, 1.2, 1],
                  rotate: [0, 5, -5, 0]
                }}
                transition={{ duration: 0.8, repeat: 2 }}
              >
                {sticker.emoji}
              </motion.div>

              {/* Rarity Badge */}
              <div className={`inline-block px-3 py-1 rounded-full text-xs font-body font-bold text-white bg-gradient-to-r ${getRarityColor(sticker.rarity)} mb-3`}>
                {sticker.rarity.toUpperCase()}
              </div>

              {/* Sticker Info */}
              <h4 className="text-gray-900 font-heading font-bold text-xl mb-2">
                {sticker.name}
              </h4>
              <p className="text-gray-600 font-body text-sm mb-4">
                {sticker.description}
              </p>

              {/* Confetti Animation */}
              <div className="absolute inset-0 pointer-events-none">
                {[...Array(12)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="absolute w-2 h-2 rounded-full"
                    style={{
                      backgroundColor: ['#FFD700', '#FF69B4', '#00CED1', '#32CD32', '#FF6347', '#9370DB'][i % 6],
                      left: `${10 + i * 7}%`,
                      top: `${20 + (i % 4) * 15}%`,
                    }}
                    animate={{
                      y: [0, -60, 40],
                      x: [0, (i - 6) * 15, 0],
                      rotate: [0, 720],
                      scale: [1, 1.5, 0],
                      opacity: [1, 1, 0]
                    }}
                    transition={{
                      duration: 2.5,
                      delay: i * 0.1,
                      ease: "easeOut"
                    }}
                  />
                ))}
              </div>

              {/* Success Message */}
              <div className="bg-green-50 border border-green-200 rounded-xl p-3">
                <div className="flex items-center justify-center space-x-2">
                  <Star className="w-4 h-4 text-green-600 fill-current" />
                  <span className="text-green-700 font-body font-medium text-sm">
                    Ditambahkan ke koleksimu!
                  </span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}