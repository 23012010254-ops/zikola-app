import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Timer, Trophy, Star, Heart, CheckCircle, X } from 'lucide-react';

interface MotorTestGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
}

export default function MotorTestGameScreen({ navigateTo, addSticker, childName, updateTestResults }: MotorTestGameScreenProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [score, setScore] = useState(0);
  const [timeLeft, setTimeLeft] = useState(15); // 15 seconds per question
  const [lives, setLives] = useState(3);
  const [isCompleted, setIsCompleted] = useState(false);
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [gamePhase, setGamePhase] = useState<'intro' | 'playing' | 'results'>('intro');

  const motorQuestions = [
    {
      id: 1,
      question: 'Gerakan mana yang termasuk motorik kasar?',
      image: '🏃‍♂️',
      options: ['Menulis', 'Berlari', 'Menggambar', 'Memotong'],
      correct: 1,
      explanation: 'Berlari menggunakan otot-otot besar tubuh (motorik kasar)'
    },
    {
      id: 2,
      question: 'Untuk melatih keseimbangan, aktivitas yang baik adalah:',
      image: '⚖️',
      options: ['Berjalan di garis lurus', 'Menulis huruf', 'Melipat kertas', 'Mewarnai'],
      correct: 0,
      explanation: 'Berjalan di garis lurus melatih keseimbangan tubuh'
    },
    {
      id: 3,
      question: 'Gerakan menggunting kertas melatih kemampuan:',
      image: '✂️',
      options: ['Motorik kasar', 'Motorik halus', 'Keseimbangan', 'Kecepatan'],
      correct: 1,
      explanation: 'Menggunting memerlukan koordinasi jari-jari (motorik halus)'
    },
    {
      id: 4,
      question: 'Aktivitas terbaik untuk melatih koordinasi mata-tangan:',
      image: '👁️',
      options: ['Berlari', 'Menangkap bola', 'Melompat', 'Berteriak'],
      correct: 1,
      explanation: 'Menangkap bola melatih koordinasi antara mata dan tangan'
    },
    {
      id: 5,
      question: 'Manakah yang termasuk gerakan lokomotor?',
      image: '🚶‍♂️',
      options: ['Menulis', 'Melompat', 'Mewarnai', 'Menggunting'],
      correct: 1,
      explanation: 'Melompat adalah gerakan yang memindahkan tubuh dari satu tempat ke tempat lain'
    },
    {
      id: 6,
      question: 'Untuk melatih kekuatan otot tangan, sebaiknya:',
      image: '💪',
      options: ['Meremas bola stres', 'Menonton TV', 'Tidur', 'Makan'],
      correct: 0,
      explanation: 'Meremas bola stres dapat memperkuat otot-otot tangan'
    },
    {
      id: 7,
      question: 'Gerakan yang melatih fleksibilitas adalah:',
      image: '🤸‍♀️',
      options: ['Lari cepat', 'Stretching', 'Angkat beban', 'Berteriak'],
      correct: 1,
      explanation: 'Stretching atau peregangan melatih fleksibilitas otot'
    },
    {
      id: 8,
      question: 'Keterampilan motorik halus penting untuk:',
      image: '✏️',
      options: ['Berlari marathon', 'Menulis dan menggambar', 'Bermain sepakbola', 'Berenang'],
      correct: 1,
      explanation: 'Menulis dan menggambar memerlukan kontrol otot-otot kecil di jari'
    },
    {
      id: 9,
      question: 'Permainan yang baik untuk melatih kelincahan:',
      image: '🏃‍♀️',
      options: ['Puzzle', 'Ular tangga', 'Lompat tali', 'Menggambar'],
      correct: 2,
      explanation: 'Lompat tali melatih kelincahan, koordinasi, dan timing'
    },
    {
      id: 10,
      question: 'Yang TIDAK termasuk komponen kebugaran jasmani:',
      image: '❌',
      options: ['Kekuatan', 'Kelincahan', 'Kecerdasan', 'Keseimbangan'],
      correct: 2,
      explanation: 'Kecerdasan bukan komponen kebugaran jasmani fisik'
    }
  ];

  // Timer countdown
  useEffect(() => {
    if (gamePhase === 'playing' && timeLeft > 0 && !showFeedback) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && !showFeedback) {
      // Time's up - treat as wrong answer
      handleAnswer(-1);
    }
  }, [timeLeft, showFeedback, gamePhase]);

  const startGame = () => {
    setGamePhase('playing');
    setCurrentQuestion(0);
    setScore(0);
    setLives(3);
    setTimeLeft(15);
  };

  const handleAnswer = (selectedIndex: number) => {
    const currentQ = motorQuestions[currentQuestion];
    const correct = selectedIndex === currentQ.correct;
    
    setIsCorrect(correct);
    setShowFeedback(true);

    if (correct) {
      setScore(score + 1);
    } else {
      setLives(lives - 1);
    }

    setTimeout(() => {
      setShowFeedback(false);
      
      if (currentQuestion + 1 >= motorQuestions.length || lives <= 1) {
        completeGame();
      } else {
        setCurrentQuestion(currentQuestion + 1);
        setTimeLeft(15); // Reset timer for next question
      }
    }, 2500);
  };

  const completeGame = () => {
    setGamePhase('results');
    
    // Award stickers based on performance
    const percentage = (score / motorQuestions.length) * 100;
    if (percentage >= 80) {
      addSticker('motor-master');
    } else if (percentage >= 60) {
      addSticker('motor-star');
    } else {
      addSticker('motor-participant');
    }

    // Save test results
    updateTestResults('motor', {
      score: score,
      total: motorQuestions.length,
      percentage: Math.round(percentage),
      timeSpent: (motorQuestions.length * 15) - (timeLeft), // Approximate time spent
      livesRemaining: lives
    });
  };

  const getScoreMessage = () => {
    const percentage = (score / motorQuestions.length) * 100;
    if (percentage >= 80) return { message: '🏆 Luar Biasa! Kamu Motor Master!', color: 'text-yellow-600' };
    if (percentage >= 60) return { message: '⭐ Bagus Sekali! Kamu Motor Star!', color: 'text-blue-600' };
    if (percentage >= 40) return { message: '👍 Lumayan! Terus belajar ya!', color: 'text-green-600' };
    return { message: '💪 Semangat! Coba lagi besok!', color: 'text-purple-600' };
  };

  // Intro Screen
  if (gamePhase === 'intro') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-500 via-pink-500 to-orange-500 relative overflow-hidden">
        {/* Animated background elements */}
        <motion.div
          className="absolute top-20 left-10 w-20 h-20 bg-white/20 rounded-full"
          animate={{
            scale: [1, 1.2, 1],
            rotate: [0, 180, 360]
          }}
          transition={{ duration: 8, repeat: Infinity }}
        />
        <motion.div
          className="absolute top-40 right-8 w-16 h-16 bg-yellow-300/30 rounded-full"
          animate={{
            y: [0, -20, 0],
            x: [0, 10, 0]
          }}
          transition={{ duration: 6, repeat: Infinity }}
        />
        <motion.div
          className="absolute bottom-32 left-6 w-24 h-24 bg-blue-300/20 rounded-full"
          animate={{
            scale: [1, 1.1, 1],
            opacity: [0.3, 0.6, 0.3]
          }}
          transition={{ duration: 4, repeat: Infinity }}
        />

        <div className="flex flex-col items-center justify-center min-h-screen p-6 text-white relative z-10">
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ type: "spring", stiffness: 150, damping: 12 }}
            className="text-8xl mb-6 relative"
          >
            🏃‍♂️
            <motion.div
              className="absolute -top-2 -right-2 text-2xl"
              animate={{
                rotate: [0, 20, -20, 0],
                scale: [1, 1.2, 1]
              }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              ⚡
            </motion.div>
          </motion.div>
          
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-3xl font-heading font-bold text-center mb-4 drop-shadow-lg"
          >
            Motor Challenge!
          </motion.h1>
          
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-lg font-body text-center mb-8 text-white/90"
          >
            Tes pengetahuan tentang gerakan dan koordinasi tubuh!
          </motion.p>

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.4 }}
            className="bg-white/15 backdrop-blur-sm rounded-3xl p-6 mb-8 text-center shadow-xl border border-white/20"
          >
            <h3 className="font-heading font-bold text-lg mb-4 text-yellow-200">Aturan Permainan:</h3>
            <div className="space-y-3 text-sm font-body">
              <motion.div 
                className="flex items-center justify-center space-x-2 bg-white/10 rounded-2xl p-3"
                whileHover={{ scale: 1.05 }}
              >
                <Timer className="w-5 h-5 text-blue-300" />
                <span>15 detik per pertanyaan</span>
              </motion.div>
              <motion.div 
                className="flex items-center justify-center space-x-2 bg-white/10 rounded-2xl p-3"
                whileHover={{ scale: 1.05 }}
              >
                <Heart className="w-5 h-5 text-red-300" />
                <span>3 nyawa (salah 3x = game over)</span>
              </motion.div>
              <motion.div 
                className="flex items-center justify-center space-x-2 bg-white/10 rounded-2xl p-3"
                whileHover={{ scale: 1.05 }}
              >
                <Trophy className="w-5 h-5 text-yellow-300" />
                <span>10 pertanyaan tentang motorik</span>
              </motion.div>
            </div>
          </motion.div>

          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            onClick={startGame}
            className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white px-8 py-4 rounded-3xl font-heading font-bold text-lg shadow-2xl border-2 border-white/30"
            whileHover={{ scale: 1.05, boxShadow: "0 20px 40px rgba(0,0,0,0.3)" }}
            whileTap={{ scale: 0.95 }}
          >
            🚀 Mulai Permainan!
          </motion.button>

          <motion.button
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
            onClick={() => navigateTo('game')}
            className="mt-4 text-white/80 font-body underline hover:text-white transition-colors"
            whileHover={{ scale: 1.05 }}
          >
            ← Kembali ke Game Center
          </motion.button>
        </div>
      </div>
    );
  }

  // Results Screen
  if (gamePhase === 'results') {
    const { message, color } = getScoreMessage();
    const percentage = (score / motorQuestions.length) * 100;
    
    return (
      <div className="min-h-screen bg-gradient-to-br from-emerald-400 via-teal-500 to-cyan-600 relative overflow-hidden">
        {/* Celebration particles */}
        {[...Array(12)].map((_, i) => (
          <motion.div
            key={`particle-${i}`}
            className="absolute w-3 h-3 rounded-full"
            style={{
              background: i % 4 === 0 ? '#F59E0B' : i % 4 === 1 ? '#EF4444' : i % 4 === 2 ? '#8B5CF6' : '#10B981',
              left: `${10 + i * 7}%`,
              top: `${20 + i * 5}%`,
            }}
            animate={{
              y: [-20, -60, -20],
              x: [0, Math.sin(i) * 20, 0],
              rotate: [0, 360, 720],
              scale: [0.5, 1.2, 0.5]
            }}
            transition={{
              duration: 3 + i * 0.2,
              repeat: Infinity,
              delay: i * 0.1,
            }}
          />
        ))}

        <div className="flex flex-col items-center justify-center min-h-screen p-6 text-white relative z-10">
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ type: "spring", stiffness: 120, delay: 0.2 }}
            className="text-8xl mb-6 relative"
          >
            🏆
            <motion.div
              className="absolute -top-4 -right-4 text-3xl"
              animate={{
                rotate: [0, 15, -15, 0],
                scale: [1, 1.3, 1]
              }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              ✨
            </motion.div>
          </motion.div>
          
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-3xl font-heading font-bold text-center mb-4 drop-shadow-lg"
          >
            Permainan Selesai!
          </motion.h1>
          
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.3, type: "spring", stiffness: 100 }}
            className="bg-white/95 backdrop-blur-sm rounded-3xl p-8 shadow-2xl text-center mb-6 border border-white/20"
          >
            <motion.div 
              className="text-6xl font-heading font-bold mb-2"
              style={{ 
                background: percentage >= 80 ? 'linear-gradient(45deg, #F59E0B, #EAB308)' : 
                           percentage >= 60 ? 'linear-gradient(45deg, #3B82F6, #1D4ED8)' : 
                           'linear-gradient(45deg, #10B981, #059669)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent'
              }}
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.5, type: "spring", stiffness: 150 }}
            >
              {score}/{motorQuestions.length}
            </motion.div>
            <div className="text-lg font-body text-gray-600 mb-4">
              Skor: {percentage.toFixed(0)}%
            </div>
            <motion.div 
              className={`text-xl font-heading font-bold mb-4`}
              style={{ color: percentage >= 80 ? '#F59E0B' : percentage >= 60 ? '#3B82F6' : '#10B981' }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.7 }}
            >
              {message}
            </motion.div>
            
            {/* Animated Progress Bar */}
            <div className="w-full bg-gray-200 rounded-full h-6 mb-4 overflow-hidden shadow-inner">
              <motion.div
                className="h-6 rounded-full relative"
                style={{
                  background: percentage >= 80 ? 'linear-gradient(90deg, #F59E0B, #EAB308)' : 
                             percentage >= 60 ? 'linear-gradient(90deg, #3B82F6, #1D4ED8)' : 
                             'linear-gradient(90deg, #10B981, #059669)'
                }}
                initial={{ width: 0 }}
                animate={{ width: `${percentage}%` }}
                transition={{ duration: 1.5, delay: 0.8, ease: "easeOut" }}
              >
                <motion.div
                  className="absolute inset-0 rounded-full"
                  style={{
                    background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)'
                  }}
                  animate={{ x: ['-100%', '100%'] }}
                  transition={{ duration: 2, repeat: Infinity, delay: 2 }}
                />
              </motion.div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1 }}
            className="flex space-x-4"
          >
            <motion.button
              onClick={startGame}
              className="bg-white/90 text-teal-600 px-6 py-3 rounded-2xl font-heading font-bold shadow-lg backdrop-blur-sm border border-white/30"
              whileHover={{ scale: 1.05, backgroundColor: 'rgba(255,255,255,1)' }}
              whileTap={{ scale: 0.95 }}
            >
              🔄 Main Lagi
            </motion.button>
            <motion.button
              onClick={() => navigateTo('game')}
              className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-2xl font-heading font-bold shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🎮 Game Lain
            </motion.button>
          </motion.div>

          <motion.button
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.2 }}
            onClick={() => navigateTo('home')}
            className="mt-4 text-white/80 font-body underline hover:text-white transition-colors"
            whileHover={{ scale: 1.05 }}
          >
            🏠 Kembali ke Home
          </motion.button>
        </div>
      </div>
    );
  }

  // Playing Screen
  const currentQ = motorQuestions[currentQuestion];
  const progress = ((currentQuestion + 1) / motorQuestions.length) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-500 via-purple-600 to-pink-500 relative overflow-hidden">
      {/* Dynamic background elements */}
      <motion.div
        className="absolute top-10 right-10 w-32 h-32 bg-white/10 rounded-full"
        animate={{
          scale: [1, 1.2, 1],
          rotate: [0, 180, 360]
        }}
        transition={{ duration: 10, repeat: Infinity }}
      />
      <motion.div
        className="absolute bottom-20 left-8 w-24 h-24 bg-yellow-300/20 rounded-full"
        animate={{
          y: [0, -20, 0],
          x: [0, 15, 0]
        }}
        transition={{ duration: 8, repeat: Infinity }}
      />

      {/* Header */}
      <div className="bg-white/15 backdrop-blur-md px-6 pt-14 pb-6 border-b border-white/20">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-3 rounded-xl bg-white/20 backdrop-blur-sm shadow-lg border border-white/30"
            whileTap={{ scale: 0.95 }}
            whileHover={{ scale: 1.05, backgroundColor: 'rgba(255,255,255,0.3)' }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          
          <motion.div 
            className="text-center"
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <h1 className="text-white font-heading font-bold text-lg drop-shadow-lg">
              Motor Challenge ⚡
            </h1>
            <div className="text-white/90 text-sm font-body bg-white/10 rounded-full px-3 py-1 mt-1">
              Soal {currentQuestion + 1} dari {motorQuestions.length}
            </div>
          </motion.div>
          
          <div className="flex items-center space-x-1 bg-white/10 rounded-2xl p-2 backdrop-blur-sm">
            {Array.from({ length: 3 }, (_, i) => (
              <motion.div
                key={i}
                className={`w-6 h-6 rounded-full flex items-center justify-center ${
                  i < lives ? 'text-red-400' : 'text-gray-400'
                }`}
                animate={i < lives ? { scale: [1, 1.2, 1] } : {}}
                transition={{ duration: 1, repeat: Infinity }}
              >
                <Heart className="w-5 h-5" fill={i < lives ? "currentColor" : "none"} />
              </motion.div>
            ))}
          </div>
        </div>

        {/* Timer and Progress */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-2">
            <Timer className="w-4 h-4 text-white" />
            <span className={`text-white font-heading font-bold ${timeLeft <= 5 ? 'text-red-300' : ''}`}>
              {timeLeft}s
            </span>
          </div>
          <div className="text-white font-heading font-bold">
            Skor: {score}
          </div>
        </div>

        {/* Progress Bar */}
        <div className="w-full bg-white/20 rounded-full h-2">
          <motion.div
            className="bg-white h-2 rounded-full"
            initial={{ width: 0 }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </div>

      <div className="p-6">
        {/* Question Card */}
        <motion.div
          key={currentQ.id}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          className="bg-white rounded-3xl p-6 shadow-xl mb-6"
        >
          <div className="text-center mb-6">
            <div className="text-6xl mb-4">{currentQ.image}</div>
            <h2 className="text-xl font-heading font-bold text-gray-900 leading-tight">
              {currentQ.question}
            </h2>
          </div>

          {/* Timer Bar */}
          <div className="w-full bg-gray-200 rounded-full h-2 mb-6">
            <motion.div
              className={`h-2 rounded-full ${
                timeLeft > 10 ? 'bg-green-500' : 
                timeLeft > 5 ? 'bg-yellow-500' : 'bg-red-500'
              }`}
              initial={{ width: '100%' }}
              animate={{ width: `${(timeLeft / 15) * 100}%` }}
              transition={{ duration: 0.1 }}
            />
          </div>

          {/* Answer Options */}
          <div className="space-y-3">
            {currentQ.options.map((option, index) => (
              <motion.button
                key={index}
                onClick={() => !showFeedback && handleAnswer(index)}
                className={`w-full p-4 text-left rounded-2xl border-2 transition-all font-body font-medium ${
                  showFeedback
                    ? index === currentQ.correct
                      ? 'bg-green-100 border-green-500 text-green-800'
                      : 'bg-gray-100 border-gray-300 text-gray-600'
                    : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-blue-50 hover:border-blue-300'
                }`}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                whileHover={!showFeedback ? { scale: 1.02 } : {}}
                whileTap={!showFeedback ? { scale: 0.98 } : {}}
                disabled={showFeedback}
              >
                <div className="flex items-center space-x-3">
                  <div className={`w-8 h-8 rounded-full border-2 flex items-center justify-center font-bold ${
                    showFeedback && index === currentQ.correct
                      ? 'border-green-500 bg-green-500 text-white'
                      : 'border-gray-400 text-gray-600'
                  }`}>
                    {showFeedback && index === currentQ.correct ? (
                      <CheckCircle className="w-5 h-5" />
                    ) : (
                      String.fromCharCode(65 + index)
                    )}
                  </div>
                  <span>{option}</span>
                </div>
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* Feedback */}
        {showFeedback && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className={`rounded-2xl p-6 text-center ${
              isCorrect
                ? 'bg-green-100 text-green-800'
                : 'bg-red-100 text-red-800'
            }`}
          >
            <div className="text-4xl mb-3">
              {isCorrect ? '🎉' : '😅'}
            </div>
            <div className="font-heading font-bold text-lg mb-2">
              {isCorrect ? 'Benar!' : 'Kurang Tepat!'}
            </div>
            <div className="font-body text-sm leading-relaxed">
              {currentQ.explanation}
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
}