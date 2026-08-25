import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Heart, Volume2, Star, Sparkles } from 'lucide-react';

interface LinguisticGameScreenProps {
  onBack: () => void;
  onComplete: (score: number) => void;
  isParentMode: boolean;
}

interface Question {
  question: string;
  answer: string;
  options: string[];
  type: 'rhyme' | 'synonym' | 'sound' | 'spelling' | 'category';
  hint?: string;
  emoji?: string;
}

export default function LinguisticGameScreen({ onBack, onComplete, isParentMode }: LinguisticGameScreenProps) {
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [combo, setCombo] = useState(0);
  const [isGameActive, setIsGameActive] = useState(true);

  const questions: Question[] = [
    // Rhyming words
    {
      question: isParentMode ? 'Kata mana yang berima dengan "KUDA"?' : 'Kata mana yang bunyinya mirip "KUDA"?',
      answer: 'MUDA',
      options: ['MUDA', 'SAPI', 'BIRU', 'MEJA'],
      type: 'rhyme',
      emoji: '🐴',
      hint: 'Cari yang bunyinya ...UDA'
    },
    {
      question: isParentMode ? 'Kata mana yang berima dengan "BUKU"?' : 'Kata mana yang bunyinya mirip "BUKU"?',
      answer: 'SAKU',
      options: ['MEJA', 'SAKU', 'BOLA', 'TOPI'],
      type: 'rhyme',
      emoji: '📚',
      hint: 'Cari yang bunyinya ...UKU'
    },
    // Synonyms
    {
      question: isParentMode ? 'Kata yang artinya sama dengan "SENANG"?' : 'Kata lain dari "SENANG" itu...',
      answer: 'GEMBIRA',
      options: ['SEDIH', 'GEMBIRA', 'MARAH', 'TAKUT'],
      type: 'synonym',
      emoji: '😊',
      hint: 'Perasaan bahagia'
    },
    {
      question: isParentMode ? 'Kata yang artinya sama dengan "BESAR"?' : 'Kata lain dari "BESAR" itu...',
      answer: 'RAKSASA',
      options: ['KECIL', 'RAKSASA', 'PENDEK', 'TIPIS'],
      type: 'synonym',
      emoji: '🐘',
      hint: 'Sangat besar sekali'
    },
    // Animal sounds
    {
      question: isParentMode ? 'Suara apa yang dibuat KUCING?' : 'Kucing bersuara...',
      answer: 'MEONG',
      options: ['GUK GUK', 'MEONG', 'MOO', 'KUKURUYUK'],
      type: 'sound',
      emoji: '🐱',
      hint: 'Dengarkan suara kucing'
    },
    {
      question: isParentMode ? 'Suara apa yang dibuat BEBEK?' : 'Bebek bersuara...',
      answer: 'KWEK KWEK',
      options: ['MEONG', 'KWEK KWEK', 'GUK GUK', 'CICIT'],
      type: 'sound',
      emoji: '🦆',
      hint: 'Suara bebek di kolam'
    },
    // Spelling
    {
      question: isParentMode ? 'Mana penulisan yang BENAR?' : 'Pilih yang tulisannya benar!',
      answer: 'RUMAH',
      options: ['RUMAH', 'RUMMAH', 'RUMHA', 'RUMA'],
      type: 'spelling',
      emoji: '🏠',
      hint: 'Tempat tinggal kita'
    },
    {
      question: isParentMode ? 'Mana penulisan yang BENAR?' : 'Pilih yang tulisannya benar!',
      answer: 'SEKOLAH',
      options: ['SEKOLAH', 'SEKOLA', 'SKOLAH', 'SEKOLH'],
      type: 'spelling',
      emoji: '🏫',
      hint: 'Tempat belajar'
    },
    // Categories
    {
      question: isParentMode ? 'Mana yang termasuk BUAH?' : 'Mana yang buah-buahan?',
      answer: 'APEL',
      options: ['WORTEL', 'APEL', 'BROKOLI', 'BAYAM'],
      type: 'category',
      emoji: '🍎',
      hint: 'Yang manis dan bulat'
    },
    {
      question: isParentMode ? 'Mana yang termasuk KENDARAAN?' : 'Mana yang kendaraan?',
      answer: 'MOBIL',
      options: ['KURSI', 'MOBIL', 'RUMAH', 'POHON'],
      type: 'category',
      emoji: '🚗',
      hint: 'Yang bisa berjalan di jalan'
    }
  ];

  const currentQuestion = questions[currentQuestionIndex];

  const handleAnswer = (selectedAnswer: string) => {
    if (showFeedback || !isGameActive) return;

    const correct = selectedAnswer === currentQuestion.answer;
    setIsCorrect(correct);
    setShowFeedback(true);

    if (correct) {
      const points = 10 + (combo * 3);
      setScore(score + points);
      setCombo(combo + 1);
    } else {
      setLives(lives - 1);
      setCombo(0);
    }

    setTimeout(() => {
      setShowFeedback(false);
      
      if (!correct && lives <= 1) {
        completeGame();
      } else if (currentQuestionIndex + 1 >= questions.length) {
        completeGame();
      } else {
        setCurrentQuestionIndex(currentQuestionIndex + 1);
      }
    }, 1800);
  };

  const completeGame = () => {
    setIsGameActive(false);
    const percentage = Math.round((score / (questions.length * 13)) * 100);
    setTimeout(() => {
      onComplete(Math.min(percentage, 100));
    }, 1500);
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'rhyme': return 'from-pink-400 to-rose-500';
      case 'synonym': return 'from-purple-400 to-indigo-500';
      case 'sound': return 'from-yellow-400 to-orange-500';
      case 'spelling': return 'from-green-400 to-teal-500';
      case 'category': return 'from-blue-400 to-cyan-500';
      default: return 'from-gray-400 to-gray-500';
    }
  };

  const getTypeName = (type: string) => {
    switch (type) {
      case 'rhyme': return 'Sajak';
      case 'synonym': return 'Sinonim';
      case 'sound': return 'Suara';
      case 'spelling': return 'Ejaan';
      case 'category': return 'Kategori';
      default: return 'Bahasa';
    }
  };

  if (!isGameActive) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center p-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white rounded-3xl p-8 shadow-2xl text-center max-w-md"
        >
          <div className="text-6xl mb-4">📖</div>
          <h2 className="text-2xl font-heading font-bold text-gray-800 mb-2">
            {isParentMode ? 'Tes Selesai!' : 'Game Selesai!'}
          </h2>
          <div className="text-5xl font-heading font-bold text-purple-600 mb-4">{score}</div>
          <p className="text-gray-600 font-body mb-6">
            {isParentMode ? 'Total Poin' : 'Poin yang kamu dapat!'}
          </p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-pink-50">
      {/* Header */}
      <div className="bg-white shadow-md">
        <div className="max-w-md mx-auto px-6 py-4">
          <div className="flex items-center justify-between mb-3">
            <motion.button
              onClick={onBack}
              className="p-2 rounded-xl bg-gray-100 hover:bg-gray-200"
              whileTap={{ scale: 0.9 }}
            >
              <ArrowLeft className="text-gray-600" size={20} />
            </motion.button>
            
            <div className="flex items-center space-x-2">
              {Array.from({ length: lives }, (_, i) => (
                <motion.div
                  key={i}
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: i * 0.1 }}
                >
                  <Heart className="text-red-500" size={20} fill="currentColor" />
                </motion.div>
              ))}
            </div>

            <div className="text-right">
              <div className="text-2xl font-heading font-bold text-purple-600">{score}</div>
              <div className="text-xs text-gray-600 font-body">poin</div>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="flex items-center space-x-3 mb-3">
            <div className="flex-1 bg-gray-200 rounded-full h-2">
              <motion.div
                className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${((currentQuestionIndex + 1) / questions.length) * 100}%` }}
              />
            </div>
            <span className="text-sm font-body text-gray-600 min-w-[60px] text-right">
              {currentQuestionIndex + 1}/{questions.length}
            </span>
          </div>

          {/* Combo Counter */}
          {combo > 0 && (
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="flex items-center justify-center space-x-2 bg-gradient-to-r from-yellow-100 to-orange-100 rounded-full px-4 py-2"
            >
              <Sparkles className="text-orange-500" size={16} />
              <span className="text-sm font-body font-bold text-orange-700">
                {combo}x Combo!
              </span>
            </motion.div>
          )}
        </div>
      </div>

      {/* Game Area */}
      <div className="max-w-md mx-auto px-6 py-6">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentQuestionIndex}
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -50 }}
            className="space-y-6"
          >
            {/* Type Badge */}
            <div className="flex justify-center">
              <motion.div
                className={`bg-gradient-to-r ${getTypeColor(currentQuestion.type)} text-white px-6 py-2 rounded-full shadow-lg`}
                whileHover={{ scale: 1.05 }}
              >
                <span className="font-body font-bold text-sm">
                  {getTypeName(currentQuestion.type)}
                </span>
              </motion.div>
            </div>

            {/* Emoji Display */}
            <motion.div 
              className="text-center"
              animate={{ rotate: [0, -10, 10, -10, 0] }}
              transition={{ duration: 0.5 }}
            >
              <div className="text-7xl mb-2">{currentQuestion.emoji}</div>
            </motion.div>

            {/* Question Card */}
            <motion.div
              className="bg-white rounded-3xl p-6 shadow-xl"
              whileHover={{ scale: 1.01 }}
            >
              <h2 className="text-2xl font-heading font-bold text-gray-800 text-center mb-6">
                {currentQuestion.question}
              </h2>

              {/* Hint */}
              {currentQuestion.hint && (
                <div className="text-center mb-6 p-3 bg-purple-50 rounded-xl">
                  <p className="text-sm font-body text-purple-700 italic">
                    💡 {currentQuestion.hint}
                  </p>
                </div>
              )}

              {/* Answer Options */}
              <div className="space-y-3">
                {currentQuestion.options.map((option, index) => (
                  <motion.button
                    key={index}
                    onClick={() => handleAnswer(option)}
                    className={`w-full p-5 rounded-2xl font-body font-bold text-lg transition-all ${
                      showFeedback
                        ? option === currentQuestion.answer
                          ? 'bg-green-500 text-white scale-105'
                          : 'bg-gray-200 text-gray-400'
                        : 'bg-gradient-to-r from-purple-100 to-pink-100 text-gray-800 hover:from-purple-200 hover:to-pink-200 active:scale-95'
                    }`}
                    whileHover={!showFeedback ? { scale: 1.02, x: 5 } : {}}
                    whileTap={!showFeedback ? { scale: 0.98 } : {}}
                    disabled={showFeedback}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                  >
                    {option}
                  </motion.button>
                ))}
              </div>
            </motion.div>

            {/* Feedback */}
            <AnimatePresence>
              {showFeedback && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8 }}
                  className={`text-center p-6 rounded-2xl ${
                    isCorrect ? 'bg-green-100' : 'bg-red-100'
                  }`}
                >
                  <motion.div 
                    className="text-6xl mb-2"
                    animate={{ rotate: [0, 360] }}
                    transition={{ duration: 0.5 }}
                  >
                    {isCorrect ? '🎉' : '💪'}
                  </motion.div>
                  <p className={`font-heading font-bold text-2xl mb-1 ${
                    isCorrect ? 'text-green-800' : 'text-red-800'
                  }`}>
                    {isCorrect
                      ? (isParentMode ? 'Benar!' : 'Pintar sekali!')
                      : (isParentMode ? 'Coba lagi' : 'Ayo semangat!')
                    }
                  </p>
                  {isCorrect && (
                    <p className="text-sm font-body text-green-700">
                      +{10 + ((combo - 1) * 3)} poin
                    </p>
                  )}
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
