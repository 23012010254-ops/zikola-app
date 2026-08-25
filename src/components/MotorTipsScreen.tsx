import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Home, MessageSquare, BarChart3, User, Users, Play, Download, Clock, FileText, Trophy, Gamepad2 } from 'lucide-react';

interface MotorTipsScreenProps {
  navigateTo: (screen: string) => void;
  isParentMode: boolean;
  childAge?: number; // From survey data
  addSticker?: (sticker: string) => void;
}

export default function MotorTipsScreen({ navigateTo, isParentMode, childAge = 6, addSticker }: MotorTipsScreenProps) {
  const [selectedCategory, setSelectedCategory] = useState<'gross' | 'fine'>('gross');

  // Age-appropriate content based on survey data
  const getAgeGroup = (age: number) => {
    if (age >= 5 && age <= 7) return 'early';
    if (age >= 8 && age <= 10) return 'middle';
    return 'late'; // 11-12
  };

  const ageGroup = getAgeGroup(childAge);

  const motorTips = {
    gross: {
      title: 'Motorik Kasar',
      icon: '🏃‍♂️',
      description: 'Gerakan otot-otot besar seperti berjalan, berlari, melompat',
      color: 'from-blue-500 to-blue-600',
      early: [
        {
          title: 'Bermain Bola Sederhana',
          type: 'video',
          duration: '8 menit',
          description: 'Latihan menendang, melempar, dan menangkap bola dengan cara yang menyenangkan',
          thumbnail: '⚽',
          difficulty: 'Mudah',
          benefits: ['Koordinasi mata-kaki', 'Keseimbangan', 'Konsentrasi']
        },
        {
          title: 'Senam Pagi Anak',
          type: 'video',
          duration: '12 menit',
          description: 'Gerakan senam sederhana untuk mengembangkan fleksibilitas dan kekuatan',
          thumbnail: '🤸‍♀️',
          difficulty: 'Mudah',
          benefits: ['Fleksibilitas', 'Kekuatan otot', 'Koordinasi']
        },
        {
          title: 'Permainan Lari Obstacle',
          type: 'pdf',
          pages: '6 halaman',
          description: 'Panduan membuat track obstacle sederhana di rumah',
          thumbnail: '🏃‍♂️',
          difficulty: 'Mudah',
          benefits: ['Kelincahan', 'Kecepatan', 'Problem solving']
        },
        {
          title: 'Yoga untuk Anak Pemula',
          type: 'video',
          duration: '15 menit',
          description: 'Pose yoga dasar yang aman dan menyenangkan untuk anak',
          thumbnail: '🧘‍♀️',
          difficulty: 'Mudah',
          benefits: ['Keseimbangan', 'Konsentrasi', 'Relaksasi']
        }
      ],
      middle: [
        {
          title: 'Basketball Skills Basic',
          type: 'video',
          duration: '18 menit',
          description: 'Teknik dasar basket: dribbling, shooting, passing',
          thumbnail: '🏀',
          difficulty: 'Sedang',
          benefits: ['Koordinasi tangan-mata', 'Timing', 'Konsentrasi']
        },
        {
          title: 'Gymnastics Fun',
          type: 'video',
          duration: '20 menit',
          description: 'Gerakan senam lantai sederhana yang aman',
          thumbnail: '🤸‍♀️',
          difficulty: 'Sedang',
          benefits: ['Fleksibilitas', 'Kekuatan', 'Kepercayaan diri']
        },
        {
          title: 'Martial Arts untuk Anak',
          type: 'pdf',
          pages: '12 halaman',
          description: 'Gerakan dasar beladiri yang fokus pada disiplin dan kontrol',
          thumbnail: '🥋',
          difficulty: 'Sedang',
          benefits: ['Disiplin', 'Koordinasi', 'Fokus']
        }
      ],
      late: [
        {
          title: 'Soccer Training Advanced',
          type: 'video',
          duration: '25 menit',
          description: 'Teknik sepakbola tingkat menengah dengan strategi',
          thumbnail: '⚽',
          difficulty: 'Menantang',
          benefits: ['Strategi', 'Teamwork', 'Atletis']
        },
        {
          title: 'Athletic Training',
          type: 'video',
          duration: '30 menit',
          description: 'Program latihan atletik yang terstruktur',
          thumbnail: '🏃‍♂️',
          difficulty: 'Menantang',
          benefits: ['Stamina', 'Kecepatan', 'Kekuatan']
        }
      ]
    },
    fine: {
      title: 'Motorik Halus',
      icon: '✏️',
      description: 'Gerakan otot-otot kecil seperti menulis, menggambar, memotong',
      color: 'from-purple-500 to-purple-600',
      early: [
        {
          title: 'Finger Painting Fun',
          type: 'video',
          duration: '10 menet',
          description: 'Teknik melukis dengan jari untuk melatih kreativitas',
          thumbnail: '🎨',
          difficulty: 'Mudah',
          benefits: ['Kreativitas', 'Koordinasi jari', 'Ekspresi diri']
        },
        {
          title: 'Origami Sederhana',
          type: 'pdf',
          pages: '8 halaman',
          description: 'Panduan melipat kertas dengan bentuk-bentuk sederhana',
          thumbnail: '📜',
          difficulty: 'Mudah',
          benefits: ['Presisi', 'Konsentrasi', 'Mengikuti instruksi']
        },
        {
          title: 'Playdough Activities',
          type: 'video',
          duration: '12 menit',
          description: 'Berbagai permainan dengan plastisin untuk melatih jari',
          thumbnail: '🎭',
          difficulty: 'Mudah',
          benefits: ['Kekuatan jari', 'Kreativitas', 'Tekstur']
        },
        {
          title: 'Tracing & Writing',
          type: 'pdf',
          pages: '15 halaman',
          description: 'Lembar kerja untuk latihan menebalkan garis dan huruf',
          thumbnail: '✏️',
          difficulty: 'Mudah',
          benefits: ['Kontrol pensil', 'Menulis', 'Konsentrasi']
        }
      ],
      middle: [
        {
          title: 'Advanced Drawing',
          type: 'video',
          duration: '20 menit',
          description: 'Teknik menggambar dengan detail dan proporsi',
          thumbnail: '🖊️',
          difficulty: 'Sedang',
          benefits: ['Detail', 'Presisi', 'Artistik']
        },
        {
          title: 'Paper Craft Projects',
          type: 'pdf',
          pages: '18 halaman',
          description: 'Proyek kerajinan kertas yang lebih kompleks',
          thumbnail: '📄',
          difficulty: 'Sedang',
          benefits: ['Perencanaan', 'Eksekusi', 'Kreativitas']
        },
        {
          title: 'Beading & Threading',
          type: 'video',
          duration: '15 menit',
          description: 'Membuat gelang dan kalung dengan manik-manik',
          thumbnail: '📿',
          difficulty: 'Sedang',
          benefits: ['Koordinasi mata-tangan', 'Pola', 'Kesabaran']
        }
      ],
      late: [
        {
          title: 'Calligraphy Basic',
          type: 'video',
          duration: '25 menit',
          description: 'Seni menulis indah dengan teknik kaligrafi',
          thumbnail: '🖋️',
          difficulty: 'Menantang',
          benefits: ['Presisi tinggi', 'Estetika', 'Konsentrasi']
        },
        {
          title: 'Model Making',
          type: 'pdf',
          pages: '20 halaman',
          description: 'Membuat model 3D dengan bahan sederhana',
          thumbnail: '🏗️',
          difficulty: 'Menantang',
          benefits: ['Perencanaan 3D', 'Problem solving', 'Teknis']
        }
      ]
    }
  };

  const currentTips = motorTips[selectedCategory][ageGroup];

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Mudah': return 'bg-green-100 text-green-700';
      case 'Sedang': return 'bg-yellow-100 text-yellow-700';
      case 'Menantang': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 px-6 pt-14 pb-8 text-white">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6" />
          </motion.button>
          <h1 className="font-heading font-bold text-xl">Tips Motorik</h1>
          <div className="w-10" />
        </div>

        {/* Age Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
        >
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
              <span className="text-2xl">🎯</span>
            </div>
            <div>
              <h3 className="text-white font-heading font-semibold text-base">
                Sesuai Usia {childAge} Tahun
              </h3>
              <p className="text-green-100 text-sm font-body">
                Konten disesuaikan dengan tahap perkembangan anak
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      <div className="px-6 -mt-4 pb-24">
        {/* Category Tabs */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-2 shadow-lg mb-6"
        >
          <div className="grid grid-cols-2 gap-2">
            {Object.entries(motorTips).map(([key, category]) => (
              <motion.button
                key={key}
                onClick={() => setSelectedCategory(key as 'gross' | 'fine')}
                className={`p-4 rounded-xl transition-all ${
                  selectedCategory === key
                    ? 'bg-gradient-to-r from-green-500 to-green-600 text-white shadow-md'
                    : 'text-gray-600 hover:bg-gray-50'
                }`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <div className="text-center">
                  <div className="text-2xl mb-2">{category.icon}</div>
                  <div className="font-heading font-bold text-sm">{category.title}</div>
                  <div className="text-xs opacity-80 mt-1">{category.description}</div>
                </div>
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* Motor Challenge Game */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-green-500 to-green-600 rounded-2xl p-6 text-white shadow-lg mb-6"
        >
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center">
              <Gamepad2 className="w-8 h-8 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-white font-heading font-bold text-lg mb-1">
                Motor Challenge Game
              </h3>
              <p className="text-green-100 font-body text-sm mb-3">
                Tes koordinasi dan gerakan tubuh dengan timer dan 3 nyawa
              </p>
              <div className="flex items-center space-x-4 text-sm">
                <div className="flex items-center space-x-1">
                  <Clock className="w-4 h-4" />
                  <span>8-12 menit</span>
                </div>
                <div className="flex items-center space-x-1">
                  <Trophy className="w-4 h-4" />
                  <span>Motor Master</span>
                </div>
              </div>
            </div>
            <motion.button
              onClick={() => navigateTo('motor-test-game')}
              className="bg-white/20 backdrop-blur-sm text-white px-6 py-3 rounded-xl font-body font-semibold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Main Sekarang
            </motion.button>
          </div>
        </motion.div>

        {/* Tips Content */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-gray-900 font-heading font-bold text-lg">
              {motorTips[selectedCategory].title}
            </h2>
            <span className="text-sm text-gray-500 font-body">
              {currentTips.length} aktivitas
            </span>
          </div>

          {currentTips.map((tip, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100"
            >
              <div className="flex items-start space-x-4">
                {/* Thumbnail */}
                <div className={`w-16 h-16 bg-gradient-to-r ${motorTips[selectedCategory].color} rounded-2xl flex items-center justify-center shadow-sm`}>
                  <span className="text-2xl">{tip.thumbnail}</span>
                </div>

                {/* Content */}
                <div className="flex-1">
                  <div className="flex items-start justify-between mb-2">
                    <h3 className="font-heading font-bold text-base text-gray-900">
                      {tip.title}
                    </h3>
                    <div className="flex items-center space-x-2">
                      {tip.type === 'video' ? (
                        <div className="flex items-center space-x-1 text-xs text-blue-600 bg-blue-50 px-2 py-1 rounded-lg">
                          <Play className="w-3 h-3" />
                          <span>{tip.duration}</span>
                        </div>
                      ) : (
                        <div className="flex items-center space-x-1 text-xs text-purple-600 bg-purple-50 px-2 py-1 rounded-lg">
                          <FileText className="w-3 h-3" />
                          <span>{tip.pages}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  <p className="text-gray-600 font-body text-sm mb-3 leading-relaxed">
                    {tip.description}
                  </p>

                  {/* Difficulty and Benefits */}
                  <div className="flex items-center justify-between mb-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-body font-medium ${getDifficultyColor(tip.difficulty)}`}>
                      {tip.difficulty}
                    </span>
                  </div>

                  {/* Benefits */}
                  <div className="mb-4">
                    <div className="text-xs text-gray-500 font-body mb-2">Manfaat:</div>
                    <div className="flex flex-wrap gap-2">
                      {tip.benefits.map((benefit, benefitIndex) => (
                        <span
                          key={benefitIndex}
                          className="bg-green-50 text-green-700 px-2 py-1 rounded-lg text-xs font-body"
                        >
                          {benefit}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex space-x-3">
                    <motion.button
                      className={`flex-1 ${
                        tip.type === 'video' 
                          ? 'bg-blue-500 hover:bg-blue-600' 
                          : 'bg-purple-500 hover:bg-purple-600'
                      } text-white px-4 py-2 rounded-xl font-body font-semibold text-sm flex items-center justify-center space-x-2`}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => {
                        // Simulate opening content
                        alert(`Membuka ${tip.type === 'video' ? 'video' : 'PDF'}: ${tip.title}`);
                        // Award sticker for exploring tips
                        if (addSticker) {
                          addSticker('tips-explorer');
                        }
                      }}
                    >
                      {tip.type === 'video' ? (
                        <>
                          <Play className="w-4 h-4" />
                          <span>Tonton</span>
                        </>
                      ) : (
                        <>
                          <Download className="w-4 h-4" />
                          <span>Download</span>
                        </>
                      )}
                    </motion.button>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-gradient-to-r from-orange-50 to-yellow-50 border border-orange-200 rounded-2xl p-6 mt-8"
        >
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
              <span className="text-2xl">💡</span>
            </div>
            <div>
              <h3 className="text-orange-700 font-heading font-bold text-base mb-1">
                Tips untuk Orang Tua
              </h3>
              <p className="text-orange-600 font-body text-sm leading-relaxed">
                Dampingi anak saat melakukan aktivitas dan berikan pujian atas usahanya. 
                Konsistensi latihan lebih penting daripada kesempurnaan.
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Bottom Navigation - FIXED: Added Community with Users icon */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-100">
        <div className="flex justify-around py-3">
          {[
            { icon: Home, label: 'Beranda', screen: 'home' },
            { icon: MessageSquare, label: 'Konsultasi', screen: isParentMode ? 'consultation' : 'tips' },
            { icon: Users, label: 'Komunitas', screen: 'community' },
            { icon: BarChart3, label: 'Progres', screen: 'progress' },
            { icon: User, label: 'Profil', screen: 'profile' }
          ].map((item) => (
            <motion.button
              key={item.screen}
              onClick={() => navigateTo(item.screen)}
              className="flex flex-col items-center space-y-1 py-2 px-2 text-gray-400"
              whileTap={{ scale: 0.95 }}
            >
              <item.icon size={18} />
              <span className="text-xs font-body font-medium">{item.label}</span>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}