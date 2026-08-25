import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, BookOpen, Video, FileText, Clock, Star, ChevronRight } from 'lucide-react';

interface ParentGuideScreenProps {
  navigateTo: (screen: string) => void;
  childName: string;
}

export default function ParentGuideScreen({ navigateTo, childName }: ParentGuideScreenProps) {
  const [activeCategory, setActiveCategory] = useState('all');

  const guides = [
    {
      id: 1,
      title: 'Panduan Tes Kognitif',
      description: 'Memahami hasil tes kognitif anak',
      category: 'cognitive',
      type: 'pdf',
      duration: '15 min',
      icon: '🧠'
    },
    {
      id: 2,
      title: 'Stimulasi Bahasa',
      description: 'Tingkatkan kemampuan berbahasa',
      category: 'language',
      type: 'video',
      duration: '12 min',
      icon: '📚'
    },
    {
      id: 3,
      title: 'Gaya Belajar Anak',
      description: 'Identifikasi cara belajar optimal',
      category: 'learning',
      type: 'article',
      duration: '8 min',
      icon: '🎨'
    },
    {
      id: 4,
      title: 'Kelola Emosi Anak',
      description: 'Strategi menghadapi tantrum',
      category: 'emotion',
      type: 'video',
      duration: '20 min',
      icon: '❤️'
    },
    {
      id: 5,
      title: 'Milestone Perkembangan',
      description: 'Checklist usia 5-12 tahun',
      category: 'development',
      type: 'pdf',
      duration: '10 min',
      icon: '📋'
    },
    {
      id: 6,
      title: 'Rutina Belajar',
      description: 'Ciptakan lingkungan positif',
      category: 'learning',
      type: 'article',
      duration: '6 min',
      icon: '⏰'
    }
  ];

  const categories = [
    { id: 'all', label: 'Semua', icon: '📚' },
    { id: 'cognitive', label: 'Kognitif', icon: '🧠' },
    { id: 'language', label: 'Bahasa', icon: '💬' },
    { id: 'learning', label: 'Belajar', icon: '🎓' },
    { id: 'emotion', label: 'Emosi', icon: '❤️' },
    { id: 'development', label: 'Tumbuh', icon: '🌱' }
  ];

  const filteredGuides = activeCategory === 'all' 
    ? guides 
    : guides.filter(guide => guide.category === activeCategory);

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'video':
        return <Video className="w-4 h-4" />;
      case 'pdf':
        return <FileText className="w-4 h-4" />;
      default:
        return <BookOpen className="w-4 h-4" />;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="px-6 pt-14 pb-6">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              onClick={() => navigateTo('home')}
              className="p-2 rounded-xl bg-gray-100"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-gray-700" />
            </motion.button>
            <h1 className="text-gray-900 font-heading">Panduan Orang Tua</h1>
            <div className="w-10" />
          </div>
          <p className="text-gray-600 text-sm text-center">
            Panduan praktis untuk mendukung {childName}
          </p>
        </div>
      </div>

      {/* Categories */}
      <div className="px-6 py-4 bg-white border-b border-gray-100">
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
          {categories.map((cat) => (
            <motion.button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`flex-shrink-0 px-4 py-2 rounded-full text-sm whitespace-nowrap ${
                activeCategory === cat.id
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
              whileTap={{ scale: 0.95 }}
            >
              <span className="mr-1.5">{cat.icon}</span>
              {cat.label}
            </motion.button>
          ))}
        </div>
      </div>

      {/* Guide Cards */}
      <div className="px-6 py-6">
        <div className="space-y-3">
          {filteredGuides.map((guide, index) => (
            <motion.div
              key={guide.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
              className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100"
              whileTap={{ scale: 0.98 }}
            >
              <div className="flex items-start gap-4">
                {/* Icon */}
                <div className="flex-shrink-0 w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
                  <span className="text-2xl">{guide.icon}</span>
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <h3 className="text-gray-900 font-heading text-base mb-1">
                    {guide.title}
                  </h3>
                  <p className="text-gray-600 text-sm mb-3 line-clamp-1">
                    {guide.description}
                  </p>
                  
                  {/* Meta */}
                  <div className="flex items-center gap-3 text-xs text-gray-500">
                    <div className="flex items-center gap-1">
                      {getTypeIcon(guide.type)}
                      <span className="capitalize">{guide.type}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>{guide.duration}</span>
                    </div>
                  </div>
                </div>

                {/* Arrow */}
                <ChevronRight className="w-5 h-5 text-gray-400 flex-shrink-0" />
              </div>
            </motion.div>
          ))}
        </div>

        {filteredGuides.length === 0 && (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📚</div>
            <p className="text-gray-500">Belum ada panduan di kategori ini</p>
          </div>
        )}
      </div>

      {/* Quick Tips */}
      <div className="px-6 pb-8">
        <div className="bg-gradient-to-r from-blue-500 to-purple-500 rounded-2xl p-6 text-white">
          <div className="flex items-start gap-3">
            <Star className="w-6 h-6 flex-shrink-0 mt-1" />
            <div>
              <h3 className="font-heading text-lg mb-2">Tips Cepat</h3>
              <p className="text-blue-50 text-sm mb-3">
                Konsistensi adalah kunci! Lakukan aktivitas belajar secara rutin setiap hari, meski hanya 15-20 menit.
              </p>
              <motion.button
                className="bg-white/20 backdrop-blur-sm px-4 py-2 rounded-xl text-sm"
                whileTap={{ scale: 0.95 }}
              >
                Lihat Tips Lainnya
              </motion.button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
