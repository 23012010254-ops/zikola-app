import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Search, Home, MessageSquare, BarChart3, User, Users, Brain, MessageCircle, Theater, Target, Gamepad2 } from 'lucide-react';

interface HomeScreenProps {
  navigateTo: (screen: string) => void;
  childName: string;
  isParentMode: boolean;
  setIsParentMode: (mode: boolean) => void;
  collectedStickers: string[];
  profileData: any;
  testResults: any;
}

export default function HomeScreen({ 
  navigateTo, 
  childName, 
  isParentMode, 
  setIsParentMode,
  collectedStickers,
  profileData,
  testResults
}: HomeScreenProps) {

  const testCategories = [
    {
      id: 'cognitive-test',
      title: 'Kognitif',
      icon: '🧠',
      bgColor: 'bg-blue-100',
      iconColor: 'text-blue-600'
    },
    {
      id: 'linguistic-test',
      title: 'Linguistik',
      icon: '📝',
      bgColor: 'bg-orange-100',
      iconColor: 'text-orange-600'
    },
    {
      id: 'personality-test',
      title: 'Kepribadian',
      icon: '🎭',
      bgColor: 'bg-purple-100',
      iconColor: 'text-purple-600'
    },
    {
      id: 'motor-tips',
      title: 'Motorik',
      icon: '🎯',
      bgColor: 'bg-green-100',
      iconColor: 'text-green-600'
    },
    {
      id: 'game',
      title: 'Game',
      icon: '🎮',
      bgColor: 'bg-pink-100',
      iconColor: 'text-pink-600'
    }
  ];

  // Generate dynamic test data based on actual results
  const getTestDisplayData = () => {
    const tests = [
      {
        id: 'cognitive',
        title: 'Kognitif',
        icon: '🧠',
        bgColor: 'bg-blue-50',
        progressColor: 'bg-blue-500',
        testKey: 'cognitive'
      },
      {
        id: 'linguistic',
        title: 'Linguistik',
        icon: '📝',
        bgColor: 'bg-orange-50',
        progressColor: 'bg-orange-500',
        testKey: 'linguistic'
      },
      {
        id: 'personality',
        title: 'Kepribadian',
        icon: '🎭',
        bgColor: 'bg-purple-50',
        progressColor: 'bg-purple-500',
        testKey: 'personality'
      },
      {
        id: 'motor',
        title: 'Motorik',
        icon: '🎯',
        bgColor: 'bg-green-50',
        progressColor: 'bg-green-500',
        testKey: 'motor'
      }
    ];

    return tests.map(test => {
      const testResult = testResults[test.testKey];
      
      if (test.testKey === 'personality') {
        // Special handling for personality test
        return {
          ...test,
          score: testResult.completed ? 'Selesai' : 'Belum',
          total: testResult.completed ? testResult.animal || 'Selesai' : 'Mulai',
          progress: testResult.completed ? 100 : 0
        };
      } else {
        // Handle cognitive, linguistic, and motor tests
        return {
          ...test,
          score: testResult.completed ? testResult.score : 0,
          total: testResult.total,
          progress: testResult.completed ? testResult.percentage : 0
        };
      }
    }).filter(test => testResults[test.testKey].completed); // Only show completed tests
  };

  const recentTests = getTestDisplayData();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white px-6 pt-14 pb-6">
        <div className="flex items-center justify-between mb-2">
          <div>
            <p className="text-gray-600 font-body text-base">Selamat Datang</p>
            <h1 className="text-gray-900 font-heading font-bold text-2xl">{childName} !</h1>
          </div>
          <div className="flex items-center space-x-4">
            <button className="p-2">
              <Search className="w-6 h-6 text-gray-600" />
            </button>
            <div className="w-10 h-10 rounded-full flex items-center justify-center" style={{ backgroundColor: profileData?.backgroundColor || '#FEF3C7' }}>
              <span className="text-lg">{profileData?.avatar || '👦'}</span>
            </div>
          </div>
        </div>
      </div>

      <div className="px-6 pb-24">
        {/* Main Test Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-3xl p-6 mb-8 shadow-lg"
        >
          <h2 className="text-white font-heading font-bold text-xl mb-2">Test Yuk</h2>
          <p className="text-blue-100 font-body text-base mb-4">
            Ayo cari tahu seberapa hebat kamu !!!
          </p>
          
          <div className="flex items-center justify-between">
            <div className="flex -space-x-2">
              <div className="w-8 h-8 bg-white rounded-full border-2 border-blue-500 flex items-center justify-center">
                <span className="text-sm">👦</span>
              </div>
              <div className="w-8 h-8 bg-white rounded-full border-2 border-blue-500 flex items-center justify-center">
                <span className="text-sm">👧</span>
              </div>
              <div className="w-8 h-8 bg-white rounded-full border-2 border-blue-500 flex items-center justify-center">
                <span className="text-sm">👦</span>
              </div>
              <div className="w-8 h-8 bg-yellow-400 rounded-full border-2 border-blue-500 flex items-center justify-center">
                <span className="text-xs font-bold text-white">+1</span>
              </div>
            </div>
            
            <motion.button
              onClick={() => navigateTo('test-room')}
              className="bg-orange-500 hover:bg-orange-600 text-white font-bold px-6 py-3 rounded-2xl shadow-lg"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Mulai
            </motion.button>
          </div>
        </motion.div>

        {/* Test Categories */}
        <div className="mb-8">
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Kategori Test</h3>
          <div className="flex justify-between">
            {testCategories.map((category, index) => (
              <motion.button
                key={category.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                onClick={() => navigateTo(category.id)}
                className="flex flex-col items-center space-y-2"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <div className={`w-14 h-14 ${category.bgColor} rounded-2xl flex items-center justify-center shadow-sm`}>
                  <span className="text-2xl">{category.icon}</span>
                </div>
                <span className="text-gray-700 font-body text-xs font-medium text-center">
                  {category.title}
                </span>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Recently */}
        <div>
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Recently</h3>
          {recentTests.length === 0 ? (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-gray-50 rounded-2xl p-6 text-center border-2 border-dashed border-gray-200"
            >
              <span className="text-4xl mb-3 block">📝</span>
              <h4 className="text-gray-700 font-heading font-semibold text-base mb-2">
                Belum ada test yang selesai
              </h4>
              <p className="text-gray-500 font-body text-sm">
                Ayo mulai test pertamamu! Pilih kategori test di atas.
              </p>
            </motion.div>
          ) : (
            <div className="space-y-3">
              {recentTests.map((test, index) => (
                <motion.div
                  key={test.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className={`${test.bgColor} rounded-2xl p-4 shadow-sm`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center shadow-sm">
                        <span className="text-xl">{test.icon}</span>
                      </div>
                      <div className="flex-1">
                        <h4 className="text-gray-900 font-heading font-semibold text-base">
                          {test.title}
                        </h4>
                        <div className="flex items-center space-x-2 mt-1">
                          <div className="flex-1 h-2 bg-white rounded-full overflow-hidden">
                            <div 
                              className={`h-2 ${test.progressColor} rounded-full transition-all duration-500`}
                              style={{ width: `${test.progress}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-gray-900 font-heading font-bold text-lg">
                        {test.score}/{test.total}
                      </span>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-100">
        <div className="flex justify-around py-3">
          {[
            { icon: Home, label: 'Beranda', screen: 'home', active: true },
            { icon: MessageSquare, label: 'Konsultasi', screen: 'consultation' },
            { icon: Users, label: 'Komunitas', screen: 'community' },
            { icon: BarChart3, label: 'Progres', screen: 'progress' },
            { icon: User, label: 'Profil', screen: 'profile' }
          ].map((item) => (
            <motion.button
              key={item.screen}
              onClick={() => navigateTo(item.screen)}
              className={`flex flex-col items-center space-y-1 py-2 px-2 ${
                item.active 
                  ? 'text-orange-500' 
                  : 'text-gray-400'
              }`}
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