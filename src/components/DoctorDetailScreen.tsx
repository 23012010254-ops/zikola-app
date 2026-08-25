import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Star, GraduationCap, MapPin, FileText } from 'lucide-react';

interface DoctorDetailScreenProps {
  navigateTo: (screen: string) => void;
  doctor: any;
}

export default function DoctorDetailScreen({ navigateTo, doctor }: DoctorDetailScreenProps) {
  if (!doctor) {
    navigateTo('consultation');
    return null;
  }

  const doctorDetails = {
    education: 'Universitas Veteran Jawa Timur',
    practice: 'RS Muhammadiyah Surabaya',
    license: 'NIP-DR-2025-06-00123'
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-400 to-blue-500 px-6 pt-14 pb-16">
        <div className="flex items-center justify-between">
          <motion.button
            onClick={() => navigateTo('consultation')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-xl">Kenalan Sama Dokter</h1>
          <div className="w-10" />
        </div>
      </div>

      {/* Doctor Profile Card */}
      <div className="px-6 -mt-8 mb-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-3xl p-6 shadow-lg text-center"
        >
          {/* Doctor Avatar */}
          <div className="w-24 h-24 bg-blue-100 rounded-full mx-auto mb-4 flex items-center justify-center">
            <span className="text-4xl">{doctor.image}</span>
          </div>
          
          {/* Doctor Info */}
          <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
            {doctor.name}
          </h2>
          <p className="text-blue-600 font-body text-base mb-4">
            {doctor.specialty}
          </p>
          
          {/* Stats */}
          <div className="flex items-center justify-center space-x-6 mb-6">
            <div className="text-center">
              <div className="flex items-center justify-center space-x-1 mb-1">
                <div className="w-3 h-3 bg-orange-500 rounded-full" />
                <span className="text-gray-900 font-heading font-bold text-lg">
                  {doctor.experience}
                </span>
              </div>
              <p className="text-gray-500 text-xs font-body">Pengalaman</p>
            </div>
            
            <div className="text-center">
              <div className="flex items-center justify-center space-x-1 mb-1">
                <Star className="w-4 h-4 text-yellow-500 fill-current" />
                <span className="text-gray-900 font-heading font-bold text-lg">
                  {doctor.rating}% Suka
                </span>
              </div>
              <p className="text-gray-500 text-xs font-body">Rating</p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Consultation Fee */}
      <div className="px-6 mb-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-yellow-100 rounded-2xl p-4 border-2 border-dashed border-yellow-300"
        >
          <div className="text-center">
            <h3 className="text-gray-900 font-heading font-bold text-lg mb-2">
              Biaya Konsultasi : Rp {doctor.price.toLocaleString()}
            </h3>
          </div>
        </motion.div>
      </div>

      {/* Doctor Credentials */}
      <div className="px-6 mb-8 space-y-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-4 shadow-sm"
        >
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
              <GraduationCap className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h4 className="text-gray-900 font-heading font-semibold text-base">
                Lulusan Dari
              </h4>
              <p className="text-gray-600 font-body text-sm">
                {doctorDetails.education}
              </p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-2xl p-4 shadow-sm"
        >
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
              <MapPin className="w-6 h-6 text-green-600" />
            </div>
            <div>
              <h4 className="text-gray-900 font-heading font-semibold text-base">
                Tempat Praktik
              </h4>
              <p className="text-gray-600 font-body text-sm">
                {doctorDetails.practice}
              </p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-white rounded-2xl p-4 shadow-sm"
        >
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
              <FileText className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <h4 className="text-gray-900 font-heading font-semibold text-base">
                Nomor Izin Praktik
              </h4>
              <p className="text-gray-600 font-body text-sm">
                {doctorDetails.license}
              </p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Start Consultation Button */}
      <div className="px-6 pb-8">
        <motion.button
          onClick={() => navigateTo('payment')}
          className="w-full btn-orange"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
        >
          MULAI NGOBROL!
        </motion.button>
      </div>
    </div>
  );
}