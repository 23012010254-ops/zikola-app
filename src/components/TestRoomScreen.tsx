import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Brain, BookOpen, Star, Trophy, Lock, CheckCircle, Clock, Heart, Sparkles } from 'lucide-react';
import ChildMascot from './ChildMascot';
import MathGameScreen from './MathGameScreen';
import LinguisticGameScreen from './LinguisticGameScreen';
import StoryGameScreen from './StoryGameScreen';

interface TestRoomScreenProps {
  navigateTo: (screen: string) => void;
  isParentMode: boolean;
  addSticker: (stickerId: string) => void;
}

export default function TestRoomScreen({ navigateTo, isParentMode, addSticker }: TestRoomScreenProps) {
  const [currentPhase, setCurrentPhase] = useState<'intro' | 'cognitive' | 'linguistic' | 'talent' | 'results' | 'cognitive-test' | 'linguistic-test' | 'talent-test'>('intro');
  const [completedTests, setCompletedTests] = useState<string[]>([]);
  const [testResults, setTestResults] = useState<Record<string, number>>({});
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [currentScore, setCurrentScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);

  const testPhases = [
    {
      id: 'cognitive',
      title: isParentMode ? 'Tes Kognitif' : 'Game Matematika 🧮',
      description: isParentMode ? 'Mengukur kemampuan berpikir dan pemecahan masalah' : 'Asyik main game matematika seru!',
      icon: Brain,
      emoji: '🧮',
      color: 'from-blue-400 to-blue-600',
      duration: isParentMode ? '10 menit' : '10 menit main'
    },
    {
      id: 'linguistic',
      title: isParentMode ? 'Tes Linguistik' : 'Game Linguistik 📖',
      description: isParentMode ? 'Mengukur kemampuan bahasa dan komunikasi' : 'Seru banget bermain kata!',
      icon: BookOpen,
      emoji: '📖',
      color: 'from-purple-400 to-purple-600',
      duration: isParentMode ? '8 menit' : '8 menit main'
    },
    {
      id: 'talent',
      title: isParentMode ? 'Tes Bakat & Minat' : 'Cerita Bergambar 📚',
      description: isParentMode ? 'Mengetahui bakat alami dan area minat' : 'Animasi cerita interaktif untukmu!',
      icon: Star,
      emoji: '📚',
      color: 'from-orange-400 to-orange-600',
      duration: isParentMode ? '12 menit' : '12 menit main'
    }
  ];

  // Sample questions for each test type
  const cognitiveQuestions = [
    {
      question: isParentMode ? "Berapa hasil dari 5 + 3?" : "Hitung yuk: 5 + 3 = ?",
      options: ["6", "7", "8", "9"],
      correct: 2,
      type: "math"
    },
    {
      question: isParentMode ? "Pola selanjutnya: 🔵 🟩 🔵 ?" : "Lanjutkan polanya: 🔵 🟩 🔵 ?",
      options: ["🔵", "🟩", "🟨", "🟪"],
      correct: 1,
      type: "pattern"
    },
    {
      question: isParentMode ? "Manakah yang berbeda?" : "Mana yang tidak sama?",
      options: ["🐱", "🐶", "🐱", "🐱"],
      correct: 1,
      type: "difference"
    },
    {
      question: isParentMode ? "7 - 4 = ?" : "Kurangin yuk: 7 - 4 = ?",
      options: ["2", "3", "4", "5"],
      correct: 1,
      type: "math"
    },
    {
      question: isParentMode ? "Urutan dari kecil ke besar: 3, 1, 4, 2" : "Urutkan dari kecil: 3, 1, 4, 2",
      options: ["1,2,3,4", "4,3,2,1", "2,3,1,4", "3,4,1,2"],
      correct: 0,
      type: "sequence"
    }
  ];

  const linguisticQuestions = [
    {
      question: isParentMode ? "Mana kata yang benar?" : "Pilih kata yang benar!",
      options: ["Buku", "Bukku", "Buk", "Bukuu"],
      correct: 0,
      type: "spelling"
    },
    {
      question: isParentMode ? "Lawan kata 'besar' adalah..." : "Kebalikan kata 'besar' itu...",
      options: ["Tinggi", "Kecil", "Lebar", "Panjang"],
      correct: 1,
      type: "opposite"
    },
    {
      question: isParentMode ? "Kata mana yang sama artinya dengan 'gembira'?" : "Kata apa yang sama artinya dengan 'gembira'?",
      options: ["Sedih", "Senang", "Marah", "Takut"],
      correct: 1,
      type: "synonym"
    },
    {
      question: isParentMode ? "Suara kucing adalah..." : "Kucing bersuara...",
      options: ["Guk guk", "Meong", "Moo", "Kukuruyuk"],
      correct: 1,
      type: "sound"
    },
    {
      question: isParentMode ? "Huruf pertama dari kata 'Apel'" : "Huruf pertama dari 'Apel' itu...",
      options: ["A", "P", "E", "L"],
      correct: 0,
      type: "letter"
    }
  ];

  const talentQuestions = [
    {
      question: isParentMode ? "Aktivitas mana yang paling kamu sukai?" : "Yang paling kamu suka itu...",
      options: ["Menggambar 🎨", "Bernyanyi 🎵", "Olahraga ⚽", "Membaca 📖"],
      correct: -1, // No correct answer for preference
      type: "preference"
    },
    {
      question: isParentMode ? "Kapan kamu paling kreatif?" : "Kapan kamu paling suka berkreasi?",
      options: ["Pagi hari ☀️", "Siang hari 🌞", "Sore hari 🌅", "Malam hari 🌙"],
      correct: -1,
      type: "preference"
    },
    {
      question: isParentMode ? "Dengan siapa kamu lebih suka bermain?" : "Kamu lebih suka main dengan...",
      options: ["Sendiri 😊", "1-2 teman 👯", "Banyak teman 👥", "Keluarga 👨‍👩‍👧‍👦"],
      correct: -1,
      type: "preference"
    },
    {
      question: isParentMode ? "Warna apa yang paling mewakili perasaanmu?" : "Warna apa yang paling kamu suka?",
      options: ["Merah ❤️", "Biru 💙", "Hijau 💚", "Kuning 💛"],
      correct: -1,
      type: "preference"
    },
    {
      question: isParentMode ? "Jenis musik apa yang kamu sukai?" : "Musik apa yang bikin kamu semangat?",
      options: ["Ceria 🎉", "Tenang 😌", "Energik 🔥", "Klasik 🎼"],
      correct: -1,
      type: "preference"
    }
  ];

  const getCurrentQuestions = () => {
    switch (currentPhase) {
      case 'cognitive-test':
        return cognitiveQuestions;
      case 'linguistic-test':
        return linguisticQuestions;
      case 'talent-test':
        return talentQuestions;
      default:
        return [];
    }
  };

  const startTest = (testId: string) => {
    setCurrentPhase(`${testId}-test` as any);
    setCurrentQuestionIndex(0);
    setCurrentScore(0);
    setLives(3);
  };

  const handleAnswer = (selectedIndex: number) => {
    const questions = getCurrentQuestions();
    const currentQuestion = questions[currentQuestionIndex];
    
    // For preference questions, all answers are correct
    const correct = currentQuestion.correct === -1 || selectedIndex === currentQuestion.correct;
    
    setIsCorrect(correct);
    setShowFeedback(true);
    
    if (correct || currentQuestion.correct === -1) {
      setCurrentScore(currentScore + 1);
    } else {
      setLives(lives - 1);
    }
    
    setTimeout(() => {
      setShowFeedback(false);
      
      if (currentQuestionIndex + 1 >= questions.length) {
        // Test completed
        completeTest();
      } else if (lives <= 1 && !correct && currentQuestion.correct !== -1) {
        // Game over
        completeTest();
      } else {
        setCurrentQuestionIndex(currentQuestionIndex + 1);
      }
    }, 2000);
  };

  const completeTest = () => {
    const testType = currentPhase.replace('-test', '');
    const questions = getCurrentQuestions();
    const score = Math.round((currentScore / questions.length) * 100);
    
    setCompletedTests(prev => [...prev, testType]);
    setTestResults(prev => ({ ...prev, [testType]: score }));
    
    // Award stickers based on performance
    if (score >= 80) {
      if (testType === 'cognitive') addSticker('brain-master');
      if (testType === 'linguistic') addSticker('word-wizard');
      if (testType === 'talent') addSticker('talent-star');
    }
    
    if (completedTests.length + 1 === testPhases.length) {
      setCurrentPhase('results');
    } else {
      setCurrentPhase('intro');
    }
  };

  const getOverallScore = () => {
    const scores = Object.values(testResults);
    return scores.length > 0 ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : 0;
  };

  // Render individual test screens
  if (currentPhase === 'cognitive-test') {
    return (
      <MathGameScreen
        onBack={() => setCurrentPhase('intro')}
        onComplete={(score) => {
          setCompletedTests(prev => [...prev, 'cognitive']);
          setTestResults(prev => ({ ...prev, cognitive: score }));
          
          if (score >= 80) {
            addSticker('brain-master');
          }
          
          if (completedTests.length + 1 === testPhases.length) {
            setCurrentPhase('results');
          } else {
            setCurrentPhase('intro');
          }
        }}
        isParentMode={isParentMode}
      />
    );
  }

  if (currentPhase === 'linguistic-test') {
    return (
      <LinguisticGameScreen
        onBack={() => setCurrentPhase('intro')}
        onComplete={(score) => {
          setCompletedTests(prev => [...prev, 'linguistic']);
          setTestResults(prev => ({ ...prev, linguistic: score }));
          
          if (score >= 80) {
            addSticker('word-wizard');
          }
          
          if (completedTests.length + 1 === testPhases.length) {
            setCurrentPhase('results');
          } else {
            setCurrentPhase('intro');
          }
        }}
        isParentMode={isParentMode}
      />
    );
  }

  if (currentPhase === 'talent-test') {
    return (
      <StoryGameScreen
        onBack={() => setCurrentPhase('intro')}
        onComplete={(score) => {
          setCompletedTests(prev => [...prev, 'talent']);
          setTestResults(prev => ({ ...prev, talent: score }));
          
          if (score >= 80) {
            addSticker('talent-star');
          }
          
          if (completedTests.length + 1 === testPhases.length) {
            setCurrentPhase('results');
          } else {
            setCurrentPhase('intro');
          }
        }}
        isParentMode={isParentMode}
      />
    );
  }

  // Render intro screen
  if (currentPhase === 'intro') {
    return (
      <div className="h-screen bg-gradient-to-br from-emerald-200 to-teal-200 flex flex-col">
        {/* Header */}
        <div className="flex items-center p-6 bg-white rounded-b-3xl shadow-lg">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-3 rounded-full bg-emerald-100"
            whileTap={{ scale: 0.9 }}
          >
            <ArrowLeft className="text-emerald-600" size={24} />
          </motion.button>
          <div className="flex-1 text-center">
            <h1 className="text-2xl text-emerald-800 font-heading font-bold">
              {isParentMode ? 'Ruang Tes Pribadi' : 'Petualangan Belajar Pribadi! 🏰'}
            </h1>
            <div className="flex items-center justify-center space-x-2 mt-1">
              <Lock className="text-emerald-600" size={16} />
              <p className="text-emerald-600 text-sm font-body">
                {isParentMode ? 'Tes komprehensif & privat' : 'Petualangan khusus untukmu!'}
              </p>
            </div>
          </div>
        </div>

        {/* Welcome Message */}
        <div className="px-6 py-4">
          <motion.div
            className="bg-white rounded-3xl p-6 shadow-lg"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <div className="flex items-center space-x-4 mb-4">
              <div className="text-5xl">👩‍⚕️</div>
              <div className="flex-1">
                <div className="bg-emerald-100 rounded-2xl p-4 relative">
                  <p className="text-emerald-800 font-body font-medium">
                    {isParentMode 
                      ? "Selamat datang di Ruang Tes! Kita akan melakukan 3 tes untuk memahami kemampuan dan minatmu dengan lebih baik."
                      : "Halo! Yuk, ikuti 3 petualangan seru untuk mengetahui seberapa hebat kemampuanmu! 🌟"
                    }
                  </p>
                  <div className="absolute -left-2 top-4 w-4 h-4 bg-emerald-100 transform rotate-45"></div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Test Progress */}
        <div className="px-6 mb-6">
          <div className="bg-white rounded-2xl p-4 shadow-lg">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-lg text-emerald-800 font-heading font-semibold">
                {isParentMode ? 'Progress Tes' : 'Kemajuan Petualangan'}
              </h3>
              <span className="text-emerald-600 text-sm font-body">
                {completedTests.length}/{testPhases.length} {isParentMode ? 'selesai' : 'selesai'}
              </span>
            </div>
            <div className="w-full bg-emerald-100 rounded-full h-3">
              <motion.div
                className="bg-emerald-500 h-3 rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${(completedTests.length / testPhases.length) * 100}%` }}
                transition={{ duration: 0.5 }}
              />
            </div>
          </div>
        </div>

        {/* Test Phases */}
        <div className="flex-1 px-6 pb-6 overflow-y-auto">
          <div className="space-y-4">
            {testPhases.map((phase, index) => {
              const isCompleted = completedTests.includes(phase.id);
              const isNext = index === completedTests.length;
              const isLocked = index > completedTests.length;

              return (
                <motion.div
                  key={phase.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className={`relative overflow-hidden rounded-3xl shadow-lg ${
                    isLocked ? 'opacity-50' : ''
                  }`}
                >
                  <div className={`bg-gradient-to-r ${phase.color} p-6`}>
                    <div className="flex items-center space-x-4">
                      <div className="relative">
                        <div className="text-5xl">{phase.emoji}</div>
                        {isCompleted && (
                          <motion.div
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            className="absolute -top-1 -right-1 bg-green-500 rounded-full p-1"
                          >
                            <CheckCircle className="text-white" size={16} />
                          </motion.div>
                        )}
                        {isLocked && (
                          <div className="absolute inset-0 flex items-center justify-center bg-black/20 rounded-full">
                            <Lock className="text-white/80" size={24} />
                          </div>
                        )}
                      </div>
                      <div className="flex-1">
                        <h3 className="text-xl text-white mb-1 font-heading font-bold">
                          {phase.title}
                        </h3>
                        <p className="text-white/90 text-sm mb-2 font-body">
                          {phase.description}
                        </p>
                        <div className="flex items-center space-x-3 text-white/80 text-xs">
                          <div className="flex items-center space-x-1">
                            <Clock size={12} />
                            <span className="font-body">{phase.duration}</span>
                          </div>
                          {isCompleted && (
                            <div className="flex items-center space-x-1">
                              <Trophy size={12} />
                              <span className="font-body">{testResults[phase.id]}% skor</span>
                            </div>
                          )}
                        </div>
                      </div>
                      <div>
                        {isCompleted ? (
                          <div className="bg-green-500 text-white px-4 py-2 rounded-full text-sm font-body font-medium">
                            {isParentMode ? 'Selesai ✓' : 'Selesai ✓'}
                          </div>
                        ) : isNext ? (
                          <motion.button
                            onClick={() => startTest(phase.id)}
                            className="bg-white text-gray-800 px-6 py-3 rounded-full shadow-lg font-body font-bold"
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                          >
                            {isParentMode ? 'Mulai' : 'Yuk!'}
                          </motion.button>
                        ) : (
                          <div className="text-white/60 text-sm font-body">
                            {isParentMode ? 'Menunggu...' : 'Tunggu ya...'}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </motion.div>
              );
            })}
          </div>

          {completedTests.length === testPhases.length && (
            <motion.button
              onClick={() => setCurrentPhase('results')}
              className="w-full mt-6 bg-gradient-to-r from-yellow-400 to-orange-500 text-white p-6 rounded-3xl shadow-xl font-body font-bold"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <div className="flex items-center justify-center space-x-3">
                <Trophy size={24} />
                <span className="text-xl font-heading">
                  {isParentMode ? 'Lihat Hasil Lengkap' : 'Lihat Hasilku! 🎉'}
                </span>
              </div>
            </motion.button>
          )}
        </div>
      </div>
    );
  }

  // Render results screen
  if (currentPhase === 'results') {
    const overallScore = getOverallScore();

    return (
      <div className="h-screen bg-gradient-to-br from-yellow-200 to-orange-200 flex flex-col">
        <div className="flex items-center p-6 bg-white rounded-b-3xl shadow-lg">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-3 rounded-full bg-yellow-100"
            whileTap={{ scale: 0.9 }}
          >
            <ArrowLeft className="text-yellow-600" size={24} />
          </motion.button>
          <div className="flex-1 text-center">
            <h1 className="text-2xl text-yellow-800 font-heading font-bold">
              {isParentMode ? 'Hasil Tes Lengkap' : 'Hasil Petualanganku! 🏆'}
            </h1>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          {/* Overall Score */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-3xl p-8 shadow-xl text-center mb-6"
          >
            <div className="text-6xl mb-4">🎉</div>
            <h2 className="text-3xl text-yellow-800 mb-2 font-heading font-bold">
              {isParentMode ? 'Skor Keseluruhan' : 'Skor Totalku!'}
            </h2>
            <div className="text-5xl text-yellow-600 mb-4 font-heading font-bold">{overallScore}%</div>
            <p className="text-yellow-700 font-body text-lg">
              {overallScore >= 85 
                ? (isParentMode ? 'Luar Biasa!' : 'Kamu luar biasa banget!') 
                : overallScore >= 70 
                  ? (isParentMode ? 'Bagus Sekali!' : 'Kamu keren banget!') 
                  : (isParentMode ? 'Terus Belajar!' : 'Kamu hebat, terus belajar ya!')
              }
            </p>
          </motion.div>

          {/* Individual Test Results */}
          <div className="space-y-4 mb-6">
            {testPhases.map((phase, index) => (
              <motion.div
                key={phase.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-3xl p-6 shadow-lg"
              >
                <div className="flex items-center space-x-4">
                  <div className="text-4xl">{phase.emoji}</div>
                  <div className="flex-1">
                    <h3 className="text-lg text-gray-800 mb-2 font-heading font-semibold">
                      {phase.title}
                    </h3>
                    <div className="w-full bg-gray-200 rounded-full h-4">
                      <motion.div
                        className={`bg-gradient-to-r ${phase.color} h-4 rounded-full`}
                        initial={{ width: 0 }}
                        animate={{ width: `${testResults[phase.id] || 0}%` }}
                        transition={{ duration: 1, delay: 0.5 + index * 0.2 }}
                      />
                    </div>
                  </div>
                  <div className="text-2xl text-gray-600 font-heading font-bold">
                    {testResults[phase.id] || 0}%
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Mascot Congratulations */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1 }}
            className="text-center mb-6"
          >
            <ChildMascot 
              mood="celebrating" 
              size="medium" 
              showMessage={true}
              message={isParentMode 
                ? "Hasil tes menunjukkan perkembangan yang baik" 
                : `Selamat! Kamu sudah menyelesaikan semua petualangan dengan hebat!`
              }
            />
          </motion.div>
        </div>
      </div>
    );
  }

  return null;
}