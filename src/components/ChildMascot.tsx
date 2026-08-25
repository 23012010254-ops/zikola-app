import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';

interface ChildMascotProps {
  mood?: 'happy' | 'excited' | 'thinking' | 'celebrating' | 'encouraging' | 'sleepy' | 'curious';
  size?: 'small' | 'medium' | 'large';
  message?: string;
  showMessage?: boolean;
  className?: string;
  onClick?: () => void;
  animate?: boolean;
}

export default function ChildMascot({ 
  mood = 'happy', 
  size = 'medium',
  message,
  showMessage = false,
  className = '',
  onClick,
  animate = true
}: ChildMascotProps) {
  const [currentMood, setCurrentMood] = useState(mood);
  const [isBlinking, setIsBlinking] = useState(false);

  // Auto-blink animation
  useEffect(() => {
    const blinkInterval = setInterval(() => {
      setIsBlinking(true);
      setTimeout(() => setIsBlinking(false), 150);
    }, 3000 + Math.random() * 2000);

    return () => clearInterval(blinkInterval);
  }, []);

  const sizeClasses = {
    small: 'w-16 h-16',
    medium: 'w-24 h-24',
    large: 'w-32 h-32'
  };

  const getMascotFace = () => {
    const baseStyle = `${sizeClasses[size]} relative`;
    
    switch (currentMood) {
      case 'happy':
        return {
          face: '😊',
          color: 'from-yellow-300 to-orange-300',
          bounce: true
        };
      case 'excited':
        return {
          face: '🤩',
          color: 'from-pink-300 to-purple-300',
          bounce: true
        };
      case 'thinking':
        return {
          face: '🤔',
          color: 'from-blue-300 to-indigo-300',
          bounce: false
        };
      case 'celebrating':
        return {
          face: '🎉',
          color: 'from-green-300 to-emerald-300',
          bounce: true
        };
      case 'encouraging':
        return {
          face: '💪',
          color: 'from-orange-300 to-red-300',
          bounce: true
        };
      case 'sleepy':
        return {
          face: '😴',
          color: 'from-indigo-300 to-purple-300',
          bounce: false
        };
      case 'curious':
        return {
          face: '🧐',
          color: 'from-teal-300 to-cyan-300',
          bounce: false
        };
      default:
        return {
          face: '😊',
          color: 'from-yellow-300 to-orange-300',
          bounce: true
        };
    }
  };

  const mascotData = getMascotFace();

  const encouragingMessages = {
    happy: ["Hai! Aku Ana, teman belajarmu!", "Semangat belajar hari ini!", "Kamu hebat!"],
    excited: ["Wah, keren sekali!", "Ayo kita belajar!", "Ini pasti seru!"],
    thinking: ["Hmm, ayo kita pikirkan...", "Tidak apa-apa, pelan-pelan saja", "Kamu bisa!"],
    celebrating: ["Selamat! Kamu berhasil!", "Hebat sekali!", "Kamu juara!"],
    encouraging: ["Semangat! Jangan menyerah!", "Kamu kuat!", "Ayo coba lagi!"],
    sleepy: ["Sudah waktunya istirahat?", "Jangan lupa tidur yang cukup ya", "Besok kita lanjut lagi"],
    curious: ["Penasaran? Ayo kita cari tahu!", "Ada yang menarik nih!", "Wah, apa ya ini?"]
  };

  const getRandomMessage = () => {
    const messages = encouragingMessages[currentMood];
    return messages[Math.floor(Math.random() * messages.length)];
  };

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else {
      // Random mood change on click
      const moods = ['happy', 'excited', 'thinking', 'celebrating', 'encouraging', 'curious'];
      const newMood = moods[Math.floor(Math.random() * moods.length)] as typeof mood;
      setCurrentMood(newMood);
    }
  };

  return (
    <div className={`flex flex-col items-center ${className}`}>
      {/* Speech bubble */}
      {showMessage && (
        <motion.div
          initial={{ opacity: 0, y: 10, scale: 0.8 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          className="mb-4 relative max-w-xs"
        >
          <div className="bg-white rounded-2xl p-4 shadow-lg border-2 border-blue-100">
            <p className="text-sm text-gray-700 font-body font-medium text-center">
              {message || getRandomMessage()}
            </p>
          </div>
          <div className="absolute -bottom-2 left-1/2 transform -translate-x-1/2 w-4 h-4 bg-white border-r-2 border-b-2 border-blue-100 rotate-45"></div>
        </motion.div>
      )}

      {/* Mascot */}
      <motion.div
        className="relative cursor-pointer"
        onClick={handleClick}
        whileHover={{ scale: animate ? 1.1 : 1 }}
        whileTap={{ scale: animate ? 0.95 : 1 }}
        animate={animate ? {
          y: mascotData.bounce ? [0, -4, 0] : 0,
        } : {}}
        transition={animate ? {
          duration: mascotData.bounce ? 2 : 0,
          repeat: mascotData.bounce ? Infinity : 0,
          ease: "easeInOut"
        } : {}}
      >
        {/* Glow effect */}
        <div className={`absolute inset-0 rounded-full bg-gradient-to-r ${mascotData.color} blur-lg opacity-30 ${animate ? 'animate-pulse-soft' : ''}`} />
        
        {/* Main mascot body */}
        <div className={`relative ${sizeClasses[size]} rounded-full bg-gradient-to-br ${mascotData.color} shadow-lg flex items-center justify-center border-4 border-white`}>
          <div className={`text-4xl ${size === 'small' ? 'text-2xl' : size === 'large' ? 'text-5xl' : 'text-4xl'} ${isBlinking ? 'animate-pulse' : ''}`}>
            {isBlinking && currentMood === 'happy' ? '😌' : mascotData.face}
          </div>
        </div>

        {/* Sparkle effects */}
        {(currentMood === 'celebrating' || currentMood === 'excited') && animate && (
          <>
            {[...Array(6)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute text-yellow-400 text-xs"
                style={{
                  left: `${20 + Math.random() * 60}%`,
                  top: `${20 + Math.random() * 60}%`,
                }}
                animate={{
                  scale: [0, 1, 0],
                  rotate: [0, 180, 360],
                  opacity: [0, 1, 0],
                }}
                transition={{
                  duration: 1.5,
                  repeat: Infinity,
                  delay: i * 0.2,
                }}
              >
                ✨
              </motion.div>
            ))}
          </>
        )}

        {/* Hearts for happy mood */}
        {currentMood === 'happy' && animate && (
          <>
            {[...Array(3)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute text-pink-400 text-sm"
                style={{
                  right: `${-10 - i * 8}px`,
                  top: `${10 + i * 8}px`,
                }}
                animate={{
                  y: [-5, 5, -5],
                  opacity: [0.3, 0.8, 0.3],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  delay: i * 0.3,
                }}
              >
                💖
              </motion.div>
            ))}
          </>
        )}
      </motion.div>

      {/* Name tag */}
      {size !== 'small' && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="mt-2 bg-white rounded-full px-3 py-1 shadow-md border-2 border-blue-100"
        >
          <span className="text-xs font-heading font-bold text-blue-600">Ana</span>
        </motion.div>
      )}
    </div>
  );
}