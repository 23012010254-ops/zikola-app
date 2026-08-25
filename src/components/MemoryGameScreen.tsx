import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, RotateCcw, Trophy, Star, CheckCircle } from 'lucide-react';

interface MemoryGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

interface Card {
  id: number;
  emoji: string;
  isFlipped: boolean;
  isMatched: boolean;
}

export default function MemoryGameScreen({ navigateTo, addSticker, updateGameAssessment }: MemoryGameScreenProps) {
  const [cards, setCards] = useState<Card[]>([]);
  const [flippedCards, setFlippedCards] = useState<number[]>([]);
  const [matchedPairs, setMatchedPairs] = useState(0);
  const [moves, setMoves] = useState(0);
  const [gameCompleted, setGameCompleted] = useState(false);
  const [gameStarted, setGameStarted] = useState(false);
  const [gameTime, setGameTime] = useState(0);
  const [isTimerRunning, setIsTimerRunning] = useState(false);

  // Card emojis for the memory game - more variety and fun
  const cardEmojis = ['🐱', '🐶', '🐸', '🦊', '🐰', '🐨', '🐼', '🦁', '🦄', '🐯', '🐵', '🐧', '🦋', '🐝', '🌸', '🌟', '🎈', '🍎'];
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('medium');
  const [streak, setStreak] = useState(0);
  const [bestStreak, setBestStreak] = useState(0);
  const [errors, setErrors] = useState(0);
  const [gameCompletionHandled, setGameCompletionHandled] = useState(false);

  useEffect(() => {
    if (!gameStarted) {
      // Select cards based on difficulty
      const cardCount = difficulty === 'easy' ? 6 : difficulty === 'medium' ? 8 : 10;
      const selectedEmojis = cardEmojis.slice(0, cardCount);
      
      // Create pairs of cards with proper unique IDs
      const pairedEmojis = [...selectedEmojis, ...selectedEmojis];
      const gameCards = pairedEmojis.map((emoji, index) => ({
        id: index,
        emoji,
        isFlipped: false,
        isMatched: false,
      }));
      
      // Shuffle cards using Fisher-Yates algorithm for better randomization
      const shuffledCards = [...gameCards];
      for (let i = shuffledCards.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffledCards[i], shuffledCards[j]] = [shuffledCards[j], shuffledCards[i]];
      }
      
      setCards(shuffledCards);
      setFlippedCards([]);
      setMatchedPairs(0);
      setMoves(0);
      setGameCompleted(false);
      setStreak(0);
      setErrors(0);
      setGameCompletionHandled(false);
    }
  }, [gameStarted, difficulty]);

  const handleCardClick = useCallback((cardId: number) => {
    // Prevent clicking if already 2 cards flipped or card is already matched/flipped
    if (flippedCards.length === 2) return;
    if (flippedCards.includes(cardId)) return;
    
    const clickedCard = cards.find(card => card.id === cardId);
    if (!clickedCard || clickedCard.isMatched) return;

    const newFlippedCards = [...flippedCards, cardId];
    setFlippedCards(newFlippedCards);

    // Flip the card
    setCards(prev => 
      prev.map(card => 
        card.id === cardId ? { ...card, isFlipped: true } : card
      )
    );

    // Check for match when 2 cards are flipped
    if (newFlippedCards.length === 2) {
      setMoves(prev => prev + 1);
      
      const [firstCardId, secondCardId] = newFlippedCards;
      const firstCard = cards.find(card => card.id === firstCardId);
      const secondCard = cards.find(card => card.id === secondCardId);

      if (firstCard && secondCard && firstCard.emoji === secondCard.emoji) {
        // Match found
        setStreak(prev => {
          const newStreak = prev + 1;
          if (newStreak > bestStreak) {
            setBestStreak(newStreak);
          }
          return newStreak;
        });
        
        setTimeout(() => {
          setCards(prev => 
            prev.map(card => 
              card.id === firstCardId || card.id === secondCardId 
                ? { ...card, isMatched: true, isFlipped: true }
                : card
            )
          );
          setMatchedPairs(prev => prev + 1);
          setFlippedCards([]);
        }, 800);
      } else {
        // No match - flip cards back
        setStreak(0); // Reset streak on miss
        setErrors(prev => prev + 1); // Count errors for assessment
        setTimeout(() => {
          setCards(prev => 
            prev.map(card => 
              card.id === firstCardId || card.id === secondCardId 
                ? { ...card, isFlipped: false }
                : card
            )
          );
          setFlippedCards([]);
        }, 1200);
      }
    }
  }, [flippedCards, cards]);

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isTimerRunning && !gameCompleted) {
      interval = setInterval(() => {
        setGameTime(prev => prev + 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning, gameCompleted]);

  useEffect(() => {
    const cardCount = difficulty === 'easy' ? 6 : difficulty === 'medium' ? 8 : 10;
    if (matchedPairs === cardCount && matchedPairs > 0 && !gameCompletionHandled) {
      setIsTimerRunning(false);
      setGameCompleted(true);
      setGameCompletionHandled(true);
      
      // Calculate final score for assessment
      const stars = getStarRating(moves, gameTime);
      const score = calculateScore(stars, gameTime, errors, difficulty);
      
      // Update assessment data
      const sessionData = {
        timeSpent: gameTime,
        errors: errors,
        score: score,
        difficulty: difficulty,
        moves: moves,
        stars: stars,
        timestamp: new Date().toISOString(),
        domains: ['Konsentrasi', 'Memori Jangka Pendek']
      };
      
      updateGameAssessment('memory', sessionData);
      addSticker('memory-master');
    }
  }, [matchedPairs, difficulty, gameCompletionHandled]);

  const resetGame = () => {
    setGameStarted(false);
    setGameCompleted(false);
    setIsTimerRunning(false);
    setGameTime(0);
    setGameCompletionHandled(false);
    setTimeout(() => {
      setGameStarted(true);
      setIsTimerRunning(true);
    }, 100);
  };

  const startGame = () => {
    setGameStarted(true);
    setGameTime(0);
    setIsTimerRunning(true);
  };

  const getStarRating = (moves: number, timeInSeconds: number) => {
    // Updated star rating system based on difficulty
    const thresholds = {
      easy: { moves: 8, time: 30 },
      medium: { moves: 13, time: 60 },
      hard: { moves: 16, time: 50 }
    };
    
    const target = thresholds[difficulty];
    
    // 3 stars
    if (moves <= target.moves && timeInSeconds <= target.time) return 3;
    
    // 2 stars - different thresholds for hard mode
    if (difficulty === 'hard') {
      if (moves <= 18 && timeInSeconds <= 60) return 2;
    } else {
      if (moves <= target.moves + 5 && timeInSeconds <= target.time + 30) return 2;
    }
    
    // 1 star
    return 1;
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const calculateScore = (stars: number, timeInSeconds: number, errors: number, difficulty: string) => {
    const baseScore = stars * 30; // 30, 60, or 90
    
    // Time bonus (faster = better)
    const timeTarget = difficulty === 'easy' ? 60 : difficulty === 'medium' ? 120 : 180;
    const timeBonus = Math.max(0, Math.floor((timeTarget - timeInSeconds) / 10)) * 2;
    
    // Error penalty
    const errorPenalty = errors * 5;
    
    // Difficulty multiplier
    const difficultyMultiplier = difficulty === 'easy' ? 1 : difficulty === 'medium' ? 1.2 : 1.5;
    
    return Math.round(Math.max(10, (baseScore + timeBonus - errorPenalty) * difficultyMultiplier));
  };

  const getPerformanceLevel = (score: number) => {
    if (score >= 90) return { level: 'Luar Biasa', color: 'text-purple-600', bg: 'bg-purple-50' };
    if (score >= 70) return { level: 'Sangat Baik', color: 'text-blue-600', bg: 'bg-blue-50' };
    if (score >= 50) return { level: 'Baik', color: 'text-green-600', bg: 'bg-green-50' };
    if (score >= 30) return { level: 'Cukup', color: 'text-yellow-600', bg: 'bg-yellow-50' };
    return { level: 'Perlu Latihan', color: 'text-orange-600', bg: 'bg-orange-50' };
  };

  if (gameCompleted) {
    const stars = getStarRating(moves, gameTime);
    const score = calculateScore(stars, gameTime, errors, difficulty);
    const performance = getPerformanceLevel(score);
    
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center">
        <motion.div
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: "spring", stiffness: 200, damping: 15 }}
          className="bg-white rounded-3xl p-8 text-center max-w-sm mx-4 shadow-2xl"
        >
          <motion.div
            animate={{ 
              scale: [1, 1.2, 1], 
              rotate: [0, 10, -10, 0],
              y: [0, -10, 0]
            }}
            transition={{ duration: 0.8, repeat: 3 }}
            className="text-8xl mb-4 relative"
          >
            🎉
            {/* Confetti particles */}
            {[...Array(8)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute w-2 h-2 rounded-full"
                style={{
                  backgroundColor: ['#FFD700', '#FF69B4', '#00CED1', '#32CD32', '#FF6347', '#9370DB', '#FFA500', '#DC143C'][i],
                  left: `${10 + i * 10}%`,
                  top: `${20 + (i % 3) * 15}%`,
                }}
                animate={{
                  y: [0, -40, 30],
                  x: [0, (i - 4) * 20, 0],
                  rotate: [0, 720],
                  scale: [1, 1.8, 0],
                  opacity: [1, 1, 0]
                }}
                transition={{
                  duration: 2,
                  delay: i * 0.1,
                  repeat: Infinity,
                  repeatDelay: 1.5
                }}
              />
            ))}
          </motion.div>

          <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
            Hebat Sekali! 🏆
          </h2>
          <p className="text-gray-600 font-body text-base mb-4">
            Kamu berhasil mencocokkan semua kartu!
          </p>

          {/* Stars */}
          <div className="flex justify-center space-x-1 mb-4">
            {[1, 2, 3].map(star => (
              <Star 
                key={star}
                className={`w-8 h-8 ${star <= stars ? 'text-yellow-400 fill-current' : 'text-gray-200'}`}
              />
            ))}
          </div>

          {/* Assessment Results */}
          <div className={`${performance.bg} rounded-2xl p-4 mb-4`}>
            <div className="flex items-center justify-between mb-3">
              <h3 className={`font-heading font-bold ${performance.color}`}>Assessment Result</h3>
              <span className={`font-heading font-bold text-lg ${performance.color}`}>{score}</span>
            </div>
            <div className={`${performance.color} font-body text-sm space-y-1`}>
              <p>Performance: <span className="font-bold">{performance.level}</span></p>
              <p>Domain: <span className="font-bold">Konsentrasi & Memori</span></p>
              <p>Tingkat: <span className="font-bold">{difficulty === 'easy' ? 'Mudah' : difficulty === 'medium' ? 'Sedang' : 'Sulit'}</span></p>
            </div>
          </div>

          {/* Detailed Stats */}
          <div className="bg-purple-50 rounded-2xl p-4 mb-6">
            <div className="text-purple-700 font-body text-sm space-y-2">
              <div className="flex justify-between">
                <span>Gerakan:</span>
                <span className="font-bold">{moves}</span>
              </div>
              <div className="flex justify-between">
                <span>Waktu:</span>
                <span className="font-bold">{formatTime(gameTime)}</span>
              </div>
              <div className="flex justify-between">
                <span>Kesalahan:</span>
                <span className="font-bold">{errors}</span>
              </div>
              <div className="flex justify-between">
                <span>Best Streak:</span>
                <span className="font-bold">{bestStreak}</span>
              </div>
              <div className="border-t border-purple-200 pt-2 mt-2">
                <div className="flex justify-between">
                  <span className="font-semibold">Skor Akhir:</span>
                  <span className="font-bold text-purple-800">{score}/100</span>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-yellow-50 rounded-2xl p-4 mb-6">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <Trophy className="w-5 h-5 text-yellow-600" />
              <span className="text-yellow-700 font-body font-semibold">
                Hadiah Diperoleh!
              </span>
            </div>
            <p className="text-yellow-600 font-body text-sm">
              Stiker "Memory Master" ditambahkan ke koleksimu!
            </p>
          </div>

          <div className="flex space-x-3">
            <motion.button
              onClick={resetGame}
              className="flex-1 bg-purple-500 text-white py-3 px-4 rounded-2xl font-heading font-bold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Main Lagi
            </motion.button>
            <motion.button
              onClick={() => navigateTo('game')}
              className="flex-1 bg-gray-500 text-white py-3 px-4 rounded-2xl font-heading font-bold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Kembali
            </motion.button>
          </div>
        </motion.div>
      </div>
    );
  }

  if (!gameStarted) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-purple-500 to-purple-600 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-6">
            <motion.button
              onClick={() => navigateTo('game')}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </motion.button>
            <h1 className="text-white font-heading font-bold text-xl">Memory Cards</h1>
            <div className="w-10" />
          </div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
          >
            <h2 className="text-white font-heading font-semibold text-lg mb-2">
              Siap untuk Tantangan? 🧠
            </h2>
            <p className="text-purple-100 font-body text-sm">
              Cocokkan kartu yang sama dan asah daya ingatmu!
            </p>
          </motion.div>
        </div>

        {/* Game Instructions */}
        <div className="px-6 -mt-4 pb-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl p-6 shadow-sm mb-6"
          >
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Cara Bermain:</h3>
            <div className="space-y-3">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                  <span className="text-purple-600 font-bold text-sm">1</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Klik kartu untuk membaliknya</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                  <span className="text-purple-600 font-bold text-sm">2</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Cocokkan 2 kartu dengan gambar yang sama</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                  <span className="text-purple-600 font-bold text-sm">3</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Selesaikan dengan gerakan sesedikit mungkin</p>
              </div>
            </div>
          </motion.div>

          {/* Difficulty Selection */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-2xl p-6 shadow-sm mb-6"
          >
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Pilih Tingkat Kesulitan:</h3>
            <div className="grid grid-cols-3 gap-3">
              {[
                { level: 'easy', label: 'Mudah', cards: '6 Kartu', emoji: '😊' },
                { level: 'medium', label: 'Sedang', cards: '8 Kartu', emoji: '😐' },
                { level: 'hard', label: 'Sulit', cards: '10 Kartu', emoji: '😤' }
              ].map((diff) => (
                <motion.button
                  key={diff.level}
                  onClick={() => setDifficulty(diff.level as 'easy' | 'medium' | 'hard')}
                  className={`p-4 rounded-2xl border-2 text-center transition-all ${
                    difficulty === diff.level
                      ? diff.level === 'easy' ? 'border-green-500 bg-green-50' :
                        diff.level === 'medium' ? 'border-yellow-500 bg-yellow-50' :
                        'border-red-500 bg-red-50'
                      : 'border-gray-200 bg-white hover:border-gray-300'
                  }`}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  <div className="text-2xl mb-2">
                    {diff.emoji}
                  </div>
                  <div className={`font-heading font-bold text-sm ${
                    difficulty === diff.level
                      ? diff.level === 'easy' ? 'text-green-700' :
                        diff.level === 'medium' ? 'text-yellow-700' :
                        'text-red-700'
                      : 'text-gray-600'
                  }`}>
                    {diff.label}
                  </div>
                  <div className={`font-body text-xs ${
                    difficulty === diff.level
                      ? diff.level === 'easy' ? 'text-green-600' :
                        diff.level === 'medium' ? 'text-yellow-600' :
                        'text-red-600'
                      : 'text-gray-500'
                  }`}>
                    {diff.cards}
                  </div>
                </motion.button>
              ))}
            </div>
          </motion.div>

          {/* Target Info */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-gradient-to-r from-yellow-50 to-orange-50 border border-yellow-200 rounded-2xl p-6 mb-6"
          >
            <h3 className="text-orange-700 font-heading font-bold text-base mb-2">
              Target Bintang ({difficulty === 'easy' ? 'Mudah' : difficulty === 'medium' ? 'Sedang' : 'Sulit'}):
            </h3>
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-orange-600 font-body text-sm">3 Bintang ⭐⭐⭐</span>
                <span className="text-orange-600 font-body text-sm font-bold">
                  ≤ {difficulty === 'easy' ? '8 gerakan & 30 detik' : difficulty === 'medium' ? '13 gerakan & 1 menit' : '16 gerakan & 50 detik'}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-orange-600 font-body text-sm">2 Bintang ⭐⭐</span>
                <span className="text-orange-600 font-body text-sm font-bold">
                  ≤ {difficulty === 'easy' ? '13 gerakan & 1 menit' : difficulty === 'medium' ? '18 gerakan & 1.5 menit' : '18 gerakan & 1 menit'}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-orange-600 font-body text-sm">1 Bintang ⭐</span>
                <span className="text-orange-600 font-body text-sm font-bold">Selesaikan game</span>
              </div>
            </div>
          </motion.div>

          <motion.button
            onClick={startGame}
            className="w-full bg-gradient-to-r from-purple-500 to-purple-600 text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            Mulai Permainan! 🎮
          </motion.button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-500 to-purple-600 px-6 pt-14 pb-6">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-lg">Memory Cards</h1>
          <motion.button
            onClick={resetGame}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <RotateCcw className="w-6 h-6 text-white" />
          </motion.button>
        </div>

        {/* Game Stats */}
        <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4">
          <div className="flex items-center justify-between">
            <div className="text-center">
              <span className="text-white font-heading font-bold text-lg">{moves}</span>
              <p className="text-purple-100 font-body text-xs">Gerakan</p>
            </div>
            <div className="text-center">
              <span className="text-white font-heading font-bold text-lg">{formatTime(gameTime)}</span>
              <p className="text-purple-100 font-body text-xs">Waktu</p>
            </div>
            <div className="text-center">
              <span className="text-white font-heading font-bold text-lg">{matchedPairs}/{difficulty === 'easy' ? 6 : difficulty === 'medium' ? 8 : 10}</span>
              <p className="text-purple-100 font-body text-xs">Pasangan</p>
            </div>
            <div className="text-center">
              <div className="flex space-x-1">
                {[1, 2, 3].map(star => (
                  <Star 
                    key={star}
                    className={`w-4 h-4 ${star <= getStarRating(moves, gameTime) ? 'text-yellow-300 fill-current' : 'text-white/30'}`}
                  />
                ))}
              </div>
              <p className="text-purple-100 font-body text-xs">Target</p>
            </div>
          </div>
        </div>
      </div>

      {/* Game Board */}
      <div className="px-4 py-6">
        <div className={`grid gap-2 max-w-xs mx-auto ${
          difficulty === 'easy' ? 'grid-cols-3' : 
          difficulty === 'medium' ? 'grid-cols-4' : 
          'grid-cols-5'
        }`}>
          {cards.map((card) => (
            <motion.button
              key={card.id}
              onClick={() => handleCardClick(card.id)}
              className={`aspect-square rounded-2xl border-2 transition-all relative overflow-hidden shadow-md ${
                card.isMatched
                  ? 'bg-gradient-to-br from-emerald-200 to-emerald-300 border-emerald-500'
                  : card.isFlipped
                    ? 'bg-gradient-to-br from-white to-gray-50 border-purple-400 shadow-lg'
                    : 'bg-gradient-to-br from-indigo-300 via-purple-300 to-pink-300 border-purple-400 hover:from-indigo-400 hover:via-purple-400 hover:to-pink-400'
              }`}
              whileHover={{ 
                scale: card.isMatched ? 1.02 : 1.08,
                rotate: card.isMatched ? 0 : 2
              }}
              whileTap={{ 
                scale: card.isMatched ? 1 : 0.92,
                rotate: card.isMatched ? 0 : -2
              }}
              disabled={card.isMatched || flippedCards.includes(card.id) || flippedCards.length === 2}
              initial={{ opacity: 0, scale: 0.3, rotate: 180 }}
              animate={{ opacity: 1, scale: 1, rotate: 0 }}
              transition={{ 
                delay: card.id * 0.08,
                type: "spring",
                stiffness: 260,
                damping: 20
              }}
            >
              <div className="w-full h-full flex items-center justify-center relative">
                {card.isFlipped || card.isMatched ? (
                  <motion.span 
                    className={`text-xl sm:text-2xl ${card.isMatched ? 'drop-shadow-md' : ''}`}
                    initial={{ rotateY: -90, scale: 0.5 }}
                    animate={{ rotateY: 0, scale: 1 }}
                    transition={{ 
                      duration: 0.4,
                      type: "spring",
                      stiffness: 200
                    }}
                  >
                    {card.emoji}
                  </motion.span>
                ) : (
                  <motion.div
                    className="text-white text-xl"
                    whileHover={{ scale: 1.2, rotate: 10 }}
                    animate={{ 
                      scale: [1, 1.05, 1],
                      rotate: [0, 5, -5, 0]
                    }}
                    transition={{
                      duration: 2,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  >
                    ❓
                  </motion.div>
                )}
                
                {/* Sparkle effect for matched cards */}
                {card.isMatched && (
                  <>
                    <motion.div
                      className="absolute top-1 right-1"
                      initial={{ scale: 0, rotate: -180 }}
                      animate={{ scale: 1, rotate: 0 }}
                      transition={{ delay: 0.3, duration: 0.5 }}
                    >
                      <CheckCircle className="w-4 h-4 text-emerald-600" />
                    </motion.div>
                    
                    {/* Particle effect */}
                    <motion.div
                      className="absolute inset-0 pointer-events-none"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: [0, 1, 0] }}
                      transition={{ duration: 0.8, delay: 0.2 }}
                    >
                      {[...Array(3)].map((_, i) => (
                        <motion.div
                          key={i}
                          className="absolute w-1 h-1 bg-yellow-400 rounded-full"
                          style={{
                            left: `${30 + i * 20}%`,
                            top: `${20 + i * 30}%`,
                          }}
                          animate={{
                            y: [-10, -20, -10],
                            x: [0, 5, -5, 0],
                            scale: [0, 1, 0],
                          }}
                          transition={{
                            duration: 0.6,
                            delay: 0.3 + i * 0.1,
                            repeat: 1
                          }}
                        />
                      ))}
                    </motion.div>
                  </>
                )}
              </div>
            </motion.button>
          ))}
        </div>
        
        {/* Progress indicator */}
        <div className="mt-6 max-w-xs mx-auto">
          <div className="flex justify-between text-sm text-purple-600 mb-2">
            <span>Progress</span>
            <span>{matchedPairs}/{difficulty === 'easy' ? 6 : difficulty === 'medium' ? 8 : 10}</span>
          </div>
          <div className="w-full h-3 bg-purple-100 rounded-full overflow-hidden">
            <motion.div
              className="h-3 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"
              initial={{ width: 0 }}
              animate={{ 
                width: `${(matchedPairs / (difficulty === 'easy' ? 6 : difficulty === 'medium' ? 8 : 10)) * 100}%` 
              }}
              transition={{ duration: 0.5, ease: "easeOut" }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}