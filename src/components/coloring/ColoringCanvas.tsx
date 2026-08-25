import React from 'react';
import { motion } from 'motion/react';

interface ColoringCanvasProps {
  selectedImage: any;
  coloredAreas: { [key: string]: string };
  onAreaColor: (areaId: string) => void;
}

export default function ColoringCanvas({ selectedImage, coloredAreas, onAreaColor }: ColoringCanvasProps) {
  const generateColoringAreas = () => {
    const areas = [];
    for (let i = 0; i < selectedImage.areas; i++) {
      areas.push({
        id: `area-${i}`,
        x: (i % 4) * 25,
        y: Math.floor(i / 4) * 25,
        width: 20,
        height: 20
      });
    }
    return areas;
  };

  // Example coloring template based on image type
  const getExampleColors = () => {
    switch (selectedImage.id) {
      case 'butterfly':
        return {
          'area-0': '#FF6B6B', 'area-1': '#4ECDC4', 'area-2': '#45B7D1',
          'area-3': '#96CEB4', 'area-4': '#FFEAA7', 'area-5': '#DDA0DD',
          'area-6': '#98D8C8', 'area-7': '#F7DC6F'
        };
      case 'flower':
        return {
          'area-0': '#FF69B4', 'area-1': '#FFB6C1', 'area-2': '#90EE90',
          'area-3': '#228B22', 'area-4': '#FFFF00', 'area-5': '#FFA500'
        };
      case 'cat':
        return {
          'area-0': '#D2691E', 'area-1': '#F4A460', 'area-2': '#000000',
          'area-3': '#FF69B4', 'area-4': '#FFFFFF', 'area-5': '#808080'
        };
      default:
        return {
          'area-0': '#FF6B6B', 'area-1': '#4ECDC4', 'area-2': '#45B7D1',
          'area-3': '#96CEB4', 'area-4': '#FFEAA7', 'area-5': '#DDA0DD'
        };
    }
  };

  const areas = generateColoringAreas();
  const exampleColors = getExampleColors();

  return (
    <div className="bg-white rounded-3xl p-6 shadow-lg mb-6">
      <div className="text-center mb-6">
        <div className="text-6xl mb-2">{selectedImage.preview}</div>
        <h2 className="text-gray-900 font-heading font-bold text-xl">
          {selectedImage.title}
        </h2>
        <p className="text-gray-600 font-body text-sm">
          Ketuk area untuk mewarnai
        </p>
      </div>

      {/* Coloring Canvas with Background Example */}
      <div className="relative bg-gray-50 rounded-2xl p-8 min-h-80 flex items-center justify-center">
        <div className="relative">
          {/* Background Example (faded) */}
          <svg
            width="300"
            height="300"
            viewBox="0 0 100 100"
            className="absolute inset-0 border-2 border-gray-200 rounded-xl bg-white opacity-30"
          >
            {areas.map((area) => (
              <rect
                key={`example-${area.id}`}
                x={area.x}
                y={area.y}
                width={area.width}
                height={area.height}
                fill={exampleColors[area.id] || '#ffffff'}
                stroke="#e5e7eb"
                strokeWidth="0.5"
              />
            ))}
            
            {/* Simple outline overlay for example */}
            <g stroke="#374151" strokeWidth="1" fill="none">
              <circle cx="50" cy="40" r="15" opacity="0.3" />
              <ellipse cx="50" cy="70" rx="20" ry="15" opacity="0.3" />
            </g>
          </svg>

          {/* Actual Coloring Canvas */}
          <svg
            width="300"
            height="300"
            viewBox="0 0 100 100"
            className="relative border-2 border-gray-200 rounded-xl bg-white"
          >
            {areas.map((area, index) => (
              <motion.rect
                key={area.id}
                x={area.x}
                y={area.y}
                width={area.width}
                height={area.height}
                fill={coloredAreas[area.id] || 'rgba(255,255,255,0.9)'}
                stroke="#e5e7eb"
                strokeWidth="0.5"
                className="cursor-pointer hover:opacity-80 transition-opacity"
                onClick={() => onAreaColor(area.id)}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: index * 0.05 }}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              />
            ))}
            
            {/* Simple outline overlay */}
            <motion.g
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
              stroke="#374151"
              strokeWidth="1"
              fill="none"
            >
              {/* Create simple outline based on the preview emoji */}
              <circle cx="50" cy="40" r="15" opacity="0.3" />
              <ellipse cx="50" cy="70" rx="20" ry="15" opacity="0.3" />
            </motion.g>
          </svg>
        </div>

        {/* Example Toggle */}
        <div className="absolute top-4 right-4">
          <div className="bg-white/80 backdrop-blur-sm rounded-lg p-2 text-xs text-gray-600 font-body">
            💡 Latar belakang menunjukkan contoh pewarnaan
          </div>
        </div>
      </div>

      {/* Progress */}
      <div className="mt-6">
        <div className="flex items-center justify-between mb-2">
          <span className="text-gray-600 font-body text-sm">Progress</span>
          <span className="text-gray-900 font-body font-semibold">
            {Object.keys(coloredAreas).length}/{selectedImage.areas}
          </span>
        </div>
        <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
          <motion.div
            className="h-2 bg-gradient-to-r from-pink-500 to-purple-500 rounded-full"
            initial={{ width: 0 }}
            animate={{ width: `${(Object.keys(coloredAreas).length / selectedImage.areas) * 100}%` }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </div>
    </div>
  );
}