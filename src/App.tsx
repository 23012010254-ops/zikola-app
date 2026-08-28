import PrivacyPolicy from './components/PrivacyPolicy';
import DeleteAccountRequest from './components/DeleteAccountRequest';
import React, { useState, useEffect, Component, ErrorInfo, ReactNode } from 'react';
import DoctorDashboard from './components/DoctorDashboard';
import DoctorLogin from './components/DoctorLogin';
import DoctorRegister from './components/DoctorRegister';
import { auth, db } from './lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { collection, query, where, getDocs } from 'firebase/firestore';

interface ErrorBoundaryProps {
  children: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Zikola App Error Caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-6 text-center font-sans">
          <div className="w-16 h-16 bg-teal-50 text-teal-600 rounded-3xl flex items-center justify-center text-3xl mb-4 shadow-sm">
            🩺
          </div>
          <h2 className="text-xl font-black text-slate-800">Memulihkan Sesi Portal Zikola</h2>
          <p className="text-xs text-slate-500 max-w-sm mt-2 font-medium">
            Terjadi pembaruan data sesi. Klik tombol di bawah untuk memuat ulang dasbor secara aman.
          </p>
          <div className="flex space-x-3 mt-6">
            <button
              onClick={() => {
                localStorage.removeItem('zikola_doctor_id');
                window.location.reload();
              }}
              className="px-5 py-2.5 bg-slate-200 text-slate-700 text-xs font-bold rounded-xl hover:bg-slate-300 transition-colors"
            >
              Halaman Login
            </button>
            <button
              onClick={() => {
                this.setState({ hasError: false, error: null });
                window.location.reload();
              }}
              className="px-5 py-2.5 bg-teal-600 text-white text-xs font-bold rounded-xl hover:bg-teal-700 shadow-md transition-colors"
            >
              Muat Ulang
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

type ViewType = 'login' | 'register' | 'dashboard';

export interface GoogleInitialData {
  email?: string;
  name?: string;
  photoUrl?: string;
  googleUid?: string;
}

function App() {
  const [currentView, setCurrentView] = useState<ViewType>(() => {
    const savedId = localStorage.getItem('zikola_doctor_id');
    return (savedId && savedId !== 'null' && savedId !== 'undefined' && savedId.trim() !== '') ? 'dashboard' : 'login';
  });
  const [doctorId, setDoctorId] = useState<string | null>(() => {
    const savedId = localStorage.getItem('zikola_doctor_id');
    return (savedId && savedId !== 'null' && savedId !== 'undefined' && savedId.trim() !== '') ? savedId : null;
  });
  const [googleInitialData, setGoogleInitialData] = useState<GoogleInitialData | null>(null);
  const [showSuccessMessage, setShowSuccessMessage] = useState(false);

  // Restore session from localStorage or Firebase Auth on mount
  useEffect(() => {
    const savedId = localStorage.getItem('zikola_doctor_id');
    if (savedId && savedId !== 'null' && savedId !== 'undefined' && savedId.trim() !== '') {
      setDoctorId(savedId);
      setCurrentView('dashboard');
    }

    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user && user.email) {
        const savedDoctorId = localStorage.getItem('zikola_doctor_id');
        if (!savedDoctorId) {
          try {
            const credQuery = query(
              collection(db, 'doctor_credentials'),
              where('email', '==', user.email.toLowerCase().trim())
            );
            const snapshot = await getDocs(credQuery);
            if (!snapshot.empty) {
              const credData = snapshot.docs[0].data();
              const activeId = credData.doctorId || user.uid;
              localStorage.setItem('zikola_doctor_id', activeId);
              setDoctorId(activeId);
              setCurrentView('dashboard');
            }
          } catch (e) {
            console.error('Error verifying auth state:', e);
          }
        }
      }
    });

    return () => unsubscribe();
  }, []);

  const handleLogin = (id: string) => {
    const validId = id || 'doctor_rani';
    localStorage.setItem('zikola_doctor_id', validId);
    setDoctorId(validId);
    setCurrentView('dashboard');
  };

  const handleLogout = () => {
    localStorage.removeItem('zikola_doctor_id');
    auth.signOut().catch(() => {});
    setDoctorId(null);
    setGoogleInitialData(null);
    setCurrentView('login');
  };

  const handleGoToRegister = (googleData?: GoogleInitialData) => {
    if (googleData) {
      setGoogleInitialData(googleData);
    }
    setCurrentView('register');
  };

  const handleRegisterSuccess = (id: string) => {
    const validId = id || 'doctor_rani';
    localStorage.setItem('zikola_doctor_id', validId);
    setDoctorId(validId);
    setShowSuccessMessage(true);
    setCurrentView('dashboard');
    setTimeout(() => setShowSuccessMessage(false), 5000);
  };

  // Route checks for Google Play Policy Pages
  const path = window.location.pathname.toLowerCase();
  if (path === '/privacy' || path === '/privacy-policy') {
    return <PrivacyPolicy />;
  }
  if (path === '/delete-account' || path === '/delete-data') {
    return <DeleteAccountRequest />;
  }

  if (currentView === 'register') {
    return (
      <ErrorBoundary>
        <DoctorRegister
          initialData={googleInitialData}
          onBack={() => {
            setGoogleInitialData(null);
            setCurrentView('login');
          }}
          onRegisterSuccess={handleRegisterSuccess}
        />
      </ErrorBoundary>
    );
  }

  if (currentView === 'dashboard') {
    const activeDoctorId = doctorId || localStorage.getItem('zikola_doctor_id') || 'doctor_rani';
    return (
      <ErrorBoundary>
        <div className="w-full h-screen">
          <DoctorDashboard currentDoctorId={activeDoctorId} onLogout={handleLogout} />
        </div>
      </ErrorBoundary>
    );
  }

  return (
    <ErrorBoundary>
      {/* Success Registration Banner */}
      {showSuccessMessage && (
        <div className="fixed top-0 left-0 right-0 z-[200] flex justify-center animate-in slide-in-from-top-5 duration-500">
          <div className="mt-4 bg-gradient-to-r from-emerald-500 to-green-600 text-white px-8 py-4 rounded-2xl shadow-2xl shadow-emerald-200 flex items-center space-x-3 font-bold text-sm">
            <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">✅</div>
            <div>
              <p className="font-black">Pendaftaran Berhasil!</p>
              <p className="text-emerald-100 text-xs font-medium mt-0.5">Akun dokter Anda telah aktif dan tersinkronisasi.</p>
            </div>
          </div>
        </div>
      )}
      <DoctorLogin
        onLogin={handleLogin}
        onGoToRegister={handleGoToRegister}
      />
    </ErrorBoundary>
  );
}

export default App;
