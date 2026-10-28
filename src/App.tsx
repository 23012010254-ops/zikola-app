import PrivacyPolicy from './components/PrivacyPolicy';
import DeleteAccountRequest from './components/DeleteAccountRequest';
import React, { useState, useEffect, Component, ErrorInfo, ReactNode } from 'react';
import DoctorDashboard from './components/DoctorDashboard';
import DoctorLogin from './components/DoctorLogin';
import DoctorRegister from './components/DoctorRegister';
import { auth, db } from './lib/firebase';
import { onAuthStateChanged, User } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';

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
                auth.signOut().finally(() => window.location.reload());
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

type ViewType = 'loading' | 'login' | 'register' | 'pending' | 'dashboard';

export interface GoogleInitialData {
  email?: string;
  name?: string;
  photoUrl?: string;
}

// Session comes only from Firebase Auth. The doctor role comes from
// doctor_accounts/{uid}; `verified` can only be set by an admin.
function App() {
  const [currentView, setCurrentView] = useState<ViewType>('loading');
  const [doctorId, setDoctorId] = useState<string | null>(null);
  const [googleInitialData, setGoogleInitialData] = useState<GoogleInitialData | null>(null);
  const [showSuccessMessage, setShowSuccessMessage] = useState(false);
  const [accountError, setAccountError] = useState('');

  const resolveAccount = async (user: User | null) => {
    setAccountError('');
    if (!user) {
      setDoctorId(null);
      setCurrentView(view => (view === 'register' ? 'register' : 'login'));
      return;
    }
    try {
      const snap = await getDoc(doc(db, 'doctor_accounts', user.uid));
      if (!snap.exists()) {
        // Signed in (e.g. Google) but never registered as a doctor.
        setGoogleInitialData({
          email: user.email || '',
          name: user.displayName || '',
          photoUrl: user.photoURL || '',
        });
        setCurrentView('register');
        return;
      }
      const data = snap.data();
      if (data.verified === true) {
        setDoctorId(data.doctorId || user.uid);
        setCurrentView('dashboard');
      } else {
        setCurrentView('pending');
      }
    } catch (e) {
      console.error('Error verifying doctor account:', e);
      setAccountError('Gagal memeriksa status akun. Coba muat ulang halaman.');
      setCurrentView('login');
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, resolveAccount);
    return () => unsubscribe();
  }, []);

  const handleLogout = () => {
    auth.signOut().catch(() => {});
    setDoctorId(null);
    setGoogleInitialData(null);
    setCurrentView('login');
  };

  const handleGoToRegister = () => {
    setCurrentView('register');
  };

  const handleRegisterSuccess = () => {
    setShowSuccessMessage(true);
    setTimeout(() => setShowSuccessMessage(false), 5000);
    resolveAccount(auth.currentUser);
  };

  // Route checks for Google Play Policy Pages
  const path = window.location.pathname.toLowerCase();
  if (path === '/privacy' || path === '/privacy-policy') {
    return <PrivacyPolicy />;
  }
  if (path === '/delete-account' || path === '/delete-data') {
    return <DeleteAccountRequest />;
  }

  if (currentView === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="w-8 h-8 border-4 border-teal-100 border-t-teal-600 rounded-full animate-spin"></div>
      </div>
    );
  }

  if (currentView === 'register') {
    return (
      <ErrorBoundary>
        <DoctorRegister
          initialData={googleInitialData}
          onBack={() => {
            setGoogleInitialData(null);
            if (auth.currentUser) auth.signOut().catch(() => {});
            setCurrentView('login');
          }}
          onRegisterSuccess={handleRegisterSuccess}
        />
      </ErrorBoundary>
    );
  }

  if (currentView === 'pending') {
    return (
      <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-6 text-center font-sans">
        {showSuccessMessage && (
          <p className="mb-4 text-sm font-bold text-emerald-600">✅ Pendaftaran berhasil dikirim.</p>
        )}
        <div className="w-16 h-16 bg-amber-50 text-amber-600 rounded-3xl flex items-center justify-center text-3xl mb-4 shadow-sm">
          ⏳
        </div>
        <h2 className="text-xl font-black text-slate-800">Akun Menunggu Verifikasi</h2>
        <p className="text-sm text-slate-500 max-w-sm mt-2 font-medium">
          Tim Zikola sedang memeriksa STR/SIP Anda. Anda bisa mengakses dashboard dan data pasien setelah akun diverifikasi.
        </p>
        <div className="flex space-x-3 mt-6">
          <button
            onClick={handleLogout}
            className="px-5 py-2.5 bg-slate-200 text-slate-700 text-xs font-bold rounded-xl hover:bg-slate-300 transition-colors"
          >
            Keluar
          </button>
          <button
            onClick={() => resolveAccount(auth.currentUser)}
            className="px-5 py-2.5 bg-teal-600 text-white text-xs font-bold rounded-xl hover:bg-teal-700 shadow-md transition-colors"
          >
            Cek Status
          </button>
        </div>
      </div>
    );
  }

  if (currentView === 'dashboard' && doctorId) {
    return (
      <ErrorBoundary>
        <div className="w-full h-screen">
          <DoctorDashboard currentDoctorId={doctorId} onLogout={handleLogout} />
        </div>
      </ErrorBoundary>
    );
  }

  return (
    <ErrorBoundary>
      {accountError && (
        <div className="fixed top-4 left-0 right-0 z-[200] flex justify-center">
          <div className="bg-red-50 text-red-700 border border-red-100 px-6 py-3 rounded-xl text-xs font-bold">
            {accountError}
          </div>
        </div>
      )}
      <DoctorLogin onGoToRegister={handleGoToRegister} />
    </ErrorBoundary>
  );
}

export default App;
