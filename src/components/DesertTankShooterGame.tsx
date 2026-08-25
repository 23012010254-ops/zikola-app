import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Target, Clock, Volume2, Award, Heart, Zap } from 'lucide-react';

interface DesertTankShooterGameProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
  updateGameAssessment: (gameType: string, sessionData: any) => void;
}

interface TankTarget {
  id: number;
  x: number;
  y: number;
  problem: string;
  correctAnswer: string;
  options: string[];
  type: 'logic' | 'pattern' | 'sequence' | 'abstract';
  destroyed: boolean;
  speed: number;
  spawnTime: number;
}

export default function DesertTankShooterGame({ navigateTo, addSticker, childName, updateTestResults, updateGameAssessment }: DesertTankShooterGameProps) {
  const [gameState, setGameState] = useState<'menu' | 'playing' | 'completed'>('menu');
  const [tanks, setTanks] = useState<TankTarget[]>([]);
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [timeLeft, setTimeLeft] = useState(120); // 2 minutes
  const [currentLevel, setCurrentLevel] = useState(1);
  const [hits, setHits] = useState(0);
  const [misses, setMisses] = useState(0);
  const [correctAnswers, setCorrectAnswers] = useState(0);
  const [totalQuestions, setTotalQuestions] = useState(0);
  const [startTime, setStartTime] = useState(0);
  const [gameSessionData, setGameSessionData] = useState<any[]>([]);
  const [selectedTank, setSelectedTank] = useState<number | null>(null);
  const [isPaused, setIsPaused] = useState(false);

  // Enhanced Logic and Abstract Reasoning Problems
  const generateLogicProblem = (level: number) => {
    const problems = [
      // Level 1: Fun Animal Logic
      () => {
        const scenarios = [
          {
            problem: "🐸 Kodok melompat di air. 🐰 Kelinci melompat di darat. 🐧 Penguin berenang di...",
            correct: "🌊 Air",
            options: ["🌊 Air", "🌳 Pohon", "☁️ Awan", "🔥 Api"]
          },
          {
            problem: "🦁 Raja hutan adalah singa. 🐙 Raja laut adalah...",
            correct: "🐋 Paus",
            options: ["🐋 Paus", "🐶 Anjing", "🐱 Kucing", "🐰 Kelinci"]
          },
          {
            problem: "🌙 Malam hari bulan bersinar. ☀️ Siang hari ... bersinar.",
            correct: "☀️ Matahari",
            options: ["☀️ Matahari", "⭐ Bintang", "🌈 Pelangi", "💡 Lampu"]
          },
          {
            problem: "🍎 Apel tumbuh di pohon. 🥕 Wortel tumbuh di...",
            correct: "🌱 Tanah",
            options: ["🌱 Tanah", "💧 Air", "☁️ Udara", "🔥 Api"]
          },
          {
            problem: "🚗 Mobil jalan di darat. ✈️ Pesawat terbang di...",
            correct: "☁️ Udara",
            options: ["☁️ Udara", "🌊 Air", "🌱 Tanah", "🏠 Rumah"]
          },
          {
            problem: "❄️ Es sangat dingin. 🔥 Api sangat...",
            correct: "🌡️ Panas",
            options: ["🌡️ Panas", "❄️ Dingin", "💧 Basah", "🌪️ Berangin"]
          },
          {
            problem: "🐝 Lebah membuat madu. 🐄 Sapi memberikan...",
            correct: "🥛 Susu",
            options: ["🥛 Susu", "🍯 Madu", "🥚 Telur", "🍖 Daging"]
          },
          {
            problem: "📚 Buku untuk dibaca. ✏️ Pensil untuk...",
            correct: "✍️ Menulis",
            options: ["✍️ Menulis", "👀 Melihat", "👂 Mendengar", "👃 Mencium"]
          },
          {
            problem: "🌧️ Hujan membuat tanah basah. ☀️ Matahari membuat tanah...",
            correct: "🏜️ Kering",
            options: ["🏜️ Kering", "💧 Basah", "❄️ Beku", "🌪️ Berputar"]
          },
          {
            problem: "🦷 Gigi untuk menggigit. 👁️ Mata untuk...",
            correct: "👀 Melihat",
            options: ["👀 Melihat", "👂 Mendengar", "👃 Mencium", "✋ Menyentuh"]
          }
        ];
        return scenarios[Math.floor(Math.random() * scenarios.length)];
      },
      
      // Level 2: Fun Pattern Adventures
      () => {
        const patterns = [
          {
            problem: "🌈 Pelangi: 🔴🟡🟢🔵🟣 ... apa selanjutnya?",
            correct: "🔴",
            options: ["🔴", "⚫", "⚪", "🟤"]
          },
          {
            problem: "🎵 Musik: Do-Re-Mi-Fa-Sol-? apa selanjutnya?",
            correct: "La",
            options: ["La", "Do", "Si", "Ti"]
          },
          {
            problem: "🚦 Lampu lalu lintas: Merah-Kuning-Hijau-? apa selanjutnya?",
            correct: "Merah",
            options: ["Merah", "Biru", "Ungu", "Orange"]
          },
          {
            problem: "🏠🏢🏠🏢🏠? Bangunan apa selanjutnya?",
            correct: "🏢",
            options: ["🏢", "🏠", "🏰", "🏭"]
          },
          {
            problem: "🌍🌎🌏🌍? Planet apa selanjutnya?",
            correct: "🌎",
            options: ["🌎", "🌍", "🌙", "☀️"]
          },
          {
            problem: "⚽🏀⚽🏀⚽? Bola apa selanjutnya?",
            correct: "🏀",
            options: ["🏀", "⚽", "🎾", "🏐"]
          },
          {
            problem: "1️⃣3️⃣5️⃣7️⃣? Angka apa selanjutnya?",
            correct: "9️⃣",
            options: ["9️⃣", "8️⃣", "6️⃣", "4️⃣"]
          },
          {
            problem: "🍕🍔🍕🍔🍕? Makanan apa selanjutnya?",
            correct: "🍔",
            options: ["🍔", "🍕", "🌭", "🍟"]
          },
          {
            problem: "❤️💙💚💛? Warna apa selanjutnya?",
            correct: "🧡",
            options: ["🧡", "❤️", "💜", "🖤"]
          },
          {
            problem: "🎈🎁🎈🎁🎈? Apa selanjutnya?",
            correct: "🎁",
            options: ["🎁", "🎈", "🎊", "🎉"]
          }
        ];
        return patterns[Math.floor(Math.random() * patterns.length)];
      },
      
      // Level 3: Magic Math & Logic
      () => {
        const abstracts = [
          {
            problem: "🏰 Kastil punya 4 menara. 2 kastil punya berapa menara?",
            correct: "8",
            options: ["8", "6", "4", "10"]
          },
          {
            problem: "🍪 + 🍪 + 🍪 = 🎂. Jika 🍪 = 3, maka 🎂 = ?",
            correct: "9",
            options: ["9", "6", "12", "3"]
          },
          {
            problem: "🐾 Jejak: 🐕 punya 4, 🐈 punya 4, 🐣 punya berapa?",
            correct: "2",
            options: ["2", "4", "6", "8"]
          },
          {
            problem: "🎁 Hadiah: Merah=5 poin, Biru=3 poin, Hijau=? jika total 15",
            correct: "7",
            options: ["7", "5", "8", "6"]
          },
          {
            problem: "🌟 Bintang: Jika 🌟🌟 = 10, maka 🌟🌟🌟 = ?",
            correct: "15",
            options: ["15", "20", "12", "18"]
          },
          {
            problem: "🚗 Roda: Mobil 4, Motor 2, Sepeda berapa?",
            correct: "2",
            options: ["2", "1", "3", "4"]
          },
          {
            problem: "🎪 Sirkus: 🤹 = 3, 🎭 = 5, 🎨 = 2, total = ?",
            correct: "10",
            options: ["10", "8", "12", "9"]
          },
          {
            problem: "⚖️ Timbangan: 🍎🍎 = 🍌🍌🍌🍌, 🍎 = berapa 🍌?",
            correct: "2",
            options: ["2", "1", "3", "4"]
          },
          {
            problem: "🎲 Dadu: Sisi atas 6, bawah pasti berapa?",
            correct: "1",
            options: ["1", "2", "5", "3"]
          },
          {
            problem: "🕐 Jam: Jarum pendek di 3, jarum panjang di 12, jam berapa?",
            correct: "3:00",
            options: ["3:00", "12:00", "6:00", "9:00"]
          }
        ];
        return abstracts[Math.floor(Math.random() * abstracts.length)];
      },
      
      // Level 4: Detective Logic Mysteries
      () => {
        const complex = [
          {
            problem: "🕵️ Detektif: Pencuri masuk dari jendela. Jendela tertutup. Apa yang terjadi?",
            correct: "Pencuri sudah pergi",
            options: ["Pencuri sudah pergi", "Jendela rusak", "Salah jendela", "Pencuri tersembunyi"]
          },
          {
            problem: "🏆 Lomba: Ana juara 1, Beni juara 2, Cici juara 3. Siapa tercepat?",
            correct: "Ana",
            options: ["Ana", "Beni", "Cici", "Sama cepat"]
          },
          {
            problem: "🍰 Kue: Ibu buat 12 kue, dimakan 5, sisanya dibagi 7 anak. Berapa per anak?",
            correct: "1",
            options: ["1", "2", "3", "0"]
          },
          {
            problem: "🌙 Malam: Jika lampu mati, kamar gelap. Kamar terang. Apa yang terjadi?",
            correct: "Lampu menyala",
            options: ["Lampu menyala", "Siang hari", "Jendela terbuka", "Tidak ada yang benar"]
          },
          {
            problem: "🐾 Jejak: Kucing 4 kaki, ayam 2 kaki. 3 kucing + 2 ayam = berapa kaki?",
            correct: "16",
            options: ["16", "14", "12", "18"]
          },
          {
            problem: "🎒 Tas: Merah 3 buku, Biru 5 buku, Hijau 2 buku. Total berapa buku?",
            correct: "10",
            options: ["10", "8", "12", "9"]
          },
          {
            problem: "🚌 Bus: Naik 8 orang, turun 3 orang, naik 5 orang. Sekarang berapa orang?",
            correct: "10",
            options: ["10", "8", "11", "13"]
          },
          {
            problem: "🎨 Warna: Merah + Kuning = Orange. Biru + Kuning = ?",
            correct: "Hijau",
            options: ["Hijau", "Ungu", "Orange", "Merah"]
          },
          {
            problem: "⏰ Waktu: Kemarin Senin, besok hari apa?",
            correct: "Rabu",
            options: ["Rabu", "Selasa", "Kamis", "Minggu"]
          },
          {
            problem: "🏠 Rumah: Lantai 1 ada 4 kamar, lantai 2 ada 3 kamar. Total berapa kamar?",
            correct: "7",
            options: ["7", "6", "8", "5"]
          }
        ];
        return complex[Math.floor(Math.random() * complex.length)];
      },
      
      // Level 5: Super Brain Challenge
      () => {
        const advanced = [
          {
            problem: "🎪 Sirkus: Badut A lucu, B tidak lucu, C lucu. Siapa yang paling disukai anak-anak?",
            correct: "A dan C",
            options: ["A dan C", "Hanya A", "Hanya B", "Semua sama"]
          },
          {
            problem: "🌈 Pelangi: Setelah hujan ada pelangi. Tidak ada pelangi. Apa yang terjadi?",
            correct: "Tidak hujan",
            options: ["Tidak hujan", "Awan tebal", "Malam hari", "Semua benar"]
          },
          {
            problem: "🎯 Target: Panah 1 dapat 10 poin, panah 2 dapat 5 poin, panah 3 dapat 15 poin. Rata-rata?",
            correct: "10",
            options: ["10", "15", "5", "12"]
          },
          {
            problem: "🔐 Kunci: Kunci A buka pintu 1, kunci B buka pintu 2. Kunci C buka pintu?",
            correct: "3",
            options: ["3", "1", "2", "Semua pintu"]
          },
          {
            problem: "🎲 Dadu: Lempar 2 dadu, jumlah 7. Kemungkinan apa saja?",
            correct: "1+6, 2+5, 3+4",
            options: ["1+6, 2+5, 3+4", "Hanya 3+4", "Hanya 1+6", "Tidak mungkin"]
          },
          {
            problem: "🚗 Parkir: Mobil A di slot 1, B di slot 3, C di slot mana?",
            correct: "2 atau 4",
            options: ["2 atau 4", "Hanya 2", "Hanya 4", "Di mana saja"]
          },
          {
            problem: "🍎 Buah: 1 keranjang 12 apel, dimakan 1/4. Sisanya berapa?",
            correct: "9",
            options: ["9", "8", "10", "6"]
          },
          {
            problem: "⭐ Bintang: Jika 1 bintang = 3 poin, 3 bintang + 1 bulan (5 poin) = ?",
            correct: "14",
            options: ["14", "12", "15", "11"]
          },
          {
            problem: "🎨 Lukisan: Merah + Biru = Ungu. Ungu + Putih = ?",
            correct: "Ungu muda",
            options: ["Ungu muda", "Pink", "Biru muda", "Merah muda"]
          },
          {
            problem: "🏁 Balap: Start jam 2, finish jam 5. Lama balapan berapa jam?",
            correct: "3",
            options: ["3", "2", "5", "7"]
          }
        ];
        return advanced[Math.floor(Math.random() * advanced.length)];
      }
    ];

    const problemLevel = Math.min(level, problems.length);
    const problemGenerator = problems[problemLevel - 1];
    const problem = problemGenerator();
    
    return {
      problem: problem.problem,
      answer: problem.correct,
      options: problem.options,
      type: level <= 1 ? 'logic' : level <= 2 ? 'pattern' : level <= 3 ? 'abstract' : level <= 4 ? 'sequence' : 'advanced'
    };
  };

  const generateGameSound = (frequency: number, duration: number, type: string) => {
    if (typeof window !== 'undefined' && window.AudioContext) {
      try {
        const audioContext = new AudioContext();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
        oscillator.type = type === 'explosion' ? 'sawtooth' : 'sine';
        
        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + duration);
      } catch (error) {
        console.warn('Audio not supported');
      }
    }
  };

  useEffect(() => {
    if (gameState === 'playing' && timeLeft > 0 && lives > 0) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if ((timeLeft === 0 || lives <= 0) && gameState === 'playing') {
      setTimeout(() => endGame(), 100);
    }
  }, [timeLeft, gameState, lives]);

  useEffect(() => {
    if (gameState === 'playing') {
      const spawnInterval = setInterval(() => {
        spawnTank();
      }, 4000 - (currentLevel * 500)); // Faster spawning each level

      return () => clearInterval(spawnInterval);
    }
  }, [gameState, currentLevel]);

  useEffect(() => {
    if (gameState === 'playing' && !isPaused) {
      const moveInterval = setInterval(() => {
        setTanks(prev => prev.map(tank => ({
          ...tank,
          y: tank.y + tank.speed
        })).filter(tank => tank.y < window.innerHeight - 50));
      }, 60);

      return () => clearInterval(moveInterval);
    }
  }, [gameState, isPaused]);

  const startGame = () => {
    setGameState('playing');
    setScore(0);
    setLives(3);
    setTimeLeft(120);
    setCurrentLevel(1);
    setHits(0);
    setMisses(0);
    setCorrectAnswers(0);
    setTotalQuestions(0);
    setStartTime(Date.now());
    setGameSessionData([]);
    setTanks([]);
    setSelectedTank(null);
    setIsPaused(false);
    generateGameSound(600, 0.5, 'sine');
  };

  const spawnTank = () => {
    const problem = generateLogicProblem(currentLevel);
    const newTank: TankTarget = {
      id: Date.now() + Math.random(),
      x: Math.random() * (window.innerWidth - 120),
      y: 60,
      problem: problem.problem,
      correctAnswer: problem.answer,
      options: problem.options,
      type: problem.type as any,
      destroyed: false,
      speed: 0.8 + (currentLevel * 0.2),
      spawnTime: Date.now()
    };
    
    setTanks(prev => [...prev, newTank]);
    generateGameSound(400, 0.3, 'sine');
  };

  const shootTank = (tankId: number, selectedAnswer: string) => {
    if (selectedTank !== tankId || gameState !== 'playing') return;
    
    setSelectedTank(null);
    setIsPaused(false);

    const tankToShoot = tanks.find(tank => tank.id === tankId);
    if (!tankToShoot || tankToShoot.destroyed) return;

    const isCorrect = selectedAnswer === tankToShoot.correctAnswer;
    
    setTotalQuestions(prev => prev + 1);
    
    if (isCorrect) {
      setScore(prevScore => prevScore + (15 * currentLevel));
      setHits(prevHits => prevHits + 1);
      setCorrectAnswers(prevCorrect => {
        const newCorrectAnswers = prevCorrect + 1;
        if (newCorrectAnswers % 4 === 0 && currentLevel < 6) {
          setCurrentLevel(prevLevel => prevLevel + 1);
          addSticker('logic-master');
        }
        return newCorrectAnswers;
      });
      generateGameSound(900, 0.4, 'explosion');
      addSticker('desert-commander');
    } else {
      setMisses(prevMisses => prevMisses + 1);
      setLives(prevLives => {
        const newLives = prevLives - 1;
        if (newLives <= 0) {
          setTimeout(() => {
            if (gameState === 'playing') {
              endGame();
            }
          }, 100);
        }
        return newLives;
      });
      generateGameSound(200, 0.4, 'sawtooth');
    }

    setGameSessionData(prev => [...prev, {
      problem: tankToShoot.problem,
      correctAnswer: tankToShoot.correctAnswer,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeSpent: Date.now() - tankToShoot.spawnTime,
      level: currentLevel,
      type: tankToShoot.type
    }]);

    setTanks(prev => prev.filter(tank => tank.id !== tankId));
    generateGameSound(700, 0.2, 'sine');
  };

  const endGame = () => {
    // Clear all tanks and reset selection state immediately
    setTanks([]);
    setSelectedTank(null);
    setIsPaused(false);
    setGameState('completed');
    
    const totalTime = Math.round((Date.now() - startTime) / 1000);
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    
    updateTestResults('cognitive', {
      score: correctAnswers,
      total: totalQuestions,
      percentage: accuracy,
      timeSpent: totalTime,
      gameMode: 'Desert Tank Logic',
      level: currentLevel,
      categoryScores: {
        logic: Math.round((accuracy / 100) * 30),
        abstraction: Math.round((hits / Math.max(hits + misses, 1)) * 30),
        reasoning: Math.round((currentLevel / 5) * 20)
      },
      detailedResults: {
        accuracy: accuracy,
        averageResponseTime: gameSessionData.length > 0 
          ? gameSessionData.reduce((sum, s) => sum + s.timeSpent, 0) / gameSessionData.length / 1000
          : 0,
        levelReached: currentLevel,
        livesRemaining: lives,
        logicProblems: gameSessionData.filter(s => s.type === 'logic').length,
        patternProblems: gameSessionData.filter(s => s.type === 'pattern').length,
        abstractProblems: gameSessionData.filter(s => s.type === 'abstract').length
      }
    });

    updateGameAssessment('desertTankGame', {
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      accuracy: accuracy,
      timeSpent: totalTime,
      level: currentLevel,
      errors: misses
    });

    // Award stickers based on performance
    if (accuracy >= 90) addSticker('logic-genius');
    if (accuracy >= 80) addSticker('abstract-master');
    if (currentLevel >= 4) addSticker('reasoning-expert');
    if (correctAnswers >= 15) addSticker('tank-destroyer');
    
    addSticker('desert-survivor');
  };

  if (gameState === 'completed') {
    const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
    const totalTime = Math.round((Date.now() - startTime) / 1000);

    return (
      <div className="min-h-screen bg-gradient-to-b from-amber-300 via-orange-300 to-rose-400 text-white">
        <div className="px-6 py-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center mb-8"
          >
            <div className="text-8xl mb-4">🏆</div>
            <h1 className="font-heading font-bold text-3xl mb-2">Misi Selesai!</h1>
            <p className="text-yellow-100 text-lg">
              Hebat {childName}! Kamu berhasil menguasai logika desert!
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

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5 }}
              className="bg-white/20 backdrop-blur-sm rounded-2xl p-4"
            >
              <div className="flex justify-between items-center">
                <span className="font-body">Waktu Bermain</span>
                <span className="font-heading font-bold text-2xl">{Math.floor(totalTime / 60)}:{(totalTime % 60).toString().padStart(2, '0')}</span>
              </div>
            </motion.div>
          </div>

          <div className="space-y-3">
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
              onClick={() => setGameState('menu')}
              className="w-full bg-white text-orange-600 py-4 px-6 rounded-2xl font-heading font-bold text-lg shadow-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Main Lagi
            </motion.button>

            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7 }}
              onClick={() => navigateTo('game')}
              className="w-full bg-white/20 backdrop-blur-sm text-white py-4 px-6 rounded-2xl font-heading font-bold text-lg border-2 border-white/30"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Pilih Game Lain
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  if (gameState === 'playing') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-amber-200 via-orange-200 to-rose-300 relative overflow-hidden">
        {/* Enhanced Desert Background Elements */}
        <div className="absolute inset-0">
          {/* Sand dunes with smoother gradients */}
          <div className="absolute bottom-0 left-0 w-full h-40 bg-gradient-to-t from-amber-300 via-orange-200 to-transparent opacity-60" />
          <div className="absolute bottom-0 right-1/4 w-72 h-28 bg-gradient-to-br from-yellow-400 to-orange-300 rounded-full opacity-20" />
          <div className="absolute bottom-0 left-1/3 w-56 h-20 bg-gradient-to-br from-amber-400 to-yellow-400 rounded-full opacity-15" />
          
          {/* Gentle Sun */}
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 60, repeat: Infinity, ease: "linear" }}
            className="absolute top-8 right-8 w-20 h-20 bg-gradient-to-br from-yellow-100 to-amber-300 rounded-full shadow-xl opacity-80"
          />
          
          {/* Desert plants */}
          <motion.div 
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 3, repeat: Infinity }}
            className="absolute bottom-20 left-1/4 text-5xl"
          >
            🌵
          </motion.div>
          <motion.div 
            animate={{ scale: [1, 1.1, 1] }}
            transition={{ duration: 4, repeat: Infinity, delay: 1 }}
            className="absolute bottom-24 right-1/3 text-4xl"
          >
            🌵
          </motion.div>
          <div className="absolute bottom-16 left-1/6 text-3xl opacity-70">🌿</div>
          <div className="absolute bottom-18 right-1/6 text-3xl opacity-60">🏜️</div>
          
          {/* Player Tank at bottom center */}
          <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2">
            <motion.div
              animate={{ 
                y: [0, -5, 0],
                rotate: [0, 2, -2, 0]
              }}
              transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              className="text-6xl filter drop-shadow-lg"
            >
              🚙
            </motion.div>
            <div className="text-center mt-2">
              <span className="bg-emerald-500 text-white px-3 py-1 rounded-full text-sm font-bold shadow-lg">
                Player Tank
              </span>
            </div>
          </div>
        </div>

        {/* Game UI */}
        <div className="relative z-10">
          {/* Header */}
          <div className="flex justify-between items-center px-6 pt-12 pb-4">
            <div className="flex items-center space-x-4">
              <motion.button
                onClick={() => navigateTo('game')}
                className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
                whileTap={{ scale: 0.95 }}
              >
                <ArrowLeft className="w-5 h-5 text-white" />
              </motion.button>
              <div className="text-white">
                <div className="font-heading font-bold text-lg">Desert Tank</div>
                <div className="text-white/80 text-sm">Level {currentLevel}</div>
              </div>
            </div>
            
            <div className="text-right text-white">
              <div className="font-heading font-bold text-2xl">{score}</div>
              <div className="text-white/80 text-sm">Skor</div>
            </div>
          </div>

          {/* Status Bar */}
          <div className="px-6 mb-4">
            <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
              <div className="flex justify-between items-center mb-3">
                <div className="flex items-center space-x-2">
                  <Heart className="w-5 h-5 text-red-400" />
                  <span className="text-white font-medium">{lives}</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Clock className="w-5 h-5 text-blue-400" />
                  <span className="text-white font-medium">{Math.floor(timeLeft / 60)}:{(timeLeft % 60).toString().padStart(2, '0')}</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Zap className="w-5 h-5 text-yellow-400" />
                  <span className="text-white font-medium">{correctAnswers}/15</span>
                </div>
              </div>
              
              <div className="w-full bg-white/20 rounded-full h-2">
                <motion.div
                  className="bg-white h-2 rounded-full"
                  initial={{ width: 0 }}
                  animate={{ width: `${(correctAnswers / 15) * 100}%` }}
                  transition={{ duration: 0.3 }}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Tanks */}
        <div className="relative px-6">
          <AnimatePresence>
            {tanks.map((tank) => (
              <motion.div
                key={tank.id}
                className="absolute"
                style={{ left: tank.x, top: tank.y }}
                initial={{ scale: 0, y: -50 }}
                animate={{ scale: tank.destroyed ? 0 : 1, y: tank.y }}
                exit={{ scale: 0, opacity: 0 }}
                transition={{ duration: 0.3 }}
              >
                <div
                  onClick={() => {
                    setSelectedTank(tank.id);
                    setIsPaused(true);
                  }}
                  className={`relative cursor-pointer transform hover:scale-110 transition-all duration-300 ${
                    selectedTank === tank.id ? 'scale-125 z-30' : 'z-10'
                  }`}
                >
                  {/* Enhanced Tank Body */}
                  <div className="relative flex flex-col items-center space-y-3">
                    <motion.div
                      animate={{ 
                        rotate: [0, 5, -5, 0],
                        scale: [1, 1.05, 1]
                      }}
                      transition={{ duration: 2, repeat: Infinity }}
                      className="text-6xl filter drop-shadow-lg"
                    >
                      🚛
                    </motion.div>
                    {/* Enhanced Problem Display */}
                    <motion.div 
                      animate={{ y: [0, -3, 0] }}
                      transition={{ duration: 1.5, repeat: Infinity }}
                      className="bg-gradient-to-br from-white to-blue-50 rounded-xl px-4 py-2 border-3 border-emerald-400 shadow-xl max-w-40"
                    >
                      <span className="text-gray-900 font-body font-bold text-sm text-center block leading-tight">{tank.problem}</span>
                    </motion.div>
                    {/* Target indicator */}
                    <motion.div
                      animate={{ scale: [1, 1.2, 1], opacity: [0.7, 1, 0.7] }}
                      transition={{ duration: 1, repeat: Infinity }}
                      className="text-xl"
                    >
                      🎯
                    </motion.div>
                  </div>
                </div>

                {/* Enhanced Answer Modal */}
                {selectedTank === tank.id && (
                  <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4">
                    <motion.div
                      initial={{ opacity: 0, scale: 0.8, y: 50 }}
                      animate={{ opacity: 1, scale: 1, y: 0 }}
                      className="bg-gradient-to-br from-white to-blue-50 rounded-3xl p-6 border-4 border-emerald-400 shadow-2xl max-w-md w-full"
                    >
                      <div className="text-center mb-6">
                        <motion.div 
                          animate={{ rotate: [0, 10, -10, 0] }}
                          transition={{ duration: 0.8, repeat: 3 }}
                          className="text-6xl mb-4"
                        >
                          🎯
                        </motion.div>
                        <div className="text-gray-900 font-heading font-bold text-xl mb-3 leading-tight px-2">{tank.problem}</div>
                        <div className="text-emerald-600 font-bold text-lg">Tembak Jawaban yang Benar!</div>
                      </div>
                      
                      <div className="space-y-3 mb-6">
                        {tank.options.map((option, index) => (
                          <motion.button
                            key={index}
                            onClick={() => {
                              shootTank(tank.id, option);
                            }}
                            className="w-full bg-gradient-to-r from-emerald-400 to-blue-400 hover:from-emerald-500 hover:to-blue-500 text-white py-4 px-6 rounded-xl font-bold text-base shadow-lg border-2 border-white/50 min-h-[60px] flex items-center justify-center text-center transition-all duration-200"
                            whileHover={{ scale: 1.02, y: -2 }}
                            whileTap={{ scale: 0.98 }}
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: index * 0.1 }}
                          >
                            <span className="break-words">{option}</span>
                          </motion.button>
                        ))}
                      </div>
                      
                      <motion.button
                        onClick={() => {
                          setSelectedTank(null);
                          setIsPaused(false);
                        }}
                        className="w-full bg-gradient-to-r from-gray-400 to-gray-500 hover:from-gray-500 hover:to-gray-600 text-white py-3 px-4 rounded-xl font-bold border-2 border-white/30"
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.5 }}
                      >
                        ❌ Batal
                      </motion.button>
                    </motion.div>
                  </div>
                )}
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>
    );
  }

  // Menu Screen
  return (
    <div className="min-h-screen bg-gradient-to-b from-amber-300 via-orange-300 to-rose-400 relative overflow-hidden">
      {/* Desert Background */}
      <div className="absolute inset-0">
        <div className="absolute bottom-0 left-0 w-full h-40 bg-gradient-to-t from-yellow-600 to-transparent" />
        <div className="absolute top-8 right-8 w-20 h-20 bg-gradient-to-br from-yellow-200 to-orange-400 rounded-full shadow-lg" />
        <div className="absolute bottom-20 left-1/4 text-6xl">🌵</div>
        <div className="absolute bottom-16 right-1/3 text-5xl">🌵</div>
        <div className="absolute bottom-24 left-3/4 text-4xl">🏜️</div>
      </div>

      <div className="relative z-10 px-6 py-8">
        <div className="flex items-center justify-between mb-12">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-5 h-5 text-white" />
          </motion.button>
          <h1 className="text-white font-heading text-xl">Desert Tank Logic</h1>
          <div className="w-10" />
        </div>

        <div className="text-center mb-12">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: "spring", stiffness: 200 }}
            className="text-8xl mb-6"
          >
            🚗💨
          </motion.div>
          <h2 className="text-white font-heading text-2xl mb-4">
            Petualangan Logika di Padang Pasir!
          </h2>
          <p className="text-yellow-100 text-base mb-8">
            Gunakan tank untuk menembak jawaban yang benar dan kuasai logika abstrak!
          </p>

          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 mb-8">
            <h3 className="text-white font-heading text-lg mb-4">Cara Bermain:</h3>
            <div className="space-y-3 text-left">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center">
                  <Target className="w-4 h-4 text-white" />
                </div>
                <span className="text-yellow-100">Tap tank lalu pilih jawaban logika yang benar</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                  <Clock className="w-4 h-4 text-white" />
                </div>
                <span className="text-yellow-100">Bertahan selama 2 menit</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                  <Award className="w-4 h-4 text-white" />
                </div>
                <span className="text-yellow-100">Asah kemampuan logika dan abstraksi!</span>
              </div>
            </div>
          </div>

          <motion.button
            onClick={startGame}
            className="w-full bg-white text-orange-600 py-4 px-6 rounded-2xl font-heading font-bold text-xl shadow-lg mb-4"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            🚀 Mulai Petualangan!
          </motion.button>
        </div>
      </div>
    </div>
  );
}