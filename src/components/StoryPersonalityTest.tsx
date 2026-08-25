import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Sparkles, Star, Heart } from 'lucide-react';

interface StoryPersonalityTestProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  updateTestResults: (testType: string, results: any) => void;
}

export default function StoryPersonalityTest({ 
  navigateTo, 
  addSticker, 
  childName,
  updateTestResults 
}: StoryPersonalityTestProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<string[]>([]);
  const [isCompleted, setIsCompleted] = useState(false);
  const [mbtiResult, setMbtiResult] = useState<any>(null);
  const [selectedChoice, setSelectedChoice] = useState<number | null>(null);

  // Simple daily life situations with 4 choices (MBTI based)
  const questions = [
    {
      id: 1,
      emoji: '🤕',
      situation: 'Ketika temanmu terjatuh, kamu akan:',
      choices: [
        { emoji: '🏃', text: 'Langsung lari menghampiri dan menolong', trait: 'E' },
        { emoji: '🤗', text: 'Tanya apakah dia baik-baik saja', trait: 'F' },
        { emoji: '👨‍⚕️', text: 'Panggil guru atau orang dewasa', trait: 'T' },
        { emoji: '🩹', text: 'Ambilkan obat merah dan plester', trait: 'S' }
      ]
    },
    {
      id: 2,
      emoji: '🎂',
      situation: 'Temanmu tidak diundang ke pesta ulang tahun:',
      choices: [
        { emoji: '🎉', text: 'Ajak temanku ikut bersamaku', trait: 'E' },
        { emoji: '💝', text: 'Hibur dia dan bilang nanti kita main', trait: 'F' },
        { emoji: '📞', text: 'Beritahu yang punya pesta', trait: 'J' },
        { emoji: '🎁', text: 'Ajak dia bikin pesta sendiri besok', trait: 'N' }
      ]
    },
    {
      id: 3,
      emoji: '📚',
      situation: 'Saat kerja kelompok, kamu biasanya:',
      choices: [
        { emoji: '🗣️', text: 'Ngobrol sama semua anggota', trait: 'E' },
        { emoji: '📝', text: 'Catat dan bagi tugas dengan jelas', trait: 'J' },
        { emoji: '💡', text: 'Kasih ide-ide kreatif', trait: 'N' },
        { emoji: '🤝', text: 'Pastikan semua setuju dan senang', trait: 'F' }
      ]
    },
    {
      id: 4,
      emoji: '🎮',
      situation: 'Ada teman baru di sekolah, kamu:',
      choices: [
        { emoji: '👋', text: 'Langsung kenalan dan ajak main', trait: 'E' },
        { emoji: '😊', text: 'Senyum dan tunggu dia mendekat', trait: 'I' },
        { emoji: '🏫', text: 'Tunjukkan ruang kelas dan aturan', trait: 'S' },
        { emoji: '❓', text: 'Tanya dari mana dan hobi apa', trait: 'N' }
      ]
    },
    {
      id: 5,
      emoji: '😢',
      situation: 'Temanmu menangis di kelas, kamu:',
      choices: [
        { emoji: '🪑', text: 'Duduk di sebelahnya menemani', trait: 'I' },
        { emoji: '💬', text: 'Tanya kenapa dia menangis', trait: 'T' },
        { emoji: '🤗', text: 'Peluk dan hibur sampai tenang', trait: 'F' },
        { emoji: '🧃', text: 'Ambilkan tisu dan minum', trait: 'S' }
      ]
    },
    {
      id: 6,
      emoji: '⚽',
      situation: 'Saat bermain, ada yang curang, kamu:',
      choices: [
        { emoji: '🗣️', text: 'Bilang ke semua kalau itu curang', trait: 'E' },
        { emoji: '⚖️', text: 'Ingatkan aturan mainnya', trait: 'T' },
        { emoji: '😔', text: 'Kasih tahu perasaanku yang kecewa', trait: 'F' },
        { emoji: '🔄', text: 'Usul main ulang yang adil', trait: 'J' }
      ]
    },
    {
      id: 7,
      emoji: '🍕',
      situation: 'Ada 1 pizza terakhir, tapi temanmu juga mau:',
      choices: [
        { emoji: '✂️', text: 'Potong jadi dua, bagi rata', trait: 'S' },
        { emoji: '💝', text: 'Kasih ke temanku saja', trait: 'F' },
        { emoji: '🎲', text: 'Suit batu gunting kertas', trait: 'T' },
        { emoji: '🍕🍕', text: 'Beli pizza lagi buat berdua', trait: 'N' }
      ]
    },
    {
      id: 8,
      emoji: '🏆',
      situation: 'Temanmu kalah lomba dan sedih, kamu:',
      choices: [
        { emoji: '🎮', text: 'Ajak main game untuk melupakan', trait: 'E' },
        { emoji: '⭐', text: 'Bilang dia sudah hebat dan berusaha', trait: 'F' },
        { emoji: '📊', text: 'Analisis apa yang bisa diperbaiki', trait: 'T' },
        { emoji: '🎯', text: 'Ajak latihan untuk lomba berikutnya', trait: 'J' }
      ]
    },
    {
      id: 9,
      emoji: '🎨',
      situation: 'Ada teman yang kesulitan mengerjakan tugas:',
      choices: [
        { emoji: '👥', text: 'Ajak belajar bersama-sama', trait: 'E' },
        { emoji: '📖', text: 'Jelaskan cara mengerjakannya', trait: 'S' },
        { emoji: '💪', text: 'Semangatin dia pasti bisa', trait: 'F' },
        { emoji: '🔍', text: 'Bantu cari cara yang lebih mudah', trait: 'N' }
      ]
    },
    {
      id: 10,
      emoji: '🎁',
      situation: 'Kamu punya 2 mainan, temanmu tidak punya:',
      choices: [
        { emoji: '🎮🎮', text: 'Main bersama dengan mainanku', trait: 'E' },
        { emoji: '🎁', text: 'Kasih 1 mainan untuknya', trait: 'F' },
        { emoji: '⏰', text: 'Bergantian pakai dengan jadwal', trait: 'J' },
        { emoji: '🤝', text: 'Tukar mainan supaya seru', trait: 'P' }
      ]
    },
    {
      id: 11,
      emoji: '🚌',
      situation: 'Di bus, kamu lihat orang tua berdiri:',
      choices: [
        { emoji: '🪑', text: 'Langsung berdiri kasih tempat duduk', trait: 'S' },
        { emoji: '😊', text: 'Tawarkan dengan sopan', trait: 'I' },
        { emoji: '❤️', text: 'Kasihan, langsung bantu', trait: 'F' },
        { emoji: '✅', text: 'Itu yang benar, harus dilakukan', trait: 'T' }
      ]
    },
    {
      id: 12,
      emoji: '🗑️',
      situation: 'Ada sampah di kelas tapi bukan sampahmu:',
      choices: [
        { emoji: '👥', text: 'Ajak teman-teman bersih-bersih', trait: 'E' },
        { emoji: '🧹', text: 'Langsung buang ke tempat sampah', trait: 'S' },
        { emoji: '📢', text: 'Ingatkan semua jangan buang sembarangan', trait: 'T' },
        { emoji: '♻️', text: 'Bikin sistem daur ulang di kelas', trait: 'N' }
      ]
    }
  ];

  // 16 Animal MBTI Results
  const animalTypes = {
    'ENFJ': {
      animal: '🦁',
      name: 'Singa Pemimpin',
      personality: 'Pemimpin yang Peduli',
      traits: 'Karismatik, Inspiratif, dan Empati',
      description: `${childName} adalah pemimpin alami yang selalu peduli dengan teman-teman! Kamu suka membantu orang lain dan punya kemampuan membuat semua orang merasa spesial.`,
      strengths: ['Pemimpin Natural', 'Mudah Bergaul', 'Peduli Orang Lain', 'Komunikatif'],
      tips: 'Dukung jiwa kepemimpinan dengan memberikan tanggung jawab kecil dan ajari untuk mendengarkan berbagai pendapat.',
      color: 'from-yellow-400 to-orange-500'
    },
    'ENFP': {
      animal: '🐰',
      name: 'Kelinci Petualang',
      personality: 'Petualang Ceria',
      traits: 'Kreatif, Antusias, dan Imajinatif',
      description: `${childName} adalah petualang yang penuh energi! Kamu punya ide-ide kreatif yang luar biasa dan selalu optimis melihat hal baru.`,
      strengths: ['Sangat Kreatif', 'Mudah Beradaptasi', 'Antusias', 'Imajinatif'],
      tips: 'Berikan banyak aktivitas kreatif dan hindari rutinitas yang terlalu kaku. Biarkan bereksplorasi!',
      color: 'from-pink-400 to-purple-500'
    },
    'ENTJ': {
      animal: '🦅',
      name: 'Elang Komandan',
      personality: 'Komandan Cilik',
      traits: 'Tegas, Strategis, dan Ambisius',
      description: `${childName} punya visi besar dan determinasi kuat! Kamu suka membuat rencana dan mencapai target yang kamu tetapkan.`,
      strengths: ['Terorganisir', 'Berani', 'Strategis', 'Goal-Oriented'],
      tips: 'Tantang dengan target yang achievable dan ajarkan fleksibilitas serta empati.',
      color: 'from-blue-400 to-indigo-500'
    },
    'ENTP': {
      animal: '🦊',
      name: 'Rubah Inovator',
      personality: 'Innovator Pintar',
      traits: 'Cerdik, Adaptif, dan Inovatif',
      description: `${childName} adalah problem solver yang pintar! Kamu suka debat, punya ide-ide fresh, dan selalu curious.`,
      strengths: ['Problem Solver', 'Quick Learner', 'Inovatif', 'Sangat Curious'],
      tips: 'Stimulasi rasa ingin tahu dengan eksperimen, debat, dan diskusi yang menantang.',
      color: 'from-orange-400 to-red-500'
    },
    'ESFJ': {
      animal: '🐨',
      name: 'Koala Penolong',
      personality: 'Penolong Setia',
      traits: 'Peduli, Harmonis, dan Supportive',
      description: `${childName} adalah teman yang hangat dan selalu siap membantu! Kamu peduli dengan perasaan orang lain dan suka menjaga keharmonisan.`,
      strengths: ['Supportive', 'Reliable', 'Team Player', 'Sangat Peduli'],
      tips: 'Apresiasi kebaikannya dan ajarkan untuk kadang prioritaskan diri sendiri juga.',
      color: 'from-green-400 to-teal-500'
    },
    'ESFP': {
      animal: '🐹',
      name: 'Hamster Entertainer',
      personality: 'Entertainer Lucu',
      traits: 'Fun, Spontan, dan Cheerful',
      description: `${childName} adalah mood booster! Kamu suka bikin orang senang, spontan, dan selalu bawa energy positif ke mana-mana.`,
      strengths: ['Sangat Cheerful', 'Spontan', 'People Person', 'Praktis'],
      tips: 'Dukung ekspresi dirinya dan ajarkan perencanaan sederhana untuk keseimbangan.',
      color: 'from-yellow-400 to-pink-500'
    },
    'ESTJ': {
      animal: '🐝',
      name: 'Lebah Organizer',
      personality: 'Organizer Teliti',
      traits: 'Disiplin, Sistematis, dan Responsible',
      description: `${childName} suka kerapihan dan punya jadwal jelas! Kamu sangat reliable dan bisa diandalkan untuk menyelesaikan tugas.`,
      strengths: ['Sangat Organized', 'Responsible', 'Hardworking', 'Loyal'],
      tips: 'Hargai kedisiplinannya tapi ajak untuk lebih fleksibel dan spontan sesekali.',
      color: 'from-yellow-400 to-orange-500'
    },
    'ESTP': {
      animal: '🐯',
      name: 'Harimau Athlete',
      personality: 'Athlete Berani',
      traits: 'Sporty, Aktif, dan Berani',
      description: `${childName} sangat energik dan suka tantangan fisik! Kamu berani coba hal baru dan suka action.`,
      strengths: ['Sangat Energetic', 'Adaptable', 'Hands-On', 'Courageous'],
      tips: 'Sediakan banyak aktivitas fisik dan olahraga untuk menyalurkan energi.',
      color: 'from-orange-400 to-red-500'
    },
    'INFJ': {
      animal: '🦉',
      name: 'Burung Hantu Visioner',
      personality: 'Visioner Bijak',
      traits: 'Bijaksana, Intuitif, dan Idealistik',
      description: `${childName} punya pemikiran yang dalam dan insight bagus! Kamu sangat peduli dengan orang lain dan punya visi yang indah.`,
      strengths: ['Insightful', 'Sangat Empati', 'Kreatif', 'Idealistic'],
      tips: 'Berikan waktu sendiri untuk recharge dan dukung kreativitas serta idealisme.',
      color: 'from-purple-400 to-indigo-500'
    },
    'INFP': {
      animal: '🐼',
      name: 'Panda Dreamer',
      personality: 'Dreamer Baik Hati',
      traits: 'Sensitif, Imajinatif, dan Autentik',
      description: `${childName} punya dunia dalam yang kaya dan indah! Kamu sangat peduli keadilan dan autentik dengan diri sendiri.`,
      strengths: ['Sangat Kreatif', 'Authentic', 'Compassionate', 'Open-Minded'],
      tips: 'Dukung ekspresi kreatif dan hargai sensitivitas serta nilai-nilai yang dipegang.',
      color: 'from-green-400 to-blue-500'
    },
    'INTJ': {
      animal: '🐺',
      name: 'Serigala Mastermind',
      personality: 'Mastermind Muda',
      traits: 'Strategis, Independent, dan Analytical',
      description: `${childName} suka berpikir deep dan punya rencana jangka panjang! Kamu mandiri dan sangat analitis.`,
      strengths: ['Strategic', 'Independent', 'Analytical', 'Determined'],
      tips: 'Respect kebutuhan waktu sendiri dan tantang dengan puzzle serta strategi games.',
      color: 'from-gray-400 to-blue-500'
    },
    'INTP': {
      animal: '🐧',
      name: 'Penguin Scientist',
      personality: 'Scientist Kecil',
      traits: 'Logis, Eksploratif, dan Objektif',
      description: `${childName} sangat curious dan suka eksperimen! Kamu selalu tanya "kenapa" dan suka memahami cara kerja sesuatu.`,
      strengths: ['Sangat Logical', 'Curious', 'Objective', 'Innovative'],
      tips: 'Fasilitasi rasa ingin tahu dengan buku, eksperimen sains, dan diskusi mendalam.',
      color: 'from-blue-400 to-cyan-500'
    },
    'ISFJ': {
      animal: '🐑',
      name: 'Domba Protector',
      personality: 'Protector Lembut',
      traits: 'Nurturing, Supportive, dan Detail-Oriented',
      description: `${childName} lembut dan selalu siap bantu! Kamu menjaga harmoni di group dan sangat perhatian dengan detail.`,
      strengths: ['Sangat Caring', 'Detail-Oriented', 'Loyal', 'Patient'],
      tips: 'Apresiasi kebaikan dan ajarkan untuk assertive saat dibutuhkan.',
      color: 'from-pink-400 to-rose-500'
    },
    'ISFP': {
      animal: '🐻',
      name: 'Beruang Artist',
      personality: 'Artist Lembut',
      traits: 'Kreatif, Peace-Loving, dan Artistik',
      description: `${childName} artistik dan kalem! Kamu passionate dengan hal yang kamu suka dan punya jiwa seni yang kuat.`,
      strengths: ['Sangat Artistic', 'Gentle', 'Flexible', 'Observant'],
      tips: 'Sediakan banyak medium artistik dan berikan ruang untuk eksplorasi kreatif.',
      color: 'from-brown-400 to-orange-500'
    },
    'ISTJ': {
      animal: '🐘',
      name: 'Gajah Guardian',
      personality: 'Guardian Setia',
      traits: 'Reliable, Traditional, dan Methodical',
      description: `${childName} sangat bisa diandalkan! Kamu detail-oriented dan selalu menepati janji.`,
      strengths: ['Sangat Reliable', 'Methodical', 'Loyal', 'Responsible'],
      tips: 'Hargai konsistensi dan sesekali ajak untuk coba pendekatan baru.',
      color: 'from-gray-400 to-blue-500'
    },
    'ISTP': {
      animal: '🐱',
      name: 'Kucing Mechanic',
      personality: 'Mechanic Cool',
      traits: 'Praktis, Independent, dan Hands-On',
      description: `${childName} hands-on dan suka oprek-oprek! Kamu solve masalah dengan praktek langsung.`,
      strengths: ['Sangat Practical', 'Adaptable', 'Calm', 'Problem-Solver'],
      tips: 'Berikan banyak aktivitas hands-on dan respect kebutuhan personal space.',
      color: 'from-orange-400 to-yellow-500'
    }
  };

  const calculateMBTI = (answers: string[]) => {
    const traits = { E: 0, I: 0, S: 0, N: 0, T: 0, F: 0, J: 0, P: 0 };
    
    answers.forEach(answer => {
      traits[answer as keyof typeof traits]++;
    });

    const result =
      (traits.E > traits.I ? 'E' : 'I') +
      (traits.S > traits.N ? 'S' : 'N') +
      (traits.T > traits.F ? 'T' : 'F') +
      (traits.J > traits.P ? 'J' : 'P');

    return result;
  };

  const handleChoice = (trait: string, choiceIndex: number) => {
    setSelectedChoice(choiceIndex);
    
    setTimeout(() => {
      const newAnswers = [...answers, trait];
      setAnswers(newAnswers);
      setSelectedChoice(null);

      if (currentQuestion < questions.length - 1) {
        setCurrentQuestion(currentQuestion + 1);
      } else {
        // Complete test
        const mbtiType = calculateMBTI(newAnswers);
        const result = animalTypes[mbtiType as keyof typeof animalTypes];
        setMbtiResult(result);
        setIsCompleted(true);
        addSticker('personality-test-complete');
        
        // Save test results
        updateTestResults('personality', {
          type: mbtiType,
          animal: result.name,
          personality: result.personality,
          traits: result.strengths,
          description: result.description,
          tips: result.tips
        });
      }
    }, 600);
  };

  const question = questions[currentQuestion];
  const progress = ((currentQuestion + 1) / questions.length) * 100;

  if (isCompleted && mbtiResult) {
    return (
      <div className={`min-h-screen bg-gradient-to-br ${mbtiResult.color} relative overflow-hidden`}>
        {/* Animated Background */}
        <div className="absolute inset-0">
          {[...Array(30)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-3 h-3 bg-white/20 rounded-full"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
              }}
              animate={{
                y: [0, -30, 0],
                opacity: [0.2, 0.6, 0.2],
              }}
              transition={{
                duration: 3 + Math.random() * 2,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
            />
          ))}
        </div>

        {/* Results Content */}
        <div className="relative z-10 px-6 pt-16 pb-32">
          {/* Animal Emoji */}
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ duration: 1, type: "spring", bounce: 0.5 }}
            className="text-center mb-6"
          >
            <motion.div
              animate={{ 
                scale: [1, 1.15, 1],
                rotate: [0, 5, -5, 0]
              }}
              transition={{ 
                duration: 3,
                repeat: Infinity,
                ease: "easeInOut"
              }}
              className="text-9xl inline-block relative"
            >
              {mbtiResult.animal}
              <motion.div
                className="absolute -top-6 -right-6 text-4xl"
                animate={{ rotate: 360, scale: [1, 1.3, 1] }}
                transition={{ duration: 3, repeat: Infinity }}
              >
                ✨
              </motion.div>
            </motion.div>
          </motion.div>

          {/* Title */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="text-center text-white mb-8"
          >
            <h1 className="text-5xl font-bold font-fredoka mb-3">
              {mbtiResult.name}
            </h1>
            <p className="text-2xl font-medium opacity-90">
              {mbtiResult.personality}
            </p>
            <p className="text-lg opacity-80 mt-1">
              {mbtiResult.traits}
            </p>
          </motion.div>

          {/* Description Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
            className="bg-white/95 backdrop-blur-sm rounded-3xl p-6 mb-6 shadow-2xl"
          >
            <div className="flex items-center gap-2 mb-4">
              <Sparkles className="text-purple-500" size={24} />
              <h3 className="text-xl font-bold font-fredoka text-gray-800">
                Tentang Kepribadianmu
              </h3>
            </div>
            <p className="text-gray-700 leading-relaxed text-lg">
              {mbtiResult.description}
            </p>
          </motion.div>

          {/* Strengths Grid */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="bg-white/95 backdrop-blur-sm rounded-3xl p-6 mb-6 shadow-2xl"
          >
            <div className="flex items-center gap-2 mb-4">
              <Star className="text-yellow-500" size={24} />
              <h3 className="text-xl font-bold font-fredoka text-gray-800">
                Kekuatan Kamu ✨
              </h3>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {mbtiResult.strengths.map((strength: string, index: number) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, scale: 0.5 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.9 + index * 0.1 }}
                  className={`bg-gradient-to-r ${mbtiResult.color} text-white rounded-2xl p-4 text-center shadow-lg`}
                  whileHover={{ scale: 1.05, y: -3 }}
                >
                  <p className="font-bold text-sm leading-tight">
                    {strength}
                  </p>
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ duration: 4, repeat: Infinity, ease: "linear" }}
                    className="text-2xl mt-2"
                  >
                    ⭐
                  </motion.div>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Tips for Parents */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.3 }}
            className="bg-gradient-to-r from-orange-50 to-yellow-50 rounded-3xl p-6 shadow-xl border-2 border-orange-200"
          >
            <div className="flex items-center gap-2 mb-3">
              <motion.div
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="text-3xl"
              >
                💡
              </motion.div>
              <h3 className="text-xl font-bold font-fredoka text-orange-700">
                Tips untuk Orang Tua
              </h3>
            </div>
            <p className="text-orange-600 leading-relaxed text-lg">
              {mbtiResult.tips}
            </p>
          </motion.div>

          {/* Back Button */}
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.5 }}
            onClick={() => navigateTo('home')}
            className="w-full mt-8 bg-white text-gray-800 py-5 px-6 rounded-3xl font-bold text-xl shadow-2xl flex items-center justify-center gap-3"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <span>Kembali ke Home</span>
            <span className="text-2xl">🏠</span>
          </motion.button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-400 via-purple-400 to-pink-400 relative overflow-hidden">
      {/* Animated Background */}
      <div className="absolute inset-0">
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute text-3xl opacity-20"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
            }}
            animate={{
              y: [0, -30, 0],
              rotate: [0, 360],
              opacity: [0.1, 0.3, 0.1],
            }}
            transition={{
              duration: 4 + Math.random() * 3,
              repeat: Infinity,
              delay: Math.random() * 2,
            }}
          >
            {['⭐', '✨', '💫', '🌟', '💝', '🎈'][Math.floor(Math.random() * 6)]}
          </motion.div>
        ))}
      </div>

      {/* Header */}
      <div className="relative z-10 px-6 pt-12 pb-6">
        <button 
          className="w-10 h-10 bg-white/90 rounded-full flex items-center justify-center text-gray-700 mb-4 shadow-lg"
          onClick={() => navigateTo('home')}
        >
          <ArrowLeft size={20} />
        </button>

        {/* Progress Bar */}
        <div className="bg-white/30 rounded-full h-4 mb-3 overflow-hidden shadow-lg">
          <motion.div
            className="bg-white h-full rounded-full shadow-lg flex items-center justify-end pr-2"
            initial={{ width: 0 }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.5 }}
          >
            <span className="text-xs font-bold text-purple-600">
              {Math.round(progress)}%
            </span>
          </motion.div>
        </div>

        <p className="text-white/90 text-base font-bold text-center drop-shadow-lg">
          🎯 Pertanyaan {currentQuestion + 1} dari {questions.length}
        </p>
      </div>

      {/* Question Content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentQuestion}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -50 }}
          transition={{ duration: 0.4 }}
          className="relative z-10 px-6 pb-32"
        >
          {/* Large Emoji */}
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ type: "spring", bounce: 0.6 }}
            className="text-center mb-6"
          >
            <motion.div
              animate={{ 
                scale: [1, 1.1, 1],
                rotate: [0, 10, -10, 0]
              }}
              transition={{ 
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut"
              }}
              className="text-9xl inline-block drop-shadow-2xl"
            >
              {question.emoji}
            </motion.div>
          </motion.div>

          {/* Situation Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-white/95 backdrop-blur-sm rounded-3xl p-6 mb-6 shadow-2xl border-2 border-white/50"
          >
            <p className="text-gray-900 font-bold text-2xl text-center leading-relaxed">
              {question.situation}
            </p>
          </motion.div>

          {/* Choices - 4 options with big emojis */}
          <div className="space-y-3">
            {question.choices.map((choice, index) => (
              <motion.button
                key={index}
                initial={{ opacity: 0, x: -30 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 + index * 0.1 }}
                onClick={() => handleChoice(choice.trait, index)}
                disabled={selectedChoice !== null}
                className={`w-full bg-white/95 backdrop-blur-sm rounded-3xl p-5 shadow-xl border-3 transition-all ${
                  selectedChoice === index
                    ? 'border-green-400 scale-105 bg-green-50'
                    : 'border-white/50 hover:border-purple-300 hover:scale-102'
                }`}
                whileHover={{ scale: selectedChoice === null ? 1.02 : 1 }}
                whileTap={{ scale: selectedChoice === null ? 0.98 : 1 }}
              >
                <div className="flex items-center gap-4">
                  {/* Big Emoji */}
                  <motion.div 
                    className="text-5xl flex-shrink-0"
                    animate={selectedChoice === index ? { 
                      scale: [1, 1.2, 1],
                      rotate: [0, 10, -10, 0]
                    } : {}}
                    transition={{ duration: 0.5 }}
                  >
                    {choice.emoji}
                  </motion.div>
                  
                  {/* Text */}
                  <div className="flex-1 text-left">
                    <p className="text-gray-900 font-bold text-lg leading-snug">
                      {choice.text}
                    </p>
                  </div>
                  
                  {/* Check Mark */}
                  {selectedChoice === index && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1, rotate: 360 }}
                      className="text-4xl"
                    >
                      ✅
                    </motion.div>
                  )}
                </div>
              </motion.button>
            ))}
          </div>
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
