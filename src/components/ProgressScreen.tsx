import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Home, MessageSquare, BarChart3, User, Users, Calendar, TrendingUp, MessageCircle } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, ResponsiveContainer, BarChart, Bar } from 'recharts';

interface ProgressScreenProps {
  navigateTo: (screen: string) => void;
  isParentMode: boolean;
  setIsParentMode: (mode: boolean) => void;
  collectedStickers: string[];
  childName: string;
  testResults: any;
}

export default function ProgressScreen({ navigateTo, isParentMode, setIsParentMode, collectedStickers, childName, testResults }: ProgressScreenProps) {
  const [activeTab, setActiveTab] = useState<'current' | 'weekly' | 'charts'>('current');
  
  // Calculate user stats based on actual test results
  const calculateUserStats = () => {
    const completedTests = Object.values(testResults).filter((test: any) => test.completed).length;
    const totalTests = Object.keys(testResults).length;
    
    let totalScore = 0;
    let totalPossible = 0;

    Object.values(testResults).forEach((test: any) => {
      if (test.completed) {
        if (test.score !== undefined) {
          totalScore += test.score;
          totalPossible += test.total;
        }
      }
    });

    const averagePercentage = totalPossible > 0 ? Math.round((totalScore / totalPossible) * 100) : 0;
    
    let rank = 'Pemula';
    if (averagePercentage >= 90) rank = 'Luar Biasa';
    else if (averagePercentage >= 80) rank = 'Sangat Baik';
    else if (averagePercentage >= 70) rank = 'Baik';
    else if (averagePercentage >= 60) rank = 'Cukup';

    return {
      name: childName,
      level: completedTests + 1,
      score: averagePercentage,
      rank: rank,
      completedTests: completedTests,
      totalTests: totalTests
    };
  };

  const userStats = calculateUserStats();

  // Weekly progress data
  const weeklyData = [
    { week: 'Minggu 1', kepribadian: 75, kognitif: 70, linguistik: 68 },
    { week: 'Minggu 2', kepribadian: 78, kognitif: 73, linguistik: 72 },
    { week: 'Minggu 3', kepribadian: 82, kognitif: 76, linguistik: 74 },
    { week: 'Minggu 4', kepribadian: 82, kognitif: 82, linguistik: 78 },
  ];

  // Chart data for each category
  const chartData = {
    kepribadian: [
      { skill: 'Emosional', score: 85, target: 90 },
      { skill: 'Motivasi', score: 72, target: 80 },
      { skill: 'Sosial', score: 90, target: 85 }
    ],
    kognitif: [
      { skill: 'Logika', score: 78, target: 85 },
      { skill: 'Perhatian', score: 82, target: 90 },
      { skill: 'Memori', score: 88, target: 92 }
    ],
    linguistik: [
      { skill: 'Reseptif', score: 92, target: 95 },
      { skill: 'Ekspresif', score: 75, target: 85 },
      { skill: 'Fonemik', score: 68, target: 80 }
    ]
  };

  // Generate dynamic progress data based on actual test results
  const generateProgressData = () => {
    const defaultSkills = {
      cognitive: [
        { name: 'Logika', level: 0, max: 100 },
        { name: 'Perhatian', level: 0, max: 100 },
        { name: 'Memori', level: 0, max: 100 }
      ],
      linguistic: [
        { name: 'Reseptif', level: 0, max: 100 },
        { name: 'Ekspresif', level: 0, max: 100 },
        { name: 'Fonemik', level: 0, max: 100 }
      ],
      personality: [
        { name: 'Sosial', level: 0, max: 100 },
        { name: 'Emosional', level: 0, max: 100 },
        { name: 'Karakter', level: 0, max: 100 }
      ],
      motor: [
        { name: 'Koordinasi', level: 0, max: 100 },
        { name: 'Keseimbangan', level: 0, max: 100 },
        { name: 'Ketangkasan', level: 0, max: 100 }
      ]
    };

    const progressData = [
      {
        category: 'Kognitif', 
        color: 'blue',
        testId: 'cognitive-test',
        skills: defaultSkills.cognitive
      },
      {
        category: 'Linguistik',
        color: 'orange',
        testId: 'linguistic-test',
        skills: defaultSkills.linguistic
      },
      {
        category: 'Kepribadian',
        color: 'purple',
        testId: 'personality-test',
        skills: defaultSkills.personality
      },
      {
        category: 'Motorik',
        color: 'green',
        testId: 'motor-test-game',
        skills: defaultSkills.motor
      }
    ];

    // Update with actual test results
    if (testResults.cognitive.completed) {
      if (testResults.cognitive.gameMode === 'Math Shooter') {
        // Handle new game-based assessment
        progressData[0].skills = [
          { name: 'Logika & Matematika', level: testResults.cognitive.categoryScores?.logic || testResults.cognitive.percentage, max: 100 },
          { name: 'Perhatian & Fokus', level: testResults.cognitive.categoryScores?.attention || Math.round((testResults.cognitive.detailedResults?.accuracy || 0)), max: 100 },
          { name: 'Adaptasi Level', level: testResults.cognitive.categoryScores?.memory || Math.round((testResults.cognitive.level / 4) * 100), max: 100 }
        ];
      } else if (testResults.cognitive.categoryScores) {
        // Handle traditional test format
        progressData[0].skills = [
          { name: 'Logika', level: Math.round((testResults.cognitive.categoryScores.logic / 25) * 100), max: 100 },
          { name: 'Perhatian', level: Math.round((testResults.cognitive.categoryScores.attention / 25) * 100), max: 100 },
          { name: 'Memori', level: Math.round((testResults.cognitive.categoryScores.memory / 25) * 100), max: 100 }
        ];
      }
    }

    if (testResults.linguistic.completed) {
      if (testResults.linguistic.gameMode === 'Ocean Word Adventure') {
        // Handle new game-based assessment
        progressData[1].skills = [
          { name: 'Pemahaman Kata', level: testResults.linguistic.categoryScores?.receptive || testResults.linguistic.percentage, max: 100 },
          { name: 'Tata Bahasa', level: testResults.linguistic.categoryScores?.expressive || Math.round((testResults.linguistic.detailedResults?.accuracy || 0)), max: 100 },
          { name: 'Adaptasi Bahasa', level: testResults.linguistic.categoryScores?.phonemic || Math.round((testResults.linguistic.level / 4) * 100), max: 100 }
        ];
      } else if (testResults.linguistic.categoryScores) {
        // Handle traditional test format
        progressData[1].skills = [
          { name: 'Reseptif', level: Math.round((testResults.linguistic.categoryScores.receptive / 25) * 100), max: 100 },
          { name: 'Ekspresif', level: Math.round((testResults.linguistic.categoryScores.expressive / 25) * 100), max: 100 },
          { name: 'Fonemik', level: Math.round((testResults.linguistic.categoryScores.phonemic / 25) * 100), max: 100 }
        ];
      }
    }

    if (testResults.personality.completed) {
      // For personality, we'll show 100% completion for all traits since it's more about type than score
      progressData[2].skills = [
        { name: 'Sosial', level: 100, max: 100 },
        { name: 'Emosional', level: 100, max: 100 },
        { name: 'Karakter', level: 100, max: 100 }
      ];
    }

    if (testResults.motor.completed) {
      const motorPercentage = testResults.motor.percentage;
      progressData[3].skills = [
        { name: 'Koordinasi', level: motorPercentage, max: 100 },
        { name: 'Keseimbangan', level: motorPercentage, max: 100 },
        { name: 'Ketangkasan', level: motorPercentage, max: 100 }
      ];
    }

    return progressData;
  };

  const progressData = generateProgressData();

  const getColorClasses = (color: string) => {
    switch (color) {
      case 'blue':
        return { bg: 'bg-blue-500', stroke: 'stroke-blue-500', text: 'text-blue-600' };
      case 'orange':
        return { bg: 'bg-orange-500', stroke: 'stroke-orange-500', text: 'text-orange-600' };
      case 'purple':
        return { bg: 'bg-purple-500', stroke: 'stroke-purple-500', text: 'text-purple-600' };
      case 'green':
        return { bg: 'bg-green-500', stroke: 'stroke-green-500', text: 'text-green-600' };
      default:
        return { bg: 'bg-gray-500', stroke: 'stroke-gray-500', text: 'text-gray-600' };
    }
  };

  const CircularProgress = ({ percentage, color, size = 60 }: { percentage: number; color: string; size?: number }) => {
    const radius = (size - 12) / 2; // Adjusted for thicker stroke
    const circumference = 2 * Math.PI * radius;
    const strokeDasharray = circumference;
    const strokeDashoffset = circumference - (percentage / 100) * circumference;
    const colorClasses = getColorClasses(color);

    return (
      <div className="relative inline-flex items-center justify-center">
        <svg width={size} height={size} className="transform -rotate-90">
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="#e5e7eb"
            strokeWidth="6" // Made thicker
            fill="none"
          />
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            className={colorClasses.stroke}
            strokeWidth="6" // Made thicker
            fill="none"
            strokeDasharray={strokeDasharray}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            style={{ transition: 'stroke-dashoffset 1s ease-in-out' }}
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className={`text-sm font-bold ${colorClasses.text}`}>
            {percentage}%
          </span>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white px-6 pt-14 pb-6 border-b border-gray-100">
        <div className="flex items-center justify-center mb-4">
          <h1 className="text-gray-900 font-heading font-bold text-xl">Dashboard Perkembangan</h1>
        </div>
        
        {/* Tab Navigation */}
        <div className="flex bg-gray-100 rounded-2xl p-1">
          {[
            { id: 'current', label: 'Saat Ini', icon: BarChart3 },
            { id: 'weekly', label: 'Mingguan', icon: Calendar },
            { id: 'charts', label: 'Grafik', icon: TrendingUp }
          ].map((tab) => (
            <motion.button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex-1 flex items-center justify-center space-x-2 py-2 px-4 rounded-xl font-body font-medium text-sm transition-all ${
                activeTab === tab.id
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
              whileTap={{ scale: 0.98 }}
            >
              <tab.icon size={16} />
              <span>{tab.label}</span>
            </motion.button>
          ))}
        </div>
      </div>

      <div className="px-6 py-6 pb-24">
        {/* User Progress Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-2xl p-6 text-white shadow-lg mb-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <div className="text-xs opacity-80 mb-1">Dashboard Perkembangan Pengguna</div>
              <h2 className="font-heading font-bold text-xl mb-1">{userStats.name}</h2>
              <div className="text-sm opacity-90">Level Saat Ini: {userStats.level}</div>
            </div>
            <div className="text-center bg-white/20 rounded-xl px-4 py-3">
              <div className="text-xs opacity-80 mb-1">{userStats.rank}</div>
              <div className="text-2xl font-heading font-bold">{userStats.score}</div>
            </div>
          </div>
        </motion.div>

        {/* Tab Content */}
        {activeTab === 'current' && (
          <>
            {/* Progress Categories */}
            <div className="space-y-6">
              {progressData.map((category, categoryIndex) => (
                <motion.div
                  key={category.category}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: categoryIndex * 0.2 }}
                  className="bg-white rounded-2xl p-6 shadow-sm"
                >
                  <h3 className="text-gray-900 font-heading font-bold text-lg mb-6">
                    {category.category}
                  </h3>
                  
                  <div className="grid grid-cols-3 gap-6">
                    {category.skills.map((skill, skillIndex) => (
                      <motion.div
                        key={skill.name}
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: categoryIndex * 0.2 + skillIndex * 0.1 }}
                        className="text-center cursor-pointer"
                        onClick={() => navigateTo(category.testId)}
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <div className="mb-3">
                          <CircularProgress 
                            percentage={skill.level} 
                            color={category.color}
                            size={80}
                          />
                        </div>
                        <div className="text-sm font-body font-medium text-gray-900 mb-1">
                          {skill.name}
                        </div>
                        <div className="text-xs font-body text-gray-500">
                          Normal
                        </div>
                      </motion.div>
                    ))}
                  </div>
                </motion.div>
              ))}
            </div>

            {/* Cognitive Game Analysis */}
            {testResults.cognitive.completed && testResults.cognitive.gameMode === 'Math Shooter' && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
                className="bg-white rounded-2xl p-6 shadow-sm mt-6"
              >
                <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
                  🎯 Analisis Game Matematika
                </h3>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="bg-orange-50 rounded-xl p-4">
                    <div className="text-orange-600 font-heading text-sm mb-1">Akurasi Tembakan</div>
                    <div className="text-orange-800 font-bold text-xl">
                      {testResults.cognitive.detailedResults?.accuracy || testResults.cognitive.percentage}%
                    </div>
                  </div>
                  <div className="bg-green-50 rounded-xl p-4">
                    <div className="text-green-600 font-heading text-sm mb-1">Level Tertinggi</div>
                    <div className="text-green-800 font-bold text-xl">
                      {testResults.cognitive.level || 1}
                    </div>
                  </div>
                  <div className="bg-blue-50 rounded-xl p-4">
                    <div className="text-blue-600 font-heading text-sm mb-1">Waktu Rata-rata</div>
                    <div className="text-blue-800 font-bold text-xl">
                      {Math.round(testResults.cognitive.detailedResults?.averageResponseTime || testResults.cognitive.timeSpent)}s
                    </div>
                  </div>
                  <div className="bg-purple-50 rounded-xl p-4">
                    <div className="text-purple-600 font-heading text-sm mb-1">Domain Terkuat</div>
                    <div className="text-purple-800 font-bold text-sm">
                      {testResults.cognitive.detailedResults?.strongestDomain || 'Addition'}
                    </div>
                  </div>
                </div>

                {testResults.cognitive.domainAnalysis && (
                  <div className="space-y-2">
                    <h4 className="text-gray-700 font-heading text-sm mb-2">Analisis per Domain:</h4>
                    {Object.entries(testResults.cognitive.domainAnalysis).map(([domain, data]: [string, any]) => (
                      <div key={domain} className="flex items-center justify-between bg-gray-50 rounded-lg p-3">
                        <span className="text-gray-700 font-body text-sm">{domain}</span>
                        <div className="flex items-center space-x-2">
                          <span className="text-gray-600 text-xs">{data.correct}/{data.total}</span>
                          <div className="w-16 bg-gray-200 rounded-full h-2">
                            <div 
                              className="bg-orange-500 h-2 rounded-full transition-all duration-500"
                              style={{ width: `${(data.correct / data.total) * 100}%` }}
                            />
                          </div>
                          <span className="text-gray-700 text-xs font-medium">
                            {Math.round((data.correct / data.total) * 100)}%
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </motion.div>
            )}

            {/* Alien Shooter Game Analysis */}
            {testResults.cognitive.completed && testResults.cognitive.gameMode === 'Alien Math Shooter' && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
                className="bg-white rounded-2xl p-6 shadow-sm mt-6"
              >
                <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
                  🛸 Analisis Alien Math Shooter
                </h3>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="bg-purple-50 rounded-xl p-4">
                    <div className="text-purple-600 font-heading text-sm mb-1">Akurasi Pertahanan</div>
                    <div className="text-purple-800 font-bold text-xl">
                      {testResults.cognitive.detailedResults?.accuracy || testResults.cognitive.percentage}%
                    </div>
                  </div>
                  <div className="bg-blue-50 rounded-xl p-4">
                    <div className="text-blue-600 font-heading text-sm mb-1">Level Tertinggi</div>
                    <div className="text-blue-800 font-bold text-xl">
                      {testResults.cognitive.level || 1}
                    </div>
                  </div>
                  <div className="bg-red-50 rounded-xl p-4">
                    <div className="text-red-600 font-heading text-sm mb-1">Nyawa Tersisa</div>
                    <div className="text-red-800 font-bold text-xl">
                      {testResults.cognitive.detailedResults?.livesRemaining || 0}
                    </div>
                  </div>
                  <div className="bg-green-50 rounded-xl p-4">
                    <div className="text-green-600 font-heading text-sm mb-1">Waktu Bertahan</div>
                    <div className="text-green-800 font-bold text-xl">
                      {Math.round(testResults.cognitive.timeSpent)}s
                    </div>
                  </div>
                </div>

                <div className="bg-purple-50 rounded-xl p-4">
                  <div className="text-purple-700 font-medium text-sm">
                    🚀 Kemampuan terfokus pada: Matematika Lanjutan, Pecahan & Logika Kompleks
                  </div>
                </div>
              </motion.div>
            )}

            {/* Linguistic Game Analysis */}
            {testResults.linguistic.completed && testResults.linguistic.gameMode === 'Ocean Word Adventure' && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7 }}
                className="bg-white rounded-2xl p-6 shadow-sm mt-6"
              >
                <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
                  🌊 Analisis Ocean Word Adventure
                </h3>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="bg-cyan-50 rounded-xl p-4">
                    <div className="text-cyan-600 font-heading text-sm mb-1">Akurasi Kata</div>
                    <div className="text-cyan-800 font-bold text-xl">
                      {testResults.linguistic.detailedResults?.accuracy || testResults.linguistic.percentage}%
                    </div>
                  </div>
                  <div className="bg-blue-50 rounded-xl p-4">
                    <div className="text-blue-600 font-heading text-sm mb-1">Level Tertinggi</div>
                    <div className="text-blue-800 font-bold text-xl">
                      {testResults.linguistic.level || 1}
                    </div>
                  </div>
                  <div className="bg-purple-50 rounded-xl p-4">
                    <div className="text-purple-600 font-heading text-sm mb-1">Waktu Rata-rata</div>
                    <div className="text-purple-800 font-bold text-xl">
                      {Math.round(testResults.linguistic.detailedResults?.averageResponseTime || testResults.linguistic.timeSpent)}s
                    </div>
                  </div>
                  <div className="bg-green-50 rounded-xl p-4">
                    <div className="text-green-600 font-heading text-sm mb-1">Bahasa</div>
                    <div className="text-green-800 font-bold text-sm">
                      {testResults.linguistic.detailedResults?.languageTested || 'Bahasa Indonesia'}
                    </div>
                  </div>
                </div>

                {testResults.linguistic.domainAnalysis && (
                  <div className="space-y-2">
                    <h4 className="text-gray-700 font-heading text-sm mb-2">Analisis per Domain:</h4>
                    {Object.entries(testResults.linguistic.domainAnalysis).map(([domain, data]: [string, any]) => (
                      <div key={domain} className="flex items-center justify-between bg-gray-50 rounded-lg p-3">
                        <span className="text-gray-700 font-body text-sm">{domain}</span>
                        <div className="flex items-center space-x-2">
                          <span className="text-gray-600 text-xs">{data.correct}/{data.total}</span>
                          <div className="w-16 bg-gray-200 rounded-full h-2">
                            <div 
                              className="bg-cyan-500 h-2 rounded-full transition-all duration-500"
                              style={{ width: `${(data.correct / data.total) * 100}%` }}
                            />
                          </div>
                          <span className="text-gray-700 text-xs font-medium">
                            {Math.round((data.correct / data.total) * 100)}%
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                <div className="mt-4 bg-cyan-50 rounded-xl p-4">
                  <div className="text-cyan-700 font-medium text-sm">
                    🎯 Domain Terkuat: {testResults.linguistic.detailedResults?.strongestDomain || 'Kata Kerja'}
                  </div>
                </div>
              </motion.div>
            )}

            {/* Summary Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8 }}
              className="bg-white rounded-2xl p-6 shadow-sm mt-6"
            >
              <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
                Rekomendasi
              </h3>
              <div className="bg-blue-50 rounded-xl p-4">
                <p className="text-blue-800 font-body text-sm">
                  {(() => {
                    const mathShooter = testResults.cognitive.completed && testResults.cognitive.gameMode === 'Math Shooter';
                    const alienShooter = testResults.cognitive.completed && testResults.cognitive.gameMode === 'Alien Math Shooter';
                    const linguisticCompleted = testResults.linguistic.completed && testResults.linguistic.gameMode === 'Ocean Word Adventure';
                    
                    if ((mathShooter || alienShooter) && linguisticCompleted) {
                      return `Luar biasa ${childName}! Kemampuan matematika dan bahasa berkembang dengan baik. Level ${testResults.cognitive.level} menunjukkan progres yang sangat positif!`;
                    } else if (mathShooter) {
                      return `Kemampuan matematika dasar ${childName} berkembang dengan baik! Coba Alien Shooter untuk tantangan lebih besar, atau game bahasa untuk pengembangan yang seimbang.`;
                    } else if (alienShooter) {
                      return `Wow! ${childName} sudah menguasai matematika lanjutan! Level ${testResults.cognitive.level} menunjukkan kemampuan logika yang excellent. Coba juga game bahasa untuk pengembangan yang seimbang.`;
                    } else if (linguisticCompleted) {
                      return `Kemampuan bahasa ${childName} berkembang dengan baik! Level ${testResults.linguistic.level} menunjukkan progres yang positif. Coba juga game matematika untuk pengembangan yang lebih seimbang.`;
                    } else {
                      return 'Mulai dengan game matematika dan bahasa untuk mengembangkan kemampuan kognitif dan linguistik secara seimbang!';
                    }
                  })()}
                </p>
              </div>
              <div className="mt-4 space-y-2">
                <motion.button
                  onClick={() => navigateTo('cognitive-test')}
                  className="w-full bg-gradient-to-r from-blue-500 to-blue-600 text-white py-3 px-6 rounded-xl font-body font-semibold"
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  🎯 Main Game Matematika
                </motion.button>
                <motion.button
                  onClick={() => navigateTo('linguistic-test')}
                  className="w-full bg-gradient-to-r from-cyan-500 to-blue-600 text-white py-3 px-6 rounded-xl font-body font-semibold"
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  🌊 Main Game Bahasa
                </motion.button>
              </div>
            </motion.div>
          </>
        )}

        {activeTab === 'weekly' && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-6"
          >
            {/* Weekly Progress Chart */}
            <div className="bg-white rounded-2xl p-6 shadow-sm">
              <h3 className="text-gray-900 font-heading font-bold text-lg mb-6">
                Progress Mingguan
              </h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={weeklyData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                    <XAxis 
                      dataKey="week" 
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 12, fill: '#6b7280' }}
                    />
                    <YAxis 
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 12, fill: '#6b7280' }}
                    />
                    <Line 
                      type="monotone" 
                      dataKey="kepribadian" 
                      stroke="#3b82f6" 
                      strokeWidth={3}
                      dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }}
                      activeDot={{ r: 6, stroke: '#3b82f6', strokeWidth: 2 }}
                    />
                    <Line 
                      type="monotone" 
                      dataKey="kognitif" 
                      stroke="#f97316" 
                      strokeWidth={3}
                      dot={{ fill: '#f97316', strokeWidth: 2, r: 4 }}
                      activeDot={{ r: 6, stroke: '#f97316', strokeWidth: 2 }}
                    />
                    <Line 
                      type="monotone" 
                      dataKey="linguistik" 
                      stroke="#10b981" 
                      strokeWidth={3}
                      dot={{ fill: '#10b981', strokeWidth: 2, r: 4 }}
                      activeDot={{ r: 6, stroke: '#10b981', strokeWidth: 2 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
              
              {/* Legend */}
              <div className="flex justify-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                  <span className="text-sm font-body text-gray-600">Kepribadian</span>
                </div>
                <div className="flex items-center space-x-2">
                  <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
                  <span className="text-sm font-body text-gray-600">Kognitif</span>
                </div>
                <div className="flex items-center space-x-2">
                  <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                  <span className="text-sm font-body text-gray-600">Linguistik</span>
                </div>
              </div>
            </div>

            {/* Weekly Summary Cards */}
            <div className="grid grid-cols-3 gap-4">
              {[
                { label: 'Kepribadian', value: 82, change: '+7', color: 'blue' },
                { label: 'Kognitif', value: 82, change: '+12', color: 'orange' },
                { label: 'Linguistik', value: 78, change: '+10', color: 'green' }
              ].map((item, index) => (
                <motion.div
                  key={item.label}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-white rounded-2xl p-4 shadow-sm text-center"
                >
                  <div className={`text-2xl font-heading font-bold text-${item.color}-600 mb-1`}>
                    {item.value}%
                  </div>
                  <div className="text-xs font-body text-gray-600 mb-2">{item.label}</div>
                  <div className={`text-xs font-body text-green-600 bg-green-50 px-2 py-1 rounded-full`}>
                    {item.change} minggu ini
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>
        )}

        {activeTab === 'charts' && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-6"
          >
            {/* Charts for each category */}
            {Object.entries(chartData).map(([category, data], index) => (
              <motion.div
                key={category}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.2 }}
                className="bg-white rounded-2xl p-6 shadow-sm"
              >
                <h3 className="text-gray-900 font-heading font-bold text-lg mb-6 capitalize">
                  Analisis {category}
                </h3>
                <div className="h-48">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={data} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                      <XAxis 
                        dataKey="skill" 
                        axisLine={false}
                        tickLine={false}
                        tick={{ fontSize: 12, fill: '#6b7280' }}
                      />
                      <YAxis 
                        axisLine={false}
                        tickLine={false}
                        tick={{ fontSize: 12, fill: '#6b7280' }}
                      />
                      <Bar 
                        dataKey="score" 
                        fill={category === 'kepribadian' ? '#3b82f6' : category === 'kognitif' ? '#f97316' : '#10b981'}
                        radius={[4, 4, 0, 0]}
                      />
                      <Bar 
                        dataKey="target" 
                        fill="#e5e7eb"
                        radius={[4, 4, 0, 0]}
                        opacity={0.3}
                      />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
                <div className="flex justify-center space-x-6 mt-4">
                  <div className="flex items-center space-x-2">
                    <div className={`w-3 h-3 rounded-full ${
                      category === 'kepribadian' ? 'bg-blue-500' : 
                      category === 'kognitif' ? 'bg-orange-500' : 'bg-green-500'
                    }`}></div>
                    <span className="text-sm font-body text-gray-600">Skor Saat Ini</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-3 h-3 bg-gray-300 rounded-full"></div>
                    <span className="text-sm font-body text-gray-600">Target</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        )}
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-100">
        <div className="flex justify-around py-3">
          {[
            { icon: Home, label: 'Beranda', screen: 'home' },
            { icon: MessageSquare, label: 'Konsultasi', screen: 'consultation' },
            { icon: Users, label: 'Komunitas', screen: 'community' },
            { icon: BarChart3, label: 'Progres', screen: 'progress', active: true },
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