import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, RotateCcw } from 'lucide-react';
import { coloringImages, getDifficultyColor } from './coloring/coloringData';
import CompletionScreen from './coloring/CompletionScreen';
import ColorPalette from './coloring/ColorPalette';
import ColoringCanvas from './coloring/ColoringCanvas';

interface ColoringGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
}

export default function ColoringGameScreen({ navigateTo, addSticker }: ColoringGameScreenProps) {
  const [selectedImage, setSelectedImage] = useState<any>(null);
  const [selectedColor, setSelectedColor] = useState('#3B82F6');
  const [coloredAreas, setColoredAreas] = useState<{ [key: string]: string }>({});
  const [isCompleted, setIsCompleted] = useState(false);

  const handleAreaColor = (areaId: string) => {
    const newColoredAreas = { ...coloredAreas, [areaId]: selectedColor };
    setColoredAreas(newColoredAreas);

    if (Object.keys(newColoredAreas).length === selectedImage.areas) {
      setIsCompleted(true);
      addSticker('artist-star');
      
      setTimeout(() => {
        setSelectedImage(null);
        setIsCompleted(false);
        setColoredAreas({});
      }, 3000);
    }
  };

  const resetColoring = () => {
    setColoredAreas({});
    setIsCompleted(false);
  };

  const handlePlayAgain = () => {
    setSelectedImage(null);
    setIsCompleted(false);
    setColoredAreas({});
  };

  if (isCompleted) {
    return <CompletionScreen selectedImage={selectedImage} onPlayAgain={handlePlayAgain} />;
  }

  if (selectedImage) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-pink-500 to-purple-600 px-6 pt-14 pb-6">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              onClick={() => setSelectedImage(null)}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </motion.button>
            <h1 className="text-white font-heading font-bold text-lg">{selectedImage.title}</h1>
            <motion.button
              onClick={resetColoring}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <RotateCcw className="w-6 h-6 text-white" />
            </motion.button>
          </div>
        </div>

        {/* Game Content */}
        <div className="px-6 py-6">
          <ColorPalette selectedColor={selectedColor} onColorSelect={setSelectedColor} />
          <ColoringCanvas 
            selectedImage={selectedImage}
            coloredAreas={coloredAreas}
            onAreaColor={handleAreaColor}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-pink-500 to-purple-600 px-6 pt-14 pb-8">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo('game')}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-xl">Coloring Games</h1>
          <div className="w-10" />
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
        >
          <h2 className="text-white font-heading font-semibold text-lg mb-2">
            Pilih Gambar untuk Diwarnai! 🎨
          </h2>
          <p className="text-pink-100 font-body text-sm">
            Ekspresikan kreativitasmu dengan warna-warna indah
          </p>
        </motion.div>
      </div>

      {/* Image Selection */}
      <div className="px-6 -mt-4 pb-8">
        <div className="grid grid-cols-2 gap-4">
          {coloringImages.map((image, index) => (
            <motion.button
              key={image.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => setSelectedImage(image)}
              className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 hover:shadow-md transition-all"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="text-center">
                <div className="text-4xl mb-3">{image.preview}</div>
                <h3 className="text-gray-900 font-heading font-bold text-sm mb-1">
                  {image.title}
                </h3>
                <p className="text-gray-600 font-body text-xs mb-3 leading-tight">
                  {image.description}
                </p>
                <div className="flex items-center justify-between">
                  <span className={`px-2 py-1 rounded-lg text-xs font-body font-medium ${getDifficultyColor(image.difficulty)}`}>
                    {image.difficulty}
                  </span>
                  <span className="text-gray-500 text-xs font-body">
                    {image.areas} area
                  </span>
                </div>
              </div>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}