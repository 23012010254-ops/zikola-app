import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Heart, Star, Trophy, Zap } from 'lucide-react';

interface MathGameScreenProps {
  onBack: () => void;
  onComplete: (score: number) => void;
  isParentMode: boolean;
}

interface Question {
  question: string;
  answer: number;
  options: number[];
  type: 'addition' | 'subtraction' | 'counting' | 'comparison';
  visual?: string;
}

export default function MathGameScreen({ onBack, onComplete, isParentMode }: MathGameScreenProps) {
  const [currentLevel, setCurrentLevel] = useState(1);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [streak, setStreak] = useState(0);
  const [timeLeft, setTimeLeft] = useState(30);
  const [isGameActive, setIsGameActive] = useState(true);

  const generateQuestions = (): Question[] => {
    const questions: Question[] = [];
    
    // Level 1: Simple Addition (1-10)
    for (let i = 0; i < 3; i++) {
      const num1 = Math.floor(Math.random() * 5) + 1;
      const num2 = Math.floor(Math.random() * 5) + 1;
      const answer = num1 + num2;
      const wrongAnswers = [answer - 1, answer + 1, answer + 2].filter(n => n > 0 && n !== answer);
      questions.push({
        question: `${num1} + ${num2} = ?`,
        answer,
        options: [answer, ...wrongAnswers.slice(0, 3)].sort(() => Math.random() - 0.5),
        type: 'addition',
        visual: '🍎'.repeat(num1) + ' + ' + '🍎'.repeat(num2)
      });
    }

    // Level 2: Simple Subtraction
    for (let i = 0; i < 3; i++) {
      const num1 = Math.floor(Math.random() * 5) + 5;
      const num2 = Math.floor(Math.random() * num1) + 1;
      const answer = num1 - num2;
      const wrongAnswers = [answer - 1, answer + 1, answer + 2].filter(n => n >= 0 && n !== answer);
      questions.push({
        question: `${num1} - ${num2} = ?`,
        answer,
        options: [answer, ...wrongAnswers.slice(0, 3)].sort(() => Math.random() - 0.5),
        type: 'subtraction',
        visual: '🍊'.repeat(num1) + ' ➖ ' + '🍊'.repeat(num2)
      });
    }

    // Level 3: Counting objects
    for (let i = 0; i < 2; i++) {
      const count = Math.floor(Math.random() * 10) + 5;
      const wrongAnswers = [count - 2, count + 1, count - 1].filter(n => n > 0 && n !== count);
      questions.push({
        question: isParentMode ? 'Hitung jumlah objek' : 'Hitung ada berapa?',
        answer: count,
        options: [count, ...wrongAnswers.slice(0, 3)].sort(() => Math.random() - 0.5),
        type: 'counting',
        visual: '⭐'.repeat(count)
      });
    }

    // Level 4: Comparison
    for (let i = 0; i < 2; i++) {
      const num1 = Math.floor(Math.random() * 10) + 1;
      const num2 = Math.floor(Math.random() * 10) + 1;
      const answer = Math.max(num1, num2);
      const options = [num1, num2, Math.floor(Math.random() * 10) + 1, Math.floor(Math.random() * 10) + 1];
      questions.push({
        question: isParentMode ? `Mana yang lebih besar?` : 'Pilih yang paling besar!',
        answer,
        options: Array.from(new Set(options)).slice(0, 4),
        type: 'comparison',
        visual: `${num1} 🆚 ${num2}`
      });
    }

    return questions;
  };

  const [questions] = useState<Question[]>(generateQuestions());
  const currentQuestion = questions[currentQuestionIndex];

  // Timer countdown
  useEffect(() => {
    if (!isGameActive || showFeedback) return;
    
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          handleTimeUp();
          return 30;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [isGameActive, showFeedback, currentQuestionIndex]);

  const handleTimeUp = () => {
    setLives(lives - 1);
    setStreak(0);
    if (lives <= 1) {
      completeGame();
    } else {
      nextQuestion();
    }
  };

  const handleAnswer = (selectedAnswer: number) => {
    if (showFeedback || !isGameActive) return;

    const correct = selectedAnswer === currentQuestion.answer;
    setIsCorrect(correct);
    setShowFeedback(true);

    if (correct) {
      const points = Math.ceil(10 * (timeLeft / 30)); // Bonus for speed
      setScore(score + points + (streak * 2));
      setStreak(streak + 1);
    } else {
      setLives(lives - 1);
      setStreak(0);
    }

    setTimeout(() => {
      setShowFeedback(false);
      
      if (!correct && lives <= 1) {
        completeGame();
      } else {
        nextQuestion();
      }
    }, 1500);
  };

  const nextQuestion = () => {
    if (currentQuestionIndex + 1 >= questions.length) {
      completeGame();
    } else {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
      setTimeLeft(30);
    }
  };

  const completeGame = () => {
    setIsGameActive(false);
    const percentage = Math.round((score / (questions.length * 12)) * 100);
    setTimeout(() => {
      onComplete(Math.min(percentage, 100));
    }, 1500);
  };

  if (!isGameActive) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center p-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white rounded-3xl p-8 shadow-2xl text-center max-w-md"
        >
          <div className="text-6xl mb-4">🎉</div>
          <h2 className="text-2xl font-heading font-bold text-gray-800 mb-2">
            {isParentMode ? 'Tes Selesai!' : 'Game Selesai!'}
          </h2>
          <div className="text-5xl font-heading font-bold text-blue-600 mb-4">{score}</div>
          <p className="text-gray-600 font-body mb-6">
            {isParentMode ? 'Total Poin' : 'Poin yang kamu dapat!'}
          </p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-purple-50">
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
              <div className="text-2xl font-heading font-bold text-blue-600">{score}</div>
              <div className="text-xs text-gray-600 font-body">poin</div>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="flex items-center space-x-3 mb-3">
            <div className="flex-1 bg-gray-200 rounded-full h-2">
              <motion.div
                className="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${((currentQuestionIndex + 1) / questions.length) * 100}%` }}
              />
            </div>
            <span className="text-sm font-body text-gray-600 min-w-[60px] text-right">
              {currentQuestionIndex + 1}/{questions.length}
            </span>
          </div>

          {/* Timer */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Zap className="text-yellow-500" size={16} />
              <span className="text-sm font-body font-semibold text-gray-700">
                {streak > 0 && `${streak}x Streak!`}
              </span>
            </div>
            <div className={`text-sm font-body font-bold ${timeLeft <= 10 ? 'text-red-500 animate-pulse' : 'text-gray-700'}`}>
              ⏱️ {timeLeft}s
            </div>
          </div>
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
            {/* Mascot Encouragement */}
            <motion.div 
              className="text-center"
              animate={{ y: [0, -10, 0] }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              <div className="text-6xl mb-2">🧮</div>
              <p className="text-gray-700 font-body font-medium">
                {isParentMode ? 'Pilih jawaban yang benar' : 'Yuk jawab dengan cepat!'}
              </p>
            </motion.div>

            {/* Question Card */}
            <motion.div
              className="bg-white rounded-3xl p-8 shadow-xl"
              whileHover={{ scale: 1.01 }}
            >
              {/* Visual representation */}
              {currentQuestion.visual && (
                <div className="text-center mb-6 p-4 bg-blue-50 rounded-2xl">
                  <div className="text-2xl mb-2 break-words">{currentQuestion.visual}</div>
                </div>
              )}

              {/* Question */}
              <h2 className="text-3xl font-heading font-bold text-gray-800 text-center mb-8">
                {currentQuestion.question}
              </h2>

              {/* Answer Options */}
              <div className="grid grid-cols-2 gap-4">
                {currentQuestion.options.map((option, index) => (
                  <motion.button
                    key={index}
                    onClick={() => handleAnswer(option)}
                    className={`p-6 rounded-2xl font-heading font-bold text-2xl transition-all ${
                      showFeedback
                        ? option === currentQuestion.answer
                          ? 'bg-green-500 text-white scale-105'
                          : 'bg-gray-200 text-gray-400'
                        : 'bg-gradient-to-br from-blue-100 to-purple-100 text-gray-800 hover:from-blue-200 hover:to-purple-200 active:scale-95'
                    }`}
                    whileHover={!showFeedback ? { scale: 1.05, y: -5 } : {}}
                    whileTap={!showFeedback ? { scale: 0.95 } : {}}
                    disabled={showFeedback}
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
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  className={`text-center p-6 rounded-2xl ${
                    isCorrect ? 'bg-green-100' : 'bg-red-100'
                  }`}
                >
                  <div className="text-5xl mb-2">
                    {isCorrect ? '🎉' : '💪'}
                  </div>
                  <p className={`font-heading font-bold text-xl ${
                    isCorrect ? 'text-green-800' : 'text-red-800'
                  }`}>
                    {isCorrect
                      ? (isParentMode ? 'Benar!' : 'Hebat!')
                      : (isParentMode ? 'Coba lagi' : 'Semangat!')
                    }
                  </p>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
