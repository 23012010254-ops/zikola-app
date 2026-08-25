import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, CheckCircle, Clock, Volume2, Target, Globe } from 'lucide-react';

interface LinguisticTestScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment?: (gameType: string, sessionData: any) => void;
}

export default function LinguisticTestScreen({ navigateTo, addSticker, childName, updateTestResults, updateGameAssessment }: LinguisticTestScreenProps) {
  const [gameState, setGameState] = useState<'menu' | 'options' | 'playing' | 'completed'>('menu');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [timeLeft, setTimeLeft] = useState(60);
  const [currentProblem, setCurrentProblem] = useState<any>(null);
  const [selectedWords, setSelectedWords] = useState<string[]>([]);
  const [availableWords, setAvailableWords] = useState<string[]>([]);
  const [language, setLanguage] = useState<'id' | 'en'>('id');
  const [startTime, setStartTime] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [draggedWord, setDraggedWord] = useState<string | null>(null);
  const [dropZones, setDropZones] = useState<(string | null)[]>([]);
  const [usedQuestions, setUsedQuestions] = useState<number[]>([]);

  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Soal bahasa untuk anak usia 8-9 tahun
  const languageProblems = {
    id: [
      // Level 1: Kata benda sederhana
      { 
        sentence: "Kucing itu _ di atas kasur", 
        answer: "tidur", 
        options: ["tidur", "makan", "berlari", "terbang"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang dilakukan kucing di kasur?"
      },
      { 
        sentence: "Aku _ apel merah yang manis", 
        answer: "makan", 
        options: ["makan", "tidur", "bermain", "menyanyi"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang kita lakukan dengan apel?"
      },
      { 
        sentence: "Burung _ di langit biru", 
        answer: "terbang", 
        options: ["terbang", "berenang", "berlari", "tidur"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang dilakukan burung di langit?"
      },
      
      // Level 2: Kata sifat
      { 
        sentence: "Gajah adalah hewan yang sangat _", 
        answer: "besar", 
        options: ["besar", "kecil", "cepat", "lambat"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Bagaimana ukuran gajah?"
      },
      { 
        sentence: "Es krim rasanya sangat _ dan manis", 
        answer: "dingin", 
        options: ["dingin", "panas", "asam", "pahit"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Bagaimana suhu es krim?"
      },
      { 
        sentence: "Matahari bersinar sangat _ hari ini", 
        answer: "terang", 
        options: ["terang", "gelap", "dingin", "basah"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Bagaimana cahaya matahari?"
      },
      
      // Level 3: Preposisi
      { 
        sentence: "Buku ada _ atas meja", 
        answer: "di", 
        options: ["di", "ke", "dari", "untuk"], 
        level: 3, 
        domain: 'Preposisi',
        hint: "Kata depan untuk menunjukkan tempat"
      },
      { 
        sentence: "Kami pergi _ sekolah pagi ini", 
        answer: "ke", 
        options: ["ke", "di", "dari", "dengan"], 
        level: 3, 
        domain: 'Preposisi',
        hint: "Kata depan untuk menunjukkan tujuan"
      },
      { 
        sentence: "Ayah pulang _ kantor sore hari", 
        answer: "dari", 
        options: ["dari", "ke", "di", "untuk"], 
        level: 3, 
        domain: 'Preposisi',
        hint: "Kata depan untuk menunjukkan asal"
      },
      
      // Level 4: Konjungsi
      { 
        sentence: "Aku suka apel _ jeruk", 
        answer: "dan", 
        options: ["dan", "atau", "tetapi", "karena"], 
        level: 4, 
        domain: 'Konjungsi',
        hint: "Kata penghubung untuk menambahkan"
      },
      { 
        sentence: "Hari ini hujan _ aku tetap berangkat", 
        answer: "tetapi", 
        options: ["tetapi", "dan", "atau", "karena"], 
        level: 4, 
        domain: 'Konjungsi',
        hint: "Kata penghubung untuk menunjukkan pertentangan"
      },
      
      // More Level 1: Basic verbs
      { 
        sentence: "Ikan _ di dalam air", 
        answer: "berenang", 
        options: ["berenang", "terbang", "berlari", "melompat"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang dilakukan ikan di air?"
      },
      { 
        sentence: "Anak-anak _ bola di halaman", 
        answer: "bermain", 
        options: ["bermain", "makan", "tidur", "belajar"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang dilakukan dengan bola?"
      },
      { 
        sentence: "Ayah _ mobil ke kantor", 
        answer: "mengendarai", 
        options: ["mengendarai", "membawa", "mendorong", "menarik"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang dilakukan dengan mobil?"
      },
      { 
        sentence: "Adik _ susu setiap pagi", 
        answer: "minum", 
        options: ["minum", "makan", "bermain", "belajar"], 
        level: 1, 
        domain: 'Kata Kerja',
        hint: "Apa yang dilakukan dengan susu?"
      },
      
      // More Level 2: Adjectives
      { 
        sentence: "Semut adalah serangga yang sangat _", 
        answer: "kecil", 
        options: ["kecil", "besar", "tinggi", "gemuk"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Bagaimana ukuran semut?"
      },
      { 
        sentence: "Singa memiliki suara yang sangat _", 
        answer: "keras", 
        options: ["keras", "pelan", "lembut", "merdu"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Bagaimana suara singa?"
      },
      { 
        sentence: "Bunga mawar berwarna _ dan harum", 
        answer: "merah", 
        options: ["merah", "hitam", "abu-abu", "coklat"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Warna apa yang umum untuk mawar?"
      },
      { 
        sentence: "Air laut rasanya sangat _", 
        answer: "asin", 
        options: ["asin", "manis", "asam", "pahit"], 
        level: 2, 
        domain: 'Kata Sifat',
        hint: "Bagaimana rasa air laut?"
      },
      
      // More Level 3: Prepositions
      { 
        sentence: "Kupu-kupu hinggap _ bunga", 
        answer: "di", 
        options: ["di", "ke", "dari", "untuk"], 
        level: 3, 
        domain: 'Preposisi',
        hint: "Kata depan untuk menunjukkan tempat"
      },
      { 
        sentence: "Burung terbang _ langit", 
        answer: "di", 
        options: ["di", "ke", "dari", "untuk"], 
        level: 3, 
        domain: 'Preposisi',
        hint: "Kata depan untuk menunjukkan tempat"
      },
      { 
        sentence: "Kami berlari _ taman", 
        answer: "ke", 
        options: ["ke", "di", "dari", "untuk"], 
        level: 3, 
        domain: 'Preposisi',
        hint: "Kata depan untuk menunjukkan tujuan"
      },
      
      // More Level 4: Conjunctions
      { 
        sentence: "Aku lapar _ aku akan makan", 
        answer: "karena", 
        options: ["karena", "tetapi", "dan", "atau"], 
        level: 4, 
        domain: 'Konjungsi',
        hint: "Kata penghubung untuk menunjukkan sebab"
      },
      { 
        sentence: "Kamu mau es krim _ permen?", 
        answer: "atau", 
        options: ["atau", "dan", "tetapi", "karena"], 
        level: 4, 
        domain: 'Konjungsi',
        hint: "Kata penghubung untuk pilihan"
      }
    ],
    en: [
      // Level 1: Simple verbs
      { 
        sentence: "The cat _ on the bed", 
        answer: "sleeps", 
        options: ["sleeps", "eats", "runs", "flies"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What does a cat do on a bed?"
      },
      { 
        sentence: "I _ a red apple", 
        answer: "eat", 
        options: ["eat", "sleep", "play", "sing"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What do we do with an apple?"
      },
      { 
        sentence: "Birds _ in the sky", 
        answer: "fly", 
        options: ["fly", "swim", "run", "sleep"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What do birds do in the sky?"
      },
      
      // Level 2: Adjectives
      { 
        sentence: "Elephants are very _ animals", 
        answer: "big", 
        options: ["big", "small", "fast", "slow"], 
        level: 2, 
        domain: 'Adjectives',
        hint: "What size are elephants?"
      },
      { 
        sentence: "Ice cream is _ and sweet", 
        answer: "cold", 
        options: ["cold", "hot", "sour", "bitter"], 
        level: 2, 
        domain: 'Adjectives',
        hint: "What temperature is ice cream?"
      },
      
      // Level 3: Prepositions
      { 
        sentence: "The book is _ the table", 
        answer: "on", 
        options: ["on", "in", "under", "beside"], 
        level: 3, 
        domain: 'Prepositions',
        hint: "Where is the book in relation to the table?"
      },
      { 
        sentence: "We go _ school every morning", 
        answer: "to", 
        options: ["to", "at", "from", "with"], 
        level: 3, 
        domain: 'Prepositions',
        hint: "Which direction do we go to school?"
      },
      
      // Level 4: Conjunctions
      { 
        sentence: "I like apples _ oranges", 
        answer: "and", 
        options: ["and", "or", "but", "because"], 
        level: 4, 
        domain: 'Conjunctions',
        hint: "Word to connect two things you like"
      },
      { 
        sentence: "It's raining _ I will go outside", 
        answer: "but", 
        options: ["but", "and", "or", "because"], 
        level: 4, 
        domain: 'Conjunctions',
        hint: "Word showing contrast"
      },
      
      // More Level 1: Basic verbs
      { 
        sentence: "Fish _ in the water", 
        answer: "swim", 
        options: ["swim", "fly", "run", "jump"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What do fish do in water?"
      },
      { 
        sentence: "Children _ games in the park", 
        answer: "play", 
        options: ["play", "eat", "sleep", "study"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What do children do with games?"
      },
      { 
        sentence: "My mom _ delicious food", 
        answer: "cooks", 
        options: ["cooks", "eats", "sleeps", "runs"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What does mom do with food?"
      },
      { 
        sentence: "Students _ their homework", 
        answer: "do", 
        options: ["do", "eat", "sleep", "fly"], 
        level: 1, 
        domain: 'Verbs',
        hint: "What do students do with homework?"
      },
      
      // More Level 2: Adjectives
      { 
        sentence: "Mice are very _ animals", 
        answer: "small", 
        options: ["small", "big", "tall", "fat"], 
        level: 2, 
        domain: 'Adjectives',
        hint: "What size are mice?"
      },
      { 
        sentence: "Lions have a very _ voice", 
        answer: "loud", 
        options: ["loud", "quiet", "soft", "sweet"], 
        level: 2, 
        domain: 'Adjectives',
        hint: "How does a lion's voice sound?"
      },
      { 
        sentence: "Snow is very _ and white", 
        answer: "cold", 
        options: ["cold", "hot", "warm", "cool"], 
        level: 2, 
        domain: 'Adjectives',
        hint: "What temperature is snow?"
      },
      { 
        sentence: "The ocean is very _ and blue", 
        answer: "deep", 
        options: ["deep", "shallow", "narrow", "short"], 
        level: 2, 
        domain: 'Adjectives',
        hint: "How far down does the ocean go?"
      },
      
      // More Level 3: Prepositions
      { 
        sentence: "The cat sleeps _ the bed", 
        answer: "on", 
        options: ["on", "in", "under", "beside"], 
        level: 3, 
        domain: 'Prepositions',
        hint: "Where does the cat sleep in relation to the bed?"
      },
      { 
        sentence: "We walk _ the park every day", 
        answer: "in", 
        options: ["in", "on", "under", "beside"], 
        level: 3, 
        domain: 'Prepositions',
        hint: "Where do we walk?"
      },
      { 
        sentence: "The ball is _ the table", 
        answer: "under", 
        options: ["under", "on", "in", "beside"], 
        level: 3, 
        domain: 'Prepositions',
        hint: "Where is the ball in relation to the table?"
      },
      
      // More Level 4: Conjunctions
      { 
        sentence: "I am tired _ I will sleep", 
        answer: "so", 
        options: ["so", "but", "and", "or"], 
        level: 4, 
        domain: 'Conjunctions',
        hint: "Word showing result"
      },
      { 
        sentence: "Do you want juice _ water?", 
        answer: "or", 
        options: ["or", "and", "but", "so"], 
        level: 4, 
        domain: 'Conjunctions',
        hint: "Word for giving choices"
      }
    ]
  };

  // Generate game sounds
  const generateGameSound = (frequency: number, duration: number, type: 'bubble' | 'success' | 'error' | 'splash' | 'complete' = 'bubble') => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      switch (type) {
        case 'bubble':
          oscillator.frequency.value = 600;
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
          break;
        case 'success':
          oscillator.frequency.setValueAtTime(523, audioContext.currentTime); // C5
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1); // E5
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.2); // G5
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
        case 'splash':
          oscillator.frequency.value = 400;
          oscillator.type = 'triangle';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
          break;
        case 'complete':
          // Play celebration notes
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
    setTimeLeft(60);
    setCurrentLevel(1);
    setStartTime(Date.now());
    setTotalQuestions(0);
    setGameSessionData([]);
    setSelectedWords([]);
    setDropZones([]);
    setUsedQuestions([]); // Reset used questions
    generateNewProblem();
    generateGameSound(400, 0.4, 'splash');
  };

  const generateNewProblem = () => {
    const problems = languageProblems[language];
    const levelProblems = problems.filter(p => p.level === currentLevel);
    
    // Filter out used questions
    const availableProblems = levelProblems.filter((_, index) => {
      const globalIndex = problems.indexOf(levelProblems[index]);
      return !usedQuestions.includes(globalIndex);
    });
    
    // If no unused problems for current level, move to next level or reset
    if (availableProblems.length === 0) {
      if (currentLevel < 4) {
        setCurrentLevel(prev => prev + 1);
        return; // Let useEffect handle the new level
      } else {
        // Reset used questions if all levels are exhausted
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
    
    // Setup drag and drop
    const sentenceParts = problem.sentence.split('_');
    setDropZones(Array(sentenceParts.length - 1).fill(null));
    setAvailableWords([...problem.options]);
    setSelectedWords([]);
    setTotalQuestions(prev => prev + 1);
  };

  const handleDragStart = (word: string) => {
    setDraggedWord(word);
    generateGameSound(600, 0.2, 'bubble');
  };

  const handleDragEnd = () => {
    setDraggedWord(null);
  };

  const handleDrop = (dropIndex: number) => {
    if (draggedWord && dropZones[dropIndex] === null) {
      const newDropZones = [...dropZones];
      newDropZones[dropIndex] = draggedWord;
      setDropZones(newDropZones);
      
      // Remove word from available words
      setAvailableWords(prev => prev.filter(w => w !== draggedWord));
      setSelectedWords(prev => [...prev, draggedWord]);
      
      // Check if answer is correct
      checkAnswer(draggedWord);
      setDraggedWord(null);
    }
  };

  const checkAnswer = (selectedWord: string) => {
    const isCorrect = selectedWord === currentProblem.answer;
    
    if (isCorrect) {
      setScore(prev => prev + 10);
      setCorrectAnswers(prev => {
        const newCorrectAnswers = prev + 1;
        // Level up every 3 correct answers
        if (newCorrectAnswers % 3 === 0 && currentLevel < 4) {
          setCurrentLevel(prevLevel => prevLevel + 1);
        }
        return newCorrectAnswers;
      });
      generateGameSound(523, 0.6, 'success');
      addSticker('linguistic-word-master');
    } else {
      setWrongAnswers(prev => prev + 1);
      generateGameSound(220, 0.4, 'error');
    }

    // Save session data
    setGameSessionData(prev => [...prev, {
      question: currentProblem.sentence,
      correctAnswer: currentProblem.answer,
      selectedAnswer: selectedWord,
      isCorrect: isCorrect,
      domain: currentProblem.domain,
      timeSpent: Date.now() - startTime,
      level: currentLevel,
      language: language
    }]);

    // Move to next problem after delay
    setTimeout(() => {
      setCurrentProblem(null); // This will trigger useEffect to generate new problem
    }, 1500);
  };

  const resetCurrentProblem = () => {
    if (currentProblem) {
      setDropZones(Array(currentProblem.sentence.split('_').length - 1).fill(null));
      setAvailableWords([...currentProblem.options]);
      setSelectedWords([]);
    }
  };

  const endGame = () => {
    setGameState('completed');
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    
    // Analisis domain
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
    updateTestResults('linguistic', {
      score: correctAnswers,
      total: totalQuestions,
      percentage: accuracy,
      timeSpent: totalTime,
      gameMode: 'Ocean Word Adventure',
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
          Object.keys(domainAnalysis)[0] || 'Kata Kerja'
        ),
        languageTested: language === 'id' ? 'Bahasa Indonesia' : 'English'
      }
    });

    // Update game assessment
    if (updateGameAssessment) {
      updateGameAssessment('linguisticGame', {
        score: score,
        timeSpent: totalTime,
        errors: wrongAnswers,
        level: currentLevel,
        accuracy: accuracy,
        domain: 'Bahasa dan Linguistik'
      });
    }

    // Award stickers
    if (accuracy >= 90) addSticker('linguistic-expert');
    if (correctAnswers >= 10) addSticker('word-master');
    if (currentLevel >= 4) addSticker('grammar-champion');
    addSticker('linguistic-test-complete');
    
    generateGameSound(523, 1.2, 'complete');
  };

  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-cyan-300 via-blue-400 to-blue-600 relative overflow-hidden">
        {/* Ocean background */}
        <div className="absolute inset-0">
          <div className="absolute bottom-0 w-full h-40 bg-gradient-to-t from-blue-700 to-blue-500"></div>
          <div className="absolute bottom-20 left-6 text-4xl animate-float-slow">🐠</div>
          <div className="absolute bottom-32 right-8 text-3xl animate-float-medium">🐟</div>
          <div className="absolute top-20 left-10 text-2xl animate-twinkle">🌊</div>
          <div className="absolute top-32 right-12 text-3xl animate-float-slow">🐙</div>
          <div className="absolute bottom-40 left-1/3 text-2xl animate-float-medium">🦀</div>
        </div>

        <div className="relative z-10 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => navigateTo('home')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">Tes Linguistik</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🌊
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Pilih Aktivitas Linguistik
            </h2>
            <p className="text-cyan-100 text-base mb-8">
              Asah kemampuan bahasa dengan berbagai permainan menarik!
            </p>

            {/* Game Options */}
            <div className="space-y-4">
              <motion.button
                onClick={() => setGameState('options')}
                className="w-full bg-white/15 backdrop-blur-sm rounded-2xl p-6 border border-white/20 hover:bg-white/20 transition-all"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
              >
                <div className="text-5xl mb-3">🐸</div>
                <h3 className="text-white font-heading text-lg mb-2">
                  1. Petualangan Kata
                </h3>
                <p className="text-cyan-100 text-sm">
                  Seret kata yang tepat untuk melengkapi kalimat
                </p>
              </motion.button>

              <motion.button
                onClick={() => navigateTo('word-puzzle-game')}
                className="w-full bg-white/15 backdrop-blur-sm rounded-2xl p-6 border border-white/20 hover:bg-white/20 transition-all"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
              >
                <div className="text-5xl mb-3">📝</div>
                <h3 className="text-white font-heading text-lg mb-2">
                  2. Teka-Teki Kata
                </h3>
                <p className="text-cyan-100 text-sm">
                  Susun huruf menjadi kata yang benar dengan petunjuk gambar
                </p>
              </motion.button>

              <motion.button
                onClick={() => navigateTo('story-builder-game')}
                className="w-full bg-white/15 backdrop-blur-sm rounded-2xl p-6 border border-white/20 hover:bg-white/20 transition-all"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
              >
                <div className="text-5xl mb-3">📖</div>
                <h3 className="text-white font-heading text-lg mb-2">
                  3. Story Builder
                </h3>
                <p className="text-cyan-100 text-sm">
                  Susun kata-kata menjadi kalimat yang benar dan sempurna
                </p>
              </motion.button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (gameState === 'options') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-cyan-300 via-blue-400 to-blue-600 relative overflow-hidden">
        {/* Ocean background */}
        <div className="absolute inset-0">
          <div className="absolute bottom-0 w-full h-40 bg-gradient-to-t from-blue-700 to-blue-500"></div>
          <div className="absolute bottom-20 left-6 text-4xl animate-float-slow">🐠</div>
          <div className="absolute bottom-32 right-8 text-3xl animate-float-medium">🐟</div>
          <div className="absolute top-20 left-10 text-2xl animate-twinkle">🌊</div>
          <div className="absolute top-32 right-12 text-3xl animate-float-slow">🐙</div>
          <div className="absolute bottom-40 left-1/3 text-2xl animate-float-medium">🦀</div>
        </div>

        <div className="relative z-10 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => navigateTo('home')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">Tes Linguistik - Ocean Word Adventure</h1>
            <div className="w-10" />
          </div>

          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              className="text-8xl mb-6"
            >
              🐸
            </motion.div>
            <h2 className="text-white font-heading text-2xl mb-4">
              Petualangan Kata di Lautan!
            </h2>
            <p className="text-cyan-100 text-base mb-8">
              Seret kata yang tepat untuk melengkapi kalimat dan bantu kodok mencapai tujuan!
            </p>

            {/* Language Selection */}
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-6">
              <h3 className="text-white font-heading text-lg mb-4">Pilih Bahasa:</h3>
              <div className="flex space-x-4 justify-center">
                <motion.button
                  onClick={() => setLanguage('id')}
                  className={`px-6 py-3 rounded-xl font-medium transition-all ${
                    language === 'id' 
                      ? 'bg-white text-blue-600 shadow-lg' 
                      : 'bg-white/20 text-white hover:bg-white/30'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  🇮🇩 Bahasa Indonesia
                </motion.button>
                <motion.button
                  onClick={() => setLanguage('en')}
                  className={`px-6 py-3 rounded-xl font-medium transition-all ${
                    language === 'en' 
                      ? 'bg-white text-blue-600 shadow-lg' 
                      : 'bg-white/20 text-white hover:bg-white/30'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  🇺🇸 English
                </motion.button>
              </div>
            </div>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-cyan-500 rounded-full flex items-center justify-center">
                    <Target className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-cyan-100">Seret kata ke tempat yang kosong</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                    <Clock className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-cyan-100">Selesaikan dalam 60 detik</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <Volume2 className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-cyan-100">Dengarkan suara gelembung laut!</span>
                </div>
              </div>
            </div>

            <motion.button
              onClick={startGame}
              className="bg-gradient-to-r from-cyan-500 to-blue-600 text-white px-8 py-4 rounded-2xl font-heading text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🌊 Mulai Petualangan!
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  if (gameState === 'completed') {
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    
    return (
      <div className="min-h-screen bg-gradient-to-b from-cyan-300 via-blue-400 to-blue-600">
        <div className="px-6 pt-14 pb-8 text-center">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="text-8xl mb-6"
          >
            🏆
          </motion.div>
          
          <h1 className="text-white font-heading text-2xl mb-4">
            Petualangan Selesai, {childName}!
          </h1>
          
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{correctAnswers}</div>
                <div className="text-cyan-100 text-sm">Kata Benar</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{accuracy}%</div>
                <div className="text-cyan-100 text-sm">Akurasi</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{currentLevel}</div>
                <div className="text-cyan-100 text-sm">Level Tertinggi</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{score}</div>
                <div className="text-cyan-100 text-sm">Total Skor</div>
              </div>
            </div>

            <div className="text-left space-y-2 mb-4">
              <h4 className="text-white font-heading text-base mb-2">Analisis Kemampuan:</h4>
              <div className="text-cyan-100 text-sm">
                • Pemahaman Kata: {Math.round((accuracy / 100) * 25)}/25
              </div>
              <div className="text-cyan-100 text-sm">
                • Tata Bahasa: {Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 25)}/25
              </div>
              <div className="text-cyan-100 text-sm">
                • Kemampuan Adaptasi: {Math.round((currentLevel / 4) * 25)}/25
              </div>
              <div className="text-cyan-100 text-sm">
                • Bahasa Digunakan: {language === 'id' ? 'Bahasa Indonesia' : 'English'}
              </div>
            </div>

            {accuracy >= 90 && (
              <div className="bg-green-500/20 border border-green-400/30 rounded-xl p-4 mb-4">
                <div className="text-green-100 font-medium">🌟 Excellent! Kemampuan bahasamu sangat baik!</div>
              </div>
            )}
            
            {accuracy >= 70 && accuracy < 90 && (
              <div className="bg-blue-500/20 border border-blue-400/30 rounded-xl p-4 mb-4">
                <div className="text-blue-100 font-medium">👍 Good! Terus latih kemampuan bahasamu!</div>
              </div>
            )}
            
            {accuracy < 70 && (
              <div className="bg-purple-500/20 border border-purple-400/30 rounded-xl p-4 mb-4">
                <div className="text-purple-100 font-medium">💪 Keep practicing! Kemampuan bahasamu akan terus berkembang!</div>
              </div>
            )}
          </div>

          <div className="space-y-3">
            <motion.button
              onClick={() => setGameState('menu')}
              className="w-full bg-gradient-to-r from-cyan-500 to-blue-600 text-white py-3 px-6 rounded-xl font-medium"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              🔄 Main Lagi
            </motion.button>
            
            <motion.button
              onClick={() => navigateTo('progress')}
              className="w-full bg-white/20 text-white py-3 px-6 rounded-xl font-medium"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              📊 Lihat Progress Dashboard
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  // Playing state
  return (
    <div className="min-h-screen bg-gradient-to-b from-cyan-300 via-blue-400 to-blue-600 relative overflow-hidden">
      {/* Ocean background */}
      <div className="absolute inset-0">
        <div className="absolute bottom-0 w-full h-32 bg-gradient-to-t from-blue-700 to-blue-500"></div>
        <div className="absolute bottom-16 left-4 text-2xl animate-float-slow">🐠</div>
        <div className="absolute bottom-20 right-6 text-2xl animate-float-medium">🐟</div>
        <div className="absolute top-20 right-8 text-3xl animate-twinkle">🌊</div>
      </div>

      {/* Game HUD */}
      <div className="relative z-20 px-6 pt-14 pb-4">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-2 rounded-xl bg-white/20 backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-4 h-4 text-white" />
          </motion.button>
          <div className="flex items-center space-x-3">
            <div className="text-white font-heading text-xs">BENAR: {correctAnswers}</div>
            <div className="text-cyan-100 font-heading text-xs">SALAH: {wrongAnswers}</div>
            <div className="text-blue-100 font-heading text-xs">AKURASI: {Math.round((correctAnswers / Math.max(totalQuestions, 1)) * 100)}%</div>
          </div>
          <div className="flex items-center space-x-2">
            <Clock className="w-4 h-4 text-white" />
            <span className="text-white font-heading">{timeLeft}s</span>
          </div>
        </div>

        <div className="text-center mb-6">
          <div className="text-white text-sm mb-2">Level {currentLevel} • Skor: {score}</div>
          <div className="text-cyan-100 text-xs">
            {language === 'id' ? 'Bahasa Indonesia' : 'English'} • {currentProblem?.domain}
          </div>
        </div>
      </div>

      {/* Game Area */}
      <div className="relative px-6 mb-8">
        {/* Sentence with drop zones */}
        <div className="bg-white rounded-2xl p-6 mb-6 border-2 border-cyan-200 shadow-lg">
          <div className="text-center mb-4">
            <div className="text-gray-900 font-heading text-xl mb-4 font-bold">
              Lengkapi kalimat:
            </div>
            {currentProblem && (
              <div className="text-gray-900 text-lg font-bold flex flex-wrap items-center justify-center gap-3">
                {currentProblem.sentence.split('_').map((part: string, index: number) => (
                  <React.Fragment key={index}>
                    <span>{part}</span>
                    {index < currentProblem.sentence.split('_').length - 1 && (
                      <div
                        className="min-w-[90px] h-10 bg-gray-100 border-2 border-dashed border-gray-500 rounded-lg flex items-center justify-center text-base font-bold text-gray-800 transition-all hover:bg-gray-200 hover:border-cyan-400"
                        onDragOver={(e) => e.preventDefault()}
                        onDrop={(e) => {
                          e.preventDefault();
                          handleDrop(index);
                        }}
                      >
                        {dropZones[index] || '___'}
                      </div>
                    )}
                  </React.Fragment>
                ))}
              </div>
            )}
          </div>
          
          {currentProblem?.hint && (
            <div className="text-center text-blue-700 text-base font-bold">
              💡 {currentProblem.hint}
            </div>
          )}
        </div>

        {/* Frog Character */}
        <div className="text-center mb-6">
          <motion.div
            className="text-8xl"
            animate={{ 
              scale: [1, 1.1, 1],
              rotate: [0, 5, -5, 0]
            }}
            transition={{ 
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          >
            🐸
          </motion.div>
        </div>

        {/* Available words */}
        <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
          <h3 className="text-white font-heading text-center mb-4">Pilih Kata:</h3>
          <div className="grid grid-cols-2 gap-3">
            {availableWords.map((word, index) => (
              <motion.div
                key={`${word}-${index}`}
                draggable
                onDragStart={() => handleDragStart(word)}
                onDragEnd={handleDragEnd}
                className="bg-gradient-to-r from-purple-600 to-pink-600 text-white py-4 px-5 rounded-xl text-center font-bold text-lg cursor-grab active:cursor-grabbing shadow-lg hover:shadow-xl transform hover:scale-105 transition-all border-2 border-white"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
              >
                {word}
              </motion.div>
            ))}
          </div>
        </div>

        {/* Reset button */}
        {selectedWords.length > 0 && (
          <div className="text-center mt-4">
            <motion.button
              onClick={resetCurrentProblem}
              className="bg-white/20 text-white py-2 px-4 rounded-xl font-medium"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🔄 Reset
            </motion.button>
          </div>
        )}
      </div>

      <audio ref={audioRef} preload="auto" />
    </div>
  );
}