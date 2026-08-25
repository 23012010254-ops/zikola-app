import React from 'react';
import { motion } from 'motion/react';
import { Trophy, Share2, Download } from 'lucide-react';

interface CompletionScreenProps {
  selectedImage: any;
  onPlayAgain: () => void;
}

export default function CompletionScreen({ selectedImage, onPlayAgain }: CompletionScreenProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-400 to-purple-600 flex items-center justify-center">
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", stiffness: 200, damping: 15 }}
        className="bg-white rounded-3xl p-8 text-center max-w-sm mx-4 shadow-2xl"
      >
        <motion.div
          animate={{ 
            scale: [1, 1.2, 1],
            rotate: [0, 10, -10, 0]
          }}
          transition={{ duration: 0.8, repeat: 2 }}
          className="text-8xl mb-4"
        >
          🎨
        </motion.div>
        
        <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
          Karya Seni Indah! ✨
        </h2>
        <p className="text-gray-600 font-body text-base mb-4">
          Kamu berhasil mewarnai {selectedImage.title} dengan sempurna!
        </p>
        
        <div className="bg-purple-50 rounded-2xl p-4 mb-6">
          <div className="flex items-center justify-center space-x-2 mb-2">
            <Trophy className="w-5 h-5 text-purple-600" />
            <span className="text-purple-700 font-body font-semibold">Seniman Hebat!</span>
          </div>
          <p className="text-purple-600 font-body text-sm">
            Stiker "Artist Star" ditambahkan ke koleksimu!
          </p>
        </div>

        <div className="flex space-x-3 mb-6">
          <motion.button
            className="flex-1 bg-blue-500 text-white py-2 px-4 rounded-xl font-body font-semibold text-sm flex items-center justify-center space-x-2"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Share2 className="w-4 h-4" />
            <span>Bagikan</span>
          </motion.button>
          
          <motion.button
            className="flex-1 bg-green-500 text-white py-2 px-4 rounded-xl font-body font-semibold text-sm flex items-center justify-center space-x-2"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Download className="w-4 h-4" />
            <span>Simpan</span>
          </motion.button>
        </div>

        <motion.button
          onClick={onPlayAgain}
          className="w-full bg-gradient-to-r from-pink-500 to-purple-500 text-white py-3 px-6 rounded-2xl font-heading font-bold shadow-lg"
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          Warnai Lagi
        </motion.button>
      </motion.div>
    </div>
  );
}