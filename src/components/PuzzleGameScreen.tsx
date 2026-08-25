import React, { useState, useEffect, useCallback } from "react";
import { motion } from "motion/react";
import {
  ArrowLeft,
  RotateCcw,
  Lightbulb,
  CheckCircle,
  Trophy,
} from "lucide-react";

interface PuzzleGameScreenProps {
  navigateTo: (screen: string) => void;
  addSticker: (sticker: string) => void;
}

// Simple Touch-friendly Puzzle Components
const PuzzlePiece = React.memo(({
  piece,
  onSelect,
  isSelected,
  wrongMoveShake,
}: {
  piece: any;
  onSelect: (id: number) => void;
  isSelected: boolean;
  wrongMoveShake?: boolean;
}) => {
  return (
    <motion.button
      onClick={() => onSelect(piece.id)}
      className={`w-16 h-16 bg-blue-100 border-3 border-blue-300 rounded-2xl flex items-center justify-center font-heading font-bold text-lg transition-all relative overflow-hidden ${
        isSelected
          ? "ring-4 ring-blue-400 bg-blue-200 shadow-lg"
          : "hover:scale-105 hover:shadow-md"
      }`}
      whileHover={{ 
        scale: isSelected ? 1 : 1.05,
        rotateZ: isSelected ? 0 : [0, -2, 2, 0]
      }}
      whileTap={{ scale: 0.95 }}
      animate={{
        x: wrongMoveShake && isSelected ? [-4, 4, -4, 4, 0] : 0,
        backgroundColor: isSelected ? ["#DBEAFE", "#93C5FD", "#DBEAFE"] : "#DBEAFE"
      }}
      transition={{
        x: { duration: 0.6 },
        backgroundColor: { duration: 1, repeat: isSelected ? Infinity : 0 }
      }}
    >
      {/* Sparkle effect for selected piece */}
      {isSelected && (
        <motion.div
          className="absolute inset-0 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: [0, 1, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <div className="absolute top-1 left-1 w-1 h-1 bg-yellow-400 rounded-full" />
          <div className="absolute top-3 right-2 w-1 h-1 bg-blue-400 rounded-full" />
          <div className="absolute bottom-2 left-3 w-1 h-1 bg-purple-400 rounded-full" />
        </motion.div>
      )}
      <motion.span 
        className="text-blue-700 relative z-10"
        animate={isSelected ? {
          scale: [1, 1.1, 1],
          color: ["#1D4ED8", "#3B82F6", "#1D4ED8"]
        } : {}}
        transition={{ duration: 0.8, repeat: isSelected ? Infinity : 0 }}
      >
        {piece.id + 1}
      </motion.span>
    </motion.button>
  );
});

PuzzlePiece.displayName = 'PuzzlePiece';

const PuzzleSlot = React.memo(({
  slotId,
  onPlace,
  piece,
  isTargeted,
}: {
  slotId: number;
  onPlace: (slotId: number) => void;
  piece?: any;
  isTargeted: boolean;
}) => {
  return (
    <motion.button
      onClick={() => onPlace(slotId)}
      className={`aspect-square rounded-2xl border-3 border-dashed transition-all ${
        piece
          ? "bg-green-100 border-green-500"
          : isTargeted
            ? "bg-orange-100 border-orange-500 border-solid animate-pulse"
            : "bg-gray-50 border-gray-300"
      }`}
      whileHover={{ scale: piece ? 1 : 1.02 }}
      whileTap={{ scale: 0.98 }}
      disabled={!!piece}
    >
      {piece ? (
        <div className="w-full h-full flex items-center justify-center">
          <CheckCircle className="w-8 h-8 text-green-500" />
        </div>
      ) : (
        <motion.div 
          className="w-full h-full flex items-center justify-center"
          whileHover={{ scale: 1.1 }}
          animate={isTargeted ? { 
            scale: [1, 1.1, 1],
            boxShadow: [
              "0 0 0 rgba(249, 115, 22, 0)",
              "0 0 20px rgba(249, 115, 22, 0.3)",
              "0 0 0 rgba(249, 115, 22, 0)"
            ]
          } : {}}
          transition={{ 
            scale: { duration: 0.6, repeat: isTargeted ? Infinity : 0 },
            boxShadow: { duration: 0.6, repeat: isTargeted ? Infinity : 0 }
          }}
        >
          <motion.span 
            className="text-gray-400 font-heading font-bold text-lg"
            animate={isTargeted ? {
              color: ["#9CA3AF", "#F97316", "#9CA3AF"],
              scale: [1, 1.2, 1]
            } : {}}
            transition={{ duration: 0.6, repeat: isTargeted ? Infinity : 0 }}
          >
            {slotId + 1}
          </motion.span>
        </motion.div>
      )}
    </motion.button>
  );
});

PuzzleSlot.displayName = 'PuzzleSlot';

export default function PuzzleGameScreen({
  navigateTo,
  addSticker,
}: PuzzleGameScreenProps) {
  const [selectedPuzzle, setSelectedPuzzle] =
    useState<any>(null);
  const [puzzlePieces, setPuzzlePieces] = useState<any[]>([]);
  const [completedPieces, setCompletedPieces] = useState<
    number[]
  >([]);
  const [gameCompleted, setGameCompleted] = useState(false);
  const [showHint, setShowHint] = useState(false);
  const [selectedPiece, setSelectedPiece] = useState<
    number | null
  >(null);
  const [celebrationParticles, setCelebrationParticles] = useState(false);
  const [wrongMoveShake, setWrongMoveShake] = useState(false);
  const [combo, setCombo] = useState(0);
  const [lastCorrectTime, setLastCorrectTime] = useState(0);

  const puzzles = [
    {
      id: 1,
      title: "Cute Fox",
      difficulty: "Easy",
      pieces: 6,
      image: "🦊",
      description: "Susun puzzle rubah lucu ini!",
      color: "bg-orange-100",
      borderColor: "border-orange-300",
    },
    {
      id: 2,
      title: "Happy Elephant",
      difficulty: "Easy",
      pieces: 9,
      image: "🐘",
      description: "Bentuk gajah yang bahagia!",
      color: "bg-gray-100",
      borderColor: "border-gray-300",
    },
    {
      id: 3,
      title: "Colorful Butterfly",
      difficulty: "Medium",
      pieces: 12,
      image: "🦋",
      description: "Kupu-kupu berwarna cantik!",
      color: "bg-purple-100",
      borderColor: "border-purple-300",
    },
    {
      id: 4,
      title: "Ocean Fish",
      difficulty: "Medium",
      pieces: 16,
      image: "🐠",
      description: "Ikan cantik di lautan biru!",
      color: "bg-blue-100",
      borderColor: "border-blue-300",
    },
  ];

  useEffect(() => {
    if (selectedPuzzle) {
      initializePuzzle();
    }
  }, [selectedPuzzle?.id]); // Only re-run when puzzle ID changes

  const initializePuzzle = useCallback(() => {
    if (!selectedPuzzle) return;

    const pieces = Array.from(
      { length: selectedPuzzle.pieces },
      (_, i) => ({
        id: i,
        correctPosition: i,
        currentPosition: i,
        placed: false,
        isInCorrectPosition: false,
      }),
    );

    // Shuffle pieces
    const shuffledPieces = [...pieces].sort(
      () => Math.random() - 0.5,
    );
    setPuzzlePieces(shuffledPieces);
    setCompletedPieces([]);
    setGameCompleted(false);
    setShowHint(false);
    setSelectedPiece(null); // Reset selected piece
    setCombo(0);
    setCelebrationParticles(false);
    setWrongMoveShake(false);
  }, [selectedPuzzle]);

  const handlePieceSelect = useCallback((pieceId: number) => {
    if (completedPieces.includes(pieceId)) return;
    setSelectedPiece(
      selectedPiece === pieceId ? null : pieceId,
    );
  }, [completedPieces, selectedPiece]);

  const handleSlotPlace = useCallback((slotId: number) => {
    if (!selectedPiece || !selectedPuzzle) return;

    const piece = puzzlePieces.find(
      (p) => p.id === selectedPiece,
    );
    if (!piece) return;

    // Check if this piece belongs to this slot
    if (piece.correctPosition === slotId) {
      // Calculate combo for quick consecutive correct placements
      const currentTime = Date.now();
      const timeSinceLastCorrect = currentTime - lastCorrectTime;
      if (timeSinceLastCorrect < 3000 && completedPieces.length > 0) {
        setCombo(combo + 1);
      } else {
        setCombo(1);
      }
      setLastCorrectTime(currentTime);
      
      // Trigger celebration particles for combo
      if (combo >= 2) {
        setCelebrationParticles(true);
        setTimeout(() => setCelebrationParticles(false), 1000);
      }
      const newPieces = puzzlePieces.map((p) =>
        p.id === selectedPiece
          ? {
              ...p,
              placed: true,
              isInCorrectPosition: true,
              currentPosition: slotId,
            }
          : p,
      );
      setPuzzlePieces(newPieces);

      const newCompletedPieces = [
        ...completedPieces,
        selectedPiece,
      ];
      setCompletedPieces(newCompletedPieces);
      setSelectedPiece(null);

      // Check if puzzle is completed
      if (newCompletedPieces.length === selectedPuzzle.pieces) {
        setGameCompleted(true);
        addSticker("puzzle-master");

        // Auto return to puzzle selection after 3 seconds
        setTimeout(() => {
          setSelectedPuzzle(null);
          setGameCompleted(false);
        }, 3000);
      }
    } else {
      // Wrong piece, give feedback with shake animation
      setWrongMoveShake(true);
      setCombo(0); // Reset combo on wrong move
      setTimeout(() => {
        setWrongMoveShake(false);
        setSelectedPiece(null);
      }, 600);
    }
  }, [selectedPiece, selectedPuzzle, puzzlePieces, completedPieces, addSticker, combo, lastCorrectTime]);

  const resetPuzzle = useCallback(() => {
    initializePuzzle();
  }, [initializePuzzle]);

  const getDifficultyColor = useCallback((difficulty: string) => {
    switch (difficulty) {
      case "Easy":
        return "bg-green-100 text-green-700";
      case "Medium":
        return "bg-yellow-100 text-yellow-700";
      case "Hard":
        return "bg-red-100 text-red-700";
      default:
        return "bg-gray-100 text-gray-700";
    }
  }, []);

  if (gameCompleted && selectedPuzzle) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center">
        <motion.div
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{
            type: "spring",
            stiffness: 200,
            damping: 15,
          }}
          className="bg-white rounded-3xl p-8 text-center max-w-sm mx-4 shadow-2xl"
        >
          <motion.div
            animate={{
              scale: [1, 1.2, 1],
              rotate: [0, 10, -10, 0],
            }}
            transition={{ duration: 0.8, repeat: 2 }}
            className="text-8xl mb-4"
          >
            🎉
          </motion.div>

          <h2 className="text-gray-900 font-heading font-bold text-2xl mb-2">
            Selamat! 🏆
          </h2>
          <p className="text-gray-600 font-body text-base mb-4">
            Kamu berhasil menyelesaikan puzzle{" "}
            {selectedPuzzle.title}!
          </p>

          <div className="bg-yellow-50 rounded-2xl p-4 mb-6">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <Trophy className="w-5 h-5 text-yellow-600" />
              <span className="text-yellow-700 font-body font-semibold">
                Hadiah Diperoleh!
              </span>
            </div>
            <p className="text-yellow-600 font-body text-sm">
              Stiker "Puzzle Master" ditambahkan ke koleksimu!
            </p>
          </div>

          <motion.button
            onClick={() => {
              setSelectedPuzzle(null);
              setGameCompleted(false);
            }}
            className="w-full bg-gradient-to-r from-blue-500 to-purple-500 text-white py-3 px-6 rounded-2xl font-heading font-bold shadow-lg"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            Main Lagi
          </motion.button>
        </motion.div>
      </div>
    );
  }

  if (selectedPuzzle) {
    return (
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-r from-blue-500 to-purple-600 px-6 pt-14 pb-6">
          <div className="flex items-center justify-between mb-4">
            <motion.button
              onClick={() => setSelectedPuzzle(null)}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </motion.button>
            <h1 className="text-white font-heading font-bold text-lg">
              {selectedPuzzle?.title || "Puzzle Game"}
            </h1>
            <motion.button
              onClick={() => setShowHint(!showHint)}
              className="p-2 rounded-xl bg-white/20"
              whileTap={{ scale: 0.95 }}
            >
              <Lightbulb
                className={`w-6 h-6 ${showHint ? "text-yellow-300" : "text-white"}`}
              />
            </motion.button>
          </div>

          {/* Progress */}
          {selectedPuzzle && (
            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-white font-body text-sm">
                  Progress {combo > 1 && `• Combo ${combo}x 🔥`}
                </span>
                <span className="text-white font-body font-semibold">
                  {completedPieces.length}/
                  {selectedPuzzle.pieces}
                </span>
              </div>
              <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden">
                <motion.div
                  className="h-2 bg-gradient-to-r from-white to-yellow-300 rounded-full"
                  initial={{ width: 0 }}
                  animate={{
                    width: `${(completedPieces.length / selectedPuzzle.pieces) * 100}%`,
                  }}
                  transition={{ duration: 0.5, type: "spring" }}
                />
              </div>
              {combo > 0 && (
                <motion.div 
                  className="text-center mt-2"
                  animate={{ scale: [1, 1.05, 1] }}
                  transition={{ duration: 0.8, repeat: combo > 1 ? Infinity : 0 }}
                >
                  <span className="text-yellow-300 font-heading font-bold text-xs">
                    {combo === 1 ? "Great start! 🌟" : `Amazing! Keep going! ⭐`}
                  </span>
                </motion.div>
              )}
            </div>
          )}
        </div>

        {/* Game Area */}
        <div className="px-6 py-8">
          {/* Combo Display */}
          {combo > 1 && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              className="bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-2xl p-4 mb-6 text-center"
            >
              <motion.div
                animate={{ 
                  scale: [1, 1.2, 1],
                  rotate: [0, 5, -5, 0]
                }}
                transition={{ duration: 0.6, repeat: Infinity }}
              >
                <h3 className="font-heading font-bold text-lg mb-1">
                  🔥 COMBO x{combo}!
                </h3>
                <p className="font-body text-sm">
                  Kamu lagi on fire! Lanjutkan!
                </p>
              </motion.div>
            </motion.div>
          )}

          {/* Wrong Move Feedback */}
          {wrongMoveShake && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="bg-red-100 border border-red-300 rounded-2xl p-4 mb-6"
            >
              <div className="flex items-center justify-center space-x-2">
                <span className="text-2xl">😅</span>
                <div className="text-center">
                  <h3 className="text-red-700 font-heading font-bold text-base">
                    Oops! Posisi Salah
                  </h3>
                  <p className="text-red-600 font-body text-sm">
                    Coba lagi ya! Kamu pasti bisa!
                  </p>
                </div>
              </div>
            </motion.div>
          )}

          {/* Celebration Particles */}
          {celebrationParticles && (
            <motion.div
              className="fixed inset-0 pointer-events-none z-50"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              {[...Array(8)].map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute w-4 h-4 bg-yellow-400 rounded-full"
                  initial={{ 
                    x: "50%", 
                    y: "50%",
                    scale: 0
                  }}
                  animate={{
                    x: `${50 + (Math.random() - 0.5) * 100}%`,
                    y: `${30 + (Math.random() - 0.5) * 40}%`,
                    scale: [0, 1, 0],
                    opacity: [0, 1, 0]
                  }}
                  transition={{
                    duration: 1,
                    delay: i * 0.1,
                    ease: "easeOut"
                  }}
                />
              ))}
            </motion.div>
          )}

          {/* Hint */}
          {showHint && selectedPuzzle && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-yellow-100 border border-yellow-300 rounded-2xl p-4 mb-6"
            >
              <div className="flex items-center space-x-2 mb-2">
                <Lightbulb className="w-5 h-5 text-yellow-600" />
                <span className="text-yellow-700 font-body font-semibold">
                  Hint
                </span>
              </div>
              <p className="text-yellow-700 font-body text-sm">
                Klik setiap bagian puzzle sesuai urutan yang
                benar untuk menyusun gambar{" "}
                {selectedPuzzle.title}!
              </p>
            </motion.div>
          )}

          {/* Preview Image */}
          {selectedPuzzle && (
            <div className="text-center mb-8">
              <div
                className={`inline-flex w-24 h-24 ${selectedPuzzle.color} rounded-3xl items-center justify-center border-3 ${selectedPuzzle.borderColor} shadow-lg`}
              >
                <span className="text-5xl">
                  {selectedPuzzle.image}
                </span>
              </div>
              <p className="text-gray-600 font-body text-sm mt-2">
                Gambar yang harus disusun
              </p>
            </div>
          )}

          {/* Instructions */}
          {selectedPuzzle && selectedPiece === null && (
            <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-6">
              <p className="text-blue-700 font-body text-sm text-center">
                🧩 Pilih potongan puzzle, lalu ketuk posisi yang
                tepat di area puzzle
              </p>
            </div>
          )}

          {selectedPiece !== null && (
            <div className="bg-orange-50 border border-orange-200 rounded-2xl p-4 mb-6">
              <p className="text-orange-700 font-body text-sm text-center">
                ✨ Potongan {selectedPiece + 1} dipilih! Ketuk
                posisi {selectedPiece + 1} di area puzzle
              </p>
            </div>
          )}

          {/* Puzzle Board */}
          {selectedPuzzle && (
            <div className="mb-8">
              <h3 className="text-gray-700 font-heading font-semibold text-base mb-4 text-center">
                Area Puzzle
              </h3>
              <div
                className={`grid gap-2 mb-6 mx-auto max-w-sm ${
                  selectedPuzzle.pieces <= 6
                    ? "grid-cols-2"
                    : selectedPuzzle.pieces <= 9
                      ? "grid-cols-3"
                      : selectedPuzzle.pieces <= 12
                        ? "grid-cols-3"
                        : "grid-cols-4"
                }`}
              >
                {Array.from(
                  { length: selectedPuzzle.pieces },
                  (_, slotIndex) => {
                    const placedPiece = puzzlePieces.find(
                      (p) =>
                        p.currentPosition === slotIndex &&
                        p.placed,
                    );
                    // Fix targeting logic: check if selected piece should go to this slot
                    const isTargeted =
                      selectedPiece !== null &&
                      puzzlePieces.find(
                        (p) => p.id === selectedPiece,
                      )?.correctPosition === slotIndex;

                    return (
                      <PuzzleSlot
                        key={`slot-${slotIndex}`}
                        slotId={slotIndex}
                        onPlace={handleSlotPlace}
                        piece={placedPiece}
                        isTargeted={isTargeted}
                      />
                    );
                  },
                )}
              </div>

              <h3 className="text-gray-700 font-heading font-semibold text-base mb-4 text-center">
                Potongan Puzzle
              </h3>
              <div className="flex flex-wrap gap-3 justify-center">
                {puzzlePieces
                  .filter((piece) => !piece.placed)
                  .map((piece) => (
                    <PuzzlePiece
                      key={`piece-${piece.id}`}
                      piece={piece}
                      onSelect={handlePieceSelect}
                      isSelected={selectedPiece === piece.id}
                      wrongMoveShake={wrongMoveShake}
                    />
                  ))}
              </div>
            </div>
          )}

          {/* Reset Button */}
          <div className="flex justify-center">
            <motion.button
              onClick={resetPuzzle}
              className="flex items-center space-x-2 bg-gray-200 hover:bg-gray-300 text-gray-700 px-6 py-3 rounded-2xl font-body font-semibold"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <RotateCcw className="w-5 h-5" />
              <span>Reset Puzzle</span>
            </motion.button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-500 to-purple-600 px-6 pt-14 pb-8">
        <div className="flex items-center justify-between mb-6">
          <motion.button
            onClick={() => navigateTo("game")}
            className="p-2 rounded-xl bg-white/20"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </motion.button>
          <h1 className="text-white font-heading font-bold text-xl">
            Puzzle Games
          </h1>
          <div className="w-10" />
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4"
        >
          <h2 className="text-white font-heading font-semibold text-lg mb-2">
            Pilih Puzzle Favoritmu! 🧩
          </h2>
          <p className="text-blue-100 font-body text-sm">
            Susun potongan-potongan untuk membuat gambar yang
            sempurna
          </p>
        </motion.div>
      </div>

      {/* Puzzle Selection */}
      <div className="px-6 -mt-4 pb-8">
        <div className="grid grid-cols-1 gap-4">
          {puzzles.map((puzzle, index) => (
            <motion.button
              key={`puzzle-${puzzle.id}`}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => setSelectedPuzzle(puzzle)}
              className={`bg-white rounded-2xl p-4 shadow-sm border border-gray-100 hover:shadow-lg hover:border-purple-200 transition-all`}
              whileHover={{ scale: 1.02, y: -2 }}
              whileTap={{ scale: 0.98 }}
            >
              <div className="flex items-center space-x-4">
                <div
                  className={`w-20 h-20 ${puzzle.color} rounded-2xl border-2 ${puzzle.borderColor} flex items-center justify-center`}
                >
                  <span className="text-4xl">
                    {puzzle.image}
                  </span>
                </div>

                <div className="flex-1 text-left">
                  <h3 className="text-gray-900 font-heading font-bold text-lg mb-1">
                    {puzzle.title}
                  </h3>
                  <p className="text-gray-600 font-body text-sm mb-3">
                    {puzzle.description}
                  </p>

                  <div className="flex items-center space-x-3">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-body font-medium ${getDifficultyColor(puzzle.difficulty)}`}
                    >
                      {puzzle.difficulty}
                    </span>
                    <span className="text-gray-500 text-xs font-body">
                      🧩 {puzzle.pieces} pieces
                    </span>
                  </div>
                </div>

                <div className="text-purple-500">
                  <span className="text-2xl">▶</span>
                </div>
              </div>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}