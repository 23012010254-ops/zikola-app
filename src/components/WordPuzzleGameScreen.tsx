import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, RotateCcw, Trophy, Star, CheckCircle, Lightbulb, Shuffle } from 'lucide-react';

interface WordPuzzleGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

interface WordData {
  word: string;
  hint: string;
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
  imageUrl: string;
}

interface LetterTile {
  letter: string;
  id: number;
  isPlaced: boolean;
  correctPosition: number;
  currentPosition: number | null;
  isCorrect?: boolean;
}

export default function WordPuzzleGameScreen({ navigateTo, addSticker, updateGameAssessment }: WordPuzzleGameScreenProps) {
  const [gameStarted, setGameStarted] = useState(false);
  const [currentWordIndex, setCurrentWordIndex] = useState(0);
  const [letters, setLetters] = useState<LetterTile[]>([]);
  const [placedLetters, setPlacedLetters] = useState<(LetterTile | null)[]>([]);
  const [gameCompleted, setGameCompleted] = useState(false);
  const [score, setScore] = useState(0);
  const [hintsUsed, setHintsUsed] = useState(0);
  const [showHint, setShowHint] = useState(false);
  const [wordsCompleted, setWordsCompleted] = useState(0);
  const [timeElapsed, setTimeElapsed] = useState(0);
  const [isProcessingWord, setIsProcessingWord] = useState(false);
  const [gameStartTime, setGameStartTime] = useState(0);
  const [currentWordStartTime, setCurrentWordStartTime] = useState(0);
  const [errors, setErrors] = useState(0);
  const [showImage, setShowImage] = useState(true);

  // Memoize word data to prevent recreation on every render
  const wordData = useMemo<WordData[]>(() => [
    { 
      word: 'KUCING', 
      hint: 'Hewan peliharaan yang suka minum susu', 
      category: 'Hewan', 
      difficulty: 'easy',
      imageUrl: 'https://images.unsplash.com/photo-1701496966210-4eea1d7f7210?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjdXRlJTIwY2F0JTIwa2l0dGVufGVufDF8fHx8MTc1OTUxMjg4N3ww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'RUMAH', 
      hint: 'Tempat tinggal keluarga', 
      category: 'Tempat', 
      difficulty: 'easy',
      imageUrl: 'https://images.unsplash.com/photo-1756435292384-1bf32eff7baf?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2Rlcm4lMjBob3VzZSUyMGhvbWV8ZW58MXx8fHwxNzU5NTQ2MjMyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'BUNGA', 
      hint: 'Tumbuhan yang berwarna-warni dan harum', 
      category: 'Alam', 
      difficulty: 'easy',
      imageUrl: 'https://images.unsplash.com/photo-1564230259732-38be02d788df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2xvcmZ1bCUyMGZsb3dlcnMlMjBnYXJkZW58ZW58MXx8fHwxNzU5NTQ2MjM1fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'MATAHARI', 
      hint: 'Benda langit yang memberikan cahaya di siang hari', 
      category: 'Alam', 
      difficulty: 'medium',
      imageUrl: 'https://images.unsplash.com/photo-1721849282256-8e2b66f03f4e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxicmlnaHQlMjBzdW4lMjBzdW5zaGluZXxlbnwxfHx8fDE3NTk0MzY0MjF8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'SEKOLAH', 
      hint: 'Tempat anak-anak belajar bersama guru', 
      category: 'Tempat', 
      difficulty: 'easy',
      imageUrl: 'https://images.unsplash.com/photo-1699347914988-c61ec13c99c5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2hvb2wlMjBidWlsZGluZyUyMGVkdWNhdGlvbnxlbnwxfHx8fDE3NTk0MzA4NjN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'PELANGI', 
      hint: 'Lengkungan warna-warni yang muncul setelah hujan', 
      category: 'Alam', 
      difficulty: 'medium',
      imageUrl: 'https://images.unsplash.com/photo-1630416995029-b91cea387e31?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyYWluYm93JTIwc2t5JTIwY29sb3JmdWx8ZW58MXx8fHwxNzU5NTQ2MjQ1fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'BINTANG', 
      hint: 'Titik cahaya kecil yang terlihat di malam hari', 
      category: 'Alam', 
      difficulty: 'easy',
      imageUrl: 'https://images.unsplash.com/photo-1700979685622-1df98c74702f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdGFycnklMjBuaWdodCUyMHNreSUyMHN0YXJzfGVufDF8fHx8MTc1OTU0NjI0OHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'PESAWAT', 
      hint: 'Kendaraan yang bisa terbang di langit', 
      category: 'Kendaraan', 
      difficulty: 'medium',
      imageUrl: 'https://images.unsplash.com/photo-1683806900937-1695468e808b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhaXJwbGFuZSUyMGZseWluZyUyMHNreXxlbnwxfHx8fDE3NTk1NDU5NTF8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'MAKANAN', 
      hint: 'Yang kita makan setiap hari', 
      category: 'Kebutuhan', 
      difficulty: 'medium',
      imageUrl: 'https://images.unsplash.com/photo-1646299501330-c46c84c0c936?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkZWxpY2lvdXMlMjBmb29kJTIwbWVhbHxlbnwxfHx8fDE3NTk1NDYyNTV8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'KOMPUTER', 
      hint: 'Mesin pintar untuk bekerja dan belajar', 
      category: 'Teknologi', 
      difficulty: 'medium',
      imageUrl: 'https://images.unsplash.com/photo-1754928864131-21917af96dfd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2Rlcm4lMjBjb21wdXRlciUyMGxhcHRvcHxlbnwxfHx8fDE3NTk1NDYyNTh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'DINOSAURUS', 
      hint: 'Hewan purba raksasa yang sudah punah', 
      category: 'Hewan', 
      difficulty: 'hard',
      imageUrl: 'https://images.unsplash.com/photo-1719932617023-687af4067d14?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaW5vc2F1ciUyMGZvc3NpbCUyMGFuY2llbnR8ZW58MXx8fHwxNzU5NTQ2MjYyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    },
    { 
      word: 'PERPUSTAKAAN', 
      hint: 'Tempat menyimpan dan meminjam buku', 
      category: 'Tempat', 
      difficulty: 'hard',
      imageUrl: 'https://images.unsplash.com/photo-1660479123634-2c700dfbbbdb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsaWJyYXJ5JTIwYm9va3MlMjByZWFkaW5nfGVufDF8fHx8MTc1OTQ3NDIzNHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral'
    }
  ], []);

  const currentWord = wordData[currentWordIndex];

  // Initialize game
  useEffect(() => {
    if (gameStarted) {
      const word = wordData[currentWordIndex];
      if (!word) return;
      
      const wordLetters = word.word.split('').map((letter, index) => ({
        letter,
        id: index,
        isPlaced: false,
        correctPosition: index,
        currentPosition: null
      }));

      // Shuffle the letters
      const shuffledLetters = [...wordLetters].sort(() => Math.random() - 0.5);
      setLetters(shuffledLetters);
      setPlacedLetters(new Array(word.word.length).fill(null));
      setShowHint(false);
      setShowImage(true);
      setIsProcessingWord(false);
      setCurrentWordStartTime(Date.now());
    }
  }, [gameStarted, currentWordIndex, wordData]);

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (gameStarted && !gameCompleted) {
      interval = setInterval(() => {
        setTimeElapsed(prev => prev + 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [gameStarted, gameCompleted]);

  const handleLetterClick = useCallback((letter: LetterTile) => {
    if (letter.isPlaced) return;

    // Find the next empty slot
    const nextEmptyIndex = placedLetters.findIndex(slot => slot === null);
    if (nextEmptyIndex === -1) return;

    const updatedLetter = { ...letter, isPlaced: true, currentPosition: nextEmptyIndex };
    
    setLetters(prev => prev.map(l => l.id === letter.id ? updatedLetter : l));
    setPlacedLetters(prev => {
      const newPlaced = [...prev];
      newPlaced[nextEmptyIndex] = updatedLetter;
      return newPlaced;
    });
  }, [placedLetters]);

  const handlePlacedLetterClick = useCallback((position: number) => {
    const letter = placedLetters[position];
    if (!letter) return;

    const updatedLetter = { ...letter, isPlaced: false, currentPosition: null };
    
    setLetters(prev => prev.map(l => l.id === letter.id ? updatedLetter : l));
    setPlacedLetters(prev => {
      const newPlaced = [...prev];
      newPlaced[position] = null;
      return newPlaced;
    });
  }, [placedLetters]);

  // Check word completion when all letters are placed
  useEffect(() => {
    if (placedLetters.every(slot => slot !== null) && placedLetters.length > 0 && !isProcessingWord) {
      const formedWord = placedLetters.map(letter => letter?.letter || '').join('');
      const word = wordData[currentWordIndex];
      
      if (formedWord === word.word) {
        setIsProcessingWord(true);
        
        // Calculate word completion time
        const wordCompletionTime = Math.round((Date.now() - currentWordStartTime) / 1000);
        
        // Correct word! Add celebration effects
        let earnedScore = 100;
        if (hintsUsed === 0) earnedScore += 50; // Bonus for no text hints
        if (word.difficulty === 'medium') earnedScore += 25;
        if (word.difficulty === 'hard') earnedScore += 50;
        
        setScore(prev => prev + earnedScore);
        setWordsCompleted(prev => prev + 1);

        // Add celebration animation
        setPlacedLetters(prev => prev.map(letter => 
          letter ? { ...letter, isCorrect: true } : letter
        ));

        // Update assessment data for this word
        const sessionData = {
          timeSpent: wordCompletionTime,
          errors: errors,
          score: earnedScore,
          hintsUsed: hintsUsed, // Only count text hints
          difficulty: word.difficulty,
          timestamp: Date.now()
        };

        // Move to next word or complete game
        if (currentWordIndex < wordData.length - 1) {
          setTimeout(() => {
            setCurrentWordIndex(prev => prev + 1);
            setHintsUsed(0);
            setErrors(0);
            setIsProcessingWord(false);
          }, 2000);
        } else {
          // Game completed - send final assessment
          setTimeout(() => {
            updateGameAssessment('wordPuzzle', sessionData);
            setGameCompleted(true);
            addSticker('word-master');
            setIsProcessingWord(false);
          }, 2000);
        }
      } else {
        // Wrong answer - count as error
        setErrors(prev => prev + 1);
      }
    }
  }, [placedLetters, wordData, hintsUsed, currentWordIndex, isProcessingWord]);

  const shuffleLetters = () => {
    const availableLetters = letters.filter(l => !l.isPlaced);
    const shuffled = [...availableLetters].sort(() => Math.random() - 0.5);
    
    setLetters(prev => {
      const placed = prev.filter(l => l.isPlaced);
      return [...placed, ...shuffled];
    });
  };

  const useHint = () => {
    if (showHint) return;
    setShowHint(true);
    setHintsUsed(prev => prev + 1);
  };



  const resetCurrentWord = () => {
    const word = wordData[currentWordIndex];
    if (!word) return;
    
    const wordLetters = word.word.split('').map((letter, index) => ({
      letter,
      id: index,
      isPlaced: false,
      correctPosition: index,
      currentPosition: null
    }));

    // Shuffle the letters
    const shuffledLetters = [...wordLetters].sort(() => Math.random() - 0.5);
    setLetters(shuffledLetters);
    setPlacedLetters(new Array(word.word.length).fill(null));
    setShowHint(false);
    setIsProcessingWord(false);
  };

  const startGame = () => {
    setGameStarted(true);
    setTimeElapsed(0);
    setGameStartTime(Date.now());
    setCurrentWordStartTime(Date.now());
    setErrors(0);
  };

  const getStarRating = () => {
    const averageTimePerWord = timeElapsed / Math.max(wordsCompleted, 1);
    const hintsPerWord = hintsUsed / Math.max(wordsCompleted, 1);
    
    // Better scoring system: consider both time and hints
    if (averageTimePerWord <= 45 && hintsPerWord <= 1) return 3;
    if (averageTimePerWord <= 75 && hintsPerWord <= 2) return 2;
    return 1;
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Game completion screen
  if (gameCompleted) {
    const stars = getStarRating();
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-400 to-blue-500 flex items-center justify-center">
        <motion.div
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: "spring", stiffness: 200, damping: 15 }}
          className="bg-white rounded-3xl p-8 text-center max-w-sm mx-4 shadow-2xl"
        >
          <motion.div
            animate={{ 
              scale: [1, 1.2, 1], 
              rotate: [0, 10, -10, 0],
              y: [0, -10, 0]
            }}
            transition={{ duration: 0.8, repeat: 3 }}
            className="text-8xl mb-4 relative"
          >
            🏆
            {/* Confetti particles */}
            {[...Array(6)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute w-2 h-2 rounded-full"
                style={{
                  backgroundColor: ['#FFD700', '#FF69B4', '#00CED1', '#32CD32', '#FF6347', '#9370DB'][i],
                  left: `${20 + i * 10}%`,
                  top: `${30 + (i % 2) * 20}%`,
                }}
                animate={{
                  y: [0, -30, 20],
                  x: [0, (i - 3) * 15, 0],
                  rotate: [0, 360],
                  scale: [1, 1.5, 0],
                  opacity: [1, 1, 0]
                }}
                transition={{
                  duration: 1.5,
                  delay: i * 0.1,
                  repeat: Infinity,
                  repeatDelay: 1
                }}
              />
            ))}
          </motion.div>

          <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
            Luar Biasa! 🌟
          </h2>
          <p className="text-gray-600 font-body text-base mb-4">
            Kamu telah menyelesaikan semua teka-teki kata!
          </p>

          {/* Stars */}
          <div className="flex justify-center space-x-1 mb-4">
            {[1, 2, 3].map(star => (
              <Star 
                key={star}
                className={`w-8 h-8 ${star <= stars ? 'text-yellow-400 fill-current' : 'text-gray-200'}`}
              />
            ))}
          </div>

          {/* Stats */}
          <div className="bg-green-50 rounded-2xl p-4 mb-6">
            <div className="text-green-700 font-body text-sm space-y-1">
              <p>Kata Selesai: <span className="font-bold">{wordsCompleted}/{wordData.length}</span></p>
              <p>Total Waktu: <span className="font-bold">{formatTime(timeElapsed)}</span></p>
              <p>Rata-rata/Kata: <span className="font-bold">{Math.round(timeElapsed / Math.max(wordsCompleted, 1))} detik</span></p>
              <p>Total Hint: <span className="font-bold">{hintsUsed}</span></p>
            </div>
          </div>

          <div className="bg-yellow-50 rounded-2xl p-4 mb-6">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <Trophy className="w-5 h-5 text-yellow-600" />
              <span className="text-yellow-700 font-body font-semibold">
                Hadiah Diperoleh!
              </span>
            </div>
            <p className="text-yellow-600 font-body text-sm">
              Stiker "Word Master" ditambahkan ke koleksimu!
            </p>
          </div>

          <div className="flex space-x-3">
            <motion.button
              onClick={() => {
                setGameStarted(false);
                setGameCompleted(false);
                setCurrentWordIndex(0);
                setScore(0);
                setWordsCompleted(0);
                setTimeElapsed(0);
                setIsProcessingWord(false);
              }}
              className="flex-1 bg-green-500 text-white py-3 px-4 rounded-2xl font-heading font-bold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Main Lagi
            </motion.button>
            <motion.button
              onClick={() => navigateTo('game')}
              className="flex-1 bg-gray-500 text-white py-3 px-4 rounded-2xl font-heading font-bold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Kembali
            </motion.button>
          </div>
        </motion.div>
      </div>
    );
  }

  // Game start screen
  if (!gameStarted) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-green-500 to-blue-600 px-6 pt-14 pb-8">
          <div className="flex items-center justify-between mb-6">
            <motion.button
              onClick={() => navigateTo('game')}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </motion.button>
            <h1 className="text-white font-heading font-bold text-xl">Teka-Teki Kata</h1>
            <div className="w-10" />
          </div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
          >
            <h2 className="text-white font-heading font-semibold text-lg mb-2">
              Asah Kemampuan Kata! 📚
            </h2>
            <p className="text-green-100 font-body text-sm">
              Susun huruf menjadi kata yang benar dengan bantuan petunjuk!
            </p>
          </motion.div>
        </div>

        {/* Game Instructions */}
        <div className="px-6 -mt-4 pb-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl p-6 shadow-sm mb-6"
          >
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Cara Bermain:</h3>
            <div className="space-y-3">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                  <span className="text-green-600 font-bold text-sm">1</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Baca petunjuk untuk menebak kata</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                  <span className="text-green-600 font-bold text-sm">2</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Klik huruf untuk menyusun kata</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                  <span className="text-green-600 font-bold text-sm">3</span>
                </div>
                <p className="text-gray-600 font-body text-sm">Selesaikan semua kata untuk mendapat hadiah</p>
              </div>
            </div>
          </motion.div>

          {/* Difficulty Info */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-gradient-to-r from-blue-50 to-green-50 border border-blue-200 rounded-2xl p-6 mb-6"
          >
            <h3 className="text-blue-700 font-heading font-bold text-base mb-2">
              Target Bintang:
            </h3>
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-blue-600 font-body text-sm">3 Bintang ⭐⭐⭐</span>
                <span className="text-blue-600 font-body text-sm font-bold">≤ 45 detik/kata & ≤ 1 hint/kata</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-blue-600 font-body text-sm">2 Bintang ⭐⭐</span>
                <span className="text-blue-600 font-body text-sm font-bold">≤ 75 detik/kata & ≤ 2 hint/kata</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-blue-600 font-body text-sm">1 Bintang ⭐</span>
                <span className="text-blue-600 font-body text-sm font-bold">Selesaikan semua kata</span>
              </div>
            </div>
          </motion.div>

          <motion.button
            onClick={startGame}
            className="w-full bg-gradient-to-r from-green-500 to-blue-600 text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            Mulai Bermain! 🎯
          </motion.button>
        </div>
      </div>
    );
  }

  // Main game screen
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-500 to-blue-600 px-6 pt-14 pb-6">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-lg">Teka-Teki Kata</h1>
          <motion.button
            onClick={resetCurrentWord}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <RotateCcw className="w-6 h-6 text-white" />
          </motion.button>
        </div>

        {/* Game Stats */}
        <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4">
          <div className="flex items-center justify-between text-center">
            <div>
              <span className="text-white font-heading font-bold text-lg">{score}</span>
              <p className="text-green-100 font-body text-xs">Skor</p>
            </div>
            <div>
              <span className="text-white font-heading font-bold text-lg">{currentWordIndex + 1}/{wordData.length}</span>
              <p className="text-green-100 font-body text-xs">Kata</p>
            </div>
            <div>
              <span className="text-white font-heading font-bold text-lg">{formatTime(timeElapsed)}</span>
              <p className="text-green-100 font-body text-xs">Waktu</p>
            </div>
            <div>
              <span className="text-white font-heading font-bold text-lg">{errors}</span>
              <p className="text-green-100 font-body text-xs">Error</p>
            </div>
          </div>
        </div>
      </div>

      {/* Game Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Word Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-4 shadow-sm"
        >
          <div className="flex items-center justify-between mb-3">
            <div>
              <span className="bg-blue-100 text-blue-700 text-xs font-bold px-2 py-1 rounded-full">
                {currentWord.category}
              </span>
              <span className={`ml-2 text-xs font-bold px-2 py-1 rounded-full ${
                currentWord.difficulty === 'easy' ? 'bg-green-100 text-green-700' :
                currentWord.difficulty === 'medium' ? 'bg-yellow-100 text-yellow-700' :
                'bg-red-100 text-red-700'
              }`}>
                {currentWord.difficulty === 'easy' ? 'Mudah' : 
                 currentWord.difficulty === 'medium' ? 'Sedang' : 'Sulit'}
              </span>
            </div>
            <div className="flex space-x-2">

              <motion.button
                onClick={useHint}
                disabled={showHint}
                className={`p-2 rounded-xl ${showHint ? 'bg-gray-100 text-gray-400' : 'bg-yellow-100 text-yellow-600 hover:bg-yellow-200'}`}
                whileTap={{ scale: 0.95 }}
              >
                <Lightbulb className="w-5 h-5" />
              </motion.button>
              <motion.button
                onClick={shuffleLetters}
                className="p-2 rounded-xl bg-blue-100 text-blue-600 hover:bg-blue-200"
                whileTap={{ scale: 0.95 }}
              >
                <Shuffle className="w-5 h-5" />
              </motion.button>
            </div>
          </div>

          {/* Image Hint */}
          {showImage && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="mb-3"
            >
              <div className="bg-purple-50 rounded-xl p-3">
                <div className="w-full h-32 bg-gradient-to-br from-purple-100 to-pink-100 rounded-lg overflow-hidden">
                  <img 
                    src={currentWord.imageUrl}
                    alt="Petunjuk Visual"
                    className="w-full h-full object-cover"
                  />
                </div>
                <p className="text-purple-700 font-body text-xs mt-2 text-center">
                  🖼️ Petunjuk Visual: Apa yang ada di gambar?
                </p>
              </div>
            </motion.div>
          )}

          {/* Text Hint */}
          {showHint && (
            <motion.p
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="text-gray-600 font-body text-sm bg-yellow-50 p-3 rounded-xl"
            >
              💡 {currentWord.hint}
            </motion.p>
          )}
        </motion.div>

        {/* Word Slots */}
        <div className="bg-white rounded-2xl p-6 shadow-sm">
          <div className="flex justify-center mb-6">
            <div className="flex flex-wrap justify-center gap-2 max-w-full">
              {placedLetters.map((letter, index) => (
                <motion.button
                  key={index}
                  onClick={() => handlePlacedLetterClick(index)}
                  className={`w-12 h-12 border-2 border-dashed border-gray-300 rounded-xl flex items-center justify-center font-bold ${
                    letter?.isCorrect ? 'bg-gradient-to-br from-green-200 to-green-300 border-green-500 text-green-800 animate-bounce' :
                    letter ? 'bg-gradient-to-br from-blue-100 to-blue-200 border-blue-400 text-blue-700' : 'bg-gray-50'
                  } shadow-sm transition-all duration-300`}
                  whileHover={letter ? { scale: 1.05, rotate: 2 } : {}}
                  whileTap={letter ? { scale: 0.95 } : {}}
                >
                  <span className="text-lg">{letter?.letter || '?'}</span>
                </motion.button>
              ))}
            </div>
          </div>

          {/* Available Letters */}
          <div className="flex flex-wrap justify-center gap-2 max-w-full px-2">
            {letters.filter(l => !l.isPlaced).map((letter) => (
              <motion.button
                key={letter.id}
                onClick={() => handleLetterClick(letter)}
                className="w-10 h-10 bg-gradient-to-br from-emerald-300 to-emerald-400 border-2 border-emerald-500 rounded-xl flex items-center justify-center font-bold text-emerald-800 hover:from-emerald-400 hover:to-emerald-500 shadow-md"
                whileHover={{ scale: 1.15, rotate: 5 }}
                whileTap={{ scale: 0.9 }}
                initial={{ opacity: 0, scale: 0.8, rotate: -10 }}
                animate={{ opacity: 1, scale: 1, rotate: 0 }}
                transition={{ 
                  delay: letter.id * 0.05,
                  type: "spring",
                  stiffness: 260,
                  damping: 20
                }}
              >
                <span className="text-lg drop-shadow-sm">{letter.letter}</span>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Progress */}
        <div className="bg-white rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="text-gray-700 font-body font-medium text-sm">Progress</span>
            <span className="text-gray-500 font-body text-sm">{wordsCompleted}/{wordData.length}</span>
          </div>
          <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
            <motion.div
              className="h-2 bg-gradient-to-r from-green-500 to-blue-500 rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${((wordsCompleted + (placedLetters.filter(l => l !== null).length / currentWord.word.length)) / wordData.length) * 100}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}