import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Heart, Star, Palette, Music, Trophy, BookOpen } from 'lucide-react';

interface InterestTalentTestScreenProps {
  navigateTo: (screen: string) => void;
}

export default function InterestTalentTestScreen({ navigateTo }: InterestTalentTestScreenProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Record<string, any>>({});
  const [showResults, setShowResults] = useState(false);
  const [draggedItem, setDraggedItem] = useState<string | null>(null);

  const questions = [
    {
      id: 'activity',
      question: 'Aktivitas mana yang paling kamu suka?',
      type: 'choice',
      options: [
        { id: 'art', label: 'Menggambar', emoji: '🎨', category: 'creative' },
        { id: 'sport', label: 'Olahraga', emoji: '⚽', category: 'physical' },
        { id: 'music', label: 'Musik', emoji: '🎵', category: 'creative' },
        { id: 'reading', label: 'Membaca', emoji: '📚', category: 'academic' }
      ]
    },
    {
      id: 'color',
      question: 'Warna favorit kamu?',
      type: 'choice',
      options: [
        { id: 'red', label: 'Merah', emoji: '🔴', category: 'energetic' },
        { id: 'blue', label: 'Biru', emoji: '🔵', category: 'calm' },
        { id: 'yellow', label: 'Kuning', emoji: '🟡', category: 'cheerful' },
        { id: 'green', label: 'Hijau', emoji: '🟢', category: 'nature' }
      ]
    },
    {
      id: 'hobby',
      question: 'Urutkan hobi dari yang paling disukai (seret dan lepas)',
      type: 'drag',
      options: [
        { id: 'dance', label: 'Menari', emoji: '💃', category: 'creative' },
        { id: 'science', label: 'Sains', emoji: '🔬', category: 'academic' },
        { id: 'cooking', label: 'Memasak', emoji: '👩‍🍳', category: 'practical' },
        { id: 'games', label: 'Bermain', emoji: '🎮', category: 'entertainment' }
      ]
    },
    {
      id: 'future',
      question: 'Apa yang ingin kamu jadi saat besar nanti?',
      type: 'choice',
      options: [
        { id: 'artist', label: 'Seniman', emoji: '🎨', category: 'creative' },
        { id: 'doctor', label: 'Dokter', emoji: '👩‍⚕️', category: 'academic' },
        { id: 'athlete', label: 'Atlet', emoji: '🏃‍♀️', category: 'physical' },
        { id: 'teacher', label: 'Guru', emoji: '👩‍🏫', category: 'social' }
      ]
    }
  ];

  const handleAnswer = (questionId: string, answer: any) => {
    setAnswers({ ...answers, [questionId]: answer });
    
    if (currentQuestion < questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      calculateResults();
    }
  };

  const calculateResults = () => {
    const categories = {
      creative: 0,
      academic: 0,
      physical: 0,
      social: 0,
      practical: 0,
      entertainment: 0
    };

    Object.values(answers).forEach((answer: any) => {
      if (Array.isArray(answer)) {
        answer.forEach((item, index) => {
          const points = answer.length - index;
          categories[item.category as keyof typeof categories] += points;
        });
      } else if (answer?.category) {
        categories[answer.category as keyof typeof categories] += 1;
      }
    });

    setShowResults(true);
  };

  const getTopInterests = () => {
    const categories = {
      creative: 0,
      academic: 0,
      physical: 0,
      social: 0,
      practical: 0,
      entertainment: 0
    };

    Object.values(answers).forEach((answer: any) => {
      if (Array.isArray(answer)) {
        answer.forEach((item, index) => {
          const points = answer.length - index;
          categories[item.category as keyof typeof categories] += points;
        });
      } else if (answer?.category) {
        categories[answer.category as keyof typeof categories] += 1;
      }
    });

    return Object.entries(categories)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 3)
      .map(([category, score]) => ({
        category,
        score,
        label: {
          creative: 'Kreatif',
          academic: 'Akademis',
          physical: 'Fisik',
          social: 'Sosial',
          practical: 'Praktis',
          entertainment: 'Hiburan'
        }[category],
        emoji: {
          creative: '🎨',
          academic: '📚',
          physical: '⚽',
          social: '👥',
          practical: '🔧',
          entertainment: '🎮'
        }[category],
        color: {
          creative: 'bg-pink-400',
          academic: 'bg-blue-400',
          physical: 'bg-green-400',
          social: 'bg-purple-400',
          practical: 'bg-orange-400',
          entertainment: 'bg-yellow-400'
        }[category]
      }));
  };

  const handleDragStart = (item: any) => {
    setDraggedItem(item.id);
  };

  const handleDrop = (targetIndex: number) => {
    if (!draggedItem) return;

    const currentOrder = answers['hobby'] || [...questions[2].options];
    const draggedIndex = currentOrder.findIndex((item: any) => item.id === draggedItem);
    
    if (draggedIndex === -1) return;

    const newOrder = [...currentOrder];
    const [draggedObject] = newOrder.splice(draggedIndex, 1);
    newOrder.splice(targetIndex, 0, draggedObject);

    setAnswers({ ...answers, hobby: newOrder });
    setDraggedItem(null);
  };

  if (showResults) {
    const topInterests = getTopInterests();
    
    return (
      <div className="h-screen bg-gradient-to-br from-purple-200 to-pink-200 flex flex-col">
        <div className="flex items-center p-6 bg-white rounded-b-3xl shadow-lg">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-3 rounded-full bg-purple-100"
            whileTap={{ scale: 0.9 }}
          >
            <ArrowLeft className="text-purple-600" size={24} />
          </motion.button>
          <div className="flex-1 text-center">
            <h1 className="text-gray-900 font-heading font-bold text-xl">
              Hasil Tes Bakat & Minat
            </h1>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-3xl p-8 shadow-xl text-center mb-6"
          >
            <div className="text-6xl mb-4">🎉</div>
            <h2 className="text-gray-900 font-heading font-bold text-2xl mb-4">
              Bakat & Minat Kamu
            </h2>
            <p className="text-gray-600 font-body text-base">
              Inilah area yang paling menarik untuk kamu!
            </p>
          </motion.div>

          {/* Results Chart */}
          <div className="space-y-4">
            {topInterests.map((interest, index) => (
              <motion.div
                key={interest.category}
                initial={{ opacity: 0, x: -50 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.2 }}
                className="bg-white rounded-3xl p-6 shadow-lg"
              >
                <div className="flex items-center space-x-4 mb-4">
                  <div className="text-4xl">{interest.emoji}</div>
                  <div className="flex-1">
                    <h3 className="text-gray-900 font-heading font-bold text-lg">
                      {interest.label}
                    </h3>
                    <div className="w-full bg-gray-200 rounded-full h-4 mt-2">
                      <motion.div
                        className={`${interest.color} h-4 rounded-full`}
                        initial={{ width: 0 }}
                        animate={{ width: `${(interest.score / Math.max(...topInterests.map(i => i.score))) * 100}%` }}
                        transition={{ duration: 1, delay: index * 0.3 }}
                      />
                    </div>
                  </div>
                  <div className="text-gray-600 font-heading font-bold text-xl">
                    #{index + 1}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Recommendations */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1 }}
            className="mt-6 bg-gradient-to-r from-yellow-400 to-orange-500 rounded-3xl p-6 text-white shadow-lg"
          >
            <div className="flex items-center space-x-3 mb-4">
              <Star size={32} />
              <h3 className="text-white font-heading font-bold text-lg">
                Rekomendasi Aktivitas
              </h3>
            </div>
            <div className="space-y-2">
              {topInterests[0]?.category === 'creative' && (
                <p className="text-white font-body text-sm">
                  • Ikut kelas seni atau musik
                </p>
              )}
              {topInterests[0]?.category === 'academic' && (
                <p className="text-white font-body text-sm">
                  • Bergabung dengan klub sains
                </p>
              )}
              {topInterests[0]?.category === 'physical' && (
                <p className="text-white font-body text-sm">
                  • Coba berbagai jenis olahraga
                </p>
              )}
              <p className="text-white font-body text-sm">
                • Eksplorasi lebih banyak aktivitas sesuai minat
              </p>
            </div>
          </motion.div>
        </div>
      </div>
    );
  }

  const currentQ = questions[currentQuestion];

  return (
    <div className="h-screen bg-gradient-to-br from-indigo-200 to-purple-200 flex flex-col">
      {/* Header */}
      <div className="flex items-center p-6 bg-white rounded-b-3xl shadow-lg">
        <motion.button
          onClick={() => navigateTo('home')}
          className="p-3 rounded-full bg-indigo-100"
          whileTap={{ scale: 0.9 }}
        >
          <ArrowLeft className="text-indigo-600" size={24} />
        </motion.button>
        <div className="flex-1 text-center">
          <h1 className="text-gray-900 font-heading font-bold text-xl">
            Tes Bakat & Minat
          </h1>
          <p className="text-indigo-600 font-body text-sm">Pertanyaan {currentQuestion + 1} dari {questions.length}</p>
        </div>
        <div className="flex space-x-1">
          {questions.map((_, i) => (
            <div
              key={i}
              className={`w-3 h-3 rounded-full ${
                i <= currentQuestion ? 'bg-indigo-500' : 'bg-indigo-200'
              }`}
            />
          ))}
        </div>
      </div>

      {/* Question */}
      <div className="flex-1 flex flex-col justify-center p-6">
        <motion.div
          key={currentQuestion}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-3xl p-8 shadow-xl text-center mb-8"
        >
          <h2 className="text-gray-900 font-heading font-bold text-xl mb-6">
            {currentQ.question}
          </h2>
          
          {currentQ.type === 'choice' && (
            <div className="grid grid-cols-2 gap-4">
              {currentQ.options.map((option, index) => (
                <motion.button
                  key={option.id}
                  onClick={() => handleAnswer(currentQ.id, option)}
                  className="p-6 bg-indigo-50 hover:bg-indigo-100 rounded-3xl shadow-lg transition-colors"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <div className="text-4xl mb-2">{option.emoji}</div>
                  <p className="text-indigo-800 font-heading font-semibold">
                    {option.label}
                  </p>
                </motion.button>
              ))}
            </div>
          )}

          {currentQ.type === 'drag' && (
            <div className="space-y-4">
              <p className="text-indigo-600 font-body text-sm mb-6">
                Seret untuk mengurutkan dari yang paling disukai
              </p>
              {(answers['hobby'] || currentQ.options).map((item: any, index: number) => (
                <motion.div
                  key={item.id}
                  draggable
                  onDragStart={() => handleDragStart(item)}
                  onDragOver={(e) => e.preventDefault()}
                  onDrop={() => handleDrop(index)}
                  className="flex items-center space-x-4 p-4 bg-indigo-50 rounded-2xl shadow-md cursor-move hover:bg-indigo-100 transition-colors"
                  whileHover={{ scale: 1.02 }}
                >
                  <div className="text-indigo-800 font-heading font-bold text-lg">{index + 1}</div>
                  <div className="text-3xl">{item.emoji}</div>
                  <div className="flex-1 text-left">
                    <p className="text-indigo-800 font-heading font-semibold">
                      {item.label}
                    </p>
                  </div>
                  <div className="text-indigo-400">≡</div>
                </motion.div>
              ))}
              <motion.button
                onClick={() => handleAnswer(currentQ.id, answers['hobby'] || currentQ.options)}
                className="bg-indigo-500 hover:bg-indigo-600 text-white font-heading font-bold px-8 py-3 rounded-2xl shadow-lg mt-6"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                Lanjut
              </motion.button>
            </div>
          )}
        </motion.div>
      </div>
    </div>
  );
}