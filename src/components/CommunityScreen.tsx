import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, MessageSquare, Heart, Clock, Plus, Send, ThumbsUp } from 'lucide-react';

interface CommunityScreenProps {
  navigateTo: (screen: string) => void;
  childName: string;
  isParentMode?: boolean;
}

export default function CommunityScreen({ navigateTo, childName, isParentMode }: CommunityScreenProps) {
  const [activeTab, setActiveTab] = useState('trending');
  const [likedPosts, setLikedPosts] = useState<number[]>([]);

  const posts = [
    {
      id: 1,
      author: 'Bunda Sarah',
      avatar: '👩',
      time: '2 jam lalu',
      content: 'Anak saya (7th) baru mulai belajar membaca. Ada tips membuat dia lebih semangat?',
      likes: 12,
      comments: 8,
      category: 'Tips'
    },
    {
      id: 2,
      author: 'Papa Ahmad',
      avatar: '👨',
      time: '5 jam lalu',
      content: 'Sharing hasil tes kognitif: Matematika 85%, Bahasa 92%! Ada peningkatan dari bulan lalu 🙏',
      likes: 24,
      comments: 15,
      category: 'Pencapaian'
    },
    {
      id: 3,
      author: 'Mama Lisa',
      avatar: '👩',
      time: '1 hari lalu',
      content: 'Anak saya (6th) susah fokus saat belajar. Ada yang punya pengalaman serupa?',
      likes: 18,
      comments: 22,
      category: 'Tanya'
    },
    {
      id: 4,
      author: 'Bunda Fitri',
      avatar: '👩',
      time: '2 hari lalu',
      content: 'Game puzzle di ANAK sangat membantu melatih logika anak! Recommended!',
      likes: 31,
      comments: 12,
      category: 'Review'
    }
  ];

  const tabs = [
    { id: 'trending', label: 'Trending', icon: '🔥' },
    { id: 'recent', label: 'Terbaru', icon: '⏰' },
    { id: 'following', label: 'Mengikuti', icon: '👥' }
  ];

  const categories = [
    { label: 'Tips', color: 'bg-blue-100 text-blue-700' },
    { label: 'Pencapaian', color: 'bg-green-100 text-green-700' },
    { label: 'Tanya', color: 'bg-orange-100 text-orange-700' },
    { label: 'Review', color: 'bg-purple-100 text-purple-700' }
  ];

  const toggleLike = (postId: number) => {
    setLikedPosts(prev => 
      prev.includes(postId) 
        ? prev.filter(id => id !== postId)
        : [...prev, postId]
    );
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm sticky top-0 z-10">
        <div className="px-6 pt-14 pb-4">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              onClick={() => navigateTo('home')}
              className="p-2 rounded-xl bg-gray-100"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-gray-700" />
            </motion.button>
            <h1 className="text-gray-900 font-heading">Komunitas</h1>
            <motion.button
              className="p-2 rounded-xl bg-blue-500"
              whileTap={{ scale: 0.95 }}
            >
              <Plus className="w-5 h-5 text-white" />
            </motion.button>
          </div>

          {/* Tabs */}
          <div className="flex gap-2">
            {tabs.map((tab) => (
              <motion.button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-1 py-2 px-3 rounded-xl text-sm ${
                  activeTab === tab.id
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 text-gray-600'
                }`}
                whileTap={{ scale: 0.98 }}
              >
                <span className="mr-1">{tab.icon}</span>
                {tab.label}
              </motion.button>
            ))}
          </div>
        </div>
      </div>

      {/* Posts */}
      <div className="px-6 py-4 space-y-3">
        {posts.map((post, index) => (
          <motion.div
            key={post.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            className="bg-white rounded-2xl p-4 shadow-sm"
          >
            {/* Author */}
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                <span className="text-xl">{post.avatar}</span>
              </div>
              <div className="flex-1">
                <h3 className="text-gray-900 font-heading text-sm">{post.author}</h3>
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <Clock className="w-3 h-3" />
                  <span>{post.time}</span>
                  <span className={`px-2 py-0.5 rounded-full text-xs ${
                    categories.find(c => c.label === post.category)?.color
                  }`}>
                    {post.category}
                  </span>
                </div>
              </div>
            </div>

            {/* Content */}
            <p className="text-gray-700 text-sm mb-4 leading-relaxed">
              {post.content}
            </p>

            {/* Actions */}
            <div className="flex items-center gap-4 pt-3 border-t border-gray-100">
              <motion.button
                onClick={() => toggleLike(post.id)}
                className={`flex items-center gap-1.5 text-sm ${
                  likedPosts.includes(post.id)
                    ? 'text-red-500'
                    : 'text-gray-500'
                }`}
                whileTap={{ scale: 0.95 }}
              >
                <Heart 
                  className="w-4 h-4" 
                  fill={likedPosts.includes(post.id) ? 'currentColor' : 'none'}
                />
                <span>{post.likes + (likedPosts.includes(post.id) ? 1 : 0)}</span>
              </motion.button>

              <motion.button
                className="flex items-center gap-1.5 text-sm text-gray-500"
                whileTap={{ scale: 0.95 }}
              >
                <MessageSquare className="w-4 h-4" />
                <span>{post.comments}</span>
              </motion.button>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="px-6 pb-8">
        <div className="bg-gradient-to-r from-blue-500 to-purple-500 rounded-2xl p-5 text-white">
          <h3 className="font-heading text-lg mb-2">Bergabung dengan Diskusi</h3>
          <p className="text-blue-50 text-sm mb-4">
            Tanyakan, berbagi pengalaman, dan dapatkan tips dari sesama orang tua
          </p>
          <div className="flex gap-2">
            <motion.button
              className="flex-1 bg-white text-blue-600 py-2.5 rounded-xl text-sm font-medium"
              whileTap={{ scale: 0.98 }}
            >
              Buat Postingan
            </motion.button>
            <motion.button
              className="flex-1 bg-white/20 backdrop-blur-sm text-white py-2.5 rounded-xl text-sm font-medium"
              whileTap={{ scale: 0.98 }}
            >
              Cari Topik
            </motion.button>
          </div>
        </div>
      </div>

      {/* Popular Topics */}
      <div className="px-6 pb-8">
        <h3 className="text-gray-900 font-heading mb-3">Topik Populer</h3>
        <div className="flex flex-wrap gap-2">
          {['Belajar di Rumah', 'Fokus & Konsentrasi', 'Motivasi Anak', 'Tips Orang Tua', 'Milestone'].map((topic) => (
            <motion.button
              key={topic}
              className="px-4 py-2 bg-white rounded-full text-sm text-gray-700 shadow-sm border border-gray-200"
              whileTap={{ scale: 0.95 }}
            >
              {topic}
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}
