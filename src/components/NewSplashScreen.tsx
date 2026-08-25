import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export default function NewSplashScreen() {
  const [imageError, setImageError] = useState(false);
  const [logoSrc, setLogoSrc] = useState<string | null>(null);

  useEffect(() => {
    // Dynamically import the new ANAK logo
    const loadLogo = async () => {
      try {
        const logo = await import('figma:asset/d23cc22017b09da662f9bf1b2a9bad34d870b085.png');
        setLogoSrc(logo.default);
      } catch (error) {
        console.warn('Failed to load Figma logo, using fallback');
        setImageError(true);
      }
    };

    loadLogo();
  }, []);

  return (
    <div className="h-screen bg-gradient-to-b from-sky-300 via-sky-200 to-sky-100 relative overflow-hidden flex flex-col justify-center items-center">
      {/* Animated Sun in top right */}
      <div className="absolute top-8 right-8 w-20 h-20 bg-gradient-to-br from-yellow-300 to-orange-400 rounded-full shadow-lg animate-spin-slow">
        {/* Sun rays */}
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full top-0 left-1/2 transform -translate-x-1/2 -translate-y-6" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full top-1/2 right-0 transform -translate-y-1/2 translate-x-6 rotate-90" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full bottom-0 left-1/2 transform -translate-x-1/2 translate-y-6 rotate-180" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full top-1/2 left-0 transform -translate-y-1/2 -translate-x-6 -rotate-90" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full top-2 right-2 transform translate-x-4 -translate-y-4 rotate-45" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full bottom-2 right-2 transform translate-x-4 translate-y-4 rotate-135" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full bottom-2 left-2 transform -translate-x-4 translate-y-4 -rotate-45" />
        <div className="absolute w-1 h-4 bg-yellow-300 rounded-full top-2 left-2 transform -translate-x-4 -translate-y-4 -rotate-135" />
      </div>

      {/* Animated Clouds */}
      <div className="absolute top-16 left-8 w-16 h-10 bg-white rounded-full opacity-90 shadow-sm animate-float-slow" style={{animationDelay: '0s'}} />
      <div className="absolute top-28 right-6 w-20 h-12 bg-white rounded-full opacity-90 shadow-sm animate-float-medium" style={{animationDelay: '1s'}} />
      <div className="absolute top-12 left-1/2 transform -translate-x-1/2 w-12 h-8 bg-white rounded-full opacity-90 shadow-sm animate-float-slow" style={{animationDelay: '2s'}} />
      <div className="absolute bottom-36 left-10 w-14 h-10 bg-white rounded-full opacity-90 shadow-sm animate-float-medium" style={{animationDelay: '0.5s'}} />
      <div className="absolute bottom-28 right-8 w-18 h-12 bg-white rounded-full opacity-90 shadow-sm animate-float-slow" style={{animationDelay: '1.5s'}} />

      {/* Main Logo Container */}
      <div className="relative z-20 flex flex-col items-center">
        {/* ANAK Logo */}
        <div className="relative mb-8 flex flex-col items-center">
          <motion.div 
            className="w-72 h-72 mb-6 flex items-center justify-center"
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ 
              duration: 1.2, 
              ease: "easeOut",
              type: "spring",
              stiffness: 200,
              damping: 15
            }}
          >
            {!imageError && logoSrc ? (
              <motion.div
                className="w-full h-full relative"
                animate={{ 
                  scale: [1, 1.05, 1],
                  rotateY: [0, 10, 0, -10, 0]
                }}
                transition={{ 
                  duration: 4,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
              >
                <ImageWithFallback 
                  src={logoSrc} 
                  alt="ANAK Logo" 
                  className="w-full h-full object-contain drop-shadow-2xl"
                  onError={() => setImageError(true)}
                />
                {/* Glowing effect */}
                <div className="absolute inset-0 bg-gradient-to-r from-blue-400/20 via-purple-400/20 to-pink-400/20 rounded-full blur-xl animate-pulse" />
              </motion.div>
            ) : (
              // Enhanced fallback logo
              <motion.div 
                className="w-full h-full flex items-center justify-center bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500 rounded-full shadow-2xl"
                animate={{ 
                  rotate: [0, 360],
                  scale: [1, 1.1, 1]
                }}
                transition={{ 
                  rotate: { duration: 20, repeat: Infinity, ease: "linear" },
                  scale: { duration: 3, repeat: Infinity, ease: "easeInOut" }
                }}
              >
                <div className="text-center">
                  <motion.div 
                    className="text-8xl mb-4"
                    animate={{ scale: [1, 1.2, 1] }}
                    transition={{ duration: 2, repeat: Infinity }}
                  >
                    🧠
                  </motion.div>
                  <div className="text-5xl font-heading font-bold text-white tracking-wider drop-shadow-lg">
                    ANAK
                  </div>
                </div>
              </motion.div>
            )}
          </motion.div>
          
          {/* Subtitle - BOLD WITH FUN FONT */}
          <motion.div 
            className="text-center"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8, duration: 0.6 }}
          >
            <p className="text-lg font-heading text-gray-700 mt-1 font-bold tracking-wide">
              ANALISIS NEUROPSIKOLOGI DAN AKTIVITAS KOGNITIF
            </p>
          </motion.div>
        </div>

        {/* Enhanced Loading Animation */}
        <motion.div 
          className="flex space-x-3"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2 }}
        >
          <motion.div 
            className="w-4 h-4 bg-blue-500 rounded-full" 
            animate={{ scale: [1, 1.5, 1], opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 1, repeat: Infinity, delay: 0 }}
          />
          <motion.div 
            className="w-4 h-4 bg-orange-500 rounded-full" 
            animate={{ scale: [1, 1.5, 1], opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 1, repeat: Infinity, delay: 0.3 }}
          />
          <motion.div 
            className="w-4 h-4 bg-green-500 rounded-full" 
            animate={{ scale: [1, 1.5, 1], opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 1, repeat: Infinity, delay: 0.6 }}
          />
        </motion.div>
      </div>

      {/* Enhanced animated sparkles */}
      <motion.div 
        className="absolute top-1/4 left-1/4 w-2 h-2 bg-blue-400 rounded-full opacity-60" 
        animate={{ scale: [0, 1, 0], rotate: [0, 180, 360] }}
        transition={{ duration: 2, repeat: Infinity, delay: 0 }}
      />
      <motion.div 
        className="absolute top-1/3 right-1/4 w-2 h-2 bg-orange-400 rounded-full opacity-60" 
        animate={{ scale: [0, 1, 0], rotate: [0, 180, 360] }}
        transition={{ duration: 2, repeat: Infinity, delay: 0.5 }}
      />
      <motion.div 
        className="absolute bottom-1/3 left-1/3 w-2 h-2 bg-green-400 rounded-full opacity-60" 
        animate={{ scale: [0, 1, 0], rotate: [0, 180, 360] }}
        transition={{ duration: 2, repeat: Infinity, delay: 1 }}
      />
      <motion.div 
        className="absolute bottom-1/4 right-1/3 w-2 h-2 bg-purple-400 rounded-full opacity-60" 
        animate={{ scale: [0, 1, 0], rotate: [0, 180, 360] }}
        transition={{ duration: 2, repeat: Infinity, delay: 1.5 }}
      />
      <motion.div 
        className="absolute top-2/3 left-1/5 w-2 h-2 bg-pink-400 rounded-full opacity-60" 
        animate={{ scale: [0, 1, 0], rotate: [0, 180, 360] }}
        transition={{ duration: 2, repeat: Infinity, delay: 2 }}
      />
      <motion.div 
        className="absolute top-3/4 right-1/5 w-2 h-2 bg-indigo-400 rounded-full opacity-60" 
        animate={{ scale: [0, 1, 0], rotate: [0, 180, 360] }}
        transition={{ duration: 2, repeat: Infinity, delay: 2.5 }}
      />

      {/* Soft gradient overlay */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-white/60 to-transparent z-10" />
    </div>
  );
}