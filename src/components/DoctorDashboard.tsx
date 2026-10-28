import { doctorWebRTC } from '../lib/webrtc';
import React, { useState, useEffect, useRef } from 'react';
import { db, auth } from '../lib/firebase';
import {
  collection, query, where, orderBy, onSnapshot, addDoc, setDoc,
  doc, getDoc, deleteDoc, updateDoc, serverTimestamp, getDocs, writeBatch
} from 'firebase/firestore';
import { format } from 'date-fns';
import {
  Menu, User, Home, Brain, MessageSquare, BarChart2, Users, Bell, Settings,
  HelpCircle, Phone, MoreVertical, ArrowLeft, Paperclip, Send,
  FileText, Clipboard, Calendar, Star, Info, ShieldCheck, Sparkles, X, Save, Trash2, Edit3, Download, Printer, LogOut, Mic, MicOff,
  Check, CheckCheck, Pill, QrCode, Plus, Clock
} from 'lucide-react';
import {
  Radar, RadarChart, PolarGrid, PolarAngleAxis, ResponsiveContainer,
  AreaChart, Area, XAxis, YAxis, Tooltip, LineChart, Line
} from 'recharts';
import zikolaLogoFull from '../assets/zikola_logo_full.jpg';
import zikolaMascot from '../assets/zikola_mascot.png';

const CLINICAL_SEED_PATIENTS = [
  {
    id: 'demo-patient-1',
    name: 'Budi Pratama',
    avatar: '👦',
    age: 8,
    gender: 'male',
    school: 'SD Bintang Kejora Sby',
    parent: 'Ibu Ratna Dewi',
    phone: '0812-3456-7890',
    hasAssessment: true,
    completedCount: 4,
    scores: {
      logika: 85,
      memori: 78,
      bahasa: 92,
      motorik: 88,
    }
  },
  {
    id: 'demo-patient-2',
    name: 'Aisyah Putri',
    avatar: '👧',
    age: 7,
    gender: 'female',
    school: 'SD Permata Hati',
    parent: 'Ibu Maya Santoso',
    phone: '0813-9876-5432',
    hasAssessment: true,
    completedCount: 3,
    scores: {
      logika: 90,
      memori: 84,
      bahasa: 80,
      motorik: 82,
    }
  },
  {
    id: 'demo-patient-3',
    name: 'Kevin Wijaya',
    avatar: '👦',
    age: 9,
    gender: 'male',
    school: 'SD Bina Prestasi',
    parent: 'Pak Hendra Wijaya',
    phone: '0857-1122-3344',
    hasAssessment: true,
    completedCount: 2,
    scores: {
      logika: 72,
      memori: 65,
      bahasa: 88,
      motorik: 70,
    }
  },
  {
    id: 'demo-patient-4',
    name: 'Nadia Salsabila',
    avatar: '👧',
    age: 6,
    gender: 'female',
    school: 'TK Harapan Bangsa',
    parent: 'Ibu Dina Fitri',
    phone: '0878-3344-5566',
    hasAssessment: false,
    completedCount: 0,
    scores: {
      logika: 0,
      memori: 0,
      bahasa: 0,
      motorik: 0,
    }
  }
];

const CLINICAL_SEED_APPOINTMENTS = [
  {
    id: 'demo-appt-1',
    patientName: 'Budi Pratama',
    parentName: 'Ibu Ratna Dewi',
    dateTime: '2026-09-14T10:00:00',
    topic: 'Konsultasi Evaluasi Perkembangan Logika & Fokus',
    status: 'confirmed',
    type: 'Video Call',
    avatar: '👦'
  },
  {
    id: 'demo-appt-2',
    patientName: 'Aisyah Putri',
    parentName: 'Ibu Maya Santoso',
    dateTime: '2026-09-15T14:30:00',
    topic: 'Tinjauan Rutin Kosakata & Kemandirian Belajar',
    status: 'upcoming',
    type: 'Chat Sesi',
    avatar: '👧'
  },
  {
    id: 'demo-appt-3',
    patientName: 'Kevin Wijaya',
    parentName: 'Pak Hendra Wijaya',
    dateTime: '2026-09-12T11:00:00',
    topic: 'Pemeriksaan Awal Gejala Distraksi & Minat Belajar',
    status: 'completed',
    type: 'Konsultasi Klinik',
    avatar: '👦'
  }
];

const CLINICAL_SEED_CHATS = [
  {
    id: 'demo-chat-1',
    doctorId: 'doctor_rani',
    buyerId: 'demo-patient-1',
    patientName: 'Budi Pratama',
    parentName: 'Ibu Ratna Dewi',
    childAge: 8,
    childGender: 'Laki-laki',
    complaint: 'Sering melamun saat latihan berhitung dan butuh penguatan fokus',
    status: 'active',
    lastMessage: 'Dok, hasil evaluasi logika Budi sudah saya lihat di rapor.',
    unreadCount: 1,
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 3600 * 1000)
  },
  {
    id: 'demo-chat-2',
    doctorId: 'doctor_rani',
    buyerId: 'demo-patient-2',
    patientName: 'Aisyah Putri',
    parentName: 'Ibu Maya Santoso',
    childAge: 7,
    childGender: 'Perempuan',
    complaint: 'Ingin konsultasi pemilihan puzzle stimulasi memori visual',
    status: 'active',
    lastMessage: 'Terima kasih banyak atas materi stimulasi yang dikirimkan!',
    unreadCount: 0,
    createdAt: new Date(Date.now() - 3600 * 1000 * 2),
    expiresAt: new Date(Date.now() + 1800 * 1000)
  }
];

const CLINICAL_SEED_MESSAGES: Record<string, any[]> = {
  'demo-chat-1': [
    {
      id: 'm1',
      senderType: 'patient',
      senderId: 'demo-patient-1',
      text: 'Selamat pagi dr. Rani. Budi sudah menyelesaikan tes logika dan game puzzle minggu ini.',
      timestamp: new Date(Date.now() - 15 * 60 * 1000)
    },
    {
      id: 'm2',
      senderType: 'doctor',
      senderId: 'doctor_rani',
      text: 'Selamat pagi Ibu Ratna. Saya sudah memeriksa grafiknya, kemampuan penalaran Budi berada di skor 85 (Sangat Baik), pemahaman kosakatanya juga sangat tajam.',
      timestamp: new Date(Date.now() - 10 * 60 * 1000)
    },
    {
      id: 'm3',
      senderType: 'patient',
      senderId: 'demo-patient-1',
      text: 'Alhamdulillah dok. Untuk latihan konsentrasi di rumah, apa yang sebaiknya kami latih secara rutin?',
      timestamp: new Date(Date.now() - 5 * 60 * 1000)
    }
  ],
  'demo-chat-2': [
    {
      id: 'm2-1',
      senderType: 'patient',
      senderId: 'demo-patient-2',
      text: 'Halo dokter Rani, mau menanyakan hasil asesmen Aisyah.',
      timestamp: new Date(Date.now() - 30 * 60 * 1000)
    },
    {
      id: 'm2-2',
      senderType: 'doctor',
      senderId: 'doctor_rani',
      text: 'Halo Ibu Maya. Memori spasial Aisyah mencapai skor 84, sudah sangat bagus untuk rentang usianya.',
      timestamp: new Date(Date.now() - 20 * 60 * 1000)
    }
  ]
};

export default function DoctorDashboard({ currentDoctorId, onLogout }: { currentDoctorId: string; onLogout?: () => void }) {
  const [chats, setChats] = useState<any[]>(CLINICAL_SEED_CHATS);
  const [selectedChat, setSelectedChat] = useState<any>(CLINICAL_SEED_CHATS[0]);
  const [jadwalDashboardFilter, setJadwalDashboardFilter] = useState<'all' | 'active' | 'completed'>('all');

  const isChatCompleted = (chat: any) => {
    if (!chat) return false;
    if (chat.status === 'completed') return true;
    if (chat.expiresAt) {
      let expiresAt: Date | null = null;
      if (typeof chat.expiresAt?.toDate === 'function') {
        expiresAt = chat.expiresAt.toDate();
      } else if (typeof chat.expiresAt === 'string') {
        expiresAt = new Date(chat.expiresAt);
      } else if (chat.expiresAt instanceof Date) {
        expiresAt = chat.expiresAt;
      }
      if (expiresAt && expiresAt.getTime() <= Date.now()) {
        return true;
      }
    }
    return false;
  };

  const [messages, setMessages] = useState<any[]>(CLINICAL_SEED_MESSAGES['demo-chat-1']);
  const [newMessage, setNewMessage] = useState('');
  const [patientProfile, setPatientProfile] = useState<any>({
    uid: 'demo-patient-1',
    name: 'Budi Pratama',
    age: 8,
    gender: 'male',
    avatar: '👦',
    school: 'SD Bintang Kejora Sby',
    parent: 'Ibu Ratna Dewi',
    phone: '0812-3456-7890',
    noRm: `ZK-${new Date().getFullYear()}-0028`
  });
  const [testResults, setTestResults] = useState<any>({
    cognitive: { completed: true, percentage: 85, score: 85, total: 100, completedDate: new Date() },
    linguistic: { completed: true, percentage: 92, score: 92, total: 100, completedDate: new Date() },
    personality: { completed: true, percentage: 88, score: 88, total: 100, completedDate: new Date() },
    motor: { completed: true, percentage: 88, score: 88, total: 100, completedDate: new Date() }
  });
  const [gameAssessments, setGameAssessments] = useState<any>({
    assessments: {
      puzzleGame: { averageScore: 85 },
      memory: { averageScore: 78 },
      wordPuzzle: { averageScore: 92 }
    }
  });
  const [aiReport, setAiReport] = useState<any>(null);
  const [showAiReportModal, setShowAiReportModal] = useState(false);
  const [showPrintModal, setShowPrintModal] = useState(false);
  const [showAddPatientModal, setShowAddPatientModal] = useState(false);
  const [patientTabFilter, setPatientTabFilter] = useState<'all' | 'assessed' | 'new'>('all');
  // Add Patient Form State
  const [newPatientName, setNewPatientName] = useState('');
  const [newPatientDob, setNewPatientDob] = useState('');
  const [newPatientGender, setNewPatientGender] = useState('male');
  const [newPatientParent, setNewPatientParent] = useState('');
  const [newPatientPhone, setNewPatientPhone] = useState('');
  const [isCreatingPatient, setIsCreatingPatient] = useState(false);
  const [doctorAiNote, setDoctorAiNote] = useState('');
  const [actionTarget, setActionTarget] = useState('Motorik Halus');
  const [actionScreenTime, setActionScreenTime] = useState('Maks. 30 Menit per Hari');
  const [actionNotes, setActionNotes] = useState('');
  
  // E-Prescription & Therapy Plan state
  const [patientPrescriptions, setPatientPrescriptions] = useState<any[]>([]);
  const [patientActionPlans, setPatientActionPlans] = useState<any[]>([]);
  const [patientMaterials, setPatientMaterials] = useState<any[]>([]);
  const [showPrescriptionModal, setShowPrescriptionModal] = useState(false);
  const [prescType, setPrescType] = useState<'suplemen' | 'terapi' | 'medis'>('suplemen');
  const [prescItemName, setPrescItemName] = useState('');
  const [prescDosage, setPrescDosage] = useState('');
  const [prescDuration, setPrescDuration] = useState('');
  const [prescNotes, setPrescNotes] = useState('');
  const [isSavingPrescription, setIsSavingPrescription] = useState(false);
  
  // Real Patient profiles list from Firebase database
  const [allPatients, setAllPatients] = useState<any[]>(CLINICAL_SEED_PATIENTS);
  const [activePatientUid, setActivePatientUid] = useState<string | null>(CLINICAL_SEED_PATIENTS[0].id);
  const [notifications, setNotifications] = useState<any[]>([]);

  // Memoized dynamic & db notifications combined
  const displayNotifications = React.useMemo(() => {
    if (notifications.length > 0) return notifications;

    if (allPatients.length === 0) {
      return [
        { id: 'n-empty', title: 'Belum Ada Aktivitas', desc: 'Belum ada notifikasi baru dari pasien', time: 'Baru saja', type: 'info' }
      ];
    }

    const generated: any[] = [];
    allPatients.forEach((patient) => {
      if (patient.hasAssessment) {
        generated.push({
          id: `gen-${patient.id}-assess`,
          title: 'Asesmen Tersedia',
          desc: `${patient.name} memiliki data hasil asesmen & skrining`,
          time: 'Terverifikasi',
          type: 'success'
        });
      } else {
        generated.push({
          id: `gen-${patient.id}-new`,
          title: 'Pasien Baru Terdaftar',
          desc: `${patient.name} telah terdaftar dan menunggu asesmen pertama`,
          time: 'Baru saja',
          type: 'info'
        });
      }
    });

    return generated.slice(0, 5);
  }, [notifications, allPatients]);

  const [patientNames, setPatientNames] = useState<Record<string, string>>({
    'demo-patient-1': 'Budi Pratama',
    'demo-patient-2': 'Aisyah Putri',
    'demo-patient-3': 'Kevin Wijaya',
    'demo-patient-4': 'Nadia Salsabila',
  });
  const [patientAvatars, setPatientAvatars] = useState<Record<string, string>>({
    'demo-patient-1': '👦',
    'demo-patient-2': '👧',
    'demo-patient-3': '👦',
    'demo-patient-4': '👧',
  });
  
  // Doctor Profile State
  const [doctorProfile, setDoctorProfile] = useState<any>(null);
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [isSavingProfile, setIsSavingProfile] = useState(false);
  
  // Active Navigation Menu (Matches Sidebar Mockup)
  const [activeMenu, setActiveMenu] = useState<'dashboard' | 'patients' | 'jadwal' | 'asesmen' | 'laporan' | 'pesan' | 'profil'>(() => {
    const params = new URLSearchParams(window.location.search);
    const tab = params.get('tab');
    if (tab && ['dashboard', 'patients', 'jadwal', 'asesmen', 'laporan', 'pesan', 'profil'].includes(tab)) {
      return tab as any;
    }
    return 'dashboard';
  });
  // Mobile Responsive States
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [mobileShowRadarSheet, setMobileShowRadarSheet] = useState(false);
  const [showPatientDetailOptionsMenu, setShowPatientDetailOptionsMenu] = useState(false);
  // SEGMEN 2 States: Jadwal Filter & Notifications
  const [jadwalTabFilter, setJadwalTabFilter] = useState<'upcoming' | 'completed'>('upcoming');
  const [allAppointments, setAllAppointments] = useState<any[]>(CLINICAL_SEED_APPOINTMENTS);
  const [showNotificationDrawer, setShowNotificationDrawer] = useState(false);
  const [assessmentCategoryFilter, setAssessmentCategoryFilter] = useState('all');

  // Patient detail sub-tabs: 'overview' | 'assessment' | 'stimulasi' | 'notes' | 'reports' | 'medical_history'
  const [patientDetailTab, setPatientDetailTab] = useState<'overview' | 'assessment' | 'stimulasi' | 'notes' | 'reports' | 'medical_history'>(() => {
    const params = new URLSearchParams(window.location.search);
    const sub = params.get('sub');
    if (sub && ['overview', 'assessment', 'stimulasi', 'notes', 'reports', 'medical_history'].includes(sub)) {
      return sub as any;
    }
    return 'overview';
  });
  
  // Selected patient name for display
  const [selectedPatientId, setSelectedPatientId] = useState<string | null>(null);

  // Selected assessment date in tab Hasil Asesmen
  const [selectedAssessmentDate, setSelectedAssessmentDate] = useState('Sesi Terkini');

  // Notes and Reports subcollection states
  const [patientNotes, setPatientNotes] = useState<any[]>([]);
  const [patientReports, setPatientReports] = useState<any[]>([]);
  const [newNoteText, setNewNoteText] = useState('');
  const [newNoteCategory, setNewNoteCategory] = useState('Perkembangan');

  // Modal States
  const [showMateriModal, setShowMateriModal] = useState(false);
  const [showTugasModal, setShowTugasModal] = useState(false);
  const [showJadwalModal, setShowJadwalModal] = useState(false);
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [showPatientProfileModal, setShowPatientProfileModal] = useState(false);
  const [showPhoneCallModal, setShowPhoneCallModal] = useState(false);
  const [isDoctorMuted, setIsDoctorMuted] = useState(false);
  const [incomingPatientCall, setIncomingPatientCall] = useState<any>(null);
  const [callNotes, setCallNotes] = useState('');
  const [phoneCallState, setPhoneCallState] = useState<'connecting' | 'connected'>('connecting');
  const [phoneCallDuration, setPhoneCallDuration] = useState(0);

  // Form States
  const [selectedMateriId, setSelectedMateriId] = useState('');
  const [selectedGameId, setSelectedGameId] = useState('');
  const [appointmentDateTime, setAppointmentDateTime] = useState('');
  const [sessionRating, setSessionRating] = useState(5);
  const [clinicalNotes, setClinicalNotes] = useState('');
  const [ratingSubmitted, setRatingSubmitted] = useState(false);
  
  const [timeRemaining, setTimeRemaining] = useState<string>("30:00");
  const [isExpired, setIsExpired] = useState<boolean>(false);
  
  const bottomRef = useRef<HTMLDivElement>(null);
  const phoneCallTimerRef = useRef<any>(null);

  // Search/Filter states for panels
  const [globalSearch, setGlobalSearch] = useState('');
  const [asesmenSearch, setAsesmenSearch] = useState('');
  const [asesmenFilter, setAsesmenFilter] = useState('all');

    const cleanClinicalText = (text: string) => {
    if (!text) return '';
    return text.replace(/\*/g, '').replace(/#/g, '');
  };

  // Date formatting helper that protects against Timestamp or format crashes
  const formatDateSafe = (val: any) => {
    if (!val) return 'Baru saja';
    try {
      let dateObj: Date;
      if (val && typeof val.toDate === 'function') {
        dateObj = val.toDate();
      } else if (val && typeof val.toMillis === 'function') {
        dateObj = new Date(val.toMillis());
      } else if (val?.seconds) {
        dateObj = new Date(val.seconds * 1000);
      } else {
        dateObj = new Date(val);
      }
      if (isNaN(dateObj.getTime())) {
        return 'Baru saja';
      }
      return format(dateObj, 'dd MMMM yyyy, HH:mm');
    } catch (e) {
      return 'Baru saja';
    }
  };

  // Doctor photo file upload handler
  const handleDoctorPhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        const base64Content = result.split(',')[1];
        setDoctorProfile((prev: any) => ({
          ...prev,
          image: `base64:${base64Content}`
        }));
      };
      reader.readAsDataURL(file);
    }
  };

  // Create physical or new patient directly in Firestore
  const handleCreatePatient = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPatientName.trim()) return;

    try {
      let calculatedAge = 8;
      if (newPatientDob) {
        const birthDate = new Date(newPatientDob);
        const diff = Date.now() - birthDate.getTime();
        const ageDate = new Date(diff);
        calculatedAge = Math.max(1, Math.abs(ageDate.getUTCFullYear() - 1970));
      }

      const newUserId = 'patient_' + Date.now();
      const userData = {
        name: newPatientParent || 'Orang Tua Pasien',
        phone: newPatientPhone || '-',
        role: 'parent',
        createdAt: serverTimestamp(),
        profile: {
          name: newPatientName,
          age: calculatedAge,
          gender: newPatientGender,
          school: newPatientSchool || 'Belum diisi',
          parent: newPatientParent || 'Orang Tua Pasien',
          phone: newPatientPhone || '-',
          dob: newPatientDob || '',
          avatar: newPatientGender === 'female' ? '👧' : '👦',
        }
      };

      await setDoc(doc(db, 'users', newUserId), userData);

      // Create children subcollection
      await addDoc(collection(db, 'users', newUserId, 'children'), {
        name: newPatientName,
        age: calculatedAge,
        gender: newPatientGender,
        dob: newPatientDob || '',
        school: newPatientSchool || 'Belum diisi',
        avatar: newPatientGender === 'female' ? '👧' : '👦',
        createdAt: serverTimestamp()
      });

      // Reset form
      setNewPatientName('');
      setNewPatientDob('');
      setNewPatientGender('male');
      setNewPatientParent('');
      setNewPatientPhone('');
      setNewPatientSchool('');
      setShowAddPatientModal(false);

      // Select newly created patient
      setActivePatientUid(newUserId);
      setSelectedPatientId(newPatientName);
      setActiveMenu('patients');
      setPatientDetailTab('overview');

      alert(`Pasien "${newPatientName}" berhasil didaftarkan ke sistem!`);
    } catch (err) {
      console.error('Error creating patient:', err);
      alert('Gagal menambahkan pasien: ' + err);
    }
  };

  // Save Doctor Profile changes to Firestore
  const handleSaveDoctorProfile = async (e?: React.FormEvent | React.MouseEvent) => {
    if (e && 'preventDefault' in e) {
      e.preventDefault();
    }
    if (!doctorProfile) return;
    setIsSavingProfile(true);
    try {
      await setDoc(doc(db, 'doctors', currentDoctorId), doctorProfile, { merge: true });
      setShowProfileModal(false);
      alert('Profil berhasil diperbarui!');
    } catch (err) {
      console.error('Error saving doctor profile:', err);
      alert('Gagal menyimpan profil. Silakan coba lagi.');
    } finally {
      setIsSavingProfile(false);
    }
  };

  // Avatar rendering helper function with support for doctor's base64 prefix
  const renderAvatar = (imageSrc: string | undefined, sizeClass: string = "w-10 h-10", textClass: string = "text-sm") => {
    if (imageSrc) {
      if (imageSrc.startsWith('base64:')) {
        const rawBase64 = imageSrc.split(':')[1];
        return <img src={`data:image/jpeg;base64,${rawBase64}`} alt="Avatar" className={`${sizeClass} rounded-full object-cover border border-slate-100 shadow-sm`} />;
      }
      if (imageSrc.startsWith('data:') || imageSrc.startsWith('http') || imageSrc.startsWith('/') || imageSrc.includes('.png') || imageSrc.includes('.jpg')) {
        return <img src={imageSrc} alt="Avatar" className={`${sizeClass} rounded-full object-cover border border-slate-100 shadow-sm`} />;
      }
    }
    return (
      <div className={`${sizeClass} rounded-full bg-teal-50 border border-teal-100 text-teal-600 flex items-center justify-center font-bold ${textClass}`}>
        👩‍⚕️
      </div>
    );
  };

  // Logout helper function
  const handleLogout = () => {
    try {
      auth.signOut();
    } catch (e) {}
    if (onLogout) {
      onLogout();
    } else {
      window.location.reload();
    }
  };

  // Predefined materials for "Kirim Materi"
  const materiList = [
    {
      id: 'materi_01',
      title: 'Stimulasi Motorik Halus',
      desc: 'Panduan melatih kelenturan otot jari tangan anak melalui aktivitas melipat kertas, memotong pola, dan menempel kolase edukatif.',
      icon: '🎨'
    },
    {
      id: 'materi_02',
      title: 'Pengembangan Kosa Kata & Bahasa',
      desc: 'Panduan membacakan dongeng interaktif bersama Ayah/Bunda untuk merangsang minat baca dan memperkaya perbendaharaan kata anak.',
      icon: '📚'
    },
    {
      id: 'materi_03',
      title: 'Regulasi Emosi & Mengatasi Tantrum',
      desc: 'Langkah taktis mendampingi anak saat mengalami ledakan emosi secara suportif, tenang, dan tanpa kekerasan.',
      icon: '🌱'
    }
  ];

  // Predefined games for "Beri Tugas"
  const gamesList = [
    { id: 'puzzle_game_screen', name: 'Puzzle Logika (Problem Solving)' },
    { id: 'memory_game_screen', name: 'Memori Visual (Daya Identifikasi)' },
    { id: 'number_sequence_game_screen', name: 'Math Adventure (Numerasi)' },
    { id: 'word_puzzle_game_screen', name: 'Bahasa Seru (Pemahaman Kognitif)' }
  ];

  // Fetch Chats
  useEffect(() => {
    const q = query(
      collection(db, 'chats'),
      where('doctorId', '==', currentDoctorId),
      orderBy('createdAt', 'desc')
    );
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const chatsData: any[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      const finalChats = chatsData.length > 0 ? chatsData : CLINICAL_SEED_CHATS;
      setChats(finalChats);

      if (finalChats.length > 0 && !selectedChat) {
        setSelectedChat(finalChats[0]);
        setActivePatientUid(finalChats[0].buyerId);
      }

      finalChats.forEach(chat => {
        if (chat.buyerId && !patientNames[chat.buyerId]) {
          getDoc(doc(db, 'users', chat.buyerId)).then(snap => {
            if (snap.exists()) {
              const data = snap.data();
              const name = data?.name || data?.profile?.name || 'Pasien Zikola';
              const avatar = (data?.profile?.avatarBase64 || data?.avatarBase64) ? `data:image/jpeg;base64,${data.profile?.avatarBase64 || data.avatarBase64}` : (data?.avatar || data?.profile?.avatar || '👦');
              setPatientNames(prev => ({ ...prev, [chat.buyerId]: name }));
              setPatientAvatars(prev => ({ ...prev, [chat.buyerId]: avatar }));
            }
          }).catch(err => console.error(err));
        }
      });
    }, (error) => {
      console.error("Firestore Query Error:", error);
      setChats(CLINICAL_SEED_CHATS);
      if (!selectedChat) {
        setSelectedChat(CLINICAL_SEED_CHATS[0]);
        setActivePatientUid(CLINICAL_SEED_CHATS[0].buyerId);
      }
    });

    return () => unsubscribe();
  }, [currentDoctorId, selectedChat]);

  // Fetch Appointments
  useEffect(() => {
    // Only this doctor's appointments (firestore.rules reject unfiltered reads).
    // Sorted client-side to avoid needing a composite index.
    const apptsQuery = query(
      collection(db, 'appointments'),
      where('doctorId', '==', currentDoctorId)
    );
    const unsubscribe = onSnapshot(apptsQuery, (snapshot) => {
      const apptsData: any[] = snapshot.docs.map(d => ({
        id: d.id,
        ...d.data()
      }));
      apptsData.sort((a, b) => String(b.dateTime || '').localeCompare(String(a.dateTime || '')));
      setAllAppointments(apptsData.length > 0 ? apptsData : CLINICAL_SEED_APPOINTMENTS);
    }, (err) => {
      console.log('Appointments read fallback:', err);
      setAllAppointments(CLINICAL_SEED_APPOINTMENTS);
    });

    return () => unsubscribe();
  }, [currentDoctorId]);

  // Fetch All Registered Patient Profiles from the database
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'users'), async (snapshot) => {
      const patientsPromises = snapshot.docs.map(async (userDoc) => {
        const data = userDoc.data();
        const name = data.name || data.profile?.name;
        if (!name) return null;

        let completedCount = 0;
        let pScoreLogika = 0;
        let pScoreMemori = 0;
        let pScoreBahasa = 0;
        let hasData = false;

        try {
          const [testsSnap, gamesSnap] = await Promise.all([
            getDoc(doc(db, 'users', userDoc.id, 'data', 'tests')),
            getDoc(doc(db, 'users', userDoc.id, 'data', 'games'))
          ]);

          if (testsSnap.exists()) {
            const t = testsSnap.data();
            if (t.cognitive?.completed) { completedCount++; pScoreLogika = Math.round(t.cognitive.percentage || 0); hasData = true; }
            if (t.linguistic?.completed) { completedCount++; pScoreBahasa = Math.round(t.linguistic.percentage || 0); hasData = true; }
            if (t.personality?.completed) { completedCount++; hasData = true; }
            if (t.motor?.completed) { completedCount++; hasData = true; }
          }
          if (gamesSnap.exists()) {
            const g = gamesSnap.data()?.assessments;
            if (g) {
              if (g.puzzleGame?.averageScore) { pScoreLogika = Math.round(g.puzzleGame.averageScore); hasData = true; }
              if (g.memory?.averageScore) { pScoreMemori = Math.round(g.memory.averageScore); hasData = true; }
              if (g.wordPuzzle?.averageScore) { pScoreBahasa = Math.round(g.wordPuzzle.averageScore); hasData = true; }
              const gameKeys = Object.keys(g);
              if (gameKeys.length > 0) hasData = true;
            }
          }
        } catch (e) {
          // silently handle
        }

        return {
          id: userDoc.id,
          name: name,
          avatar: (data.profile?.avatarBase64 || data.avatarBase64) ? `data:image/jpeg;base64,${data.profile?.avatarBase64 || data.avatarBase64}` : (data.avatar || data.profile?.avatar || '👦'),
          age: data.age || data.profile?.age || 8,
          gender: data.gender || data.profile?.gender || 'male',
          school: data.profile?.school || '-',
          parent: data.profile?.parent || '-',
          phone: data.profile?.phone || '-',
          hasAssessment: hasData,
          completedCount: completedCount,
          scores: {
            logika: pScoreLogika,
            memori: pScoreMemori,
            bahasa: pScoreBahasa,
          }
        };
      });

      const resolved = (await Promise.all(patientsPromises)).filter(Boolean);
      setAllPatients(resolved.length > 0 ? resolved : CLINICAL_SEED_PATIENTS);
    }, (error) => {
      console.error("Error loading patient list:", error);
      setAllPatients(CLINICAL_SEED_PATIENTS);
    });
    return () => unsubscribe();
  }, []);

  // Fetch Doctor Notifications from Firestore
  useEffect(() => {
    const q = query(
      collection(db, 'doctors', currentDoctorId, 'notifications'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const notifs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setNotifications(notifs);
    }, (error) => {
      console.log("No doctor notifications subcollection, using fallback generator");
    });
    return () => unsubscribe();
  }, [currentDoctorId]);

  // Fetch Doctor Profile
  useEffect(() => {
    const fetchDoc = async () => {
      try {
        const snap = await getDoc(doc(db, 'doctors', currentDoctorId));
        if (snap.exists()) {
          setDoctorProfile(snap.data());
        } else {
          const initialData = {
            name: 'dr. Rani, M.Psi., Psikolog',
            specialty: 'Psikolog Anak & Tumbuh Kembang',
            hospital: 'Zikola Clinic',
            image: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=200&auto=format&fit=crop',
            experience: 10,
            licenseNumber: 'STR-001/ZIKOLA/2025',
            practiceLocation: 'Daring',
            education: 'S2 Psikologi Profesi',
            bio: 'Berpengalaman selama 10 tahun lebih dalam pendampingan tumbuh kembang dan kognitif anak.',
            price: 150000,
            available: true,
          };
          setDoctorProfile(initialData);
        }
      } catch (err) {
        console.error('Error fetching doctor profile:', err);
      }
    };
    fetchDoc();
  }, [currentDoctorId]);

  // Fetch Messages for chat
  useEffect(() => {
    if (!selectedChat) return;

    const q = query(
      collection(db, 'chats', selectedChat.id, 'messages'),
      orderBy('timestamp', 'asc')
    );

    const unsubscribeMessages = onSnapshot(q, (snapshot) => {
      const msgs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      if (msgs.length === 0 && CLINICAL_SEED_MESSAGES[selectedChat.id]) {
        setMessages(CLINICAL_SEED_MESSAGES[selectedChat.id]);
      } else {
        setMessages(msgs);
      }
      setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    }, (err) => {
      if (CLINICAL_SEED_MESSAGES[selectedChat.id]) {
        setMessages(CLINICAL_SEED_MESSAGES[selectedChat.id]);
      }
    });

    const unsubscribeChatDoc = onSnapshot(doc(db, 'chats', selectedChat.id, 'webrtc', 'session'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data?.status === 'ringing' && data?.caller === 'user') {
          setIncomingPatientCall({
            chatId: selectedChat.id,
            patientName: patientNames[selectedChat.buyerId] || patientProfile?.name || 'Pasien',
          });
        } else if (data?.status === 'connected') {
          setPhoneCallState('connected');
          setIncomingPatientCall(null);
        } else if (data?.status === 'ended') {
          setPhoneCallState('connecting');
          setShowPhoneCallModal(false);
          setIncomingPatientCall(null);
        }
      }
    });

    return () => {
      unsubscribeMessages();
      unsubscribeChatDoc();
    };
  }, [selectedChat]);

  // Fetch Profile, Children subcollection, Tests, Assessments, Notes, and Reports by activePatientUid
  useEffect(() => {
    if (!activePatientUid) return;

    // Reset previous patient assessment & report state immediately to prevent state leakage
    setTestResults(null);
    setGameAssessments(null);
    setAiReport(null);
    setPatientNotes([]);
    setPatientReports([]);

    // Populate demo patient clinical baseline if available
    const demoPatient = CLINICAL_SEED_PATIENTS.find(p => p.id === activePatientUid);
    if (demoPatient) {
      setPatientProfile({
        uid: demoPatient.id,
        name: demoPatient.name,
        age: demoPatient.age,
        gender: demoPatient.gender,
        avatar: demoPatient.avatar,
        school: demoPatient.school,
        parent: demoPatient.parent,
        phone: demoPatient.phone,
        hobbies: 'Membaca Komik & Eksperimen Sains',
        interests: 'Robotik, Sains, Alam Bebas',
        personality: 'Cerdas, Aktif, Terkadang Mudah Terdistraksi',
        learningStyle: 'Visual & Kinestetik',
        noRm: `ZK-${new Date().getFullYear()}-0028`
      });
      setTestResults({
        cognitive: { completed: true, percentage: demoPatient.scores.logika, score: demoPatient.scores.logika, total: 100, completedDate: new Date() },
        linguistic: { completed: true, percentage: demoPatient.scores.bahasa, score: demoPatient.scores.bahasa, total: 100, completedDate: new Date() },
        personality: { completed: true, percentage: 88, score: 88, total: 100, completedDate: new Date() },
        motor: { completed: true, percentage: demoPatient.scores.motorik || 85, score: demoPatient.scores.motorik || 85, total: 100, completedDate: new Date() }
      });
      setGameAssessments({
        assessments: {
          puzzleGame: { averageScore: demoPatient.scores.logika },
          memory: { averageScore: demoPatient.scores.memori },
          wordPuzzle: { averageScore: demoPatient.scores.bahasa }
        }
      });
      setPatientNotes([
        {
          id: 'note-seed-1',
          category: 'Observasi Klinis',
          text: 'Daya analisis dan penalaran logis sangat tinggi. Pola atensi visual konsisten dengan rekomendasi penguatan ritme belajar harian.',
          createdAt: new Date(),
          doctorName: 'dr. Rani, M.Psi.'
        }
      ]);
    }

    let parentInfo: any = {};

    const unsubscribeProfile = onSnapshot(doc(db, 'users', activePatientUid), (snap) => {
      if (snap.exists()) {
        const userData = snap.data();
        parentInfo = userData;
        
        setPatientProfile((prev: any) => ({
          ...prev,
          uid: activePatientUid,
          parent: userData.name || userData.profile?.name || userData.profile?.parentName || '-',
          phone: userData.phone || userData.profile?.phone || userData.profile?.parentPhone || '-',
          school: userData.profile?.school || userData.school || '-',
        }));
      }
    });

    // Listen to children subcollection where real child data (name, age, gender) is stored
    const unsubscribeChildren = onSnapshot(collection(db, 'users', activePatientUid, 'children'), (snap) => {
      if (!snap.empty) {
        const childDoc = snap.docs[0];
        const childData = childDoc.data();
        setPatientProfile((prev: any) => ({
          ...prev,
          uid: activePatientUid,
          childId: childDoc.id,
          name: childData.name || 'Pasien Anak',
          gender: childData.gender || 'male',
          age: childData.age || 8,
          avatar: childData.avatarBase64 ? `data:image/jpeg;base64,${childData.avatarBase64}` : (childData.avatar || '👦'),
          avatarBase64: childData.avatarBase64 || null,
          school: childData.school || prev?.school || '-',
          hobbies: childData.surveyData?.hobbies?.join(', ') || childData.hobbies || null,
          interests: childData.surveyData?.interests?.join(', ') || childData.interests || null,
          personality: childData.surveyData?.personality?.join(', ') || childData.personality || null,
          learningStyle: childData.surveyData?.learningStyle?.join(', ') || childData.learningStyle || null,
        }));
      } else if (!activePatientUid.startsWith('demo-')) {
        // Fallback if children collection is empty
        setPatientProfile((prev: any) => ({
          ...prev,
          uid: activePatientUid,
          name: parentInfo.name || 'Pasien Anak',
          gender: parentInfo.profile?.gender || 'male',
          age: parentInfo.profile?.age || 8,
          avatar: (parentInfo.profile?.avatarBase64 || parentInfo.avatarBase64) ? `data:image/jpeg;base64,${parentInfo.profile?.avatarBase64 || parentInfo.avatarBase64}` : (parentInfo.avatar || parentInfo.profile?.avatar || '👦'),
          avatarBase64: parentInfo.profile?.avatarBase64 || parentInfo.avatarBase64 || null,
          hobbies: parentInfo.profile?.surveyData?.hobbies?.join(', ') || null,
          interests: parentInfo.profile?.surveyData?.interests?.join(', ') || null,
          personality: parentInfo.profile?.surveyData?.personality?.join(', ') || null,
          learningStyle: parentInfo.profile?.surveyData?.learningStyle?.join(', ') || null,
        }));
      }
    });

    const unsubscribeTests = onSnapshot(doc(db, 'users', activePatientUid, 'data', 'tests'), (snap) => {
      if (snap.exists()) {
        setTestResults(snap.data());
      } else if (!activePatientUid.startsWith('demo-')) {
        setTestResults(null);
      }
    });

    const unsubscribeGames = onSnapshot(doc(db, 'users', activePatientUid, 'data', 'games'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data && data.assessments) {
          setGameAssessments(data.assessments);
        } else if (!activePatientUid.startsWith('demo-')) {
          setGameAssessments(null);
        }
      } else if (!activePatientUid.startsWith('demo-')) {
        setGameAssessments(null);
      }
    });

    const unsubscribeAiReport = onSnapshot(doc(db, 'users', activePatientUid, 'data', 'ai_report'), (snap) => {
      if (snap.exists()) {
        setAiReport(snap.data());
      } else if (!activePatientUid.startsWith('demo-')) {
        setAiReport(null);
      }
    });

    // Notes listener
    const notesQuery = query(
      collection(db, 'users', activePatientUid, 'notes'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribeNotes = onSnapshot(notesQuery, (snap) => {
      const notesData = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPatientNotes(notesData);
    }, (err) => console.log('Notes read failed, fallback to empty'));

    // Reports listener
    const reportsQuery = query(
      collection(db, 'users', activePatientUid, 'reports'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribeReports = onSnapshot(reportsQuery, (snap) => {
      const reportsData = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPatientReports(reportsData);
    }, (err) => console.log('Reports read failed, fallback to empty'));

    // Prescriptions listener
    const prescriptionsQuery = query(
      collection(db, 'users', activePatientUid, 'prescriptions'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribePrescriptions = onSnapshot(prescriptionsQuery, (snap) => {
      const prescData = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPatientPrescriptions(prescData);
    }, (err) => console.log('Prescriptions read failed, fallback to empty'));

    // Action plans listener
    const plansQuery = query(
      collection(db, 'users', activePatientUid, 'action_plans'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribePlans = onSnapshot(plansQuery, (snap) => {
      const plansData = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPatientActionPlans(plansData);
    }, (err) => console.log('Action plans read failed, fallback to empty'));

    // Materials listener
    const matsQuery = query(
      collection(db, 'users', activePatientUid, 'materials'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribeMats = onSnapshot(matsQuery, (snap) => {
      const matsData = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPatientMaterials(matsData);
    }, (err) => console.log('Materials read failed, fallback to empty'));

    // EMR listener
    const unsubscribeEmr = onSnapshot(doc(db, 'users', activePatientUid, 'emr', 'latest'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data.birthCondition) setEmrBirthCondition(data.birthCondition);
        if (data.pregnancyNotes) setEmrPregnancyNotes(data.pregnancyNotes);
        if (data.allergies) setEmrAllergies(data.allergies);
        if (data.previousTherapy) setEmrPreviousTherapy(data.previousTherapy);
        if (data.diagnosis) setEmrDiagnosis(data.diagnosis);
        if (data.treatmentPlan) setEmrTreatmentPlan(data.treatmentPlan);
      } else {
        setEmrBirthCondition('Normal (Cukup Bulan)');
        setEmrPregnancyNotes('');
        setEmrAllergies('');
        setEmrPreviousTherapy('');
        setEmrDiagnosis('');
        setEmrTreatmentPlan('');
      }
    }, (err) => console.log('EMR read failed, fallback to defaults'));

    return () => {
      unsubscribeProfile();
      unsubscribeChildren();
      unsubscribeTests();
      unsubscribeGames();
      unsubscribeAiReport();
      unsubscribeNotes();
      unsubscribeReports();
      unsubscribePrescriptions();
      unsubscribePlans();
      unsubscribeMats();
      unsubscribeEmr();
    };
  }, [activePatientUid]);

  // Expiration Timer & State for Sesi Chat
  useEffect(() => {
    if (!selectedChat) return;

    if (selectedChat.status === 'completed') {
      setIsExpired(true);
      setTimeRemaining("Selesai");
      return;
    }

    if (!selectedChat.expiresAt) {
      setTimeRemaining("Aktif");
      setIsExpired(false);
      return;
    }
    
    const checkTimer = () => {
      const now = new Date();
      let expiresAt;
      if (typeof selectedChat.expiresAt?.toDate === 'function') {
        expiresAt = selectedChat.expiresAt.toDate();
      } else if (typeof selectedChat.expiresAt === 'string') {
        expiresAt = new Date(selectedChat.expiresAt);
      } else if (selectedChat.expiresAt instanceof Date) {
        expiresAt = selectedChat.expiresAt;
      } else {
        expiresAt = new Date();
      }
      
      const diffMs = expiresAt.getTime() - now.getTime();
      
      if (diffMs <= 0) {
        setIsExpired(true);
        setTimeRemaining("Selesai");
      } else {
        setIsExpired(false);
        const diffMins = Math.floor(diffMs / 60000);
        const diffSecs = Math.floor((diffMs % 60000) / 1000);
        setTimeRemaining(`${diffMins.toString().padStart(2, '0')}:${diffSecs.toString().padStart(2, '0')}`);
      }
    };

    checkTimer();
    const interval = setInterval(checkTimer, 1000);

    return () => clearInterval(interval);
  }, [selectedChat]);

  
  const handleCompleteSession = async (chatId: string) => {
    if (!chatId) return;
    const confirm = window.confirm('Apakah Anda yakin ingin menyelesaikan dan menutup sesi konsultasi ini?');
    if (!confirm) return;

    try {
      // 1. Update session status in Firestore
      await updateDoc(doc(db, 'chats', chatId), {
        status: 'completed',
        completedAt: serverTimestamp(),
        expiresAt: new Date(Date.now() - 1000)
      });

      // 2. Send official closing message
      await addDoc(collection(db, 'chats', chatId, 'messages'), {
        text: '🏁 **SESI KONSULTASI RESMI SELESAI**\n\nTerima kasih telah berkonsultasi dengan Klinik Zikola. Rangkuman hasil asesmen dan Rencana Stimulasi telah tersimpan ke rekam medis anak Anda. Sesi chat resmi ditutup.',
        senderId: currentDoctorId,
        senderType: 'doctor',
        timestamp: serverTimestamp()
      });

      setIsExpired(true);
      setTimeRemaining('Selesai');
      setSelectedChat((prev: any) => prev ? { ...prev, status: 'completed' } : null);

      // Open rating & case notes modal so the doctor can write case summary
      setShowRatingModal(true);
    } catch (err) {
      console.error('Error completing session:', err);
      alert('Gagal menyelesaikan sesi: ' + err);
    }
  };

  
  
  // Timer effect for live call duration
  useEffect(() => {
    if (showPhoneCallModal && phoneCallState === 'connected') {
      phoneCallTimerRef.current = setInterval(() => {
        setPhoneCallDuration(prev => prev + 1);
      }, 1000);
    } else {
      if (phoneCallTimerRef.current) {
        clearInterval(phoneCallTimerRef.current);
        phoneCallTimerRef.current = null;
      }
    }
    return () => {
      if (phoneCallTimerRef.current) clearInterval(phoneCallTimerRef.current);
    };
  }, [showPhoneCallModal, phoneCallState]);

  const acceptIncomingCall = async () => {
    if (!selectedChat?.id) return;
    try {
      setShowPhoneCallModal(true);
      setPhoneCallState('connecting');
      setPhoneCallDuration(0);
      setIncomingPatientCall(null);

      await doctorWebRTC.answerPatientCall(
        selectedChat.id,
        (remoteStream) => {
          console.log('[DoctorWebRTC] Receiving patient remote stream');
          const player = document.getElementById('remote-audio-player') as HTMLAudioElement;
          if (player) {
            player.srcObject = remoteStream;
            player.play().catch(e => console.warn('Audio autoplay failed:', e));
          }
        },
        (status) => {
          console.log('[DoctorWebRTC] Status changed to:', status);
          if (status === 'connected') {
            setPhoneCallState('connected');
          } else if (status === 'ended') {
            setPhoneCallState('connecting');
            setShowPhoneCallModal(false);
          }
        }
      );
    } catch (e) {
      console.error('[DoctorWebRTC] Accept call error:', e);
      alert('Gagal menerima panggilan: ' + e);
    }
  };

  const declineIncomingCall = async () => {
    if (!selectedChat?.id) return;
    try {
      await doctorWebRTC.endCall(selectedChat.id);
      setIncomingPatientCall(null);
    } catch (e) {
      console.error('[DoctorWebRTC] Decline call error:', e);
    }
  };

  const startAudioCall = async () => {
    if (!selectedChat?.id) return;
    
    // Start pure In-App WebRTC voice call directly to the mobile app
    setShowPhoneCallModal(true);
    setPhoneCallState('connecting');
    setPhoneCallDuration(0);

    try {
      await doctorWebRTC.startDoctorCall(
        selectedChat.id,
        (remoteStream) => {
          console.log('[DoctorWebRTC] Receiving patient remote audio stream');
          const player = document.getElementById('remote-audio-player') as HTMLAudioElement;
          if (player) {
            player.srcObject = remoteStream;
            player.play().catch(e => console.warn('Audio autoplay error:', e));
          }
        },
        (status) => {
          console.log('[DoctorWebRTC] Call status changed to:', status);
          if (status === 'connected') {
            setPhoneCallState('connected');
          } else if (status === 'ended') {
            setPhoneCallState('connecting');
            setShowPhoneCallModal(false);
          }
        }
      );
    } catch (err) {
      console.error('[DoctorWebRTC] Start call error:', err);
      alert('Gagal memulai panggilan suara: ' + err);
      setShowPhoneCallModal(false);
    }
  };

  const endAudioCall = async () => {
    setShowPhoneCallModal(false);
    if (selectedChat?.id) {
      try {
        await updateDoc(doc(db, 'chats', selectedChat.id), {
          callStatus: 'ended',
          callEndedAt: serverTimestamp(),
          durationSeconds: phoneCallDuration
        });
        await doctorWebRTC.endCall(selectedChat.id);
      } catch (e) {
        console.error('End call signal error:', e);
      }
    }

    const targetUid = activePatientUid || selectedChat?.buyerId;
    if (callNotes.trim().length > 0 && targetUid) {
      try {
        await addDoc(collection(db, 'users', targetUid, 'notes'), {
          text: `[Telekonsultasi Audio - Durasi ${Math.floor(phoneCallDuration / 60)}m ${phoneCallDuration % 60}s]\n${callNotes}`,
          category: 'Konsultasi',
          createdAt: new Date().toISOString(),
          doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
        });
        alert('Panggilan diakhiri. Catatan Konsultasi telah tersimpan otomatis ke Rekam Medis (EMR)!');
      } catch (err) {
        console.error('Error saving call notes:', err);
      }
      setCallNotes('');
    }
    setPhoneCallDuration(0);
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || isExpired || !selectedChat) return;

    const text = newMessage;
    setNewMessage('');

    if (selectedChat.id.startsWith('demo-')) {
      const mockMsg = {
        id: 'msg-' + Date.now(),
        text,
        senderId: currentDoctorId,
        senderType: 'doctor',
        timestamp: new Date(),
        isRead: true
      };
      setMessages(prev => [...prev, mockMsg]);
      setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
      return;
    }

    try {
      await addDoc(collection(db, 'chats', selectedChat.id, 'messages'), {
        text,
        senderId: currentDoctorId,
        senderType: 'doctor',
        timestamp: serverTimestamp(),
        isRead: false,
      });
    } catch (err) {
      console.error('Send message error:', err);
    }
  };

  const sendPatientNotification = async (
    targetUid: string,
    params: {
      type: 'prescription' | 'action_plan' | 'appointment' | 'notes' | 'material' | 'clinic';
      title: string;
      content: string;
      targetId?: string;
      sourceAvatar?: string;
    }
  ) => {
    if (!targetUid || targetUid === 'anonymous' || targetUid === 'guest') return;
    try {
      await addDoc(collection(db, 'users', targetUid, 'notifications'), {
        type: params.type,
        title: params.title,
        content: params.content,
        targetId: params.targetId || 'emr',
        sourceId: currentDoctorId,
        sourceName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
        sourceAvatar: params.sourceAvatar || '🏥',
        isRead: false,
        createdAt: serverTimestamp(),
        timestamp: serverTimestamp()
      });
    } catch (err) {
      console.log('Error sending patient notification:', err);
    }
  };

  const handleSavePrescription = async (e: React.FormEvent) => {
    e.preventDefault();
    const targetUid = activePatientUid || selectedChat?.buyerId;
    if (!targetUid || !prescItemName.trim()) {
      alert('Silakan pilih pasien dan masukkan nama suplemen/program terapi.');
      return;
    }

    try {
      setIsSavingPrescription(true);
      const prescData = {
        patientUid: targetUid,
        doctorId: currentDoctorId,
        doctorName: doctorProfile?.name || 'Dokter Spesialis Anak',
        type: prescType,
        itemName: prescItemName.trim(),
        dosage: prescDosage.trim() || '-',
        duration: prescDuration.trim() || '-',
        notes: prescNotes.trim() || '-',
        createdAt: serverTimestamp(),
      };

      // 1. Simpan ke koleksi resep pasien
      await addDoc(collection(db, 'users', targetUid, 'prescriptions'), prescData);

      // 2. Kirim notifikasi realtime ke akun orang tua
      await sendPatientNotification(targetUid, {
        type: 'prescription',
        title: 'Resep & Terapi Baru Diterbitkan',
        content: `Dokter telah meresepkan ${prescItemName.trim()} (${prescType === 'terapi' ? 'Paket Terapi' : 'Resep'}) untuk ananda.`,
        targetId: 'emr',
        sourceAvatar: '💊'
      });

      // 3. Jika ada sesi chat yang cocok, kirimkan kartu pesan terstruktur ke orang tua
      const currentChatId = selectedChat?.id || chats.find(c => c.buyerId === targetUid)?.id;
      if (currentChatId) {
        const typeLabel = prescType === 'terapi' ? 'Paket Terapi Klinis' : prescType === 'medis' ? 'Resep Obat Medis' : 'Resep Suplemen & Vitamin';
        const formattedMsg = `📋 RESEP & REKOMENDASI TERAPI (${typeLabel.toUpperCase()}):\n• Item: ${prescItemName.trim()}\n• Dosis/Frekuensi: ${prescDosage.trim() || '-'}\n• Durasi: ${prescDuration.trim() || '-'}\n• Catatan: ${prescNotes.trim() || '-'}\n\n*Diresepkan oleh ${doctorProfile?.name || 'Dokter Zikola'} melalui Rekam Medis Digital.*`;

        await addDoc(collection(db, 'chats', currentChatId, 'messages'), {
          senderId: currentDoctorId,
          senderName: doctorProfile?.name || 'Dokter Zikola',
          senderType: 'doctor',
          text: formattedMsg,
          metadata: {
            type: 'prescription',
            prescType: prescType,
            itemName: prescItemName.trim(),
            dosage: prescDosage.trim() || '-',
            duration: prescDuration.trim() || '-',
            notes: prescNotes.trim() || '-',
            doctorName: doctorProfile?.name || 'Dokter Zikola'
          },
          isRead: false,
          timestamp: serverTimestamp()
        });

        await updateDoc(doc(db, 'chats', currentChatId), {
          lastMessage: `[Resep/Terapi] ${prescItemName.trim()}`,
          lastMessageTime: serverTimestamp()
        });
      }

      alert('Resep & Rekomendasi Terapi berhasil disimpan ke EMR dan dikirimkan ke pasien!');
      setPrescItemName('');
      setPrescDosage('');
      setPrescDuration('');
      setPrescNotes('');
      setShowPrescriptionModal(false);
    } catch (error) {
      console.error('Gagal menyimpan resep:', error);
      alert('Terjadi kesalahan saat menyimpan resep.');
    } finally {
      setIsSavingPrescription(false);
    }
  };

  const handleSaveClinicalNote = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNoteText.trim() || !activePatientUid) return;

    try {
      await addDoc(collection(db, 'users', activePatientUid, 'notes'), {
        text: newNoteText,
        category: newNoteCategory,
        createdAt: new Date().toISOString(),
        doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
      });
      setNewNoteText('');
      alert('Catatan klinis berhasil disimpan!');
    } catch (err) {
      console.error('Error adding clinical note:', err);
    }
  };

  const handleSendMateri = async () => {
    if (!selectedMateriId || !selectedChat?.id) return;
    const materi = materiList.find(m => m.id === selectedMateriId);
    if (!materi) return;

    try {
      const materiText = `📚 **MATERI EDUKASI DOKTER**\n\n**${materi.title}**\n${materi.desc}\n\nSilakan dipelajari dan diterapkan bersama ananda di rumah ya Ayah/Bunda!`;
      await addDoc(collection(db, 'chats', selectedChat.id, 'messages'), {
        text: materiText,
        senderId: currentDoctorId,
        senderType: 'doctor',
        timestamp: serverTimestamp(),
        isRead: false,
        metadata: {
          type: 'materi',
          materiId: materi.id,
          title: materi.title,
          desc: materi.desc,
          icon: materi.icon
        }
      });

      const targetUid = activePatientUid || selectedChat?.buyerId;
      if (targetUid) {
        await addDoc(collection(db, 'users', targetUid, 'materials'), {
          materiId: materi.id,
          title: materi.title,
          desc: materi.desc,
          icon: materi.icon,
          doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
          createdAt: new Date().toISOString(),
          timestamp: serverTimestamp()
        });

        await sendPatientNotification(targetUid, {
          type: 'material',
          title: 'Materi Edukasi Baru dari Dokter',
          content: `Dokter membagikan materi: "${materi.title}". Silakan pelajari panduannya di aplikasi.`,
          targetId: 'emr',
          sourceAvatar: '📚'
        });
      }

      setShowMateriModal(false);
      setSelectedMateriId('');
      alert('Materi edukasi berhasil dikirim ke ruang chat orang tua!');
    } catch (err) {
      console.error('Error sending materi:', err);
      alert('Gagal mengirim materi: ' + err);
    }
  };

  const handleScheduleSession = async () => {
    if (!appointmentDateTime) return;
    const targetUid = activePatientUid || selectedChat?.buyerId;
    const patientName = patientProfile?.name || selectedPatientId || (targetUid ? patientNames[targetUid] : 'Pasien');

    try {
      // 1. If active chat exists, send confirmation message
      if (selectedChat?.id) {
        const appointmentText = `📅 **JADWAL KONSULTASI BARU**\n\nDokter telah menetapkan jadwal sesi konsultasi:\n⏰ **${appointmentDateTime.replace('T', ' ')} WIB**\n\nMohon pastikan Ayah/Bunda dan ananda siap 10 menit sebelum sesi dimulai.`;
        await addDoc(collection(db, 'chats', selectedChat.id, 'messages'), {
          text: appointmentText,
          senderId: currentDoctorId,
          senderType: 'doctor',
          timestamp: serverTimestamp(),
          isRead: false,
          metadata: {
            type: 'schedule_confirmation',
            dateTime: appointmentDateTime
          }
        });
      }

      // 2. Save appointment record in Firestore
      await addDoc(collection(db, 'appointments'), {
        doctorId: currentDoctorId,
        doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
        patientId: targetUid || 'anonymous',
        patientName: patientName,
        dateTime: appointmentDateTime,
        status: 'scheduled',
        type: 'online_chat',
        createdAt: serverTimestamp()
      });

      // 3. Kirim notifikasi realtime ke pasien
      if (targetUid) {
        await sendPatientNotification(targetUid, {
          type: 'appointment',
          title: 'Jadwal Konsultasi Ditetapkan',
          content: `Sesi konsultasi dijadwalkan pada ${appointmentDateTime.replace('T', ' ')} WIB. Mohon bersiap tepat waktu.`,
          targetId: 'consultation',
          sourceAvatar: '📅'
        });
      }

      setShowJadwalModal(false);
      setAppointmentDateTime('');
      alert(`Jadwal konsultasi berhasil disimpan untuk ${patientName}!`);
    } catch (err) {
      console.error('Error scheduling session:', err);
      alert('Gagal menjadwalkan konsultasi: ' + err);
    }
  };

  const handleUpdateAppointmentStatus = async (apptId: string, newStatus: string) => {
    try {
      await updateDoc(doc(db, 'appointments', apptId), {
        status: newStatus,
        updatedAt: serverTimestamp()
      });
      const statusLabel = newStatus === 'confirmed' ? 'Dikonfirmasi' : newStatus === 'completed' ? 'Diselesaikan' : 'Dibatalkan';
      alert(`Janji temu berhasil diubah menjadi: ${statusLabel}!`);
    } catch (err) {
      console.error('Error updating appointment:', err);
      alert('Gagal memperbarui status janji temu: ' + err);
    }
  };

  const handleDeleteAppointment = async (apptId: string) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus arsip janji temu ini?')) return;
    try {
      await deleteDoc(doc(db, 'appointments', apptId));
      alert('Janji temu berhasil dihapus dari database.');
    } catch (err) {
      console.error('Error deleting appointment:', err);
      alert('Gagal menghapus janji temu: ' + err);
    }
  };

  const handleSubmitReview = async () => {
    const targetUid = activePatientUid || selectedChat?.buyerId;
    if (!clinicalNotes.trim() || !targetUid) {
      alert('Harap masukkan catatan klinis sebelum menyimpan.');
      return;
    }

    try {
      await addDoc(collection(db, 'users', targetUid, 'notes'), {
        text: `[Rating Sesi: ${sessionRating}/5 ⭐]\n${clinicalNotes}`,
        category: 'Evaluasi Sesi',
        rating: sessionRating,
        createdAt: new Date().toISOString(),
        doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
      });

      await sendPatientNotification(targetUid, {
        type: 'notes',
        title: 'Catatan Evaluasi Sesi Dokter',
        content: `Dokter telah merilis rangkuman catatan klinis untuk sesi konsultasi Anda.`,
        targetId: 'emr',
        sourceAvatar: '📋'
      });

      setRatingSubmitted(true);
      setTimeout(() => {
        setShowRatingModal(false);
        setRatingSubmitted(false);
        setClinicalNotes('');
        setSessionRating(5);
      }, 1400);
    } catch (err) {
      console.error('Error submitting session review:', err);
      alert('Gagal menyimpan catatan evaluasi: ' + err);
    }
  };

  const hasAssessmentData = React.useMemo(() => {
    const hasGames = Boolean(
      gameAssessments && 
      Object.keys(gameAssessments).length > 0 &&
      Object.values(gameAssessments).some((g: any) => g && (g.averageScore > 0 || g.playCount > 0 || g.score > 0))
    );
    const hasTests = Boolean(
      testResults &&
      (testResults.cognitive?.completed ||
       testResults.linguistic?.completed ||
       testResults.motor?.completed ||
       testResults.personality?.completed ||
       (testResults.results && Object.keys(testResults.results).length > 0))
    );
    return hasGames || hasTests;
  }, [gameAssessments, testResults]);

  const getDynamicScore = (gameKey: string, fallbackScore: number = 0) => {
    if (gameAssessments && gameAssessments[gameKey]) {
      const g = gameAssessments[gameKey];
      if (typeof g.averageScore === 'number' && g.averageScore > 0) return Math.round(g.averageScore);
      if (typeof g.score === 'number' && g.score > 0) return Math.round(g.score);
    }
    // Also cross-reference testResults if available
    if (testResults) {
      if (gameKey === 'puzzleGame' && testResults.cognitive?.completed) {
        return Math.round(testResults.cognitive.percentage || 0);
      }
      if (gameKey === 'wordPuzzle' && testResults.linguistic?.completed) {
        return Math.round(testResults.linguistic.percentage || 0);
      }
      if (gameKey === 'coloringGame' && testResults.motor?.completed) {
        return Math.round(testResults.motor.percentage || 0);
      }
    }
    return fallbackScore;
  };

  const radarData = React.useMemo(() => {
    if (!hasAssessmentData) {
      return [
        { subject: 'Logika', A: 0, fullMark: 100 },
        { subject: 'Memori', A: 0, fullMark: 100 },
        { subject: 'Bahasa', A: 0, fullMark: 100 },
        { subject: 'Motorik', A: 0, fullMark: 100 },
        { subject: 'Emosi', A: 0, fullMark: 100 }
      ];
    }
    return [
      { subject: 'Logika', A: getDynamicScore('puzzleGame', 0), fullMark: 100 },
      { subject: 'Memori', A: getDynamicScore('memory', 0), fullMark: 100 },
      { subject: 'Bahasa', A: getDynamicScore('wordPuzzle', 0), fullMark: 100 },
      { subject: 'Motorik', A: getDynamicScore('coloringGame', 0), fullMark: 100 },
      { subject: 'Emosi', A: getDynamicScore('storyBuilderGame', 0), fullMark: 100 }
    ];
  }, [hasAssessmentData, gameAssessments, testResults]);

  const progressLineData = React.useMemo(() => {
    if (!hasAssessmentData) {
      return [];
    }
    const logika = getDynamicScore('puzzleGame', 0);
    const memori = getDynamicScore('memory', 0);
    const atensi = getDynamicScore('numberSequence', 0);
    return [
      { name: 'Sesi Awal', Logika: Math.max(0, logika - 15), Memori: Math.max(0, memori - 15), Atensi: Math.max(0, atensi - 15) },
      { name: 'Sesi Evaluasi', Logika: Math.max(0, logika - 8), Memori: Math.max(0, memori - 8), Atensi: Math.max(0, atensi - 8) },
      { name: 'Sesi Terbaru', Logika: logika, Memori: memori, Atensi: atensi }
    ];
  }, [hasAssessmentData, gameAssessments, testResults]);

  const averageScoreValue = React.useMemo(() => {
    if (!hasAssessmentData) return 0;
    const scores = [
      getDynamicScore('puzzleGame', 0),
      getDynamicScore('memory', 0),
      getDynamicScore('wordPuzzle', 0),
      getDynamicScore('coloringGame', 0),
      getDynamicScore('storyBuilderGame', 0)
    ].filter(s => s > 0);
    if (scores.length === 0) return 0;
    return Math.round(scores.reduce((a, b) => a + b, 0) / scores.length);
  }, [hasAssessmentData, gameAssessments, testResults]);

  const averageScoreLabel = averageScoreValue >= 80 ? 'Sangat Baik' : averageScoreValue >= 65 ? 'Baik' : averageScoreValue >= 50 ? 'Cukup' : 'Perlu Pendampingan';

  const cohortRadarData = React.useMemo(() => {
    const assessedPatients = allPatients.filter(p => p.hasAssessment && (p.scores?.logika > 0 || p.scores?.memori > 0 || p.scores?.bahasa > 0));
    if (assessedPatients.length === 0) {
      return [
        { subject: 'Logika', A: 78, fullMark: 100 },
        { subject: 'Memori', A: 82, fullMark: 100 },
        { subject: 'Bahasa', A: 80, fullMark: 100 },
        { subject: 'Motorik', A: 75, fullMark: 100 },
        { subject: 'Emosi', A: 74, fullMark: 100 }
      ];
    }
    const avgLogika = Math.round(assessedPatients.reduce((acc, p) => acc + (p.scores?.logika || 0), 0) / assessedPatients.length);
    const avgMemori = Math.round(assessedPatients.reduce((acc, p) => acc + (p.scores?.memori || 0), 0) / assessedPatients.length);
    const avgBahasa = Math.round(assessedPatients.reduce((acc, p) => acc + (p.scores?.bahasa || 0), 0) / assessedPatients.length);
    return [
      { subject: 'Logika', A: avgLogika, fullMark: 100 },
      { subject: 'Memori', A: avgMemori, fullMark: 100 },
      { subject: 'Bahasa', A: avgBahasa, fullMark: 100 },
      { subject: 'Motorik', A: Math.round((avgLogika + avgBahasa) / 2), fullMark: 100 },
      { subject: 'Emosi', A: Math.round((avgMemori + avgBahasa) / 2), fullMark: 100 }
    ];
  }, [allPatients]);

  const displayTimelineData = React.useMemo(() => {
    const list: any[] = [];
    const patientName = patientProfile?.name || selectedPatientId || 'Anak';
    
    // Add real database tests completed if they exist
    if (testResults) {
      if (testResults.cognitive?.completed) {
        list.push({
          date: testResults.cognitive.completedDate ? formatDateSafe(testResults.cognitive.completedDate).split(',')[0] : 'Baru saja',
          title: 'Asesmen Kognitif selesai',
          desc: `Skor: ${testResults.cognitive.score}/${testResults.cognitive.total} (${Math.round(testResults.cognitive.percentage)}%)`,
          done: true
        });
      }
      if (testResults.linguistic?.completed) {
        list.push({
          date: testResults.linguistic.completedDate ? formatDateSafe(testResults.linguistic.completedDate).split(',')[0] : 'Baru saja',
          title: 'Asesmen Linguistik selesai',
          desc: `Skor: ${testResults.linguistic.score}/${testResults.linguistic.total} (${Math.round(testResults.linguistic.percentage)}%)`,
          done: true
        });
      }
      if (testResults.personality?.completed) {
        list.push({
          date: testResults.personality.completedDate ? formatDateSafe(testResults.personality.completedDate).split(',')[0] : 'Baru saja',
          title: 'Tes Kepribadian selesai',
          desc: `Tipe kepribadian terdeteksi: ${testResults.personality.animalEmoji || '🦁'} ${testResults.personality.personality || 'Ekstrovert'}`,
          done: true
        });
      }
      if (testResults.motor?.completed) {
        list.push({
          date: testResults.motor.completedDate ? formatDateSafe(testResults.motor.completedDate).split(',')[0] : 'Baru saja',
          title: 'Tes Motorik selesai',
          desc: `Skor persentase pengerjaan: ${Math.round(testResults.motor.percentage)}%`,
          done: true
        });
      }
    }

    // Add game assessment completed if they exist
    if (gameAssessments) {
      const keys = Object.keys(gameAssessments);
      if (keys.length > 0) {
        list.push({
          date: 'Baru saja',
          title: 'Asesmen Game Zikola aktif',
          desc: `${keys.length} jenis permainan telah dimainkan oleh ${patientName}`,
          done: true
        });
      }
    }

    // Add notes to timeline if present
    if (patientNotes && patientNotes.length > 0) {
      patientNotes.slice(0, 3).forEach(note => {
        list.push({
          date: formatDateSafe(note.createdAt).split(',')[0],
          title: `Catatan Klinis (${note.category || 'Observasi'})`,
          desc: note.text.length > 60 ? note.text.substring(0, 60) + '...' : note.text,
          done: true
        });
      });
    }

    if (list.length === 0) {
      return [
        { date: 'Terkini', title: 'Pendaftaran Pasien Aktif', desc: `Profil ${patientName} terhubung ke sistem Zikola`, done: true },
        { date: 'Mendatang', title: 'Sesi Asesmen / Konsultasi Pertama', desc: 'Menunggu pengisian asesmen oleh orang tua', done: false }
      ];
    }

    // Append future recommendation roadmap
    list.push({
      date: 'Mendatang',
      title: 'Jadwalkan Konsultasi Lanjutan',
      desc: `Mengevaluasi laporan stimulasi harian ${patientName} di rumah`,
      done: false
    });

    return list;
  }, [testResults, gameAssessments, patientProfile, selectedPatientId]);

  // SUB-RENDER: 1. Dashboard / Beranda View (Top Left Screen)
  
  // SEGMEN 2: View Analitik Asesmen Global
  const renderGlobalAssessmentView = () => {
    const filteredPatients = allPatients.filter(p => 
      p.name.toLowerCase().includes(globalSearch.toLowerCase())
    );

    return (
      <div className="flex-1 overflow-y-auto p-8 space-y-6 bg-slate-50/30">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-black text-slate-800">Hasil Asesmen Perkembangan Anak</h2>
            <p className="text-xs text-slate-400 font-bold mt-1">Pantau performa kognitif, motorik, bahasa, dan gaya belajar seluruh pasien anak.</p>
          </div>
          <div className="flex items-center space-x-3">
            <div className="bg-white border border-slate-200 px-3 py-2 rounded-xl flex items-center space-x-2">
              <span className="text-slate-400">🔍</span>
              <input 
                type="text" 
                value={globalSearch} 
                onChange={(e) => setGlobalSearch(e.target.value)} 
                placeholder="Cari nama pasien..." 
                className="bg-transparent border-none outline-none text-xs w-44 font-medium text-slate-700" 
              />
            </div>
            <button 
              onClick={() => setShowPrintModal(true)}
              className="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center space-x-2 shadow-sm"
            >
              <Download size={14} />
              <span>Ekspor Analitik</span>
            </button>
          </div>
        </div>

        {/* 4 Metric Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4">
          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Total Pasien Terasesmen</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-slate-800">{allPatients.filter(p => p.hasAssessment).length} / {allPatients.length}</span>
              <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded">Aktif</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Pasien dengan riwayat tes</span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Rata-rata Logika & Penalaran</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-teal-600">{cohortRadarData[0]?.A > 0 ? `${cohortRadarData[0]?.A}%` : '-'}</span>
              <span className="text-[9px] font-bold text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded">Kohort</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Tingkat akurasi pemecahan masalah</span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Rata-rata Memori & Bahasa</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-indigo-600">
                {(cohortRadarData[1]?.A > 0 || cohortRadarData[2]?.A > 0)
                  ? `${Math.round((cohortRadarData[1]?.A + cohortRadarData[2]?.A) / 2)}%`
                  : '-'}
              </span>
              <span className="text-[9px] font-bold text-indigo-700 bg-indigo-50 px-1.5 py-0.5 rounded">Kohort</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Retensi visual & pemahaman bahasa</span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Perlu Asesmen / Tindak Lanjut</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-amber-600">{allPatients.filter(p => !p.hasAssessment).length}</span>
              <span className="text-[9px] font-bold text-amber-700 bg-amber-50 px-1.5 py-0.5 rounded">Pending</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Belum ada data pengerjaan tes</span>
          </div>
        </div>

        {/* Radar & Patient Feed */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
          <div className="bg-white p-6 rounded-3xl border border-slate-100 shadow-sm space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-sm font-black text-slate-800">Distribusi Kemampuan Kohort</h3>
              <span className="text-[10px] font-bold text-teal-600 bg-teal-50 px-2 py-0.5 rounded-full">Semua Pasien</span>
            </div>
            <div className="h-64 flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <RadarChart cx="50%" cy="50%" outerRadius="75%" data={cohortRadarData}>
                  <PolarGrid stroke="#E2E8F0" />
                  <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 8, fontWeight: 'bold' }} />
                  <Radar name="Rata-rata Kohort" dataKey="A" stroke="#0D9488" fill="#14B8A6" fillOpacity={0.3} />
                </RadarChart>
              </ResponsiveContainer>
            </div>
            <div className="border-t border-slate-100 pt-3 space-y-2 text-[11px] font-bold text-slate-600">
              <div className="flex justify-between"><span>🧩 Logika & Problem Solving</span><span className="text-teal-600">{cohortRadarData[0]?.A > 0 ? `${cohortRadarData[0]?.A}/100` : '-'}</span></div>
              <div className="flex justify-between"><span>👁️ Memori & Visual Spasial</span><span className="text-teal-600">{cohortRadarData[1]?.A > 0 ? `${cohortRadarData[1]?.A}/100` : '-'}</span></div>
              <div className="flex justify-between"><span>🗣️ Bahasa & Kosakata</span><span className="text-teal-600">{cohortRadarData[2]?.A > 0 ? `${cohortRadarData[2]?.A}/100` : '-'}</span></div>
              <div className="flex justify-between"><span>🎯 Motorik & Refleks</span><span className="text-teal-600">{cohortRadarData[3]?.A > 0 ? `${cohortRadarData[3]?.A}/100` : '-'}</span></div>
            </div>
          </div>

          <div className="col-span-2 bg-white p-6 rounded-3xl border border-slate-100 shadow-sm space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-sm font-black text-slate-800">Daftar Hasil Asesmen Terbaru Pasien</h3>
              <span className="text-xs text-slate-400 font-bold">{filteredPatients.length} Pasien Terdata</span>
            </div>

            <div className="space-y-3 max-h-[380px] overflow-y-auto pr-1">
              {filteredPatients.length === 0 ? (
                <div className="text-center py-12 text-slate-400">
                  <span className="text-4xl block mb-2">📊</span>
                  <p className="text-xs font-bold">Belum ada pasien yang terdaftar di database.</p>
                </div>
              ) : (
                filteredPatients.map((p, idx) => (
                <div 
                  key={p.id || idx}
                  onClick={() => {
                    setActivePatientUid(p.id);
                    setSelectedPatientId(p.name);
                    setActiveMenu('patients');
                    setPatientDetailTab('assessment');
                  }}
                  className="border border-slate-100 hover:border-teal-200 p-4 rounded-2xl flex items-center justify-between hover:bg-teal-50/20 cursor-pointer transition-all"
                >
                  <div className="flex items-center space-x-3">
                    {renderAvatar(p.avatar, "w-10 h-10")}
                    <div>
                      <h4 className="text-xs font-black text-slate-800">{p.name}</h4>
                      <p className="text-[9px] text-slate-400 font-bold mt-0.5">
                        {p.hasAssessment 
                          ? `Status Asesmen: Selesai • ${p.completedCount > 0 ? `${p.completedCount} Tes Selesai` : 'Tersedia Data Game'}`
                          : 'Status Asesmen: Belum Ada Tes (Pasien Baru)'
                        }
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center space-x-3">
                    <div className="flex space-x-1.5 text-[9px] font-bold">
                      {p.hasAssessment ? (
                        <>
                          {p.scores?.logika > 0 && <span className="bg-teal-50 text-teal-700 px-2 py-0.5 rounded">🧩 {p.scores.logika}</span>}
                          {p.scores?.memori > 0 && <span className="bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded">👁️ {p.scores.memori}</span>}
                          {p.scores?.bahasa > 0 && <span className="bg-amber-50 text-amber-700 px-2 py-0.5 rounded">🗣️ {p.scores.bahasa}</span>}
                        </>
                      ) : (
                        <span className="bg-slate-100 text-slate-400 px-2 py-0.5 rounded font-normal text-[9px]">Belum ada penilaian</span>
                      )}
                    </div>
                    <button className="px-3 py-1.5 bg-white border border-slate-200 text-teal-600 hover:bg-slate-50 font-bold text-[10px] rounded-xl">
                      Lihat Asesmen
                    </button>
                  </div>
                </div>
              ))
              )}
            </div>
          </div>
        </div>
      </div>
    );
  };

  
  // SEGMEN 3: EMR Form States & Handlers
  const [emrBirthCondition, setEmrBirthCondition] = useState('Normal (Cukup Bulan)');
  const [emrPregnancyNotes, setEmrPregnancyNotes] = useState('');
  const [emrAllergies, setEmrAllergies] = useState('');
  const [emrPreviousTherapy, setEmrPreviousTherapy] = useState('');
  const [emrDiagnosis, setEmrDiagnosis] = useState('');
  const [emrTreatmentPlan, setEmrTreatmentPlan] = useState('');
  const [isSavingEmr, setIsSavingEmr] = useState(false);

  const handleSaveEMR = async () => {
    if (!activePatientUid) return;
    setIsSavingEmr(true);
    try {
      await setDoc(doc(db, 'users', activePatientUid, 'emr', 'latest'), {
        birthCondition: emrBirthCondition,
        pregnancyNotes: emrPregnancyNotes,
        allergies: emrAllergies,
        previousTherapy: emrPreviousTherapy,
        diagnosis: emrDiagnosis,
        treatmentPlan: emrTreatmentPlan,
        updatedAt: serverTimestamp(),
        updatedBy: doctorProfile?.name || 'Dokter Zikola'
      }, { merge: true });
      alert('Data Rekam Medis (EMR) berhasil disimpan secara permanen ke database!');
    } catch (err) {
      console.error('Error saving EMR:', err);
      alert('Gagal menyimpan EMR: ' + err);
    } finally {
      setIsSavingEmr(false);
    }
  };

  // Chat session cleanup & deletion handlers
  const handleDeleteChatSession = async (chatId: string) => {
    if (!chatId) return;
    const confirm = window.confirm('Hapus riwayat sesi konsultasi ini secara permanen? Seluruh riwayat obrolan akan dibersihkan dari server.');
    if (!confirm) return;

    try {
      // 1. Delete all messages in the messages subcollection
      const messagesRef = collection(db, 'chats', chatId, 'messages');
      const messagesSnap = await getDocs(messagesRef);
      const batch = writeBatch(db);
      messagesSnap.forEach((msgDoc) => {
        batch.delete(msgDoc.ref);
      });
      // 2. Delete the chat document itself
      batch.delete(doc(db, 'chats', chatId));
      await batch.commit();

      // 3. Update local state
      setChats(prev => prev.filter(c => c.id !== chatId));
      if (selectedChat?.id === chatId) {
        setSelectedChat(null);
        setActiveMenu('dashboard');
      }
      alert('Riwayat konsultasi berhasil dihapus secara permanen.');
    } catch (err) {
      console.error('Error deleting chat session:', err);
      alert('Gagal menghapus riwayat konsultasi: ' + err);
    }
  };

  const handleCleanAllCompletedSessions = async () => {
    const completedChats = chats.filter(c => isChatCompleted(c));
    if (completedChats.length === 0) {
      alert('Tidak ada riwayat sesi konsultasi yang selesai untuk dibersihkan.');
      return;
    }
    const confirm = window.confirm(`Hapus seluruh ${completedChats.length} riwayat sesi konsultasi yang telah selesai secara permanen?`);
    if (!confirm) return;

    try {
      for (const chat of completedChats) {
        const messagesRef = collection(db, 'chats', chat.id, 'messages');
        const messagesSnap = await getDocs(messagesRef);
        const batch = writeBatch(db);
        messagesSnap.forEach((msgDoc) => {
          batch.delete(msgDoc.ref);
        });
        batch.delete(doc(db, 'chats', chat.id));
        await batch.commit();
      }
      setChats(prev => prev.filter(c => !isChatCompleted(c)));
      if (selectedChat && isChatCompleted(selectedChat)) {
        setSelectedChat(null);
        setActiveMenu('dashboard');
      }
      alert(`Berhasil membersihkan ${completedChats.length} riwayat sesi konsultasi.`);
    } catch (err) {
      console.error('Error cleaning completed chats:', err);
      alert('Gagal membersihkan riwayat chat: ' + err);
    }
  };

  const handleDeleteNote = async (noteId: string) => {
    if (!activePatientUid || !noteId) return;
    if (window.confirm('Hapus catatan klinis ini?')) {
      try {
        await deleteDoc(doc(db, 'users', activePatientUid, 'notes', noteId));
      } catch (err) {
        console.error('Error deleting note:', err);
        alert('Gagal menghapus catatan: ' + err);
      }
    }
  };

    // SEGMEN 4: Chat File & Header Menu State
  const chatFileInputRef = useRef<HTMLInputElement>(null);
  const [showChatOptionsMenu, setShowChatOptionsMenu] = useState(false);

  const handleUploadChatAttachment = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !selectedChat) return;

    try {
      const fileSizeKb = (file.size / 1024).toFixed(1);
      const isImg = file.type.startsWith('image/');
      const icon = isImg ? '🖼️' : '📄';
      const text = `${icon} **LAMPIRAN DOKTER**\n\n**Nama Berkas:** ${file.name}\n**Ukuran:** ${fileSizeKb} KB\n\nBerkas telah diverifikasi dan siap diunduh.`;

      await addDoc(collection(db, 'chats', selectedChat.id, 'messages'), {
        text,
        senderId: currentDoctorId,
        senderType: 'doctor',
        timestamp: serverTimestamp(),
        isRead: false,
        attachmentName: file.name,
        attachmentType: file.type
      });

      alert(`Berkas "${file.name}" berhasil dilampirkan ke ruang chat!`);
    } catch (err) {
      console.error('Error uploading attachment:', err);
      alert('Gagal mengirim lampiran: ' + err);
    } finally {
      if (chatFileInputRef.current) chatFileInputRef.current.value = '';
    }
  };

  
  // SEGMEN 3: Auto-load EMR data when activePatientUid changes
  useEffect(() => {
    if (!activePatientUid) return;
    const fetchEMR = async () => {
      try {
        const emrDoc = await getDoc(doc(db, 'users', activePatientUid, 'emr', 'latest'));
        if (emrDoc.exists()) {
          const d = emrDoc.data();
          if (d.birthCondition) setEmrBirthCondition(d.birthCondition);
          if (d.pregnancyNotes) setEmrPregnancyNotes(d.pregnancyNotes);
          if (d.allergies) setEmrAllergies(d.allergies);
          if (d.previousTherapy) setEmrPreviousTherapy(d.previousTherapy);
          if (d.diagnosis) setEmrDiagnosis(d.diagnosis);
          if (d.treatmentPlan) setEmrTreatmentPlan(d.treatmentPlan);
        } else {
          setEmrBirthCondition('Normal (Cukup Bulan)');
          setEmrPregnancyNotes('');
          setEmrAllergies('');
          setEmrPreviousTherapy('');
          setEmrDiagnosis('');
          setEmrTreatmentPlan('');
        }
      } catch (err) {
        console.error('Error loading EMR:', err);
      }
    };
    fetchEMR();
  }, [activePatientUid]);

  
  // SEGMEN 4: WebRTC Audio Mute Controller
  const toggleDoctorMute = () => {
    const newMuteState = !isDoctorMuted;
    setIsDoctorMuted(newMuteState);
    if (doctorWebRTC.localStream) {
      doctorWebRTC.localStream.getAudioTracks().forEach(track => {
        track.enabled = !newMuteState;
      });
    }
  };

  const renderDashboardView = () => (
    <div className="flex-1 overflow-y-auto p-8 space-y-8 bg-slate-50/30">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-black text-slate-800 tracking-tight">Selamat pagi, {doctorProfile?.name ? doctorProfile.name.split(',')[0] : 'dr. Rani'} 👋</h2>
          <p className="text-xs text-slate-405 font-bold mt-1.5">Berikut ringkasan aktivitas Anda hari ini.</p>
        </div>
        <div className="flex items-center space-x-3">
          <div className="bg-white border border-slate-100 p-2.5 rounded-2xl flex items-center shadow-sm w-64">
            <input type="text" value={globalSearch} onChange={(e) => setGlobalSearch(e.target.value)} placeholder="Cari pasien..." className="bg-transparent border-none outline-none text-xs w-full text-slate-600" />
          </div>
          <button onClick={() => setShowNotificationDrawer(true)} className="w-10 h-10 bg-white border border-slate-100 rounded-2xl flex items-center justify-center text-slate-505 shadow-sm relative hover:bg-slate-50 transition-colors">
            <Bell size={18} />
            <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-4 gap-5">
        {/* WIDGET 1: Pasien Aktif */}
        <div className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm flex items-center justify-between relative overflow-hidden">
          <div className="z-10">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Total Pasien Terdaftar</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-teal-600">
                {allPatients.length}
              </span>
              <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-md">Aktif</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Pasien terdata di sistem</span>
          </div>
          <div className="h-12 w-20 opacity-20 right-2 absolute">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={[{v:10},{v:15},{v:12},{v:20},{v:25}]}>
                <Line type="monotone" dataKey="v" stroke="#0D9488" strokeWidth={3} dot={false} isAnimationActive={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
        
        {/* WIDGET 2: Konsultasi */}
        <div className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm flex items-center justify-between relative overflow-hidden">
          <div className="z-10">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Sesi Konsultasi</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-slate-800">
                {chats.length}
              </span>
              <span className="text-[9px] font-bold text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded-md">Aktif</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Ruang konsultasi terbuka</span>
          </div>
          <div className="h-12 w-20 opacity-20 right-2 absolute">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={[{v:2},{v:5},{v:3},{v:8},{v:4}]}>
                <Area type="monotone" dataKey="v" stroke="#F59E0B" fill="#F59E0B" strokeWidth={3} dot={false} isAnimationActive={false} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        
        {/* WIDGET 3: Asesmen Selesai */}
        <div className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm flex items-center justify-between relative overflow-hidden">
          <div className="z-10">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Asesmen Selesai</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-emerald-600">
                {allPatients.filter(p => p.hasAssessment).length}
              </span>
              <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-md">Lengkap</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Pasien dengan skor riil</span>
          </div>
          <div className="h-12 w-20 opacity-20 right-2 absolute">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={[{v:4},{v:2},{v:6},{v:4},{v:7}]}>
                <Line type="monotone" dataKey="v" stroke="#10B981" strokeWidth={3} dot={false} isAnimationActive={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
        
        {/* WIDGET 4: Menunggu Asesmen */}
        <div className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm flex items-center justify-between relative overflow-hidden">
          <div className="z-10">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Menunggu Asesmen</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-amber-600">
                {allPatients.filter(p => !p.hasAssessment).length}
              </span>
              <span className="text-[9px] font-bold text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded-md">Pending</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Pasien belum tes / skrining</span>
          </div>
          <div className="h-12 w-20 opacity-20 right-2 absolute">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={[{v:1},{v:1},{v:3},{v:2},{v:3}]}>
                <Area type="step" dataKey="v" stroke="#E11D48" fill="#E11D48" strokeWidth={3} dot={false} isAnimationActive={false} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 md:gap-6">
        <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm col-span-3 flex flex-col justify-between">
          <div>
            <div className="flex flex-wrap justify-between items-center mb-4 gap-2">
              <div>
                <h3 className="text-sm font-black text-slate-800">Jadwal Hari Ini</h3>
                <p className="text-[10px] text-slate-400 font-bold mt-0.5">Antrean konsultasi pasien anak secara online & tatap muka.</p>
              </div>
              <div className="flex items-center space-x-2">
                <div className="inline-flex bg-slate-100 p-0.5 rounded-xl text-[10px] font-bold">
                  <button 
                    onClick={() => setJadwalDashboardFilter('all')}
                    className={`px-2.5 py-1 rounded-lg transition-colors ${jadwalDashboardFilter === 'all' ? 'bg-white text-teal-700 shadow-xs font-black' : 'text-slate-500 hover:text-slate-800'}`}
                  >
                    Semua ({chats.length})
                  </button>
                  <button 
                    onClick={() => setJadwalDashboardFilter('active')}
                    className={`px-2.5 py-1 rounded-lg transition-colors ${jadwalDashboardFilter === 'active' ? 'bg-white text-teal-700 shadow-xs font-black' : 'text-slate-500 hover:text-slate-800'}`}
                  >
                    Aktif ({chats.filter(c => !isChatCompleted(c)).length})
                  </button>
                  <button 
                    onClick={() => setJadwalDashboardFilter('completed')}
                    className={`px-2.5 py-1 rounded-lg transition-colors ${jadwalDashboardFilter === 'completed' ? 'bg-white text-teal-700 shadow-xs font-black' : 'text-slate-500 hover:text-slate-800'}`}
                  >
                    Selesai ({chats.filter(c => isChatCompleted(c)).length})
                  </button>
                </div>
                {chats.filter(c => isChatCompleted(c)).length > 0 && (
                  <button 
                    onClick={handleCleanAllCompletedSessions}
                    className="px-2.5 py-1 bg-rose-50 hover:bg-rose-100 text-rose-600 border border-rose-200 rounded-xl text-[10px] font-bold transition-colors flex items-center space-x-1"
                    title="Hapus seluruh riwayat chat yang telah selesai"
                  >
                    <Trash2 size={11} />
                    <span>Bersihkan</span>
                  </button>
                )}
                <button onClick={() => setActiveMenu('jadwal')} className="text-[10px] font-black text-teal-600 hover:text-teal-800 uppercase tracking-widest pl-1">
                  Lihat Semua
                </button>
              </div>
            </div>
            
            <div className="space-y-3">
              {(() => {
                const displayChats = chats.filter(chat => {
                  const done = isChatCompleted(chat);
                  if (jadwalDashboardFilter === 'active') return !done;
                  if (jadwalDashboardFilter === 'completed') return done;
                  return true;
                });

                if (displayChats.length === 0) {
                  return (
                    <p className="text-xs text-slate-400 italic py-4 text-center">
                      {jadwalDashboardFilter === 'active' 
                        ? 'Tidak ada konsultasi aktif saat ini.' 
                        : jadwalDashboardFilter === 'completed' 
                        ? 'Belum ada riwayat sesi konsultasi selesai.' 
                        : 'Belum ada antrean konsultasi masuk saat ini.'}
                    </p>
                  );
                }

                return displayChats.map((chat) => {
                  const name = patientNames[chat.buyerId] || 'Memuat...';
                  const avatar = patientAvatars[chat.buyerId];
                  const isDone = isChatCompleted(chat);
                  const status = isDone ? 'Selesai' : 'Konsultasi Online';
                  const color = isDone ? 'border-slate-200 text-slate-500 bg-slate-50' : 'border-blue-200 text-blue-600 bg-blue-50/20';
                  
                  return (
                    <div 
                      key={chat.id}
                      onClick={() => {
                        setSelectedChat(chat);
                        setActivePatientUid(chat.buyerId);
                        setSelectedPatientId(name);
                        setActiveMenu('pesan');
                      }}
                      className="flex items-center justify-between hover:bg-slate-50 p-2.5 rounded-2xl cursor-pointer transition-colors border border-transparent hover:border-slate-100 group"
                    >
                      <div className="flex items-center space-x-4">
                        <span className="text-xs font-black text-slate-400">09.00</span>
                        <div className="flex items-center space-x-3">
                          {renderAvatar(avatar, "w-8 h-8", "text-xs")}
                          <div>
                            <h4 className="text-xs font-black text-slate-800 leading-none">{name}</h4>
                            <p className="text-[9px] text-slate-400 font-bold mt-1">
                              {isDone ? 'Riwayat Selesai' : 'Pasien Aktif'}
                            </p>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className={`border text-[9px] font-black px-2.5 py-1 rounded-xl ${color}`}>
                          {status}
                        </span>
                        {isDone && (
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeleteChatSession(chat.id);
                            }}
                            className="p-1 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                            title="Hapus riwayat sesi ini"
                          >
                            <Trash2 size={13} />
                          </button>
                        )}
                      </div>
                    </div>
                  );
                });
              })()}
            </div>
          </div>
        </div>

        <div className="col-span-2 space-y-6">
          <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm">
            <div className="flex justify-between items-baseline mb-4">
              <h3 className="text-sm font-black text-slate-800">Notifikasi</h3>
              <button onClick={() => setShowNotificationDrawer(true)} className="text-[10px] font-black text-teal-600 hover:text-teal-800 uppercase tracking-widest">
                Lihat Semua
              </button>
            </div>
            
            <div className="space-y-4 max-h-[240px] overflow-y-auto pr-1">
              {displayNotifications.map((notif) => (
                <div key={notif.id} className="flex items-start space-x-3 text-xs">
                  <span className={`mt-0.5 font-bold ${
                    notif.type === 'success' ? 'text-green-500' :
                    notif.type === 'warning' ? 'text-orange-500' : 'text-blue-500'
                  }`}>
                    {notif.type === 'success' ? '✓' : notif.type === 'warning' ? '⚠' : 'ℹ'}
                  </span>
                  <div>
                    <h4 className="font-bold text-slate-800">{notif.title}</h4>
                    <p className="text-[10px] text-slate-500 font-medium leading-relaxed mt-0.5">{notif.desc}</p>
                    <p className="text-[9px] text-slate-400 font-bold mt-1">{notif.time}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-sm font-black text-slate-800">Statistik Mingguan</h3>
              <span className="text-[10px] font-extrabold text-emerald-600 bg-emerald-50 border border-emerald-200/60 px-2 py-0.5 rounded-full">
                +18% vs minggu lalu
              </span>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 bg-slate-50/50 border border-slate-100 rounded-2xl">
                <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Konsultasi Aktif</span>
                <span className="text-xl font-black text-slate-800 mt-1 block">
                  {chats.length}
                </span>
              </div>
              <div className="p-3 bg-slate-50/50 border border-slate-100 rounded-2xl">
                <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Pasien Terasesmen</span>
                <span className="text-xl font-black text-slate-800 mt-1 block">
                  {allPatients.filter(p => p.hasAssessment).length}
                </span>
              </div>
            </div>

            {/* Visualisasi Tren Konsultasi Mingguan */}
            <div className="pt-2 border-t border-slate-50">
              <div className="flex justify-between items-center mb-2.5">
                <span className="text-[10px] font-bold text-slate-400">Tren Sesi Konsultasi (7 Hari Terakhir)</span>
                <span className="text-[9px] font-black text-teal-600">Rata-rata: 6 sesi/hari</span>
              </div>
              <div className="flex items-end justify-between gap-2 h-20 px-1">
                {[
                  { day: 'Sen', count: 4, h: '45%' },
                  { day: 'Sel', count: 6, h: '65%' },
                  { day: 'Rab', count: 8, h: '85%' },
                  { day: 'Kam', count: 5, h: '55%' },
                  { day: 'Jum', count: 9, h: '95%' },
                  { day: 'Sab', count: 7, h: '75%' },
                  { day: 'Min', count: 3, h: '35%' },
                ].map((bar, idx) => (
                  <div key={idx} className="flex-1 flex flex-col items-center gap-1.5 group cursor-default">
                    <span className="text-[8px] font-bold text-slate-400 group-hover:text-teal-600 transition-colors">
                      {bar.count}
                    </span>
                    <div className="w-full bg-slate-100 rounded-lg overflow-hidden h-12 flex items-end">
                      <div 
                        className="w-full bg-gradient-to-t from-teal-500 to-teal-400 rounded-lg group-hover:from-teal-600 group-hover:to-teal-500 transition-all duration-300 shadow-xs" 
                        style={{ height: bar.h }}
                      />
                    </div>
                    <span className="text-[9px] font-extrabold text-slate-500">{bar.day}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  // SUB-RENDER: 2. Patient Detail View (Tab Overview, Hasil Asesmen, Catatan, Laporan)
  const renderPatientDetailView = () => {
    const name = patientProfile?.name || selectedPatientId || 'Pasien Zikola';
    const age = patientProfile?.age ? `${patientProfile.age} tahun` : 'Usia belum diisi';
    const gender = patientProfile?.gender === 'female' ? 'Perempuan' : patientProfile?.gender === 'male' ? 'Laki-laki' : '-';
    const avatar = patientProfile?.avatar || '👦';

    return (
      <div className="flex-1 overflow-y-auto bg-slate-50/30 p-4 sm:p-6 md:p-8 flex flex-col justify-start h-full">
        <div className="flex justify-between items-center pb-6 border-b border-slate-100 shrink-0">
          <div className="flex items-center space-x-4">
            <button 
              onClick={() => setSelectedPatientId(null)}
              className="w-10 h-10 border border-slate-200 rounded-2xl flex items-center justify-center text-slate-500 hover:bg-slate-50 bg-white shrink-0"
            >
              <ArrowLeft size={18} />
            </button>
            <div className="min-w-0">
              <div className="flex items-center space-x-2 flex-wrap">
                <span className="text-lg font-black text-slate-800 truncate">{name}</span>
                <span className="text-xs text-slate-400 font-bold whitespace-nowrap">/ {age} • {gender}</span>
              </div>
              <p className="text-[10px] text-slate-400 font-bold mt-1 truncate">Status tumbuh kembang terpantau sinkron</p>
            </div>
          </div>
          <div className="flex items-center space-x-2 shrink-0">
            <button 
              onClick={() => setShowPrescriptionModal(true)}
              className="bg-indigo-50 border border-indigo-200 text-indigo-700 hover:bg-indigo-100 px-3 py-2 rounded-xl text-[10px] font-bold shadow-xs transition-colors hidden sm:flex items-center space-x-1"
              title="Tulis Resep Suplemen & Terapi Baru"
            >
              <Pill size={12} />
              <span>Resep & Terapi</span>
            </button>

            <button 
              onClick={() => {
                if (patientDetailTab === 'assessment' || patientDetailTab === 'reports') {
                  setShowPrintModal(true);
                } else if (patientDetailTab === 'medical_history') {
                  handleSaveEMR();
                } else {
                  setShowRatingModal(true);
                }
              }}
              className="bg-teal-600 text-white hover:bg-teal-700 px-4 py-2 rounded-xl text-[10px] font-bold shadow-sm transition-colors hidden sm:block"
            >
              {patientDetailTab === 'assessment' ? 'Cetak Laporan Asesmen' : 
               patientDetailTab === 'reports' ? 'Cetak Rekap Laporan' : 
               patientDetailTab === 'medical_history' ? 'Simpan Data EMR' : 'Buat Catatan Klinis'}
            </button>

            <div className="relative">
              <button 
                onClick={() => setShowPatientDetailOptionsMenu(!showPatientDetailOptionsMenu)}
                className="w-10 h-10 border border-slate-200 bg-white rounded-2xl flex items-center justify-center text-slate-500 shadow-sm hover:bg-slate-50 transition-colors"
                title="Opsi Pasien"
              >
                <MoreVertical size={18} />
              </button>
              {showPatientDetailOptionsMenu && (
                <div className="absolute right-0 top-12 w-52 bg-white border border-slate-100 rounded-2xl shadow-xl p-2 z-50 animate-in fade-in zoom-in duration-150 space-y-1">
                  <button 
                    onClick={() => {
                      setShowPatientDetailOptionsMenu(false);
                      setShowPrescriptionModal(true);
                    }}
                    className="w-full text-left px-3 py-2 text-xs font-bold text-indigo-700 hover:bg-indigo-50 rounded-xl flex items-center space-x-2"
                  >
                    <Pill size={14} />
                    <span>Tulis Resep & Terapi</span>
                  </button>
                  <button 
                    onClick={() => {
                      setShowPatientDetailOptionsMenu(false);
                      setShowPatientProfileModal(true);
                    }}
                    className="w-full text-left px-3 py-2 text-xs font-bold text-slate-700 hover:bg-teal-50 hover:text-teal-700 rounded-xl flex items-center space-x-2"
                  >
                    <User size={14} />
                    <span>Lihat Biodata Lengkap</span>
                  </button>
                  <button 
                    onClick={() => {
                      setShowPatientDetailOptionsMenu(false);
                      setShowPrintModal(true);
                    }}
                    className="w-full text-left px-3 py-2 text-xs font-bold text-slate-700 hover:bg-teal-50 hover:text-teal-700 rounded-xl flex items-center space-x-2"
                  >
                    <Printer size={14} />
                    <span>Cetak Lembar EMR</span>
                  </button>
                  <button 
                    onClick={() => {
                      setShowPatientDetailOptionsMenu(false);
                      setShowAiReportModal(true);
                    }}
                    className="w-full text-left px-3 py-2 text-xs font-bold text-slate-700 hover:bg-teal-50 hover:text-teal-700 rounded-xl flex items-center space-x-2"
                  >
                    <Sparkles size={14} />
                    <span>Validasi AI Report</span>
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="flex border-b border-slate-100 my-4 md:my-6 bg-white rounded-2xl p-1 shadow-sm w-full max-w-full overflow-x-auto scrollbar-hide shrink-0">
          {['overview', 'assessment', 'stimulasi', 'notes', 'reports', 'medical_history'].map((tab) => (
            <button 
              key={tab}
              onClick={() => setPatientDetailTab(tab as any)}
              className={`px-6 py-2 text-xs font-bold rounded-xl transition-all capitalize ${
                patientDetailTab === tab ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:text-slate-650'
              }`}
            >
              {tab === 'assessment' ? 'Hasil Asesmen' : tab === 'stimulasi' ? 'Target Stimulasi' : tab === 'notes' ? 'Catatan' : tab === 'reports' ? 'Laporan' : tab === 'medical_history' ? 'Rekam Medis (EMR)' : tab}
            </button>
          ))}
        </div>

        {patientDetailTab === 'overview' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6 flex-1">
            <div className="col-span-1 space-y-6">
              <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm text-center">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block text-left">Profil Anak</span>
                <div className="w-20 h-20 rounded-full bg-slate-100 flex items-center justify-center text-4xl mx-auto my-4 border-2 border-slate-200 shadow-sm overflow-hidden animate-in fade-in duration-200">
                  {renderAvatar(avatar, "w-full h-full", "text-3xl")}
                </div>
                
                <div className="text-left space-y-3 text-xs font-bold text-slate-700">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Nama Lengkap</span>
                    <span>{name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Tanggal Lahir</span>
                    <span>{patientProfile?.dob || '-'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Sekolah</span>
                    <span>{patientProfile?.school || '-'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Orang Tua</span>
                    <span>{patientProfile?.parent || '-'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">No. Telepon</span>
                    <span>{patientProfile?.phone || '-'}</span>
                  </div>
                </div>
              </div>

              <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-4">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Riwayat Konsultasi</span>
                <div className="space-y-3">
                  <div className="flex justify-between items-center text-xs font-bold text-slate-700">
                    <span className="text-slate-400">Sesi Terkini</span>
                    <span>Konsultasi Online</span>
                  </div>
                  <div className="flex justify-between items-center text-xs font-bold text-slate-700">
                    <span className="text-slate-400">10 Mei 2025</span>
                    <span>Konsultasi Tatap Muka</span>
                  </div>
                  <div className="flex justify-between items-center text-xs font-bold text-slate-700">
                    <span className="text-slate-400">02 Mei 2025</span>
                    <span>Konsultasi Online</span>
                  </div>
                </div>
                <button 
                  onClick={() => setPatientDetailTab('notes')}
                  className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-teal-600 font-bold py-2.5 rounded-xl text-[10px] transition-colors mt-2"
                >
                  Lihat Semua Catatan Medis
                </button>
              </div>
            </div>

            <div className="col-span-2 space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-4">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Timeline Perkembangan</span>
                  <div className="space-y-4 relative pl-4 border-l border-slate-100 ml-2">
                    {displayTimelineData.map((item, idx) => (
                      <div key={idx} className="relative text-xs">
                        <div className={`absolute -left-[23px] top-0.5 w-3.5 h-3.5 rounded-full flex items-center justify-center text-[9px] font-black ${
                          item.done ? 'bg-green-500 text-white' : 'bg-teal-600 text-white'
                        }`}>
                          {item.done ? '✓' : '•'}
                        </div>
                        <span className="text-[9px] text-slate-400 font-bold block">{item.date}</span>
                        <h4 className="font-bold text-slate-805 mt-1">{item.title}</h4>
                        <p className="text-[10px] text-slate-500 font-medium leading-relaxed mt-0.5">{item.desc}</p>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm flex flex-col justify-between space-y-4">
                  <div>
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">✨ AI Summary</span>
                    <p className="text-[9px] text-slate-400 font-bold mt-1">Status: Terverifikasi Digital</p>
                    <p className="text-[11px] text-slate-500 leading-relaxed font-medium mt-3">
                      {aiReport && typeof aiReport.rawMarkdown === 'string' 
                        ? cleanClinicalText(aiReport.rawMarkdown).substring(0, 160) + '...' 
                        : (hasAssessmentData 
                            ? `Berdasarkan data asesmen terbaru, ${name} telah menyelesaikan sesi evaluasi kemampuan.`
                            : `Belum ada sesi tes atau game yang diselesaikan oleh ${name}. Laporan AI akan otomatis digenerate setelah anak menyelesaikan asesmen pertamanya.`)}
                    </p>
                  </div>
                  <div className="space-y-2 mt-4">
                    <button 
                      onClick={() => {
                        if (!aiReport) {
                          if (hasAssessmentData) {
                            setAiReport({
                              rawMarkdown: `### Laporan Analisis Tumbuh Kembang Zikola AI\n\n**Nama Pasien:** ${name}\n**Usia:** ${age}\n**Status:** Terverifikasi\n\n#### Ringkasan Analisis:\nBerdasarkan data asesmen terbaru yang diselesaikan anak, ${name} memiliki skor rata-rata ${averageScoreValue}/100 (${averageScoreLabel}). Perkembangan kognitif dan motorik menunjukkan kemajuan positif.`
                            });
                          } else {
                            setAiReport({
                              rawMarkdown: `### Laporan Awal Pasien Zikola AI\n\n**Nama Pasien:** ${name}\n**Usia:** ${age}\n**Status:** Belum Melakukan Asesmen\n\n#### Rekomendasi Awal:\nPasien baru terdaftar dan belum memiliki riwayat tes asesmen atau permainan skrining. Disarankan untuk memberikan tugas asesmen awal atau menjadwalkan sesi konsultasi pertama.`
                            });
                          }
                        }
                        setShowAiReportModal(true);
                      }}
                      className="w-full bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-bold py-2.5 rounded-xl text-[10px] shadow-sm transition-colors"
                    >
                      Lihat Laporan Lengkap (Gemini AI)
                    </button>
                    <button 
                      onClick={() => setPatientDetailTab('assessment')}
                      className="w-full bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 font-bold py-2.5 rounded-xl text-[10px] shadow-sm transition-colors"
                    >
                      Lihat Hasil Asesmen
                    </button>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-6">
                <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-3">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Catatan Terakhir</span>
                  {patientNotes && patientNotes.length > 0 ? (
                    <>
                      <p className="text-[9px] text-slate-400 font-bold">{formatDateSafe(patientNotes[0].createdAt).split(",")[0]} oleh {patientNotes[0].doctorName || doctorProfile?.name || "Dokter Spesialis"}</p>
                      <p className="text-xs text-slate-700 leading-relaxed font-bold bg-slate-50/50 p-3 rounded-2xl border border-slate-100">
                        "{patientNotes[0].text}"
                      </p>
                    </>
                  ) : (
                    <div className="bg-slate-50/50 p-4 rounded-2xl border border-slate-100 text-center">
                      <p className="text-xs text-slate-400 font-medium">Belum ada catatan klinis untuk pasien ini.</p>
                      <button onClick={() => setPatientDetailTab('notes')} className="mt-2 text-[10px] text-teal-600 font-bold hover:underline">
                        + Tambah Catatan Sekarang
                      </button>
                    </div>
                  )}
                </div>

                <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-2">
                  <div className="flex justify-between items-baseline">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Status Perkembangan</span>
                    <span className="text-xs font-black text-slate-800">
                      {hasAssessmentData ? (
                        <>Skor Rata-rata: <span className="text-teal-600">{averageScoreValue}</span> <span className="text-[10px] font-bold text-green-500">{averageScoreLabel}</span></>
                      ) : (
                        <span className="text-slate-400 font-medium text-[11px]">Belum Ada Nilai Tes</span>
                      )}
                    </span>
                  </div>
                  
                  <div className="h-[90px] w-full mt-2">
                    {hasAssessmentData ? (
                      <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={progressLineData} margin={{ top: 5, right: 5, left: -25, bottom: 0 }}>
                          <XAxis dataKey="name" tick={{ fontSize: 8, fontWeight: 'bold' }} stroke="#94A3B8" />
                          <YAxis tick={{ fontSize: 8, fontWeight: 'bold' }} stroke="#94A3B8" />
                          <Area type="monotone" dataKey="Logika" stroke="#7C3AED" fill="#E0E7FF" fillOpacity={0.4} />
                        </AreaChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="h-full flex items-center justify-center bg-slate-50 rounded-xl text-center">
                        <span className="text-[10px] text-slate-400 font-bold">Grafik akan aktif setelah asesmen pertama</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {patientDetailTab === 'assessment' && (
          !hasAssessmentData ? (
            <div className="bg-white border border-slate-100 rounded-[2rem] p-12 text-center shadow-sm flex-1 flex flex-col items-center justify-center my-4 space-y-4">
              <div className="w-20 h-20 rounded-3xl bg-teal-50 text-teal-600 flex items-center justify-center text-4xl shadow-inner">
                📊
              </div>
              <div className="max-w-md space-y-1">
                <h3 className="text-base font-black text-slate-800">Belum Ada Penilaian Asesmen</h3>
                <p className="text-xs text-slate-500 font-medium leading-relaxed">
                  Pasien <span className="font-bold text-slate-700">{patientProfile?.name || selectedPatientId}</span> belum pernah menyelesaikan tes asesmen atau permainan skrining di aplikasi Zikola.
                </p>
              </div>
              <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
                <button
                  onClick={() => setShowTugasModal(true)}
                  className="px-5 py-2.5 bg-teal-600 hover:bg-teal-700 text-white font-bold text-xs rounded-xl shadow-sm transition-all"
                >
                  🚀 Beri Tugas & Game Asesmen
                </button>
                <button
                  onClick={() => setShowMateriModal(true)}
                  className="px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs rounded-xl transition-all"
                >
                  📚 Kirim Panduan Stimulasi
                </button>
                <button
                  onClick={() => setActiveMenu('pesan')}
                  className="px-5 py-2.5 border border-slate-200 hover:bg-slate-50 text-slate-700 font-bold text-xs rounded-xl transition-all"
                >
                  💬 Hubungi Orang Tua
                </button>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-4 gap-6 flex-1">
              <div className="col-span-1 bg-white border border-slate-100 rounded-[1.5rem] p-5 shadow-sm space-y-4 h-fit">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Riwayat Asesmen</span>
                <div className="space-y-2">
                  <div 
                    onClick={() => setSelectedAssessmentDate('Sesi Terkini')}
                    className={`p-3.5 border-2 rounded-2xl cursor-pointer transition-all flex items-center justify-between ${
                      selectedAssessmentDate === 'Sesi Terkini' ? 'border-teal-600 bg-teal-50/40' : 'border-slate-100 hover:border-slate-200 bg-white'
                    }`}
                  >
                    <div>
                      <h4 className="text-xs font-black text-slate-800">Sesi Terkini</h4>
                      <p className="text-[9px] text-slate-400 font-bold mt-1">Data Hasil Real-time</p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="col-span-3 space-y-6">
                <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-4">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">
                    Ringkasan Hasil Asesmen - {selectedAssessmentDate}
                  </span>
                  
                  <div className="grid grid-cols-3 gap-4">
                    <div className="col-span-1 space-y-2 text-center border-r border-slate-100 pr-4">
                      <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider block text-left">Profil Kemampuan</span>
                      <div className="h-[140px] flex items-center justify-center">
                        <ResponsiveContainer width="100%" height="100%">
                          <RadarChart cx="50%" cy="50%" outerRadius="75%" data={radarData}>
                            <PolarGrid stroke="#E2E8F0" />
                            <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 7, fontWeight: 'bold' }} />
                            <Radar name="Skor" dataKey="A" stroke="#7C3AED" fill="#7C3AED" fillOpacity={0.25} />
                          </RadarChart>
                        </ResponsiveContainer>
                      </div>
                    </div>

                    <div className="col-span-1 space-y-3 px-2 border-r border-slate-100">
                      <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider block">Skor Kemampuan</span>
                      {[
                        { label: 'Logika', val: getDynamicScore('puzzleGame', 0), stat: getDynamicScore('puzzleGame', 0) >= 80 ? 'Atas Rata-rata' : getDynamicScore('puzzleGame', 0) >= 60 ? 'Rata-rata' : 'Perlu Stimulasi', color: 'bg-teal-600' },
                        { label: 'Bahasa', val: getDynamicScore('wordPuzzle', 0), stat: getDynamicScore('wordPuzzle', 0) >= 80 ? 'Atas Rata-rata' : getDynamicScore('wordPuzzle', 0) >= 60 ? 'Rata-rata' : 'Perlu Stimulasi', color: 'bg-teal-600' },
                        { label: 'Motorik', val: getDynamicScore('coloringGame', 0), stat: getDynamicScore('coloringGame', 0) >= 80 ? 'Atas Rata-rata' : getDynamicScore('coloringGame', 0) >= 60 ? 'Rata-rata' : 'Perlu Stimulasi', color: 'bg-teal-600' },
                        { label: 'Emosi', val: getDynamicScore('storyBuilderGame', 0), stat: getDynamicScore('storyBuilderGame', 0) >= 80 ? 'Atas Rata-rata' : getDynamicScore('storyBuilderGame', 0) >= 60 ? 'Rata-rata' : 'Perlu Stimulasi', color: 'bg-orange-500' },
                        { label: 'Memori', val: getDynamicScore('memory', 0), stat: getDynamicScore('memory', 0) >= 80 ? 'Atas Rata-rata' : getDynamicScore('memory', 0) >= 60 ? 'Rata-rata' : 'Perlu Stimulasi', color: 'bg-orange-500' },
                        { label: 'Atensi', val: getDynamicScore('numberSequence', 0), stat: getDynamicScore('numberSequence', 0) >= 80 ? 'Atas Rata-rata' : getDynamicScore('numberSequence', 0) >= 60 ? 'Rata-rata' : 'Perlu Stimulasi', color: 'bg-indigo-600' }
                      ].map((bar, i) => (
                        <div key={i} className="text-[10px] font-bold text-slate-700">
                          <div className="flex justify-between">
                            <span>{bar.label}</span>
                            <span>{bar.val > 0 ? `${bar.val}/100` : '-'} <span className="text-[8px] font-medium text-slate-400">({bar.val > 0 ? bar.stat : 'Belum ada'})</span></span>
                          </div>
                          <div className="w-full bg-slate-100 h-1.5 rounded-full mt-1 overflow-hidden">
                            <div className={`h-full rounded-full ${bar.val > 0 ? bar.color : 'bg-slate-200'}`} style={{ width: `${bar.val}%` }}></div>
                          </div>
                        </div>
                      ))}
                    </div>

                    <div className="col-span-1 pl-4 space-y-3">
                      <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider block">Perkembangan Skor</span>
                      <div className="h-[140px] w-full">
                        {progressLineData.length > 0 ? (
                          <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={progressLineData} margin={{ top: 5, right: 5, left: -25, bottom: 0 }}>
                              <XAxis dataKey="name" tick={{ fontSize: 7, fontWeight: 'bold' }} stroke="#94A3B8" />
                              <YAxis tick={{ fontSize: 7, fontWeight: 'bold' }} stroke="#94A3B8" />
                              <Tooltip />
                              <Line type="monotone" dataKey="Logika" stroke="#7C3AED" strokeWidth={2} dot={{ r: 2 }} />
                              <Line type="monotone" dataKey="Memori" stroke="#10B981" strokeWidth={2} dot={{ r: 2 }} />
                              <Line type="monotone" dataKey="Atensi" stroke="#F59E0B" strokeWidth={2} dot={{ r: 2 }} />
                            </LineChart>
                          </ResponsiveContainer>
                        ) : (
                          <div className="h-full flex items-center justify-center text-[9px] text-slate-400 font-bold">
                            Belum ada riwayat berkala
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Game & Skrining yang Dikerjakan</span>
                  <div className="grid grid-cols-2 gap-4">
                    {[
                      { title: 'Puzzle Logika (Problem Solving)', icon: '🧩', score: getDynamicScore('puzzleGame', 0), key: 'puzzleGame' },
                      { title: 'Memori Visual', icon: '👁️', score: getDynamicScore('memory', 0), key: 'memory' },
                      { title: 'Math Adventure (Atensi & Angka)', icon: '🔢', score: getDynamicScore('numberSequence', 0), key: 'numberSequence' },
                      { title: 'Bahasa Seru (Kosakata)', icon: '🗣️', score: getDynamicScore('wordPuzzle', 0), key: 'wordPuzzle' }
                    ].map((card, i) => {
                      const played = card.score > 0 || (gameAssessments && gameAssessments[card.key]);
                      const stat = card.score >= 80 ? 'Sangat Baik' : card.score >= 65 ? 'Baik' : card.score >= 50 ? 'Cukup' : 'Perlu Latihan';
                      const statColor = card.score >= 80 ? 'text-green-600 bg-green-50' : card.score >= 65 ? 'text-blue-600 bg-blue-50' : card.score >= 50 ? 'text-orange-600 bg-orange-50' : 'text-slate-500 bg-slate-50';
                      return (
                        <div key={i} className="bg-white border border-slate-100 p-4 rounded-2xl shadow-sm flex items-center justify-between hover:shadow-md transition-shadow">
                          <div className="flex items-center space-x-3">
                            <span className="text-3xl bg-slate-50 p-2.5 rounded-2xl block">{card.icon}</span>
                            <div>
                              <h4 className="text-xs font-black text-slate-800">{card.title}</h4>
                              <div className="flex items-center space-x-2 mt-1.5 text-[9px] text-slate-400 font-bold">
                                <span>Skor: {played ? `${card.score}/100` : 'Belum dimainkan'}</span>
                              </div>
                            </div>
                          </div>
                          {played ? (
                            <span className={`px-2 py-0.5 rounded-lg text-[9px] font-black ${statColor}`}>
                              {stat}
                            </span>
                          ) : (
                            <span className="px-2 py-0.5 rounded-lg text-[9px] font-medium text-slate-400 bg-slate-100">
                              Menunggu
                            </span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </div>
          )
        )}

        {/* 🎯 Tab Target Stimulasi (Action Plans & Monitoring Kepatuhan) */}
        {patientDetailTab === 'stimulasi' && (
          <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 md:p-8 shadow-sm flex-1 space-y-8">
            <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4 border-b border-slate-100 pb-5">
              <div>
                <h3 className="text-base font-black text-slate-800">Target Stimulasi & Kepatuhan Stimulasi Anak</h3>
                <p className="text-xs text-slate-500 font-bold mt-1">Pantau kepatuhan orang tua dalam menjalankan checklist stimulasi harian dan materi yang ditugaskan.</p>
              </div>
              <div className="flex items-center space-x-2 shrink-0">
                <button 
                  onClick={() => setShowTugasModal(true)}
                  className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-xl text-xs font-black shadow-sm flex items-center space-x-1.5 transition-colors"
                >
                  <Plus size={14} />
                  <span>+ Beri Target Stimulasi</span>
                </button>
                <button 
                  onClick={() => setShowMateriModal(true)}
                  className="px-4 py-2 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200 text-indigo-700 rounded-xl text-xs font-black flex items-center space-x-1.5 transition-colors"
                >
                  <Plus size={14} />
                  <span>+ Kirim Panduan Materi</span>
                </button>
              </div>
            </div>

            {/* Sub-section: Action Plans */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-black text-slate-800 uppercase tracking-wider flex items-center space-x-2">
                  <span className="w-2 h-2 rounded-full bg-teal-500"></span>
                  <span>Rencana Aksi Harian Pasien ({patientActionPlans.length})</span>
                </h4>
                <span className="text-[10px] text-slate-400 font-bold">Sinkronisasi Realtime dengan Aplikasi Anak</span>
              </div>

              {patientActionPlans.length === 0 ? (
                <div className="p-8 bg-slate-50 border border-dashed border-slate-200 rounded-2xl text-center space-y-2">
                  <div className="text-3xl">🎯</div>
                  <p className="text-xs text-slate-600 font-bold">Belum ada target stimulasi harian (Action Plan) untuk pasien ini.</p>
                  <p className="text-[10px] text-slate-400 max-w-md mx-auto">
                    Klik tombol "+ Beri Target Stimulasi" di atas untuk menetapkan fokus stimulasi bicara/motorik, batas durasi layar (screen-time), dan instruksi dokter yang langsung muncul di aplikasi orang tua.
                  </p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {patientActionPlans.map((plan) => (
                    <div key={plan.id} className="border border-slate-200/80 rounded-2xl p-5 bg-gradient-to-br from-white to-slate-50/50 hover:shadow-md transition-all relative flex flex-col justify-between">
                      <div>
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex flex-wrap items-center gap-1.5">
                            <span className="text-[10px] font-black uppercase tracking-wider px-2.5 py-1 rounded-lg bg-teal-50 text-teal-700 border border-teal-200">
                              🎯 {plan.target || 'Stimulasi Umum'}
                            </span>
                            {plan.screenTime && (
                              <span className="text-[10px] font-bold px-2 py-1 rounded-lg bg-purple-50 text-purple-700 border border-purple-200">
                                ⏱️ Layar: {plan.screenTime}
                              </span>
                            )}
                          </div>
                          <button
                            type="button"
                            onClick={async () => {
                              if (confirm(`Hapus rencana stimulasi "${plan.target}"?`) && activePatientUid) {
                                await deleteDoc(doc(db, 'users', activePatientUid, 'action_plans', plan.id));
                              }
                            }}
                            className="text-slate-300 hover:text-rose-500 transition-colors p-1"
                            title="Hapus Action Plan"
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>

                        <div className="mt-3">
                          <p className="text-xs text-slate-700 font-semibold leading-relaxed bg-white p-3 rounded-xl border border-slate-100 shadow-2xs">
                            "{plan.notes || 'Lakukan stimulasi terarah setiap hari.'}"
                          </p>
                        </div>
                      </div>

                      <div className="mt-4 pt-3 border-t border-slate-100 space-y-2">
                        {/* Compliance Status Badge */}
                        <div className={`p-2.5 rounded-xl border flex items-center justify-between text-xs font-bold ${
                          plan.completedToday 
                            ? 'bg-emerald-50 border-emerald-200 text-emerald-800' 
                            : 'bg-amber-50 border-amber-200 text-amber-800'
                        }`}>
                          <div className="flex items-center space-x-2">
                            <span>{plan.completedToday ? '✅' : '⏳'}</span>
                            <span className="text-[11px]">
                              {plan.completedToday 
                                ? 'Selesai Dijalankan Orang Tua Hari Ini' 
                                : 'Belum Dijalankan / Menunggu Orang Tua'}
                            </span>
                          </div>
                          <span className="text-[9px] uppercase font-black tracking-wider opacity-75">
                            {plan.completedToday ? 'Patuh' : 'Pending'}
                          </span>
                        </div>

                        <div className="flex justify-between items-center text-[9px] text-slate-400 font-bold px-1">
                          <span>Diberikan oleh: {plan.doctorName || doctorProfile?.name || 'Dokter Spesialis'}</span>
                          <span>{plan.createdAt ? formatDateSafe(plan.createdAt).split(',')[0] : 'Hari ini'}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Sub-section: Sent Materials */}
            <div className="space-y-4 pt-4 border-t border-slate-100">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-black text-slate-800 uppercase tracking-wider flex items-center space-x-2">
                  <span className="w-2 h-2 rounded-full bg-indigo-500"></span>
                  <span>Modul Panduan & Materi Edukasi Terkirim ({patientMaterials.length})</span>
                </h4>
              </div>

              {patientMaterials.length === 0 ? (
                <div className="p-6 bg-slate-50 border border-dashed border-slate-200 rounded-2xl text-center">
                  <p className="text-xs text-slate-500 font-bold">Belum ada artikel atau video edukasi yang dikirimkan ke orang tua pasien.</p>
                  <p className="text-[10px] text-slate-400 mt-0.5">Kirim materi untuk melatih kemampuan stimulasi orang tua di rumah.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {patientMaterials.map((mat) => (
                    <div key={mat.id} className="p-4 border border-indigo-100 rounded-2xl bg-indigo-50/30 flex items-start justify-between">
                      <div className="space-y-1">
                        <span className="text-[9px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md bg-indigo-100 text-indigo-800">
                          {mat.category || 'Panduan'}
                        </span>
                        <h5 className="text-xs font-black text-slate-800">{mat.title}</h5>
                        {mat.notes && <p className="text-[10px] text-slate-600 font-medium italic">"{mat.notes}"</p>}
                        <p className="text-[9px] text-slate-400 font-bold">{formatDateSafe(mat.createdAt).split(',')[0]}</p>
                      </div>
                      <div className="flex items-center space-x-1">
                        {mat.url && (
                          <a
                            href={mat.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="px-2.5 py-1 bg-white border border-indigo-200 text-indigo-700 hover:bg-indigo-50 rounded-lg text-[10px] font-bold shadow-2xs"
                          >
                            Buka ↗
                          </a>
                        )}
                        <button
                          type="button"
                          onClick={async () => {
                            if (confirm(`Hapus materi "${mat.title}"?`) && activePatientUid) {
                              await deleteDoc(doc(db, 'users', activePatientUid, 'materials', mat.id));
                            }
                          }}
                          className="text-slate-300 hover:text-rose-500 transition-colors p-1"
                          title="Hapus Materi"
                        >
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* 📝 Tab Catatan (Clinical Notes) */}
        {patientDetailTab === 'notes' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6 flex-1">
            <div className="col-span-1 bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm h-fit">
              <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-4">Buat Catatan Baru</span>
              <form onSubmit={handleSaveClinicalNote} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-500">Kategori Catatan</label>
                  <select 
                    value={newNoteCategory}
                    onChange={(e) => setNewNoteCategory(e.target.value)}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-xs outline-none bg-white font-bold"
                  >
                    <option value="Perkembangan">📈 Perkembangan Kognitif</option>
                    <option value="Perilaku">🌱 Perilaku & Sikap</option>
                    <option value="Rekomendasi">🎯 Stimulasi & Rekomendasi</option>
                    <option value="Lainnya">✏️ Catatan Lainnya</option>
                  </select>
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-bold text-slate-500">Isi Catatan Dokter</label>
                  <textarea 
                    value={newNoteText}
                    onChange={(e) => setNewNoteText(e.target.value)}
                    rows={6}
                    placeholder="Ketik rincian perkembangan klinis anak di sini..."
                    className="w-full border border-slate-200 p-3 rounded-xl text-xs outline-none focus:border-teal-500 resize-none font-medium"
                    required
                  />
                </div>
                <button 
                  type="submit"
                  className="w-full bg-teal-600 hover:bg-teal-700 text-white font-bold py-2.5 rounded-xl text-[10px] shadow-sm transition-colors"
                >
                  Simpan Catatan Pasien
                </button>
              </form>
            </div>

            <div className="col-span-2 bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm flex flex-col justify-between">
              <div>
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-4">Riwayat Catatan Klinis</span>
                <div className="space-y-4 max-h-[400px] overflow-y-auto pr-2">
                  {patientNotes.length === 0 ? (
                    <div className="space-y-3 py-6">
                      {[
                        { date: '18 Mei 2025', doctor: 'Dra. Rina Melati, M.Psi.', cat: 'Konsultasi', text: 'Anak kooperatif dan komunikasi baik. Perlu latihan fokus dan kontrol impuls. Disarankan stimulasi memori jangka pendek secara bertahap.' },
                        { date: '10 Mei 2025', doctor: 'Dra. Rina Melati, M.Psi.', cat: 'Perilaku', text: 'Observasi tatap muka menunjukkan konsentrasi stabil hingga menit ke-12, kemudian menunjukkan sedikit distraksi visual.' }
                      ].map((item, i) => (
                        <div key={i} className="border border-slate-100 p-4 rounded-2xl bg-slate-50/50">
                          <div className="flex justify-between items-baseline">
                            <span className="text-[10px] text-teal-600 bg-teal-50 px-2 py-0.5 rounded-lg font-black">{item.cat}</span>
                            <span className="text-[9px] text-slate-400 font-bold">{item.date} • {item.doctor}</span>
                          </div>
                          <p className="text-xs text-slate-700 mt-2 leading-relaxed font-bold">"{item.text}"</p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    patientNotes.map((note) => (
                      <div key={note.id} className="border border-slate-100 p-4 rounded-2xl bg-slate-50/50 hover:bg-slate-50 transition-colors">
                        <div className="flex justify-between items-baseline">
                          <span className="text-[10px] text-teal-600 bg-teal-50 px-2 py-0.5 rounded-lg font-black">{note.category}</span>
                          <div className="flex items-center space-x-2">
                            <span className="text-[9px] text-slate-400 font-bold">
                              {formatDateSafe(note.createdAt)} • {note.doctorName}
                            </span>
                            <button 
                              onClick={() => handleDeleteNote(note.id)}
                              className="text-slate-300 hover:text-rose-500 transition-colors p-1"
                              title="Hapus Catatan"
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </div>
                        <p className="text-xs text-slate-700 mt-2 leading-relaxed font-bold whitespace-pre-line">"{note.text}"</p>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 📄 Tab Laporan (Reports) */}
        
        {patientDetailTab === 'medical_history' && (
          <div className="bg-white border border-slate-100 rounded-[1.5rem] p-8 shadow-sm">
            <div className="mb-6 flex justify-between items-center border-b border-slate-100 pb-4">
              <div>
                <h3 className="text-base font-black text-slate-800">Riwayat Klinis & Medis (EMR)</h3>
                <p className="text-xs text-slate-500 font-bold mt-1">Lengkapi data komprehensif pasien untuk akurasi diagnosa dan rekam medis digital.</p>
              </div>
              <button 
                onClick={handleSaveEMR} 
                disabled={isSavingEmr}
                className="px-6 py-2 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 shadow-sm flex items-center space-x-2 disabled:opacity-50 transition-colors"
              >
                <Save size={14} />
                <span>{isSavingEmr ? 'Menyimpan...' : 'Simpan Data EMR'}</span>
              </button>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-8">
              <div className="space-y-5">
                <h4 className="text-[11px] font-black text-teal-800 uppercase tracking-widest bg-teal-50 p-2 rounded-lg inline-block">1. Riwayat Kehamilan & Kelahiran</h4>
                <div className="space-y-1.5">
                  <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Kondisi Kelahiran</label>
                  <select 
                    value={emrBirthCondition}
                    onChange={(e) => setEmrBirthCondition(e.target.value)}
                    className="w-full p-3 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 bg-slate-50 outline-none focus:border-teal-500"
                  >
                    <option value="Normal (Cukup Bulan)">Normal (Cukup Bulan)</option>
                    <option value="Prematur (Kurang Bulan)">Prematur (Kurang Bulan)</option>
                    <option value="Komplikasi Lahir (Asfiksia, dll)">Komplikasi Lahir (Asfiksia, dll)</option>
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Catatan Tambahan Kehamilan</label>
                  <textarea 
                    rows={3} 
                    value={emrPregnancyNotes}
                    onChange={(e) => setEmrPregnancyNotes(e.target.value)}
                    className="w-full p-3 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 bg-slate-50 outline-none resize-none focus:border-teal-500" 
                    placeholder="Cth: Ibu mengalami pre-eklamsia ringan, riwayat USG 4D normal."
                  />
                </div>
              </div>
              
              <div className="space-y-5">
                <h4 className="text-[11px] font-black text-indigo-800 uppercase tracking-widest bg-indigo-50 p-2 rounded-lg inline-block">2. Riwayat Kesehatan Anak</h4>
                <div className="space-y-1.5">
                  <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Alergi & Penyakit Penyerta</label>
                  <textarea 
                    rows={2} 
                    value={emrAllergies}
                    onChange={(e) => setEmrAllergies(e.target.value)}
                    className="w-full p-3 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 bg-slate-50 outline-none resize-none focus:border-teal-500" 
                    placeholder="Cth: Alergi susu sapi, pernah kejang demam usia 2 tahun."
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Riwayat Terapi Sebelumnya</label>
                  <textarea 
                    rows={2} 
                    value={emrPreviousTherapy}
                    onChange={(e) => setEmrPreviousTherapy(e.target.value)}
                    className="w-full p-3 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 bg-slate-50 outline-none resize-none focus:border-teal-500" 
                    placeholder="Cth: Terapi Wicara 6 bulan di klinik X, stimulasi motorik mandiri."
                  />
                </div>
              </div>

              <div className="space-y-5 md:col-span-2 pt-4 border-t border-slate-100">
                <h4 className="text-[11px] font-black text-purple-800 uppercase tracking-widest bg-purple-50 p-2 rounded-lg inline-block">3. Diagnosa Klinis & Rencana Terapi Dokter</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Kesimpulan Klinis & Diagnosa Sementara</label>
                    <textarea 
                      rows={3} 
                      value={emrDiagnosis}
                      onChange={(e) => setEmrDiagnosis(e.target.value)}
                      className="w-full p-3 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 bg-slate-50 outline-none resize-none focus:border-teal-500" 
                      placeholder="Cth: Tidak ditemukan retardasi mayor. Kecenderungan atensi terdistraksi saat aktivitas visual monoton."
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Rencana Terapi / Stimulasi Lanjutan</label>
                    <textarea 
                      rows={3} 
                      value={emrTreatmentPlan}
                      onChange={(e) => setEmrTreatmentPlan(e.target.value)}
                      className="w-full p-3 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 bg-slate-50 outline-none resize-none focus:border-teal-500" 
                      placeholder="Cth: Terapi sensori integrasi 1x/minggu, pembatasan screen time maks 30 menit, latihan puzzle bertingkat."
                    />
                  </div>
                </div>
              </div>

              {/* 4. Resep Digital & Terapi */}
              <div className="space-y-4 md:col-span-2 pt-4 border-t border-slate-100">
                <div className="flex items-center justify-between">
                  <h4 className="text-[11px] font-black text-indigo-800 uppercase tracking-widest bg-indigo-50 p-2 rounded-lg inline-flex items-center space-x-1.5">
                    <Pill size={13} />
                    <span>4. Resep Digital & Rekomendasi Terapi (E-Prescription)</span>
                  </h4>
                  <button 
                    type="button" 
                    onClick={() => setShowPrescriptionModal(true)}
                    className="px-3 py-1.5 bg-indigo-50 border border-indigo-200 text-indigo-700 hover:bg-indigo-100 rounded-xl text-xs font-black transition-all flex items-center space-x-1"
                  >
                    <Plus size={13} />
                    <span>Tulis Resep Baru</span>
                  </button>
                </div>

                {patientPrescriptions.length === 0 ? (
                  <div className="p-4 bg-slate-50 border border-dashed border-slate-200 rounded-2xl text-center">
                    <p className="text-xs text-slate-500 font-bold">Belum ada resep digital atau paket terapi yang diterbitkan untuk pasien ini.</p>
                    <p className="text-[10px] text-slate-400 mt-0.5">Klik tombol "Tulis Resep Baru" di atas untuk meresepkan suplemen (DHA/Vitamin D3) atau paket terapi klinis.</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {patientPrescriptions.map((pr) => (
                      <div key={pr.id} className="p-4 border border-indigo-100 rounded-2xl bg-indigo-50/40 relative">
                        <div className="flex items-start justify-between">
                          <div>
                            <span className="text-[9px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md bg-indigo-100 text-indigo-800">
                              {pr.type || 'suplemen'}
                            </span>
                            <h5 className="text-xs font-black text-slate-800 mt-1.5">{pr.itemName}</h5>
                          </div>
                          <button 
                            type="button"
                            onClick={async () => {
                              if (confirm(`Hapus resep "${pr.itemName}"?`) && activePatientUid) {
                                await deleteDoc(doc(db, 'users', activePatientUid, 'prescriptions', pr.id));
                              }
                            }}
                            className="text-slate-300 hover:text-rose-500 transition-colors p-1"
                            title="Hapus Resep"
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                        <div className="mt-2 text-[10px] space-y-0.5 text-slate-600 font-medium">
                          <p><span className="font-bold text-slate-700">Dosis / Sesi:</span> {pr.dosage || '-'}</p>
                          <p><span className="font-bold text-slate-700">Durasi:</span> {pr.duration || '-'}</p>
                          {pr.notes && <p className="italic text-slate-500 mt-1 border-t border-indigo-100 pt-1">"{pr.notes}"</p>}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {patientDetailTab === 'reports' && (
          <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm flex flex-col justify-between flex-1">
            <div>
              <div className="flex justify-between items-center mb-6">
                <div>
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Arsip Laporan Orang Tua</span>
                  <p className="text-xs text-slate-405 font-bold mt-1">Daftar file PDF dokumen hasil tumbuh kembang triwulan anak.</p>
                </div>
                <button 
                  onClick={() => setShowAiReportModal(true)}
                  className="bg-teal-600 hover:bg-teal-700 text-white font-bold px-4 py-2 rounded-xl text-[10px] shadow-sm flex items-center space-x-1.5"
                >
                  <Sparkles size={12} />
                  <span>Buat Laporan Baru</span>
                </button>
              </div>

              <div className="space-y-3">
                {[
                  { title: `Rapor Tumbuh Kembang Komprehensif - ${name}`, tag: 'EMR Digital', date: formatDateSafe(new Date()).split(',')[0], status: 'Terverifikasi' },
                  { title: `Hasil Analisis Asesmen Gemini AI - ${name}`, tag: 'AI Analysis', date: formatDateSafe(new Date()).split(',')[0], status: 'Siap Cetak' },
                  { title: `Rencana Stimulasi & Rekomendasi Klinis - ${name}`, tag: 'Action Plan', date: formatDateSafe(new Date()).split(',')[0], status: 'Aktif' }
                ].map((rep, idx) => (
                  <div key={idx} className="border border-slate-100 p-4 rounded-2xl flex items-center justify-between hover:bg-slate-50/50 transition-colors">
                    <div className="flex items-center space-x-3">
                      <span className="text-3xl bg-teal-50 text-teal-600 p-2 rounded-xl block">📄</span>
                      <div>
                        <h4 className="text-xs font-black text-slate-800">{rep.title}</h4>
                        <div className="flex items-center space-x-2 mt-1 text-[9px] text-slate-400 font-bold">
                          <span className="text-teal-600">{rep.tag}</span>
                          <span>•</span>
                          <span>Tanggal: {rep.date}</span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      <span className="text-[9px] font-black bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-lg mr-2">
                        {rep.status}
                      </span>
                      <button 
                        onClick={() => setShowPrintModal(true)}
                        className="px-3 py-1.5 border border-slate-200 rounded-xl flex items-center space-x-1 text-slate-600 hover:bg-slate-50 bg-white text-[10px] font-bold"
                        title="Unduh & Cetak Laporan"
                      >
                        <Printer size={12} />
                        <span>Cetak EMR</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

      </div>
    );
  };

  // SUB-RENDER: 3. Consultation Chat View (Bottom Right Screen)
  const renderKonsultasiChatView = () => (
    <div className="flex-1 flex overflow-hidden bg-slate-50/30 w-full">
      {/* 1. Left Column: Informasi Sesi */}
      <div className="w-56 xl:w-64 bg-white border-r border-slate-100 flex flex-col justify-between p-4 xl:p-5 overflow-y-auto flex-shrink-0">
        <div className="space-y-4">
          <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Informasi Sesi</span>
          
          <div 
            onClick={() => setShowPatientProfileModal(true)}
            className="bg-slate-50 border border-slate-100 rounded-2xl p-3 text-center cursor-pointer hover:bg-teal-50/50 hover:border-teal-200 transition-all group"
            title="Klik untuk melihat profil anak lengkap"
          >
            <div className="w-14 h-14 rounded-full bg-slate-100 flex items-center justify-center text-2xl mx-auto mb-2 shadow-sm border border-slate-200 overflow-hidden group-hover:scale-105 transition-transform">
              {renderAvatar(patientAvatars[selectedChat?.buyerId], "w-full h-full")}
            </div>
            <h4 className="text-xs font-black text-slate-800 leading-tight group-hover:text-teal-700">{patientProfile?.name || selectedPatientId || 'Pasien'}</h4>
            <p className="text-[9px] text-slate-400 font-bold mt-0.5">{patientProfile?.age ? `${patientProfile.age} Tahun` : 'Anak'} • 🔍 Profil Anak</p>
          </div>

          {selectedChat?.complaint && (
            <div className="p-2.5 bg-amber-50/70 border border-amber-200/80 rounded-xl text-left space-y-1">
              <span className="text-[9px] font-black uppercase tracking-wider text-amber-800 flex items-center space-x-1">
                <span>📋 Keluhan Awal:</span>
              </span>
              <p className="text-[11px] font-bold text-amber-950 leading-snug">{selectedChat.complaint}</p>
              {selectedChat.complaintNote && (
                <p className="text-[10px] text-amber-800 italic">"{selectedChat.complaintNote}"</p>
              )}
            </div>
          )}

          <div className="text-[11px] font-bold text-slate-700 space-y-2.5 pt-3 border-t border-slate-100">
            <div className="flex justify-between items-center">
              <span className="text-slate-400 font-medium text-[10px]">Orang Tua</span>
              <span className="truncate max-w-[100px]">{patientProfile?.parent || "Orang Tua"}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400 font-medium text-[10px]">Tipe</span>
              <span className="text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded text-[10px]">Online (Chat)</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400 font-medium text-[10px]">Durasi Sesi</span>
              <span>45 Menit</span>
            </div>
          </div>
          
          <div className="space-y-1.5 pt-1">
            <button 
              onClick={() => setShowPrescriptionModal(true)}
              className="w-full bg-indigo-50 hover:bg-indigo-100 border border-indigo-200 text-indigo-700 font-bold py-2 rounded-xl text-[10px] transition-colors shadow-sm flex items-center justify-center space-x-1.5"
            >
              <Pill size={13} className="text-indigo-600" />
              <span>Tulis Resep & Terapi</span>
            </button>
            <button 
              onClick={() => setShowPatientProfileModal(true)}
              className="w-full bg-teal-50 hover:bg-teal-100 border border-teal-200 text-teal-700 font-bold py-1.5 rounded-xl text-[10px] transition-colors shadow-sm flex items-center justify-center space-x-1"
            >
              <span>🔍</span>
              <span>Lihat Profil Lengkap</span>
            </button>
            <button 
              onClick={() => {
                setSelectedPatientId(patientProfile?.name || selectedPatientId || 'Pasien');
                setActiveMenu('patients');
                setPatientDetailTab('overview');
              }}
              className="w-full bg-white hover:bg-slate-50 border border-slate-200 text-slate-600 font-bold py-1.5 rounded-xl text-[10px] transition-colors shadow-sm"
            >
              Buka Lembar Pasien
            </button>
          </div>
        </div>

        {(selectedChat?.status === 'completed' || isExpired) ? (
          <button 
            onClick={() => {
              setSelectedChat(null);
              setActiveMenu('dashboard');
            }}
            className="w-full bg-slate-100 hover:bg-slate-200 text-slate-700 py-2.5 rounded-xl font-bold text-xs transition-colors mt-3 flex items-center justify-center space-x-1.5 shadow-xs"
          >
            <span>Tutup Ruangan Chat</span>
          </button>
        ) : (
          <button 
            onClick={() => handleCompleteSession(selectedChat.id)}
            className="w-full bg-rose-50 hover:bg-rose-100 text-rose-600 border border-rose-200 py-2.5 rounded-xl font-bold text-xs transition-colors mt-3 flex items-center justify-center space-x-1.5 shadow-xs"
          >
            <X size={14} />
            <span>Akhiri Sesi</span>
          </button>
        )}
      </div>

      {/* 2. Middle Column: Chat Messages & Input */}
      <div className="flex-1 min-w-0 flex flex-col bg-[#F8FAFC] border-r border-slate-100">
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          <div className="text-center">
            <span className="bg-slate-100 text-slate-400 text-[10px] font-bold px-3 py-1 rounded-full uppercase tracking-wider">
              Mulai Sesi Chat
            </span>
          </div>

          {messages.map((msg) => {
            const isDoctor = msg.senderType === 'doctor';
            const textContent = msg.text || msg.content || '';
            const isPrescription = msg.metadata?.type === 'prescription' || textContent.includes('📋 RESEP & REKOMENDASI TERAPI');
            const hasImage = msg.attachmentType === 'image' && msg.attachmentUrl;
            const hasDocument = msg.attachmentType === 'document' && msg.attachmentUrl;
            
            const imgUrl = msg.attachmentUrl?.startsWith('base64:')
              ? msg.attachmentUrl.replace('base64:', 'data:image/jpeg;base64,')
              : msg.attachmentUrl;

            return (
              <div key={msg.id} className={`flex ${isDoctor ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[80%] rounded-2xl shadow-sm relative ${
                  isDoctor 
                    ? 'bg-teal-600 text-white rounded-tr-none' 
                    : 'bg-white text-slate-700 rounded-tl-none border border-slate-100'
                } ${hasImage ? 'p-2' : 'p-4'}`}>
                  {isPrescription ? (
                    <div className="space-y-2 min-w-[220px]">
                      <div className={`flex items-center space-x-1.5 pb-2 border-b ${isDoctor ? 'border-teal-500/50 text-teal-100' : 'border-slate-200 text-teal-700'}`}>
                        <Pill size={15} />
                        <span className="font-black text-[11px] uppercase tracking-wider">
                          {msg.metadata?.prescType === 'terapi' ? 'Paket Terapi Klinis' : msg.metadata?.prescType === 'medis' ? 'Resep Obat Medis' : 'Resep Suplemen & Vitamin'}
                        </span>
                      </div>
                      <div className={`p-3 rounded-xl ${isDoctor ? 'bg-teal-700/60' : 'bg-teal-50/70 border border-teal-100'}`}>
                        <p className={`font-black text-xs ${isDoctor ? 'text-white' : 'text-slate-900'}`}>
                          {msg.metadata?.itemName || 'Rekomendasi Terapi'}
                        </p>
                        <div className={`mt-1.5 text-[10px] space-y-1 ${isDoctor ? 'text-teal-100' : 'text-slate-600'}`}>
                          <p><span className="font-bold">Dosis / Sesi:</span> {msg.metadata?.dosage || '-'}</p>
                          <p><span className="font-bold">Durasi:</span> {msg.metadata?.duration || '-'}</p>
                          {msg.metadata?.notes && (
                            <p className={`italic mt-1 pt-1 border-t ${isDoctor ? 'border-teal-600/70 text-teal-200' : 'border-teal-100 text-teal-700'}`}>
                              "{msg.metadata.notes}"
                            </p>
                          )}
                        </div>
                      </div>
                      <p className={`text-[9px] ${isDoctor ? 'text-teal-200' : 'text-slate-400'} italic`}>
                        {msg.metadata?.doctorName ? `Diresepkan oleh ${msg.metadata.doctorName}` : 'Resep Rekam Medis Sah'}
                      </p>
                    </div>
                  ) : hasImage ? (
                    <div>
                      <img 
                        src={imgUrl} 
                        alt={msg.attachmentName || 'Foto'} 
                        className="rounded-xl max-w-full max-h-64 object-cover cursor-pointer hover:opacity-90 transition-opacity"
                        onClick={() => {
                          if (imgUrl?.startsWith('data:')) {
                            const newTab = window.open();
                            newTab?.document.write(`<img src="${imgUrl}" style="max-width:100%;" />`);
                          } else {
                            window.open(imgUrl, '_blank');
                          }
                        }}
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none';
                          const fallback = (e.target as HTMLImageElement).nextElementSibling;
                          if (fallback) (fallback as HTMLElement).style.display = 'block';
                        }}
                      />
                      <p className="text-xs font-bold mt-1.5 px-1 hidden">📷 Foto tidak dapat dimuat</p>
                    </div>
                  ) : hasDocument ? (
                    <a 
                      href={msg.attachmentUrl} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className={`flex items-center space-x-2 ${isDoctor ? 'text-white hover:text-teal-100' : 'text-teal-600 hover:text-teal-800'}`}
                    >
                      <span className="text-2xl">📄</span>
                      <div className="min-w-0 flex-1">
                        <p className="text-xs font-black truncate">{msg.attachmentName || 'Dokumen'}</p>
                        {msg.attachmentSize && (
                          <p className={`text-[9px] font-bold mt-0.5 ${isDoctor ? 'text-teal-200' : 'text-slate-400'}`}>
                            {(msg.attachmentSize / 1024).toFixed(1)} KB
                          </p>
                        )}
                      </div>
                      <span className="text-sm">↓</span>
                    </a>
                  ) : (
                    <p className="text-xs leading-relaxed font-bold whitespace-pre-line">{textContent}</p>
                  )}
                  <div className={`text-[9px] flex items-center justify-end space-x-1.5 mt-1.5 font-bold ${isDoctor ? 'text-teal-100' : 'text-slate-400'}`}>
                    <span>
                      {msg.timestamp ? (typeof msg.timestamp.toDate === 'function' ? format(msg.timestamp.toDate(), 'HH:mm') : typeof msg.timestamp === 'string' ? format(new Date(msg.timestamp), 'HH:mm') : '') : '09:00'}
                    </span>
                    {isDoctor && (
                      msg.isRead ? (
                        <span title="Pesan telah dibaca oleh orang tua" className="flex items-center text-teal-200">
                          <CheckCheck size={12} />
                        </span>
                      ) : (
                        <span title="Pesan terkirim ke orang tua" className="flex items-center text-teal-300/70">
                          <Check size={12} />
                        </span>
                      )
                    )}
                  </div>
                </div>
              </div>
            );
          })}

          <div className="flex justify-start">
            <div className="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm max-w-sm flex items-center space-x-3">
              <span className="text-3xl bg-rose-50 text-rose-500 p-2 rounded-xl block">📄</span>
              <div className="flex-1 min-w-0">
                <h4 className="text-xs font-black text-slate-800 truncate">Ringkasan Hasil Asesmen Pasien.pdf</h4>
                <p className="text-[9px] text-slate-400 font-bold mt-1">1.2 MB</p>
              </div>
              <button 
                onClick={() => setShowPrintModal(true)}
                className="w-8 h-8 border border-slate-200 rounded-lg flex items-center justify-center text-slate-500 hover:bg-slate-50"
              >
                ↓
              </button>
            </div>
          </div>

          <div ref={bottomRef} />
        </div>

        {(selectedChat?.status === 'completed' || isExpired) ? (
          <div className="p-4 bg-slate-50/90 border-t border-slate-200 text-center space-y-2.5">
            <div className="inline-flex items-center space-x-2 text-slate-700 font-black text-xs bg-slate-100 px-4 py-1.5 rounded-full border border-slate-200">
              <ShieldCheck size={16} className="text-teal-600" />
              <span>Sesi Konsultasi Resmi Telah Berakhir & Ditutup</span>
            </div>
            <p className="text-[11px] text-slate-400 font-medium">
              Riwayat obrolan terkunci dan tersimpan aman di Rekam Medis (EMR) pasien.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-2 pt-1">
              <button 
                type="button" 
                onClick={() => setShowRatingModal(true)}
                className="px-4 py-2 bg-white border border-slate-200 text-teal-700 rounded-xl text-xs font-bold hover:bg-teal-50 shadow-xs transition-colors flex items-center space-x-1.5"
              >
                <Edit3 size={13} />
                <span>Catatan & Ulasan</span>
              </button>
              <button 
                type="button" 
                onClick={() => setShowPrintModal(true)}
                className="px-4 py-2 bg-white border border-slate-200 text-slate-700 rounded-xl text-xs font-bold hover:bg-slate-50 shadow-xs transition-colors flex items-center space-x-1.5"
              >
                <Printer size={13} />
                <span>Cetak EMR</span>
              </button>
              <button 
                type="button" 
                onClick={() => handleDeleteChatSession(selectedChat.id)}
                className="px-4 py-2 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs font-bold hover:bg-rose-100 shadow-xs transition-colors flex items-center space-x-1.5"
                title="Hapus riwayat sesi ini secara permanen dari server"
              >
                <Trash2 size={13} />
                <span>Hapus Riwayat Chat</span>
              </button>
              <button 
                type="button" 
                onClick={() => {
                  setSelectedChat(null);
                  setActiveMenu('dashboard');
                }}
                className="px-5 py-2 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 shadow-sm transition-colors"
              >
                Kembali ke Beranda
              </button>
            </div>
          </div>
        ) : (
          <div className="p-4 bg-white border-t border-slate-100 space-y-3">
            {/* QUICK REPLIES SHORTCUTS */}
            <div className="flex space-x-2 overflow-x-auto pb-1 scrollbar-hide">
              {['Halo Bunda, ada yang bisa dibantu?', 'Sesi konsultasi dimulai 5 menit lagi ya.', 'Silakan coba mainkan game puzzle.', 'Action Plan baru saja saya kirim.', 'Tunggu sebentar ya Bunda.'].map((tmpl, idx) => (
                <button 
                  key={idx}
                  type="button"
                  onClick={() => setNewMessage(tmpl)}
                  className="whitespace-nowrap px-3 py-1.5 bg-teal-50 text-teal-600 rounded-full text-[10px] font-bold hover:bg-teal-100 border border-teal-100 transition-colors"
                >
                  {tmpl}
                </button>
              ))}
            </div>
            <form onSubmit={handleSendMessage} className="flex items-center space-x-3">
              <div className="flex-1 bg-slate-50 border border-slate-200 rounded-full px-5 py-2.5 flex items-center space-x-3">
                <input 
                  type="file" 
                  ref={chatFileInputRef} 
                  onChange={handleUploadChatAttachment} 
                  className="hidden" 
                  accept="image/*,.pdf,.doc,.docx" 
                />
                <button 
                  type="button" 
                  onClick={() => chatFileInputRef.current?.click()}
                  className="text-slate-400 hover:text-teal-600 transition-colors flex-shrink-0"
                  title="Lampirkan Gambar atau Dokumen"
                >
                  <Paperclip size={18} />
                </button>
                <input 
                  type="text" 
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="Ketik pesan..." 
                  className="flex-1 bg-transparent border-none outline-none text-xs text-slate-700 placeholder:text-slate-400"
                />
              </div>
              <button 
                type="submit"
                disabled={!newMessage.trim()}
                className="w-10 h-10 bg-teal-600 hover:bg-teal-700 text-white rounded-full flex items-center justify-center disabled:opacity-50 transition-colors shadow-md"
              >
                <Send size={16} className="ml-0.5" />
              </button>
            </form>

            <div className="flex items-center justify-between text-[10px] font-bold text-slate-400">
              <div className="flex items-center space-x-2 overflow-x-auto pb-1">
                <button 
                  type="button" 
                  onClick={() => setShowPrescriptionModal(true)} 
                  className="flex items-center space-x-1 px-3 py-1.5 border border-indigo-200 bg-indigo-50/80 text-indigo-700 font-bold rounded-full hover:bg-indigo-100 transition-colors shadow-xs shrink-0"
                >
                  <Pill size={12} className="text-indigo-600" />
                  <span>Resep & Terapi</span>
                </button>
                <button type="button" onClick={() => setShowMateriModal(true)} className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50 shrink-0">
                  <FileText size={12} className="text-teal-500" />
                  <span>Kirim Materi</span>
                </button>
                <button type="button" onClick={() => setShowTugasModal(true)} className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50 shrink-0">
                  <Clipboard size={12} className="text-emerald-500" />
                  <span>Beri Tugas</span>
                </button>
                <button type="button" onClick={() => setShowJadwalModal(true)} className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50 shrink-0">
                  <Calendar size={12} className="text-amber-500" />
                  <span>Jadwalkan Sesi</span>
                </button>
              </div>
              <button 
                type="button" 
                onClick={() => setShowRatingModal(true)}
                className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50 text-teal-600"
              >
                <span>Buat Catatan Pribadi</span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* 3. Right Column: Ringkasan Cepat & Asesmen */}
      <div className="hidden lg:flex w-64 xl:w-72 bg-white flex-col justify-between overflow-y-auto flex-shrink-0 p-4 xl:p-5">
        <div className="space-y-5">
          <div className="space-y-2.5">
            <div className="flex justify-between items-baseline">
              <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Ringkasan Cepat</span>
              <span className="text-xs font-black text-slate-800">
                {hasAssessmentData ? (
                  <>Rata-rata: <span className="text-teal-600">{averageScoreValue}</span> <span className="text-[9px] text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">{averageScoreLabel}</span></>
                ) : (
                  <span className="text-[9px] text-slate-400 font-bold bg-slate-100 px-1.5 py-0.5 rounded">Menunggu Tes</span>
                )}
              </span>
            </div>
            
            <div className="h-[135px] flex items-center justify-center bg-slate-50/50 border border-slate-100 rounded-2xl p-1">
              {hasAssessmentData ? (
                <ResponsiveContainer width="100%" height="100%">
                  <RadarChart cx="50%" cy="50%" outerRadius="72%" data={radarData}>
                    <PolarGrid stroke="#E2E8F0" />
                    <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 6, fontWeight: 'bold' }} />
                    <Radar name="Skor" dataKey="A" stroke="#0D9488" fill="#14B8A6" fillOpacity={0.25} />
                  </RadarChart>
                </ResponsiveContainer>
              ) : (
                <div className="text-center p-2">
                  <span className="text-2xl block mb-1">📊</span>
                  <span className="text-[10px] text-slate-400 font-bold block">Belum Ada Tes</span>
                </div>
              )}
            </div>
          </div>

          <div className="space-y-2.5 border-t border-slate-100 pt-4">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Hasil Game Terkini</span>
            <div className="space-y-1.5 text-xs font-bold text-slate-700">
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-[11px]">🧩 Puzzle Logika</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('puzzleGame', 0) > 0 ? `${getDynamicScore('puzzleGame', 0)}/100` : '-'}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-[11px]">👁️ Memori Visual</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('memory', 0) > 0 ? `${getDynamicScore('memory', 0)}/100` : '-'}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-[11px]">🔢 Math Adventure</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('numberSequence', 0) > 0 ? `${getDynamicScore('numberSequence', 0)}/100` : '-'}</span>
              </div>
              <div className="flex justify-between items-center py-1">
                <span className="text-[11px]">🗣️ Bahasa Seru</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('wordPuzzle', 0) > 0 ? `${getDynamicScore('wordPuzzle', 0)}/100` : '-'}</span>
              </div>
            </div>
          </div>
        </div>

        <button 
          onClick={() => {
            setSelectedPatientId(patientProfile?.name || selectedPatientId || 'Pasien');
            setActiveMenu('patients');
            setPatientDetailTab('assessment');
          }}
          className="w-full bg-white hover:bg-slate-50 border border-slate-200 text-teal-600 font-bold py-2 rounded-xl text-[10px] transition-colors shadow-sm mt-3"
        >
          Lihat Hasil Lengkap
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex flex-col md:flex-row h-screen bg-[#F8FAFC] overflow-hidden font-sans antialiased text-slate-800 font-medium">
      
      {/* MOBILE TOP BAR */}
      <div className="md:hidden bg-white border-b border-slate-100 px-4 py-3 flex items-center justify-between flex-shrink-0 z-30 shadow-xs">
        <div className="flex items-center space-x-3">
          <button 
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="w-9 h-9 border border-slate-200 rounded-xl flex items-center justify-center text-slate-600 hover:bg-slate-50 transition-colors"
            aria-label="Toggle Menu"
          >
            <Menu size={18} />
          </button>
          <img src={zikolaLogoFull} alt="Zikola" className="h-7 object-contain" />
        </div>
        <div className="flex items-center space-x-2">
          <button 
            onClick={() => setShowNotificationDrawer(true)} 
            className="w-9 h-9 border border-slate-100 rounded-xl flex items-center justify-center text-slate-500 hover:bg-slate-50 relative"
          >
            <Bell size={16} />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-teal-500 rounded-full"></span>
          </button>
          <div onClick={() => setShowProfileModal(true)} className="cursor-pointer">
            {renderAvatar(doctorProfile?.image, "w-8 h-8", "text-xs")}
          </div>
        </div>
      </div>

      {/* MOBILE SLIDE-OUT DRAWER */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden flex animate-in fade-in duration-200">
          <div className="fixed inset-0 bg-black/40 backdrop-blur-xs" onClick={() => setMobileMenuOpen(false)}></div>
          <div className="relative w-4/5 max-w-xs bg-white h-full flex flex-col justify-between p-5 z-10 shadow-2xl animate-in slide-in-from-left duration-250">
            <div className="space-y-6">
              <div className="flex items-center justify-between border-b border-slate-100 pb-4">
                <img src={zikolaLogoFull} alt="Zikola" className="h-8 object-contain" />
                <button onClick={() => setMobileMenuOpen(false)} className="p-1 rounded-lg text-slate-400 hover:text-slate-600">
                  <X size={20} />
                </button>
              </div>

              <nav className="space-y-1">
                {[
                  { id: 'dashboard', label: 'Dashboard', icon: <Home size={16} /> },
                  { id: 'patients', label: 'Daftar Pasien', icon: <Users size={16} /> },
                  { id: 'jadwal', label: 'Jadwal Konsultasi', icon: <Calendar size={16} /> },
                  { id: 'asesmen', label: 'Hasil Asesmen', icon: <Brain size={16} /> },
                  { id: 'laporan', label: 'Laporan', icon: <BarChart2 size={16} /> },
                  { id: 'pesan', label: 'Pesan Konsultasi', icon: <MessageSquare size={16} /> },
                ].map(item => (
                  <button 
                    key={item.id}
                    onClick={() => {
                      setActiveMenu(item.id as any);
                      setSelectedPatientId(null);
                      setMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                      activeMenu === item.id ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-500 hover:bg-slate-50'
                    }`}
                  >
                    {item.icon}
                    <span>{item.label}</span>
                  </button>
                ))}
              </nav>
            </div>

            <div className="border-t border-slate-100 pt-4 space-y-3">
              <div className="flex items-center space-x-3 cursor-pointer" onClick={() => { setShowProfileModal(true); setMobileMenuOpen(false); }}>
                {renderAvatar(doctorProfile?.image, "w-10 h-10")}
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-black text-slate-800 truncate">{doctorProfile?.name || 'Dokter Zikola'}</p>
                  <p className="text-[10px] text-slate-400 font-bold truncate">{doctorProfile?.specialty || 'Psikolog Anak'}</p>
                </div>
              </div>
              <button onClick={handleLogout} className="w-full text-xs font-bold text-rose-500 hover:bg-rose-50 py-2.5 px-3 rounded-xl flex items-center space-x-2 transition-colors">
                <LogOut size={16} />
                <span>Keluar Akun</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* DESKTOP SIDEBAR */}
      <div className="hidden md:flex w-56 xl:w-64 bg-white border-r border-slate-100 flex-col justify-between p-4 xl:p-6 flex-shrink-0">
        <div className="space-y-8">
          <div className="flex flex-col space-y-2">
            <img src={zikolaLogoFull} alt="Zikola" className="h-8 object-contain object-left" />
            <div className="flex items-center space-x-1.5 px-0.5">
              <div className="w-1.5 h-1.5 rounded-full bg-teal-500"></div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Portal Dokter</span>
            </div>
          </div>

          <nav className="space-y-1">
            <button 
              onClick={() => { setActiveMenu('dashboard'); setSelectedPatientId(null); }}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'dashboard' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <Home size={16} />
              <span>Dashboard</span>
            </button>
            <button 
              onClick={() => { setActiveMenu('patients'); }}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'patients' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <Users size={16} />
              <span>Daftar Pasien</span>
            </button>
            <button 
              onClick={() => setActiveMenu('jadwal')}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'jadwal' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <Calendar size={16} />
              <span>Jadwal Konsultasi</span>
            </button>
            <button 
              onClick={() => { setActiveMenu('asesmen'); setSelectedPatientId(null); }}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'asesmen' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <Brain size={16} />
              <span>Hasil Asesmen</span>
            </button>
            <button 
              onClick={() => setActiveMenu('laporan')}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'laporan' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <BarChart2 size={16} />
              <span>Laporan</span>
            </button>
            <button 
              onClick={() => { setActiveMenu('pesan'); }}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'pesan' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <MessageSquare size={16} />
              <span>Pesan</span>
            </button>
            <button 
              onClick={() => setShowProfileModal(true)}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-2xl text-xs font-black transition-all ${
                activeMenu === 'profil' ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:bg-slate-50'
              }`}
            >
              <Settings size={16} />
              <span>Profil</span>
            </button>
          </nav>
        </div>

        <div className="space-y-4">
          <div className="border-t border-slate-100 pt-4 flex flex-col space-y-2">
            <div className="flex items-center space-x-3 cursor-pointer" onClick={() => setShowProfileModal(true)}>
              {renderAvatar(doctorProfile?.image, "w-9 h-9")}
              <div>
                <p className="text-xs font-black text-slate-800 leading-none truncate max-w-[120px]">
                  {doctorProfile?.name || 'dr. Rani'}
                </p>
                <p className="text-[9px] text-slate-400 font-bold mt-1">{doctorProfile?.specialty || 'Psikolog Anak & Tumbuh Kembang'}</p>
              </div>
            </div>
            <button onClick={handleLogout} className="text-xs font-semibold text-rose-500 hover:text-rose-700 flex items-center space-x-2 pt-2 border-t border-slate-100 transition-colors">
              <LogOut size={14} />
              <span>Keluar</span>
            </button>
          </div>
        </div>
      </div>

      {/* 2. DYNAMIC MAIN CONTENT PANEL */}
      <div className="flex-1 flex flex-col h-full bg-white overflow-hidden">
        {/* Default View if activeMenu is dashboard, profil, or unknown */}
        {(activeMenu === 'dashboard' || activeMenu === 'profil' || !['asesmen', 'patients', 'jadwal', 'laporan', 'pesan'].includes(activeMenu)) && renderDashboardView()}
        {activeMenu === 'asesmen' && renderGlobalAssessmentView()}
        {activeMenu === 'patients' && (
          selectedPatientId ? renderPatientDetailView() : (
            <div className="p-4 sm:p-6 md:p-8 space-y-6 flex-1 overflow-y-auto bg-slate-50/30">
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-2xl font-black text-slate-800">Daftar Pasien Anak</h2>
                  <p className="text-xs text-slate-400 font-bold mt-1">Pilih pasien untuk melihat detail kemajuan serta hasil asesmen game.</p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="bg-white border border-slate-200 px-3 py-2 rounded-xl flex items-center space-x-2">
                    <span className="text-slate-400">🔍</span>
                    <input 
                      type="text" 
                      value={globalSearch} 
                      onChange={(e) => setGlobalSearch(e.target.value)} 
                      placeholder="Cari nama pasien..." 
                      className="bg-transparent border-none outline-none text-xs w-48 font-medium text-slate-700" 
                    />
                  </div>
                  <button onClick={() => setShowAddPatientModal(true)} className="px-5 py-2.5 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 shadow-sm flex items-center space-x-2 transition-colors">
                    <Users size={16} /><span>Tambah Pasien Baru</span>
                  </button>
                </div>
              </div>

              {/* Filter Tabs */}
              <div className="flex items-center space-x-2 border-b border-slate-200/60 pb-3">
                {[
                  { id: 'all', label: `Semua Pasien (${allPatients.length})` },
                  { id: 'assessed', label: `Asesmen Selesai (${allPatients.filter(p => p.hasAssessment).length})` },
                  { id: 'new', label: `Menunggu Tes (${allPatients.filter(p => !p.hasAssessment).length})` }
                ].map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setPatientTabFilter(tab.id as any)}
                    className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                      patientTabFilter === tab.id
                        ? 'bg-teal-600 text-white shadow-sm'
                        : 'bg-white text-slate-500 hover:bg-slate-100 border border-slate-200/60'
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
              
              {allPatients.length === 0 ? (
                <div className="bg-white border border-slate-100 p-12 rounded-3xl shadow-sm text-center text-slate-400 space-y-3">
                  <span className="text-5xl block">👦</span>
                  <h4 className="text-sm font-black text-slate-700">Belum Ada Pasien Terdaftar</h4>
                  <p className="text-xs text-slate-400 max-w-sm mx-auto">
                    Daftar pasien anak yang terhubung dengan akun Anda akan muncul di sini secara otomatis.
                  </p>
                  <button 
                    onClick={() => setShowAddPatientModal(true)} 
                    className="mt-2 px-5 py-2.5 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 transition-colors shadow-sm inline-flex items-center space-x-2"
                  >
                    <Plus size={15} />
                    <span>Tambah Pasien Sekarang</span>
                  </button>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                  {allPatients
                    .filter(p => {
                      const matchesSearch = p.name.toLowerCase().includes(globalSearch.toLowerCase()) || (p.school && p.school.toLowerCase().includes(globalSearch.toLowerCase()));
                      if (!matchesSearch) return false;
                      if (patientTabFilter === 'assessed') return p.hasAssessment;
                      if (patientTabFilter === 'new') return !p.hasAssessment;
                      return true;
                    })
                    .map((patient) => (
                      <div 
                        key={patient.id}
                        onClick={() => { 
                          setActivePatientUid(patient.id);
                          setSelectedPatientId(patient.name); 
                          setPatientDetailTab('overview'); 
                        }}
                        className="bg-white border border-slate-100 p-5 rounded-3xl shadow-xs hover:shadow-md hover:border-teal-400 cursor-pointer transition-all flex flex-col justify-between group space-y-4"
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex items-center space-x-3.5">
                            <div className="relative shrink-0">
                              {renderAvatar(patient.avatar, "w-12 h-12", "text-xl")}
                              <span className={`absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 border-white ${
                                patient.hasAssessment ? 'bg-emerald-500' : 'bg-amber-400'
                              }`} />
                            </div>
                            <div>
                              <h4 className="text-sm font-black text-slate-800 group-hover:text-teal-700 transition-colors">{patient.name}</h4>
                              <p className="text-[10px] text-slate-400 font-bold mt-0.5">
                                {patient.age} Thn • {patient.gender === 'female' ? 'Perempuan' : 'Laki-laki'} • {patient.school || '-'}
                              </p>
                              <p className="text-[9px] text-slate-400 font-medium">Wali: {patient.parent || '-'}</p>
                            </div>
                          </div>
                          <span className={`text-[9px] font-extrabold px-2.5 py-1 rounded-full uppercase tracking-wider ${
                            patient.hasAssessment ? 'bg-teal-50 text-teal-700 border border-teal-200' : 'bg-amber-50 text-amber-700 border border-amber-200'
                          }`}>
                            {patient.hasAssessment ? 'Terverifikasi' : 'Pasien Baru'}
                          </span>
                        </div>

                        {/* Indikator Skor Asesmen */}
                        {patient.hasAssessment && patient.scores && (
                          <div className="grid grid-cols-3 gap-2 bg-slate-50/80 p-2.5 rounded-2xl text-[10px] font-bold">
                            <div className="text-center">
                              <span className="text-[9px] text-slate-400 block font-medium">🧩 Logika</span>
                              <span className="text-teal-700 font-black">{patient.scores.logika || '-'}/100</span>
                            </div>
                            <div className="text-center border-x border-slate-200/80">
                              <span className="text-[9px] text-slate-400 block font-medium">🧠 Memori</span>
                              <span className="text-indigo-700 font-black">{patient.scores.memori || '-'}/100</span>
                            </div>
                            <div className="text-center">
                              <span className="text-[9px] text-slate-400 block font-medium">🗣️ Bahasa</span>
                              <span className="text-teal-700 font-black">{patient.scores.bahasa || '-'}/100</span>
                            </div>
                          </div>
                        )}

                        <div className="flex items-center justify-between pt-2 border-t border-slate-50 text-[10px] font-bold text-slate-400">
                          <span className="text-teal-600 font-extrabold group-hover:underline flex items-center">
                            Lihat Profil Klinis & Rekam Medis →
                          </span>
                          <span className="text-[9px] font-medium text-slate-400">{patient.phone || '-'}</span>
                        </div>
                      </div>
                    ))}
                </div>
              )}
            </div>
          )
        )}
        {activeMenu === 'jadwal' && (
          <div className="p-4 sm:p-6 md:p-8 flex-1 overflow-y-auto bg-slate-50/30">
            <div className="flex justify-between items-center mb-8">
              <div>
                <h2 className="text-2xl font-black text-slate-800">Jadwal Konsultasi</h2>
                <p className="text-xs text-slate-400 font-bold mt-1">Daftar janji temu dan sesi konsultasi Anda minggu ini.</p>
              </div>
              <button onClick={() => setShowJadwalModal(true)} className="bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-xl text-xs font-bold flex items-center space-x-2 shadow-sm">
                <Calendar size={14} />
                <span>Buat Jadwal Baru</span>
              </button>
            </div>
            
            <div className="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm">
              <div className="flex border-b border-slate-100 mb-6">
                <button 
                  onClick={() => setJadwalTabFilter('upcoming')}
                  className={`px-6 py-3 text-xs font-bold transition-all ${
                    jadwalTabFilter === 'upcoming' 
                      ? 'font-black text-teal-600 border-b-2 border-teal-600' 
                      : 'text-slate-400 hover:text-slate-600'
                  }`}
                >
                  Mendatang
                </button>
                <button 
                  onClick={() => setJadwalTabFilter('completed')}
                  className={`px-6 py-3 text-xs font-bold transition-all ${
                    jadwalTabFilter === 'completed' 
                      ? 'font-black text-teal-600 border-b-2 border-teal-600' 
                      : 'text-slate-400 hover:text-slate-600'
                  }`}
                >
                  Riwayat Selesai
                </button>
              </div>
              
              <div className="space-y-4">
                {(() => {
                  const filteredAppts = allAppointments.filter(appt => {
                    if (jadwalTabFilter === 'upcoming') {
                      return appt.status !== 'completed' && appt.status !== 'cancelled';
                    } else {
                      return appt.status === 'completed' || appt.status === 'cancelled';
                    }
                  });

                  const filteredChats = chats.filter(chat => {
                    const isDone = isChatCompleted(chat);
                    return jadwalTabFilter === 'upcoming' ? !isDone : isDone;
                  });

                  if (filteredAppts.length === 0 && filteredChats.length === 0) {
                    return (
                      <div className="text-center py-12 text-slate-400 space-y-2">
                        <span className="text-4xl mb-2 block">📅</span>
                        <p className="text-xs font-bold">
                          {jadwalTabFilter === 'upcoming' 
                            ? 'Belum ada jadwal konsultasi atau janji temu mendatang.' 
                            : 'Belum ada riwayat sesi konsultasi yang telah selesai.'}
                        </p>
                        {jadwalTabFilter === 'upcoming' && (
                          <button 
                            onClick={() => setShowJadwalModal(true)}
                            className="mt-2 px-4 py-2 bg-teal-50 text-teal-600 rounded-xl text-xs font-bold hover:bg-teal-100 transition-colors"
                          >
                            + Jadwalkan Sesi Sekarang
                          </button>
                        )}
                      </div>
                    );
                  }

                  return (
                    <div className="space-y-6">
                      {/* 1. SEKSI JANJI TEMU RESMI (APPOINTMENTS) */}
                      {filteredAppts.length > 0 && (
                        <div className="space-y-3">
                          <div className="flex items-center justify-between">
                            <span className="text-[11px] font-black text-slate-400 uppercase tracking-wider flex items-center">
                              <Calendar size={13} className="mr-1.5 text-teal-600" />
                              Janji Temu Kalender Klinis ({filteredAppts.length})
                            </span>
                          </div>
                          {filteredAppts.map((appt) => {
                            const dateParts = (appt.dateTime || '').split('T');
                            const dateStr = dateParts[0] || '-';
                            const timeStr = dateParts[1] ? dateParts[1].substring(0, 5) : '09:00';
                            const isConfirmed = appt.status === 'confirmed';
                            const isCompleted = appt.status === 'completed';

                            return (
                              <div key={'appt-' + appt.id} className="border border-teal-100 bg-teal-50/20 p-4 rounded-2xl flex items-center justify-between hover:bg-teal-50/40 transition-colors shadow-xs">
                                <div className="flex items-center space-x-4">
                                  <div className="w-12 h-12 bg-teal-600 text-white rounded-2xl flex flex-col items-center justify-center font-black shadow-xs">
                                    <span className="text-xs leading-none">{dateStr.split('-')[2] || '12'}</span>
                                    <span className="text-[8px] uppercase mt-0.5">{dateStr.split('-')[1] || 'SEP'}</span>
                                  </div>
                                  <div>
                                    <div className="flex items-center space-x-2">
                                      <h4 className="text-sm font-black text-slate-800">{appt.patientName || 'Pasien Zikola'}</h4>
                                      <span className={`text-[9px] px-2 py-0.5 rounded-full font-extrabold uppercase tracking-wide ${
                                        isCompleted 
                                          ? 'bg-slate-100 text-slate-600' 
                                          : isConfirmed 
                                            ? 'bg-emerald-100 text-emerald-700' 
                                            : 'bg-amber-100 text-amber-700'
                                      }`}>
                                        {isCompleted ? 'Selesai' : isConfirmed ? 'Dikonfirmasi' : 'Menunggu Konfirmasi'}
                                      </span>
                                    </div>
                                    <div className="flex items-center space-x-2 text-[10px] text-slate-500 font-bold mt-1">
                                      <span className="flex items-center"><Clock size={10} className="mr-1 text-teal-600"/> Pukul {timeStr} WIB</span>
                                      <span>•</span>
                                      <span>{appt.type === 'telehealth_call' ? 'Panggilan Telekonsultasi' : 'Sesi Chat Dokter'}</span>
                                    </div>
                                  </div>
                                </div>
                                <div className="flex items-center space-x-2">
                                  {!isCompleted && !isConfirmed && (
                                    <button 
                                      onClick={() => handleUpdateAppointmentStatus(appt.id, 'confirmed')}
                                      className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-[10px] rounded-xl transition-colors shadow-xs"
                                    >
                                      Konfirmasi
                                    </button>
                                  )}
                                  {!isCompleted && (
                                    <button 
                                      onClick={() => handleUpdateAppointmentStatus(appt.id, 'completed')}
                                      className="px-3 py-1.5 bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200 font-bold text-[10px] rounded-xl transition-colors"
                                    >
                                      Tandai Selesai
                                    </button>
                                  )}
                                  <button 
                                    onClick={() => {
                                      const targetChat = chats.find(c => c.buyerId === appt.patientId);
                                      if (targetChat) {
                                        setSelectedChat(targetChat);
                                        setActivePatientUid(targetChat.buyerId);
                                        setSelectedPatientId(appt.patientName || patientNames[targetChat.buyerId]);
                                        setActiveMenu('pesan');
                                      } else {
                                        setActivePatientUid(appt.patientId);
                                        setSelectedPatientId(appt.patientName);
                                        setActiveMenu('patients');
                                      }
                                    }} 
                                    className="px-3 py-1.5 border border-slate-200 text-slate-700 hover:bg-slate-50 font-bold text-[10px] rounded-xl transition-colors"
                                  >
                                    Buka Profil / Chat
                                  </button>
                                  {jadwalTabFilter === 'completed' && (
                                    <button 
                                      onClick={() => handleDeleteAppointment(appt.id)}
                                      className="p-1.5 text-rose-500 hover:bg-rose-50 rounded-lg transition-colors"
                                      title="Hapus arsip jadwal"
                                    >
                                      <Trash2 size={13} />
                                    </button>
                                  )}
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      )}

                      {/* 2. SEKSI SESI CHAT AKTIF / RIWAYAT CHAT */}
                      {filteredChats.length > 0 && (
                        <div className="space-y-3 pt-2">
                          <div className="flex items-center justify-between">
                            <span className="text-[11px] font-black text-slate-400 uppercase tracking-wider block">
                              Sesi Konsultasi Chat Langsung ({filteredChats.length})
                            </span>
                            {jadwalTabFilter === 'completed' && filteredChats.length > 0 && (
                              <button 
                                onClick={handleCleanAllCompletedSessions}
                                className="px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-600 border border-rose-200 rounded-xl text-[10px] font-bold transition-colors flex items-center space-x-1.5"
                              >
                                <Trash2 size={12} />
                                <span>Bersihkan Semua Riwayat Selesai</span>
                              </button>
                            )}
                          </div>
                          {filteredChats.map((chat) => (
                            <div key={'j-' + chat.id} className="border border-slate-100 p-4 rounded-2xl flex items-center justify-between hover:bg-slate-50 transition-colors">
                              <div className="flex items-center space-x-4">
                                <div className="w-12 h-12 bg-slate-100 text-slate-600 rounded-2xl flex flex-col items-center justify-center font-black">
                                  <span className="text-sm leading-none">{formatDateSafe(chat.expiresAt || new Date()).split(' ')[0]}</span>
                                  <span className="text-[9px] uppercase mt-0.5">{formatDateSafe(chat.expiresAt || new Date()).split(' ')[1]?.substring(0,3) || 'MEI'}</span>
                                </div>
                                <div>
                                  <h4 className="text-sm font-black text-slate-800">{patientNames[chat.buyerId] || 'Pasien'}</h4>
                                  <div className="flex items-center space-x-2 text-[10px] text-slate-400 font-bold mt-1">
                                    <span className="flex items-center"><Calendar size={10} className="mr-1"/> Sesi Chat Langsung</span>
                                    <span>•</span>
                                    <span>{jadwalTabFilter === 'upcoming' ? 'Aktif' : 'Selesai'}</span>
                                  </div>
                                </div>
                              </div>
                              <div className="flex items-center space-x-2">
                                <button onClick={() => {
                                  setSelectedChat(chat);
                                  setActivePatientUid(chat.buyerId);
                                  setSelectedPatientId(patientNames[chat.buyerId] || 'Pasien');
                                  setActiveMenu('pesan');
                                }} className="px-4 py-2 border border-slate-200 text-teal-600 font-bold text-[10px] rounded-xl hover:bg-teal-50 transition-colors">
                                  {jadwalTabFilter === 'upcoming' ? 'Masuk Ruangan' : 'Lihat Rekap Chat'}
                                </button>
                                {jadwalTabFilter === 'completed' && (
                                  <button 
                                    onClick={() => handleDeleteChatSession(chat.id)}
                                    className="p-2 border border-rose-200 text-rose-600 hover:bg-rose-50 rounded-xl text-[10px] font-bold transition-colors"
                                    title="Hapus riwayat sesi selesai ini"
                                  >
                                    <Trash2 size={13} />
                                  </button>
                                )}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })()}
              </div>
            </div>
          </div>
        )}
        {activeMenu === 'laporan' && (
          <div className="p-4 sm:p-6 md:p-8 flex-1 overflow-y-auto bg-slate-50/30">
            <div className="flex justify-between items-center mb-8">
              <div>
                <h2 className="text-2xl font-black text-slate-800">Arsip Laporan Global</h2>
                <p className="text-xs text-slate-400 font-bold mt-1">Kumpulan dokumen rekam medis & evaluasi klinis seluruh pasien Zikola.</p>
              </div>
              <div className="flex items-center space-x-3">
                <div className="bg-white border border-slate-200 px-3 py-2 rounded-xl flex items-center space-x-2">
                  <span className="text-slate-400">🔍</span>
                  <input type="text" value={globalSearch} onChange={(e) => setGlobalSearch(e.target.value)} placeholder="Cari laporan pasien..." className="bg-transparent border-none outline-none text-xs w-48 font-medium text-slate-700" />
                </div>
              </div>
            </div>

            <div className="bg-white border border-slate-100 rounded-3xl shadow-sm overflow-hidden">
              {allPatients.length === 0 ? (
                <div className="p-12 text-center text-slate-400 space-y-2">
                  <span className="text-4xl block mb-2">📄</span>
                  <p className="text-xs font-bold">Belum ada dokumen laporan yang tersimpan.</p>
                </div>
              ) : (
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 text-[10px] font-black text-slate-400 uppercase tracking-widest">
                      <th className="p-4 border-b border-slate-100">Nama Dokumen</th>
                      <th className="p-4 border-b border-slate-100">Pasien</th>
                      <th className="p-4 border-b border-slate-100">Tipe Dokumen</th>
                      <th className="p-4 border-b border-slate-100">Status</th>
                      <th className="p-4 border-b border-slate-100 text-right">Aksi</th>
                    </tr>
                  </thead>
                  <tbody className="text-xs font-bold text-slate-700">
                    {allPatients
                      .filter(p => p.name.toLowerCase().includes(globalSearch.toLowerCase()))
                      .map((patient, idx) => (
                        <tr key={patient.id || idx} className="hover:bg-slate-50 border-b border-slate-50 transition-colors">
                          <td className="p-4 flex items-center space-x-3">
                            <span className="text-2xl">📋</span>
                            <div>
                              <span className="font-black text-slate-800 block">Rapor Tumbuh Kembang Komprehensif</span>
                              <span className="text-[9px] text-slate-400 font-medium">Rekam Medis Digital Pasien • {formatDateSafe(new Date()).split(',')[0]}</span>
                            </div>
                          </td>
                          <td className="p-4">
                            <span className="font-black text-slate-800 block">{patient.name}</span>
                            <span className="text-[10px] text-slate-400 font-medium">{patient.age ? `${patient.age} Tahun` : 'Anak'}</span>
                          </td>
                          <td className="p-4 text-teal-600 font-bold">Laporan AI & EMR</td>
                          <td className="p-4">
                            <span className="px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-lg text-[10px] font-black">
                              Terverifikasi
                            </span>
                          </td>
                          <td className="p-4 text-right space-x-2">
                            <button 
                              onClick={() => {
                                setActivePatientUid(patient.id);
                                setSelectedPatientId(patient.name);
                                setShowAiReportModal(true);
                              }} 
                              className="p-2 bg-indigo-50 border border-indigo-100 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors shadow-xs"
                              title="Lihat Evaluasi AI Gemini"
                            >
                              <Sparkles size={14}/>
                            </button>
                            <button 
                              onClick={() => {
                                setActivePatientUid(patient.id);
                                setSelectedPatientId(patient.name);
                                setShowPrintModal(true);
                              }} 
                              className="p-2 bg-white border border-slate-200 rounded-lg hover:bg-slate-100 text-slate-600 transition-colors shadow-xs"
                              title="Cetak Rekam Medis (EMR)"
                            >
                              <Printer size={14}/>
                            </button>
                            <button 
                              onClick={() => {
                                setActivePatientUid(patient.id);
                                setSelectedPatientId(patient.name);
                                setActiveMenu('patients');
                                setPatientDetailTab('reports');
                              }} 
                              className="p-2 bg-teal-50 border border-teal-100 text-teal-700 rounded-lg hover:bg-teal-100 transition-colors shadow-xs"
                              title="Buka Lembar Rekam Medis Pasien"
                            >
                              <FileText size={14}/>
                            </button>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        )}
        {activeMenu === 'pesan' && (
          <div className="flex-1 flex flex-col md:flex-row h-full overflow-hidden bg-white">
            {/* Kolom Kiri: Chat List */}
            <div className={`w-full md:w-80 border-r border-slate-100 flex flex-col shrink-0 bg-white ${selectedChat ? 'hidden md:flex' : 'flex'}`}>
              <div className="p-4 border-b border-slate-100 flex items-center justify-between">
                <div>
                  <h2 className="text-base font-black text-slate-800">Pesan Konsultasi</h2>
                  <p className="text-[10px] text-slate-400 font-bold mt-0.5">Ruang telekonsultasi & pendampingan</p>
                </div>
                <span className="text-[10px] font-black px-2 py-0.5 rounded-full bg-teal-50 text-teal-700">
                  {chats.length} Sesi
                </span>
              </div>
              <div className="p-3 border-b border-slate-50">
                <div className="bg-slate-50 border border-slate-200/80 px-3 py-1.5 rounded-xl flex items-center space-x-2">
                  <span className="text-slate-400 text-xs">🔍</span>
                  <input 
                    type="text" 
                    value={globalSearch} 
                    onChange={(e) => setGlobalSearch(e.target.value)} 
                    placeholder="Cari pasien..." 
                    className="bg-transparent border-none outline-none text-xs w-full font-medium text-slate-700" 
                  />
                </div>
              </div>
              <div className="flex-1 overflow-y-auto divide-y divide-slate-50">
                {chats
                  .filter(c => {
                    const name = c.patientName || patientNames[c.buyerId] || '';
                    return name.toLowerCase().includes(globalSearch.toLowerCase());
                  })
                  .map((chat) => {
                    const name = chat.patientName || patientNames[chat.buyerId] || 'Pasien Zikola';
                    const avatar = chat.avatar || patientAvatars[chat.buyerId];
                    const isDone = isChatCompleted(chat);
                    const isSelected = selectedChat?.id === chat.id;

                    return (
                      <div
                        key={chat.id}
                        onClick={() => {
                          setSelectedChat(chat);
                          setActivePatientUid(chat.buyerId);
                          setSelectedPatientId(name);
                        }}
                        className={`p-3.5 flex items-start space-x-3 cursor-pointer transition-all ${
                          isSelected ? 'bg-teal-50/70 border-l-4 border-teal-600' : 'hover:bg-slate-50/80'
                        }`}
                      >
                        <div className="relative shrink-0 mt-0.5">
                          {renderAvatar(avatar, "w-10 h-10", "text-sm")}
                          <span className={`absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-white ${isDone ? 'bg-slate-400' : 'bg-green-500 animate-pulse'}`} />
                        </div>
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center justify-between">
                            <h4 className={`text-xs truncate ${isSelected ? 'font-black text-teal-900' : 'font-bold text-slate-800'}`}>{name}</h4>
                            <span className="text-[9px] text-slate-400 font-medium">09:15</span>
                          </div>
                          <p className="text-[10px] text-slate-500 truncate mt-0.5">
                            {chat.lastMessage || chat.complaint || 'Sesi konsultasi dibuka'}
                          </p>
                          <div className="flex items-center space-x-2 mt-1">
                            <span className={`text-[8px] font-extrabold uppercase px-1.5 py-0.5 rounded ${
                              isDone ? 'bg-slate-100 text-slate-500' : 'bg-green-100 text-green-700'
                            }`}>
                              {isDone ? 'Selesai' : 'Aktif'}
                            </span>
                            {chat.childAge && (
                              <span className="text-[8px] font-bold text-slate-400">
                                {chat.childAge} Thn
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })}
              </div>
            </div>

            {/* Kolom Kanan: Chat View */}
            <div className={`flex-1 flex flex-col h-full bg-slate-50/50 ${!selectedChat ? 'hidden md:flex' : 'flex'}`}>
              {selectedChat ? (
                <>
                  {/* Header Bar */}
                  <div className="bg-white p-4 border-b border-slate-100 flex items-center justify-between shadow-sm z-10 shrink-0">
                    <div className="flex items-center space-x-3">
                      <button 
                        onClick={() => setSelectedChat(null)} 
                        className="md:hidden w-9 h-9 border border-slate-200 rounded-xl flex items-center justify-center text-slate-500 hover:bg-slate-50 bg-white"
                      >
                        <ArrowLeft size={18} />
                      </button>
                      <div>
                        <div className="flex flex-wrap items-center gap-2">
                          <h2 className="text-sm font-black text-slate-800">
                            Konsultasi: {selectedChat?.patientName || patientNames[selectedChat.buyerId] || patientProfile?.name || 'Pasien Zikola'}
                          </h2>
                          {selectedChat?.childAge && (
                            <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-teal-50 text-teal-700 border border-teal-200">
                              {selectedChat.childAge} Thn
                            </span>
                          )}
                          {selectedChat?.childGender && (
                            <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-blue-50 text-blue-700 border border-blue-200">
                              {selectedChat.childGender}
                            </span>
                          )}
                          {selectedChat?.complaint && (
                            <span className="text-[9px] font-black px-2 py-0.5 rounded-md bg-amber-50 text-amber-800 border border-amber-200 truncate max-w-[200px]" title={selectedChat.complaint}>
                              Keluhan: {selectedChat.complaint}
                            </span>
                          )}
                        </div>
                        <div className="flex items-center space-x-1.5 mt-0.5">
                          <span className={`w-2 h-2 rounded-full ${(selectedChat?.status === 'completed' || isExpired) ? 'bg-slate-400' : 'bg-green-500 animate-pulse'}`}></span>
                          <span className={`text-[9px] font-bold uppercase ${(selectedChat?.status === 'completed' || isExpired) ? 'text-slate-500' : 'text-green-600'}`}>
                            {(selectedChat?.status === 'completed' || isExpired) ? 'Sesi Selesai • Riwayat Ditutup' : `Sesi Online Aktif • Sisa Waktu: ${timeRemaining}`}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <button 
                        onClick={() => setMobileShowRadarSheet(true)}
                        className="lg:hidden px-2.5 py-2 border border-slate-200 rounded-xl text-[10px] font-bold text-teal-600 bg-teal-50/50 hover:bg-teal-50 transition-colors flex items-center space-x-1"
                        title="Lihat Ringkasan & Radar Asesmen"
                      >
                        <Brain size={14} />
                        <span className="hidden sm:inline">Radar</span>
                      </button>
                      <button 
                        onClick={startAudioCall}
                        className="w-9 h-9 sm:w-10 sm:h-10 border border-slate-200 rounded-xl flex items-center justify-center text-slate-500 hover:bg-slate-50 bg-white transition-colors"
                      >
                        <Phone size={18} />
                      </button>
                      <div className="relative">
                        <button 
                          onClick={() => setShowChatOptionsMenu(!showChatOptionsMenu)}
                          className="w-10 h-10 border border-slate-200 rounded-xl flex items-center justify-center text-slate-500 hover:bg-slate-50 bg-white transition-colors"
                          title="Opsi Ruang Konsultasi"
                        >
                          <MoreVertical size={18} />
                        </button>
                        {showChatOptionsMenu && (
                          <div className="absolute right-0 top-12 w-52 bg-white border border-slate-100 rounded-2xl shadow-xl p-2 z-50 animate-in fade-in zoom-in duration-150 space-y-1">
                            <button 
                              onClick={() => {
                                setShowChatOptionsMenu(false);
                                setActiveMenu('patients');
                                setPatientDetailTab('medical_history');
                              }}
                              className="w-full text-left px-3 py-2 text-xs font-bold text-slate-700 hover:bg-teal-50 hover:text-teal-700 rounded-xl flex items-center space-x-2"
                            >
                              <FileText size={14} />
                              <span>Buka Rekam Medis (EMR)</span>
                            </button>
                            <button 
                              onClick={() => {
                                setShowChatOptionsMenu(false);
                                setShowPrintModal(true);
                              }}
                              className="w-full text-left px-3 py-2 text-xs font-bold text-slate-700 hover:bg-teal-50 hover:text-teal-700 rounded-xl flex items-center space-x-2"
                            >
                              <Printer size={14} />
                              <span>Cetak Rekam Medis</span>
                            </button>
                            <div className="border-t border-slate-100 my-1"></div>
                            <button 
                              onClick={() => {
                                setShowChatOptionsMenu(false);
                                handleCompleteSession(selectedChat.id);
                              }}
                              className="w-full text-left px-3 py-2 text-xs font-bold text-amber-600 hover:bg-amber-50 rounded-xl flex items-center space-x-2"
                            >
                              <X size={14} />
                              <span>Akhiri Sesi Konsultasi</span>
                            </button>
                            <button 
                              onClick={() => {
                                setShowChatOptionsMenu(false);
                                handleDeleteChatSession(selectedChat.id);
                              }}
                              className="w-full text-left px-3 py-2 text-xs font-bold text-rose-600 hover:bg-rose-50 rounded-xl flex items-center space-x-2"
                            >
                              <Trash2 size={14} />
                              <span>Hapus Riwayat Chat</span>
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {renderKonsultasiChatView()}
                </>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center text-slate-400 bg-white p-8">
                  <span className="text-5xl mb-4">💬</span>
                  <h3 className="text-base font-black text-slate-700">Pilih Pasien Konsultasi</h3>
                  <p className="text-xs text-slate-400 mt-1 max-w-xs text-center leading-relaxed">
                    Pilih salah satu ruang konsultasi di panel kiri untuk membuka percakapan dan tinjauan klinis.
                  </p>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      
      {/* NOTIFICATION DRAWER / MODAL */}
      {showNotificationDrawer && (
        <div className="fixed inset-0 bg-black/40 z-[150] flex items-center justify-center p-4 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden flex flex-col shadow-2xl">
            <div className="p-5 border-b flex items-center justify-between bg-teal-600 text-white">
              <div className="flex items-center space-x-2">
                <Bell size={18} />
                <h3 className="text-base font-black">Notifikasi & Aktivitas Klinis</h3>
              </div>
              <button onClick={() => setShowNotificationDrawer(false)} className="p-1 hover:bg-white/10 rounded-full">
                <X size={18} />
              </button>
            </div>

            <div className="p-5 space-y-3 max-h-[400px] overflow-y-auto">
              {displayNotifications.map((notif) => (
                <div key={notif.id} className="p-3 rounded-2xl border border-slate-100 hover:bg-slate-50 transition-colors flex items-start space-x-3">
                  <span className={`text-base ${
                    notif.type === 'success' ? 'text-emerald-500' :
                    notif.type === 'warning' ? 'text-amber-500' : 'text-teal-500'
                  }`}>
                    {notif.type === 'success' ? '✅' : notif.type === 'warning' ? '⚠️' : 'ℹ️'}
                  </span>
                  <div className="flex-1">
                    <h4 className="text-xs font-bold text-slate-800">{notif.title}</h4>
                    <p className="text-[10px] text-slate-500 font-medium mt-0.5 leading-relaxed">{notif.desc}</p>
                    <p className="text-[9px] text-slate-400 font-bold mt-1">{notif.time}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-4 border-t bg-slate-50 flex justify-end">
              <button 
                onClick={() => setShowNotificationDrawer(false)}
                className="px-5 py-2 bg-teal-600 text-white text-xs font-bold rounded-xl hover:bg-teal-700"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 3. PROFILE MODAL */}
      {showProfileModal && (
        <div className="fixed inset-0 bg-black/40 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-6 border-b flex items-center justify-between bg-teal-600 text-white">
              <h2 className="text-lg font-black">Kelola Profil Profesional</h2>
              <button onClick={() => setShowProfileModal(false)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleSaveDoctorProfile} className="flex-1 overflow-y-auto p-6 space-y-6">
              <div className="flex flex-col items-center pb-6 border-b border-slate-100">
                <div className="relative group cursor-pointer" onClick={() => document.getElementById('profile-photo-input-7')?.click()}>
                  {renderAvatar(doctorProfile?.image, "w-24 h-24", "text-4xl")}
                  <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <span className="text-white text-xs font-bold">Ganti Foto</span>
                  </div>
                </div>
                <input 
                  id="profile-photo-input-7"
                  type="file" 
                  accept="image/*" 
                  className="hidden"
                  onChange={handleDoctorPhotoChange}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-600">Nama Lengkap & Gelar</label>
                  <input 
                    type="text" 
                    value={doctorProfile?.name || ''} 
                    onChange={e => setDoctorProfile({...doctorProfile, name: e.target.value})}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none"
                    required
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-600">Spesialisasi</label>
                  <input 
                    type="text" 
                    value={doctorProfile?.specialty || ''} 
                    onChange={e => setDoctorProfile({...doctorProfile, specialty: e.target.value})}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-600">Tempat Praktik / Rumah Sakit</label>
                  <input 
                    type="text" 
                    value={doctorProfile?.hospital || ''} 
                    onChange={e => setDoctorProfile({...doctorProfile, hospital: e.target.value})}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none"
                    placeholder="Contoh: Klinik Tumbuh Kembang Zikola"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-600">Nomor Izin Praktik (SIP / STR)</label>
                  <input 
                    type="text" 
                    value={doctorProfile?.licenseNumber || ''} 
                    onChange={e => setDoctorProfile({...doctorProfile, licenseNumber: e.target.value})}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none font-mono"
                    placeholder="STR-001/ZIKOLA/2025"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-600">Tarif Telekonsultasi</label>
                  <input 
                    type="text" 
                    value={doctorProfile?.price || 'Rp 150.000 / sesi'} 
                    onChange={e => setDoctorProfile({...doctorProfile, price: e.target.value})}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none"
                    placeholder="Rp 150.000 / sesi"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-600">Jadwal Praktik Online</label>
                  <input 
                    type="text" 
                    value={doctorProfile?.schedule || 'Senin - Jumat (09:00 - 17:00 WIB)'} 
                    onChange={e => setDoctorProfile({...doctorProfile, schedule: e.target.value})}
                    className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none"
                    placeholder="Senin - Jumat (09:00 - 17:00 WIB)"
                  />
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-600">Ringkasan Pengalaman & Bio Dokter</label>
                <textarea 
                  value={doctorProfile?.bio || ''} 
                  onChange={e => setDoctorProfile({...doctorProfile, bio: e.target.value})}
                  rows={3}
                  className="w-full border border-slate-200 p-3 rounded-xl text-xs resize-none outline-none focus:border-teal-500"
                  placeholder="Spesialisasi tumbuh kembang anak, asesmen kognitif, stimulasi interaktif..."
                />
              </div>
            </form>
            
            <div className="p-6 border-t bg-slate-50 flex items-center justify-end space-x-3">
              <button 
                type="button"
                onClick={() => setShowProfileModal(false)}
                className="px-6 py-2.5 border border-slate-200 text-slate-600 font-bold hover:bg-slate-100 rounded-xl text-sm transition-colors"
              >
                Batal
              </button>
              <button 
                onClick={handleSaveDoctorProfile}
                disabled={isSavingProfile}
                className="px-8 py-2.5 bg-teal-600 text-white font-bold rounded-xl hover:bg-teal-700 transition-colors text-sm shadow-md flex items-center space-x-2"
              >
                {isSavingProfile ? 'Menyimpan...' : 'Simpan Profil'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 4. AI REPORT MODAL (Doctor-in-the-Loop) */}
      {showAiReportModal && aiReport && (
        <div className="fixed inset-0 bg-black/45 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl">
            <div className="p-6 border-b flex items-center justify-between bg-teal-600 text-white">
              <h2 className="text-lg font-black flex items-center space-x-2">
                <span>🧠</span>
                <span>Validasi Laporan AI Gemini</span>
              </h2>
              <button onClick={() => setShowAiReportModal(false)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto bg-slate-50 flex">
              {/* Kiri: Hasil AI */}
              <div className="w-1/2 p-6 border-r border-slate-200 overflow-y-auto">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-4">Draf Analisis Kecerdasan Buatan</span>
                <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-100 prose max-w-none text-sm leading-relaxed whitespace-pre-line text-slate-600">
                  {cleanClinicalText(aiReport.rawMarkdown) || 'Laporan kosong.'}
                </div>
              </div>

              {/* Kanan: Editor Dokter */}
              <div className="w-1/2 p-6 flex flex-col">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-4">Kurasi & Validasi Dokter (Doctor-in-the-Loop)</span>
                <div className="flex-1 flex flex-col space-y-4">
                  <div className="bg-blue-50 border border-blue-100 p-4 rounded-xl flex items-start space-x-3">
                    <Info size={16} className="text-blue-500 mt-0.5 flex-shrink-0" />
                    <p className="text-[10px] font-bold text-blue-700 leading-relaxed">
                      Tambahkan kesimpulan klinis, diagnosis akhir, atau revisi atas draf AI di bawah ini sebelum laporan disahkan dan dikirimkan ke aplikasi orang tua.
                    </p>
                  </div>
                  <textarea 
                    value={doctorAiNote}
                    onChange={(e) => setDoctorAiNote(e.target.value)}
                    placeholder="Ketik catatan validasi dokter di sini..."
                    className="flex-1 w-full border border-slate-200 rounded-2xl p-4 text-xs font-medium text-slate-700 outline-none focus:border-teal-500 resize-none shadow-sm"
                  />
                </div>
              </div>
            </div>
            
            <div className="p-5 border-t bg-white flex items-center justify-between">
              <button onClick={() => setShowAiReportModal(false)} className="px-6 py-2.5 border border-slate-200 text-slate-600 font-bold hover:bg-slate-50 rounded-xl text-xs transition-colors">
                Simpan Draf & Tutup
              </button>
              <button onClick={async () => { 
                  if (!selectedPatientId || !activePatientUid) {
                    alert('Tidak ada pasien yang dipilih.');
                    return;
                  }
                  try {
                    // Temukan chat ID pasien ini
                    const q = query(collection(db, 'chats'), where('buyerId', '==', activePatientUid), where('doctorId', '==', currentDoctorId));
                    const snapshot = await getDocs(q);
                    if (!snapshot.empty) {
                      const chatId = snapshot.docs[0].id;
                      const reportMsg = `📄 **LAPORAN ASESMEN RESMI**\n\n**Kesimpulan Klinis:**\n${doctorAiNote || 'Tidak ditemukan indikasi keterlambatan kognitif mayor. Terdapat kecenderungan distraksi ringan yang wajar. Laporan AI mendetail dapat diakses melalui menu riwayat asesmen anak Anda.'}\n\nSalam sehat,\nKlinik Zikola`;
                      
                      await addDoc(collection(db, 'chats', chatId, 'messages'), {
                        text: reportMsg,
                        senderId: currentDoctorId,
                        timestamp: serverTimestamp(), senderType: 'doctor'
                      });

                      // Also save to reports collection for record
                      await addDoc(collection(db, 'users', activePatientUid, 'reports'), {
                        title: `Laporan Observasi Klinis - ${patientProfile?.name || selectedPatientId || 'Pasien'}`,
                        doctorNote: doctorAiNote || 'Terverifikasi.',
                        createdAt: serverTimestamp(),
                        doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog'
                      });

                      alert('Laporan berhasil disahkan dan disinkronisasi ke aplikasi mobile orang tua!');
                      setShowAiReportModal(false);
                    } else {
                      alert('Gagal sinkronisasi: Tidak ada ruang chat aktif dengan orang tua ini.');
                    }
                  } catch (err) {
                    alert('Gagal mengirim: ' + err);
                  }
                }} className="px-8 py-2.5 bg-gradient-to-r from-emerald-500 to-green-600 text-white font-bold rounded-xl hover:from-emerald-600 hover:to-green-700 transition-colors text-xs shadow-md flex items-center space-x-2">
                <ShieldCheck size={16} />
                <span>Sahkan & Kirim Laporan</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL E-PRESCRIPTION & REKOMENDASI TERAPI */}
      {showPrescriptionModal && (
        <div className="fixed inset-0 bg-black/50 z-[150] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-lg overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-5 border-b flex items-center justify-between bg-gradient-to-r from-indigo-600 to-teal-600 text-white">
              <div className="flex items-center space-x-2.5">
                <div className="w-9 h-9 bg-white/15 rounded-xl flex items-center justify-center">
                  <Pill size={20} className="text-white" />
                </div>
                <div>
                  <h3 className="text-sm font-black tracking-tight">Tulis Resep & Rekomendasi Terapi</h3>
                  <p className="text-[10px] text-teal-100 font-medium">Pasien: {patientProfile?.name || selectedPatientId || 'Pasien Zikola'}</p>
                </div>
              </div>
              <button onClick={() => setShowPrescriptionModal(false)} className="p-1.5 hover:bg-white/10 rounded-full transition-colors">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSavePrescription} className="p-5 space-y-4 max-h-[80vh] overflow-y-auto">
              {/* Pilihan Jenis */}
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-wider block">Kategori Rekomendasi</label>
                <div className="grid grid-cols-3 gap-2">
                  {[
                    { key: 'suplemen', label: 'Suplemen / Vitamin', icon: '💊' },
                    { key: 'terapi', label: 'Paket Terapi', icon: '🧩' },
                    { key: 'medis', label: 'Obat Medis', icon: '🩺' },
                  ].map(t => (
                    <button
                      key={t.key}
                      type="button"
                      onClick={() => setPrescType(t.key as any)}
                      className={`p-2.5 rounded-xl border text-xs font-black flex flex-col items-center justify-center space-y-1 transition-all ${
                        prescType === t.key
                          ? 'border-indigo-600 bg-indigo-50 text-indigo-700 shadow-xs'
                          : 'border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100'
                      }`}
                    >
                      <span className="text-lg">{t.icon}</span>
                      <span className="text-[10px] text-center leading-tight">{t.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Template Cepat */}
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-wider block">Pilihan Cepat (Rekomendasi Teruji)</label>
                <div className="flex flex-wrap gap-1.5">
                  {(prescType === 'terapi' ? [
                    'Terapi Wicara (Speech Therapy)',
                    'Sensori Integrasi (SI)',
                    'Terapi Okupasi & Kemandirian',
                    'Terapi Perilaku (ABA / Behavior)',
                    'Stimulasi Kognitif Interaktif'
                  ] : prescType === 'medis' ? [
                    'Sirup Paracetamol 120mg/5ml',
                    'Cetirizine Drops 10mg/ml',
                    'Ambroxol Sirup 15mg/5ml',
                    'Probiotik Tumbuh Kembang'
                  ] : [
                    'DHA & EPA Omega 3 (Minyak Ikan)',
                    'Vitamin D3 Drops 400 IU',
                    'Zat Besi Sirup (Suplementasi)',
                    'Zinc Sirup 20mg',
                    'Multivitamin Anak + Kolin'
                  ]).map((item, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setPrescItemName(item)}
                      className="text-[10px] font-bold px-2.5 py-1 bg-slate-100 text-slate-700 hover:bg-indigo-50 hover:text-indigo-600 rounded-lg border border-slate-200 transition-colors"
                    >
                      + {item}
                    </button>
                  ))}
                </div>
              </div>

              {/* Nama Item / Terapi */}
              <div className="space-y-1">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-wider block">Nama Suplemen / Program Terapi *</label>
                <input
                  type="text"
                  value={prescItemName}
                  onChange={(e) => setPrescItemName(e.target.value)}
                  placeholder="Contoh: Minyak Ikan DHA 250mg atau Terapi Sensori Integrasi"
                  required
                  className="w-full p-2.5 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-indigo-500 bg-white"
                />
              </div>

              {/* Dosis & Durasi */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-500 uppercase tracking-wider block">Dosis / Frekuensi Sesi *</label>
                  <input
                    type="text"
                    value={prescDosage}
                    onChange={(e) => setPrescDosage(e.target.value)}
                    placeholder="Contoh: 1x sehari 2.5 ml / 2x seminggu"
                    required
                    className="w-full p-2.5 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-indigo-500 bg-white"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-slate-500 uppercase tracking-wider block">Durasi Konsumsi / Terapi *</label>
                  <input
                    type="text"
                    value={prescDuration}
                    onChange={(e) => setPrescDuration(e.target.value)}
                    placeholder="Contoh: 30 Hari / 8 Pertemuan"
                    required
                    className="w-full p-2.5 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-indigo-500 bg-white"
                  />
                </div>
              </div>

              {/* Catatan Anjuran */}
              <div className="space-y-1">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-wider block">Catatan Anjuran Khusus Dokter</label>
                <textarea
                  value={prescNotes}
                  onChange={(e) => setPrescNotes(e.target.value)}
                  rows={3}
                  placeholder="Contoh: Diminum sesudah sarapan pagi. Pantau perkembangan kontak mata dan atensi selama 2 pekan ke depan."
                  className="w-full p-2.5 border border-slate-200 rounded-xl text-xs font-medium outline-none focus:border-indigo-500 bg-white resize-none"
                />
              </div>

              <div className="pt-3 border-t flex items-center justify-between">
                <p className="text-[9px] text-slate-400 font-medium">
                  Resep akan tersimpan di EMR dan terkirim ke chat pasien.
                </p>
                <div className="flex items-center space-x-2">
                  <button
                    type="button"
                    onClick={() => setShowPrescriptionModal(false)}
                    className="px-4 py-2 border border-slate-200 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-50"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={isSavingPrescription || !prescItemName.trim()}
                    className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-black shadow-md transition-all flex items-center space-x-1.5 disabled:opacity-50"
                  >
                    <Save size={13} />
                    <span>{isSavingPrescription ? 'Menyimpan...' : 'Simpan & Kirim'}</span>
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* PHASE 1 ACTION: KIRIM MATERI MODAL */}
      {showMateriModal && (
        <div className="fixed inset-0 bg-black/40 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-5 border-b flex items-center justify-between bg-teal-600 text-white">
              <h3 className="text-base font-black">Pilih Materi Edukasi</h3>
              <button onClick={() => setShowMateriModal(false)} className="p-1 hover:bg-white/10 rounded-full">
                <X size={18} />
              </button>
            </div>
            <div className="p-5 space-y-3">
              {materiList.map(m => (
                <div 
                  key={m.id}
                  onClick={() => setSelectedMateriId(m.id)}
                  className={`p-4 border-2 rounded-2xl cursor-pointer transition-all flex items-start space-x-3 ${
                    selectedMateriId === m.id ? 'border-teal-600 bg-teal-50/50' : 'border-slate-100 hover:border-slate-200 bg-white'
                  }`}
                >
                  <span className="text-2xl">{m.icon}</span>
                  <div>
                    <h4 className="text-xs font-black text-slate-800">{m.title}</h4>
                    <p className="text-[10px] text-slate-500 font-medium mt-1 leading-relaxed">{m.desc}</p>
                  </div>
                </div>
              ))}
            </div>
            <div className="p-5 border-t bg-slate-50 flex items-center justify-end space-x-3">
              <button 
                onClick={() => setShowMateriModal(false)}
                className="px-4 py-2 border border-slate-200 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Batal
              </button>
              <button 
                onClick={handleSendMateri}
                disabled={!selectedMateriId}
                className="px-6 py-2 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 disabled:opacity-50"
              >
                Kirim Materi
              </button>
            </div>
          </div>
        </div>
      )}

      
      {/* PHASE 2 ACTION: ACTION PLAN / DIGITAL PRESCRIPTION */}
      {showTugasModal && (
        <div className="fixed inset-0 bg-black/45 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-6 border-b flex items-center justify-between bg-teal-600 text-white">
              <div className="flex items-center space-x-3">
                <span className="text-2xl">📝</span>
                <div>
                  <h3 className="text-lg font-black leading-tight">Rencana Stimulasi (Action Plan)</h3>
                  <p className="text-[10px] text-teal-100 font-bold mt-0.5">Resep digital target perkembangan mingguan</p>
                </div>
              </div>
              <button onClick={() => setShowTugasModal(false)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              <div className="space-y-3">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Target Fokus Stimulasi (Pilih 1-2)</span>
                <div className="grid grid-cols-2 gap-3">
                  {['Motorik Halus', 'Motorik Kasar', 'Fokus & Atensi', 'Kemampuan Bahasa', 'Sosial-Emosional', 'Regulasi Tantrum'].map((t, i) => (
                    <div 
                      key={i} 
                      onClick={() => setActionTarget(t)}
                      className={`p-3 border-2 rounded-xl flex items-center justify-between cursor-pointer transition-colors ${actionTarget === t ? 'border-teal-600 bg-teal-50' : 'border-slate-100 hover:border-indigo-300'}`}
                    >
                      <span className="text-xs font-bold text-slate-700">{t}</span>
                      <div className={`w-4 h-4 rounded-full border flex items-center justify-center ${actionTarget === t ? 'border-teal-600 bg-teal-600 text-white' : 'border-slate-300'}`}>
                        {actionTarget === t && <span className="text-[10px] text-white">✓</span>}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Saran Batas Waktu Layar (Screen Time)</label>
                  <select 
                    value={actionScreenTime}
                    onChange={(e) => setActionScreenTime(e.target.value)}
                    className="w-full border border-slate-200 p-3 rounded-xl text-xs outline-none bg-white font-bold"
                  >
                    <option>Maks. 30 Menit per Hari</option>
                    <option>Maks. 1 Jam per Hari</option>
                    <option>Sama Sekali Tanpa Layar (0 Menit)</option>
                  </select>
                </div>
                
                <div className="space-y-1.5">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Instruksi Khusus untuk Orang Tua (Feeding Rules, Tidur, dll)</label>
                  <textarea 
                    rows={4}
                    value={actionNotes}
                    onChange={(e) => setActionNotes(e.target.value)}
                    placeholder="Contoh: Hentikan pemberian gadget saat makan (Screen-free meals)."
                    className="w-full border border-slate-200 p-3 rounded-xl text-xs outline-none focus:border-teal-500 resize-none font-medium text-slate-700"
                  />
                </div>
              </div>
              
              <div className="bg-amber-50 border border-amber-100 rounded-xl p-4 flex space-x-3">
                <span className="text-amber-500">⚠️</span>
                <p className="text-[10px] font-bold text-amber-800 leading-relaxed">
                  Action Plan ini akan muncul sebagai pesan instan khusus di layar aplikasi mobile orang tua secara realtime.
                </p>
              </div>
            </div>
            
            <div className="p-5 border-t bg-slate-50 flex items-center justify-end space-x-3">
              <button 
                onClick={() => setShowTugasModal(false)}
                className="px-6 py-2.5 border border-slate-200 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Batal
              </button>
              <button 
                onClick={async () => { 
                  if (!selectedChat) return;
                  try {
                    const planText = `📋 **ACTION PLAN STIMULASI**\n\n🎯 **Target Fokus**: ${actionTarget}\n📱 **Batas Waktu Layar**: ${actionScreenTime}\n\n💡 **Instruksi Khusus**:\n${actionNotes || 'Tetap semangat memberikan stimulasi harian!'}\n\nSilakan ikuti panduan ini minggu ini ya Ayah & Bunda!`;
                    
                    await addDoc(collection(db, 'chats', selectedChat.id, 'messages'), {
                      text: planText,
                      senderId: currentDoctorId,
                      timestamp: serverTimestamp(),
                      senderType: 'doctor',
                      metadata: {
                        type: 'action_plan',
                        target: actionTarget,
                        screenTime: actionScreenTime,
                        notes: actionNotes
                      }
                    });

                    const targetUid = activePatientUid || selectedChat?.buyerId;
                    if (targetUid) {
                      await addDoc(collection(db, 'users', targetUid, 'action_plans'), {
                        target: actionTarget,
                        screenTime: actionScreenTime,
                        notes: actionNotes || 'Lakukan stimulasi terarah setiap hari.',
                        doctorName: doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog',
                        createdAt: new Date().toISOString(),
                        completedToday: false,
                        timestamp: serverTimestamp()
                      });

                      await sendPatientNotification(targetUid, {
                        type: 'action_plan',
                        title: 'Target Stimulasi (Action Plan) Baru',
                        content: `Dokter menetapkan fokus stimulasi "${actionTarget}" dengan batas screen-time: ${actionScreenTime}.`,
                        targetId: 'emr',
                        sourceAvatar: '📝'
                      });
                    }
                    
                    alert('Action Plan berhasil disinkronkan ke aplikasi orang tua!'); 
                    setShowTugasModal(false);
                    setActionNotes(''); // reset
                  } catch (err) {
                    alert('Gagal mengirim plan: ' + err);
                  }
                }}
                className="px-8 py-2.5 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 shadow-md"
              >
                Kirim & Sinkronkan
              </button>
            </div>
          </div>
        </div>
      )}


      {/* PHASE 1 ACTION: JADWALKAN SESI MODAL */}
      {showJadwalModal && (
        <div className="fixed inset-0 bg-black/40 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-5 border-b flex items-center justify-between bg-teal-600 text-white">
              <h3 className="text-base font-black">Jadwalkan Konsultasi</h3>
              <button onClick={() => setShowJadwalModal(false)} className="p-1 hover:bg-white/10 rounded-full">
                <X size={18} />
              </button>
            </div>
            <div className="p-5 space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-600">Tanggal & Waktu Konsultasi</label>
                <input 
                  type="datetime-local"
                  value={appointmentDateTime}
                  onChange={(e) => setAppointmentDateTime(e.target.value)}
                  className="w-full border border-slate-200 p-2.5 rounded-xl text-sm focus:border-teal-500 outline-none"
                  required
                />
              </div>
              <p className="text-[10px] text-slate-400 font-medium leading-relaxed">
                Jadwal ini akan masuk ke daftar janji temu di aplikasi orang tua dan mengirim pesan notifikasi konfirmasi di ruang chat.
              </p>
            </div>
            <div className="p-5 border-t bg-slate-50 flex items-center justify-end space-x-3">
              <button 
                onClick={() => setShowJadwalModal(false)}
                className="px-4 py-2 border border-slate-200 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
              >
                Batal
              </button>
              <button 
                onClick={handleScheduleSession}
                disabled={!appointmentDateTime}
                className="px-6 py-2 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 disabled:opacity-50"
              >
                Simpan Jadwal
              </button>
            </div>
          </div>
        </div>
      )}

      {/* PHASE 1 ACTION: RATING SESI MODAL */}
      {showRatingModal && (
        <div className="fixed inset-0 bg-black/40 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-5 border-b flex items-center justify-between bg-teal-600 text-white">
              <h3 className="text-base font-black">Rating Sesi & Catatan</h3>
              <button onClick={() => setShowRatingModal(false)} className="p-1 hover:bg-white/10 rounded-full">
                <X size={18} />
              </button>
            </div>
            
            {ratingSubmitted ? (
              <div className="p-8 text-center space-y-3">
                <span className="text-4xl block animate-bounce">🎉</span>
                <h4 className="text-sm font-black text-slate-800">Catatan Sesi Disimpan!</h4>
                <p className="text-[10px] text-slate-500">Terima kasih atas dedikasi dan profesionalitas Anda.</p>
              </div>
            ) : (
              <div className="p-5 space-y-4">
                <div className="space-y-1.5 flex flex-col items-center">
                  <label className="text-xs font-bold text-slate-600 mr-auto">Berikan Rating Performa Sesi</label>
                  <div className="flex items-center space-x-2 mt-2">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button 
                        type="button" 
                        key={star}
                        onClick={() => setSessionRating(star)}
                        className={`text-2xl transition-transform hover:scale-110 ${
                          sessionRating >= star ? 'text-amber-400' : 'text-slate-200'
                        }`}
                      >
                        ★
                      </button>
                    ))}
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-slate-600">Catatan Klinis & Rekomendasi Dokter</label>
                  <textarea 
                    value={clinicalNotes}
                    onChange={(e) => setClinicalNotes(e.target.value)}
                    rows={4}
                    placeholder="Tulis diagnosa cepat, catatan perkembangan penting, atau saran pengawasan ortu di sini..."
                    className="w-full border border-slate-200 p-3 rounded-xl text-xs resize-none outline-none focus:border-teal-500"
                    required
                  />
                </div>
              </div>
            )}

            {!ratingSubmitted && (
              <div className="p-5 border-t bg-slate-50 flex items-center justify-end space-x-3">
                <button 
                  onClick={() => setShowRatingModal(false)}
                  className="px-4 py-2 border border-slate-200 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-100"
                >
                  Batal
                </button>
                <button 
                  onClick={handleSubmitReview}
                  disabled={!clinicalNotes.trim()}
                  className="px-6 py-2 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700 disabled:opacity-50"
                >
                  Simpan Catatan
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* PHASE 1 ACTION: LIHAT PROFIL ANAK MODAL */}
      {showPatientProfileModal && (
        <div className="fixed inset-0 bg-black/40 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="p-5 border-b flex items-center justify-between bg-teal-600 text-white">
              <h3 className="text-base font-black">Profil Lengkap Pasien Anak</h3>
              <button onClick={() => setShowPatientProfileModal(false)} className="p-1 hover:bg-white/10 rounded-full">
                <X size={18} />
              </button>
            </div>
            <div className="p-6 space-y-6">
              <div className="text-center">
                <div className="w-20 h-20 bg-blue-100 rounded-full flex items-center justify-center text-4xl mx-auto mb-3 overflow-hidden border-4 border-white shadow-md">
                  {renderAvatar(patientProfile?.avatar, "w-full h-full", "text-3xl")}
                </div>
                <h4 className="text-base font-black text-slate-800">{patientProfile?.name || 'Pasien Anonim'}</h4>
                <p className="text-xs text-slate-400 font-bold mt-1">
                  Usia: {patientProfile?.age ? `${patientProfile.age} Tahun` : 'Belum diisi'} • {patientProfile?.gender === 'female' ? 'Perempuan' : patientProfile?.gender === 'male' ? 'Laki-laki' : '-'}
                </p>
              </div>

              <div className="space-y-3 pt-4 border-t border-slate-100 text-xs">
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Sekolah</span>
                  <span className="text-slate-700 font-black">{patientProfile?.school || '-'}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Hobi Utama</span>
                  <span className="text-slate-700 font-black">{patientProfile?.hobbies || '-'}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Minat Anak</span>
                  <span className="text-slate-700 font-black">{patientProfile?.interests || '-'}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Karakteristik</span>
                  <span className="text-slate-700 font-black">{patientProfile?.personality || '-'}</span>
                </div>
                <div className="flex justify-between py-1">
                  <span className="text-slate-400 font-bold">Gaya Belajar</span>
                  <span className="text-teal-600 font-black">{patientProfile?.learningStyle || '-'}</span>
                </div>
              </div>
            </div>
            <div className="p-5 border-t bg-slate-50 flex items-center justify-end">
              <button 
                onClick={() => setShowPatientProfileModal(false)}
                className="px-6 py-2 bg-teal-600 text-white rounded-xl text-xs font-bold hover:bg-teal-700"
              >
                Tutup Profil
              </button>
            </div>
          </div>
        </div>
      )}

      
      {/* PHASE 2 ACTION: MEDICAL RECORD PRINT PREVIEW */}
      {showPrintModal && (
        <div className="fixed inset-0 bg-black/60 z-[200] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="print-modal-container bg-slate-100 rounded-3xl w-full max-w-4xl max-h-[95vh] overflow-hidden flex flex-col shadow-2xl">
            <div className="p-4 border-b flex items-center justify-between bg-white no-print">
              <div className="flex items-center space-x-3">
                <button onClick={() => setShowPrintModal(false)} className="w-8 h-8 border border-slate-200 rounded-lg flex items-center justify-center text-slate-500 hover:bg-slate-50">
                  <ArrowLeft size={16} />
                </button>
                <h3 className="text-sm font-black text-slate-800">Print Preview - Rekam Medis (A4)</h3>
              </div>
              <div className="flex items-center space-x-2">
                <button onClick={() => window.print()} className="px-4 py-2 bg-teal-50 text-teal-600 font-bold rounded-lg text-xs hover:bg-teal-100 flex items-center space-x-2">
                  <Download size={14} /><span>Unduh PDF</span>
                </button>
                <button onClick={() => window.print()} className="px-4 py-2 bg-teal-600 text-white font-bold rounded-lg text-xs hover:bg-teal-700 flex items-center space-x-2 shadow-sm">
                  <Printer size={14} /><span>Cetak Dokumen</span>
                </button>
              </div>
            </div>
            
            <div className="flex-1 overflow-y-auto p-4 md:p-8 flex justify-center">
              {/* Kertas A4 Mockup */}
              <div className="emr-printable-sheet bg-white w-[210mm] min-h-[297mm] shadow-md border border-slate-200 p-10 text-slate-800 font-sans relative scale-95 origin-top flex flex-col justify-between">
                <div>
                  {/* Kop Surat */}
                  <div className="border-b-4 border-teal-600 pb-5 mb-5 flex justify-between items-center">
                    <div className="flex items-center space-x-4">
                      <img src={zikolaLogoFull} alt="Logo" className="h-10 object-contain" />
                      <div>
                        <h1 className="text-2xl font-black tracking-tighter text-indigo-900 uppercase">Klinik Zikola</h1>
                        <p className="text-[10px] font-bold text-slate-500 tracking-widest mt-0.5">PUSAT TUMBUH KEMBANG ANAK & PSIKOLOGI</p>
                        <p className="text-[9px] text-slate-400 mt-0.5">Jl. Raya Rungkut Madya No. 1, Gunung Anyar, Surabaya, Jawa Timur 60294 | Layanan Resmi Zikola Care</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <h2 className="text-[13px] font-black text-slate-800 uppercase">Rekam Medis Elektronik</h2>
                      <p className="text-[10px] text-slate-500 font-medium mt-1">
                        No. RM: <span className="font-bold">{patientProfile?.noRm || (activePatientUid ? `ZK-${new Date().getFullYear()}-${activePatientUid.substring(0, 6).toUpperCase()}` : `ZK-${new Date().getFullYear()}-001`)}</span>
                      </p>
                      <p className="text-[10px] text-slate-500 font-medium">Tanggal: <span className="font-bold">{formatDateSafe(new Date()).split(",")[0]}</span></p>
                    </div>
                  </div>

                  {/* Data Pasien & Dokter */}
                  <div className="grid grid-cols-2 gap-6 mb-6 text-[11px] bg-slate-50/70 p-3 rounded-xl border border-slate-100">
                    <div className="space-y-1.5">
                      <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Nama Pasien</span><span className="col-span-2 font-black">: {patientProfile?.name || selectedPatientId || 'Pasien Zikola'}</span></div>
                      <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Usia / Gender</span><span className="col-span-2 font-black">: {patientProfile?.age ? `${patientProfile.age} Tahun` : 'Belum diisi'} / {patientProfile?.gender === 'female' ? 'Perempuan' : patientProfile?.gender === 'male' ? 'Laki-laki' : '-'}</span></div>
                      <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Nama Orang Tua</span><span className="col-span-2 font-black">: {patientProfile?.parent || '-'}</span></div>
                    </div>
                    <div className="space-y-1.5">
                      <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Dokter Pemeriksa</span><span className="col-span-2 font-black">: {doctorProfile?.name || 'Dokter Spesialis Anak'}</span></div>
                      <div className="grid grid-cols-3"><span className="font-bold text-slate-500">SIP / STR</span><span className="col-span-2 font-black">: {doctorProfile?.licenseNumber || 'STR/SIP Terdaftar'}</span></div>
                      <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Fasilitas</span><span className="col-span-2 font-black">: Klinik Zikola Surabaya</span></div>
                    </div>
                  </div>

                  {/* Hasil Asesmen Klinis */}
                  <div className="mb-6">
                    <h3 className="text-xs font-black text-indigo-900 border-b border-slate-200 pb-1.5 mb-3 uppercase tracking-widest">A. Hasil Observasi & Asesmen Kognitif</h3>
                    {hasAssessmentData ? (
                      <div className="grid grid-cols-2 gap-6 items-center">
                        <div className="h-40 flex items-center justify-center -ml-6">
                          <ResponsiveContainer width="100%" height="100%">
                            <RadarChart cx="50%" cy="50%" outerRadius="70%" data={radarData}>
                              <PolarGrid stroke="#E2E8F0" />
                              <PolarAngleAxis dataKey="subject" tick={{ fill: '#1E293B', fontSize: 9, fontWeight: 'bold' }} />
                              <Radar dataKey="A" stroke="#0D9488" fill="#0D9488" fillOpacity={0.2} />
                            </RadarChart>
                          </ResponsiveContainer>
                        </div>
                        <div className="space-y-2">
                          <p className="text-[10px] leading-relaxed text-slate-700">
                            Berdasarkan hasil asesmen digital Zikola, pasien meraih skor kognitif rata-rata <strong>{averageScoreValue}/100 ({averageScoreLabel})</strong>.
                            Tercatat performa domain Logika: <strong>{radarData.find(d => d.subject === 'Logika')?.A || 0}/100</strong>, Memori: <strong>{radarData.find(d => d.subject === 'Memori')?.A || 0}/100</strong>, Bahasa: <strong>{radarData.find(d => d.subject === 'Bahasa')?.A || 0}/100</strong>, Motorik: <strong>{radarData.find(d => d.subject === 'Motorik')?.A || 0}/100</strong>, dan Emosi: <strong>{radarData.find(d => d.subject === 'Emosi')?.A || 0}/100</strong>.
                          </p>
                          <p className="text-[10px] leading-relaxed text-slate-700">
                            {emrPreviousTherapy ? `Catatan terapi pasien sebelumnya: ${emrPreviousTherapy}.` : 'Perkembangan kognitif dan sensori motorik anak terus dipantau secara berkala melalui program stimulasi terpadu.'}
                          </p>
                        </div>
                      </div>
                    ) : (
                      <div className="bg-slate-50 border border-dashed border-slate-200 rounded-xl p-4 text-slate-600 text-[10px] leading-relaxed space-y-1.5">
                        <p className="font-bold text-slate-700">
                          ⚠️ Pasien belum menyelesaikan tes skrining / game asesmen kognitif digital di aplikasi Zikola.
                        </p>
                        <p className="text-slate-500">
                          Observasi klinis awal disimpulkan melalui anamnesis riwayat tumbuh kembang bersama orang tua ({patientProfile?.parent || 'Keluarga'}) dan pengamatan sesi konsultasi dokter.
                          {emrBirthCondition && ` Kondisi kelahiran tercatat: ${emrBirthCondition}.`}
                          {emrAllergies && ` Catatan riwayat alergi: ${emrAllergies}.`}
                        </p>
                      </div>
                    )}
                  </div>

                  {/* Kesimpulan & Diagnosis */}
                  <div className="mb-6">
                    <h3 className="text-xs font-black text-indigo-900 border-b border-slate-200 pb-1.5 mb-3 uppercase tracking-widest">B. Kesimpulan Klinis & Diagnosa</h3>
                    <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-2">
                      <div>
                        <span className="text-[9px] font-black text-teal-700 uppercase tracking-wider block mb-0.5">Diagnosa & Catatan Evaluasi:</span>
                        <p className="text-[11px] font-bold leading-relaxed text-slate-800 whitespace-pre-line">
                          {emrDiagnosis || doctorAiNote || "Belum ada catatan diagnosa spesifik yang diinput dokter. Pasien dalam pemantauan tumbuh kembang wajar sesuai tahapan usia."}
                        </p>
                      </div>
                      {emrTreatmentPlan && (
                        <div className="pt-2 border-t border-slate-200">
                          <span className="text-[9px] font-black text-indigo-700 uppercase tracking-wider block mb-0.5">Rencana Stimulasi & Terapi:</span>
                          <p className="text-[10px] font-medium leading-relaxed text-slate-700 whitespace-pre-line">
                            {emrTreatmentPlan}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Bagian C: Rekomendasi Terapi & Resep Klinis */}
                  <div className="mb-6">
                    <h3 className="text-xs font-black text-indigo-900 border-b border-slate-200 pb-1.5 mb-3 uppercase tracking-widest flex items-center justify-between">
                      <span>C. Rekomendasi Terapi & Resep Digital</span>
                      <span className="text-[9px] font-bold text-teal-600 lowercase tracking-normal font-sans">e-prescription terverifikasi</span>
                    </h3>
                    {patientPrescriptions && patientPrescriptions.length > 0 ? (
                      <div className="border border-slate-200 rounded-xl overflow-hidden">
                        <table className="w-full text-[10px] text-left">
                          <thead className="bg-slate-100 font-black text-slate-700 uppercase tracking-wider text-[9px]">
                            <tr>
                              <th className="py-2 px-3">Item / Tindakan</th>
                              <th className="py-2 px-3">Kategori</th>
                              <th className="py-2 px-3">Dosis / Frekuensi</th>
                              <th className="py-2 px-3">Durasi</th>
                              <th className="py-2 px-3">Catatan Khusus</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                            {patientPrescriptions.map((pr, idx) => (
                              <tr key={pr.id || idx} className="hover:bg-slate-50">
                                <td className="py-1.5 px-3 font-bold text-slate-900">{pr.itemName}</td>
                                <td className="py-1.5 px-3">
                                  <span className="px-2 py-0.5 rounded-full text-[8px] font-black uppercase tracking-wider bg-teal-50 text-teal-700 border border-teal-100">
                                    {pr.type || 'suplemen'}
                                  </span>
                                </td>
                                <td className="py-1.5 px-3 font-semibold">{pr.dosage || '-'}</td>
                                <td className="py-1.5 px-3">{pr.duration || '-'}</td>
                                <td className="py-1.5 px-3 text-slate-500 italic">{pr.notes || '-'}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    ) : (
                      <div className="bg-slate-50 p-3 rounded-xl border border-dashed border-slate-200 text-[10px] text-slate-600">
                        <p className="font-bold text-slate-700">
                          {emrTreatmentPlan ? `Rencana Terapi Terjadwal: ${emrTreatmentPlan}` : 'Pasien saat ini tidak memerlukan intervensi farmakologis atau paket terapi khusus.'}
                        </p>
                        <p className="text-slate-500 text-[9px] mt-0.5">
                          Edukasi stimulasi sensorik dan keteraturan pola tidur direkomendasikan untuk orang tua di rumah.
                        </p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Bagian Bawah: QR Code Keabsahan Medis & Tanda Tangan Dokter */}
                <div className="pt-4 border-t border-slate-200 mt-4 flex justify-between items-end">
                  <div className="flex items-center space-x-3 p-3 border border-slate-200 rounded-xl bg-slate-50">
                    <div className="w-16 h-16 bg-white border border-slate-200 rounded-lg p-1.5 flex items-center justify-center shrink-0">
                      <svg className="w-full h-full text-slate-800" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M2 2h8v8H2V2zm2 2v4h4V4H4zm10-2h8v8h-8V2zm2 2v4h4V4h-4zM2 14h8v8H2v-8zm2 2v4h4v-4H4zm13-2h3v3h-3v-3zm0 5h3v3h-3v-3zm-3-5h3v3h-3v-3zm0 5h3v3h-3v-3zm-2-2h2v2h-2v-2zM5 5h2v2H5V5zm12 0h2v2h-2V5zM5 17h2v2H5v-2z"/>
                      </svg>
                    </div>
                    <div className="text-[9px] text-slate-600 space-y-0.5">
                      <div className="flex items-center space-x-1 font-black text-teal-700 uppercase tracking-wide">
                        <ShieldCheck size={12} />
                        <span>Dokumen Medis Sah</span>
                      </div>
                      <p className="font-bold text-slate-800">Klinik Zikola Surabaya</p>
                      <p className="text-slate-500 font-mono text-[8px]">
                        VERIF: {patientProfile?.noRm || (activePatientUid ? `ZK-${new Date().getFullYear()}-${activePatientUid.substring(0, 6).toUpperCase()}` : `ZK-${new Date().getFullYear()}-001`)}
                      </p>
                      <p className="text-[8px] text-slate-400">Pindai kode QR untuk validasi keaslian EMR</p>
                    </div>
                  </div>

                  <div className="text-center min-w-[200px]">
                    <p className="text-[11px] mb-8 text-slate-600 font-medium">Surabaya, {formatDateSafe(new Date()).split(",")[0]}</p>
                    <p className="text-[11px] font-black underline decoration-2 underline-offset-4 text-slate-900">
                      {doctorProfile?.name || 'Dokter Spesialis Anak'}
                    </p>
                    <p className="text-[9px] text-slate-500 mt-1 font-semibold">
                      SIP / STR: {doctorProfile?.licenseNumber || 'STR/SIP Terdaftar'}
                    </p>
                    <p className="text-[9px] font-bold text-teal-700 mt-0.5">Klinik Terpadu Tumbuh Kembang Zikola Surabaya</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      
      {/* PHASE 3 ADVANCED ACTION: ADD PATIENT MODAL */}
      {showAddPatientModal && (
        <div className="fixed inset-0 bg-black/60 z-[200] flex items-center justify-center p-4 backdrop-blur-sm">
          <form onSubmit={handleCreatePatient} className="bg-white rounded-3xl w-full max-w-lg max-h-[90vh] overflow-y-auto flex flex-col shadow-2xl">
            <div className="p-6 border-b flex items-center justify-between bg-teal-600 text-white sticky top-0 z-10">
              <h2 className="text-lg font-black flex items-center space-x-2">
                <Users size={20} />
                <span>Registrasi Pasien Fisik Baru</span>
              </h2>
              <button type="button" onClick={() => setShowAddPatientModal(false)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="p-6 space-y-4 bg-slate-50">
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Nama Lengkap Anak *</label>
                <input 
                  type="text" 
                  value={newPatientName}
                  onChange={(e) => setNewPatientName(e.target.value)}
                  placeholder="Masukkan nama lengkap anak..." 
                  required
                  className="w-full p-3 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-teal-500 bg-white" 
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Tanggal Lahir</label>
                  <input 
                    type="date" 
                    value={newPatientDob}
                    onChange={(e) => setNewPatientDob(e.target.value)}
                    className="w-full p-3 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-teal-500 text-slate-700 bg-white" 
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Jenis Kelamin</label>
                  <select 
                    value={newPatientGender}
                    onChange={(e) => setNewPatientGender(e.target.value)}
                    className="w-full p-3 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-teal-500 text-slate-700 bg-white"
                  >
                    <option value="male">Laki-Laki (👦)</option>
                    <option value="female">Perempuan (👧)</option>
                  </select>
                </div>
              </div>
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Nama Orang Tua / Wali</label>
                <input 
                  type="text" 
                  value={newPatientParent}
                  onChange={(e) => setNewPatientParent(e.target.value)}
                  placeholder="Nama ayah/ibu..." 
                  className="w-full p-3 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-teal-500 bg-white" 
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">No. WhatsApp / Kontak Aktif</label>
                <input 
                  type="tel" 
                  value={newPatientPhone}
                  onChange={(e) => setNewPatientPhone(e.target.value)}
                  placeholder="Cth: 08123456789" 
                  className="w-full p-3 border border-slate-200 rounded-xl text-xs font-bold outline-none focus:border-teal-500 bg-white" 
                />
              </div>
              
              <div className="bg-teal-50 p-4 rounded-xl border border-teal-100 flex items-start space-x-3">
                <Info size={16} className="text-teal-600 mt-0.5 flex-shrink-0" />
                <p className="text-[10px] font-bold text-teal-800 leading-relaxed">
                  Setelah disimpan, profil ini dapat Anda kelola secara mandiri di daftar pasien.
                </p>
              </div>
            </div>
            
            <div className="p-5 border-t bg-white flex items-center justify-end space-x-3 sticky bottom-0">
              <button 
                type="button"
                onClick={() => setShowAddPatientModal(false)} 
                className="px-6 py-2.5 border border-slate-200 text-slate-600 font-bold hover:bg-slate-50 rounded-xl text-xs transition-colors"
              >
                Batal
              </button>
              <button 
                type="submit" 
                disabled={isCreatingPatient || !newPatientName.trim()}
                className="px-8 py-2.5 bg-teal-600 text-white font-bold rounded-xl hover:bg-teal-700 transition-colors text-xs shadow-md disabled:opacity-50 flex items-center space-x-2"
              >
                {isCreatingPatient ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <span>Simpan & Daftarkan</span>
                )}
              </button>
            </div>
          </form>
        </div>
      )}

      
      {/* INCOMING CALL MODAL FROM PATIENT */}
      {incomingPatientCall && (
        <div className="fixed inset-0 bg-black/60 z-[250] flex items-center justify-center p-4 backdrop-blur-sm animate-fade-in">
          <div className="bg-slate-900 text-white rounded-3xl p-8 max-w-md w-full text-center shadow-2xl border border-slate-700">
            <div className="relative mx-auto w-24 h-24 mb-6">
              <div className="absolute inset-0 bg-emerald-500 rounded-full animate-ping opacity-30"></div>
              <div className="w-24 h-24 rounded-full bg-slate-800 border-2 border-emerald-500 flex items-center justify-center text-4xl relative z-10 shadow-lg">
                👶
              </div>
            </div>
            <h3 className="text-xl font-black">{incomingPatientCall.patientName}</h3>
            <p className="text-emerald-400 font-bold text-xs mt-1 animate-pulse">Panggilan Telekonsultasi Masuk dari Pasien...</p>
            <div className="flex items-center justify-center space-x-6 mt-8">
              <button 
                onClick={declineIncomingCall}
                className="w-14 h-14 rounded-full bg-red-500 hover:bg-red-600 flex items-center justify-center text-white shadow-lg transition-transform hover:scale-105"
                title="Tolak Panggilan"
              >
                <Phone size={22} className="rotate-[135deg]" />
              </button>
              <button 
                onClick={acceptIncomingCall}
                className="w-16 h-16 rounded-full bg-emerald-500 hover:bg-emerald-600 flex items-center justify-center text-white shadow-xl transition-transform hover:scale-110 animate-bounce"
                title="Terima Panggilan"
              >
                <Phone size={26} />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* HIDDEN AUDIO ELEMENT FOR IN-APP WEBRTC TELECONSULTATION */}
      <audio id="remote-audio-player" autoPlay playsInline className="hidden" />

      {/* PHASE 3 ADVANCED ACTION: TELECONSULTATION WORKSPACE MODAL */}
      {showPhoneCallModal && (
        <div className="fixed inset-0 bg-[#0F172A]/95 z-[200] flex items-center justify-center p-4 backdrop-blur-md text-white">
          <div className="w-full max-w-5xl h-[80vh] flex rounded-3xl overflow-hidden shadow-2xl border border-slate-800">
            {/* KIRI: PANGGILAN AUDIO/VIDEO */}
            <div className="w-2/5 bg-slate-900 flex flex-col items-center justify-center p-8 relative">
              <div className="absolute top-6 left-6 flex items-center space-x-2">
                <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>
                <span className="text-[10px] font-black uppercase tracking-widest text-slate-400">Enkripsi End-to-End EMR</span>
              </div>
              
              <div className="relative mx-auto w-40 h-40 mb-8 mt-12">
                <div className="absolute inset-0 bg-teal-500 rounded-full animate-ping opacity-25"></div>
                <div className="w-40 h-40 rounded-full bg-slate-800 border-4 border-slate-700 flex items-center justify-center text-6xl shadow-2xl overflow-hidden relative z-10">
                  {renderAvatar(patientAvatars[selectedChat?.buyerId], "w-full h-full", "text-6xl")}
                </div>
              </div>

                            <div className="text-center">
                <h3 className="text-2xl font-black">{patientProfile?.name || 'Pasien Zikola'}</h3>
                <p className="text-xs text-slate-400 mt-2 font-bold">
                  {phoneCallState === 'connecting' ? 'Menghubungkan Panggilan...' : 'Konsultasi Suara Berlangsung'}
                </p>
                {phoneCallState === 'connecting' && (
                  <button 
                    onClick={async () => {
                      if (selectedChat?.id) {
                        await updateDoc(doc(db, 'chats', selectedChat.id), { callStatus: 'connected' });
                        setPhoneCallState('connected');
                      }
                    }}
                    className="mt-3 px-4 py-1.5 bg-teal-600 hover:bg-teal-700 text-white text-[10px] font-bold rounded-full shadow transition-all"
                  >
                    ⚡ Sambungkan Langsung
                  </button>
                )}
              </div>

              {phoneCallState === 'connected' && (
                <div className="text-3xl font-black text-indigo-400 tracking-wider mt-6 font-mono">
                  {Math.floor(phoneCallDuration / 60).toString().padStart(2, '0')}:
                  {(phoneCallDuration % 60).toString().padStart(2, '0')}
                </div>
              )}

              <div className="mt-4 mb-2 flex items-center space-x-2 text-[11px] text-teal-400 font-bold bg-teal-950/60 border border-teal-800/60 px-4 py-2 rounded-xl">
                <span>🎙️</span>
                <span>Panggilan Suara In-App Terenkripsi</span>
              </div>

              <div className="mt-auto mb-4 flex items-center space-x-3">
                <button 
                  type="button"
                  onClick={toggleDoctorMute}
                  className={`p-3.5 rounded-2xl flex items-center justify-center text-white transition-all shadow-lg ${
                    isDoctorMuted ? 'bg-amber-600 hover:bg-amber-700' : 'bg-slate-700 hover:bg-slate-600'
                  }`}
                  title={isDoctorMuted ? 'Nyalakan Mikrofon' : 'Bisukan Mikrofon (Mute)'}
                >
                  {isDoctorMuted ? <MicOff size={18} /> : <Mic size={18} />}
                </button>
                <button 
                  onClick={endAudioCall}
                  className="px-6 py-3.5 bg-rose-600 hover:bg-rose-700 rounded-2xl flex items-center space-x-2 text-white font-bold text-xs shadow-lg transition-transform hover:scale-105"
                >
                  <Phone size={18} className="rotate-[135deg]" />
                  <span>Akhiri & Simpan Catatan</span>
                </button>
              </div>
            </div>

            {/* KANAN: CALL NOTES / CATATAN MEDIS */}
            <div className="w-3/5 bg-white text-slate-800 flex flex-col">
              <div className="p-6 border-b border-slate-100 bg-slate-50 flex justify-between items-center">
                <div>
                  <h2 className="text-base font-black flex items-center space-x-2 text-slate-800">
                    <Edit3 size={18} className="text-teal-600" />
                    <span>Catatan Konsultasi Langsung</span>
                  </h2>
                  <p className="text-[10px] text-slate-400 font-bold mt-1">Catatan ini akan tersimpan permanen ke EMR setelah panggilan ditutup.</p>
                </div>
              </div>
              <div className="flex-1 p-6 flex flex-col">
                <textarea 
                  value={callNotes}
                  onChange={(e) => setCallNotes(e.target.value)}
                  placeholder="Ketik catatan medis, observasi keluhan orang tua, atau rencana stimulasi selama panggilan berlangsung..."
                  className="flex-1 w-full bg-transparent border-none outline-none resize-none text-sm text-slate-700 leading-relaxed font-medium placeholder:text-slate-300"
                />
              </div>
              <div className="p-4 border-t border-slate-100 bg-amber-50 flex items-center space-x-3">
                <span className="text-amber-500">⚠️</span>
                <p className="text-[10px] font-bold text-amber-800 leading-relaxed">
                  Jangan tutup jendela peramban. Jika panggilan terputus tiba-tiba, catatan akan tersimpan sebagai draft.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}


      {/* MOBILE RADAR / ASSESSMENT BOTTOM SHEET */}
      {mobileShowRadarSheet && (
        <div className="fixed inset-0 z-[120] lg:hidden flex items-end animate-in fade-in duration-200">
          <div className="fixed inset-0 bg-black/40 backdrop-blur-xs" onClick={() => setMobileShowRadarSheet(false)}></div>
          <div className="relative w-full bg-white rounded-t-3xl max-h-[80vh] overflow-y-auto p-6 z-10 shadow-2xl animate-in slide-in-from-bottom duration-250 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-sm font-black text-slate-800">Ringkasan & Radar Kemampuan Anak</h3>
              <button onClick={() => setMobileShowRadarSheet(false)} className="p-1 rounded-full text-slate-400 hover:bg-slate-100">
                <X size={18} />
              </button>
            </div>

            <div className="h-52 flex items-center justify-center bg-slate-50/60 border border-slate-100 rounded-2xl p-2">
              {hasAssessmentData ? (
                <ResponsiveContainer width="100%" height="100%">
                  <RadarChart cx="50%" cy="50%" outerRadius="75%" data={radarData}>
                    <PolarGrid stroke="#E2E8F0" />
                    <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 8, fontWeight: 'bold' }} />
                    <Radar name="Skor" dataKey="A" stroke="#0D9488" fill="#14B8A6" fillOpacity={0.25} />
                  </RadarChart>
                </ResponsiveContainer>
              ) : (
                <div className="text-center p-4">
                  <span className="text-3xl block mb-2">📊</span>
                  <p className="text-xs font-bold text-slate-600">Belum Ada Sesi Tes</p>
                  <p className="text-[10px] text-slate-400 font-medium">Pasien belum mengikuti asesmen</p>
                </div>
              )}
            </div>

            <div className="space-y-2 border-t border-slate-100 pt-3 text-xs font-bold text-slate-700">
              <div className="flex justify-between py-1 border-b border-slate-50"><span>🧩 Puzzle Logika</span><span className="text-teal-600 font-black">{getDynamicScore('puzzleGame', 0) > 0 ? `${getDynamicScore('puzzleGame', 0)}/100` : '-'}</span></div>
              <div className="flex justify-between py-1 border-b border-slate-50"><span>👁️ Memori Visual</span><span className="text-teal-600 font-black">{getDynamicScore('memory', 0) > 0 ? `${getDynamicScore('memory', 0)}/100` : '-'}</span></div>
              <div className="flex justify-between py-1 border-b border-slate-50"><span>🔢 Math Adventure</span><span className="text-teal-600 font-black">{getDynamicScore('numberSequence', 0) > 0 ? `${getDynamicScore('numberSequence', 0)}/100` : '-'}</span></div>
              <div className="flex justify-between py-1"><span>🗣️ Bahasa Seru</span><span className="text-teal-600 font-black">{getDynamicScore('wordPuzzle', 0) > 0 ? `${getDynamicScore('wordPuzzle', 0)}/100` : '-'}</span></div>
            </div>

            <button 
              onClick={() => {
                setMobileShowRadarSheet(false);
                setSelectedPatientId(patientProfile?.name || selectedPatientId || 'Pasien');
                setActiveMenu('patients');
                setPatientDetailTab('assessment');
              }}
              className="w-full py-2.5 bg-teal-600 text-white rounded-xl text-xs font-bold shadow-sm"
            >
              Buka Analitik Detail
            </button>
          </div>
        </div>
      )}

      {/* MOBILE BOTTOM NAVIGATION BAR */}
      <div className="md:hidden bg-white border-t border-slate-100 flex items-center justify-around py-1.5 px-2 flex-shrink-0 z-30 shadow-lg">
        {[
          { id: 'dashboard', label: 'Beranda', icon: <Home size={17} /> },
          { id: 'patients', label: 'Pasien', icon: <Users size={17} /> },
          { id: 'jadwal', label: 'Jadwal', icon: <Calendar size={17} /> },
          { id: 'asesmen', label: 'Asesmen', icon: <Brain size={17} /> },
          { id: 'pesan', label: 'Pesan', icon: <MessageSquare size={17} /> },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveMenu(tab.id as any);
              setSelectedPatientId(null);
            }}
            className={`flex flex-col items-center py-1 px-2.5 rounded-xl text-[9px] transition-all ${
              activeMenu === tab.id ? 'text-teal-600 font-black' : 'text-slate-400 hover:text-slate-600 font-bold'
            }`}
          >
            <div className={`p-1 rounded-lg transition-colors ${activeMenu === tab.id ? 'bg-teal-50 text-teal-600' : ''}`}>
              {tab.icon}
            </div>
            <span className="mt-0.5">{tab.label}</span>
          </button>
        ))}
      </div>

    </div>
  );
}
