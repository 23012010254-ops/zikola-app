import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, RotateCcw, Trophy, Star, Lightbulb, Clock, Eye } from 'lucide-react';

interface PatternRecognitionGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

interface PatternChallenge {
  pattern: PatternElement[][];
  missing: { row: number; col: number };
  choices: PatternElement[];
  correct: PatternElement;
  difficulty: 'easy' | 'medium' | 'hard';
  type: 'shape' | 'color' | 'size' | 'rotation';
}

interface PatternElement {
  shape: 'circle' | 'square' | 'triangle' | 'star' | 'diamond';
  color: string;
  size: 'small' | 'medium' | 'large';
  rotation: number;
}

export default function PatternRecognitionGameScreen({ navigateTo, addSticker, updateGameAssessment }: PatternRecognitionGameScreenProps) {
  const [gameStarted, setGameStarted] = useState(false);
  const [currentLevel, setCurrentLevel] = useState(1);
  const [challenge, setChallenge] = useState<PatternChallenge | null>(null);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [gameCompleted, setGameCompleted] = useState(false);
  const [timeLeft, setTimeLeft] = useState(45);
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [showHint, setShowHint] = useState(false);
  const [hintsUsed, setHintsUsed] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState<PatternElement | null>(null);
  const [answerFeedback, setAnswerFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [errors, setErrors] = useState(0);
  const [gameStartTime, setGameStartTime] = useState<Date | null>(null);
  const [gameCompletionHandled, setGameCompletionHandled] = useState(false);

  const maxLevel = 12;

  const shapes = ['circle', 'square', 'triangle', 'star', 'diamond'] as const;
  const colors = ['#ef4444', '#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899'];
  const sizes = ['small', 'medium', 'large'] as const;

  const generatePattern = useCallback((level: number): PatternChallenge => {
    const difficulty: 'easy' | 'medium' | 'hard' = 
      level <= 4 ? 'easy' : level <= 8 ? 'medium' : 'hard';
    
    const gridSize = difficulty === 'easy' ? 3 : 4;
    const patternTypes = ['shape', 'color', 'size', 'rotation'];
    const type = patternTypes[Math.floor(Math.random() * patternTypes.length)] as 'shape' | 'color' | 'size' | 'rotation';
    
    // Create base pattern
    const pattern: PatternElement[][] = [];
    const baseElement: PatternElement = {
      shape: shapes[Math.floor(Math.random() * shapes.length)],
      color: colors[Math.floor(Math.random() * colors.length)],
      size: sizes[Math.floor(Math.random() * sizes.length)],
      rotation: 0
    };

    // Generate pattern based on type
    for (let row = 0; row < gridSize; row++) {
      pattern[row] = [];
      for (let col = 0; col < gridSize; col++) {
        let element: PatternElement;
        
        switch (type) {
          case 'shape':
            element = {
              ...baseElement,
              shape: shapes[(shapes.indexOf(baseElement.shape) + row + col) % shapes.length],
              color: colors[(row + col) % colors.length]
            };
            break;
          case 'color':
            element = {
              ...baseElement,
              color: colors[(row * gridSize + col) % colors.length]
            };
            break;
          case 'size':
            element = {
              ...baseElement,
              size: sizes[(row + col) % sizes.length]
            };
            break;
          case 'rotation':
            element = {
              ...baseElement,
              rotation: ((row + col) * 45) % 360
            };
            break;
          default:
            element = baseElement;
        }
        
        pattern[row][col] = element;
      }
    }

    // Choose random position to remove (not corners for easier recognition)
    let missingRow, missingCol;
    if (difficulty === 'easy') {
      // Middle positions for easy mode
      missingRow = Math.floor(gridSize / 2);
      missingCol = Math.floor(gridSize / 2);
    } else {
      // Any position except corners for medium/hard
      do {
        missingRow = Math.floor(Math.random() * gridSize);
        missingCol = Math.floor(Math.random() * gridSize);
      } while ((missingRow === 0 || missingRow === gridSize - 1) && 
               (missingCol === 0 || missingCol === gridSize - 1));
    }

    const correct = pattern[missingRow][missingCol];
    
    // Generate wrong choices
    const choices = [correct];
    while (choices.length < 4) {
      const wrongChoice: PatternElement = {
        shape: shapes[Math.floor(Math.random() * shapes.length)],
        color: colors[Math.floor(Math.random() * colors.length)],
        size: sizes[Math.floor(Math.random() * sizes.length)],
        rotation: Math.floor(Math.random() * 8) * 45
      };
      
      // Make sure it's different from correct answer
      if (!choices.some(c => 
        c.shape === wrongChoice.shape && 
        c.color === wrongChoice.color && 
        c.size === wrongChoice.size && 
        c.rotation === wrongChoice.rotation
      )) {
        choices.push(wrongChoice);
      }
    }
    
    // Shuffle choices
    choices.sort(() => Math.random() - 0.5);

    return {
      pattern,
      missing: { row: missingRow, col: missingCol },
      choices,
      correct,
      difficulty,
      type
    };
  }, []);

  // Initialize game
  useEffect(() => {
    if (gameStarted && !gameCompleted) {
      const newChallenge = generatePattern(currentLevel);
      setChallenge(newChallenge);
      setTimeLeft(45);
      setIsTimerRunning(true);
      setShowHint(false);
      setSelectedAnswer(null);
      setAnswerFeedback(null);
    }
  }, [gameStarted, currentLevel, gameCompleted, generatePattern]);

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isTimerRunning && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft(prev => {
          if (prev <= 1) {
            handleWrongAnswer();
            return 45;
          }
          return prev - 1;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning, timeLeft]);

  const handleAnswer = (answer: PatternElement) => {
    if (!challenge || answerFeedback) return;
    
    setSelectedAnswer(answer);
    setIsTimerRunning(false);
    
    const isCorrect = answer.shape === challenge.correct.shape &&
                     answer.color === challenge.correct.color &&
                     answer.size === challenge.correct.size &&
                     answer.rotation === challenge.correct.rotation;
    
    if (isCorrect) {
      setAnswerFeedback('correct');
      setScore(prev => prev + (challenge.difficulty === 'easy' ? 15 : challenge.difficulty === 'medium' ? 20 : 25));
      setCorrectAnswers(prev => prev + 1);
      
      setTimeout(() => {
        if (currentLevel >= maxLevel) {
          completeGame();
        } else {
          setCurrentLevel(prev => prev + 1);
        }
      }, 2000);
    } else {
      handleWrongAnswer();
    }
  };

  const handleWrongAnswer = () => {
    setAnswerFeedback('wrong');
    setErrors(prev => prev + 1);
    setLives(prev => {
      const newLives = prev - 1;
      if (newLives <= 0) {
        setTimeout(() => {
          completeGame();
        }, 2000);
      } else {
        setTimeout(() => {
          setCurrentLevel(prev => prev + 1);
        }, 2000);
      }
      return newLives;
    });
  };

  const completeGame = () => {
    if (gameCompletionHandled) return;
    
    setGameCompletionHandled(true);
    const endTime = new Date();
    const gameTimeSpent = gameStartTime ? Math.floor((endTime.getTime() - gameStartTime.getTime()) / 1000) : 0;
    
    const stars = getStarRating();
    const finalScore = calculateAssessmentScore(stars, gameTimeSpent, errors, correctAnswers, hintsUsed);
    
    const sessionData = {
      timeSpent: gameTimeSpent,
      errors: errors,
      score: finalScore,
      difficulty: getDifficultyForLevel(currentLevel - 1),
      level: currentLevel,
      correctAnswers: correctAnswers,
      hintsUsed: hintsUsed,
      stars: stars,
      timestamp: new Date().toISOString(),
      domains: ['Logika Visual', 'Abstraksi', 'Spatial Intelligence']
    };
    
    updateGameAssessment('patternRecognition', sessionData);
    setGameCompleted(true);
    addSticker(lives > 0 ? 'pattern-master' : 'pattern-explorer');
  };

  const useHint = () => {
    if (!showHint && challenge) {
      setShowHint(true);
      setHintsUsed(prev => prev + 1);
    }
  };

  const getHintText = () => {
    if (!challenge) return '';
    
    switch (challenge.type) {
      case 'shape':
        return 'Perhatikan urutan bentuk dalam baris dan kolom';
      case 'color':
        return 'Lihat pola warna yang berulang';
      case 'size':
        return 'Amati perubahan ukuran elemen';
      case 'rotation':
        return 'Perhatikan arah rotasi setiap elemen';
      default:
        return 'Cari pola dalam susunan elemen';
    }
  };

  const renderShape = (element: PatternElement, size: string = 'w-8 h-8') => {
    const sizeMultiplier = element.size === 'small' ? 0.7 : element.size === 'large' ? 1.3 : 1;
    const actualSize = size === 'w-8 h-8' ? `w-${Math.round(8 * sizeMultiplier)} h-${Math.round(8 * sizeMultiplier)}` : size;
    
    const style = {
      color: element.color,
      transform: `rotate(${element.rotation}deg)`,
      fontSize: element.size === 'small' ? '1rem' : element.size === 'large' ? '2rem' : '1.5rem'
    };

    switch (element.shape) {
      case 'circle':
        return <div className={`${actualSize} rounded-full`} style={{backgroundColor: element.color, transform: style.transform}} />;
      case 'square':
        return <div className={`${actualSize} rounded-md`} style={{backgroundColor: element.color, transform: style.transform}} />;
      case 'triangle':
        return <div style={style}>▲</div>;
      case 'star':
        return <div style={style}>⭐</div>;
      case 'diamond':
        return <div style={style}>♦</div>;
      default:
        return <div className={actualSize} style={{backgroundColor: element.color}} />;
    }
  };

  const getDifficultyForLevel = (level: number): 'easy' | 'medium' | 'hard' => {
    if (level <= 4) return 'easy';
    if (level <= 8) return 'medium';
    return 'hard';
  };

  const calculateAssessmentScore = (stars: number, timeSpent: number, errors: number, correct: number, hints: number) => {
    const baseScore = stars * 30; // 30, 60, or 90
    
    // Accuracy bonus
    const accuracy = correct / Math.max(currentLevel - 1, 1);
    const accuracyBonus = Math.floor(accuracy * 20);
    
    // Time performance (reasonable time expectations for pattern recognition)
    const averageTimePerLevel = timeSpent / Math.max(currentLevel - 1, 1);
    const timeBonus = Math.max(0, Math.floor((90 - averageTimePerLevel) / 10)) * 2;
    
    // Error penalty
    const errorPenalty = errors * 3;
    
    // Hint penalty
    const hintPenalty = hints * 2;
    
    return Math.round(Math.max(10, baseScore + accuracyBonus + timeBonus - errorPenalty - hintPenalty));
  };

  const getPerformanceLevel = (score: number) => {
    if (score >= 90) return { level: 'Luar Biasa', color: 'text-purple-600', bg: 'bg-purple-50' };
    if (score >= 70) return { level: 'Sangat Baik', color: 'text-blue-600', bg: 'bg-blue-50' };
    if (score >= 50) return { level: 'Baik', color: 'text-green-600', bg: 'bg-green-50' };
    if (score >= 30) return { level: 'Cukup', color: 'text-yellow-600', bg: 'bg-yellow-50' };
    return { level: 'Perlu Latihan', color: 'text-red-600', bg: 'bg-red-50' };
  };

  const getStarRating = () => {
    const accuracy = correctAnswers / Math.max(currentLevel - 1, 1);
    const hintsPerLevel = hintsUsed / Math.max(currentLevel - 1, 1);
    
    if (accuracy >= 0.8 && hintsPerLevel <= 0.3) return 3;
    if (accuracy >= 0.6 && hintsPerLevel <= 0.6) return 2;
    return 1;
  };

  const resetGame = () => {
    setGameStarted(false);
    setGameCompleted(false);
    setCurrentLevel(1);
    setScore(0);
    setLives(3);
    setCorrectAnswers(0);
    setHintsUsed(0);
    setErrors(0);
    setGameStartTime(null);
    setGameCompletionHandled(false);
    setIsTimerRunning(false);
  };

  // Game completion screen
  if (gameCompleted) {
    const stars = getStarRating();
    const endTime = new Date();
    const gameTimeSpent = gameStartTime ? Math.floor((endTime.getTime() - gameStartTime.getTime()) / 1000) : 0;
    const finalScore = calculateAssessmentScore(stars, gameTimeSpent, errors, correctAnswers, hintsUsed);
    const performance = getPerformanceLevel(finalScore);
    
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
              rotate: [0, 10, -10, 0]
            }}
            transition={{ duration: 0.8, repeat: 3 }}
            className="text-8xl mb-4"
          >
            {lives > 0 ? '🎯' : '👁️'}
          </motion.div>

          <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
            {lives > 0 ? 'Mata Elang!' : 'Bagus!'}
          </h2>
          <p className="text-gray-600 font-body text-base mb-4">
            {lives > 0 ? 'Kamu ahli mengenali pola!' : 'Terus berlatih mengenali pola!'}
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
              <span className={`font-heading font-bold text-lg ${performance.color}`}>{finalScore}</span>
            </div>
            <div className={`${performance.color} font-body text-sm space-y-1`}>
              <p>Performance: <span className="font-bold">{performance.level}</span></p>
              <p>Domain: <span className="font-bold">Logika Visual & Abstraksi</span></p>
              <p>Level Tercapai: <span className="font-bold">{currentLevel}</span></p>
            </div>
          </div>

          {/* Detailed Stats */}
          <div className="bg-purple-50 rounded-2xl p-4 mb-6">
            <div className="text-purple-700 font-body text-sm space-y-2">
              <div className="flex justify-between">
                <span>Level Tercapai:</span>
                <span className="font-bold">{currentLevel}</span>
              </div>
              <div className="flex justify-between">
                <span>Waktu Total:</span>
                <span className="font-bold">{Math.floor(gameTimeSpent / 60)}:{(gameTimeSpent % 60).toString().padStart(2, '0')}</span>
              </div>
              <div className="flex justify-between">
                <span>Akurasi:</span>
                <span className="font-bold">{Math.round((correctAnswers / Math.max(currentLevel - 1, 1)) * 100)}%</span>
              </div>
              <div className="flex justify-between">
                <span>Kesalahan:</span>
                <span className="font-bold">{errors}</span>
              </div>
              <div className="flex justify-between">
                <span>Hint Digunakan:</span>
                <span className="font-bold">{hintsUsed}</span>
              </div>
              <div className="border-t border-purple-200 pt-2 mt-2">
                <div className="flex justify-between">
                  <span className="font-semibold">Skor Akhir:</span>
                  <span className="font-bold text-purple-800">{finalScore}/100</span>
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
              Stiker "{lives > 0 ? 'Pattern Master' : 'Pattern Explorer'}" ditambahkan!
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

  // Game start screen
  if (!gameStarted) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-purple-500 to-pink-600 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-6">
            <motion.button
              onClick={() => navigateTo('game')}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </motion.button>
            <h1 className="text-white font-heading font-bold text-xl">Pola Visual</h1>
            <div className="w-10" />
          </div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
          >
            <h2 className="text-white font-heading font-semibold text-lg mb-2">
              Asah Mata & Otak! 👁️
            </h2>
            <p className="text-purple-100 font-body text-sm">
              Temukan pola tersembunyi dalam susunan bentuk dan warna!
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
                <p className="text-gray-600 font-body text-sm">Amati pola dalam grid bentuk & warna</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                  <span className="text-purple-600 font-bold text-sm">2</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Temukan elemen yang hilang</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                  <span className="text-purple-600 font-bold text-sm">3</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Selesaikan 12 level dengan 3 nyawa</p>
              </div>
            </div>
          </motion.div>

          {/* Pattern Types */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-gradient-to-r from-pink-50 to-purple-50 border border-pink-200 rounded-2xl p-6 mb-6"
          >
            <h3 className="text-purple-700 font-heading font-bold text-base mb-3">
              Jenis Pola:
            </h3>
            <div className="grid grid-cols-2 gap-3">
              <div className="flex items-center space-x-2">
                <div className="w-4 h-4 bg-blue-500 rounded-full"></div>
                <span className="text-gray-600 font-body text-sm">Bentuk</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="w-4 h-4 bg-gradient-to-r from-red-400 to-yellow-400 rounded-full"></div>
                <span className="text-gray-600 font-body text-sm">Warna</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="flex space-x-1">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                  <div className="w-4 h-4 bg-green-500 rounded-full"></div>
                </div>
                <span className="text-gray-600 font-body text-sm">Ukuran</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="text-purple-600 transform rotate-45">▲</div>
                <span className="text-gray-600 font-body text-sm">Rotasi</span>
              </div>
            </div>
          </motion.div>

          <motion.button
            onClick={() => {
              setGameStarted(true);
              setGameStartTime(new Date());
            }}
            className="w-full bg-gradient-to-r from-purple-500 to-pink-600 text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            Mulai Bermain! 🎨
          </motion.button>
        </div>
      </div>
    );
  }

  if (!challenge) return null;

  // Main game screen
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-500 to-pink-600 px-6 pt-14 pb-6">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-lg">Pola Visual</h1>
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
          <div className="flex items-center justify-between text-center">
            <div>
              <span className="text-white font-heading font-bold text-lg">Level {currentLevel}</span>
              <p className="text-purple-100 font-body text-xs">dari {maxLevel}</p>
            </div>
            <div>
              <span className="text-white font-heading font-bold text-lg">{score}</span>
              <p className="text-purple-100 font-body text-xs">Skor</p>
            </div>
            <div>
              <div className="flex space-x-1">
                {[...Array(3)].map((_, i) => (
                  <div
                    key={i}
                    className={`w-2 h-2 rounded-full ${i < lives ? 'bg-red-400' : 'bg-white/30'}`}
                  />
                ))}
              </div>
              <p className="text-purple-100 font-body text-xs">Nyawa</p>
            </div>
            <div>
              <div className="flex items-center space-x-1">
                <Clock className="w-4 h-4 text-white" />
                <span className="text-white font-heading font-bold text-lg">{timeLeft}</span>
              </div>
              <p className="text-purple-100 font-body text-xs">Detik</p>
            </div>
          </div>
        </div>
      </div>

      {/* Game Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Level Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-4 shadow-sm"
        >
          <div className="flex items-center justify-between mb-3">
            <div>
              <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                challenge.difficulty === 'easy' ? 'bg-green-100 text-green-700' :
                challenge.difficulty === 'medium' ? 'bg-yellow-100 text-yellow-700' :
                'bg-red-100 text-red-700'
              }`}>
                {challenge.difficulty === 'easy' ? 'Mudah' : 
                 challenge.difficulty === 'medium' ? 'Sedang' : 'Sulit'}
              </span>
              <span className="ml-2 bg-purple-100 text-purple-700 text-xs font-bold px-2 py-1 rounded-full">
                Pola: {challenge.type === 'shape' ? 'Bentuk' : 
                       challenge.type === 'color' ? 'Warna' :
                       challenge.type === 'size' ? 'Ukuran' : 'Rotasi'}
              </span>
            </div>
            <motion.button
              onClick={useHint}
              disabled={showHint}
              className={`p-2 rounded-xl ${showHint ? 'bg-gray-100 text-gray-400' : 'bg-yellow-100 text-yellow-600 hover:bg-yellow-200'}`}
              whileTap={{ scale: 0.95 }}
            >
              <Lightbulb className="w-5 h-5" />
            </motion.button>
          </div>
          {showHint && (
            <motion.p
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="text-gray-600 font-body text-sm bg-yellow-50 p-3 rounded-xl"
            >
              💡 {getHintText()}
            </motion.p>
          )}
        </motion.div>

        {/* Pattern Grid */}
        <div className="bg-white rounded-2xl p-6 shadow-sm">
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4 text-center">
            Temukan elemen yang hilang:
          </h3>
          <div className={`grid gap-3 mb-6 justify-center ${
            challenge.pattern.length === 3 ? 'grid-cols-3' : 'grid-cols-4'
          }`}>
            {challenge.pattern.map((row, rowIndex) =>
              row.map((element, colIndex) => (
                <motion.div
                  key={`${rowIndex}-${colIndex}`}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: (rowIndex * row.length + colIndex) * 0.05 }}
                  className={`w-16 h-16 rounded-2xl flex items-center justify-center shadow-md ${
                    rowIndex === challenge.missing.row && colIndex === challenge.missing.col
                      ? 'border-2 border-dashed border-purple-400 bg-purple-50'
                      : 'bg-gradient-to-br from-gray-100 to-gray-200 border-2 border-gray-300'
                  }`}
                >
                  {rowIndex === challenge.missing.row && colIndex === challenge.missing.col ? (
                    <Eye className="w-8 h-8 text-purple-400" />
                  ) : (
                    renderShape(element)
                  )}
                </motion.div>
              ))
            )}
          </div>

          {/* Answer Choices */}
          <div className="grid grid-cols-2 gap-3">
            {challenge.choices.map((choice, index) => (
              <motion.button
                key={index}
                onClick={() => handleAnswer(choice)}
                disabled={!!answerFeedback}
                className={`py-4 px-6 rounded-2xl shadow-md transition-all flex items-center justify-center ${
                  selectedAnswer === choice
                    ? answerFeedback === 'correct'
                      ? 'bg-gradient-to-br from-green-400 to-green-500 text-white'
                      : 'bg-gradient-to-br from-red-400 to-red-500 text-white'
                    : 'bg-gradient-to-br from-gray-100 to-gray-200 hover:from-gray-200 hover:to-gray-300'
                } ${!!answerFeedback ? 'cursor-not-allowed' : 'hover:scale-105'}`}
                whileHover={!answerFeedback ? { scale: 1.05 } : {}}
                whileTap={!answerFeedback ? { scale: 0.95 } : {}}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 + index * 0.1 }}
              >
                {renderShape(choice, 'w-10 h-10')}
                {selectedAnswer === choice && answerFeedback && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="ml-2 text-white"
                  >
                    {answerFeedback === 'correct' ? '✓' : '✗'}
                  </motion.div>
                )}
              </motion.button>
            ))}
          </div>

          {/* Feedback */}
          {answerFeedback && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className={`mt-4 p-4 rounded-2xl text-center ${
                answerFeedback === 'correct'
                  ? 'bg-green-50 text-green-700'
                  : 'bg-red-50 text-red-700'
              }`}
            >
              <p className="font-bold">
                {answerFeedback === 'correct' 
                  ? '🎉 Hebat! Pola berhasil dikenali!' 
                  : '❌ Belum tepat! Coba perhatikan pola lagi'}
              </p>
            </motion.div>
          )}
        </div>
      </div>
    </div>
  );
}