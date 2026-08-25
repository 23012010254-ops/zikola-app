import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Heart, Star, Trophy } from 'lucide-react';

interface DesertRoadLogicGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

interface RoadProblem {
  id: number;
  problem: string;
  correctAnswer: string;
  options: [string, string, string]; // 3 road options
  type: 'logic' | 'pattern' | 'sequence' | 'abstract';
  level: number;
}

export default function DesertRoadLogicGame({ 
  navigateTo, 
  addSticker, 
  childName, 
  updateTestResults, 
  updateGameAssessment 
}: DesertRoadLogicGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'playing' | 'animating' | 'completed'>('menu');
  const [currentProblem, setCurrentProblem] = useState<RoadProblem | null>(null);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [currentLevel, setCurrentLevel] = useState(1);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [startTime, setStartTime] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [carPosition, setCarPosition] = useState(1); // 0=left, 1=center, 2=right
  const [isMoving, setIsMoving] = useState(false);
  const [showResult, setShowResult] = useState<'correct' | 'wrong' | null>(null);
  const [selectedRoad, setSelectedRoad] = useState<number | null>(null);

  // Logic problems for the game
  const generateLogicProblem = (level: number): RoadProblem => {
    const problems = [
      // Level 1: Fun Animal Logic
      [
        {
          problem: "🐸 Kodok melompat di air. 🐰 Kelinci melompat di darat. 🐧 Penguin berenang di...",
          correct: "🌊 Air",
          options: ["🌳 Pohon", "🌊 Air", "☁️ Awan"],
          type: 'logic' as const
        },
        {
          problem: "🦁 Raja hutan adalah singa. 🐙 Raja laut adalah...",
          correct: "🐋 Paus",
          options: ["🐋 Paus", "🐱 Kucing", "🐶 Anjing"],
          type: 'logic' as const
        },
        {
          problem: "🌙 Malam hari bulan bersinar. ☀️ Siang hari ... bersinar.",
          correct: "☀️ Matahari",
          options: ["🌈 Pelangi", "⭐ Bintang", "☀️ Matahari"],
          type: 'logic' as const
        },
        {
          problem: "🍎 Apel tumbuh di pohon. 🥕 Wortel tumbuh di...",
          correct: "🌱 Tanah",
          options: ["�� Udara", "🌱 Tanah", "💧 Air"],
          type: 'logic' as const
        },
        {
          problem: "🚗 Mobil jalan di darat. ✈️ Pesawat terbang di...",
          correct: "☁️ Udara",
          options: ["🌱 Tanah", "☁️ Udara", "🌊 Air"],
          type: 'logic' as const
        }
      ],
      
      // Level 2: Fun Pattern Adventures
      [
        {
          problem: "🌈 Pelangi: 🔴🟡🟢🔵🟣 ... apa selanjutnya?",
          correct: "🔴",
          options: ["⚪", "🔴", "⚫"],
          type: 'pattern' as const
        },
        {
          problem: "🚦 Lampu lalu lintas: Merah-Kuning-Hijau-? apa selanjutnya?",
          correct: "Merah",
          options: ["Ungu", "Biru", "Merah"],
          type: 'pattern' as const
        },
        {
          problem: "🏠🏢🏠🏢🏠? Bangunan apa selanjutnya?",
          correct: "🏢",
          options: ["🏠", "🏰", "🏢"],
          type: 'pattern' as const
        },
        {
          problem: "⚽🏀⚽🏀⚽? Bola apa selanjutnya?",
          correct: "🏀",
          options: ["🏀", "🎾", "⚽"],
          type: 'pattern' as const
        },
        {
          problem: "1️⃣3️⃣5️⃣7️⃣? Angka apa selanjutnya?",
          correct: "9️⃣",
          options: ["6️⃣", "9️⃣", "8️⃣"],
          type: 'pattern' as const
        }
      ],
      
      // Level 3: Magic Math & Logic
      [
        {
          problem: "🏰 Kastil punya 4 menara. 2 kastil punya berapa menara?",
          correct: "8",
          options: ["6", "10", "8"],
          type: 'abstract' as const
        },
        {
          problem: "🍪 + 🍪 + 🍪 = 🎂. Jika 🍪 = 3, maka 🎂 = ?",
          correct: "9",
          options: ["9", "12", "6"],
          type: 'abstract' as const
        },
        {
          problem: "🐾 Jejak: 🐕 punya 4, 🐱 punya 4, 🐣 punya berapa?",
          correct: "2",
          options: ["4", "2", "6"],
          type: 'abstract' as const
        },
        {
          problem: "🌟 Bintang: Jika 🌟🌟 = 10, maka 🌟🌟🌟 = ?",
          correct: "15",
          options: ["12", "15", "20"],
          type: 'abstract' as const
        },
        {
          problem: "🚗 Roda: Mobil 4, Motor 2, Sepeda berapa?",
          correct: "2",
          options: ["3", "1", "2"],
          type: 'abstract' as const
        }
      ],
      
      // Level 4: Detective Logic Mysteries
      [
        {
          problem: "🏆 Lomba: Ana juara 1, Beni juara 2, Cici juara 3. Siapa tercepat?",
          correct: "Ana",
          options: ["Beni", "Ana", "Cici"],
          type: 'sequence' as const
        },
        {
          problem: "🍰 Kue: Ibu buat 12 kue, dimakan 5, sisanya dibagi 7 anak. Berapa per anak?",
          correct: "1",
          options: ["2", "3", "1"],
          type: 'sequence' as const
        },
        {
          problem: "🐾 Jejak: Kucing 4 kaki, ayam 2 kaki. 3 kucing + 2 ayam = berapa kaki?",
          correct: "16",
          options: ["16", "18", "14"],
          type: 'sequence' as const
        },
        {
          problem: "🚌 Bus: Naik 8 orang, turun 3 orang, naik 5 orang. Sekarang berapa orang?",
          correct: "10",
          options: ["13", "10", "8"],
          type: 'sequence' as const
        },
        {
          problem: "🎨 Warna: Merah + Kuning = Orange. Biru + Kuning = ?",
          correct: "Hijau",
          options: ["Ungu", "Hijau", "Orange"],
          type: 'sequence' as const
        }
      ],
      
      // Level 5: Super Brain Challenge
      [
        {
          problem: "🎯 Target: Panah 1 dapat 10 poin, panah 2 dapat 5 poin, panah 3 dapat 15 poin. Rata-rata?",
          correct: "10",
          options: ["12", "10", "15"],
          type: 'abstract' as const
        },
        {
          problem: "🔐 Kunci: Kunci A buka pintu 1, kunci B buka pintu 2. Kunci C buka pintu?",
          correct: "3",
          options: ["2", "3", "1"],
          type: 'logic' as const
        },
        {
          problem: "🍎 Buah: 1 keranjang 12 apel, dimakan 1/4. Sisanya berapa?",
          correct: "9",
          options: ["9", "10", "8"],
          type: 'abstract' as const
        },
        {
          problem: "⭐ Bintang: Jika 1 bintang = 3 poin, 3 bintang + 1 bulan (5 poin) = ?",
          correct: "14",
          options: ["15", "12", "14"],
          type: 'abstract' as const
        },
        {
          problem: "🏁 Balap: Start jam 2, finish jam 5. Lama balapan berapa jam?",
          correct: "3",
          options: ["5", "2", "3"],
          type: 'logic' as const
        }
      ]
    ];

    const problemLevel = Math.min(level, problems.length) - 1;
    const levelProblems = problems[problemLevel];
    const selectedProblem = levelProblems[Math.floor(Math.random() * levelProblems.length)];
    
    // Don't shuffle, use as is to ensure variety
    return {
      id: Date.now(),
      problem: selectedProblem.problem,
      correctAnswer: selectedProblem.correct,
      options: selectedProblem.options as [string, string, string],
      type: selectedProblem.type,
      level: level
    };
  };

  // Sound effects
  const generateGameSound = (frequency: number, duration: number, type: string) => {
    if (typeof window !== 'undefined' && window.AudioContext) {
      try {
        const audioContext = new AudioContext();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
        oscillator.type = type === 'explosion' ? 'sawtooth' : 'sine';
        
        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + duration);
      } catch (error) {
        console.warn('Audio not supported');
      }
    }
  };

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setLives(3);
    setCurrentLevel(1);
    setCorrectAnswers(0);
    setTotalQuestions(0);
    setStartTime(Date.now());
    setGameSessionData([]);
    setCarPosition(1);
    setIsMoving(false);
    setShowResult(null);
    setSelectedRoad(null);
    generateGameSound(600, 0.5, 'sine');
    generateNewProblem();
  };

  const generateNewProblem = () => {
    const problem = generateLogicProblem(currentLevel);
    setCurrentProblem(problem);
    setTotalQuestions(prev => prev + 1);
    setCarPosition(1);
    setIsMoving(false);
    setShowResult(null);
    setSelectedRoad(null);
  };

  const selectRoad = (roadIndex: number) => {
    if (isMoving || !currentProblem) return;
    
    setSelectedRoad(roadIndex);
    setIsMoving(true);
    setCarPosition(roadIndex);
    
    generateGameSound(400, 0.3, 'sine');
    
    // Animate car moving
    setTimeout(() => {
      const selectedAnswer = currentProblem.options[roadIndex];
      const isCorrect = selectedAnswer === currentProblem.correctAnswer;
      
      if (isCorrect) {
        setShowResult('correct');
        setScore(prevScore => prevScore + (15 * currentLevel));
        setCorrectAnswers(prev => {
          const newCorrectAnswers = prev + 1;
          if (newCorrectAnswers % 4 === 0 && currentLevel < 5) {
            setCurrentLevel(prevLevel => prevLevel + 1);
          }
          return newCorrectAnswers;
        });
        generateGameSound(900, 0.4, 'sine');
        addSticker('road-master');
      } else {
        setShowResult('wrong');
        setLives(prevLives => {
          const newLives = prevLives - 1;
          if (newLives <= 0) {
            setTimeout(() => endGame(), 2000);
          }
          return newLives;
        });
        generateGameSound(200, 0.4, 'explosion');
      }

      // Save session data
      setGameSessionData(prev => [...prev, {
        problem: currentProblem.problem,
        correctAnswer: currentProblem.correctAnswer,
        selectedAnswer: selectedAnswer,
        isCorrect: isCorrect,
        timeSpent: Date.now() - startTime,
        level: currentLevel,
        type: currentProblem.type
      }]);

      // Move to next problem
      setTimeout(() => {
        if (lives > 0) {
          generateNewProblem();
        }
      }, 2000);
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
      gameMode: 'Desert Road Logic',
      level: currentLevel,
      categoryScores: {
        logic: Math.round((accuracy / 100) * 30),
        abstraction: Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 30),
        reasoning: Math.round((currentLevel / 5) * 20)
      },
      detailedResults: {
        accuracy: accuracy,
        averageResponseTime: gameSessionData.length > 0 
          ? gameSessionData.reduce((sum, s) => sum + s.timeSpent, 0) / gameSessionData.length / 1000
          : 0,
        levelReached: currentLevel,
        livesRemaining: lives,
        logicProblems: gameSessionData.filter(s => s.type === 'logic').length,
        patternProblems: gameSessionData.filter(s => s.type === 'pattern').length,
        abstractProblems: gameSessionData.filter(s => s.type === 'abstract').length
      }
    });

    updateGameAssessment('desertRoadGame', {
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      accuracy: accuracy,
      timeSpent: totalTime,
      level: currentLevel,
      errors: totalQuestions - correctAnswers,
      domain: 'Kognitif'
    });

    // Award stickers
    if (accuracy >= 90) addSticker('logic-genius');
    if (accuracy >= 80) addSticker('abstract-master');
    if (currentLevel >= 4) addSticker('reasoning-expert');
    if (correctAnswers >= 15) addSticker('road-champion');
    
    addSticker('desert-survivor');
  };

  // Menu Screen
  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-amber-300 via-orange-300 to-rose-400 relative overflow-hidden">
        {/* Desert Background */}
        <div className="absolute inset-0">
          <div className="absolute bottom-0 left-0 w-full h-40 bg-gradient-to-t from-amber-400 via-orange-300 to-transparent opacity-60" />
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 60, repeat: Infinity, ease: "linear" }}
            className="absolute top-8 right-8 w-20 h-20 bg-gradient-to-br from-yellow-100 to-amber-300 rounded-full shadow-xl opacity-80"
          />
          <div className="absolute bottom-20 left-1/4 text-5xl">🌵</div>
          <div className="absolute bottom-24 right-1/3 text-4xl">🌵</div>
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
            <h1 className="text-white font-heading text-xl">Desert Road Logic</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🚗
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Petualangan Logika!
            </h2>
            <p className="text-amber-100 text-base mb-8">
              Pilih jalan yang benar untuk melanjutkan perjalanan mobilmu!
            </p>

            {/* How to Play */}
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">1</span>
                  </div>
                  <p className="text-orange-100 text-sm">Baca soal yang muncul di atas</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">2</span>
                  </div>
                  <p className="text-orange-100 text-sm">Pilih jalan dengan jawaban yang benar</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">3</span>
                  </div>
                  <p className="text-orange-100 text-sm">Mobil akan jatuh jika jawabanmu salah!</p>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="w-full bg-white text-orange-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🚗 Mulai Petualangan!
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
      <div className="min-h-screen bg-gradient-to-b from-amber-300 via-orange-300 to-rose-400 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Misi Selesai!</h1>
            <p className="text-yellow-100 text-lg">
              Hebat {childName}! Kamu berhasil menguasai logika desert!
            </p>
          </motion.div>

          <div className="space-y-4 mb-8">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
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
              transition={{ delay: 0.3 }}
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
              transition={{ delay: 0.4 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Level Tertinggi</span>
                <span className="font-heading font-bold text-2xl">{currentLevel}</span>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Waktu Bermain</span>
                <span className="font-heading font-bold text-2xl">{Math.floor(totalTime / 60)}:{(totalTime % 60).toString().padStart(2, '0')}</span>
              </div>
            </motion.div>
          </div>

          <div className="space-y-3">
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
              onClick={() => setGameState('menu')}
              className="w-full bg-white text-orange-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Main Lagi
            </motion.button>

            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7 }}
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
    return (
      <div className="min-h-screen bg-gradient-to-b from-amber-200 via-orange-200 to-rose-300 relative overflow-hidden">
        {/* Desert Background */}
        <div className="absolute inset-0">
          <div className="absolute bottom-0 left-0 w-full h-40 bg-gradient-to-t from-amber-300 via-orange-200 to-transparent opacity-60" />
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 60, repeat: Infinity, ease: "linear" }}
            className="absolute top-8 right-8 w-20 h-20 bg-gradient-to-br from-yellow-100 to-amber-300 rounded-full shadow-xl opacity-80"
          />
          <motion.div 
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 3, repeat: Infinity }}
            className="absolute bottom-20 left-1/4 text-5xl"
          >
            🌵
          </motion.div>
          <motion.div 
            animate={{ scale: [1, 1.1, 1] }}
            transition={{ duration: 4, repeat: Infinity, delay: 1 }}
            className="absolute bottom-24 right-1/3 text-4xl"
          >
            🌵
          </motion.div>
        </div>

        {/* Game UI */}
        <div className="relative z-10">
          {/* Header */}
          <div className="flex justify-between items-center px-6 pt-12 pb-4">
            <motion.button
              onClick={() => navigateTo('cognitive-test')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            
            <div className="text-white text-center">
              <div className="font-heading font-bold text-lg">Desert Road</div>
              <div className="text-white/80 text-sm">Level {currentLevel}</div>
            </div>
            
            <div className="text-right text-white">
              <div className="font-heading font-bold text-2xl">{score}</div>
              <div className="text-white/80 text-sm">Skor</div>
            </div>
          </div>

          {/* Lives */}
          <div className="px-6 mb-4">
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
              <div className="flex justify-center items-center space-x-2">
                {[...Array(3)].map((_, i) => (
                  <Heart 
                    key={i} 
                    className={`w-8 h-8 ${i < lives ? 'text-red-400 fill-red-400' : 'text-gray-400'}`} 
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Problem Display */}
          <div className="px-6 mb-8">
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl p-6 shadow-lg"
            >
              <h3 className="text-gray-900 font-heading text-lg text-center mb-2">
                Soal:
              </h3>
              <p className="text-gray-700 text-base text-center">
                {currentProblem.problem}
              </p>
            </motion.div>
          </div>

          {/* Road and Car */}
          <div className="relative h-96 px-6">
            {/* Three Roads */}
            <div className="absolute inset-x-6 top-0 h-full flex justify-between gap-2">
              {currentProblem.options.map((option, index) => (
                <motion.div
                  key={index}
                  onClick={() => !isMoving && selectRoad(index)}
                  className={`flex-1 relative cursor-pointer ${
                    isMoving && selectedRoad === index 
                      ? showResult === 'correct' 
                        ? 'bg-gradient-to-t from-emerald-400 to-green-600' 
                        : 'bg-gradient-to-t from-red-400 to-rose-600'
                      : 'bg-gradient-to-t from-amber-400 to-orange-600'
                  } rounded-b-3xl shadow-lg`}
                  whileHover={!isMoving ? { scale: 1.02 } : {}}
                  whileTap={!isMoving ? { scale: 0.98 } : {}}
                >
                  {/* Road markings */}
                  <div className="absolute inset-x-0 bottom-0 flex flex-col-reverse items-center space-y-reverse space-y-8 pb-8">
                    {[...Array(4)].map((_, i) => (
                      <div key={i} className="w-1 h-8 bg-white opacity-50 rounded-full" />
                    ))}
                  </div>
                  
                  {/* Answer on road */}
                  <div className="absolute top-8 inset-x-0 flex justify-center">
                    <div className="bg-white/90 backdrop-blur-sm px-4 py-3 rounded-xl shadow-lg">
                      <p className="text-orange-700 font-body font-bold text-center text-sm">
                        {option}
                      </p>
                    </div>
                  </div>
                  
                  {/* Hole at top if wrong */}
                  {isMoving && selectedRoad === index && showResult === 'wrong' && (
                    <motion.div
                      initial={{ opacity: 0, scale: 0 }}
                      animate={{ opacity: 1, scale: 1 }}
                      className="absolute top-0 inset-x-0 h-32 bg-black rounded-t-3xl flex items-center justify-center"
                    >
                      <span className="text-6xl">🕳️</span>
                    </motion.div>
                  )}
                </motion.div>
              ))}
            </div>

            {/* Car - starts from bottom */}
            <AnimatePresence>
              <motion.div
                className="absolute bottom-4"
                style={{
                  left: carPosition === 0 ? '12%' : carPosition === 1 ? '44%' : '76%',
                }}
                animate={{
                  y: isMoving ? -300 : 0,
                  rotate: isMoving && showResult === 'wrong' ? [0, -10, 10, -10, 10, 0] : 0,
                }}
                transition={{ 
                  duration: isMoving ? 1.5 : 0,
                  ease: 'easeInOut'
                }}
              >
                <div className="text-6xl drop-shadow-lg" style={{ transform: 'rotate(90deg)' }}>
                  🚗
                </div>
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Instruction */}
          {!isMoving && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="px-6 mt-8"
            >
              <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
                <p className="text-white text-center font-body text-sm">
                  👆 Pilih jalan dengan jawaban yang benar!
                </p>
              </div>
            </motion.div>
          )}
        </div>
      </div>
    );
  }

  return null;
}