import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Star, Home, MessageSquare, BarChart3, User, Sparkles } from 'lucide-react';

interface PersonalityTestScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
  childName: string;
  isParentMode?: boolean;
  setMbtiResult?: (result: any) => void;
  updateTestResults: (testType: string, results: any) => void;
}

export default function PersonalityTestScreen({ navigateTo, addSticker, childName, isParentMode, setMbtiResult, updateTestResults }: PersonalityTestScreenProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<string[]>([]);
  const [isCompleted, setIsCompleted] = useState(false);
  const [animalResult, setAnimalResult] = useState<any>(null);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);

  // Enhanced Visual MBTI Questions with better visuals and animations
  const mbtiQuestions = [
    {
      id: 1,
      question: 'Apa yang paling kamu sukai saat bermain?',
      background: 'from-orange-300 to-yellow-300',
      options: [
        { 
          emoji: '🏞️', 
          title: 'Bermain bersama teman', 
          description: 'Seru ramai-ramai',
          trait: 'E',
          color: 'from-orange-400 to-orange-500',
          particles: ['🌟', '✨', '💫']
        },
        { 
          emoji: '🏠', 
          title: 'Bermain sendiri dengan mainan favorit', 
          description: 'Tenang dan fokus',
          trait: 'I',
          color: 'from-blue-400 to-blue-500',
          particles: ['🌙', '⭐', '💤']
        },
        { 
          emoji: '🎮', 
          title: 'Bermain game di gadget', 
          description: 'Seru dan menantang',
          trait: 'I',
          color: 'from-purple-400 to-purple-500',
          particles: ['🎯', '🚀', '⚡']
        },
        { 
          emoji: '📚', 
          title: 'Membaca atau menggambar', 
          description: 'Kreatif dan imajinatif',
          trait: 'N',
          color: 'from-green-400 to-green-500',
          particles: ['🎨', '✏️', '🖍️']
        }
      ]
    },
    {
      id: 2,
      question: 'Ketika belajar hal baru, kamu suka:',
      background: 'from-blue-300 to-purple-300',
      options: [
        { 
          emoji: '🔨', 
          title: 'Langsung praktek', 
          description: 'Coba sendiri dulu',
          trait: 'S',
          color: 'from-orange-400 to-red-500',
          particles: ['⚒️', '🔧', '⚡']
        },
        { 
          emoji: '🤔', 
          title: 'Bertanya dulu', 
          description: 'Kenapa dan bagaimana?',
          trait: 'N',
          color: 'from-blue-400 to-indigo-500',
          particles: ['❓', '💭', '🧠']
        },
        { 
          emoji: '👀', 
          title: 'Lihat orang lain dulu', 
          description: 'Amati terus ikuti',
          trait: 'S',
          color: 'from-purple-400 to-pink-500',
          particles: ['👁️', '🔍', '📖']
        },
        { 
          emoji: '💭', 
          title: 'Bayangin dulu', 
          description: 'Pikir berbagai cara',
          trait: 'N',
          color: 'from-green-400 to-teal-500',
          particles: ['🌈', '💡', '✨']
        }
      ]
    },
    {
      id: 3,
      question: 'Saat harus memilih, kamu biasanya:',
      background: 'from-pink-300 to-red-300',
      options: [
        { 
          emoji: '❤️', 
          title: 'Ikuti perasaan', 
          description: 'Yang bikin senang',
          trait: 'F',
          color: 'from-pink-400 to-red-500',
          particles: ['💖', '💕', '🌹']
        },
        { 
          emoji: '🧠', 
          title: 'Pikir logis', 
          description: 'Yang paling masuk akal',
          trait: 'T',
          color: 'from-blue-400 to-cyan-500',
          particles: ['⚙️', '🔬', '📊']
        },
        { 
          emoji: '👨‍👩‍👧‍👦', 
          title: 'Tanya keluarga', 
          description: 'Yang kata orang tua',
          trait: 'F',
          color: 'from-purple-400 to-indigo-500',
          particles: ['🏡', '💝', '🤗']
        },
        { 
          emoji: '📊', 
          title: 'Bandingkan dulu', 
          description: 'Pilih yang terbaik',
          trait: 'T',
          color: 'from-green-400 to-emerald-500',
          particles: ['📈', '⚖️', '🎯']
        }
      ]
    },
    {
      id: 4,
      question: 'Untuk tugas sekolah, kamu lebih suka:',
      background: 'from-green-300 to-teal-300',
      options: [
        { 
          emoji: '📅', 
          title: 'Kerjakan sesuai jadwal', 
          description: 'Sedikit-sedikit tiap hari',
          trait: 'J',
          color: 'from-blue-400 to-blue-500',
          particles: ['⏰', '📋', '✅']
        },
        { 
          emoji: '⚡', 
          title: 'Kerjakan sekaligus', 
          description: 'Saat lagi mood bagus',
          trait: 'P',
          color: 'from-yellow-400 to-orange-500',
          particles: ['🔥', '💨', '🌟']
        },
        { 
          emoji: '🎯', 
          title: 'Siapkan semua dulu', 
          description: 'Alat dan bahan lengkap',
          trait: 'J',
          color: 'from-purple-400 to-purple-500',
          particles: ['📎', '📌', '🗂️']
        },
        { 
          emoji: '🌈', 
          title: 'Sesuai inspirasi', 
          description: 'Kalau ada ide bagus',
          trait: 'P',
          color: 'from-pink-400 to-rose-500',
          particles: ['💡', '🎨', '✨']
        }
      ]
    },
    {
      id: 5,
      question: 'Kalau bercerita ke teman, kamu:',
      background: 'from-purple-300 to-indigo-300',
      options: [
        { 
          emoji: '📖', 
          title: 'Cerita detail lengkap', 
          description: 'Dari awal sampai akhir',
          trait: 'S',
          color: 'from-blue-400 to-blue-500',
          particles: ['📚', '📝', '📄']
        },
        { 
          emoji: '⭐', 
          title: 'Cerita bagian seru', 
          description: 'Yang paling menarik',
          trait: 'N',
          color: 'from-yellow-400 to-orange-500',
          particles: ['🌟', '✨', '💫']
        },
        { 
          emoji: '🎭', 
          title: 'Cerita sambil acting', 
          description: 'Ekspresif dan dramatis',
          trait: 'N',
          color: 'from-purple-400 to-pink-500',
          particles: ['🎪', '🎨', '🎬']
        },
        { 
          emoji: '📋', 
          title: 'Cerita berurutan', 
          description: 'Step by step',
          trait: 'S',
          color: 'from-green-400 to-teal-500',
          particles: ['📊', '📈', '🔢']
        }
      ]
    },
    {
      id: 6,
      question: 'Kalau teman sedih, kamu akan:',
      background: 'from-teal-300 to-cyan-300',
      options: [
        { 
          emoji: '🤗', 
          title: 'Peluk dan hibur', 
          description: 'Temani sampai merasa baikan',
          trait: 'F',
          color: 'from-pink-400 to-rose-500',
          particles: ['💖', '🌸', '🤍']
        },
        { 
          emoji: '❓', 
          title: 'Tanya kenapa', 
          description: 'Cari tahu masalahnya',
          trait: 'T',
          color: 'from-blue-400 to-indigo-500',
          particles: ['🔍', '🤔', '💭']
        },
        { 
          emoji: '🎈', 
          title: 'Ajak main', 
          description: 'Biar lupa sedihnya',
          trait: 'F',
          color: 'from-orange-400 to-yellow-500',
          particles: ['🎉', '🎊', '🎯']
        },
        { 
          emoji: '💡', 
          title: 'Kasih saran', 
          description: 'Cara mengatasi masalah',
          trait: 'T',
          color: 'from-green-400 to-emerald-500',
          particles: ['⚡', '🧠', '💪']
        }
      ]
    },
    {
      id: 7,
      question: 'Di weekend, kamu lebih suka:',
      background: 'from-yellow-300 to-orange-300',
      options: [
        { 
          emoji: '📝', 
          title: 'Ada rencana jelas', 
          description: 'Tahu mau ngapain dari pagi',
          trait: 'J',
          color: 'from-blue-400 to-blue-500',
          particles: ['📅', '⏰', '✅']
        },
        { 
          emoji: '🎲', 
          title: 'Spontan aja', 
          description: 'Lihat nanti mau apa',
          trait: 'P',
          color: 'from-purple-400 to-pink-500',
          particles: ['🎪', '🎭', '🌈']
        },
        { 
          emoji: '🏡', 
          title: 'Santai di rumah', 
          description: 'Istirahat dan main',
          trait: 'I',
          color: 'from-green-400 to-teal-500',
          particles: ['☕', '🛋️', '📚']
        },
        { 
          emoji: '🚗', 
          title: 'Jalan-jalan', 
          description: 'Explore tempat baru',
          trait: 'E',
          color: 'from-orange-400 to-red-500',
          particles: ['🗺️', '🌍', '✈️']
        }
      ]
    },
    {
      id: 8,
      question: 'Di tempat baru, kamu biasanya:',
      background: 'from-indigo-300 to-purple-300',
      options: [
        { 
          emoji: '🚀', 
          title: 'Langsung eksplorasi', 
          description: 'Cari tahu dan kenalan',
          trait: 'E',
          color: 'from-orange-400 to-red-500',
          particles: ['🌟', '⚡', '🔥']
        },
        { 
          emoji: '👁️', 
          title: 'Observasi dulu', 
          description: 'Lihat-lihat dari jauh',
          trait: 'I',
          color: 'from-blue-400 to-indigo-500',
          particles: ['🔍', '👀', '🤫']
        },
        { 
          emoji: '🤝', 
          title: 'Cari teman baru', 
          description: 'Ajak main bareng',
          trait: 'E',
          color: 'from-pink-400 to-rose-500',
          particles: ['👥', '💕', '🎉']
        },
        { 
          emoji: '🔍', 
          title: 'Cari yang menarik', 
          description: 'Fokus pada hal tertentu',
          trait: 'I',
          color: 'from-green-400 to-emerald-500',
          particles: ['🧭', '📍', '🎯']
        }
      ]
    }
  ];

  // Animal MBTI Results with enhanced descriptions
  const animalTypes = {
    'ENFJ': {
      animal: '🦁',
      name: 'Singa',
      personality: 'Pemimpin Peduli',
      traits: 'Karismatik dan Inspiratif',
      description: 'Anak yang natural jadi pemimpin dan selalu peduli sama teman-temannya!',
      strengths: ['Mudah bergaul', 'Suka membantu', 'Pemimpin natural', 'Empati tinggi'],
      tips: 'Dukung jiwa kepemimpinannya dengan memberikan tanggung jawab kecil dan ajari untuk mendengarkan pendapat orang lain.',
      color: 'from-yellow-400 to-orange-500',
      bgColor: 'from-yellow-50 to-orange-50'
    },
    'ENFP': {
      animal: '🐰',
      name: 'Kelinci',
      personality: 'Petualang Ceria',
      traits: 'Kreatif dan Antusias',
      description: 'Anak yang penuh energi, suka hal baru, dan selalu optimis!',
      strengths: ['Kreatif', 'Mudah beradaptasi', 'Komunikatif', 'Imajinatif'],
      tips: 'Berikan banyak aktivitas kreatif dan hindari rutinitas yang terlalu kaku.',
      color: 'from-pink-400 to-purple-500',
      bgColor: 'from-pink-50 to-purple-50'
    },
    'ENTJ': {
      animal: '🦅',
      name: 'Elang',
      personality: 'Komandan Cilik',
      traits: 'Tegas dan Ambisius',
      description: 'Anak yang punya visi besar dan determinasi kuat untuk mencapai tujuan!',
      strengths: ['Organised', 'Berani', 'Strategis', 'Goal-oriented'],
      tips: 'Tantang dengan target-target yang achievable dan ajarkan fleksibilitas.',
      color: 'from-blue-400 to-indigo-500',
      bgColor: 'from-blue-50 to-indigo-50'
    },
    'ENTP': {
      animal: '🦊',
      name: 'Rubah',
      personality: 'Innovator Pintar',
      traits: 'Cerdik dan Adaptif',
      description: 'Anak yang pintar, suka debat, dan selalu punya ide-ide fresh!',
      strengths: ['Problem solver', 'Quick learner', 'Inovatif', 'Curious'],
      tips: 'Stimulasi rasa ingin tahunya dengan eksperimen dan diskusi yang menantang.',
      color: 'from-orange-400 to-red-500',
      bgColor: 'from-orange-50 to-red-50'
    },
    'ESFJ': {
      animal: '🐨',
      name: 'Koala',
      personality: 'Penolong Setia',
      traits: 'Peduli dan Harmonis',
      description: 'Anak yang hangat, suka membantu, dan jaga perasaan orang lain!',
      strengths: ['Supportive', 'Reliable', 'Team player', 'Caring'],
      tips: 'Apresiasi kebaikannya dan ajarkan untuk kadang-kadang prioritaskan diri sendiri.',
      color: 'from-green-400 to-teal-500',
      bgColor: 'from-green-50 to-teal-50'
    },
    'ESFP': {
      animal: '🐹',
      name: 'Hamster',
      personality: 'Entertainer Lucu',
      traits: 'Fun dan Spontan',
      description: 'Anak yang jadi mood booster di mana-mana dan suka bikin orang senang!',
      strengths: ['Cheerful', 'Spontan', 'People person', 'Praktis'],
      tips: 'Dukung ekspresi dirinya dan ajarkan perencanaan sederhana.',
      color: 'from-yellow-400 to-pink-500',
      bgColor: 'from-yellow-50 to-pink-50'
    },
    'ESTJ': {
      animal: '🐝',
      name: 'Lebah',
      personality: 'Organizer Teliti',
      traits: 'Disiplin dan Sistematis',
      description: 'Anak yang suka kerapihan, punya jadwal jelas, dan reliable banget!',
      strengths: ['Organized', 'Responsible', 'Hardworking', 'Loyal'],
      tips: 'Hargai kedisiplinannya tapi sesekali ajak untuk lebih fleksibel dan spontan.',
      color: 'from-yellow-400 to-orange-500',
      bgColor: 'from-yellow-50 to-orange-50'
    },
    'ESTP': {
      animal: '🐯',
      name: 'Harimau',
      personality: 'Athlete Berani',
      traits: 'Sporty dan Aktif',
      description: 'Anak yang energik, suka tantangan fisik, dan berani coba hal baru!',
      strengths: ['Energetic', 'Adaptable', 'Hands-on', 'Courageous'],
      tips: 'Sediakan banyak aktivitas fisik dan olahraga untuk menyalurkan energinya.',
      color: 'from-orange-400 to-red-500',
      bgColor: 'from-orange-50 to-red-50'
    },
    'INFJ': {
      animal: '🦉',
      name: 'Burung Hantu',
      personality: 'Visioner Lembut',
      traits: 'Bijaksana dan Intuitif',
      description: 'Anak yang dalam, punya insight bagus, dan peduli banget sama orang lain!',
      strengths: ['Insightful', 'Empathetic', 'Creative', 'Idealistic'],
      tips: 'Berikan waktu sendiri untuk recharge dan dukung kreativitasnya.',
      color: 'from-purple-400 to-indigo-500',
      bgColor: 'from-purple-50 to-indigo-50'
    },
    'INFP': {
      animal: '🐼',
      name: 'Panda',
      personality: 'Dreamer Baik',
      traits: 'Sensitif dan Imajinatif',
      description: 'Anak yang punya dunia dalam yang kaya dan selalu peduli keadilan!',
      strengths: ['Creative', 'Authentic', 'Compassionate', 'Open-minded'],
      tips: 'Dukung ekspresi kreatifnya dan hargai sensitivitasnya.',
      color: 'from-green-400 to-blue-500',
      bgColor: 'from-green-50 to-blue-50'
    },
    'INTJ': {
      animal: '🐺',
      name: 'Serigala',
      personality: 'Mastermind Muda',
      traits: 'Strategis dan Independent',
      description: 'Anak yang suka mikir deep, punya rencana jangka panjang, dan mandiri!',
      strengths: ['Strategic', 'Independent', 'Analytical', 'Determined'],
      tips: 'Respect kebutuhan waktu sendiri dan tantang dengan puzzle atau strategi games.',
      color: 'from-gray-400 to-blue-500',
      bgColor: 'from-gray-50 to-blue-50'
    },
    'INTP': {
      animal: '🐧',
      name: 'Penguin',
      personality: 'Scientist Kecil',
      traits: 'Logis dan Eksploratif',
      description: 'Anak yang curious banget, suka experiment, dan selalu tanya "kenapa"!',
      strengths: ['Logical', 'Curious', 'Objective', 'Innovative'],
      tips: 'Fasilitasi rasa ingin tahunya dengan buku, eksperimen, dan diskusi sains.',
      color: 'from-blue-400 to-cyan-500',
      bgColor: 'from-blue-50 to-cyan-50'
    },
    'ISFJ': {
      animal: '🐑',
      name: 'Domba',
      personality: 'Protector Gentle',
      traits: 'Nurturing dan Supportive',
      description: 'Anak yang lembut, selalu siap bantu, dan jaga harmoni di group!',
      strengths: ['Caring', 'Detail-oriented', 'Loyal', 'Patient'],
      tips: 'Apresiasi kebaikannya dan ajarkan untuk assertive saat dibutuhkan.',
      color: 'from-pink-400 to-rose-500',
      bgColor: 'from-pink-50 to-rose-50'
    },
    'ISFP': {
      animal: '🐻',
      name: 'Beruang',
      personality: 'Artist Lembut',
      traits: 'Kreatif dan Peace-loving',
      description: 'Anak yang artistik, kalem, tapi passionate sama hal yang dia suka!',
      strengths: ['Artistic', 'Gentle', 'Flexible', 'Observant'],
      tips: 'Sediakan banyak medium artistik dan berikan ruang untuk eksplorasi kreatif.',
      color: 'from-brown-400 to-orange-500',
      bgColor: 'from-orange-50 to-yellow-50'
    },
    'ISTJ': {
      animal: '🐘',
      name: 'Gajah',
      personality: 'Guardian Setia',
      traits: 'Reliable dan Traditional',
      description: 'Anak yang bisa diandalkan, detail-oriented, dan selalu keep promises!',
      strengths: ['Reliable', 'Methodical', 'Loyal', 'Responsible'],
      tips: 'Hargai konsistensinya dan sesekali ajak untuk coba pendekatan baru.',
      color: 'from-gray-400 to-blue-500',
      bgColor: 'from-gray-50 to-blue-50'
    },
    'ISTP': {
      animal: '🐱',
      name: 'Kucing',
      personality: 'Mechanic Cool',
      traits: 'Praktis dan Independent',
      description: 'Anak yang hands-on, suka oprek-oprek, dan solve masalah dengan praktek!',
      strengths: ['Practical', 'Adaptable', 'Calm', 'Problem-solver'],
      tips: 'Berikan banyak aktivitas hands-on dan respect kebutuhan space-nya.',
      color: 'from-orange-400 to-yellow-500',
      bgColor: 'from-orange-50 to-yellow-50'
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

  const handleAnswer = (trait: string, optionIndex: number) => {
    setSelectedOption(optionIndex);
    
    setTimeout(() => {
      const newAnswers = [...answers, trait];
      setAnswers(newAnswers);
      setSelectedOption(null);

      if (currentQuestion < mbtiQuestions.length - 1) {
        setCurrentQuestion(currentQuestion + 1);
      } else {
        // Complete test
        const mbtiType = calculateMBTI(newAnswers);
        const result = animalTypes[mbtiType as keyof typeof animalTypes];
        setAnimalResult(result);
        setIsCompleted(true);
        addSticker('animal-mbti-complete');
        
        // Save MBTI result to app state
        if (setMbtiResult) {
          setMbtiResult(result);
        }

        // Save test results
        updateTestResults('personality', {
          type: mbtiType,
          animal: result.name,
          personality: result.personality,
          traits: result.strengths,
          description: result.description
        });
      }
    }, 800);
  };

  const currentQ = mbtiQuestions[currentQuestion];
  const progress = ((currentQuestion + 1) / mbtiQuestions.length) * 100;

  if (isCompleted && animalResult) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-400 via-pink-400 to-red-400">
        {/* Animated background particles */}
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(20)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-2 h-2 bg-white rounded-full opacity-60"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
              }}
              animate={{
                y: [0, -20, 0],
                opacity: [0.6, 1, 0.6],
                scale: [1, 1.5, 1],
              }}
              transition={{
                duration: 2 + Math.random() * 2,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
            />
          ))}
        </div>

        <div className="relative z-10 px-6 pt-14 pb-8 text-white">
          <div className="text-center">
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ duration: 1, type: "spring" }}
              className="text-9xl mb-4 relative"
            >
              <motion.div
                animate={{ 
                  scale: [1, 1.1, 1],
                  rotate: [0, 5, -5, 0]
                }}
                transition={{ 
                  duration: 3,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
              >
                {animalResult.animal}
              </motion.div>
              {/* Sparkle effects */}
              <div className="absolute -top-4 -right-4">
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 2, repeat: Infinity }}
                  className="text-2xl"
                >
                  ✨
                </motion.div>
              </div>
              <div className="absolute -bottom-4 -left-4">
                <motion.div
                  animate={{ rotate: -360 }}
                  transition={{ duration: 2, repeat: Infinity, delay: 1 }}
                  className="text-2xl"
                >
                  🌟
                </motion.div>
              </div>
            </motion.div>
            
            <motion.h1 
              className="font-heading font-bold text-3xl mb-2"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
            >
              Kamu adalah {animalResult.name}!
            </motion.h1>
            <motion.p 
              className="text-white/90 text-xl font-body mb-2"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7 }}
            >
              {animalResult.personality}
            </motion.p>
            <motion.p 
              className="text-white/80 text-lg font-body"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.9 }}
            >
              {animalResult.traits}
            </motion.p>
          </div>
        </div>

        <div className="px-6 py-6 pb-32">
          {/* Description */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.1 }}
            className={`bg-gradient-to-r ${animalResult.bgColor} rounded-3xl p-6 shadow-xl mb-6 border-2 border-white/20`}
          >
            <h3 className="font-heading font-bold text-xl mb-3 text-center text-gray-800 flex items-center justify-center">
              <Sparkles className="w-6 h-6 text-purple-500 mr-2" />
              Tentang Kepribadianmu
            </h3>
            <p className="text-gray-700 font-body text-center leading-relaxed text-lg">
              {animalResult.description}
            </p>
          </motion.div>

          {/* Strengths with enhanced animation */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.3 }}
            className="bg-white/95 rounded-3xl p-6 shadow-xl mb-6 border-2 border-white/30"
          >
            <h3 className="font-heading font-bold text-xl mb-4 flex items-center text-gray-800">
              <Star className="w-6 h-6 text-yellow-500 mr-2" />
              Kekuatan Kamu
            </h3>
            <div className="grid grid-cols-2 gap-4">
              {animalResult.strengths.map((strength: string, index: number) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, scale: 0.8, x: -20 }}
                  animate={{ opacity: 1, scale: 1, x: 0 }}
                  transition={{ delay: 1.5 + index * 0.2 }}
                  className={`bg-gradient-to-r ${animalResult.color} text-white rounded-2xl p-4 text-center shadow-lg transform hover:scale-105 transition-all`}
                  whileHover={{ scale: 1.05, y: -5 }}
                >
                  <span className="font-body font-bold text-base">
                    {strength}
                  </span>
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ duration: 4, repeat: Infinity }}
                    className="text-xl mt-2"
                  >
                    ⭐
                  </motion.div>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Tips for Parents with enhanced styling */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.7 }}
            className="bg-gradient-to-r from-orange-100 to-yellow-100 border-2 border-orange-300 rounded-3xl p-6 shadow-xl"
          >
            <h3 className="font-heading font-bold text-xl mb-3 text-orange-700 flex items-center">
              <motion.div
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="mr-2 text-2xl"
              >
                💡
              </motion.div>
              Tips untuk Orang Tua
            </h3>
            <p className="text-orange-600 font-body leading-relaxed text-lg">
              {animalResult.tips}
            </p>
          </motion.div>

          {/* Action Button with enhanced animation */}
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1.9 }}
            onClick={() => navigateTo('progress')}
            className={`w-full mt-8 bg-gradient-to-r ${animalResult.color} text-white py-5 px-6 rounded-3xl font-heading font-bold text-xl shadow-2xl`}
            whileHover={{ scale: 1.02, y: -2 }}
            whileTap={{ scale: 0.98 }}
          >
            <motion.div
              animate={{ x: [0, 10, 0] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="flex items-center justify-center"
            >
              📊 Lihat Progress Dashboard
            </motion.div>
          </motion.button>
        </div>

        {/* Bottom Navigation */}
        <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white/95 backdrop-blur-sm border-t border-gray-200">
          <div className="flex justify-around py-3">
            {[
              { icon: Home, label: 'Beranda', screen: 'home' },
              { icon: MessageSquare, label: 'Konsultasi', screen: isParentMode ? 'consultation' : 'tips' },
              { icon: BarChart3, label: 'Progres', screen: 'progress' },
              { icon: User, label: 'Profil', screen: 'profile' }
            ].map((item) => (
              <motion.button
                key={item.screen}
                onClick={() => navigateTo(item.screen)}
                className="flex flex-col items-center space-y-1 py-2 px-3 text-gray-400"
                whileTap={{ scale: 0.95 }}
                whileHover={{ scale: 1.05 }}
              >
                <item.icon size={20} />
                <span className="text-xs font-body font-medium">{item.label}</span>
              </motion.button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`min-h-screen bg-gradient-to-br ${currentQ.background} relative overflow-hidden`}>
      {/* Enhanced animated background */}
      <div className="absolute inset-0">
        {[...Array(15)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-3 h-3 bg-white/30 rounded-full"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
            }}
            animate={{
              y: [0, -30, 0],
              x: [0, Math.random() * 20 - 10, 0],
              opacity: [0.3, 0.8, 0.3],
              scale: [1, 1.5, 1],
            }}
            transition={{
              duration: 3 + Math.random() * 2,
              repeat: Infinity,
              delay: Math.random() * 2,
            }}
          />
        ))}
      </div>

      {/* Header */}
      <div className="relative z-10 px-6 pt-14 pb-6 text-white">
        <div className="flex items-center justify-between mb-4">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-3 rounded-2xl bg-white/20 backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
            whileHover={{ scale: 1.05 }}
          >
            <ArrowLeft className="w-6 h-6" />
          </motion.button>
          <h1 className="font-heading font-bold text-2xl">Tes Kepribadian</h1>
          <div className="w-12" />
        </div>

        {/* Enhanced Progress Bar */}
        <div className="w-full bg-white/20 rounded-full h-3 mb-2 overflow-hidden">
          <motion.div
            className="bg-white h-3 rounded-full shadow-lg"
            initial={{ width: 0 }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.5, ease: "easeOut" }}
          />
        </div>
        <div className="text-center text-white/90 text-sm font-medium">
          Pertanyaan {currentQuestion + 1} dari {mbtiQuestions.length}
        </div>
      </div>

      <div className="relative z-10 px-6 py-6 pb-32">
        <motion.div
          key={currentQ.id}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -50 }}
          className="bg-white/95 backdrop-blur-sm rounded-3xl p-6 shadow-2xl border border-white/50"
        >
          {/* Question with enhanced styling */}
          <div className="text-center mb-8">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.3, type: "spring" }}
              className="text-6xl mb-4"
            >
              🤔
            </motion.div>
            <h2 className="font-heading font-bold text-2xl text-gray-900 leading-tight mb-6">
              {currentQ.question}
            </h2>
          </div>

          {/* Enhanced Visual Answer Options */}
          <div className="grid grid-cols-2 gap-4">
            {currentQ.options.map((option, index) => (
              <motion.button
                key={index}
                onClick={() => handleAnswer(option.trait, index)}
                className={`relative w-full p-5 text-center border-3 rounded-3xl transition-all overflow-hidden ${
                  selectedOption === index 
                    ? 'border-white shadow-2xl scale-105 bg-white' 
                    : 'border-white/50 bg-white/90 hover:bg-white hover:border-white hover:scale-102'
                }`}
                initial={{ opacity: 0, y: 20, scale: 0.9 }}
                animate={{ opacity: 1, y: 0, scale: selectedOption === index ? 1.05 : 1 }}
                transition={{ delay: index * 0.1 }}
                whileHover={{ scale: selectedOption === index ? 1.05 : 1.02, y: -5 }}
                whileTap={{ scale: 0.95 }}
                disabled={selectedOption !== null}
              >
                {/* Background gradient effect */}
                <div className={`absolute inset-0 bg-gradient-to-br ${option.color} opacity-10 rounded-3xl`} />
                
                {/* Floating particles for selected option */}
                {selectedOption === index && (
                  <div className="absolute inset-0">
                    {option.particles.map((particle, pIndex) => (
                      <motion.div
                        key={pIndex}
                        className="absolute text-2xl"
                        style={{
                          left: `${20 + pIndex * 30}%`,
                          top: `${20 + pIndex * 20}%`,
                        }}
                        animate={{
                          y: [0, -20, 0],
                          rotate: [0, 360],
                          scale: [1, 1.5, 1],
                        }}
                        transition={{
                          duration: 1,
                          delay: pIndex * 0.2,
                        }}
                      >
                        {particle}
                      </motion.div>
                    ))}
                  </div>
                )}
                
                <div className="relative z-10">
                  <motion.div 
                    className="text-7xl mb-4"
                    animate={selectedOption === index ? { 
                      scale: [1, 1.3, 1.1],
                      rotate: [0, 10, -10, 0]
                    } : {}}
                    transition={{ duration: 0.8 }}
                  >
                    {option.emoji}
                  </motion.div>
                  <div className="font-heading font-bold text-base text-gray-800 mb-2 leading-tight">
                    {option.title}
                  </div>
                  <div className="font-body text-sm text-gray-600 leading-tight">
                    {option.description}
                  </div>
                </div>

                {/* Selection effect */}
                {selectedOption === index && (
                  <motion.div
                    className="absolute inset-0 border-4 border-green-400 rounded-3xl"
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ duration: 0.3 }}
                  />
                )}
              </motion.button>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white/95 backdrop-blur-sm border-t border-gray-200">
        <div className="flex justify-around py-3">
          {[
            { icon: Home, label: 'Beranda', screen: 'home' },
            { icon: MessageSquare, label: 'Konsultasi', screen: isParentMode ? 'consultation' : 'tips' },
            { icon: BarChart3, label: 'Progres', screen: 'progress' },
            { icon: User, label: 'Profil', screen: 'profile' }
          ].map((item) => (
            <motion.button
              key={item.screen}
              onClick={() => navigateTo(item.screen)}
              className="flex flex-col items-center space-y-1 py-2 px-3 text-gray-400"
              whileTap={{ scale: 0.95 }}
              whileHover={{ scale: 1.05 }}
            >
              <item.icon size={20} />
              <span className="text-xs font-body font-medium">{item.label}</span>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}