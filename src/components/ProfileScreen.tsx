import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Home, MessageSquare, BarChart3, User, Edit3, Palette, Star, Users, LogOut, MessageCircle } from 'lucide-react';

interface ProfileScreenProps {
  navigateTo: (screen: string) => void;
  isParentMode: boolean;
  setIsParentMode: (mode: boolean) => void;
  childName: string;
  setChildName: (name: string) => void;
  collectedStickers: string[];
  profileData: any;
  updateProfile: (data: any) => void;
  mbtiResult?: any;
}

export default function ProfileScreen({ 
  navigateTo, 
  isParentMode, 
  setIsParentMode,
  childName,
  setChildName,
  collectedStickers,
  profileData,
  updateProfile,
  mbtiResult
}: ProfileScreenProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [tempName, setTempName] = useState(childName);
  const [showCustomization, setShowCustomization] = useState(false);

  const avatarOptions = ['👦', '👧', '🧒', '👶', '🐱', '🐶', '🦊', '🐼', '🐸', '🦄'];
  const colorOptions = [
    { name: 'blue', color: '#3B82F6', label: 'Biru' },
    { name: 'green', color: '#10B981', label: 'Hijau' },
    { name: 'purple', color: '#8B5CF6', label: 'Ungu' },
    { name: 'pink', color: '#EC4899', label: 'Pink' },
    { name: 'orange', color: '#F97316', label: 'Oranye' },
    { name: 'yellow', color: '#F59E0B', label: 'Kuning' }
  ];

  const handleNameSave = () => {
    setChildName(tempName);
    setIsEditing(false);
  };

  const handleAvatarChange = (avatar: string) => {
    updateProfile({ avatar });
  };

  const handleColorChange = (color: any) => {
    updateProfile({ 
      favoriteColor: color.name,
      backgroundColor: color.color 
    });
  };

  if (showCustomization) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-white px-6 pt-14 pb-6 border-b border-gray-100">
          <div className="flex items-center justify-between">
            <motion.button
              onClick={() => setShowCustomization(false)}
              className="p-2 rounded-xl bg-gray-100"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-gray-600" />
            </motion.button>
            <h1 className="text-gray-900 font-heading font-bold text-xl">Kustomisasi</h1>
            <div className="w-10" />
          </div>
        </div>

        <div className="p-6">
          {/* Preview */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-8"
          >
            <div 
              className="w-24 h-24 rounded-full mx-auto mb-4 flex items-center justify-center shadow-lg"
              style={{ backgroundColor: profileData.backgroundColor }}
            >
              <span className="text-4xl">{profileData.avatar}</span>
            </div>
            <h2 className="text-2xl font-heading font-bold text-gray-900">{childName}</h2>
            <p className="text-gray-600 font-body">Warna favorit: {
              colorOptions.find(c => c.name === profileData.favoriteColor)?.label
            }</p>
          </motion.div>

          {/* Avatar Selection */}
          <div className="mb-8">
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
              Pilih Avatar 😊
            </h3>
            <div className="grid grid-cols-5 gap-3">
              {avatarOptions.map((avatar, index) => (
                <motion.button
                  key={index}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: index * 0.05 }}
                  onClick={() => handleAvatarChange(avatar)}
                  className={`aspect-square bg-white rounded-2xl shadow-sm border-3 flex items-center justify-center text-2xl transition-all ${
                    profileData.avatar === avatar
                      ? 'border-orange-500 bg-orange-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  {avatar}
                </motion.button>
              ))}
            </div>
          </div>

          {/* Color Selection */}
          <div className="mb-8">
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
              Warna Favorit 🎨
            </h3>
            <div className="grid grid-cols-3 gap-3">
              {colorOptions.map((color, index) => (
                <motion.button
                  key={color.name}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: index * 0.1 }}
                  onClick={() => handleColorChange(color)}
                  className={`p-4 bg-white rounded-2xl shadow-sm border-3 transition-all ${
                    profileData.favoriteColor === color.name
                      ? 'border-orange-500 bg-orange-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <div className="flex flex-col items-center space-y-2">
                    <div 
                      className="w-8 h-8 rounded-full shadow-sm"
                      style={{ backgroundColor: color.color }}
                    />
                    <span className="text-sm font-body font-medium text-gray-700">
                      {color.label}
                    </span>
                  </div>
                </motion.button>
              ))}
            </div>
          </div>

          {/* Badge Collection Preview */}
          <div>
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
              Badge Favoritku 🏆
            </h3>
            <div className="bg-white rounded-2xl p-4 shadow-sm">
              <div className="flex justify-center space-x-2">
                {profileData.badges.map((badge: string, index: number) => (
                  <div key={index} className="w-12 h-12 bg-yellow-100 rounded-xl flex items-center justify-center">
                    <span className="text-xl">
                      {badge === 'super-star' ? '⭐' : 
                       badge === 'brain-explorer' ? '🧠' : '🏆'}
                    </span>
                  </div>
                ))}
              </div>
              <p className="text-center text-gray-600 font-body text-sm mt-2">
                Kumpulkan lebih banyak badge dengan mengerjakan tes!
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div 
        className="px-6 pt-14 pb-16 text-white"
        style={{ 
          background: `linear-gradient(135deg, ${profileData.backgroundColor}, ${profileData.backgroundColor}dd)` 
        }}
      >
        <div className="flex items-center justify-center">
          <h1 className="font-heading font-bold text-xl">Profile</h1>
        </div>
      </div>

      {/* Profile Card */}
      <div className="px-6 -mt-8 mb-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-3xl p-6 shadow-lg"
        >
          {/* Avatar and Name */}
          <div className="text-center mb-6">
            <div className="relative inline-block">
              <div 
                className="w-20 h-20 rounded-full mx-auto mb-4 flex items-center justify-center shadow-lg"
                style={{ backgroundColor: profileData.backgroundColor }}
              >
                <span className="text-3xl">{profileData.avatar}</span>
              </div>
              <motion.button
                onClick={() => setShowCustomization(true)}
                className="absolute -bottom-2 -right-2 w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center shadow-lg"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <Edit3 className="w-4 h-4 text-white" />
              </motion.button>
            </div>
            
            {isEditing ? (
              <div className="space-y-3">
                <input
                  type="text"
                  value={tempName}
                  onChange={(e) => setTempName(e.target.value)}
                  className="text-center text-2xl font-heading font-bold text-gray-900 bg-gray-50 rounded-xl px-4 py-2 w-full border-2 border-gray-200 focus:border-blue-500 outline-none"
                />
                <div className="flex space-x-2 justify-center">
                  <button
                    onClick={handleNameSave}
                    className="bg-blue-500 text-white px-4 py-2 rounded-xl font-body font-medium text-sm"
                  >
                    Simpan
                  </button>
                  <button
                    onClick={() => {
                      setIsEditing(false);
                      setTempName(childName);
                    }}
                    className="bg-gray-200 text-gray-600 px-4 py-2 rounded-xl font-body font-medium text-sm"
                  >
                    Batal
                  </button>
                </div>
              </div>
            ) : (
              <div>
                <button
                  onClick={() => setIsEditing(true)}
                  className="text-2xl font-heading font-bold text-gray-900 hover:text-blue-600 transition-colors"
                >
                  {childName}
                </button>
                <p className="text-gray-500 font-body text-sm mt-1">
                  {childName.toLowerCase()}@gmail.com
                </p>
              </div>
            )}
          </div>

          {/* Stats Card */}
          <div 
            className="rounded-2xl p-4 mb-6 text-white"
            style={{ 
              background: `linear-gradient(135deg, ${profileData.backgroundColor}, ${profileData.backgroundColor}ee)` 
            }}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
                  <span className="text-xl">🏆</span>
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="text-yellow-300 text-lg">💰</span>
                    <span className="font-heading font-bold text-lg">4500</span>
                  </div>
                  <p className="text-white/80 text-sm font-body">Total Points</p>
                </div>
              </div>
              <div className="text-center">
                <div className="font-heading font-bold text-2xl">{collectedStickers.length}</div>
                <p className="text-white/80 text-sm font-body">Stiker</p>
              </div>
            </div>
          </div>

          {/* MBTI Result */}
          {mbtiResult && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-gradient-to-r from-purple-100 to-pink-100 border border-purple-200 rounded-2xl p-4 mb-4"
            >
              <div className="flex items-center space-x-4">
                <div className="text-4xl">{mbtiResult.animal}</div>
                <div className="flex-1">
                  <h3 className="font-heading font-bold text-purple-800 text-base">
                    Kepribadian: {mbtiResult.name}
                  </h3>
                  <p className="text-purple-600 font-body text-sm">
                    {mbtiResult.personality}
                  </p>
                  <p className="text-purple-500 font-body text-xs mt-1">
                    {mbtiResult.traits}
                  </p>
                </div>
                <motion.button
                  onClick={() => navigateTo('personality-test')}
                  className="bg-purple-500 text-white px-3 py-2 rounded-xl font-body font-medium text-xs"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  Lihat Detail
                </motion.button>
              </div>
            </motion.div>
          )}

          {/* Customization Button */}
          <motion.button
            onClick={() => setShowCustomization(true)}
            className="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white p-4 rounded-2xl shadow-sm mb-4"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <div className="flex items-center justify-center space-x-3">
              <Palette className="w-5 h-5" />
              <span className="font-heading font-semibold">Kustomisasi Profile</span>
            </div>
          </motion.button>
        </motion.div>
      </div>

      {/* Menu Items */}
      <div className="px-6 space-y-3 mb-24">
        {/* Parent Mode Toggle */}
        <motion.button
          onClick={() => setIsParentMode(!isParentMode)}
          className={`w-full bg-white rounded-2xl p-4 shadow-sm flex items-center space-x-4 ${
            isParentMode ? 'ring-2 ring-orange-500' : ''
          }`}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
            <Users className="w-6 h-6 text-orange-600" />
          </div>
          <div className="flex-1 text-left">
            <h3 className="font-heading font-semibold text-gray-900 text-base">
              {isParentMode ? 'Mode Orang Tua (Aktif)' : 'Orang Tua'}
            </h3>
            {isParentMode && (
              <p className="text-sm text-orange-600 font-body">Klik untuk kembali ke mode anak</p>
            )}
          </div>
        </motion.button>

        {/* Sticker Collection */}
        <motion.button
          onClick={() => navigateTo('stickers')}
          className="w-full bg-white rounded-2xl p-4 shadow-sm flex items-center space-x-4"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
            <span className="text-xl">🎨</span>
          </div>
          <div className="flex-1 text-left">
            <h3 className="font-heading font-semibold text-gray-900 text-base">Koleksi Stiker</h3>
            <p className="text-sm text-gray-500 font-body">
              {collectedStickers.length} stiker dikumpulkan
            </p>
          </div>
          <div className="text-gray-400">
            <span>›</span>
          </div>
        </motion.button>

        {/* Settings - For Parents */}
        {isParentMode && (
          <motion.button
            onClick={() => navigateTo('parent-guide')}
            className="w-full bg-white rounded-2xl p-4 shadow-sm flex items-center space-x-4"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
              <span className="text-xl">⚙️</span>
            </div>
            <div className="flex-1 text-left">
              <h3 className="font-heading font-semibold text-gray-900 text-base">Pengaturan</h3>
              <p className="text-sm text-gray-500 font-body">Tips dan panduan orang tua</p>
            </div>
            <div className="text-gray-400">
              <span>›</span>
            </div>
          </motion.button>
        )}

        {/* Logout */}
        <motion.button
          onClick={() => {
            console.log('Logout clicked');
          }}
          className="w-full bg-white rounded-2xl p-4 shadow-sm flex items-center space-x-4"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <div className="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center">
            <LogOut className="w-6 h-6 text-red-600" />
          </div>
          <div className="flex-1 text-left">
            <h3 className="font-heading font-semibold text-gray-900 text-base">Keluar</h3>
            <p className="text-sm text-gray-500 font-body">Logout dari aplikasi</p>
          </div>
        </motion.button>
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-100">
        <div className="flex justify-around py-3">
          {[
            { icon: Home, label: 'Beranda', screen: 'home' },
            { icon: MessageSquare, label: 'Konsultasi', screen: 'consultation' },
            { icon: Users, label: 'Komunitas', screen: 'community' },
            { icon: BarChart3, label: 'Progres', screen: 'progress' },
            { icon: User, label: 'Profil', screen: 'profile', active: true }
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