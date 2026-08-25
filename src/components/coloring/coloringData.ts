export const coloringImages = [
  {
    id: 1,
    title: 'Cute Fox',
    category: 'Animals',
    difficulty: 'Easy',
    areas: 8,
    preview: '🦊',
    description: 'Warnai rubah lucu dengan warna favoritmu!'
  },
  {
    id: 2,
    title: 'Happy Elephant',
    category: 'Animals',
    difficulty: 'Easy',
    areas: 6,
    preview: '🐘',
    description: 'Beri warna pada gajah yang bahagia!'
  },
  {
    id: 3,
    title: 'Magical Unicorn',
    category: 'Fantasy',
    difficulty: 'Medium',
    areas: 12,
    preview: '🦄',
    description: 'Warnai unicorn ajaib dengan warna pelangi!'
  },
  {
    id: 4,
    title: 'Little Kelinci',
    category: 'Animals',
    difficulty: 'Easy',
    areas: 7,
    preview: '🐰',
    description: 'Kelinci imut siap untuk diwarnai!'
  },
  {
    id: 5,
    title: 'Dinosaur Friend',
    category: 'Dinosaurs',
    difficulty: 'Medium',
    areas: 10,
    preview: '🦕',
    description: 'Dinosaur ramah menanti sentuhan warnamu!'
  },
  {
    id: 6,
    title: 'Bunny Family',
    category: 'Animals',
    difficulty: 'Hard',
    areas: 15,
    preview: '🐇',
    description: 'Keluarga kelinci yang menggemaskan!'
  }
];

export const colors = [
  { name: 'Blue', value: '#3B82F6' },
  { name: 'Red', value: '#EF4444' },
  { name: 'Green', value: '#22C55E' },
  { name: 'Yellow', value: '#F59E0B' },
  { name: 'Purple', value: '#8B5CF6' },
  { name: 'Pink', value: '#EC4899' },
  { name: 'Orange', value: '#F97316' },
  { name: 'Teal', value: '#14B8A6' },
  { name: 'Brown', value: '#A16207' },
  { name: 'Gray', value: '#6B7280' },
  { name: 'Black', value: '#1F2937' },
  { name: 'White', value: '#F9FAFB' }
];

export const getDifficultyColor = (difficulty: string) => {
  switch (difficulty) {
    case 'Easy': return 'bg-green-100 text-green-700';
    case 'Medium': return 'bg-yellow-100 text-yellow-700';
    case 'Hard': return 'bg-red-100 text-red-700';
    default: return 'bg-gray-100 text-gray-700';
  }
};