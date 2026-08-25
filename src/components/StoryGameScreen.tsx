import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Sparkles, Heart, Star } from 'lucide-react';

interface StoryGameScreenProps {
  onBack: () => void;
  onComplete: (score: number) => void;
  isParentMode: boolean;
}

interface StoryScene {
  id: number;
  image: string;
  story: string;
  question: string;
  options: {
    text: string;
    trait: 'creative' | 'logical' | 'social' | 'physical';
    emoji: string;
  }[];
}

export default function StoryGameScreen({ onBack, onComplete, isParentMode }: StoryGameScreenProps) {
  const [currentSceneIndex, setCurrentSceneIndex] = useState(0);
  const [traits, setTraits] = useState({
    creative: 0,
    logical: 0,
    social: 0,
    physical: 0
  });
  const [showFeedback, setShowFeedback] = useState(false);
  const [selectedOption, setSelectedOption] = useState<string>('');
  const [isGameActive, setIsGameActive] = useState(true);

  const storyScenes: StoryScene[] = [
    {
      id: 1,
      image: '🌅',
      story: isParentMode 
        ? 'Pagi ini kamu bangun dan melihat hari yang cerah. Apa yang ingin kamu lakukan?'
        : 'Pagi yang cerah! Kamu bangun dan merasa senang. Apa yang ingin kamu lakukan hari ini?',
      question: isParentMode ? 'Pilih aktivitas pagi hari' : 'Aku mau...',
      options: [
        { text: 'Menggambar pemandangan', trait: 'creative', emoji: '🎨' },
        { text: 'Membaca buku cerita', trait: 'logical', emoji: '📚' },
        { text: 'Bermain dengan teman', trait: 'social', emoji: '👫' },
        { text: 'Bersepeda di taman', trait: 'physical', emoji: '🚴' }
      ]
    },
    {
      id: 2,
      image: '🎁',
      story: isParentMode
        ? 'Kamu mendapat hadiah dari orang tua. Hadiah apa yang paling kamu inginkan?'
        : 'Wow! Ada hadiah untukmu! Kamu mau hadiah apa?',
      question: isParentMode ? 'Pilih hadiah favorit' : 'Aku pilih...',
      options: [
        { text: 'Set alat melukis', trait: 'creative', emoji: '🖌️' },
        { text: 'Puzzle dan lego', trait: 'logical', emoji: '🧩' },
        { text: 'Mainan board game', trait: 'social', emoji: '🎲' },
        { text: 'Bola dan raket', trait: 'physical', emoji: '⚽' }
      ]
    },
    {
      id: 3,
      image: '🏫',
      story: isParentMode
        ? 'Di sekolah ada banyak kegiatan ekstrakurikuler. Mana yang paling menarik?'
        : 'Di sekolah ada kegiatan seru! Mana yang paling kamu suka?',
      question: isParentMode ? 'Pilih ekstrakurikuler' : 'Aku ikut...',
      options: [
        { text: 'Seni dan kerajinan', trait: 'creative', emoji: '✂️' },
        { text: 'Klub sains', trait: 'logical', emoji: '🔬' },
        { text: 'Tim debat', trait: 'social', emoji: '🎤' },
        { text: 'Olahraga futsal', trait: 'physical', emoji: '⚽' }
      ]
    },
    {
      id: 4,
      image: '🌳',
      story: isParentMode
        ? 'Kamu pergi ke taman bermain. Apa yang pertama kali kamu lakukan?'
        : 'Yeay! Kita ke taman! Apa yang mau kamu lakukan duluan?',
      question: isParentMode ? 'Pilih aktivitas di taman' : 'Aku mau...',
      options: [
        { text: 'Membuat istana pasir', trait: 'creative', emoji: '🏰' },
        { text: 'Main catur di bangku', trait: 'logical', emoji: '♟️' },
        { text: 'Ajak teman main', trait: 'social', emoji: '🤝' },
        { text: 'Main perosotan', trait: 'physical', emoji: '🛝' }
      ]
    },
    {
      id: 5,
      image: '📱',
      story: isParentMode
        ? 'Kamu boleh memilih satu aplikasi di tablet. Apa pilihanmu?'
        : 'Kamu boleh main tablet! Mau main apa?',
      question: isParentMode ? 'Pilih aplikasi favorit' : 'Aku pilih...',
      options: [
        { text: 'Aplikasi menggambar', trait: 'creative', emoji: '🎨' },
        { text: 'Game teka-teki', trait: 'logical', emoji: '🧠' },
        { text: 'Video call teman', trait: 'social', emoji: '📞' },
        { text: 'Game balapan', trait: 'physical', emoji: '🏎️' }
      ]
    },
    {
      id: 6,
      image: '🌈',
      story: isParentMode
        ? 'Jika kamu bisa memiliki satu kekuatan super, apa yang kamu pilih?'
        : 'Kalau kamu punya kekuatan super, mau yang mana?',
      question: isParentMode ? 'Pilih kekuatan super' : 'Aku mau...',
      options: [
        { text: 'Menciptakan sesuatu', trait: 'creative', emoji: '✨' },
        { text: 'Super pintar', trait: 'logical', emoji: '🧠' },
        { text: 'Membaca pikiran', trait: 'social', emoji: '💭' },
        { text: 'Terbang tinggi', trait: 'physical', emoji: '🦸' }
      ]
    },
    {
      id: 7,
      image: '🎉',
      story: isParentMode
        ? 'Hari ulang tahunmu! Pesta seperti apa yang kamu inginkan?'
        : 'Ulang tahun! Pesta apa yang kamu mau?',
      question: isParentMode ? 'Pilih tema pesta' : 'Aku mau pesta...',
      options: [
        { text: 'Workshop kerajinan', trait: 'creative', emoji: '🎨' },
        { text: 'Escape room', trait: 'logical', emoji: '🔍' },
        { text: 'Pesta besar ramai', trait: 'social', emoji: '🎊' },
        { text: 'Petualangan outdoor', trait: 'physical', emoji: '🏕️' }
      ]
    },
    {
      id: 8,
      image: '📖',
      story: isParentMode
        ? 'Waktu membaca cerita sebelum tidur. Cerita apa yang kamu pilih?'
        : 'Mau baca cerita! Cerita apa yang kamu suka?',
      question: isParentMode ? 'Pilih jenis cerita' : 'Aku mau cerita...',
      options: [
        { text: 'Dongeng fantasi', trait: 'creative', emoji: '🧚' },
        { text: 'Misteri detektif', trait: 'logical', emoji: '🔎' },
        { text: 'Petualangan teman', trait: 'social', emoji: '👥' },
        { text: 'Pahlawan super', trait: 'physical', emoji: '🦸' }
      ]
    }
  ];

  const currentScene = storyScenes[currentSceneIndex];

  const handleChoice = (option: typeof currentScene.options[0]) => {
    setSelectedOption(option.text);
    setShowFeedback(true);

    // Update traits
    setTraits(prev => ({
      ...prev,
      [option.trait]: prev[option.trait] + 1
    }));

    setTimeout(() => {
      setShowFeedback(false);
      setSelectedOption('');
      
      if (currentSceneIndex + 1 >= storyScenes.length) {
        completeStory();
      } else {
        setCurrentSceneIndex(currentSceneIndex + 1);
      }
    }, 2000);
  };

  const completeStory = () => {
    setIsGameActive(false);
    
    // Calculate dominant trait
    const maxTrait = Math.max(...Object.values(traits));
    const percentage = Math.round((maxTrait / storyScenes.length) * 100);
    
    setTimeout(() => {
      onComplete(percentage);
    }, 1500);
  };

  const getDominantTrait = () => {
    const entries = Object.entries(traits);
    const max = Math.max(...Object.values(traits));
    const dominant = entries.find(([_, value]) => value === max);
    return dominant ? dominant[0] : 'creative';
  };

  const getTraitInfo = (trait: string) => {
    switch (trait) {
      case 'creative':
        return {
          name: 'Kreatif & Artistik',
          emoji: '🎨',
          description: isParentMode 
            ? 'Anak menunjukkan kecenderungan seni dan kreativitas'
            : 'Kamu suka berkreasi dan berimajinasi!'
        };
      case 'logical':
        return {
          name: 'Logis & Analitis',
          emoji: '🧠',
          description: isParentMode
            ? 'Anak menunjukkan kemampuan berpikir logis dan analitis'
            : 'Kamu suka berpikir dan memecahkan masalah!'
        };
      case 'social':
        return {
          name: 'Sosial & Komunikatif',
          emoji: '👥',
          description: isParentMode
            ? 'Anak menunjukkan keterampilan sosial yang baik'
            : 'Kamu suka berteman dan berbicara!'
        };
      case 'physical':
        return {
          name: 'Aktif & Atletis',
          emoji: '⚽',
          description: isParentMode
            ? 'Anak menunjukkan minat pada aktivitas fisik'
            : 'Kamu suka bergerak dan olahraga!'
        };
      default:
        return { name: 'Unik', emoji: '⭐', description: 'Kepribadian yang unik' };
    }
  };

  if (!isGameActive) {
    const dominantTrait = getDominantTrait();
    const traitInfo = getTraitInfo(dominantTrait);

    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center p-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white rounded-3xl p-8 shadow-2xl text-center max-w-md"
        >
          <motion.div 
            className="text-8xl mb-4"
            animate={{ scale: [1, 1.2, 1] }}
            transition={{ duration: 1, repeat: Infinity }}
          >
            {traitInfo.emoji}
          </motion.div>
          <h2 className="text-2xl font-heading font-bold text-gray-800 mb-2">
            {traitInfo.name}
          </h2>
          <p className="text-gray-600 font-body mb-6">
            {traitInfo.description}
          </p>
          
          {/* Trait Breakdown */}
          <div className="space-y-3 mb-6">
            {Object.entries(traits).map(([trait, value]) => {
              const info = getTraitInfo(trait);
              return (
                <div key={trait} className="flex items-center space-x-3">
                  <span className="text-2xl">{info.emoji}</span>
                  <div className="flex-1 bg-gray-200 rounded-full h-3">
                    <motion.div
                      className="bg-gradient-to-r from-purple-500 to-pink-500 h-3 rounded-full"
                      initial={{ width: 0 }}
                      animate={{ width: `${(value / storyScenes.length) * 100}%` }}
                      transition={{ duration: 1, delay: 0.5 }}
                    />
                  </div>
                  <span className="text-sm font-body font-semibold text-gray-700 min-w-[30px]">
                    {value}
                  </span>
                </div>
              );
            })}
          </div>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-pink-50">
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
              <Sparkles className="text-orange-500" size={20} />
              <span className="font-heading font-bold text-gray-800">
                {isParentMode ? 'Cerita Interaktif' : 'Petualangan Cerita'}
              </span>
            </div>

            <div className="text-sm font-body text-gray-600">
              {currentSceneIndex + 1}/{storyScenes.length}
            </div>
          </div>

          {/* Progress Bar */}
          <div className="bg-gray-200 rounded-full h-2">
            <motion.div
              className="bg-gradient-to-r from-orange-500 to-pink-500 h-2 rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${((currentSceneIndex + 1) / storyScenes.length) * 100}%` }}
            />
          </div>
        </div>
      </div>

      {/* Story Area */}
      <div className="max-w-md mx-auto px-6 py-8">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentSceneIndex}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="space-y-6"
          >
            {/* Story Image */}
            <motion.div
              className="text-center"
              animate={{ y: [0, -15, 0] }}
              transition={{ duration: 3, repeat: Infinity }}
            >
              <div className="text-9xl mb-4">{currentScene.image}</div>
            </motion.div>

            {/* Story Text */}
            <motion.div
              className="bg-white rounded-3xl p-6 shadow-xl"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <div className="text-center mb-6">
                <div className="inline-block bg-gradient-to-r from-orange-100 to-pink-100 rounded-full px-4 py-2 mb-4">
                  <span className="font-body font-semibold text-orange-700">
                    Bagian {currentSceneIndex + 1}
                  </span>
                </div>
                <p className="text-xl font-body text-gray-700 leading-relaxed mb-4">
                  {currentScene.story}
                </p>
                <h3 className="text-2xl font-heading font-bold text-gray-800">
                  {currentScene.question}
                </h3>
              </div>

              {/* Choice Options */}
              <div className="space-y-3">
                {currentScene.options.map((option, index) => (
                  <motion.button
                    key={index}
                    onClick={() => !showFeedback && handleChoice(option)}
                    className={`w-full p-5 rounded-2xl font-body font-semibold text-lg transition-all ${
                      showFeedback && selectedOption === option.text
                        ? 'bg-gradient-to-r from-green-400 to-emerald-500 text-white scale-105'
                        : 'bg-gradient-to-r from-orange-100 to-pink-100 text-gray-800 hover:from-orange-200 hover:to-pink-200 active:scale-95'
                    }`}
                    whileHover={!showFeedback ? { scale: 1.02, x: 5 } : {}}
                    whileTap={!showFeedback ? { scale: 0.98 } : {}}
                    disabled={showFeedback}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 + (index * 0.1) }}
                  >
                    <div className="flex items-center space-x-3">
                      <span className="text-3xl">{option.emoji}</span>
                      <span className="flex-1 text-left">{option.text}</span>
                    </div>
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
                  className="text-center p-6 rounded-2xl bg-gradient-to-r from-green-100 to-emerald-100"
                >
                  <motion.div 
                    className="text-6xl mb-2"
                    animate={{ rotate: [0, 10, -10, 0] }}
                    transition={{ duration: 0.5 }}
                  >
                    ✨
                  </motion.div>
                  <p className="font-heading font-bold text-xl text-green-800">
                    {isParentMode ? 'Pilihan yang bagus!' : 'Pilihan yang keren!'}
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
