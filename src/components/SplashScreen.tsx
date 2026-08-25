import React from 'react';
import { motion } from 'motion/react';
import anakLogo from 'figma:asset/e98844b3cc7b597ff0b79e0a631a430f264ab517.png';

export default function SplashScreen() {
  // Floating geometric shapes data
  const floatingShapes = [
    { type: 'triangle', color: 'bg-blue-300', size: 'w-8 h-8', position: 'top-20 left-10', rotation: '0deg' },
    { type: 'square', color: 'bg-purple-500', size: 'w-12 h-12', position: 'top-16 left-1/3', rotation: '45deg' },
    { type: 'triangle', color: 'bg-red-500', size: 'w-16 h-16', position: 'top-24 right-12', rotation: '0deg' },
    { type: 'square', color: 'bg-blue-600', size: 'w-20 h-20', position: 'top-1/3 right-8', rotation: '30deg' },
    { type: 'triangle', color: 'bg-orange-500', size: 'w-24 h-24', position: 'top-12 left-4', rotation: '0deg' },
    { type: 'square', color: 'bg-yellow-300', size: 'w-16 h-16', position: 'bottom-1/2 left-12', rotation: '60deg' },
    { type: 'triangle', color: 'bg-pink-500', size: 'w-12 h-12', position: 'bottom-1/3 left-6', rotation: '0deg' },
    { type: 'triangle', color: 'bg-green-400', size: 'w-6 h-6', position: 'bottom-1/4 right-16', rotation: '0deg' },
    { type: 'triangle', color: 'bg-red-400', size: 'w-8 h-8', position: 'bottom-20 left-20', rotation: '0deg' },
    { type: 'square', color: 'bg-yellow-400', size: 'w-32 h-32', position: 'bottom-12 right-4', rotation: '45deg' },
  ];

  return (
    <div className="h-screen bg-gradient-to-br from-blue-400 via-blue-500 to-blue-600 relative overflow-hidden flex flex-col">
      {/* Floating Geometric Shapes */}
      {floatingShapes.map((shape, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, scale: 0 }}
          animate={{ 
            opacity: 0.9, 
            scale: 1,
            y: [0, -15, 0],
            rotate: [0, 10, 0]
          }}
          transition={{ 
            opacity: { duration: 0.5, delay: index * 0.1 },
            scale: { duration: 0.5, delay: index * 0.1 },
            y: { duration: 4 + index * 0.3, repeat: Infinity, ease: "easeInOut" },
            rotate: { duration: 5 + index * 0.2, repeat: Infinity, ease: "easeInOut" }
          }}
          className={`absolute ${shape.position} ${shape.size} ${shape.color} shadow-lg`}
          style={{ 
            transform: `rotate(${shape.rotation})`,
            clipPath: shape.type === 'triangle' ? 'polygon(50% 0%, 0% 100%, 100% 100%)' : undefined,
            borderRadius: shape.type === 'square' ? '8px' : undefined
          }}
        />
      ))}

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col items-center justify-center text-center px-8 relative z-10">
        {/* ANAK Logo */}
        <motion.div
          initial={{ scale: 0, rotate: -180 }}
          animate={{ scale: 1, rotate: 0 }}
          transition={{ duration: 1, type: "spring", stiffness: 150 }}
          className="mb-12"
        >
          <motion.img 
            src={anakLogo} 
            alt="ANAK Logo" 
            className="w-40 h-40 mx-auto object-contain"
            animate={{
              y: [-5, 5, -5],
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
        </motion.div>

        {/* Title Text */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5, duration: 0.8 }}
          className="text-white mb-12"
        >
          <h1 className="font-heading font-bold text-2xl mb-2 leading-tight">
            ANALISIS NEUROPSIKOLOGI
          </h1>
          <h2 className="font-heading font-bold text-2xl mb-8 leading-tight">
            DAN AKTIVITAS KOGNITIF
          </h2>
          
          {/* Three dots indicator */}
          <div className="flex justify-center space-x-3 mb-8">
            {[0, 1, 2].map((dot) => (
              <motion.div
                key={dot}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 1 + dot * 0.1 }}
                className={`w-3 h-3 rounded-full ${
                  dot === 0 ? 'bg-white' : 'bg-white/40'
                }`}
              />
            ))}
          </div>
        </motion.div>
      </div>

      {/* Bottom White Card */}
      <motion.div
        initial={{ opacity: 0, y: 100 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8, duration: 0.8 }}
        className="bg-white rounded-t-3xl px-8 py-8 relative z-20"
      >
        <div className="text-center">
          <h3 className="text-red-500 font-heading font-bold text-lg leading-tight">
            Pahami Potensi, Wujudkan
          </h3>
          <h3 className="text-red-500 font-heading font-bold text-lg leading-tight">
            Masa Depan Anak
          </h3>
        </div>
      </motion.div>

      {/* Loading Animation */}
      <motion.div
        className="absolute bottom-32 left-1/2 transform -translate-x-1/2 z-30"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5 }}
      >
        <div className="flex space-x-2">
          {[...Array(3)].map((_, i) => (
            <motion.div
              key={i}
              className="w-2 h-2 bg-white/80 rounded-full"
              animate={{
                scale: [1, 1.5, 1],
                opacity: [0.6, 1, 0.6],
              }}
              transition={{
                duration: 1.2,
                repeat: Infinity,
                delay: i * 0.2,
              }}
            />
          ))}
        </div>
      </motion.div>
    </div>
  );
}