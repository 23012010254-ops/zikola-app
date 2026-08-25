import React, { useState } from 'react';
import { db, auth, googleProvider } from '../lib/firebase';
import { collection, query, where, getDocs, doc, setDoc } from 'firebase/firestore';
import { signInWithPopup } from 'firebase/auth';
import { ShieldCheck, Mail, Lock, Key, Eye, EyeOff, ArrowRight, Users } from 'lucide-react';
import zikolaLogoFull from '../assets/zikola_logo_full.jpg';
import zikolaMascot from '../assets/zikola_mascot.png';

interface DoctorLoginProps {
  onLogin: (doctorId: string) => void;
  onGoToRegister: (googleData?: { email?: string; name?: string; photoUrl?: string; googleUid?: string }) => void;
}

export default function DoctorLogin({ onLogin, onGoToRegister }: DoctorLoginProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);

  // Forgot Password States
  const [showReset, setShowReset] = useState(false);
  const [resetUsername, setResetUsername] = useState('');
  const [resetEmail, setResetEmail] = useState('');
  const [resetPin, setResetPin] = useState('');
  const [showResetPin, setShowResetPin] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [confirmNewPassword, setConfirmNewPassword] = useState('');
  const [resetSuccess, setResetSuccess] = useState(false);

  // Simple hash (same as register)
  const hashPassword = async (pwd: string): Promise<string> => {
    const encoder = new TextEncoder();
    const data = encoder.encode(pwd);
    const hash = await crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
  };

  const handleGoogleLogin = async () => {
    setIsLoading(true);
    setError(false);
    setErrorMessage('');

    try {
      const result = await signInWithPopup(auth, googleProvider);
      const emailVal = result.user.email;

      if (!emailVal) {
        throw new Error('Gagal mendapatkan email dari Google.');
      }

      // Query by email in doctor_credentials
      const credQuery = query(
        collection(db, 'doctor_credentials'),
        where('email', '==', emailVal.toLowerCase().trim())
      );
      const snapshot = await getDocs(credQuery);

      if (!snapshot.empty) {
        // Account exists -> Direct login
        const credData = snapshot.docs[0].data();
        const activeId = credData.doctorId || result.user.uid;
        localStorage.setItem('zikola_doctor_id', activeId);
        onLogin(activeId);
      } else {
        // Account does not exist -> Direct to Sign Up with Google prefill
        onGoToRegister({
          email: emailVal,
          name: result.user.displayName || '',
          photoUrl: result.user.photoURL || '',
          googleUid: result.user.uid
        });
      }
    } catch (err: any) {
      console.error('Google login error:', err);
      setError(true);
      setErrorMessage(err.message || 'Gagal login dengan Google.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(false);
    setErrorMessage('');

    try {
      const hashedPwd = await hashPassword(password);
      const credQuery = query(
        collection(db, 'doctor_credentials'),
        where('username', '==', username.toLowerCase().trim()),
        where('password', '==', hashedPwd)
      );
      const snapshot = await getDocs(credQuery);

      if (!snapshot.empty) {
        const credData = snapshot.docs[0].data();
        onLogin(credData.doctorId);
      } else {
        setError(true);
        setErrorMessage('Username atau password salah.');
        setTimeout(() => {
          setError(false);
          setErrorMessage('');
        }, 3000);
      }
    } catch (err) {
      console.error('Login error:', err);
      setError(true);
      setErrorMessage('Gagal terhubung ke server. Coba lagi.');
      setTimeout(() => {
        setError(false);
        setErrorMessage('');
      }, 3000);
    } finally {
      setIsLoading(false);
    }
  };

  const handleResetSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(false);
    setErrorMessage('');

    if (newPassword !== confirmNewPassword) {
      setError(true);
      setErrorMessage('Konfirmasi sandi tidak cocok.');
      setIsLoading(false);
      return;
    }

    if (newPassword.length < 6) {
      setError(true);
      setErrorMessage('Sandi baru minimal 6 karakter.');
      setIsLoading(false);
      return;
    }

    try {
      const hashedPin = await hashPassword(resetPin);
      // Find credentials by username, email, and securityPin
      const credQuery = query(
        collection(db, 'doctor_credentials'),
        where('username', '==', resetUsername.toLowerCase().trim()),
        where('email', '==', resetEmail.toLowerCase().trim()),
        where('securityPin', '==', hashedPin)
      );
      const snapshot = await getDocs(credQuery);

      if (!snapshot.empty) {
        // Hashing the new password
        const hashedPwd = await hashPassword(newPassword);
        const docRef = snapshot.docs[0].ref;
        
        // Update credentials doc
        await setDoc(docRef, { password: hashedPwd }, { merge: true });

        setResetSuccess(true);
        setError(false);
        setErrorMessage('');
        
        setTimeout(() => {
          setResetSuccess(false);
          setShowReset(false);
          // Clear forms
          setResetUsername('');
          setResetEmail('');
          setResetPin('');
          setNewPassword('');
          setConfirmNewPassword('');
        }, 3500);
      } else {
        setError(true);
        setErrorMessage('Username, Email, atau PIN Keamanan salah/tidak cocok.');
      }
    } catch (err) {
      console.error('Reset password error:', err);
      setError(true);
      setErrorMessage('Gagal memperbarui sandi. Coba lagi.');
    } finally {
      setIsLoading(false);
    }
  };

  const inputClass = (hasError: boolean) =>
    `w-full pl-11 pr-4 py-3 bg-white border rounded-xl outline-none transition-all duration-200 text-sm ${
      hasError ? 'border-red-400 bg-red-50/30' : 'border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-100 shadow-sm'
    }`;

  const inputClassWithRight = (hasError: boolean) =>
    `w-full pl-11 pr-11 py-3 bg-white border rounded-xl outline-none transition-all duration-200 text-sm ${
      hasError ? 'border-red-400 bg-red-50/30' : 'border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-100 shadow-sm'
    }`;

  const iconClass = (hasError: boolean) =>
    `absolute left-4 top-1/2 -translate-y-1/2 transition-colors duration-200 ${
      hasError ? 'text-red-400' : 'text-slate-400 group-focus-within:text-teal-500'
    }`;

  return (
    <div className="min-h-screen bg-white flex items-center justify-center p-4 md:p-8 font-sans">

      <div className="max-w-5xl w-full bg-white rounded-2xl shadow-[0_4px_24px_rgba(0,0,0,0.06)] border border-slate-100 overflow-hidden flex flex-col">
        
        {/* Main Content: Left & Right Grid */}
        <div className="flex flex-col md:flex-row">
          
          {/* Left Column: Branding Panel */}
          <div className="md:w-[44%] bg-gradient-to-b from-teal-50 to-white border-b md:border-b-0 md:border-r border-slate-100 p-6 sm:p-8 md:p-10 flex flex-col items-center justify-center text-center">
            {/* Mascot Hero */}
            <img 
              src={zikolaMascot} 
              alt="Zikola Mascot" 
              className="w-24 h-24 sm:w-36 sm:h-36 md:w-44 md:h-44 object-contain mb-3 md:mb-6" 
            />
            
            {/* Logo Text */}
            <img 
              src={zikolaLogoFull} 
              alt="Zikola" 
              className="h-8 md:h-10 object-contain mb-3 md:mb-4" 
            />
            
            {/* Tagline */}
            <p className="text-slate-500 text-xs sm:text-sm font-medium leading-relaxed max-w-[260px]">
              Platform konsultasi & asesmen tumbuh kembang anak untuk profesional.
            </p>

            {/* Badge */}
            <div className="mt-4 md:mt-6 inline-flex items-center space-x-2 bg-white border border-slate-100 rounded-full px-3.5 py-1.5 md:px-4 md:py-2 shadow-sm">
              <div className="w-2 h-2 bg-teal-500 rounded-full"></div>
              <span className="text-[11px] md:text-xs font-semibold text-slate-600">Portal Dokter & Psikolog</span>
            </div>
          </div>

          {/* Right Column: Form */}
          <div className="md:w-[56%] p-6 sm:p-8 md:p-10 flex flex-col justify-center">
            {showReset ? (
              // Reset Password Form
              <form onSubmit={handleResetSubmit} className="space-y-4">
                <div className="mb-4">
                  <h2 className="text-xl font-bold text-slate-800 tracking-tight">Atur Ulang Sandi</h2>
                  <p className="text-sm text-slate-500 mt-1">Verifikasi identitas untuk mengubah sandi</p>
                </div>

                {resetSuccess && (
                  <div className="bg-emerald-50 border border-emerald-100 text-emerald-800 p-3 rounded-xl text-xs font-semibold flex items-center space-x-2">
                    <span className="text-base">✅</span>
                    <div>
                      <p className="font-bold">Sandi Berhasil Diperbarui!</p>
                      <p className="text-emerald-600 font-medium mt-0.5">Mengalihkan ke halaman login...</p>
                    </div>
                  </div>
                )}

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-slate-600 ml-1">Username</label>
                  <div className="relative group">
                    <input type="text" value={resetUsername} onChange={(e) => setResetUsername(e.target.value)} placeholder="Masukkan username Anda" required className={inputClass(error)} />
                    <div className={iconClass(error)}><Mail size={16} /></div>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-slate-600 ml-1">Email Terdaftar</label>
                  <div className="relative group">
                    <input type="email" value={resetEmail} onChange={(e) => setResetEmail(e.target.value)} placeholder="dokter@rumahsakit.com" required className={inputClass(error)} />
                    <div className={iconClass(error)}><Mail size={16} /></div>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-slate-600 ml-1">PIN Keamanan (6 Digit)</label>
                  <div className="relative group">
                    <input type={showResetPin ? 'text' : 'password'} maxLength={6} pattern="\d*" value={resetPin} onChange={(e) => setResetPin(e.target.value.replace(/\D/g, ''))} placeholder="Masukkan 6 digit PIN" required className={inputClassWithRight(error)} />
                    <div className={iconClass(error)}><Lock size={16} /></div>
                    <button type="button" onClick={() => setShowResetPin(!showResetPin)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                      {showResetPin ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-slate-600 ml-1">Sandi Baru</label>
                  <div className="relative group">
                    <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="Minimal 6 karakter" required className={inputClass(error)} />
                    <div className={iconClass(error)}><Lock size={16} /></div>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-slate-600 ml-1">Konfirmasi Sandi Baru</label>
                  <div className="relative group">
                    <input type="password" value={confirmNewPassword} onChange={(e) => setConfirmNewPassword(e.target.value)} placeholder="Ulangi kata sandi" required className={inputClass(error)} />
                    <div className={iconClass(error)}><ShieldCheck size={16} /></div>
                  </div>
                  {error && (
                    <div className="flex items-center space-x-2 mt-1.5 ml-1 text-red-500">
                      <div className="w-1.5 h-1.5 bg-red-500 rounded-full"></div>
                      <p className="text-xs font-semibold">{errorMessage}</p>
                    </div>
                  )}
                </div>

                <div className="pt-3 flex flex-col space-y-2">
                  <button type="submit" disabled={isLoading || !resetUsername || !resetEmail || !resetPin || !newPassword || !confirmNewPassword}
                    className="w-full bg-teal-600 hover:bg-teal-700 text-white py-3 rounded-xl font-semibold text-sm flex items-center justify-center space-x-2 transition-all duration-200 active:scale-[0.98] disabled:opacity-50">
                    {isLoading ? (
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                    ) : (
                      <><Key size={15} /><span>Perbarui Sandi</span></>
                    )}
                  </button>
                  <button type="button" onClick={() => { setShowReset(false); setError(false); setErrorMessage(''); }}
                    className="w-full text-center text-xs font-semibold text-slate-500 hover:text-slate-700 py-2 transition-colors">
                    Batal, Kembali ke Login
                  </button>
                </div>
              </form>
            ) : (
              // Login Form
              <form onSubmit={handleSubmit} className="space-y-5">
                <div>
                  <h2 className="text-xl font-bold text-slate-800 tracking-tight">Masuk ke Portal</h2>
                  <p className="text-sm text-slate-500 mt-1">Akses dashboard profesional Anda</p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-semibold text-slate-600 ml-1">Email / Username</label>
                  <div className="relative group">
                    <input type="text" value={username} onChange={(e) => setUsername(e.target.value)} placeholder="Masukkan email atau username" required className={inputClass(error)} />
                    <div className={iconClass(error)}><Mail size={16} /></div>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <div className="flex justify-between items-center px-1">
                    <label className="text-xs font-semibold text-slate-600">Kata Sandi</label>
                    <button type="button" onClick={() => { setShowReset(true); setError(false); setErrorMessage(''); }}
                      className="text-xs font-semibold text-teal-600 hover:text-teal-800 transition-colors">
                      Lupa kata sandi?
                    </button>
                  </div>
                  <div className="relative group">
                    <input type={showPassword ? 'text' : 'password'} value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Masukkan kata sandi" required className={inputClassWithRight(error)} />
                    <div className={iconClass(error)}><Lock size={16} /></div>
                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                  {error && (
                    <div className="flex items-center space-x-2 mt-1.5 ml-1 text-red-500">
                      <div className="w-1.5 h-1.5 bg-red-500 rounded-full"></div>
                      <p className="text-xs font-semibold">{errorMessage || 'Autentikasi gagal. Periksa kembali akses Anda.'}</p>
                    </div>
                  )}
                </div>

                {/* Remember Me */}
                <div className="flex items-center space-x-2 ml-1">
                  <input type="checkbox" id="rememberMe" checked={rememberMe} onChange={(e) => setRememberMe(e.target.checked)}
                    className="w-4 h-4 text-teal-600 border-slate-300 rounded focus:ring-teal-500" />
                  <label htmlFor="rememberMe" className="text-xs font-semibold text-slate-600 select-none cursor-pointer">Ingat saya</label>
                </div>

                <div>
                  <button type="submit" disabled={isLoading || !username || !password}
                    className="w-full bg-teal-600 hover:bg-teal-700 text-white py-3 rounded-xl font-semibold text-sm flex items-center justify-center space-x-2 shadow-sm transition-all duration-200 active:scale-[0.98] disabled:opacity-50">
                    {isLoading ? (
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                    ) : (
                      <><span>Masuk</span><ArrowRight size={15} /></>
                    )}
                  </button>
                </div>

                {/* Social Login Separator */}
                <div className="relative flex items-center">
                  <div className="flex-grow border-t border-slate-100"></div>
                  <span className="flex-shrink mx-4 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">atau</span>
                  <div className="flex-grow border-t border-slate-100"></div>
                </div>

                {/* Google Login Only */}
                <button type="button" onClick={handleGoogleLogin} disabled={isLoading}
                  className="w-full flex items-center justify-center space-x-2 py-3 border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors duration-200 text-sm font-semibold text-slate-700 disabled:opacity-50">
                  <svg className="w-4 h-4" viewBox="0 0 24 24">
                    <path fill="#EA4335" d="M12.24 10.285V14.4h6.887c-.648 2.41-2.519 4.114-5.136 4.114-3.535 0-6.403-2.868-6.403-6.403s2.868-6.403 6.403-6.403c1.554 0 2.975.556 4.09 1.488l3.143-3.143C19.167 2.193 15.93 1 12.24 1 6.033 1 1 6.033 1 12.24s5.033 11.24 11.24 11.24c6.48 0 11.24-4.76 11.24-11.24 0-.796-.08-1.57-.22-2.285H12.24z"/>
                  </svg>
                  <span>Masuk dengan Google</span>
                </button>

                {/* Footer */}
                <div className="text-center pt-1">
                  <p className="text-sm text-slate-500">
                    Belum punya akun?{' '}
                    <button type="button" onClick={onGoToRegister} className="font-semibold text-teal-600 hover:text-teal-800 transition-colors">
                      Daftar sebagai psikolog
                    </button>
                  </p>
                </div>
              </form>
            )}
          </div>
        </div>

        {/* Bottom Bar: Features */}
        <div className="border-t border-slate-100 bg-slate-50/50 px-8 py-5 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="flex items-center space-x-3">
            <div className="p-2.5 bg-teal-50 text-teal-600 rounded-xl">
              <ShieldCheck size={18} />
            </div>
            <div>
              <p className="text-sm font-semibold text-slate-700">Data Aman & Terenkripsi</p>
              <p className="text-xs text-slate-500">Perlindungan data pasien berlapis</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="p-2.5 bg-teal-50 text-teal-600 rounded-xl">
              <Users size={18} />
            </div>
            <div>
              <p className="text-sm font-semibold text-slate-700">Untuk Profesional</p>
              <p className="text-xs text-slate-500">Dirancang khusus untuk psikolog & dokter anak</p>
            </div>
          </div>
        </div>
        
      </div>
    </div>
  );
}
