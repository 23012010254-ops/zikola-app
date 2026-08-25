import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Clock, Target, Volume2 } from 'lucide-react';

interface AlienShooterGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

interface AlienTarget {
  id: number;
  x: number;
  y: number;
  problem: string;
  answer: number;
  options: number[];
  correctAnswer: number;
  destroyed: boolean;
  speed: number;
  spawnTime: number;
}

export default function AlienShooterGame({ navigateTo, addSticker, childName, updateTestResults, updateGameAssessment }: AlienShooterGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'playing' | 'completed'>('menu');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [timeLeft, setTimeLeft] = useState(90);
  const [aliens, setAliens] = useState<AlienTarget[]>([]);
  const [hits, setHits] = useState(0);
  const [misses, setMisses] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [startTime, setStartTime] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [selectedAlien, setSelectedAlien] = useState<number | null>(null);
  const [isPaused, setIsPaused] = useState(false);

  const gameAreaRef = useRef<HTMLDivElement>(null);

  // Advanced math problems for different levels
  const generateMathProblem = (level: number) => {
    const problems = [
      // Level 1: Advanced addition/subtraction
      () => {
        const a = Math.floor(Math.random() * 50) + 10;
        const b = Math.floor(Math.random() * 30) + 5;
        const operation = Math.random() > 0.5 ? '+' : '-';
        const answer = operation === '+' ? a + b : a - b;
        return {
          problem: `${a} ${operation} ${b}`,
          answer: answer,
          options: generateOptions(answer, 4)
        };
      },
      // Level 2: Simple fractions
      () => {
        const numerators = [1, 1, 2, 3, 1, 2, 3, 4];
        const denominators = [2, 3, 4, 6, 4, 6, 9, 8];
        const index = Math.floor(Math.random() * numerators.length);
        const num = numerators[index];
        const den = denominators[index];
        const decimal = Math.round((num / den) * 100) / 100;
        return {
          problem: `${num}/${den}`,
          answer: decimal,
          options: generateDecimalOptions(decimal)
        };
      },
      // Level 3: Multiplication
      () => {
        const a = Math.floor(Math.random() * 12) + 2;
        const b = Math.floor(Math.random() * 12) + 2;
        const answer = a * b;
        return {
          problem: `${a} × ${b}`,
          answer: answer,
          options: generateOptions(answer, 4)
        };
      },
      // Level 4: Division & Complex fractions
      () => {
        if (Math.random() > 0.5) {
          // Division
          const divisor = Math.floor(Math.random() * 8) + 2;
          const quotient = Math.floor(Math.random() * 15) + 2;
          const dividend = divisor * quotient;
          return {
            problem: `${dividend} ÷ ${divisor}`,
            answer: quotient,
            options: generateOptions(quotient, 4)
          };
        } else {
          // Complex fractions
          const numerators = [2, 3, 4, 5, 6, 7, 8, 9];
          const denominators = [3, 4, 5, 6, 8, 9, 10, 12];
          const numIndex = Math.floor(Math.random() * numerators.length);
          const denIndex = Math.floor(Math.random() * denominators.length);
          const num = numerators[numIndex];
          const den = denominators[denIndex];
          const decimal = Math.round((num / den) * 1000) / 1000;
          return {
            problem: `${num}/${den}`,
            answer: decimal,
            options: generateDecimalOptions(decimal)
          };
        }
      }
    ];

    const problemGenerator = problems[Math.min(level - 1, problems.length - 1)];
    return problemGenerator();
  };

  const generateOptions = (correct: number, count: number) => {
    const options = [correct];
    while (options.length < count) {
      const offset = Math.floor(Math.random() * 20) - 10;
      const option = correct + offset;
      if (option !== correct && option > 0 && !options.includes(option)) {
        options.push(option);
      }
    }
    return options.sort(() => Math.random() - 0.5);
  };

  const generateDecimalOptions = (correct: number) => {
    const options = [correct];
    const variations = [0.1, 0.2, 0.25, 0.33, 0.5, 0.67, 0.75];
    for (let i = 0; i < 3; i++) {
      const option = variations[Math.floor(Math.random() * variations.length)];
      if (!options.includes(option)) {
        options.push(option);
      }
    }
    while (options.length < 4) {
      const option = Math.round((Math.random()) * 100) / 100;
      if (!options.includes(option)) {
        options.push(option);
      }
    }
    return options.sort(() => Math.random() - 0.5);
  };

  // Generate game sounds
  const generateGameSound = (frequency: number, duration: number, type: 'laser' | 'explosion' | 'error' | 'success' | 'alien' = 'laser') => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      switch (type) {
        case 'laser':
          oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
          oscillator.frequency.exponentialRampToValueAtTime(200, audioContext.currentTime + 0.1);
          oscillator.type = 'square';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
          break;
        case 'explosion':
          oscillator.frequency.setValueAtTime(150, audioContext.currentTime);
          oscillator.frequency.exponentialRampToValueAtTime(50, audioContext.currentTime + 0.3);
          oscillator.type = 'sawtooth';
          gainNode.gain.setValueAtTime(0.4, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
          break;
        case 'success':
          oscillator.frequency.setValueAtTime(523, audioContext.currentTime);
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1);
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.2);
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
          break;
        case 'error':
          oscillator.frequency.value = 150;
          oscillator.type = 'sawtooth';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
          break;
        case 'alien':
          oscillator.frequency.setValueAtTime(300, audioContext.currentTime);
          oscillator.frequency.setValueAtTime(600, audioContext.currentTime + 0.1);
          oscillator.frequency.setValueAtTime(300, audioContext.currentTime + 0.2);
          oscillator.type = 'triangle';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
          break;
      }
      
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
    if (gameState === 'playing' && aliens.length < 3) {
      const spawnInterval = setInterval(() => {
        if (aliens.length < 3) {
          spawnAlien();
        }
      }, 3000 - (currentLevel * 300)); // Faster spawning each level

      return () => clearInterval(spawnInterval);
    }
  }, [gameState, currentLevel, aliens.length]);

  useEffect(() => {
    if (gameState === 'playing' && !isPaused) {
      const moveInterval = setInterval(() => {
        setAliens(prev => {
          const updated = prev.map(alien => ({
            ...alien,
            y: alien.y + alien.speed
          }));
          
          // Check if any alien reached the bottom
          const escaped = updated.filter(alien => alien.y >= window.innerHeight - 150 && !alien.destroyed);
          
          // Decrease life for each escaped alien
          if (escaped.length > 0) {
            escaped.forEach(() => {
              setLives(prevLives => {
                const newLives = prevLives - 1;
                if (newLives <= 0) {
                  setTimeout(() => {
                    if (gameState === 'playing') {
                      endGame();
                    }
                  }, 100);
                }
                return newLives;
              });
            });
            generateGameSound(150, 0.4, 'error');
          }
          
          // Filter out aliens that reached the bottom
          return updated.filter(alien => alien.y < window.innerHeight - 150);
        });
      }, 50);

      return () => clearInterval(moveInterval);
    }
  }, [gameState, isPaused]);

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setLives(3);
    setTimeLeft(90);
    setCurrentLevel(1);
    setHits(0);
    setMisses(0);
    setCorrectAnswers(0);
    setTotalQuestions(0);
    setStartTime(Date.now());
    setGameSessionData([]);
    setAliens([]);
    setSelectedAlien(null);
    setIsPaused(false);
    generateGameSound(400, 0.4, 'alien');
  };

  const spawnAlien = () => {
    if (gameState !== 'playing' || aliens.length >= 3) return; // Max 3 UFOs at once
    
    const problem = generateMathProblem(currentLevel);
    const newAlien: AlienTarget = {
      id: Date.now() + Math.random(), // Ensure unique IDs
      x: Math.random() * (window.innerWidth - 100),
      y: 50,
      problem: problem.problem,
      answer: problem.answer,
      options: problem.options,
      correctAnswer: problem.answer,
      destroyed: false,
      speed: 1 + (currentLevel * 0.3),
      spawnTime: Date.now()
    };
    
    setAliens(prev => {
      // Double check we don't exceed 3 UFOs
      if (prev.length >= 3) return prev;
      return [...prev, newAlien];
    });
    generateGameSound(300, 0.3, 'alien');
  };

  const shootAlien = (alienId: number, selectedAnswer: number) => {
    // Prevent multiple clicks and ensure game is still playing
    if (selectedAlien !== alienId || gameState !== 'playing') return;
    
    // Clear selection immediately to prevent double-clicking
    setSelectedAlien(null);
    setIsPaused(false);

    const alienToShoot = aliens.find(alien => alien.id === alienId);
    if (!alienToShoot || alienToShoot.destroyed) return;

    const isCorrect = selectedAnswer === alienToShoot.correctAnswer;
    
    // Update game states
    if (isCorrect) {
      setScore(prevScore => prevScore + (10 * currentLevel));
      setHits(prevHits => prevHits + 1);
      setCorrectAnswers(prevCorrect => {
        const newCorrectAnswers = prevCorrect + 1;
        // Level up every 5 correct answers
        if (newCorrectAnswers % 5 === 0 && currentLevel < 4) {
          setCurrentLevel(prevLevel => prevLevel + 1);
          addSticker('level-master');
        }
        return newCorrectAnswers;
      });
      generateGameSound(800, 0.3, 'explosion');
      addSticker('alien-hunter');
    } else {
      setMisses(prevMisses => prevMisses + 1);
      setLives(prevLives => {
        const newLives = prevLives - 1;
        if (newLives <= 0) {
          // Use a timeout to prevent state conflicts
          setTimeout(() => {
            if (gameState === 'playing') {
              endGame();
            }
          }, 100);
        }
        return newLives;
      });
      generateGameSound(150, 0.4, 'error');
    }

    // Save session data
    setGameSessionData(prev => [...prev, {
      problem: alienToShoot.problem,
      correctAnswer: alienToShoot.correctAnswer,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeSpent: Date.now() - startTime,
      level: currentLevel
    }]);

    // Remove the alien immediately without state conflicts
    setAliens(prev => prev.filter(alien => alien.id !== alienId));
    
    generateGameSound(800, 0.1, 'laser');
  };

  const endGame = () => {
    // Clear all aliens and reset selection state immediately
    setAliens([]);
    setSelectedAlien(null);
    setIsPaused(false);
    setGameState('completed');
    
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    
    // Update test results
    updateTestResults('cognitive', {
      score: correctAnswers,
      total: totalQuestions,
      percentage: accuracy,
      timeSpent: totalTime,
      gameMode: 'Alien Math Shooter',
      level: currentLevel,
      categoryScores: {
        logic: Math.round((accuracy / 100) * 25),
        attention: Math.round((hits / Math.max(hits + misses, 1)) * 25),
        adaptation: Math.round((currentLevel / 4) * 25)
      },
      detailedResults: {
        accuracy: accuracy,
        averageResponseTime: gameSessionData.length > 0 
          ? gameSessionData.reduce((sum, s) => sum + s.timeSpent, 0) / gameSessionData.length / 1000
          : 0,
        levelReached: currentLevel,
        livesRemaining: lives
      }
    });

    // Update game assessment
    if (updateGameAssessment) {
      updateGameAssessment('alienShooterGame', {
        score: score,
        timeSpent: totalTime,
        errors: misses,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Matematika Lanjutan & Logika'
      });
    }

    // Award stickers
    if (accuracy >= 90) addSticker('alien-master');
    if (correctAnswers >= 15) addSticker('space-commander');
    if (currentLevel >= 4) addSticker('galaxy-champion');
    addSticker('alien-test-complete');
    
    generateGameSound(523, 1.2, 'success');
  };

  // Check for game over
  useEffect(() => {
    if (lives <= 0 && gameState === 'playing') {
      // Use a timeout to prevent multiple calls
      const gameOverTimer = setTimeout(() => {
        if (gameState === 'playing') { // Double check to prevent race conditions
          endGame();
        }
      }, 100);
      return () => clearTimeout(gameOverTimer);
    }
  }, [lives, gameState]);

  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-purple-900 via-blue-900 to-black relative overflow-hidden">
        {/* Space background */}
        <div className="absolute inset-0">
          <div className="absolute top-20 left-10 text-yellow-300 text-sm animate-twinkle">⭐</div>
          <div className="absolute top-32 right-8 text-yellow-200 text-xs animate-twinkle">✨</div>
          <div className="absolute top-52 left-6 text-white text-xs animate-twinkle">⭐</div>
          <div className="absolute top-40 right-20 text-yellow-400 text-sm animate-twinkle">✨</div>
          <div className="absolute bottom-40 left-12 text-yellow-300 text-xs animate-twinkle">⭐</div>
          <div className="absolute bottom-60 right-6 text-white text-sm animate-twinkle">✨</div>
          <div className="absolute top-60 left-1/3 text-yellow-200 text-xs animate-twinkle">⭐</div>
        </div>

        <div className="relative z-10 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => navigateTo('cognitive-test')}
              className="p-2.5 rounded-xl bg-white/10 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">Alien Math Shooter</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🛸
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Pertahanan Bumi dari Alien Matematika!
            </h2>
            <p className="text-purple-200 text-base mb-8">
              Selamatkan bumi dengan menembak UFO yang membawa soal matematika yang benar!
            </p>

            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <Target className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-purple-100">Tap UFO lalu pilih jawaban yang benar</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                    <Clock className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-purple-100">Bertahan selama 90 detik</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-red-500 rounded-full flex items-center justify-center">
                    <Volume2 className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-purple-100">Hati-hati! Nyawa terbatas!</span>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="bg-gradient-to-r from-purple-600 to-blue-700 text-white px-8 py-4 rounded-2xl font-heading text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🚀 Mulai Pertahanan!
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  if (gameState === 'completed') {
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    
    return (
      <div className="min-h-screen bg-gradient-to-b from-purple-900 via-blue-900 to-black">
        <div className="px-6 pt-14 pb-8 text-center">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="text-8xl mb-6"
          >
            {lives > 0 ? '🏆' : '💫'}
          </motion.div>
          
          <h1 className="text-white font-heading text-2xl mb-4">
            {lives > 0 ? `Bumi Selamat, ${childName}!` : `Pertahanan Berakhir, ${childName}!`}
          </h1>
          
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 mb-8">
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{correctAnswers}</div>
                <div className="text-purple-200 text-sm">UFO Dihancurkan</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{accuracy}%</div>
                <div className="text-purple-200 text-sm">Akurasi</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{currentLevel}</div>
                <div className="text-purple-200 text-sm">Level Tertinggi</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{lives}</div>
                <div className="text-purple-200 text-sm">Nyawa Tersisa</div>
              </div>
            </div>

            <div className="text-left space-y-2 mb-4">
              <h4 className="text-white font-heading text-base mb-2">Analisis Kemampuan:</h4>
              <div className="text-purple-200 text-sm">
                • Logika & Matematika: {Math.round((accuracy / 100) * 25)}/25
              </div>
              <div className="text-purple-200 text-sm">
                • Perhatian & Fokus: {Math.round((hits / Math.max(hits + misses, 1)) * 25)}/25
              </div>
              <div className="text-purple-200 text-sm">
                • Kemampuan Adaptasi: {Math.round((currentLevel / 4) * 25)}/25
              </div>
              <div className="text-purple-200 text-sm">
                • Waktu Bertahan: {totalTime} detik
              </div>
            </div>

            {accuracy >= 90 && (
              <div className="bg-green-500/20 border border-green-400/30 rounded-xl p-4 mb-4">
                <div className="text-green-100 font-medium">🌟 Excellent! Kamu pahlawan matematika sejati!</div>
              </div>
            )}
            
            {accuracy >= 70 && accuracy < 90 && (
              <div className="bg-blue-500/20 border border-blue-400/30 rounded-xl p-4 mb-4">
                <div className="text-blue-100 font-medium">👍 Good! Terus latih kemampuan matematikamu!</div>
              </div>
            )}
            
            {accuracy < 70 && (
              <div className="bg-purple-500/20 border border-purple-400/30 rounded-xl p-4 mb-4">
                <div className="text-purple-100 font-medium">💪 Keep practicing! Matematika akan semakin mudah!</div>
              </div>
            )}
          </div>

          <div className="space-y-3">
            <motion.button
              onClick={() => setGameState('menu')}
              className="w-full bg-gradient-to-r from-purple-600 to-blue-700 text-white py-3 px-6 rounded-xl font-medium"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              🔄 Main Lagi
            </motion.button>
            
            <motion.button
              onClick={() => navigateTo('progress')}
              className="w-full bg-white/10 text-white py-3 px-6 rounded-xl font-medium"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              📊 Lihat Progress Dashboard
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  // Playing state
  return (
    <div className="min-h-screen bg-gradient-to-b from-purple-900 via-blue-900 to-black relative overflow-hidden" ref={gameAreaRef}>
      {/* Space background */}
      <div className="absolute inset-0">
        <div className="absolute top-16 left-8 text-yellow-300 text-xs animate-twinkle">⭐</div>
        <div className="absolute top-32 right-6 text-yellow-200 text-xs animate-twinkle">✨</div>
        <div className="absolute top-52 left-4 text-white text-xs animate-twinkle">⭐</div>
        <div className="absolute top-40 right-16 text-yellow-400 text-xs animate-twinkle">✨</div>
        <div className="absolute bottom-40 left-10 text-yellow-300 text-xs animate-twinkle">⭐</div>
        <div className="absolute bottom-60 right-4 text-white text-xs animate-twinkle">✨</div>
      </div>

      {/* Game HUD */}
      <div className="relative z-20 px-6 pt-14 pb-4">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('cognitive-test')}
            className="p-2 rounded-xl bg-white/10 backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-4 h-4 text-white" />
          </motion.button>
          <div className="flex items-center space-x-3">
            <div className="text-white font-heading text-xs">HIT: {hits}</div>
            <div className="text-purple-200 font-heading text-xs">MISS: {misses}</div>
            <div className="text-blue-200 font-heading text-xs">❤️ {lives}</div>
          </div>
          <div className="flex items-center space-x-2">
            <Clock className="w-4 h-4 text-white" />
            <span className="text-white font-heading">{timeLeft}s</span>
          </div>
        </div>

        <div className="text-center mb-4">
          <div className="text-purple-200 text-sm">Level {currentLevel} • Skor: {score}</div>
        </div>
      </div>

      {/* Aliens */}
      <div className="relative px-6">
        {aliens.map((alien) => (
          <motion.div
            key={alien.id}
            className="absolute"
            style={{ left: alien.x, top: alien.y }}
            initial={{ scale: 0 }}
            animate={{ scale: alien.destroyed ? 0 : 1 }}
            exit={{ scale: 0 }}
          >
            <div
              onClick={() => {
                if (!selectedAlien && gameState === 'playing') {
                  setSelectedAlien(alien.id);
                  setIsPaused(true);
                  setTotalQuestions(prev => prev + 1);
                }
              }}
              className={`relative cursor-pointer transform hover:scale-110 transition-all ${
                selectedAlien === alien.id ? 'scale-125 z-30' : 'z-10'
              }`}
            >
              {/* UFO - Problem is NOT shown until clicked */}
              <div className="text-6xl mb-2">🛸</div>
            </div>

            {/* Answer options - Fixed position at bottom */}
            {selectedAlien === alien.id && (
              <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="bg-white rounded-2xl p-6 border-4 border-cyan-400 shadow-2xl max-w-sm w-full"
                >
                  <div className="text-center mb-6">
                    <div className="text-6xl mb-3">🛸</div>
                    <div className="text-gray-900 font-heading font-bold text-2xl mb-2">{alien.problem}</div>
                    <div className="text-cyan-600 font-medium">Pilih jawaban yang benar!</div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 mb-4">
                    {alien.options.map((option, index) => (
                      <motion.button
                        key={index}
                        onClick={() => {
                          if (selectedAlien === alien.id && gameState === 'playing') {
                            shootAlien(alien.id, option);
                          }
                        }}
                        className="bg-gradient-to-r from-cyan-500 to-blue-600 text-white py-4 px-4 rounded-xl font-bold text-xl shadow-lg hover:from-cyan-600 hover:to-blue-700 border-3 border-white min-h-[60px] flex items-center justify-center"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        {option}
                      </motion.button>
                    ))}
                  </div>
                  
                  <motion.button
                    onClick={() => {
                      if (gameState === 'playing') {
                        setSelectedAlien(null);
                        setIsPaused(false);
                      }
                    }}
                    className="w-full bg-gray-500 text-white py-3 px-4 rounded-xl font-medium"
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    Batal
                  </motion.button>
                </motion.div>
              </div>
            )}
          </motion.div>
        ))}
      </div>

      {/* Earth defender cannon */}
      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2">
        <div className="text-6xl">🚀</div>
      </div>

      {/* Instruction */}
      <div className="absolute bottom-20 left-1/2 transform -translate-x-1/2">
        <div className="bg-white rounded-2xl px-5 py-3 border-2 border-cyan-400 shadow-lg">
          <div className="text-gray-900 font-heading font-bold text-base text-center">
            Tap UFO untuk menembak!
          </div>
        </div>
      </div>
    </div>
  );
}