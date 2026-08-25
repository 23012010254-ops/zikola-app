import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Home, MessageSquare, BarChart3, User, Users, Trophy, Star, Brain, Target, TrendingUp, Clock, AlertCircle, Award, Play, ChevronDown, ChevronUp } from 'lucide-react';

interface GameScreenProps {
  navigateTo: (screen: string) => void;
  isParentMode: boolean;
  addSticker: (sticker: string) => void;
  collectedStickers: string[];
  gameAssessments?: any;
}

export default function GameScreen({ navigateTo, isParentMode, addSticker, collectedStickers, gameAssessments }: GameScreenProps) {
  const [showDashboard, setShowDashboard] = useState(false);
  // Available games
  const games = [];

  // Calculate overall assessment data
  const getOverallAssessment = () => {
    if (!gameAssessments) return null;
    
    const games = Object.values(gameAssessments);
    const playedGames = games.filter((game: any) => game.totalPlayed > 0);
    
    if (playedGames.length === 0) return null;
    
    const totalSessions = playedGames.reduce((sum: number, game: any) => sum + game.totalPlayed, 0);
    const avgScore = Math.round(playedGames.reduce((sum: number, game: any) => sum + game.averageScore, 0) / playedGames.length);
    const avgTime = Math.round(playedGames.reduce((sum: number, game: any) => sum + game.averageTime, 0) / playedGames.length);
    const avgErrors = Math.round((playedGames.reduce((sum: number, game: any) => sum + game.averageErrors, 0) / playedGames.length) * 10) / 10;
    
    // Calculate strengths (domains with best performance)
    const domainPerformance: { [key: string]: number[] } = {};
    playedGames.forEach((game: any) => {
      game.domains.forEach((domain: string) => {
        if (!domainPerformance[domain]) domainPerformance[domain] = [];
        domainPerformance[domain].push(game.averageScore);
      });
    });
    
    const domainAverages = Object.entries(domainPerformance).map(([domain, scores]) => ({
      domain,
      average: scores.reduce((sum, score) => sum + score, 0) / scores.length
    })).sort((a, b) => b.average - a.average);
    
    return {
      totalSessions,
      avgScore,
      avgTime,
      avgErrors,
      strengths: domainAverages.slice(0, 3),
      improvements: domainAverages.slice(-2)
    };
  };

  const overallAssessment = getOverallAssessment();

  const featuredGames = [
    {
      id: 'number-sequence',
      title: 'Urutan Angka',
      description: 'Latih logika matematika dengan pola angka',
      image: '🔢',
      gradient: 'from-blue-400 to-indigo-500',
      domains: ['Logika', 'Matematika', 'Pattern Recognition'],
      gameKey: 'numberSequence'
    }
  ];

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Easy': return 'bg-green-100 text-green-700';
      case 'Medium': return 'bg-yellow-100 text-yellow-700';
      case 'Hard': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const handleGameClick = (gameId: string) => {
    switch (gameId) {
      case 'word-puzzle':
        navigateTo('word-puzzle-game');
        break;
      case 'number-sequence':
        navigateTo('number-sequence-game');
        break;
      case 'maze-game':
        navigateTo('maze-game');
        break;
      default:
        addSticker('game-player');
        break;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50/30">
      {/* Header */}
      <div className="bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 px-6 pt-14 pb-6">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm border border-white/10"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-5 h-5 text-white" />
          </motion.button>
          <h1 className="text-white font-heading text-xl">Game Center</h1>
          <motion.button
            onClick={() => setShowDashboard(!showDashboard)}
            className="p-2.5 rounded-xl bg-white/20 backdrop-blur-sm border border-white/10"
            whileTap={{ scale: 0.95 }}
          >
            {showDashboard ? (
              <ChevronUp className="w-5 h-5 text-white" />
            ) : (
              <BarChart3 className="w-5 h-5 text-white" />
            )}
          </motion.button>
        </div>

        {/* Welcome Banner */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/15 backdrop-blur-md rounded-2xl p-6 border border-white/20"
        >
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <h2 className="text-white font-heading text-lg mb-1">
                Ayo Main & Belajar! 🎮
              </h2>
              <p className="text-white/80 text-sm">
                Kumpulkan bintang dan stiker dari setiap game
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="text-center">
                <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mb-1">
                  <Trophy className="w-6 h-6 text-white" />
                </div>
                <span className="text-white/90 text-xs">Master</span>
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      <div className="px-6 -mt-3 pb-24">
        {/* Assessment Dashboard */}
        {showDashboard && overallAssessment && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="mb-6"
          >
            <div className="bg-white rounded-2xl p-6 shadow-lg border border-gray-100/50">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="text-gray-900 font-heading text-lg mb-1">Dashboard Perkembangan</h3>
                  <p className="text-gray-500 text-sm">Analisis performa kognitif anak</p>
                </div>
                <div className="flex items-center space-x-2 bg-gradient-to-r from-blue-50 to-indigo-50 px-3 py-2 rounded-xl border border-blue-100">
                  <Brain className="w-4 h-4 text-blue-600" />
                  <span className="text-sm font-semibold text-blue-700">Assessment</span>
                </div>
              </div>

              {/* Overall Statistics */}
              <div className="grid grid-cols-2 gap-3 mb-8">
                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-100/50">
                  <div className="flex items-center space-x-2 mb-3">
                    <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Trophy className="w-4 h-4 text-blue-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">Total Sesi</span>
                  </div>
                  <div className="text-2xl font-heading text-gray-900">{overallAssessment.totalSessions}</div>
                </div>
                
                <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl p-4 border border-green-100/50">
                  <div className="flex items-center space-x-2 mb-3">
                    <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                      <Star className="w-4 h-4 text-green-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">Rata-rata Skor</span>
                  </div>
                  <div className="text-2xl font-heading text-gray-900">{overallAssessment.avgScore}%</div>
                </div>
                
                <div className="bg-gradient-to-br from-orange-50 to-yellow-50 rounded-xl p-4 border border-orange-100/50">
                  <div className="flex items-center space-x-2 mb-3">
                    <div className="w-8 h-8 bg-orange-100 rounded-lg flex items-center justify-center">
                      <Clock className="w-4 h-4 text-orange-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">Rata-rata Waktu</span>
                  </div>
                  <div className="text-2xl font-heading text-gray-900">{overallAssessment.avgTime}s</div>
                </div>
                
                <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl p-4 border border-purple-100/50">
                  <div className="flex items-center space-x-2 mb-3">
                    <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
                      <AlertCircle className="w-4 h-4 text-purple-600" />
                    </div>
                    <span className="text-sm font-medium text-gray-600">Rata-rata Error</span>
                  </div>
                  <div className="text-2xl font-heading text-gray-900">{overallAssessment.avgErrors}</div>
                </div>
              </div>

              {/* Strengths & Areas for Improvement */}
              <div className="space-y-6">
                <div>
                  <h4 className="text-gray-900 font-heading text-base mb-4 flex items-center">
                    <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center mr-3">
                      <Award className="w-4 h-4 text-green-600" />
                    </div>
                    Kekuatan Utama
                  </h4>
                  <div className="space-y-3">
                    {overallAssessment.strengths.map((strength: any, index: number) => (
                      <div key={strength.domain} className="bg-green-50 rounded-xl p-4 border border-green-100/50">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-sm text-gray-700 font-medium">{strength.domain}</span>
                          <span className="text-sm font-semibold text-green-700">{Math.round(strength.average)}%</span>
                        </div>
                        <div className="w-full bg-green-200 rounded-full h-2">
                          <div 
                            className="bg-green-500 h-2 rounded-full transition-all duration-500" 
                            style={{ width: `${(strength.average / 100) * 100}%` }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {overallAssessment.improvements.length > 0 && (
                  <div>
                    <h4 className="text-gray-900 font-heading text-base mb-4 flex items-center">
                      <div className="w-8 h-8 bg-orange-100 rounded-lg flex items-center justify-center mr-3">
                        <TrendingUp className="w-4 h-4 text-orange-600" />
                      </div>
                      Area Pengembangan
                    </h4>
                    <div className="space-y-3">
                      {overallAssessment.improvements.map((improvement: any, index: number) => (
                        <div key={improvement.domain} className="bg-orange-50 rounded-xl p-4 border border-orange-100/50">
                          <div className="flex items-center justify-between mb-2">
                            <span className="text-sm text-gray-700 font-medium">{improvement.domain}</span>
                            <span className="text-sm font-semibold text-orange-700">{Math.round(improvement.average)}%</span>
                          </div>
                          <div className="w-full bg-orange-200 rounded-full h-2">
                            <div 
                              className="bg-orange-500 h-2 rounded-full transition-all duration-500" 
                              style={{ width: `${(improvement.average / 100) * 100}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Game-specific Assessment */}
              <div className="mt-8">
                <h4 className="text-gray-900 font-heading text-base mb-4 flex items-center">
                  <div className="w-8 h-8 bg-indigo-100 rounded-lg flex items-center justify-center mr-3">
                    <Target className="w-4 h-4 text-indigo-600" />
                  </div>
                  Assessment per Game
                </h4>
                <div className="space-y-3">
                  {Object.entries(gameAssessments || {}).filter(([_, data]: [string, any]) => data.totalPlayed > 0).map(([gameKey, data]: [string, any]) => {
                    const gameNames: { [key: string]: string } = {
                      memory: 'Memory Cards',
                      wordPuzzle: 'Teka-Teki Kata',
                      numberSequence: 'Urutan Angka',
                      patternRecognition: 'Pola Visual',
                      motor: 'Tes Motorik',
                      mazeGame: 'Maze Adventure'
                    };
                    
                    return (
                      <div key={gameKey} className="bg-gradient-to-r from-gray-50 to-blue-50/30 rounded-xl p-4 border border-gray-100/50">
                        <div className="flex items-center justify-between mb-3">
                          <h5 className="font-heading font-medium text-gray-900">{gameNames[gameKey]}</h5>
                          <span className="text-xs bg-indigo-100 text-indigo-700 px-3 py-1 rounded-full font-medium">
                            {data.totalPlayed} sesi
                          </span>
                        </div>
                        <div className="grid grid-cols-3 gap-4 mb-4">
                          <div className="text-center">
                            <div className="text-xl font-heading text-gray-900">{data.averageScore}%</div>
                            <div className="text-xs text-gray-500">Skor</div>
                          </div>
                          <div className="text-center">
                            <div className="text-xl font-heading text-gray-900">{data.averageTime}s</div>
                            <div className="text-xs text-gray-500">Waktu</div>
                          </div>
                          <div className="text-center">
                            <div className="text-xl font-heading text-gray-900">{data.averageErrors}</div>
                            <div className="text-xs text-gray-500">Error</div>
                          </div>
                        </div>
                        <div>
                          <div className="text-xs text-gray-500 mb-2">Domain Kognitif:</div>
                          <div className="flex flex-wrap gap-1">
                            {data.domains.map((domain: string) => (
                              <span key={domain} className="text-xs bg-white text-indigo-700 px-2 py-1 rounded-lg font-medium border border-indigo-100">
                                {domain}
                              </span>
                            ))}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {/* Cognitive Games Notice */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-6"
        >
          <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-2xl p-5 border border-blue-100/50">
            <div className="flex items-center space-x-3 mb-3">
              <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                <Brain className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h3 className="text-gray-900 font-heading text-base">Game Kognitif</h3>
                <p className="text-gray-600 text-sm">Memory Cards, Pola Visual, dan Desert Tank Logic kini tersedia di Tes Kognitif!</p>
              </div>
            </div>
            <motion.button
              onClick={() => navigateTo('cognitive-test')}
              className="bg-blue-500 text-white px-4 py-2 rounded-xl text-sm font-medium"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              Ke Tes Kognitif →
            </motion.button>
          </div>
        </motion.div>

        {/* Featured Games */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <div className="flex items-center justify-between mb-5">
            <h3 className="text-gray-900 font-heading text-lg">Game Unggulan</h3>
            <span className="text-2xl">🌟</span>
          </div>
          <div className="space-y-4">
            {featuredGames.map((game, index) => (
              <motion.div
                key={game.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className={`bg-gradient-to-r ${game.gradient} rounded-2xl p-5 text-white shadow-lg hover:shadow-xl transition-shadow border border-white/20`}
              >
                <div className="flex items-center space-x-4">
                  <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center backdrop-blur-sm">
                    <span className="text-3xl">{game.image}</span>
                  </div>
                  <div className="flex-1">
                    <h4 className="text-white font-heading text-base mb-1">
                      {game.title}
                    </h4>
                    <p className="text-white/90 text-sm mb-3">
                      {game.description}
                    </p>
                    {/* Assessment Info */}
                    {gameAssessments && gameAssessments[game.gameKey] && gameAssessments[game.gameKey].totalPlayed > 0 && (
                      <div className="flex items-center space-x-4 text-xs mb-3 bg-white/10 rounded-lg px-3 py-2">
                        <div className="flex items-center space-x-1">
                          <Star className="w-3 h-3" />
                          <span>{gameAssessments[game.gameKey].averageScore}%</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Target className="w-3 h-3" />
                          <span>{gameAssessments[game.gameKey].totalPlayed} sesi</span>
                        </div>
                      </div>
                    )}
                    <div className="flex flex-wrap gap-2">
                      {game.domains.slice(0, 2).map((domain) => (
                        <span key={domain} className="text-xs bg-white/20 text-white px-2 py-1 rounded-lg font-medium">
                          {domain}
                        </span>
                      ))}
                    </div>
                  </div>
                  <motion.button
                    onClick={() => handleGameClick(game.id)}
                    className="bg-white/20 backdrop-blur-sm text-white px-5 py-3 rounded-xl font-medium text-sm border border-white/20 flex items-center space-x-2"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Play className="w-4 h-4" />
                    <span>Main</span>
                  </motion.button>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Available Games */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-5">
            <h3 className="text-gray-900 font-heading text-lg">Game Lainnya</h3>
            <span className="text-2xl">🎮</span>
          </div>
          <div className="space-y-4">
            {games.map((game, index) => (
              <motion.div
                key={game.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-2xl p-5 shadow-lg border border-gray-100/50 hover:shadow-xl transition-shadow"
              >
                <div className="flex items-center space-x-4">
                  {/* Game Icon */}
                  <div className={`w-16 h-16 ${game.color} rounded-2xl flex items-center justify-center shadow-sm`}>
                    <span className="text-3xl">{game.image}</span>
                  </div>
                  
                  {/* Game Info */}
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="text-gray-900 font-heading text-base">
                        {game.title}
                      </h4>
                      <div className="flex items-center space-x-1 bg-yellow-50 px-3 py-1 rounded-xl border border-yellow-100">
                        <Star className="w-3 h-3 text-yellow-500 fill-current" />
                        <span className="text-xs font-semibold text-gray-700">
                          {game.rating}
                        </span>
                      </div>
                    </div>
                    
                    <p className="text-gray-600 text-sm mb-3">
                      {game.description}
                    </p>
                    
                    {/* Domain Tags */}
                    <div className="flex flex-wrap gap-2 mb-3">
                      {game.domains.map((domain) => (
                        <span key={domain} className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-lg font-medium border border-blue-100">
                          {domain}
                        </span>
                      ))}
                    </div>
                    
                    <div className="flex items-center space-x-3 mb-4">
                      <span className={`px-3 py-1 rounded-xl text-xs font-medium ${getDifficultyColor(game.difficulty)}`}>
                        {game.difficulty}
                      </span>
                      <span className="text-gray-500 text-xs font-medium flex items-center space-x-1">
                        <Clock className="w-3 h-3" />
                        <span>{game.time}</span>
                      </span>
                      {/* Assessment Stats */}
                      {gameAssessments && gameAssessments[game.gameKey] && gameAssessments[game.gameKey].totalPlayed > 0 && (
                        <span className="text-green-600 text-xs font-medium bg-green-50 px-2 py-1 rounded-lg">
                          📊 {gameAssessments[game.gameKey].averageScore}% avg
                        </span>
                      )}
                    </div>
                    
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <span className="text-xs text-gray-500">Reward:</span>
                        <span className={`text-xs font-medium ${game.textColor}`}>
                          {game.reward}
                        </span>
                      </div>
                      
                      <motion.button
                        onClick={() => handleGameClick(game.id)}
                        className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-2.5 rounded-xl font-medium text-sm shadow-lg hover:shadow-xl transition-shadow flex items-center space-x-2"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <Play className="w-4 h-4" />
                        <span>Main Sekarang</span>
                      </motion.button>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Pro Tip */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-gradient-to-r from-blue-500 to-cyan-500 rounded-2xl p-6 text-white shadow-lg border border-blue-400/20"
        >
          <div className="flex items-center space-x-4">
            <div className="w-14 h-14 bg-white/20 rounded-xl flex items-center justify-center backdrop-blur-sm">
              <span className="text-3xl">💡</span>
            </div>
            <div className="flex-1">
              <h3 className="font-heading text-lg mb-1">Pro Tip!</h3>
              <p className="text-blue-100 text-sm leading-relaxed">
                Main game setiap hari untuk mengembangkan kemampuan berpikir dan kreativitas! Setiap game melatih aspek kognitif yang berbeda.
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white/95 backdrop-blur-lg border-t border-gray-200/50 shadow-lg">
        <div className="flex justify-around py-4">
          {[
            { icon: Home, label: 'Beranda', screen: 'home' },
            { icon: MessageSquare, label: 'Konsultasi', screen: 'consultation' },
            { icon: Users, label: 'Komunitas', screen: 'community' },
            { icon: BarChart3, label: 'Progres', screen: 'progress' },
            { icon: User, label: 'Profil', screen: 'profile' }
          ].map((item) => (
            <motion.button
              key={item.screen}
              onClick={() => navigateTo(item.screen)}
              className="flex flex-col items-center space-y-1 py-1 px-3 text-gray-500 hover:text-gray-700 transition-colors"
              whileTap={{ scale: 0.95 }}
            >
              <item.icon size={20} strokeWidth={1.5} />
              <span className="text-xs font-medium">{item.label}</span>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}