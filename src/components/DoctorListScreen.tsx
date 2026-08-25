import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Home, MessageSquare, BarChart3, User, Star, MessageCircle, Shield, CheckCircle, Users } from 'lucide-react';

interface DoctorListScreenProps {
  navigateTo: (screen: string, data?: any) => void;
  isParentMode: boolean;
  setIsParentMode?: (mode: boolean) => void;
}

export default function DoctorListScreen({ navigateTo, isParentMode, setIsParentMode }: DoctorListScreenProps) {
  const doctors = [
    {
      id: 1,
      name: 'Dr. Zaky Ainur Rahman',
      specialty: 'Dokter Umum',
      experience: '2 Tahun',
      rating: 4.8,
      price: 20000,
      image: '👨‍⚕️',
      availability: 'Online',
      ratingCount: 150,
      education: 'Universitas Veteran Jawa Timur',
      verified: true
    },
    {
      id: 2,
      name: 'Dr. Nizar Hakim',
      specialty: 'Dokter Anak',
      experience: '5 Tahun',
      rating: 4.9,
      price: 35000,
      image: '👨‍⚕️',
      availability: 'Online',
      ratingCount: 230,
      education: 'Universitas Airlangga',
      verified: true
    },
    {
      id: 3,
      name: 'Dr. Iren Sari',
      specialty: 'Psikolog Anak',
      experience: '3 Tahun',
      rating: 4.7,
      price: 40000,
      image: '👩‍⚕️',
      availability: 'Busy',
      ratingCount: 180,
      education: 'Universitas Indonesia',
      verified: true
    }
  ];

  const handleDoctorSelect = (doctor: any) => {
    if (doctor.availability !== 'Online') {
      return; // Prevent navigation if doctor is not available
    }
    
    navigateTo('doctor-detail', doctor);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-400 to-blue-500 px-6 pt-14 pb-8">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo('consultation')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-xl">Pilih Dokter</h1>
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
              <Shield className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-white font-heading font-semibold text-base">
                Konsultasi Terpercaya
              </h3>
              <p className="text-blue-100 text-sm font-body">
                Dokter bersertifikat untuk perkembangan anak
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Search and Filters */}
      <div className="px-6 -mt-4 mb-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-4 shadow-lg"
        >
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">
            Pilih Dokter yang Tepat
          </h3>
          
          {/* Filter Buttons */}
          <div className="flex space-x-2 mb-4">
            <button className="bg-blue-100 text-blue-600 px-4 py-2 rounded-xl text-sm font-body font-medium">
              Semua Dokter
            </button>
            <button className="bg-gray-100 text-gray-600 px-4 py-2 rounded-xl text-sm font-body font-medium">
              Anak
            </button>
            <button className="bg-gray-100 text-gray-600 px-4 py-2 rounded-xl text-sm font-body font-medium">
              Umum
            </button>
          </div>

          <div className="flex items-center space-x-2 text-sm text-gray-600">
            <CheckCircle className="w-4 h-4 text-green-500" />
            <span className="font-body">Semua dokter telah terverifikasi</span>
          </div>
        </motion.div>
      </div>

      {/* Doctor List */}
      <div className="px-6 pb-24 space-y-4">
        {doctors.map((doctor, index) => (
          <motion.div
            key={doctor.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className={`bg-white rounded-2xl p-4 shadow-sm border border-gray-100 ${
              doctor.availability === 'Online' ? 'hover:shadow-md' : 'opacity-75'
            }`}
          >
            <div className="flex items-start space-x-4">
              {/* Doctor Avatar */}
              <div className="relative">
                <div className="w-16 h-16 bg-blue-100 rounded-2xl flex items-center justify-center">
                  <span className="text-2xl">{doctor.image}</span>
                </div>
                {doctor.verified && (
                  <div className="absolute -top-1 -right-1 w-6 h-6 bg-green-500 rounded-full flex items-center justify-center">
                    <CheckCircle className="w-4 h-4 text-white" />
                  </div>
                )}
                <div className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 border-white ${
                  doctor.availability === 'Online' ? 'bg-green-500' : 'bg-yellow-500'
                }`} />
              </div>
              
              {/* Doctor Info */}
              <div className="flex-1">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="text-gray-900 font-heading font-bold text-base leading-tight">
                      {doctor.name}
                    </h3>
                    <p className="text-blue-600 font-body text-sm font-medium">
                      {doctor.specialty}
                    </p>
                  </div>
                  <div className="flex items-center space-x-1 bg-yellow-50 px-2 py-1 rounded-lg">
                    <Star className="w-3 h-3 text-yellow-500 fill-current" />
                    <span className="text-xs font-body font-semibold text-gray-700">
                      {doctor.rating}
                    </span>
                  </div>
                </div>
                
                <p className="text-gray-500 font-body text-xs mb-2">
                  {doctor.education}
                </p>
                
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="flex items-center space-x-1">
                      <div className="w-2 h-2 bg-orange-500 rounded-full" />
                      <span className="text-xs font-body text-gray-500">
                        {doctor.experience}
                      </span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <div className={`w-2 h-2 rounded-full ${
                        doctor.availability === 'Online' ? 'bg-green-500' : 'bg-yellow-500'
                      }`} />
                      <span className="text-xs font-body text-gray-500">
                        {doctor.availability === 'Online' ? 'Tersedia' : 'Sibuk'}
                      </span>
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <div className="text-orange-500 font-heading font-bold text-sm">
                      Rp {doctor.price.toLocaleString()}
                    </div>
                    <div className="text-xs text-gray-400 font-body">per sesi</div>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Chat Button */}
            <div className="mt-4 flex justify-end">
              <motion.button
                onClick={() => handleDoctorSelect(doctor)}
                className={`px-6 py-2 rounded-xl font-body font-semibold text-sm flex items-center space-x-2 ${
                  doctor.availability === 'Online'
                    ? 'bg-orange-500 hover:bg-orange-600 text-white shadow-sm'
                    : 'bg-gray-200 text-gray-500 cursor-not-allowed'
                }`}
                disabled={doctor.availability !== 'Online'}
                whileHover={doctor.availability === 'Online' ? { scale: 1.02 } : {}}
                whileTap={doctor.availability === 'Online' ? { scale: 0.98 } : {}}
              >
                <MessageCircle size={14} />
                <span>
                  {doctor.availability === 'Online' ? 'Mulai Chat' : 'Sedang Sibuk'}
                </span>
              </motion.button>
            </div>
          </motion.div>
        ))}

        {/* Emergency Contact */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
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
              className={`flex flex-col items-center space-y-1 py-2 px-2 ${
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