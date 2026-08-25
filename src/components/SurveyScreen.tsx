import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, ArrowRight, Check, SkipForward } from 'lucide-react';

interface SurveyScreenProps {
  navigateTo: (screen: string) => void;
  childName: string;
  setChildName: (name: string) => void;
  childGender: string;
  setChildGender: (gender: string) => void;
  childAge: number;
  setChildAge: (age: number) => void;
  surveyData: any;
  updateSurveyData: (data: any) => void;
}

export default function SurveyScreen({ 
  navigateTo, 
  childName, 
  setChildName, 
  childGender, 
  setChildGender, 
  childAge, 
  setChildAge,
  surveyData,
  updateSurveyData 
}: SurveyScreenProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [tempAnswers, setTempAnswers] = useState<{ [key: string]: any }>({});

  const surveySteps = [
    {
      id: 'gender-name',
      title: 'Apa gender dan siapa nama anak anda?',
      type: 'gender-name'
    },
    {
      id: 'age',
      title: 'Berapa umur anak Anda?',
      type: 'age-selection'
    },
    {
      id: 'personality',
      title: 'Capaian apa yang Anda inginkan terhadap anak Anda?',
      type: 'multiple-choice',
      options: [
        'Kemampuan akademik yang baik',
        'Keterampilan sosial dan emosional',
        'Kreativitas dan inovasi',
        'Kepercayaan diri tinggi',
        'Kemampuan problem solving',
        'Komunikasi yang efektif',
        'Kemandirian dalam belajar',
        'Lainnya'
      ]
    },
    {
      id: 'activities',
      title: 'Siapa yang sering menggunakan perangkat anak?',
      type: 'multiple-choice',
      options: [
        'Anak sendiri',
        'Orang tua',
        'Menggunakan bersama',
        'Pengasuh',
        'Saudara',
        'Lainnya'
      ]
    },
    {
      id: 'interests1',
      title: 'Apa harapan Anda kepada anak Anda?',
      type: 'multiple-choice',
      options: [
        'Tumbuh menjadi anak yang bahagia',
        'Memiliki kepercayaan diri yang tinggi',
        'Berhasil secara akademik',
        'Memiliki banyak teman dan mudah bergaul',
        'Kreatif dan inovatif dalam berpikir',
        'Mandiri dan bertanggung jawab',
        'Sehat fisik dan mental',
        'Memiliki karakter yang baik'
      ]
    },
    {
      id: 'interests2',
      title: 'Kegiatan apa yang paling disukai anak Anda?',
      type: 'multiple-choice',
      options: [
        'Menyanyi dan bercerita',
        'Mencari tahu hal baru',
        'Mendengarkan cerita',
        'Bermain dengan teman',
        'Menggambar dan mewarnai',
        'Bermain dengan mainan',
        'Belajar hal baru',
        'Lainnya'
      ]
    },
    {
      id: 'learning-difficulty',
      title: 'Apakah Anak Mengalami Kesulitan Dalam Belajar?',
      type: 'multiple-choice',
      options: [
        'Tidak ada kesulitan khusus',
        'Kesulitan konsentrasi',
        'Kesulitan memahami instruksi',
        'Kesulitan mengingat informasi',
        'Kesulitan dengan angka/matematika',
        'Kesulitan dengan huruf/membaca',
        'Kesulitan dengan motorik halus',
        'Lainnya'
      ]
    },
    {
      id: 'learning-method',
      title: 'Bagaimana metode belajar terbaik untuk anak Anda?',
      type: 'multiple-choice',
      options: [
        'Belajar sambil bermain',
        'Menggunakan gambar dan visual',
        'Mendengarkan musik dan lagu',
        'Praktek langsung dengan tangan',
        'Bercerita dan diskusi',
        'Menggunakan teknologi digital',
        'Lainnya'
      ]
    }
  ];

  const handleNext = () => {
    if (currentStep < surveySteps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      // Complete survey
      updateSurveyData(tempAnswers);
      navigateTo('home');
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSkip = () => {
    // Set default values and skip to home
    if (!childName || childName.trim().length === 0) {
      setChildName('Anak');
    }
    if (!childGender) {
      setChildGender('male');
    }
    if (childAge < 3) {
      setChildAge(6);
    }
    
    // Set default survey data
    const defaultSurveyData = {
      personality: ['Pintar'],
      activities: ['Anak sendiri'],
      learningStyle: ['Bermain sambil belajar'],
      interests: ['Bermain game edukatif'],
      hobbies: ['Belajar hal baru']
    };
    
    updateSurveyData(defaultSurveyData);
    navigateTo('home');
  };

  const handleAnswer = (questionId: string, answer: any) => {
    setTempAnswers({ ...tempAnswers, [questionId]: answer });
  };

  const handleMultipleAnswer = (questionId: string, option: string) => {
    const currentAnswers = tempAnswers[questionId] || [];
    const newAnswers = currentAnswers.includes(option)
      ? currentAnswers.filter((a: string) => a !== option)
      : [...currentAnswers, option];
    
    setTempAnswers({ ...tempAnswers, [questionId]: newAnswers });
  };

  const currentStepData = surveySteps[currentStep];
  const progress = ((currentStep + 1) / surveySteps.length) * 100;

  const canProceed = () => {
    switch (currentStepData.id) {
      case 'gender-name':
        return childName.trim().length > 0;
      case 'age':
        return childAge >= 3;
      default:
        return tempAnswers[currentStepData.id]?.length > 0;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white px-6 pt-14 pb-4">
        <div className="flex items-center justify-between mb-4">
          {currentStep > 0 ? (
            <motion.button
              onClick={handleBack}
              className="p-2 rounded-xl bg-gray-100"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-6 h-6 text-gray-600" />
            </motion.button>
          ) : (
            <div className="w-10" />
          )}
          
          <div className="text-center">
            <span className="text-sm font-body text-gray-500">
              {currentStep + 1} dari {surveySteps.length}
            </span>
          </div>
          
          {/* Skip Button - Only on first page */}
          {currentStep === 0 ? (
            <motion.button
              onClick={handleSkip}
              className="p-2 rounded-xl bg-blue-100 hover:bg-blue-200 transition-colors"
              whileTap={{ scale: 0.95 }}
              title="Lewati Survei"
            >
              <SkipForward className="w-6 h-6 text-blue-600" />
            </motion.button>
          ) : (
            <div className="w-10" />
          )}
        </div>

        {/* Progress Bar */}
        <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
          <motion.div
            className="h-2 bg-orange-500 rounded-full"
            initial={{ width: 0 }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
      </div>

      <div className="px-6 py-8 pb-32">
        {/* Question */}
        <motion.div
          key={currentStep}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -50 }}
          transition={{ duration: 0.3 }}
        >
          <h2 className="text-gray-900 font-heading font-bold text-xl mb-8 leading-tight">
            {currentStepData.title}
          </h2>

          {/* Gender and Name Selection */}
          {currentStepData.type === 'gender-name' && (
            <div className="space-y-6">
              {/* Gender Selection */}
              <div className="grid grid-cols-2 gap-4">
                {['male', 'female'].map((gender) => (
                  <motion.button
                    key={gender}
                    onClick={() => setChildGender(gender)}
                    className={`p-6 rounded-3xl border-3 transition-all ${
                      childGender === gender
                        ? 'border-orange-500 bg-orange-50'
                        : 'border-gray-200 bg-white hover:border-gray-300'
                    }`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <div className="text-center">
                      <div className="text-6xl mb-4">
                        {gender === 'male' ? '👦' : '👧'}
                      </div>
                      <div className="text-gray-900 font-body font-semibold">
                        {gender === 'male' ? 'Laki-laki' : 'Perempuan'}
                      </div>
                    </div>
                  </motion.button>
                ))}
              </div>

              {/* Name Input */}
              <div>
                <label className="block text-gray-700 font-body font-medium mb-3">
                  Nama Anak
                </label>
                <input
                  type="text"
                  value={childName}
                  onChange={(e) => setChildName(e.target.value)}
                  placeholder="Masukkan nama anak..."
                  className="w-full p-4 border-2 border-gray-200 rounded-2xl font-body text-lg focus:border-orange-500 focus:outline-none transition-colors"
                />
              </div>
            </div>
          )}

          {/* Age Selection */}
          {currentStepData.type === 'age-selection' && (
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: '3-4 Tahun', value: 3 },
                { label: '4-5 Tahun', value: 4 },
                { label: '5-6 Tahun', value: 5 },
                { label: '6-7 Tahun', value: 6 },
                { label: '7-8 Tahun', value: 7 },
                { label: '8-9 Tahun', value: 8 },
                { label: '9-10 Tahun', value: 9 },
                { label: '11-12 Tahun', value: 11 }
              ].map((age, ageIndex) => (
                <motion.button
                  key={`age-${age.label}-${ageIndex}`}
                  onClick={() => setChildAge(age.value)}
                  className={`p-4 rounded-2xl border-2 transition-all text-center ${
                    childAge === age.value
                      ? 'border-orange-500 bg-orange-50 text-orange-700'
                      : 'border-gray-200 bg-white hover:border-gray-300 text-gray-700'
                  }`}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  <span className="font-body font-medium">{age.label}</span>
                </motion.button>
              ))}
            </div>
          )}

          {/* Multiple Choice */}
          {currentStepData.type === 'multiple-choice' && (
            <div className="space-y-3">
              {currentStepData.options?.map((option, index) => {
                const isSelected = tempAnswers[currentStepData.id]?.includes(option);
                // Create unique key using step id, option text, and index
                const uniqueKey = `${currentStepData.id}-option-${index}-${option.replace(/\s+/g, '-').toLowerCase()}`;
                
                return (
                  <motion.button
                    key={uniqueKey}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                    onClick={() => handleMultipleAnswer(currentStepData.id, option)}
                    className={`w-full p-4 rounded-2xl border-2 text-left transition-all ${
                      isSelected
                        ? 'border-orange-500 bg-orange-50'
                        : 'border-gray-200 bg-white hover:border-gray-300'
                    }`}
                    whileHover={{ scale: 1.01 }}
                    whileTap={{ scale: 0.99 }}
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-body text-gray-900 leading-relaxed">
                        {option}
                      </span>
                      {isSelected && (
                        <div className="w-6 h-6 bg-orange-500 rounded-full flex items-center justify-center">
                          <Check className="w-4 h-4 text-white" />
                        </div>
                      )}
                    </div>
                  </motion.button>
                );
              })}
            </div>
          )}


        </motion.div>
      </div>

      {/* Bottom Action Area */}
      <div className="fixed bottom-0 left-1/2 transform -translate-x-1/2 w-full max-w-md bg-white border-t border-gray-100 p-6 space-y-3">
        {/* Skip All Button - Only on first page */}
        {currentStep === 0 && (
          <motion.button
            onClick={handleSkip}
            className="w-full py-3 px-6 rounded-2xl font-body font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 transition-all"
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
          >
            <div className="flex items-center justify-center space-x-2">
              <SkipForward className="w-4 h-4" />
              <span>Lewati Semua & Mulai</span>
            </div>
          </motion.button>
        )}

        {/* Next Button */}
        <motion.button
          onClick={handleNext}
          disabled={!canProceed()}
          className={`w-full py-4 px-6 rounded-2xl font-heading font-bold text-lg transition-all ${
            canProceed()
              ? 'bg-orange-500 hover:bg-orange-600 text-white shadow-lg active:scale-95'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
          whileHover={canProceed() ? { scale: 1.02 } : {}}
          whileTap={canProceed() ? { scale: 0.98 } : {}}
        >
          <div className="flex items-center justify-center space-x-2">
            <span>{currentStep === surveySteps.length - 1 ? 'Selesai' : 'Next'}</span>
            <ArrowRight className="w-5 h-5" />
          </div>
        </motion.button>
      </div>
    </div>
  );
}