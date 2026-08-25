import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, CheckCircle, Clock, Volume2, Target, Brain } from 'lucide-react';

interface CognitiveTestScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

export default function CognitiveTestScreen({ navigateTo, addSticker, childName, updateTestResults, updateGameAssessment }: CognitiveTestScreenProps) {
  const [gameState, setGameState] = useState<'menu' | 'categorySelect' | 'gameSelect' | 'playing' | 'completed'>('menu');
  const [selectedCategory, setSelectedCategory] = useState<'logic' | 'memory' | 'abstract'>('logic');
  const [currentLevel, setCurrentLevel] = useState(1);
  const [score, setScore] = useState(0);
  const [hits, setHits] = useState(0);
  const [misses, setMisses] = useState(0);
  const [timeLeft, setTimeLeft] = useState(60);
  const [currentProblem, setCurrentProblem] = useState<any>(null);
  const [targets, setTargets] = useState<any[]>([]);
  const [cannonAngle, setCannonAngle] = useState(0);
  const [isShootingAnimation, setIsShootingAnimation] = useState(false);
  const [startTime, setStartTime] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [wrongAnswers, setWrongAnswers] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Soal logika dan abstraksi untuk anak usia 8-9 tahun
  const logicProblems = [
    // Level 1: Logic sederhana
    { question: 'Semua kucing suka ikan. Mimi kucing. Mimi suka...?', answer: 'Ikan', options: ['Ikan', 'Daging', 'Sayur', 'Buah'], level: 1, domain: 'Logic' },
    { question: 'Mobil punya roda. Ferrari mobil. Ferrari punya...?', answer: 'Roda', options: ['Roda', 'Sayap', 'Sirip', 'Kaki'], level: 1, domain: 'Logic' },
    { question: 'Buah manis dimakan burung. Mangga manis. Mangga...?', answer: 'Dimakan burung', options: ['Dimakan burung', 'Jadi asam', 'Membusuk', 'Tumbuh'], level: 1, domain: 'Logic' },
    { question: 'Ikan hidup di air. Nemo ikan. Nemo hidup di...?', answer: 'Air', options: ['Air', 'Darat', 'Udara', 'Pohon'], level: 1, domain: 'Logic' },
    { question: 'Burung bisa terbang. Elang burung. Elang bisa...?', answer: 'Terbang', options: ['Terbang', 'Berenang', 'Menggali', 'Berlari'], level: 1, domain: 'Logic' },
    
    // Level 2: Pattern Recognition  
    { question: '🔴🔵🔴🔵🔴? Apa selanjutnya?', answer: '🔵', options: ['🔵', '🔴', '🟡', '⚫'], level: 2, domain: 'Pattern' },
    { question: '1, 3, 5, 7, ? Selanjutnya?', answer: '9', options: ['9', '8', '10', '11'], level: 2, domain: 'Pattern' },
    { question: '⭐🌙⭐🌙⭐? Selanjutnya?', answer: '🌙', options: ['🌙', '⭐', '☀️', '🌟'], level: 2, domain: 'Pattern' },
    { question: '2, 4, 6, 8, ? Selanjutnya?', answer: '10', options: ['10', '9', '12', '7'], level: 2, domain: 'Pattern' },
    { question: 'AB, CD, EF, ? Selanjutnya?', answer: 'GH', options: ['GH', 'IJ', 'EF', 'CD'], level: 2, domain: 'Pattern' },
    
    // Level 3: Abstract Thinking
    { question: 'A=1, B=2, C=3. CAB=?', answer: '312', options: ['312', '123', '321', '213'], level: 3, domain: 'Abstract' },
    { question: '🔺+🔺=🔴, 🔴+🔺=?', answer: '🔵', options: ['🔵', '🔴', '🔺', '⭐'], level: 3, domain: 'Abstract' },
    { question: '🟦=1, 🟨=2, 🟩=3. 🟨🟩🟦=?', answer: '231', options: ['231', '123', '321', '132'], level: 3, domain: 'Abstract' },
    { question: '15 - 8', answer: 7, level: 3, domain: 'Mixed' },
    { question: '9 + 3', answer: 12, level: 3, domain: 'Mixed' },
    
    // Level 4: Perkalian/pembagian sederhana
    { question: '2 × 3', answer: 6, level: 4, domain: 'Multiplication' },
    { question: '10 ÷ 2', answer: 5, level: 4, domain: 'Division' },
    { question: '3 × 2', answer: 6, level: 4, domain: 'Multiplication' },
    { question: '12 ÷ 3', answer: 4, level: 4, domain: 'Division' },
    { question: '4 × 2', answer: 8, level: 4, domain: 'Multiplication' }
  ];

  // Suara game
  const playSound = (type: 'shoot' | 'hit' | 'miss' | 'levelup' | 'complete') => {
    if (audioRef.current) {
      switch (type) {
        case 'shoot':
          // Bunyi tembakan
          audioRef.current.src = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuB0fDccy0FJIDf8dNwKwQriM7tyEgFIARAq+DLNBYdWKPI';
          break;
        case 'hit':
          // Bunyi target terkena
          audioRef.current.src = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBz/DCdSsFJIDJ8dx2LgUsetz0v2whBjiS2e/EeCQKKXPN+9eNPgkZZ7z';
          break;
      }
      audioRef.current.play().catch(() => {});
    }
  };

  // Generate suara game menggunakan Web Audio API
  const generateGameSound = (frequency: number, duration: number, type: 'shoot' | 'hit' | 'miss' | 'levelup' | 'start' = 'shoot') => {
    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      // Different sounds for different actions
      switch (type) {
        case 'shoot':
          oscillator.frequency.value = 300;
          oscillator.type = 'square';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
          break;
        case 'hit':
          oscillator.frequency.value = 523; // C5
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
          break;
        case 'miss':
          oscillator.frequency.value = 220; // A3
          oscillator.type = 'sawtooth';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
          break;
        case 'levelup':
          // Play ascending notes
          oscillator.frequency.setValueAtTime(523, audioContext.currentTime); // C5
          oscillator.frequency.setValueAtTime(659, audioContext.currentTime + 0.1); // E5
          oscillator.frequency.setValueAtTime(784, audioContext.currentTime + 0.2); // G5
          oscillator.type = 'sine';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
          break;
        case 'start':
          oscillator.frequency.value = 440; // A4
          oscillator.type = 'triangle';
          gainNode.gain.setValueAtTime(0.2, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
          break;
        default:
          oscillator.frequency.value = frequency;
          oscillator.type = 'square';
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
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
  }, [gameState, currentProblem]);

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setHits(0);
    setMisses(0);
    setTimeLeft(60);
    setCurrentLevel(1);
    setStartTime(Date.now());
    setTotalQuestions(0);
    setCorrectAnswers(0);
    setWrongAnswers(0);
    setGameSessionData([]);
    generateNewProblem();
    generateGameSound(440, 0.3, 'start'); // Start sound
  };

  const generateNewProblem = () => {
    const levelProblems = logicProblems.filter(p => p.level === currentLevel);
    const problem = levelProblems[Math.floor(Math.random() * levelProblems.length)];
    setCurrentProblem(problem);
    
    // For logic problems, we use predefined options instead of generating wrong answers
    const allOptions = [...problem.options];
    
    // Shuffle options
    for (let i = allOptions.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [allOptions[i], allOptions[j]] = [allOptions[j], allOptions[i]];
    }
    
    // Create targets with options
    const newTargets = allOptions.map((option, index) => ({
      id: index,
      answer: option,
      isCorrect: option === problem.answer,
      x: 10 + (index * 20), // Spread across screen
      y: 15 + Math.random() * 20, // Random height
      destroyed: false,
      color: index % 2 === 0 ? 'red' : 'yellow'
    }));
    
    setTargets(newTargets);
    setTotalQuestions(prev => prev + 1);
  };

  const shootTarget = (targetId: number) => {
    const target = targets.find(t => t.id === targetId);
    if (!target || target.destroyed || isShootingAnimation) return;

    setIsShootingAnimation(true);
    generateGameSound(300, 0.2, 'shoot'); // Shoot sound

    // Animate cannon
    const targetElement = document.getElementById(`target-${targetId}`);
    if (targetElement) {
      const rect = targetElement.getBoundingClientRect();
      const containerRect = document.getElementById('game-area')?.getBoundingClientRect();
      if (containerRect) {
        const targetX = rect.left - containerRect.left;
        const angle = Math.atan2(rect.top - containerRect.bottom + 100, targetX - containerRect.width / 2) * 180 / Math.PI;
        setCannonAngle(angle);
      }
    }

    setTimeout(() => {
      setTargets(prev => prev.map(t => 
        t.id === targetId ? { ...t, destroyed: true } : t
      ));

      if (target.isCorrect) {
        setScore(prev => prev + 10);
        setHits(prev => prev + 1);
        setCorrectAnswers(prev => prev + 1);
        generateGameSound(523, 0.4, 'hit'); // Success sound
        addSticker('cognitive-shooter');
        
        // Level up every 5 correct answers
        if ((correctAnswers + 1) % 5 === 0 && currentLevel < 4) {
          setCurrentLevel(prev => prev + 1);
          generateGameSound(659, 0.6, 'levelup'); // Level up sound
        }
      } else {
        setMisses(prev => prev + 1);
        setWrongAnswers(prev => prev + 1);
        generateGameSound(220, 0.3, 'miss'); // Miss sound
      }

      // Save session data
      setGameSessionData(prev => [...prev, {
        question: currentProblem.question,
        correctAnswer: currentProblem.answer,
        selectedAnswer: target.answer,
        isCorrect: target.isCorrect,
        domain: currentProblem.domain,
        timeSpent: Date.now() - startTime,
        level: currentLevel
      }]);

      setTimeout(() => {
        setIsShootingAnimation(false);
        generateNewProblem();
      }, 1000);
    }, 500);
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

    // Update test results dengan analisis lengkap
    updateTestResults('cognitive', {
      score: correctAnswers,
      total: totalQuestions,
      percentage: accuracy,
      timeSpent: totalTime,
      gameMode: 'Math Shooter',
      level: currentLevel,
      categoryScores: {
        logic: Math.round((accuracy / 100) * 25),
        attention: Math.round((hits / Math.max(hits + misses, 1)) * 25),
        memory: Math.round((currentLevel / 4) * 25)
      },
      domainAnalysis: domainAnalysis,
      detailedResults: {
        totalShots: hits + misses,
        accuracy: accuracy,
        averageResponseTime: gameSessionData.length > 0 
          ? gameSessionData.reduce((sum, s) => sum + s.timeSpent, 0) / gameSessionData.length / 1000
          : 0,
        levelReached: currentLevel,
        strongestDomain: Object.keys(domainAnalysis).reduce((a, b) => 
          (domainAnalysis[a]?.correct / domainAnalysis[a]?.total || 0) > 
          (domainAnalysis[b]?.correct / domainAnalysis[b]?.total || 0) ? a : b, 
          Object.keys(domainAnalysis)[0] || 'Addition'
        )
      }
    });

    // Update game assessment
    updateGameAssessment('cognitiveGame', {
      score: score,
      timeSpent: totalTime,
      errors: wrongAnswers,
      level: currentLevel,
      accuracy: accuracy,
      domain: 'Matematika Kognitif'
    });

    // Award stickers
    if (accuracy >= 90) addSticker('math-sharpshooter');
    if (hits >= 15) addSticker('target-master');
    if (currentLevel >= 4) addSticker('level-champion');
    addSticker('cognitive-test-complete');
    
    generateGameSound(523, 1); // Completion sound
  };

  if (gameState === 'categorySelect') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-purple-400 via-purple-500 to-purple-600">
        <div className="px-6 pt-14 pb-8">
          {/* Header */}
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => setGameState('menu')}
              className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">Pilih Kategori</h1>
            <div className="w-10"></div>
          </div>

          <div className="space-y-4">
            {/* Logic Category */}
            <motion.div
              onClick={() => {
                setSelectedCategory('logic');
                setGameState('gameSelect');
              }}
              className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20 cursor-pointer"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="flex items-center space-x-4">
                <div className="text-4xl">🎯</div>
                <div className="flex-1">
                  <h3 className="text-white font-heading text-lg mb-1">Logika & Penalaran</h3>
                  <p className="text-purple-100 text-sm">Game matematika dan logika</p>
                  <div className="flex items-center space-x-2 mt-2">
                    <span className="text-xs bg-white/20 text-white px-2 py-1 rounded-full">Matematika</span>
                    <span className="text-xs bg-white/20 text-white px-2 py-1 rounded-full">Logika</span>
                  </div>
                </div>
                <ArrowLeft className="w-5 h-5 text-white rotate-180" />
              </div>
            </motion.div>

            {/* Memory Category */}
            <motion.div
              onClick={() => {
                setSelectedCategory('memory');
                setGameState('gameSelect');
              }}
              className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20 cursor-pointer"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="flex items-center space-x-4">
                <div className="text-4xl">🧠</div>
                <div className="flex-1">
                  <h3 className="text-white font-heading text-lg mb-1">Memori & Konsentrasi</h3>
                  <p className="text-purple-100 text-sm">Latih daya ingat dan fokus</p>
                  <div className="flex items-center space-x-2 mt-2">
                    <span className="text-xs bg-white/20 text-white px-2 py-1 rounded-full">Memori</span>
                    <span className="text-xs bg-white/20 text-white px-2 py-1 rounded-full">Konsentrasi</span>
                  </div>
                </div>
                <ArrowLeft className="w-5 h-5 text-white rotate-180" />
              </div>
            </motion.div>

            {/* Abstract Category */}
            <motion.div
              onClick={() => {
                setSelectedCategory('abstract');
                setGameState('gameSelect');
              }}
              className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20 cursor-pointer"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="flex items-center space-x-4">
                <div className="text-4xl">🔮</div>
                <div className="flex-1">
                  <h3 className="text-white font-heading text-lg mb-1">Abstraksi & Pola Visual</h3>
                  <p className="text-purple-100 text-sm">Mengenali pola dan berpikir abstrak</p>
                  <div className="flex items-center space-x-2 mt-2">
                    <span className="text-xs bg-white/20 text-white px-2 py-1 rounded-full">Pola</span>
                    <span className="text-xs bg-white/20 text-white px-2 py-1 rounded-full">Abstraksi</span>
                  </div>
                </div>
                <ArrowLeft className="w-5 h-5 text-white rotate-180" />
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    );
  }

  if (gameState === 'gameSelect') {
    const getCategoryGames = () => {
      switch (selectedCategory) {
        case 'logic':
          return [
            {
              id: 'alien-shooter',
              title: 'Alien Math Shooter',
              description: 'Selamatkan bumi dari alien dengan matematika lanjutan!',
              icon: '🛸',
              difficulty: 'Lanjutan',
              tags: ['Pecahan', 'Perkalian']
            },
            {
              id: 'desert-road-logic',
              title: 'Desert Road Logic',
              description: 'Pilih jalan yang benar dengan logika dan penalaran',
              icon: '🚗',
              difficulty: 'Sedang',
              tags: ['Logika', 'Penalaran']
            }
          ];
        case 'memory':
          return [
            {
              id: 'memory-cards',
              title: 'Memory Cards',
              description: 'Asah daya ingat dengan permainan kartu',
              icon: '🧠',
              difficulty: 'Sedang',
              tags: ['Memori', 'Konsentrasi']
            },
            {
              id: 'sequence-memory',
              title: 'Sequence Memory',
              description: 'Ingat dan ulangi urutan warna',
              icon: '🎯',
              difficulty: 'Sedang',
              tags: ['Urutan', 'Memori']
            },
            {
              id: 'number-memory',
              title: 'Number Memory',
              description: 'Ingat angka-angka yang muncul',
              icon: '🔢',
              difficulty: 'Lanjutan',
              tags: ['Angka', 'Memori']
            }
          ];
        case 'abstract':
          return [
            {
              id: 'pattern-recognition',
              title: 'Pola Visual',
              description: 'Asah kemampuan visual dengan mengenali pola',
              icon: '🎯',
              difficulty: 'Sedang',
              tags: ['Pola', 'Abstraksi']
            },
            {
              id: 'shape-sorting',
              title: 'Shape Sorting',
              description: 'Sortir bentuk berdasarkan kategori dengan cepat',
              icon: '🎨',
              difficulty: 'Sedang',
              tags: ['Abstraksi', 'Kategorisasi']
            },
            {
              id: 'mirror-pattern',
              title: 'Mirror Pattern',
              description: 'Temukan pola cermin yang tepat',
              icon: '🪞',
              difficulty: 'Lanjutan',
              tags: ['Spatial', 'Pola']
            }
          ];
        default:
          return [];
      }
    };

    const categoryGames = getCategoryGames();
    const categoryTitles = {
      logic: 'Logika & Penalaran',
      memory: 'Memori & Konsentrasi',
      abstract: 'Abstraksi & Pola Visual'
    };

    const handleGameClick = (gameId: string) => {
      switch (gameId) {
        case 'alien-shooter':
          navigateTo('alien-shooter');
          break;
        case 'desert-road-logic':
          navigateTo('desert-road-logic');
          break;
        case 'memory-cards':
          navigateTo('memory-game');
          break;
        case 'pattern-recognition':
          navigateTo('pattern-recognition-game');
          break;
        case 'shape-sorting':
          navigateTo('shape-sorting-game');
          break;
        case 'mirror-pattern':
          navigateTo('mirror-pattern-game');
          break;
        case 'sequence-memory':
          navigateTo('sequence-memory-game');
          break;
        case 'number-memory':
          navigateTo('number-memory-game');
          break;
        default:
          break;
      }
    };

    return (
      <div className="min-h-screen bg-gradient-to-b from-blue-200 via-blue-300 to-blue-400 relative overflow-hidden">
        <div className="relative z-10 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-8">
            <motion.button
              onClick={() => setGameState('categorySelect')}
              className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-white" />
            </motion.button>
            <h1 className="text-white font-heading text-xl">{categoryTitles[selectedCategory]}</h1>
            <div className="w-10" />
          </div>

          <div className="space-y-6 mb-8">
            {categoryGames.map((game) => (
              <motion.div
                key={game.id}
                onClick={() => handleGameClick(game.id)}
                className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 cursor-pointer"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <div className="flex items-center space-x-4">
                  <div className="text-6xl">{game.icon}</div>
                  <div className="flex-1">
                    <h3 className="text-white font-heading text-lg mb-2">{game.title}</h3>
                    <p className="text-blue-100 text-sm mb-2">
                      {game.description}
                    </p>
                    <div className="flex items-center space-x-2">
                      <div className="bg-green-500/20 px-2 py-1 rounded text-green-200 text-xs">Level: {game.difficulty}</div>
                      {game.tags.map((tag) => (
                        <div key={tag} className="bg-blue-500/20 px-2 py-1 rounded text-blue-200 text-xs">{tag}</div>
                      ))}
                    </div>
                  </div>
                  <div className="text-white/60">
                    <ArrowLeft className="w-5 h-5 transform rotate-180" />
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          <div className="text-center">
            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4">
              <p className="text-blue-100 text-sm">
                💡 Pilih game sesuai kemampuan kognitif {childName}
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (gameState === 'menu') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-blue-200 via-blue-300 to-blue-400 relative overflow-hidden">
        {/* Brain background */}
        <div className="absolute inset-0">
          <div className="absolute bottom-0 w-full h-32 bg-gradient-to-t from-purple-200 to-purple-100"></div>
          <div className="absolute bottom-16 left-8 text-4xl">🧠</div>
          <div className="absolute bottom-12 right-12 text-3xl">🎯</div>
          <div className="absolute top-16 right-8 text-6xl animate-spin-slow">💡</div>
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
            <h1 className="text-white font-heading text-xl">Tes Kognitif</h1>
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
              Latih Kemampuan Kognitif!
            </h2>
            <p className="text-orange-100 text-base mb-8">
              Pilih kategori untuk melatih berbagai aspek kemampuan kognitifmu!
            </p>

            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
              <h3 className="text-white font-heading text-lg mb-4">Area Kognitif:</h3>
              <div className="space-y-3 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                    <Target className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-blue-100">Logika & Penalaran</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                    <Brain className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-blue-100">Memori & Konsentrasi</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                    <CheckCircle className="w-4 h-4 text-white" />
                  </div>
                  <span className="text-blue-100">Abstraksi & Pola Visual</span>
                </div>
              </div>
            </div>

            <motion.button
              onClick={() => setGameState('categorySelect')}
              className="bg-gradient-to-r from-blue-500 to-blue-600 text-white px-8 py-4 rounded-2xl font-heading text-lg shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              🧠 Pilih Kategori Kognitif!
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
      <div className="min-h-screen bg-gradient-to-b from-blue-200 via-blue-300 to-blue-400">
        <div className="px-6 pt-14 pb-8 text-center">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="text-8xl mb-6"
          >
            🏆
          </motion.div>
          
          <h1 className="text-white font-heading text-2xl mb-4">
            Tes Kognitif Selesai, {childName}!
          </h1>
          
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 mb-8">
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{hits}</div>
                <div className="text-orange-100 text-sm">Target Terkena</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{accuracy}%</div>
                <div className="text-orange-100 text-sm">Akurasi</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{currentLevel}</div>
                <div className="text-orange-100 text-sm">Level Tertinggi</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-heading text-white mb-1">{score}</div>
                <div className="text-orange-100 text-sm">Total Skor</div>
              </div>
            </div>

            <div className="text-left space-y-2 mb-4">
              <h4 className="text-white font-heading text-base mb-2">Analisis Kemampuan:</h4>
              <div className="text-blue-100 text-sm">
                • Logika & Matematika: {Math.round((accuracy / 100) * 25)}/25
              </div>
              <div className="text-blue-100 text-sm">
                • Perhatian & Fokus: {Math.round((hits / Math.max(hits + misses, 1)) * 25)}/25
              </div>
              <div className="text-blue-100 text-sm">
                • Kemampuan Adaptasi: {Math.round((currentLevel / 4) * 25)}/25
              </div>
              <div className="text-blue-100 text-sm">
                • Waktu Bermain: {totalTime} detik
              </div>
            </div>

            {accuracy >= 90 && (
              <div className="bg-green-500/20 border border-green-400/30 rounded-xl p-4 mb-4">
                <div className="text-green-100 font-medium">🌟 Excellent! Kemampuan kognitifmu sangat baik!</div>
              </div>
            )}
            
            {accuracy >= 70 && accuracy < 90 && (
              <div className="bg-blue-500/20 border border-blue-400/30 rounded-xl p-4 mb-4">
                <div className="text-blue-100 font-medium">👍 Good! Terus latih kemampuan kognitifmu!</div>
              </div>
            )}
            
            {accuracy < 70 && (
              <div className="bg-purple-500/20 border border-purple-400/30 rounded-xl p-4 mb-4">
                <div className="text-purple-100 font-medium">💪 Keep practicing! Kemampuan kognitifmu akan terus berkembang!</div>
              </div>
            )}
          </div>

          <div className="space-y-3">
            <motion.button
              onClick={() => setGameState('menu')}
              className="w-full bg-gradient-to-r from-blue-500 to-blue-600 text-white py-3 px-6 rounded-xl font-medium"
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

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-200 via-blue-300 to-blue-400 relative overflow-hidden">
      {/* Desert background */}
      <div className="absolute inset-0">
        <div className="absolute bottom-0 w-full h-24 bg-gradient-to-t from-yellow-200 to-yellow-100"></div>
        <div className="absolute bottom-12 left-4 text-3xl">🌵</div>
        <div className="absolute bottom-8 right-6 text-2xl">🌵</div>
        <div className="absolute top-8 right-4 text-5xl animate-spin-slow">☀️</div>
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
          <div className="flex items-center space-x-4">
            <div className="text-white font-heading text-sm">HIT: {hits}</div>
            <div className="text-blue-100 font-heading text-sm">MISS: {misses}</div>
            <div className="text-green-200 font-heading text-sm">RATE: {Math.round((hits / Math.max(hits + misses, 1)) * 100)}%</div>
          </div>
          <div className="flex items-center space-x-2">
            <Clock className="w-4 h-4 text-white" />
            <span className="text-white font-heading">{timeLeft}s</span>
          </div>
        </div>

        <div className="text-center mb-4">
          <div className="text-white text-xl font-heading mb-1">
            {currentProblem?.question}
          </div>
          <div className="text-blue-100 text-sm">Level {currentLevel} • Skor: {score}</div>
        </div>
      </div>

      {/* Game Area */}
      <div id="game-area" className="relative h-80 mx-6">
        {/* Target Cars */}
        {targets.map((target) => (
          <motion.button
            key={target.id}
            id={`target-${target.id}`}
            onClick={() => shootTarget(target.id)}
            className={`absolute w-20 h-16 rounded-lg ${
              target.destroyed 
                ? 'bg-gray-600' 
                : target.color === 'red' 
                  ? 'bg-red-600 hover:bg-red-700 border-red-500' 
                  : 'bg-green-600 hover:bg-green-700 border-green-500'
            } flex flex-col items-center justify-center text-white font-heading text-base font-bold shadow-lg border-2`}
            style={{
              left: `${target.x}%`,
              top: `${target.y}%`,
            }}
            initial={{ scale: 0, x: -100 }}
            animate={{ 
              scale: target.destroyed ? 0 : 1,
              x: target.destroyed ? 100 : 0,
              rotate: target.destroyed ? 180 : 0
            }}
            transition={{ duration: 0.5 }}
            disabled={target.destroyed || isShootingAnimation}
          >
            {target.destroyed ? '💥' : (
              <>
                <div className="text-xs">{target.answer}</div>
                <div className="text-2xl">🚗</div>
              </>
            )}
          </motion.button>
        ))}

        {/* Tank/Cannon */}
        <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2">
          <motion.div
            className="text-6xl"
            animate={{ 
              rotate: cannonAngle,
              scale: isShootingAnimation ? [1, 1.1, 1] : 1
            }}
            transition={{ duration: 0.3 }}
          >
            🎯
          </motion.div>
        </div>
      </div>

      {/* Instructions */}
      <div className="px-6 py-4">
        <div className="bg-white rounded-2xl p-5 text-center border-2 border-blue-200 shadow-lg">
          <div className="text-gray-900 font-heading text-lg font-bold">
            Tembak mobil dengan jawaban yang benar!
          </div>
        </div>
      </div>

      <audio ref={audioRef} preload="auto" />
    </div>
  );
}