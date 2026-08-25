import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Eye, EyeOff } from 'lucide-react';
import zikolaMascot from '../assets/zikola_mascot.png';
import zikolaLogoFull from '../assets/zikola_logo_full.jpg';

interface LoginScreenProps {
  navigateTo: (screen: string) => void;
}

export default function LoginScreen({ navigateTo }: LoginScreenProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = () => {
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      navigateTo('survey');
    }, 1500);
  };

  const handleGoogleLogin = () => {
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      navigateTo('survey');
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-8 py-12">
      <div className="w-full max-w-sm mx-auto flex-1 flex flex-col justify-center">
        {/* Zikola Mascot & Logo */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8 }}
          className="text-center mb-8 flex flex-col items-center"
        >
          <motion.img
            src={zikolaMascot}
            alt="Zikola Mascot"
            className="w-36 h-36 object-contain mb-3"
            animate={{
              y: [-3, 3, -3],
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
          <img
            src={zikolaLogoFull}
            alt="Zikola"
            className="h-9 object-contain"
          />
        </motion.div>

        {/* Login Form */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, duration: 0.8 }}
          className="space-y-5"
        >
          {/* Email Input */}
          <div>
            <input
              type="text"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Email atau nomor ponsel"
              className="w-full px-4 py-3.5 bg-slate-50 border border-slate-200 rounded-2xl font-body text-sm text-slate-800 placeholder-slate-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-teal-500 transition-all shadow-sm"
            />
          </div>

          {/* Password Input */}
          <div className="relative">
            <input
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Kata sandi"
              className="w-full px-4 py-3.5 bg-slate-50 border border-slate-200 rounded-2xl font-body text-sm text-slate-800 placeholder-slate-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-teal-500 transition-all pr-12 shadow-sm"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 transform -translate-y-1/2 text-slate-400 hover:text-slate-600 focus:outline-none"
            >
              {showPassword ? (
                <EyeOff className="w-5 h-5" />
              ) : (
                <Eye className="w-5 h-5" />
              )}
            </button>
          </div>

          {/* Remember Me and Forgot Password */}
          <div className="flex items-center justify-between text-xs">
            <label className="flex items-center space-x-2 cursor-pointer">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="w-4 h-4 text-teal-600 border-slate-300 rounded focus:ring-teal-500"
              />
              <span className="text-slate-600 font-medium font-body">Ingat saya</span>
            </label>
            <button
              type="button"
              className="text-teal-600 hover:text-teal-800 font-medium font-body transition-colors"
            >
              Lupa sandi?
            </button>
          </div>

          {/* Login Button */}
          <motion.button
            onClick={handleLogin}
            disabled={isLoading || !email || !password}
            className="w-full bg-teal-600 hover:bg-teal-700 text-white font-semibold py-3.5 rounded-2xl shadow-sm transition-all disabled:opacity-50 text-sm"
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
          >
            {isLoading ? (
              <div className="flex items-center justify-center space-x-2">
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                <span>Masuk...</span>
              </div>
            ) : (
              'Masuk'
            )}
          </motion.button>

          {/* Divider */}
          <div className="relative my-4">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-slate-200" />
            </div>
            <div className="relative flex justify-center text-xs">
              <span className="px-4 bg-white text-slate-400 font-medium font-body">
                atau
              </span>
            </div>
          </div>

          {/* Google Sign In Button */}
          <motion.button
            onClick={handleGoogleLogin}
            disabled={isLoading}
            className="w-full bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 font-semibold py-3.5 rounded-2xl shadow-sm flex items-center justify-center space-x-3 transition-all text-sm"
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              />
            </svg>
            <span className="font-medium font-body">Masuk dengan Google</span>
          </motion.button>
        </motion.div>

        {/* Register Link */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6, duration: 0.8 }}
          className="text-center mt-6"
        >
          <p className="text-slate-500 font-body text-xs">
            Belum punya akun?{' '}
            <button
              onClick={() => navigateTo('survey')}
              className="text-teal-600 hover:text-teal-800 font-semibold transition-colors"
            >
              Daftar disini
            </button>
          </p>
        </motion.div>
      </div>
    </div>
  );
}