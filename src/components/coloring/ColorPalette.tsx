import React from 'react';
import { motion } from 'motion/react';
import { colors } from './coloringData';

interface ColorPaletteProps {
  selectedColor: string;
  onColorSelect: (color: string) => void;
}

export default function ColorPalette({ selectedColor, onColorSelect }: ColorPaletteProps) {
  return (
    <div className="bg-white rounded-2xl p-4 shadow-sm mb-6">
      <h3 className="text-gray-900 font-heading font-semibold text-base mb-4">
        Pilih Warna 🎨
      </h3>
      <div className="grid grid-cols-6 gap-3">
        {colors.map((color, index) => (
          <motion.button
            key={color.name}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.05 }}
            onClick={() => onColorSelect(color.value)}
            className={`w-10 h-10 rounded-xl border-3 transition-all ${
              selectedColor === color.value
                ? 'border-gray-800 scale-110 shadow-lg'
                : 'border-gray-200 hover:border-gray-400'
            }`}
            style={{ backgroundColor: color.value }}
            whileHover={{ scale: selectedColor === color.value ? 1.1 : 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <span className="sr-only">{color.name}</span>
          </motion.button>
        ))}
      </div>
    </div>
  );
}