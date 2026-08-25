import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Star, Trophy, Clock } from 'lucide-react';

interface StoryBuilderGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults?: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

interface StoryProblem {
  words: string[];
  correctOrder: number[];
  correctSentence: string;
  hint: string;
  level: number;
  domain: string;
  emoji: string;
}

export default function StoryBuilderGame({ 
  navigateTo, 
  addSticker, 
  childName,
  updateTestResults,
  updateGameAssessment 
}: StoryBuilderGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'options' | 'playing' | 'completed'>('menu');
  const [language, setLanguage] = useState<'id' | 'en'>('id');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [timeLeft, setTimeLeft] = useState(90);
  const [currentProblem, setCurrentProblem] = useState<StoryProblem | null>(null);
  const [selectedWords, setSelectedWords] = useState<string[]>([]);
  const [availableWords, setAvailableWords] = useState<string[]>([]);
  const [startTime, setStartTime] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [usedQuestions, setUsedQuestions] = useState<number[]>([]);
  const [feedback, setFeedback] = useState<{ show: boolean; isCorrect: boolean; correctAnswer: string } | null>(null);

  // Story problems untuk anak usia 8-9 tahun
  const storyProblems = {
    id: [
      // Level 1: Kalimat Sederhana
      {
        words: ['makan', 'Saya', 'nasi'],
        correctOrder: [1, 0, 2], // Saya makan nasi
        correctSentence: 'Saya makan nasi',
        hint: 'Mulai dengan siapa yang melakukan',
        level: 1,
        domain: 'Struktur Kalimat',
        emoji: '🍚'
      },
      {
        words: ['bermain', 'Adik', 'bola'],
        correctOrder: [1, 0, 2], // Adik bermain bola
        correctSentence: 'Adik bermain bola',
        hint: 'Siapa + apa yang dilakukan + objek',
        level: 1,
        domain: 'Struktur Kalimat',
        emoji: '⚽'
      },
      {
        words: ['buku', 'membaca', 'Ibu'],
        correctOrder: [2, 1, 0], // Ibu membaca buku
        correctSentence: 'Ibu membaca buku',
        hint: 'Mulai dengan subjek',
        level: 1,
        domain: 'Struktur Kalimat',
        emoji: '📚'
      },
      {
        words: ['tidur', 'Kucing', 'di', 'kasur'],
        correctOrder: [1, 0, 2, 3], // Kucing tidur di kasur
        correctSentence: 'Kucing tidur di kasur',
        hint: 'Subjek + kata kerja + tempat',
        level: 1,
        domain: 'Struktur Kalimat',
        emoji: '🐱'
      },
      
      // Level 2: Kalimat dengan Keterangan
      {
        words: ['dengan', 'Kami', 'bermain', 'riang'],
        correctOrder: [1, 2, 3, 0], // Kami bermain dengan riang
        correctSentence: 'Kami bermain dengan riang',
        hint: 'Tambahkan keterangan di akhir',
        level: 2,
        domain: 'Kalimat Lengkap',
        emoji: '😊'
      },
      {
        words: ['di', 'Burung', 'terbang', 'langit'],
        correctOrder: [1, 2, 3, 0], // Burung terbang di langit
        correctSentence: 'Burung terbang di langit',
        hint: 'Jangan lupa keterangan tempat',
        level: 2,
        domain: 'Kalimat Lengkap',
        emoji: '🐦'
      },
      {
        words: ['Ayah', 'mobil', 'ke', 'mengendarai', 'kantor'],
        correctOrder: [0, 3, 1, 2, 4], // Ayah mengendarai mobil ke kantor
        correctSentence: 'Ayah mengendarai mobil ke kantor',
        hint: 'Subjek + kata kerja + objek + tujuan',
        level: 2,
        domain: 'Kalimat Lengkap',
        emoji: '🚗'
      },
      {
        words: ['merah', 'Bunga', 'sangat', 'itu', 'indah'],
        correctOrder: [1, 0, 3, 2, 4], // Bunga merah itu sangat indah
        correctSentence: 'Bunga merah itu sangat indah',
        hint: 'Subjek + sifat + kata tunjuk + keterangan',
        level: 2,
        domain: 'Kalimat Lengkap',
        emoji: '🌹'
      },
      
      // Level 3: Kalimat Kompleks
      {
        words: ['karena', 'senang', 'Aku', 'hujan', 'bermain'],
        correctOrder: [2, 1, 4, 0, 3], // Aku senang bermain karena hujan
        correctSentence: 'Aku senang bermain karena hujan',
        hint: 'Gunakan kata hubung',
        level: 3,
        domain: 'Kalimat Kompleks',
        emoji: '🌧️'
      },
      {
        words: ['dan', 'Singa', 'besar', 'kuat', 'sangat'],
        correctOrder: [1, 4, 2, 3, 0], // Singa sangat besar dan kuat
        correctSentence: 'Singa sangat besar dan kuat',
        hint: 'Hubungkan dua sifat',
        level: 3,
        domain: 'Kalimat Kompleks',
        emoji: '🦁'
      },
      {
        words: ['tetapi', 'Hari', 'hujan', 'ini', 'berangkat', 'aku', 'tetap'],
        correctOrder: [1, 3, 2, 0, 5, 6, 4], // Hari ini hujan tetapi aku tetap berangkat
        correctSentence: 'Hari ini hujan tetapi aku tetap berangkat',
        hint: 'Gabungkan dua klausa',
        level: 3,
        domain: 'Kalimat Kompleks',
        emoji: '☔'
      },
      
      // Level 4: Kalimat Cerita
      {
        words: ['pagi', 'Setiap', 'sekolah', 'berjalan', 'ke', 'aku', 'kaki'],
        correctOrder: [1, 0, 5, 3, 4, 2, 6], // Setiap pagi aku berjalan kaki ke sekolah
        correctSentence: 'Setiap pagi aku berjalan kaki ke sekolah',
        hint: 'Waktu + subjek + aktivitas + tujuan',
        level: 4,
        domain: 'Kalimat Narasi',
        emoji: '🏫'
      },
      {
        words: ['taman', 'Kemarin', 'bermain', 'kami', 'di', 'sangat', 'senang'],
        correctOrder: [1, 3, 2, 4, 0, 5, 6], // Kemarin kami bermain di taman sangat senang
        correctSentence: 'Kemarin kami bermain di taman sangat senang',
        hint: 'Ceritakan kejadian masa lalu',
        level: 4,
        domain: 'Kalimat Narasi',
        emoji: '🎈'
      }
    ],
    en: [
      // Level 1: Simple Sentences
      {
        words: ['eat', 'I', 'rice'],
        correctOrder: [1, 0, 2], // I eat rice
        correctSentence: 'I eat rice',
        hint: 'Start with who does the action',
        level: 1,
        domain: 'Sentence Structure',
        emoji: '🍚'
      },
      {
        words: ['plays', 'Brother', 'ball'],
        correctOrder: [1, 0, 2], // Brother plays ball
        correctSentence: 'Brother plays ball',
        hint: 'Subject + verb + object',
        level: 1,
        domain: 'Sentence Structure',
        emoji: '⚽'
      },
      {
        words: ['book', 'reads', 'Mom'],
        correctOrder: [2, 1, 0], // Mom reads book
        correctSentence: 'Mom reads book',
        hint: 'Start with the subject',
        level: 1,
        domain: 'Sentence Structure',
        emoji: '📚'
      },
      {
        words: ['sleeps', 'Cat', 'on', 'bed'],
        correctOrder: [1, 0, 2, 3], // Cat sleeps on bed
        correctSentence: 'Cat sleeps on bed',
        hint: 'Subject + verb + place',
        level: 1,
        domain: 'Sentence Structure',
        emoji: '🐱'
      },
      
      // Level 2: Sentences with Details
      {
        words: ['happily', 'We', 'play', 'games'],
        correctOrder: [1, 2, 3, 0], // We play games happily
        correctSentence: 'We play games happily',
        hint: 'Add description at the end',
        level: 2,
        domain: 'Complete Sentences',
        emoji: '😊'
      },
      {
        words: ['in', 'Birds', 'fly', 'sky', 'the'],
        correctOrder: [1, 2, 3, 4, 0], // Birds fly in the sky
        correctSentence: 'Birds fly in the sky',
        hint: 'Don\'t forget the place',
        level: 2,
        domain: 'Complete Sentences',
        emoji: '🐦'
      },
      {
        words: ['Dad', 'car', 'to', 'drives', 'work'],
        correctOrder: [0, 3, 1, 2, 4], // Dad drives car to work
        correctSentence: 'Dad drives car to work',
        hint: 'Subject + verb + object + destination',
        level: 2,
        domain: 'Complete Sentences',
        emoji: '🚗'
      },
      
      // Level 3: Complex Sentences
      {
        words: ['because', 'happy', 'I', 'raining', 'play', 'am'],
        correctOrder: [2, 5, 1, 4, 0, 3], // I am happy because raining play
        correctSentence: 'I am happy to play because it\'s raining',
        hint: 'Use connecting words',
        level: 3,
        domain: 'Complex Sentences',
        emoji: '🌧️'
      },
      {
        words: ['and', 'Lion', 'big', 'strong', 'very', 'is'],
        correctOrder: [1, 5, 4, 2, 3, 0], // Lion is very big and strong
        correctSentence: 'Lion is very big and strong',
        hint: 'Connect two descriptions',
        level: 3,
        domain: 'Complex Sentences',
        emoji: '🦁'
      },
      
      // Level 4: Story Sentences
      {
        words: ['morning', 'Every', 'school', 'walk', 'to', 'I'],
        correctOrder: [1, 0, 5, 3, 4, 2], // Every morning I walk to school
        correctSentence: 'Every morning I walk to school',
        hint: 'Time + subject + activity + destination',
        level: 4,
        domain: 'Narrative Sentences',
        emoji: '🏫'
      },
      {
        words: ['park', 'Yesterday', 'played', 'we', 'in', 'the'],
        correctOrder: [1, 3, 2, 4, 5, 0], // Yesterday we played in the park
        correctSentence: 'Yesterday we played in the park',
        hint: 'Tell about the past',
        level: 4,
        domain: 'Narrative Sentences',
        emoji: '🎈'
      }
    ]
  };

  // Sound effects
  const generateGameSound = (frequency: number, duration: number, type: 'success' | 'error' | 'click' | 'complete' = 'click') => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      switch (type) {
        case 'success':
          oscillator.frequency.setValueAtTime(523, audioContext.currentTime);
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1);
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.2);
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
          break;
        case 'error':
          oscillator.frequency.value = 220;
          oscillator.type = 'sawtooth';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
          break;
        case 'click':
          oscillator.frequency.value = 800;
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
          break;
        case 'complete':
          oscillator.frequency.setValueAtTime(523, audioContext.currentTime);
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.15);
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.3);
          oscillator.frequency.setValueAtTime(1047, audioContext.currentTime + 0.45);
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.8);
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
    if (gameState === 'playing' && !currentProblem) {
      generateNewProblem();
    }
  }, [gameState, currentProblem, language, currentLevel]);

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setCorrectAnswers(0);
    setWrongAnswers(0);
    setTimeLeft(90);
    setCurrentLevel(1);
    setStartTime(Date.now());
    setTotalQuestions(0);
    setGameSessionData([]);
    setSelectedWords([]);
    setUsedQuestions([]);
    generateNewProblem();
    generateGameSound(440, 0.3, 'click');
  };

  const generateNewProblem = () => {
    const problems = storyProblems[language];
    const levelProblems = problems.filter(p => p.level === currentLevel);
    
    // Filter out used questions
    const availableProblems = levelProblems.filter((_, index) => {
      const globalIndex = problems.indexOf(levelProblems[index]);
      return !usedQuestions.includes(globalIndex);
    });
    
    // If no unused problems, move to next level or reset
    if (availableProblems.length === 0) {
      if (currentLevel < 4) {
        setCurrentLevel(prev => prev + 1);
        return;
      } else {
        setUsedQuestions([]);
        setCurrentLevel(1);
        return;
      }
    }
    
    const problem = availableProblems[Math.floor(Math.random() * availableProblems.length)];
    const originalIndex = problems.indexOf(problem);
    
    // Mark this question as used
    setUsedQuestions(prev => [...prev, originalIndex]);
    setCurrentProblem(problem);
    
    // Shuffle words
    const shuffled = [...problem.words].sort(() => Math.random() - 0.5);
    setAvailableWords(shuffled);
    setSelectedWords([]);
    setTotalQuestions(prev => prev + 1);
  };

  const handleWordClick = (word: string, fromAvailable: boolean) => {
    generateGameSound(800, 0.1, 'click');
    
    if (fromAvailable) {
      setSelectedWords(prev => [...prev, word]);
      setAvailableWords(prev => {
        const index = prev.indexOf(word);
        return [...prev.slice(0, index), ...prev.slice(index + 1)];
      });
    } else {
      const index = selectedWords.indexOf(word);
      setSelectedWords(prev => [...prev.slice(0, index), ...prev.slice(index + 1)]);
      setAvailableWords(prev => [...prev, word]);
    }
  };

  const checkAnswer = () => {
    if (!currentProblem || selectedWords.length === 0) return;
    
    const isCorrect = selectedWords.join(' ') === currentProblem.correctSentence;
    
    // Show feedback
    setFeedback({
      show: true,
      isCorrect: isCorrect,
      correctAnswer: currentProblem.correctSentence
    });
    
    if (isCorrect) {
      setScore(prev => prev + 15);
      setCorrectAnswers(prev => {
        const newCorrectAnswers = prev + 1;
        // Level up every 3 correct answers
        if (newCorrectAnswers % 3 === 0 && currentLevel < 4) {
          setCurrentLevel(prevLevel => prevLevel + 1);
        }
        return newCorrectAnswers;
      });
      generateGameSound(523, 0.6, 'success');
      addSticker('story-builder');
    } else {
      setWrongAnswers(prev => prev + 1);
      generateGameSound(220, 0.4, 'error');
    }

    // Save session data
    setGameSessionData(prev => [...prev, {
      problem: currentProblem.words.join(', '),
      correctAnswer: currentProblem.correctSentence,
      selectedAnswer: selectedWords.join(' '),
      isCorrect: isCorrect,
      domain: currentProblem.domain,
      timeSpent: Date.now() - startTime,
      level: currentLevel,
      language: language
    }]);

    // Move to next problem
    setTimeout(() => {
      setCurrentProblem(null);
      setFeedback(null);
    }, 2500);
  };

  const resetCurrentProblem = () => {
    if (currentProblem) {
      const shuffled = [...currentProblem.words].sort(() => Math.random() - 0.5);
      setAvailableWords(shuffled);
      setSelectedWords([]);
    }
  };

  const endGame = () => {
    setGameState('completed');
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    
    // Domain analysis
    const domainAnalysis = gameSessionData.reduce((acc: any, session) => {
      const domain = session.domain;
      if (!acc[domain]) {
        acc[domain] = { correct: 0, total: 0 };
      }
      acc[domain].total++;
      if (session.isCorrect) {
        acc[domain].correct++;
      }
      return acc;
    }, {});

    // Update test results
    if (updateTestResults) {
      updateTestResults('linguistic', {
        score: correctAnswers,
        total: totalQuestions,
        percentage: accuracy,
        timeSpent: totalTime,
        gameMode: 'Story Builder',
        language: language,
        level: currentLevel,
        categoryScores: {
          receptive: Math.round((accuracy / 100) * 25),
          expressive: Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 25),
          phonemic: Math.round((currentLevel / 4) * 25)
        },
        domainAnalysis: domainAnalysis,
        detailedResults: {
          accuracy: accuracy,
          averageResponseTime: gameSessionData.length > 0 
            ? gameSessionData.reduce((sum, s) => sum + s.timeSpent, 0) / gameSessionData.length / 1000
            : 0,
          levelReached: currentLevel,
          strongestDomain: Object.keys(domainAnalysis).reduce((a, b) => 
            (domainAnalysis[a]?.correct / domainAnalysis[a]?.total || 0) > 
            (domainAnalysis[b]?.correct / domainAnalysis[b]?.total || 0) ? a : b, 
            Object.keys(domainAnalysis)[0] || 'Struktur Kalimat'
          ),
          languageTested: language === 'id' ? 'Bahasa Indonesia' : 'English'
        }
      });
    }

    // Update game assessment
    if (updateGameAssessment) {
      updateGameAssessment('storyBuilderGame', {
        score: score,
        timeSpent: totalTime,
        errors: wrongAnswers,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Linguistik'
      });
    }

    // Award stickers
    if (accuracy >= 90) addSticker('sentence-master');
    if (correctAnswers >= 10) addSticker('story-teller');
    if (currentLevel >= 4) addSticker('grammar-expert');
    addSticker('story-builder-complete');
    
    generateGameSound(523, 1.2, 'complete');
  };

  // Menu Screen
  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-green-300 via-emerald-400 to-teal-600 relative overflow-hidden">
        {/* Background elements */}
        <div className="absolute inset-0">
          <div className="absolute bottom-0 w-full h-40 bg-gradient-to-t from-teal-700 to-teal-500"></div>
          <div className="absolute bottom-20 left-6 text-4xl animate-float-slow">📖</div>
          <div className="absolute bottom-32 right-8 text-3xl animate-float-medium">✍️</div>
          <div className="absolute top-20 left-10 text-2xl animate-twinkle">📝</div>
          <div className="absolute top-32 right-12 text-3xl animate-float-slow">📚</div>
        </div>

        <div className="relative z-10 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => navigateTo('linguistic-test')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">Story Builder</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              📖
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Susun Kalimat yang Benar!
            </h2>
            <p className="text-green-100 text-base mb-8">
              Latih kemampuan menyusun kata menjadi kalimat yang sempurna!
            </p>

            {/* Language Selection */}
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Pilih Bahasa:</h3>
              <div className="grid grid-cols-2 gap-4">
                <motion.button
                  onClick={() => setLanguage('id')}
                  className={`p-4 rounded-xl font-body ${
                    language === 'id'
                      ? 'bg-white text-emerald-600'
                      : 'bg-white/20 text-white'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  🇮🇩 Bahasa Indonesia
                </motion.button>
                <motion.button
                  onClick={() => setLanguage('en')}
                  className={`p-4 rounded-xl font-body ${
                    language === 'en'
                      ? 'bg-white text-emerald-600'
                      : 'bg-white/20 text-white'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  🇬🇧 English
                </motion.button>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="w-full bg-white text-emerald-600 py-4 px-6 rounded-2xl font-heading text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              📖 Mulai Bermain!
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  // Playing Screen
  if (gameState === 'playing') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-green-200 via-emerald-300 to-teal-500 relative">
        {/* Header */}
        <div className="px-6 pt-14 pb-4">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              onClick={() => navigateTo('linguistic-test')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <div className="text-white text-center">
              <div className="font-heading font-bold text-lg">Story Builder</div>
              <div className="text-white/80 text-sm">Level {currentLevel}</div>
            </div>
            <div className="text-right text-white">
              <div className="font-heading font-bold text-2xl">{score}</div>
              <div className="text-white/80 text-sm">Skor</div>
            </div>
          </div>

          {/* Status Bar */}
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4 mb-4">
            <div className="flex justify-between items-center">
              <div className="flex items-center space-x-2">
                <Clock className="w-5 h-5 text-emerald-200" />
                <span className="text-white font-medium">{timeLeft}s</span>
              </div>
              <div className="flex items-center space-x-2">
                <Star className="w-5 h-5 text-yellow-300" />
                <span className="text-white font-medium">{correctAnswers} / {totalQuestions}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Game Area */}
        {currentProblem && (
          <div className="px-6 pb-8">
            {/* Problem Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl p-6 mb-6 shadow-lg"
            >
              <div className="flex items-center justify-center mb-4">
                <span className="text-6xl">{currentProblem.emoji}</span>
              </div>
              <h3 className="text-gray-900 font-heading text-lg mb-2 text-center">
                Susun kata-kata ini:
              </h3>
              <p className="text-gray-600 text-sm text-center mb-4">
                💡 {currentProblem.hint}
              </p>
            </motion.div>

            {/* Selected Words Area */}
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-4 min-h-32">
              <h4 className="text-white font-heading text-sm mb-3">Kalimat Kamu:</h4>
              <div className="flex flex-wrap gap-2 min-h-16">
                {selectedWords.length === 0 ? (
                  <p className="text-white/60 text-sm italic">Pilih kata-kata di bawah...</p>
                ) : (
                  selectedWords.map((word, index) => (
                    <motion.button
                      key={`selected-${index}`}
                      onClick={() => handleWordClick(word, false)}
                      className="bg-white text-emerald-600 px-4 py-2 rounded-xl font-body shadow-sm"
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                    >
                      {word}
                    </motion.button>
                  ))
                )}
              </div>
            </div>

            {/* Available Words */}
            <div className="bg-white rounded-2xl p-6 mb-4">
              <h4 className="text-gray-700 font-heading text-sm mb-3">Kata-kata Tersedia:</h4>
              <div className="flex flex-wrap gap-2">
                {availableWords.map((word, index) => (
                  <motion.button
                    key={`available-${index}`}
                    onClick={() => handleWordClick(word, true)}
                    className="bg-emerald-100 text-emerald-700 px-4 py-2 rounded-xl font-body border-2 border-emerald-300"
                    whileHover={{ scale: 1.05, backgroundColor: '#d1fae5' }}
                    whileTap={{ scale: 0.95 }}
                  >
                    {word}
                  </motion.button>
                ))}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex space-x-3 mb-4">
              <motion.button
                onClick={resetCurrentProblem}
                disabled={!!feedback}
                className="flex-1 bg-white/20 backdrop-blur-sm text-white py-3 px-6 rounded-2xl font-heading disabled:opacity-50"
                whileHover={!feedback ? { scale: 1.02 } : {}}
                whileTap={!feedback ? { scale: 0.98 } : {}}
              >
                🔄 Reset
              </motion.button>
              <motion.button
                onClick={checkAnswer}
                disabled={selectedWords.length === 0 || !!feedback}
                className={`flex-1 py-3 px-6 rounded-2xl font-heading ${
                  selectedWords.length === 0 || feedback
                    ? 'bg-gray-300 text-gray-500'
                    : 'bg-white text-emerald-600 shadow-lg'
                }`}
                whileHover={selectedWords.length > 0 && !feedback ? { scale: 1.02 } : {}}
                whileTap={selectedWords.length > 0 && !feedback ? { scale: 0.98 } : {}}
              >
                ✓ Cek Jawaban
              </motion.button>
            </div>

            {/* Feedback Display */}
            <AnimatePresence>
              {feedback && (
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className={`rounded-2xl p-6 shadow-lg ${
                    feedback.isCorrect
                      ? 'bg-green-500'
                      : 'bg-red-500'
                  }`}
                >
                  <div className="text-center">
                    <div className="text-5xl mb-3">
                      {feedback.isCorrect ? '🎉' : '💡'}
                    </div>
                    <h3 className="text-white font-heading text-xl mb-2">
                      {feedback.isCorrect ? 'Benar! Hebat!' : 'Belum Tepat!'}
                    </h3>
                    {!feedback.isCorrect && (
                      <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4 mt-3">
                        <p className="text-white text-sm mb-2">Jawaban yang benar:</p>
                        <p className="text-white font-heading text-lg">
                          {feedback.correctAnswer}
                        </p>
                      </div>
                    )}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )}
      </div>
    );
  }

  // Completion Screen
  if (gameState === 'completed') {
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;

    return (
      <div className="min-h-screen bg-gradient-to-b from-green-300 via-emerald-400 to-teal-600 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Hebat, {childName}!</h1>
            <p className="text-green-100 text-lg">
              Kamu telah menyelesaikan Story Builder!
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
          </div>

          <div className="space-y-3">
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
              onClick={() => setGameState('menu')}
              className="w-full bg-white text-emerald-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Main Lagi
            </motion.button>

            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7 }}
              onClick={() => navigateTo('linguistic-test')}
              className="w-full bg-white/20 backdrop-blur-sm text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg border-2 border-white/30"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Kembali ke Menu
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
