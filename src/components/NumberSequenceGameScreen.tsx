import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, RotateCcw, Trophy, Star, CheckCircle, Lightbulb, Clock } from 'lucide-react';

interface NumberSequenceGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

interface SequenceChallenge {
  sequence: number[];
  missing: number;
  missingIndex: number;
  difficulty: 'easy' | 'medium' | 'hard';
  pattern: string;
  choices: number[];
}

export default function NumberSequenceGameScreen({ navigateTo, addSticker, updateGameAssessment }: NumberSequenceGameScreenProps) {
  const [gameStarted, setGameStarted] = useState(false);
  const [currentLevel, setCurrentLevel] = useState(1);
  const [challenge, setChallenge] = useState<SequenceChallenge | null>(null);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [gameCompleted, setGameCompleted] = useState(false);
  const [timeLeft, setTimeLeft] = useState(30);
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [showHint, setShowHint] = useState(false);
  const [hintsUsed, setHintsUsed] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);
  const [answerFeedback, setAnswerFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [errors, setErrors] = useState(0);
  const [totalTime, setTotalTime] = useState(0);
  const [gameStartTime, setGameStartTime] = useState<Date | null>(null);
  const [gameCompletionHandled, setGameCompletionHandled] = useState(false);

  const maxLevel = 15;

  // Generate sequence patterns
  const generateChallenge = useCallback((level: number): SequenceChallenge => {
    const patterns = [
      // Easy patterns (levels 1-5)
      { 
        type: 'addition', 
        generate: (start: number, step: number) => Array.from({length: 6}, (_, i) => start + i * step),
        description: '+' 
      },
      { 
        type: 'subtraction', 
        generate: (start: number, step: number) => Array.from({length: 6}, (_, i) => start - i * step),
        description: '-' 
      },
      // Medium patterns (levels 6-10)
      { 
        type: 'multiplication', 
        generate: (start: number, step: number) => Array.from({length: 5}, (_, i) => start * Math.pow(step, i)),
        description: '×' 
      },
      { 
        type: 'fibonacci', 
        generate: () => {
          const fib = [1, 1];
          for (let i = 2; i < 6; i++) {
            fib[i] = fib[i-1] + fib[i-2];
          }
          return fib;
        },
        description: 'Fibonacci' 
      },
      // Hard patterns (levels 11-15)
      { 
        type: 'square', 
        generate: (start: number) => Array.from({length: 5}, (_, i) => Math.pow(start + i, 2)),
        description: 'n²' 
      },
      { 
        type: 'complex', 
        generate: (start: number, step: number) => Array.from({length: 6}, (_, i) => start + i * step + i),
        description: 'n + step + i' 
      }
    ];

    let difficulty: 'easy' | 'medium' | 'hard';
    let patternIndex: number;
    
    if (level <= 5) {
      difficulty = 'easy';
      patternIndex = Math.floor(Math.random() * 2); // addition, subtraction
    } else if (level <= 10) {
      difficulty = 'medium';
      patternIndex = 2 + Math.floor(Math.random() * 2); // multiplication, fibonacci
    } else {
      difficulty = 'hard';
      patternIndex = 4 + Math.floor(Math.random() * 2); // square, complex
    }

    const pattern = patterns[patternIndex];
    let sequence: number[];
    
    switch (pattern.type) {
      case 'addition':
      case 'subtraction':
      case 'complex':
        const start = Math.floor(Math.random() * 10) + 1;
        const step = Math.floor(Math.random() * 5) + 1;
        sequence = pattern.generate(start, step);
        break;
      case 'multiplication':
        const startMult = Math.floor(Math.random() * 3) + 2;
        const stepMult = Math.floor(Math.random() * 2) + 2;
        sequence = pattern.generate(startMult, stepMult);
        break;
      case 'fibonacci':
        sequence = pattern.generate();
        break;
      case 'square':
        const startSquare = Math.floor(Math.random() * 3) + 1;
        sequence = pattern.generate(startSquare);
        break;
      default:
        sequence = [1, 2, 3, 4, 5, 6];
    }

    // Choose random position to remove
    const missingIndex = Math.floor(Math.random() * sequence.length);
    const missing = sequence[missingIndex];
    
    // Generate wrong choices
    const choices = [missing];
    while (choices.length < 4) {
      const wrongChoice = missing + Math.floor(Math.random() * 20) - 10;
      if (!choices.includes(wrongChoice) && wrongChoice > 0) {
        choices.push(wrongChoice);
      }
    }
    
    // Shuffle choices
    choices.sort(() => Math.random() - 0.5);

    return {
      sequence,
      missing,
      missingIndex,
      difficulty,
      pattern: pattern.description,
      choices
    };
  }, []);

  // Initialize game
  useEffect(() => {
    if (gameStarted && !gameCompleted) {
      const newChallenge = generateChallenge(currentLevel);
      setChallenge(newChallenge);
      setTimeLeft(30);
      setIsTimerRunning(true);
      setShowHint(false);
      setSelectedAnswer(null);
      setAnswerFeedback(null);
    }
  }, [gameStarted, currentLevel, gameCompleted, generateChallenge]);

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isTimerRunning && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft(prev => {
          if (prev <= 1) {
            handleWrongAnswer();
            return 30;
          }
          return prev - 1;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning, timeLeft]);

  const handleAnswer = (answer: number) => {
    if (!challenge || answerFeedback) return;
    
    setSelectedAnswer(answer);
    setIsTimerRunning(false);
    
    if (answer === challenge.missing) {
      setAnswerFeedback('correct');
      setScore(prev => prev + (challenge.difficulty === 'easy' ? 10 : challenge.difficulty === 'medium' ? 15 : 20));
      setCorrectAnswers(prev => prev + 1);
      
      setTimeout(() => {
        if (currentLevel >= maxLevel) {
          completeGame();
        } else {
          setCurrentLevel(prev => prev + 1);
        }
      }, 1500);
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
        }, 1500);
      } else {
        setTimeout(() => {
          setCurrentLevel(prev => prev + 1);
        }, 1500);
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
      domains: ['Logika', 'Matematika', 'Pattern Recognition']
    };
    
    updateGameAssessment('numberSequence', sessionData);
    setGameCompleted(true);
    addSticker(lives > 0 ? 'number-master' : 'number-explorer');
  };

  const useHint = () => {
    if (!showHint && challenge) {
      setShowHint(true);
      setHintsUsed(prev => prev + 1);
    }
  };

  const getHintText = () => {
    if (!challenge) return '';
    
    switch (challenge.pattern) {
      case '+':
        return 'Setiap angka bertambah dengan jumlah yang sama';
      case '-':
        return 'Setiap angka berkurang dengan jumlah yang sama';
      case '×':
        return 'Setiap angka dikali dengan angka yang sama';
      case 'Fibonacci':
        return 'Setiap angka adalah hasil penjumlahan 2 angka sebelumnya';
      case 'n²':
        return 'Setiap angka adalah kuadrat dari bilangan berurutan';
      case 'n + step + i':
        return 'Pola lebih kompleks: perhatikan selisih antar angka';
      default:
        return 'Perhatikan pola dalam urutan angka';
    }
  };

  const getStarRating = () => {
    const accuracy = correctAnswers / Math.max(currentLevel - 1, 1);
    const hintsPerLevel = hintsUsed / Math.max(currentLevel - 1, 1);
    
    if (accuracy >= 0.8 && hintsPerLevel <= 0.5) return 3;
    if (accuracy >= 0.6 && hintsPerLevel <= 1) return 2;
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
    setTotalTime(0);
    setGameStartTime(null);
    setGameCompletionHandled(false);
    setIsTimerRunning(false);
  };

  const getDifficultyForLevel = (level: number): 'easy' | 'medium' | 'hard' => {
    if (level <= 5) return 'easy';
    if (level <= 10) return 'medium';
    return 'hard';
  };

  const calculateAssessmentScore = (stars: number, timeSpent: number, errors: number, correct: number, hints: number) => {
    const baseScore = stars * 30; // 30, 60, or 90
    
    // Accuracy bonus
    const accuracy = correct / Math.max(currentLevel - 1, 1);
    const accuracyBonus = Math.floor(accuracy * 20);
    
    // Time performance (faster = better, but reasonable time)
    const averageTimePerLevel = timeSpent / Math.max(currentLevel - 1, 1);
    const timeBonus = Math.max(0, Math.floor((60 - averageTimePerLevel) / 5)) * 2;
    
    // Error penalty
    const errorPenalty = errors * 3;
    
    // Hint penalty (using hints reduces score)
    const hintPenalty = hints * 2;
    
    return Math.round(Math.max(10, baseScore + accuracyBonus + timeBonus - errorPenalty - hintPenalty));
  };

  const getPerformanceLevel = (score: number) => {
    if (score >= 90) return { level: 'Luar Biasa', color: 'text-blue-600', bg: 'bg-blue-50' };
    if (score >= 70) return { level: 'Sangat Baik', color: 'text-green-600', bg: 'bg-green-50' };
    if (score >= 50) return { level: 'Baik', color: 'text-yellow-600', bg: 'bg-yellow-50' };
    if (score >= 30) return { level: 'Cukup', color: 'text-orange-600', bg: 'bg-orange-50' };
    return { level: 'Perlu Latihan', color: 'text-red-600', bg: 'bg-red-50' };
  };

  // Game completion screen
  if (gameCompleted) {
    const stars = getStarRating();
    const endTime = new Date();
    const gameTimeSpent = gameStartTime ? Math.floor((endTime.getTime() - gameStartTime.getTime()) / 1000) : 0;
    const finalScore = calculateAssessmentScore(stars, gameTimeSpent, errors, correctAnswers, hintsUsed);
    const performance = getPerformanceLevel(finalScore);
    
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center">
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
            {lives > 0 ? '🏆' : '🎯'}
          </motion.div>

          <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
            {lives > 0 ? 'Fantastis!' : 'Hebat!'}
          </h2>
          <p className="text-gray-600 font-body text-base mb-4">
            {lives > 0 ? 'Kamu menyelesaikan semua level!' : 'Usaha yang bagus! Coba lagi!'}
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

          {/* Stats */}
          <div className="bg-blue-50 rounded-2xl p-4 mb-6">
            <div className="text-blue-700 font-body text-sm space-y-1">
              <p>Level Tercapai: <span className="font-bold">{currentLevel}</span></p>
              <p>Skor: <span className="font-bold">{score}</span></p>
              <p>Akurasi: <span className="font-bold">{Math.round((correctAnswers / Math.max(currentLevel - 1, 1)) * 100)}%</span></p>
              <p>Hint Digunakan: <span className="font-bold">{hintsUsed}</span></p>
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
              Stiker "{lives > 0 ? 'Number Master' : 'Number Explorer'}" ditambahkan!
            </p>
          </div>

          <div className="flex space-x-3">
            <motion.button
              onClick={resetGame}
              className="flex-1 bg-blue-500 text-white py-3 px-4 rounded-2xl font-heading font-bold"
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
        <div className="bg-gradient-to-r from-blue-500 to-indigo-600 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-6">
            <motion.button
              onClick={() => navigateTo('game')}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </motion.button>
            <h1 className="text-white font-heading font-bold text-xl">Urutan Angka</h1>
            <div className="w-10" />
          </div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
          >
            <h2 className="text-white font-heading font-semibold text-lg mb-2">
              Latih Logika Matematika! 🧮
            </h2>
            <p className="text-blue-100 font-body text-sm">
              Temukan pola dan lengkapi urutan angka yang hilang!
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
                <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                  <span className="text-blue-600 font-bold text-sm">1</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Perhatikan pola dalam urutan angka</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                  <span className="text-blue-600 font-bold text-sm">2</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Pilih angka yang tepat untuk melengkapi urutan</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                  <span className="text-blue-600 font-bold text-sm">3</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Selesaikan 15 level dengan 3 nyawa</p>
              </div>
            </div>
          </motion.div>

          {/* Difficulty Info */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-gradient-to-r from-green-50 to-blue-50 border border-green-200 rounded-2xl p-6 mb-6"
          >
            <h3 className="text-blue-700 font-heading font-bold text-base mb-3">
              Level Kesulitan:
            </h3>
            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <span className="bg-green-100 text-green-700 px-2 py-1 rounded-full text-xs font-bold">Level 1-5</span>
                <span className="text-gray-600 font-body text-sm">Penjumlahan & Pengurangan</span>
              </div>
              <div className="flex items-center space-x-2">
                <span className="bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full text-xs font-bold">Level 6-10</span>
                <span className="text-gray-600 font-body text-sm">Perkalian & Fibonacci</span>
              </div>
              <div className="flex items-center space-x-2">
                <span className="bg-red-100 text-red-700 px-2 py-1 rounded-full text-xs font-bold">Level 11-15</span>
                <span className="text-gray-600 font-body text-sm">Kuadrat & Pola Kompleks</span>
              </div>
            </div>
          </motion.div>

          <motion.button
            onClick={() => {
             setGameStarted(true);
             setGameStartTime(new Date());
           }}
            className="w-full bg-gradient-to-r from-blue-500 to-indigo-600 text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            Mulai Bermain! 🚀
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
      <div className="bg-gradient-to-r from-blue-500 to-indigo-600 px-6 pt-14 pb-6">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-lg">Urutan Angka</h1>
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
              <p className="text-blue-100 font-body text-xs">dari {maxLevel}</p>
            </div>
            <div>
              <span className="text-white font-heading font-bold text-lg">{score}</span>
              <p className="text-blue-100 font-body text-xs">Skor</p>
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
              <p className="text-blue-100 font-body text-xs">Nyawa</p>
            </div>
            <div>
              <div className="flex items-center space-x-1">
                <Clock className="w-4 h-4 text-white" />
                <span className="text-white font-heading font-bold text-lg">{timeLeft}</span>
              </div>
              <p className="text-blue-100 font-body text-xs">Detik</p>
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
              <span className="ml-2 bg-blue-100 text-blue-700 text-xs font-bold px-2 py-1 rounded-full">
                Pola: {challenge.pattern}
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

        {/* Number Sequence */}
        <div className="bg-white rounded-2xl p-6 shadow-sm">
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4 text-center">
            Lengkapi urutan ini:
          </h3>
          <div className="flex flex-wrap justify-center gap-3 mb-6">
            {challenge.sequence.map((num, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: index * 0.1 }}
                className={`w-16 h-16 rounded-2xl flex items-center justify-center font-bold text-lg shadow-md ${
                  index === challenge.missingIndex
                    ? 'border-2 border-dashed border-blue-400 bg-blue-50 text-blue-600'
                    : 'bg-gradient-to-br from-indigo-100 to-indigo-200 border-2 border-indigo-300 text-indigo-800'
                }`}
              >
                {index === challenge.missingIndex ? '?' : num}
              </motion.div>
            ))}
          </div>

          {/* Answer Choices */}
          <div className="grid grid-cols-2 gap-3">
            {challenge.choices.map((choice, index) => (
              <motion.button
                key={index}
                onClick={() => handleAnswer(choice)}
                disabled={!!answerFeedback}
                className={`py-4 px-6 rounded-2xl font-bold text-lg shadow-md transition-all ${
                  selectedAnswer === choice
                    ? answerFeedback === 'correct'
                      ? 'bg-gradient-to-br from-green-400 to-green-500 text-white'
                      : 'bg-gradient-to-br from-red-400 to-red-500 text-white'
                    : 'bg-gradient-to-br from-gray-100 to-gray-200 text-gray-800 hover:from-gray-200 hover:to-gray-300'
                } ${!!answerFeedback ? 'cursor-not-allowed' : 'hover:scale-105'}`}
                whileHover={!answerFeedback ? { scale: 1.05 } : {}}
                whileTap={!answerFeedback ? { scale: 0.95 } : {}}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 + index * 0.1 }}
              >
                {choice}
                {selectedAnswer === choice && answerFeedback && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="inline-block ml-2"
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
                  ? '🎉 Benar! Jawaban yang tepat!' 
                  : `❌ Salah! Jawaban yang benar adalah ${challenge.missing}`}
              </p>
            </motion.div>
          )}
        </div>
      </div>
    </div>
  );
}