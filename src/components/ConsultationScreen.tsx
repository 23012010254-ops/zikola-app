import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Home, MessageSquare, BarChart3, User, BookOpen, Stethoscope, Users, Heart, Clock, Award } from 'lucide-react';

interface ConsultationScreenProps {
  navigateTo: (screen: string, data?: any) => void;
  isParentMode: boolean;
  setIsParentMode?: (mode: boolean) => void;
}

export default function ConsultationScreen({ navigateTo, isParentMode, setIsParentMode }: ConsultationScreenProps) {
  const consultationOptions = [
    {
      id: 'parent-guide',
      title: 'Panduan Orang Tua',
      description: 'Tips dan panduan lengkap untuk mendampingi perkembangan anak',
      icon: BookOpen,
      color: 'from-blue-500 to-blue-600',
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-600',
      features: [
        'Panduan perkembangan anak',
        'Tips parenting',
        'Aktivitas edukatif',
        'Milestone tracking'
      ],
      action: () => navigateTo('parent-guide')
    },
    {
      id: 'doctor-consultation',
      title: 'Konsultasi Dokter',
      description: 'Konsultasi langsung dengan dokter anak dan psikolog berpengalaman',
      icon: Stethoscope,
      color: 'from-green-500 to-green-600',
      bgColor: 'bg-green-50',
      textColor: 'text-green-600',
      features: [
        'Konsultasi real-time',
        'Dokter bersertifikat',
        'Sesi privat & aman',
        'Rekam medis digital'
      ],
      action: () => {
        if (!isParentMode && setIsParentMode) {
          setIsParentMode(true);
        }
        navigateTo('doctor-list');
      }
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-500 to-purple-600 px-6 pt-14 pb-8 bg-[rgba(218,70,70,0)]">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo('home')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-xl">Konsultasi & Panduan</h1>
          <div className="w-10" />
        </div>

        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
        >
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
              <Heart className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-white font-heading font-semibold text-base">
                Dukungan Lengkap untuk Anak
              </h3>
              <p className="text-purple-100 text-sm font-body">
                Panduan dan konsultasi profesional dalam satu tempat
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Consultation Options */}
      <div className="px-6 -mt-4 pb-24">
        <div className="space-y-6">
          {consultationOptions.map((option, index) => (
            <motion.div
              key={option.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.2 }}
              className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100"
            >
              {/* Header */}
              <div className="flex items-start space-x-4 mb-4">
                <div className={`w-16 h-16 bg-gradient-to-r ${option.color} rounded-2xl flex items-center justify-center shadow-lg`}>
                  <option.icon className="w-8 h-8 text-white" />
                </div>
                <div className="flex-1">
                  <h3 className="text-gray-900 font-heading font-bold text-xl mb-2">
                    {option.title}
                  </h3>
                  <p className="text-gray-600 font-body text-sm leading-relaxed">
                    {option.description}
                  </p>
                </div>
              </div>

              {/* Features */}
              <div className="mb-6">
                <h4 className="text-gray-700 font-heading font-semibold text-sm mb-3">
                  Yang Anda Dapatkan:
                </h4>
                <div className="grid grid-cols-2 gap-3">
                  {option.features.map((feature, featureIndex) => (
                    <div key={featureIndex} className="flex items-center space-x-2">
                      <div className="w-2 h-2 bg-green-500 rounded-full" />
                      <span className="text-gray-600 font-body text-xs">{feature}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Action Button */}
              <motion.button
                onClick={option.action}
                className={`w-full bg-gradient-to-r ${option.color} text-white py-4 px-6 rounded-xl font-heading font-bold text-base shadow-lg`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                {option.id === 'parent-guide' ? 'Buka Panduan' : 'Pilih Dokter'}
              </motion.button>
            </motion.div>
          ))}
        </div>

        {/* Stats Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="bg-gradient-to-r from-orange-50 to-yellow-50 border border-orange-200 rounded-2xl p-6 mt-8"
        >
          <h3 className="text-orange-700 font-heading font-bold text-lg mb-4 text-center">
            Dipercaya Ribuan Orang Tua
          </h3>
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-heading font-bold text-orange-600 mb-1">500+</div>
              <div className="text-xs text-orange-600 font-body">Konsultasi</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-heading font-bold text-orange-600 mb-1">15+</div>
              <div className="text-xs text-orange-600 font-body">Dokter Ahli</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-heading font-bold text-orange-600 mb-1">4.8★</div>
              <div className="text-xs text-orange-600 font-body">Rating</div>
            </div>
          </div>
        </motion.div>

        {/* Emergency Contact */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="bg-red-50 border border-red-200 rounded-2xl p-4 mt-6"
        >
          <div className="text-center">
            <div className="text-3xl mb-2">🚨</div>
            <h3 className="text-red-700 font-heading font-bold text-base mb-1">
              Kondisi Darurat?
            </h3>
            <p className="text-red-600 text-sm font-body mb-3">
              Segera hubungi layanan gawat darurat terdekat
            </p>
            <button className="bg-red-500 text-white px-6 py-2 rounded-xl font-body font-semibold text-sm">
              Hubungi 119
            </button>
          </div>
        </motion.div>
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-100">
        <div className="flex justify-around py-3">
          {[
            { icon: Home, label: 'Beranda', screen: 'home' },
            { icon: MessageSquare, label: 'Konsultasi', screen: 'consultation', active: true },
            { icon: Users, label: 'Komunitas', screen: 'community' },
            { icon: BarChart3, label: 'Progres', screen: 'progress' },
            { icon: User, label: 'Profil', screen: 'profile' }
          ].map((item) => (
            <motion.button
              key={item.screen}
              onClick={() => navigateTo(item.screen)}
              className={`flex flex-col items-center space-y-1 py-2 px-3 ${
                item.active && isParentMode
                  ? 'text-orange-500' 
                  : 'text-gray-400'
              }`}
              whileTap={{ scale: 0.95 }}
            >
              <item.icon size={16} />
              <span className="text-xs font-body font-medium">{item.label}</span>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}