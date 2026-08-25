import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Star, Trophy, Clock, Brain } from 'lucide-react';

interface SequenceMemoryGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

export default function SequenceMemoryGame({ 
  navigateTo, 
  addSticker, 
  childName,
  updateTestResults,
  updateGameAssessment 
}: SequenceMemoryGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'playing' | 'showing' | 'input' | 'completed'>('menu');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [round, setRound] = useState(0);
  const [sequence, setSequence] = useState<number[]>([]);
  const [userSequence, setUserSequence] = useState<number[]>([]);
  const [showingIndex, setShowingIndex] = useState(-1);
  const [startTime, setStartTime] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [feedback, setFeedback] = useState<'correct' | 'wrong' | null>(null);
  const [lives, setLives] = useState(3);
  const [isProcessing, setIsProcessing] = useState(false);
  const [inputEnabled, setInputEnabled] = useState(false);

  const buttons = [
    { id: 0, color: 'bg-red-500', emoji: '🔴', sound: 261.63 },
    { id: 1, color: 'bg-blue-500', emoji: '🔵', sound: 329.63 },
    { id: 2, color: 'bg-yellow-500', emoji: '🟡', sound: 392.00 },
    { id: 3, color: 'bg-green-500', emoji: '🟢', sound: 523.25 }
  ];

  // Sound generation
  const playSound = (frequency: number, duration: number = 0.2) => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      oscillator.frequency.value = frequency;
      oscillator.type = 'sine';
      gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
      
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + duration);
    } catch (e) {
      console.log('Audio not available');
    }
  };

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setCorrectAnswers(0);
    setWrongAnswers(0);
    setRound(1);
    setCurrentLevel(1);
    setLives(3);
    setStartTime(Date.now());
    setGameSessionData([]);
    generateSequence(3);
  };

  const generateSequence = (length: number) => {
    const newSequence: number[] = [];
    for (let i = 0; i < length; i++) {
      newSequence.push(Math.floor(Math.random() * 4));
    }
    setSequence(newSequence);
    setUserSequence([]);
    setShowingIndex(-1);
    setInputEnabled(false);
    setGameState('showing');
    
    setTimeout(() => {
      showSequence(newSequence);
    }, 1000);
  };

  const showSequence = async (seq: number[]) => {
    for (let i = 0; i < seq.length; i++) {
      setShowingIndex(i);
      playSound(buttons[seq[i]].sound);
      await new Promise(resolve => setTimeout(resolve, 600));
      setShowingIndex(-1);
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    setGameState('input');
    setTimeout(() => setInputEnabled(true), 300);
  };

  const handleButtonClick = (buttonId: number) => {
    if (gameState !== 'input' || !inputEnabled || isProcessing) return;

    setIsProcessing(true);
    playSound(buttons[buttonId].sound, 0.15);
    const newUserSequence = [...userSequence, buttonId];
    setUserSequence(newUserSequence);

    if (sequence[newUserSequence.length - 1] !== buttonId) {
      setInputEnabled(false);
      handleWrongAnswer();
      return;
    }

    if (newUserSequence.length === sequence.length) {
      setInputEnabled(false);
      handleCorrectAnswer();
    } else {
      setTimeout(() => setIsProcessing(false), 250);
    }
  };

  const handleCorrectAnswer = () => {
    setFeedback('correct');
    const points = sequence.length * 10;
    setScore(prev => prev + points);
    setCorrectAnswers(prev => prev + 1);
    playSound(523, 0.4);
    addSticker('memory-master');

    setGameSessionData(prev => [...prev, {
      sequenceLength: sequence.length,
      isCorrect: true,
      timeSpent: Date.now() - startTime,
      level: currentLevel,
      round: round
    }]);

    setTimeout(() => {
      setFeedback(null);
      setIsProcessing(false);
      const newRound = round + 1;
      setRound(newRound);

      if (newRound % 3 === 0) {
        setCurrentLevel(prev => prev + 1);
        playSound(659, 0.6);
      }

      const newLength = Math.min(3 + Math.floor(newRound / 2), 8);
      generateSequence(newLength);
    }, 1500);
  };

  const handleWrongAnswer = () => {
    setFeedback('wrong');
    setWrongAnswers(prev => prev + 1);
    playSound(150, 0.4);

    setGameSessionData(prev => [...prev, {
      sequenceLength: sequence.length,
      isCorrect: false,
      timeSpent: Date.now() - startTime,
      level: currentLevel,
      round: round
    }]);

    setLives(prev => {
      const newLives = prev - 1;
      if (newLives <= 0) {
        setTimeout(() => endGame(), 1500);
      } else {
        setTimeout(() => {
          setFeedback(null);
          setIsProcessing(false);
          generateSequence(sequence.length);
        }, 1500);
      }
      return newLives;
    });
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
      gameMode: 'Sequence Memory',
      level: currentLevel,
      categoryScores: {
        memory: Math.round((accuracy / 100) * 35),
        concentration: Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 35),
        sequencing: Math.round((currentLevel / 5) * 30)
      }
    });

    if (updateGameAssessment) {
      updateGameAssessment('sequenceMemoryGame', {
        score: score,
        timeSpent: totalTime,
        errors: wrongAnswers,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Kognitif'
      });
    }

    if (accuracy >= 85) addSticker('sequence-genius');
    if (correctAnswers >= 10) addSticker('memory-champion');
    addSticker('sequence-complete');
  };

  // Menu Screen
  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-indigo-400 via-purple-400 to-pink-500 relative overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute top-20 left-10 text-4xl animate-bounce">🧠</div>
          <div className="absolute top-32 right-16 text-5xl animate-pulse">⭐</div>
          <div className="absolute bottom-32 left-20 text-4xl animate-float-slow">🎯</div>
          <div className="absolute bottom-20 right-12 text-5xl animate-twinkle">✨</div>
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
            <h1 className="text-white font-heading text-xl">Sequence Memory</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🧠
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Latih Daya Ingat!
            </h2>
            <p className="text-indigo-100 text-base mb-8">
              Perhatikan urutan warna yang muncul, lalu ulangi dengan benar!
            </p>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">1</span>
                  </div>
                  <p className="text-purple-100 text-sm">Perhatikan urutan warna yang menyala</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">2</span>
                  </div>
                  <p className="text-purple-100 text-sm">Ingat baik-baik urutannya</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <span className="text-white font-bold text-sm">3</span>
                  </div>
                  <p className="text-purple-100 text-sm">Ketuk warna dengan urutan yang sama</p>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="w-full bg-white text-purple-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🧠 Mulai Bermain!
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
      <div className="min-h-screen bg-gradient-to-b from-indigo-400 via-purple-400 to-pink-500 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Luar Biasa!</h1>
            <p className="text-purple-100 text-lg">
              {childName}, daya ingatmu sangat baik!
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

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.3 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Round Berhasil</span>
                <span className="font-heading font-bold text-2xl">{correctAnswers}</span>
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
  return (
    <div className="min-h-screen bg-gradient-to-b from-indigo-300 via-purple-300 to-pink-400">
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
        <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4 mb-4">
          <div className="flex justify-between items-center">
            <div className="flex items-center space-x-2">
              <Brain className="w-5 h-5 text-purple-200" />
              <span className="text-white font-medium">Nyawa</span>
            </div>
            <div className="flex gap-1">
              {[...Array(3)].map((_, i) => (
                <span key={i} className="text-2xl">
                  {i < lives ? '❤️' : '🖤'}
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Game Area */}
      <div className="px-6 pb-8">
        {/* Status */}
        <div className="text-center mb-8">
          <motion.div
            className="bg-white rounded-2xl p-6 shadow-lg mb-4"
            animate={feedback ? { scale: [1, 1.05, 1] } : {}}
          >
            {gameState === 'showing' && (
              <p className="text-gray-900 font-heading text-xl">
                Perhatikan Urutan...
              </p>
            )}
            {gameState === 'input' && (
              <div>
                <p className="text-gray-900 font-heading text-xl mb-2">
                  Ulangi Urutannya!
                </p>
                <p className="text-gray-600 text-sm">
                  {userSequence.length} / {sequence.length}
                </p>
              </div>
            )}
            {feedback && (
              <div className="text-center">
                <div className="text-5xl mb-2">
                  {feedback === 'correct' ? '🎉' : '💔'}
                </div>
                <p className="text-gray-900 font-heading text-xl">
                  {feedback === 'correct' ? 'Benar Sekali!' : 'Oops! Salah'}
                </p>
              </div>
            )}
          </motion.div>
        </div>

        {/* Buttons Grid */}
        <div className="grid grid-cols-2 gap-4 max-w-sm mx-auto">
          {buttons.map((button) => {
            const isShowing = sequence[showingIndex] === button.id && gameState === 'showing';
            const isDisabled = gameState !== 'input' || !inputEnabled || isProcessing;
            
            return (
              <motion.button
                key={button.id}
                onClick={() => handleButtonClick(button.id)}
                disabled={isDisabled}
                className={`aspect-square rounded-3xl ${button.color} shadow-lg flex items-center justify-center relative overflow-hidden transition-opacity ${
                  isDisabled && !isShowing ? 'opacity-50' : 'opacity-100'
                }`}
                whileTap={!isDisabled ? { scale: 0.90 } : {}}
                animate={
                  isShowing
                    ? { scale: [1, 1.15, 1] }
                    : {}
                }
                transition={{ duration: 0.3 }}
              >
                <span className="text-6xl">{button.emoji}</span>
              </motion.button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
