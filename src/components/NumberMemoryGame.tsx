import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Star, Clock, Brain, Eye, EyeOff } from 'lucide-react';

interface NumberMemoryGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

export default function NumberMemoryGame({ 
  navigateTo, 
  addSticker, 
  childName,
  updateTestResults,
  updateGameAssessment 
}: NumberMemoryGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'showing' | 'input' | 'completed'>('menu');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [round, setRound] = useState(0);
  const [targetNumber, setTargetNumber] = useState('');
  const [userInput, setUserInput] = useState('');
  const [timeLeft, setTimeLeft] = useState(5);
  const [answerTimeLeft, setAnswerTimeLeft] = useState(10); // Timer untuk menjawab
  const [startTime, setStartTime] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [feedback, setFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [lives, setLives] = useState(3);

  // Sound effects
  const playSound = (frequency: number, duration: number, type: 'success' | 'error' | 'tick' = 'tick') => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      if (type === 'success') {
        oscillator.frequency.setValueAtTime(523, audioContext.currentTime);
        oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1);
      } else if (type === 'error') {
        oscillator.frequency.value = 200;
        oscillator.type = 'sawtooth';
      } else {
        oscillator.frequency.value = frequency;
      }
      
      gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + duration);
    } catch (e) {
      console.log('Audio not available');
    }
  };

  useEffect(() => {
    if (gameState === 'showing' && timeLeft > 0) {
      const timer = setTimeout(() => {
        setTimeLeft(timeLeft - 1);
        playSound(800, 0.1);
      }, 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && gameState === 'showing') {
      setGameState('input');
    }
  }, [timeLeft, gameState]);

  useEffect(() => {
    if (gameState === 'input' && answerTimeLeft > 0) {
      const timer = setTimeout(() => {
        setAnswerTimeLeft(answerTimeLeft - 1);
      }, 1000);
      return () => clearTimeout(timer);
    } else if (answerTimeLeft === 0 && gameState === 'input') {
      checkAnswer(userInput);
    }
  }, [answerTimeLeft, gameState]);

  const startGame = () => {
    setScore(0);
    setCorrectAnswers(0);
    setWrongAnswers(0);
    setRound(1);
    setCurrentLevel(1);
    setLives(3);
    setStartTime(Date.now());
    setGameSessionData([]);
    generateNumber(3); // Start with 3 digits
  };

  const generateNumber = (digits: number) => {
    let number = '';
    for (let i = 0; i < digits; i++) {
      number += Math.floor(Math.random() * 10);
    }
    setTargetNumber(number);
    setUserInput('');
    
    // Calculate show time based on level (increases 1 second every 3 levels)
    const showTime = 6 + Math.floor(currentLevel / 3);
    setTimeLeft(showTime);
    
    setAnswerTimeLeft(10); // Reset answer time
    setGameState('showing');
    setFeedback(null);
  };

  const handleNumberInput = (digit: string) => {
    if (userInput.length < targetNumber.length) {
      const newInput = userInput + digit;
      setUserInput(newInput);
      playSound(440, 0.1);
      
      // Auto-submit when complete
      if (newInput.length === targetNumber.length) {
        setTimeout(() => checkAnswer(newInput), 300);
      }
    }
  };

  const handleBackspace = () => {
    setUserInput(prev => prev.slice(0, -1));
    playSound(330, 0.1);
  };

  const checkAnswer = (input: string) => {
    // Check if timeout
    const isCorrect = input === targetNumber && input.length === targetNumber.length;
    setFeedback(isCorrect ? 'correct' : 'wrong');

    if (isCorrect) {
      const points = targetNumber.length * 15;
      setScore(prev => prev + points);
      setCorrectAnswers(prev => prev + 1);
      playSound(523, 0.5, 'success');
      addSticker('number-genius');
    } else {
      setWrongAnswers(prev => prev + 1);
      playSound(200, 0.5, 'error');
      setLives(prev => prev - 1);
    }

    // Save session data
    setGameSessionData(prev => [...prev, {
      digitCount: targetNumber.length,
      targetNumber: targetNumber,
      userAnswer: input,
      isCorrect: isCorrect,
      timeSpent: Date.now() - startTime,
      level: currentLevel,
      round: round
    }]);

    setTimeout(() => {
      if (lives <= 1 && !isCorrect) {
        endGame();
      } else {
        const newRound = round + 1;
        setRound(newRound);

        // Level up every 3 rounds
        if (newRound % 3 === 0) {
          setCurrentLevel(prev => prev + 1);
        }

        // Calculate digits based on level
        // Level 3: 3 digits, Level 6: 5 digits, Level 9: 7 digits, Level 12: 9 digits
        let newDigits;
        if (currentLevel >= 12) {
          newDigits = 9;
        } else if (currentLevel >= 9) {
          newDigits = 7;
        } else if (currentLevel >= 6) {
          newDigits = 5;
        } else if (currentLevel >= 3) {
          newDigits = 3;
        } else {
          newDigits = 3; // Default
        }
        
        generateNumber(newDigits);
      }
    }, 2000);
  };

  const endGame = () => {
    setGameState('completed');
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    const totalQuestions = correctAnswers + wrongAnswers;
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    
    updateTestResults('cognitive', {
      score: correctAnswers,
      total: totalQuestions,
      percentage: accuracy,
      timeSpent: totalTime,
      gameMode: 'Number Memory',
      level: currentLevel,
      categoryScores: {
        memory: Math.round((accuracy / 100) * 40),
        concentration: Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 35),
        processing: Math.round((currentLevel / 5) * 25)
      }
    });

    if (updateGameAssessment) {
      updateGameAssessment('numberMemoryGame', {
        score: score,
        timeSpent: totalTime,
        errors: wrongAnswers,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Kognitif'
      });
    }

    if (accuracy >= 80) addSticker('memory-expert');
    if (correctAnswers >= 8) addSticker('digit-master');
    addSticker('number-memory-complete');
  };

  // Menu Screen
  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-cyan-400 via-blue-400 to-indigo-500 relative overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute top-20 left-10 text-5xl animate-float-slow">1️⃣</div>
          <div className="absolute top-32 right-16 text-4xl animate-bounce">2️⃣</div>
          <div className="absolute bottom-32 left-20 text-5xl animate-pulse">3️⃣</div>
          <div className="absolute bottom-20 right-12 text-4xl animate-twinkle">4️⃣</div>
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
            <h1 className="text-white font-heading text-xl">Number Memory</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🔢
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Ingat Angka-Angka!
            </h2>
            <p className="text-cyan-100 text-base mb-8">
              Lihat angka yang muncul, ingat baik-baik, lalu ketik ulang!
            </p>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <Eye className="w-5 h-5 text-cyan-100" />
                  <p className="text-cyan-100 text-sm">Perhatikan angka yang ditampilkan</p>
                </div>
                <div className="flex items-center space-x-3">
                  <Brain className="w-5 h-5 text-cyan-100" />
                  <p className="text-cyan-100 text-sm">Ingat baik-baik sebelum hilang</p>
                </div>
                <div className="flex items-center space-x-3">
                  <EyeOff className="w-5 h-5 text-cyan-100" />
                  <p className="text-cyan-100 text-sm">Ketik angka yang kamu ingat</p>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="w-full bg-white text-blue-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🔢 Mulai Bermain!
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  // Completion Screen
  if (gameState === 'completed') {
    const totalQuestions = correctAnswers + wrongAnswers;
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;

    return (
      <div className="min-h-screen bg-gradient-to-b from-cyan-400 via-blue-400 to-indigo-500 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Hebat Sekali!</h1>
            <p className="text-cyan-100 text-lg">
              {childName}, daya ingat angkamu luar biasa!
            </p>
          </motion.div>

          <div className="space-y-4 mb-8">
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
              <div className="flex justify-between items-center">
                <span className="font-body">Skor Total</span>
                <span className="font-heading font-bold text-2xl">{score}</span>
              </div>
            </div>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
              <div className="flex justify-between items-center">
                <span className="font-body">Akurasi</span>
                <span className="font-heading font-bold text-2xl">{accuracy}%</span>
              </div>
            </div>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
              <div className="flex justify-between items-center">
                <span className="font-body">Round Berhasil</span>
                <span className="font-heading font-bold text-2xl">{correctAnswers}</span>
              </div>
            </div>
          </div>

          <div className="space-y-3">
            <motion.button
              onClick={() => setGameState('menu')}
              className="w-full bg-white text-blue-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Main Lagi
            </motion.button>

            <motion.button
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
  return (
    <div className="min-h-screen bg-gradient-to-b from-cyan-300 via-blue-300 to-indigo-400">
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
            <div className="font-heading font-bold text-lg">Round {round}</div>
            <div className="text-white/80 text-sm">Level {currentLevel}</div>
          </div>
          <div className="text-right text-white">
            <div className="font-heading font-bold text-2xl">{score}</div>
            <div className="text-white/80 text-sm">Skor</div>
          </div>
        </div>

        {/* Lives */}
        <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-3 mb-4">
          <div className="flex justify-center gap-2">
            {[...Array(3)].map((_, i) => (
              <span key={i} className="text-2xl">
                {i < lives ? '❤️' : '🖤'}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Game Area */}
      <div className="px-6 pb-8">
        {/* Number Display / Input */}
        <motion.div
          className="bg-white rounded-3xl p-8 shadow-lg mb-8"
          animate={feedback ? { scale: [1, 1.05, 1] } : {}}
        >
          {gameState === 'showing' ? (
            <div className="text-center">
              <p className="text-gray-600 text-sm mb-4">Ingat angka ini:</p>
              <motion.div
                className="text-6xl font-bold text-blue-600 mb-4 tracking-wider"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
              >
                {targetNumber}
              </motion.div>
              <div className="flex items-center justify-center gap-2 text-gray-500">
                <Clock className="w-4 h-4" />
                <span className="text-lg font-bold">{timeLeft}s</span>
              </div>
            </div>
          ) : feedback ? (
            <div className="text-center">
              <div className="text-6xl mb-4">
                {feedback === 'correct' ? '🎉' : '💔'}
              </div>
              <p className="text-gray-900 font-heading text-2xl mb-2">
                {feedback === 'correct' ? 'Benar!' : 'Salah!'}
              </p>
              <p className="text-gray-600 text-sm mb-2">Angka yang benar:</p>
              <p className="text-blue-600 font-bold text-3xl tracking-wider">{targetNumber}</p>
            </div>
          ) : (
            <div className="text-center">
              <p className="text-gray-600 text-sm mb-4">Ketik angka yang kamu ingat:</p>
              <div className="text-5xl font-bold text-blue-600 mb-2 tracking-wider min-h-16 flex items-center justify-center">
                {userInput || '___'}
              </div>
              <p className="text-gray-500 text-xs mb-3">
                {userInput.length} / {targetNumber.length} digit
              </p>
              <div className="flex items-center justify-center gap-2 text-orange-500">
                <Clock className="w-4 h-4" />
                <span className={`text-lg font-bold ${answerTimeLeft <= 3 ? 'text-red-500 animate-pulse' : ''}`}>
                  {answerTimeLeft}s tersisa
                </span>
              </div>
            </div>
          )}
        </motion.div>

        {/* Number Pad */}
        {gameState === 'input' && !feedback && (
          <div className="grid grid-cols-3 gap-3 max-w-sm mx-auto">
            {[1, 2, 3, 4, 5, 6, 7, 8, 9, '⌫', 0, '✓'].map((num) => (
              <motion.button
                key={num}
                onClick={() => {
                  if (num === '⌫') handleBackspace();
                  else if (num === '✓') checkAnswer(userInput);
                  else handleNumberInput(String(num));
                }}
                disabled={num === '✓' && userInput.length !== targetNumber.length}
                className={`aspect-square rounded-2xl font-bold text-2xl shadow-lg ${
                  num === '⌫'
                    ? 'bg-orange-500 text-white'
                    : num === '✓'
                    ? userInput.length === targetNumber.length
                      ? 'bg-green-500 text-white'
                      : 'bg-gray-300 text-gray-500'
                    : 'bg-white text-gray-900'
                }`}
                whileTap={{ scale: 0.95 }}
              >
                {num}
              </motion.button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}