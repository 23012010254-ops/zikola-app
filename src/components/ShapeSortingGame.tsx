import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Star, Trophy, Clock } from 'lucide-react';

interface ShapeSortingGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

interface ShapeProblem {
  id: number;
  shape: string;
  color: string;
  size: 'small' | 'medium' | 'large';
  pattern: 'solid' | 'striped' | 'dotted';
  category: 'shape' | 'color' | 'size' | 'pattern';
  correctBucket: string;
  level: number;
}

export default function ShapeSortingGame({ 
  navigateTo, 
  addSticker, 
  childName,
  updateTestResults,
  updateGameAssessment 
}: ShapeSortingGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'playing' | 'completed'>('menu');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [timeLeft, setTimeLeft] = useState(90);
  const [currentShape, setCurrentShape] = useState<ShapeProblem | null>(null);
  const [startTime, setStartTime] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [feedback, setFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [streak, setStreak] = useState(0);

  const shapes = ['🔴', '🔵', '🟡', '🟢', '🟣', '🟠'];
  const shapeNames = ['circle', 'square', 'triangle', 'star', 'heart', 'diamond'];

  // Generate shape sorting challenge
  const generateShapeProblem = (level: number): ShapeProblem => {
    const problemTypes = [
      // Level 1: Sort by shape
      () => {
        const shapeIndex = Math.floor(Math.random() * 4);
        const shapes = ['⚫', '⬛', '🔺', '⭐'];
        const shapeNames = ['Lingkaran', 'Persegi', 'Segitiga', 'Bintang'];
        return {
          shape: shapes[shapeIndex],
          correctBucket: shapeNames[shapeIndex],
          category: 'shape' as const,
          instruction: 'Pilih bentuk yang sama!'
        };
      },
      // Level 2: Sort by color
      () => {
        const colorIndex = Math.floor(Math.random() * 4);
        const colors = ['🔴', '🔵', '🟡', '🟢'];
        const colorNames = ['Merah', 'Biru', 'Kuning', 'Hijau'];
        return {
          shape: colors[colorIndex],
          correctBucket: colorNames[colorIndex],
          category: 'color' as const,
          instruction: 'Pilih warna yang sama!'
        };
      },
      // Level 3: Sort by size
      () => {
        const sizes = ['small', 'medium', 'large'];
        const sizeEmojis = ['🔹', '🔶', '🔷'];
        const sizeNames = ['Kecil', 'Sedang', 'Besar'];
        const sizeIndex = Math.floor(Math.random() * 3);
        return {
          shape: sizeEmojis[sizeIndex],
          correctBucket: sizeNames[sizeIndex],
          category: 'size' as const,
          instruction: 'Pilih ukuran yang sama!'
        };
      },
      // Level 4: Complex patterns
      () => {
        const patterns = [
          { shape: '🔴🔴', bucket: 'Dua Sama', category: 'pattern' },
          { shape: '🔵🟡', bucket: 'Beda Warna', category: 'pattern' },
          { shape: '⭐⭐⭐', bucket: 'Tiga Sama', category: 'pattern' }
        ];
        const pattern = patterns[Math.floor(Math.random() * patterns.length)];
        return {
          shape: pattern.shape,
          correctBucket: pattern.bucket,
          category: 'pattern' as const,
          instruction: 'Pilih pola yang sesuai!'
        };
      }
    ];

    const problemType = problemTypes[Math.min(level - 1, problemTypes.length - 1)]();
    
    return {
      id: Date.now(),
      ...problemType,
      color: '',
      size: 'medium',
      pattern: 'solid',
      level: level
    };
  };

  // Sound effects
  const generateGameSound = (frequency: number, duration: number, type: 'success' | 'error' | 'click' = 'click') => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      switch (type) {
        case 'success':
          oscillator.frequency.setValueAtTime(523, audioContext.currentTime);
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1);
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.2);
          break;
        case 'error':
          oscillator.frequency.value = 220;
          oscillator.type = 'sawtooth';
          break;
        default:
          oscillator.frequency.value = 800;
      }
      
      oscillator.type = type === 'success' ? 'sine' : oscillator.type;
      gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + duration);
    } catch (e) {
      console.log('Audio not available');
    }
  };

  useEffect(() => {
    if (gameState === 'playing' && timeLeft > 0) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && gameState === 'playing') {
      endGame();
    }
  }, [timeLeft, gameState]);

  useEffect(() => {
    if (gameState === 'playing' && !currentShape) {
      generateNewProblem();
    }
  }, [gameState, currentShape]);

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setCorrectAnswers(0);
    setWrongAnswers(0);
    setTimeLeft(90);
    setCurrentLevel(1);
    setStartTime(Date.now());
    setTotalQuestions(0);
    setGameSessionData([]);
    setStreak(0);
    generateNewProblem();
    generateGameSound(440, 0.3, 'click');
  };

  const generateNewProblem = () => {
    const problem = generateShapeProblem(currentLevel);
    setCurrentShape(problem);
    setTotalQuestions(prev => prev + 1);
    setFeedback(null);
  };

  const handleBucketClick = (bucketName: string) => {
    if (!currentShape || feedback) return;
    
    const isCorrect = bucketName === currentShape.correctBucket;
    
    if (isCorrect) {
      setFeedback('correct');
      setScore(prev => prev + (10 * currentLevel) + (streak * 2));
      setCorrectAnswers(prev => {
        const newCorrect = prev + 1;
        if (newCorrect % 5 === 0 && currentLevel < 4) {
          setCurrentLevel(prevLevel => prevLevel + 1);
        }
        return newCorrect;
      });
      setStreak(prev => prev + 1);
      generateGameSound(523, 0.4, 'success');
      addSticker('shape-sorter');
    } else {
      setFeedback('wrong');
      setWrongAnswers(prev => prev + 1);
      setStreak(0);
      generateGameSound(220, 0.4, 'error');
    }

    // Save session data
    setGameSessionData(prev => [...prev, {
      problem: currentShape.shape,
      correctAnswer: currentShape.correctBucket,
      selectedAnswer: bucketName,
      isCorrect: isCorrect,
      category: currentShape.category,
      timeSpent: Date.now() - startTime,
      level: currentLevel
    }]);

    // Move to next problem
    setTimeout(() => {
      setCurrentShape(null);
      setFeedback(null);
    }, 1500);
  };

  const endGame = () => {
    setGameState('completed');
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    
    updateTestResults('cognitive', {
      score: correctAnswers,
      total: totalQuestions,
      percentage: accuracy,
      timeSpent: totalTime,
      gameMode: 'Shape Sorting',
      level: currentLevel,
      categoryScores: {
        abstraction: Math.round((accuracy / 100) * 35),
        pattern: Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 35),
        spatial: Math.round((currentLevel / 4) * 30)
      }
    });

    if (updateGameAssessment) {
      updateGameAssessment('shapeSortingGame', {
        score: score,
        timeSpent: totalTime,
        errors: wrongAnswers,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Kognitif'
      });
    }

    if (accuracy >= 90) addSticker('sorting-master');
    if (correctAnswers >= 15) addSticker('pattern-expert');
    addSticker('shape-champion');
  };

  // Menu Screen
  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-purple-300 via-pink-300 to-rose-400 relative overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute top-20 left-10 text-5xl animate-bounce">🔴</div>
          <div className="absolute top-32 right-16 text-4xl animate-pulse">🔵</div>
          <div className="absolute bottom-32 left-20 text-6xl animate-spin-slow">🟡</div>
          <div className="absolute bottom-20 right-12 text-5xl animate-bounce">🟢</div>
        </div>

        <div className="relative z-10 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => navigateTo('cognitive-test')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">Shape Sorting</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🎨
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Sortir Bentuk & Pola!
            </h2>
            <p className="text-purple-100 text-base mb-8">
              Asah kemampuan abstraksi dengan menyortir bentuk berdasarkan kategori!
            </p>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-pink-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">1</span>
                  </div>
                  <p className="text-pink-100 text-sm">Perhatikan bentuk yang muncul</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-pink-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">2</span>
                  </div>
                  <p className="text-pink-100 text-sm">Pilih kategori yang sesuai</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-pink-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">3</span>
                  </div>
                  <p className="text-pink-100 text-sm">Kumpulkan poin sebanyak-banyaknya!</p>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="w-full bg-white text-pink-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🎨 Mulai Bermain!
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  // Completion Screen
  if (gameState === 'completed') {
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    const totalTime = Math.round((Date.now() - startTime) / 1000);

    return (
      <div className="min-h-screen bg-gradient-to-b from-purple-300 via-pink-300 to-rose-400 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Hebat Sekali!</h1>
            <p className="text-pink-100 text-lg">
              {childName}, kamu pandai dalam menyortir bentuk!
            </p>
          </motion.div>

          <div className="space-y-4 mb-8">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Skor Total</span>
                <span className="font-heading font-bold text-2xl">{score}</span>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Akurasi</span>
                <span className="font-heading font-bold text-2xl">{accuracy}%</span>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Level Tercapai</span>
                <span className="font-heading font-bold text-2xl">{currentLevel}</span>
              </div>
            </motion.div>
          </div>

          <div className="space-y-3">
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              onClick={() => setGameState('menu')}
              className="w-full bg-white text-pink-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Main Lagi
            </motion.button>

            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              onClick={() => navigateTo('cognitive-test')}
              className="w-full bg-white/20 backdrop-blur-sm text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg border-2 border-white/30"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Pilih Game Lain
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  // Playing Screen
  if (gameState === 'playing' && currentShape) {
    const getBuckets = () => {
      switch (currentLevel) {
        case 1:
          return ['Lingkaran', 'Persegi', 'Segitiga', 'Bintang'];
        case 2:
          return ['Merah', 'Biru', 'Kuning', 'Hijau'];
        case 3:
          return ['Kecil', 'Sedang', 'Besar'];
        case 4:
          return ['Dua Sama', 'Beda Warna', 'Tiga Sama'];
        default:
          return ['Lingkaran', 'Persegi', 'Segitiga', 'Bintang'];
      }
    };

    const buckets = getBuckets();

    return (
      <div className="min-h-screen bg-gradient-to-b from-purple-200 via-pink-200 to-rose-300">
        {/* Header */}
        <div className="px-6 pt-14 pb-4">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              onClick={() => navigateTo('cognitive-test')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <div className="text-white text-center">
              <div className="font-heading font-bold text-lg">Shape Sorting</div>
              <div className="text-white/80 text-sm">Level {currentLevel}</div>
            </div>
            <div className="text-right text-white">
              <div className="font-heading font-bold text-2xl">{score}</div>
              <div className="text-white/80 text-sm">Skor</div>
            </div>
          </div>

          {/* Status Bar */}
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4 mb-4">
            <div className="flex justify-between items-center">
              <div className="flex items-center space-x-2">
                <Clock className="w-5 h-5 text-pink-200" />
                <span className="text-white font-medium">{timeLeft}s</span>
              </div>
              <div className="flex items-center space-x-2">
                <Star className="w-5 h-5 text-yellow-300" />
                <span className="text-white font-medium">{correctAnswers} / {totalQuestions}</span>
              </div>
              {streak > 2 && (
                <div className="flex items-center space-x-1">
                  <span className="text-white font-medium">🔥 {streak}</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Game Area */}
        <div className="px-6 pb-8">
          {/* Shape Display */}
          <motion.div
            initial={{ opacity: 0, scale: 0 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-2xl p-8 mb-6 shadow-lg relative"
          >
            <h3 className="text-gray-900 font-heading text-lg mb-6 text-center">
              {currentShape.instruction}
            </h3>
            <div className="flex items-center justify-center mb-4">
              <motion.div
                animate={feedback ? { scale: [1, 1.2, 1], rotate: [0, 360, 0] } : {}}
                className="text-8xl"
              >
                {currentShape.shape}
              </motion.div>
            </div>

            {/* Feedback */}
            <AnimatePresence>
              {feedback && (
                <motion.div
                  initial={{ opacity: 0, y: -20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0 }}
                  className={`absolute inset-x-0 top-0 p-4 rounded-t-2xl ${
                    feedback === 'correct' ? 'bg-green-500' : 'bg-red-500'
                  }`}
                >
                  <p className="text-white text-center font-heading">
                    {feedback === 'correct' ? '✨ Benar!' : '❌ Salah!'}
                  </p>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>

          {/* Buckets */}
          <div className="grid grid-cols-2 gap-4">
            {buckets.map((bucket, index) => (
              <motion.button
                key={bucket}
                onClick={() => handleBucketClick(bucket)}
                disabled={!!feedback}
                className={`p-6 rounded-2xl font-heading text-lg shadow-lg ${
                  feedback && bucket === currentShape.correctBucket
                    ? 'bg-green-500 text-white'
                    : 'bg-white text-purple-600'
                }`}
                whileHover={!feedback ? { scale: 1.05 } : {}}
                whileTap={!feedback ? { scale: 0.95 } : {}}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
              >
                {bucket}
              </motion.button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return null;
}
