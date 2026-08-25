import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Star, Trophy, Clock, Sparkles } from 'lucide-react';

interface MirrorPatternGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

interface PatternProblem {
  id: number;
  pattern: string[][];
  correctMirror: string[][];
  options: string[][][];
  level: number;
  type: 'horizontal' | 'vertical' | 'diagonal';
}

export default function MirrorPatternGame({ 
  navigateTo, 
  addSticker, 
  childName,
  updateTestResults,
  updateGameAssessment 
}: MirrorPatternGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'playing' | 'completed'>('menu');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [timeLeft, setTimeLeft] = useState(90);
  const [currentProblem, setCurrentProblem] = useState<PatternProblem | null>(null);
  const [startTime, setStartTime] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [feedback, setFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);

  // Generate mirror pattern problems
  const generateMirrorProblem = (level: number): PatternProblem => {
    const emojis = ['🔴', '🔵', '🟡', '🟢', '⭐', '❤️', '🔷', '🔶'];
    const size = level <= 2 ? 3 : 4;
    
    // Generate base pattern
    const pattern: string[][] = [];
    for (let i = 0; i < size; i++) {
      const row: string[] = [];
      for (let j = 0; j < Math.floor(size / 2) + 1; j++) {
        row.push(emojis[Math.floor(Math.random() * (level + 2))]);
      }
      pattern.push(row);
    }

    // Generate mirror based on level
    let correctMirror: string[][];
    let mirrorType: 'horizontal' | 'vertical' | 'diagonal';

    if (level <= 2) {
      // Vertical mirror (easier)
      mirrorType = 'vertical';
      correctMirror = pattern.map(row => [...row].reverse());
    } else if (level <= 3) {
      // Horizontal mirror
      mirrorType = 'horizontal';
      correctMirror = [...pattern].reverse();
    } else {
      // Diagonal or complex
      mirrorType = 'diagonal';
      correctMirror = pattern[0].map((_, colIndex) => 
        pattern.map(row => row[colIndex]).reverse()
      );
    }

    // Generate wrong options
    const generateWrongOption = () => {
      const wrong: string[][] = correctMirror.map(row => 
        row.map(() => emojis[Math.floor(Math.random() * (level + 2))])
      );
      return wrong;
    };

    // Create array of options with correct answer
    const options = [
      JSON.parse(JSON.stringify(correctMirror)), // Deep clone
      generateWrongOption(), 
      generateWrongOption()
    ];
    
    // Shuffle options using Fisher-Yates algorithm for better randomization
    for (let i = options.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [options[i], options[j]] = [options[j], options[i]];
    }

    return {
      id: Date.now(),
      pattern,
      correctMirror,
      options: options,
      level,
      type: mirrorType
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
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.15);
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.3);
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
    if (gameState === 'playing' && !currentProblem) {
      generateNewProblem();
    }
  }, [gameState, currentProblem]);

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
    generateNewProblem();
    generateGameSound(440, 0.3, 'click');
  };

  const generateNewProblem = () => {
    const problem = generateMirrorProblem(currentLevel);
    setCurrentProblem(problem);
    setTotalQuestions(prev => prev + 1);
    setFeedback(null);
    setSelectedOption(null);
  };

  const handleOptionClick = (optionIndex: number) => {
    if (!currentProblem || feedback) return;
    
    setSelectedOption(optionIndex);
    const selectedMirror = currentProblem.options[optionIndex];
    const isCorrect = JSON.stringify(selectedMirror) === JSON.stringify(currentProblem.correctMirror);
    
    if (isCorrect) {
      setFeedback('correct');
      setScore(prev => prev + (15 * currentLevel));
      setCorrectAnswers(prev => {
        const newCorrect = prev + 1;
        if (newCorrect % 4 === 0 && currentLevel < 4) {
          setCurrentLevel(prevLevel => prevLevel + 1);
        }
        return newCorrect;
      });
      generateGameSound(523, 0.5, 'success');
      addSticker('mirror-master');
    } else {
      setFeedback('wrong');
      setWrongAnswers(prev => prev + 1);
      generateGameSound(220, 0.4, 'error');
    }

    // Save session data
    setGameSessionData(prev => [...prev, {
      problemId: currentProblem.id,
      isCorrect: isCorrect,
      mirrorType: currentProblem.type,
      timeSpent: Date.now() - startTime,
      level: currentLevel
    }]);

    // Move to next problem
    setTimeout(() => {
      setCurrentProblem(null);
      setFeedback(null);
      setSelectedOption(null);
    }, 2000);
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
      gameMode: 'Mirror Pattern',
      level: currentLevel,
      categoryScores: {
        abstraction: Math.round((accuracy / 100) * 35),
        spatial: Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 35),
        pattern: Math.round((currentLevel / 4) * 30)
      }
    });

    if (updateGameAssessment) {
      updateGameAssessment('mirrorPatternGame', {
        score: score,
        timeSpent: totalTime,
        errors: wrongAnswers,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Kognitif'
      });
    }

    if (accuracy >= 90) addSticker('mirror-genius');
    if (correctAnswers >= 12) addSticker('reflection-expert');
    addSticker('mirror-complete');
  };

  // Menu Screen
  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-indigo-300 via-purple-300 to-pink-400 relative overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute top-16 left-8 text-4xl animate-pulse">🪞</div>
          <div className="absolute top-24 right-12 text-5xl animate-bounce">✨</div>
          <div className="absolute bottom-24 left-16 text-4xl animate-spin-slow">🔮</div>
          <div className="absolute bottom-32 right-20 text-5xl animate-pulse">🌟</div>
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
            <h1 className="text-white font-heading text-xl">Mirror Pattern</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🪞
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Cermin Pola Ajaib!
            </h2>
            <p className="text-indigo-100 text-base mb-8">
              Temukan pola cermin yang tepat dan asah kemampuan spatial!
            </p>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">1</span>
                  </div>
                  <p className="text-purple-100 text-sm">Perhatikan pola di sebelah kiri</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">2</span>
                  </div>
                  <p className="text-purple-100 text-sm">Pilih pola cermin yang benar</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">3</span>
                  </div>
                  <p className="text-purple-100 text-sm">Selesaikan sebanyak mungkin!</p>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="w-full bg-white text-purple-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🪞 Mulai Bermain!
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
      <div className="min-h-screen bg-gradient-to-b from-indigo-300 via-purple-300 to-pink-400 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Luar Biasa!</h1>
            <p className="text-purple-100 text-lg">
              {childName}, kamu hebat dalam mengenali pola cermin!
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
              className="w-full bg-white text-purple-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
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
  if (gameState === 'playing' && currentProblem) {
    const renderPattern = (pattern: string[][], isOption: boolean = false, optionIndex?: number) => (
      <div className="inline-flex flex-col gap-1">
        {pattern.map((row, i) => (
          <div key={i} className="flex gap-1">
            {row.map((cell, j) => (
              <div 
                key={j} 
                className={`w-10 h-10 flex items-center justify-center rounded-lg ${
                  isOption ? 'bg-purple-100' : 'bg-white'
                }`}
              >
                <span className="text-2xl">{cell}</span>
              </div>
            ))}
          </div>
        ))}
      </div>
    );

    return (
      <div className="min-h-screen bg-gradient-to-b from-indigo-200 via-purple-200 to-pink-300">
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
              <div className="font-heading font-bold text-lg">Mirror Pattern</div>
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
                <Clock className="w-5 h-5 text-purple-200" />
                <span className="text-white font-medium">{timeLeft}s</span>
              </div>
              <div className="flex items-center space-x-2">
                <Star className="w-5 h-5 text-yellow-300" />
                <span className="text-white font-medium">{correctAnswers} / {totalQuestions}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Game Area */}
        <div className="px-6 pb-8">
          {/* Pattern Display */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl p-6 mb-6 shadow-lg"
          >
            <h3 className="text-gray-900 font-heading text-lg mb-4 text-center">
              Temukan Pola Cermin yang Benar!
            </h3>
            <div className="flex items-center justify-center mb-2">
              {renderPattern(currentProblem.pattern)}
              <Sparkles className="w-8 h-8 mx-4 text-purple-500" />
              <div className="text-6xl text-gray-300">?</div>
            </div>
          </motion.div>

          {/* Options */}
          <div className="grid grid-cols-1 gap-4">
            {currentProblem.options.map((option, index) => (
              <motion.button
                key={index}
                onClick={() => handleOptionClick(index)}
                disabled={!!feedback}
                className={`p-6 rounded-2xl shadow-lg flex items-center justify-center ${
                  selectedOption === index
                    ? feedback === 'correct'
                      ? 'bg-green-500'
                      : 'bg-red-500'
                    : 'bg-white'
                }`}
                whileHover={!feedback ? { scale: 1.02 } : {}}
                whileTap={!feedback ? { scale: 0.98 } : {}}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
              >
                {renderPattern(option, true, index)}
                {selectedOption === index && feedback && (
                  <span className="ml-4 text-3xl">
                    {feedback === 'correct' ? '✨' : '❌'}
                  </span>
                )}
              </motion.button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return null;
}
