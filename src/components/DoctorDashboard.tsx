import { doctorWebRTC } from '../lib/webrtc';
import React, { useState, useEffect, useRef } from 'react';
import { db } from '../lib/firebase';
import {
  collection, query, where, orderBy, onSnapshot, addDoc, setDoc,
  doc, getDoc, deleteDoc, updateDoc, serverTimestamp
} from 'firebase/firestore';
import { format } from 'date-fns';
import {
  Menu, User, Home, Brain, MessageSquare, BarChart2, Users, Bell, Settings,
  HelpCircle, Phone, MoreVertical, ArrowLeft, Paperclip, Send,
  FileText, Clipboard, Calendar, Star, Info, ShieldCheck, Sparkles, X, Save, Trash2, Edit3, Download, Printer, LogOut, Mic, MicOff
} from 'lucide-react';
import {
  Radar, RadarChart, PolarGrid, PolarAngleAxis, ResponsiveContainer,
  AreaChart, Area, XAxis, YAxis, Tooltip, LineChart, Line
} from 'recharts';
import zikolaLogoFull from '../assets/zikola_logo_full.jpg';
import zikolaMascot from '../assets/zikola_mascot.png';

export default function DoctorDashboard({ currentDoctorId, onLogout }: { currentDoctorId: string; onLogout?: () => void }) {
  const [chats, setChats] = useState<any[]>([]);
  const [selectedChat, setSelectedChat] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [patientProfile, setPatientProfile] = useState<any>(null);
  const [testResults, setTestResults] = useState<any>(null);
  const [gameAssessments, setGameAssessments] = useState<any>(null);
  const [aiReport, setAiReport] = useState<any>(null);
  const [showAiReportModal, setShowAiReportModal] = useState(false);
  const [showPrintModal, setShowPrintModal] = useState(false);
  const [showAddPatientModal, setShowAddPatientModal] = useState(false);
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
  
  // Real Patient profiles list from Firebase database
  const [allPatients, setAllPatients] = useState<any[]>([]);
  const [activePatientUid, setActivePatientUid] = useState<string | null>(null);
  const [notifications, setNotifications] = useState<any[]>([]);

  // Memoized dynamic & db notifications combined
  const displayNotifications = React.useMemo(() => {
    if (notifications.length > 0) return notifications;

    if (allPatients.length === 0) {
      return [
        { id: 'n1', title: 'Asesmen baru selesai', desc: 'Arkan Pratama menyelesaikan 4 game', time: '10 menit yang lalu', type: 'success' },
        { id: 'n2', title: 'Asesmen baru selesai', desc: 'Nayla Putri menyelesaikan 5 game', time: '1 jam yang lalu', type: 'success' },
        { id: 'n3', title: 'Perlu perhatian khusus', desc: 'Muhammad Ilyas menunjukkan penurunan skor atensi', time: '2 jam yang lalu', type: 'warning' }
      ];
    }

    const generated: any[] = [];
    allPatients.forEach((patient, idx) => {
      if (idx === 0) {
        generated.push({
          id: `gen-${patient.id}-1`,
          title: 'Asesmen baru selesai',
          desc: `${patient.name} menyelesaikan 4 game`,
          time: '12 menit yang lalu',
          type: 'success'
        });
      } else if (idx === 1) {
        generated.push({
          id: `gen-${patient.id}-2`,
          title: 'Sesi konsultasi dijadwalkan',
          desc: `Jadwal konsultasi baru untuk ${patient.name} telah dikonfirmasi`,
          time: '1 jam yang lalu',
          type: 'info'
        });
      } else if (idx === 2) {
        generated.push({
          id: `gen-${patient.id}-3`,
          title: 'Perlu perhatian khusus',
          desc: `${patient.name} menunjukkan penurunan pada game Memori Visual`,
          time: '3 jam yang lalu',
          type: 'warning'
        });
      }
    });

    if (generated.length < 3) {
      generated.push({
        id: 'n-def-1',
        title: 'Asesmen baru selesai',
        desc: `${allPatients[0].name} menyelesaikan 4 game`,
        time: '15 menit yang lalu',
        type: 'success'
      });
    }

    return generated.slice(0, 5);
  }, [notifications, allPatients]);

  const [patientNames, setPatientNames] = useState<Record<string, string>>({});
  const [patientAvatars, setPatientAvatars] = useState<Record<string, string>>({});
  
  // Doctor Profile State
  const [doctorProfile, setDoctorProfile] = useState<any>(null);
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [isSavingProfile, setIsSavingProfile] = useState(false);
  
  // Active Navigation Menu (Matches Sidebar Mockup)
  const [activeMenu, setActiveMenu] = useState<'dashboard' | 'patients' | 'jadwal' | 'asesmen' | 'laporan' | 'pesan' | 'profil'>('dashboard');
  // Mobile Responsive States
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [mobileShowRadarSheet, setMobileShowRadarSheet] = useState(false);
  const [showPatientDetailOptionsMenu, setShowPatientDetailOptionsMenu] = useState(false);
  // SEGMEN 2 States: Jadwal Filter & Notifications
  const [jadwalTabFilter, setJadwalTabFilter] = useState<'upcoming' | 'completed'>('upcoming');
  const [showNotificationDrawer, setShowNotificationDrawer] = useState(false);
  const [assessmentCategoryFilter, setAssessmentCategoryFilter] = useState('all');

  // Patient detail sub-tabs: 'overview' | 'assessment' | 'notes' | 'reports'
  const [patientDetailTab, setPatientDetailTab] = useState<'overview' | 'assessment' | 'notes' | 'reports'>('overview');
  
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
    localStorage.removeItem('zikola_doctor_id');
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
      setChats(chatsData);

      if (chatsData.length > 0 && !selectedChat) {
        setSelectedChat(chatsData[0]);
        setActivePatientUid(chatsData[0].buyerId);
      }

      chatsData.forEach(chat => {
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
    });

    return () => unsubscribe();
  }, [currentDoctorId, selectedChat]);

  // Fetch All Registered Patient Profiles from the database
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'users'), (snapshot) => {
      const patientsData: any[] = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        const name = data.name || data.profile?.name;
        if (name) {
          patientsData.push({
            id: doc.id,
            name: name,
            avatar: (data.profile?.avatarBase64 || data.avatarBase64) ? `data:image/jpeg;base64,${data.profile?.avatarBase64 || data.avatarBase64}` : (data.avatar || data.profile?.avatar || '👦'),
            age: data.age || data.profile?.age || 8,
            gender: data.gender || data.profile?.gender || 'male',
            school: data.profile?.school || '-',
            parent: data.profile?.parent || '-',
            phone: data.profile?.phone || '-',
          });
        }
      });
      setAllPatients(patientsData);
    }, (error) => {
      console.error("Error loading patient list:", error);
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
      setMessages(msgs);
      setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
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
      } else {
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
      }
    });

    const unsubscribeGames = onSnapshot(doc(db, 'users', activePatientUid, 'data', 'games'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data && data.assessments) {
          setGameAssessments(data.assessments);
        }
      }
    });

    const unsubscribeAiReport = onSnapshot(doc(db, 'users', activePatientUid, 'data', 'ai_report'), (snap) => {
      if (snap.exists()) {
        setAiReport(snap.data());
      } else {
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

    // EMR listener
    const unsubscribeEmr = onSnapshot(doc(db, 'users', activePatientUid, 'emr', 'latest'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data.birthCondition) setEmrBirthCondition(data.birthCondition);
        if (data.pregnancyNotes) setEmrPregnancyNotes(data.pregnancyNotes);
        if (data.allergies) setEmrAllergies(data.allergies);
        if (data.previousTherapy) setEmrPreviousTherapy(data.previousTherapy);
      } else {
        setEmrBirthCondition('Normal (Cukup Bulan)');
        setEmrPregnancyNotes('');
        setEmrAllergies('');
        setEmrPreviousTherapy('');
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

  const getDynamicScore = (gameKey: string, fallbackScore: number) => {
    if (gameAssessments && gameAssessments[gameKey]) {
      return gameAssessments[gameKey].averageScore || fallbackScore;
    }
    return fallbackScore;
  };

  const radarData = [
    { subject: 'Logika', A: getDynamicScore('puzzleGame', 88), fullMark: 100 },
    { subject: 'Memori', A: getDynamicScore('memory', 75), fullMark: 100 },
    { subject: 'Bahasa', A: getDynamicScore('wordPuzzle', 32), fullMark: 100 },
    { subject: 'Motorik', A: getDynamicScore('coloringGame', 80), fullMark: 100 },
    { subject: 'Emosi', A: getDynamicScore('storyBuilderGame', 79), fullMark: 100 }
  ];

  const progressLineData = React.useMemo(() => {
    return [
      { name: 'Observasi 1', Logika: 65, Memori: 58, Atensi: 52 },
      { name: 'Observasi 2', Logika: 72, Memori: 66, Atensi: 63 },
      { name: 'Observasi 3', Logika: 78, Memori: 70, Atensi: 68 },
      { name: 'Sesi Terbaru', Logika: getDynamicScore('puzzleGame', 88), Memori: getDynamicScore('memory', 75), Atensi: getDynamicScore('numberSequence', 72) }
    ];
  }, [gameAssessments]);

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
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Total Asesmen Pasien</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-slate-800">{Math.max(1, allPatients.length * 4)}</span>
              <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded">Aktif</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Tersebar di 4 modul gamifikasi</span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Rata-rata Logika & Penalaran</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-teal-600">{Math.round(radarData[0]?.A || 82)}%</span>
              <span className="text-[9px] font-bold text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded">Optimal</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Tingkat akurasi pemecahan masalah</span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Rata-rata Memori & Atensi</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-indigo-600">{Math.round((radarData[1]?.A + radarData[3]?.A) / 2 || 76)}%</span>
              <span className="text-[9px] font-bold text-indigo-700 bg-indigo-50 px-1.5 py-0.5 rounded">Baik</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Retensi visual & konsentrasi</span>
          </div>

          <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Perlu Stimulasi Tambahan</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-2xl font-black text-amber-600">{Math.max(1, Math.floor(allPatients.length * 0.3))}</span>
              <span className="text-[9px] font-bold text-amber-700 bg-amber-50 px-1.5 py-0.5 rounded">Action Plan</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Rekomendasi stimulasi aktif</span>
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
                <RadarChart cx="50%" cy="50%" outerRadius="75%" data={radarData}>
                  <PolarGrid stroke="#E2E8F0" />
                  <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 8, fontWeight: 'bold' }} />
                  <Radar name="Rata-rata Kohort" dataKey="A" stroke="#0D9488" fill="#14B8A6" fillOpacity={0.3} />
                </RadarChart>
              </ResponsiveContainer>
            </div>
            <div className="border-t border-slate-100 pt-3 space-y-2 text-[11px] font-bold text-slate-600">
              <div className="flex justify-between"><span>🧩 Logika & Problem Solving</span><span className="text-teal-600">{Math.round(radarData[0]?.A || 82)}/100</span></div>
              <div className="flex justify-between"><span>👁️ Memori & Visual Spasial</span><span className="text-teal-600">{Math.round(radarData[1]?.A || 76)}/100</span></div>
              <div className="flex justify-between"><span>🗣️ Bahasa & Kosakata</span><span className="text-teal-600">{Math.round(radarData[2]?.A || 74)}/100</span></div>
              <div className="flex justify-between"><span>🎯 Motorik & Refleks</span><span className="text-teal-600">{Math.round(radarData[3]?.A || 79)}/100</span></div>
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
                      <p className="text-[9px] text-slate-400 font-bold mt-0.5">Status Asesmen: Lengkap • Selesai 4/4 Game</p>
                    </div>
                  </div>

                  <div className="flex items-center space-x-3">
                    <div className="flex space-x-1.5 text-[9px] font-bold">
                      <span className="bg-teal-50 text-teal-700 px-2 py-0.5 rounded">🧩 85</span>
                      <span className="bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded">👁️ 78</span>
                      <span className="bg-amber-50 text-amber-700 px-2 py-0.5 rounded">🔢 72</span>
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
        } else {
          setEmrBirthCondition('Normal (Cukup Bulan)');
          setEmrPregnancyNotes('');
          setEmrAllergies('');
          setEmrPreviousTherapy('');
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
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Pasien Aktif</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-teal-600">
                {allPatients.length > 0 ? allPatients.length : 32}
              </span>
              <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-md">↑ 12%</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Dari minggu lalu</span>
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
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Konsultasi Hari Ini</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-slate-800">
                {chats.length}
              </span>
              <span className="text-[9px] font-bold text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded-md">Padat</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Jadwal hari ini</span>
          </div>
          <div className="h-12 w-20 opacity-20 right-2 absolute">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={[{v:2},{v:5},{v:3},{v:8},{v:4}]}>
                <Area type="monotone" dataKey="v" stroke="#F59E0B" fill="#F59E0B" strokeWidth={3} dot={false} isAnimationActive={false} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
        
        {/* WIDGET 3: Asesmen Baru */}
        <div className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm flex items-center justify-between relative overflow-hidden">
          <div className="z-10">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Asesmen Baru</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-slate-800">7</span>
              <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-md">↑ 4%</span>
            </div>
            <span className="text-[9px] text-slate-400 font-bold mt-1 block">Selesai dalam 24 jam</span>
          </div>
          <div className="h-12 w-20 opacity-20 right-2 absolute">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={[{v:4},{v:2},{v:6},{v:4},{v:7}]}>
                <Line type="monotone" dataKey="v" stroke="#10B981" strokeWidth={3} dot={false} isAnimationActive={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
        
        {/* WIDGET 4: Perlu Perhatian */}
        <div className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm flex items-center justify-between relative overflow-hidden">
          <div className="z-10">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Perlu Perhatian</span>
            <div className="flex items-baseline space-x-2 mt-2">
              <span className="text-3xl font-black text-rose-600">3</span>
              <span className="text-[9px] font-bold text-rose-600 bg-rose-50 px-1.5 py-0.5 rounded-md">Urgent</span>
            </div>
            <span className="text-[9px] text-rose-500 font-bold mt-1 block">AI Flag & Dev Delay</span>
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
            <div className="flex justify-between items-baseline mb-4">
              <h3 className="text-sm font-black text-slate-800">Jadwal Hari Ini</h3>
              <button onClick={() => setActiveMenu('patients')} className="text-[10px] font-black text-teal-600 hover:text-teal-800 uppercase tracking-widest">
                Lihat Semua
              </button>
            </div>
            
            <div className="space-y-4">
              {chats.length === 0 ? (
                <p className="text-xs text-slate-405 italic py-4">Belum ada antrean konsultasi masuk saat ini.</p>
              ) : (
                chats.map((chat, idx) => {
                  const name = patientNames[chat.buyerId] || 'Memuat...';
                  const avatar = patientAvatars[chat.buyerId];
                  const status = chat.expiresAt ? 'Konsultasi Online' : 'Selesai';
                  const color = chat.expiresAt ? 'border-blue-200 text-blue-600 bg-blue-50/20' : 'border-green-200 text-green-600 bg-green-50/20';
                  
                  return (
                    <div 
                      key={chat.id}
                      onClick={() => {
                        setSelectedChat(chat);
                        setActivePatientUid(chat.buyerId);
                        setSelectedPatientId(name);
                        setActiveMenu('pesan');
                      }}
                      className="flex items-center justify-between hover:bg-slate-50 p-2.5 rounded-2xl cursor-pointer transition-colors border border-transparent hover:border-slate-100"
                    >
                      <div className="flex items-center space-x-4">
                        <span className="text-xs font-black text-slate-400">09.00</span>
                        <div className="flex items-center space-x-3">
                          {renderAvatar(avatar, "w-8 h-8", "text-xs")}
                          <div>
                            <h4 className="text-xs font-black text-slate-800 leading-none">{name}</h4>
                            <p className="text-[9px] text-slate-400 font-bold mt-1">Pasien Aktif</p>
                          </div>
                        </div>
                      </div>
                      <span className={`border text-[9px] font-black px-2.5 py-1 rounded-xl ${color}`}>
                        {status}
                      </span>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>

        <div className="col-span-2 space-y-6">
          <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm">
            <div className="flex justify-between items-baseline mb-4">
              <h3 className="text-sm font-black text-slate-800">Notifikasi</h3>
              <button className="text-[10px] font-black text-teal-600 hover:text-teal-800 uppercase tracking-widest">
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
            <h3 className="text-sm font-black text-slate-800">Statistik Mingguan</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 bg-slate-50/50 border border-slate-100 rounded-2xl">
                <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Konsultasi Selesai</span>
                <span className="text-xl font-black text-slate-800 mt-1 block">
                  {chats.length + 12} <span className="text-[9px] text-green-500 font-bold">↑ 12%</span>
                </span>
              </div>
              <div className="p-3 bg-slate-50/50 border border-slate-100 rounded-2xl">
                <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">Asesmen Selesai</span>
                <span className="text-xl font-black text-slate-800 mt-1 block">
                  {allPatients.length * 4 + 4} <span className="text-[9px] text-green-500 font-bold">↑ 8%</span>
                </span>
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
    const age = patientProfile?.age ? `${patientProfile.age} tahun` : '8 tahun';
    const gender = patientProfile?.gender === 'male' ? 'Laki-laki' : 'Perempuan';
    const avatar = patientProfile?.avatar || '👦';

    return (
      <div className="flex-1 overflow-y-auto bg-slate-50/30 p-4 sm:p-6 md:p-8 flex flex-col justify-between h-full">
        <div className="flex justify-between items-center pb-6 border-b border-slate-100">
          <div className="flex items-center space-x-4">
            <button 
              onClick={() => setSelectedPatientId(null)}
              className="w-10 h-10 border border-slate-200 rounded-2xl flex items-center justify-center text-slate-500 hover:bg-slate-50 bg-white"
            >
              <ArrowLeft size={18} />
            </button>
            <div>
              <div className="flex items-center space-x-2">
                <span className="text-lg font-black text-slate-800">{name}</span>
                <span className="text-xs text-slate-400 font-bold">/ {age} • {gender}</span>
              </div>
              <p className="text-[10px] text-slate-400 font-bold mt-1">Status tumbuh kembang terpantau sinkron</p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
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
              className="bg-teal-600 text-white hover:bg-teal-700 px-4 py-2 rounded-xl text-[10px] font-bold shadow-sm transition-colors"
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

        <div className="flex border-b border-slate-100 my-4 md:my-6 bg-white rounded-2xl p-1 shadow-sm w-full max-w-full overflow-x-auto scrollbar-hide">
          {['overview', 'assessment', 'notes', 'reports', 'medical_history'].map((tab) => (
            <button 
              key={tab}
              onClick={() => setPatientDetailTab(tab as any)}
              className={`px-6 py-2 text-xs font-bold rounded-xl transition-all capitalize ${
                patientDetailTab === tab ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-400 hover:text-slate-650'
              }`}
            >
              {tab === 'assessment' ? 'Hasil Asesmen' : tab === 'notes' ? 'Catatan' : tab === 'reports' ? 'Laporan' : tab === 'medical_history' ? 'Rekam Medis (EMR)' : tab}
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
                <button className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-600 font-bold py-2.5 rounded-xl text-[10px] transition-colors mt-2">
                  Lihat Semua
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
                        : `Berdasarkan 4 permainan yang telah diselesaikan, ${name} menunjukkan kemampuan logika di atas rata-rata dan bahasa yang baik. Terdapat penurunan fokus ketika durasi permainan melebihi 8 menit.`}
                    </p>
                  </div>
                  <div className="space-y-2 mt-4">
                    <button 
                      onClick={() => {
                        if (!aiReport) {
                          setAiReport({
                            rawMarkdown: `### Laporan Analisis Tumbuh Kembang Zikola AI\n\n**Nama Pasien Pasien:** ${name}\n**Usia:** ${age}\n**Gelar Analisis:** Sangat Baik\n\n#### Ringkasan Analisis:\nBerdasarkan data asesmen terbaru, anak menunjukkan potensi kecerdasan logika-matematika di atas rata-rata. Kemampuan spasial visual sangat baik (ditunjukkan dari performa game Puzzle Logika). Konsentrasi dan atensi berada di tingkat optimal untuk anak seusianya.\n\n#### Rekomendasi Terapi/Stimulasi:\n1. Berikan permainan puzzle tingkat lanjut (3D Puzzle atau Maze Kompleks).\n2. Berikan latihan berbasis bahasa lisan untuk melatih kepercayaan diri.\n3. Pertahankan pola waktu layar sehat maksimal 45 menit per sesi.`
                          });
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
                  <p className="text-[9px] text-slate-400 font-bold">{formatDateSafe(new Date()).split(",")[0]} oleh {doctorProfile?.name || "Dokter Spesialis"}</p>
                  <p className="text-xs text-slate-700 leading-relaxed font-bold bg-slate-50/50 p-3 rounded-2xl border border-slate-100">
                    "Anak kooperatif dan komunikasi baik. Perlu latihan fokus dan kontrol impuls. Disarankan stimulasi memori jangka pendek secara bertahap."
                  </p>
                </div>

                <div className="bg-white border border-slate-100 rounded-[1.5rem] p-6 shadow-sm space-y-2">
                  <div className="flex justify-between items-baseline">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Status Perkembangan</span>
                    <span className="text-xs font-black text-slate-800">Skor Rata-rata: <span className="text-teal-600">78</span> <span className="text-[10px] font-bold text-green-500">Baik</span></span>
                  </div>
                  
                  <div className="h-[90px] w-full mt-2">
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={progressLineData} margin={{ top: 5, right: 5, left: -25, bottom: 0 }}>
                        <XAxis dataKey="name" tick={{ fontSize: 8, fontWeight: 'bold' }} stroke="#94A3B8" />
                        <YAxis tick={{ fontSize: 8, fontWeight: 'bold' }} stroke="#94A3B8" />
                        <Area type="monotone" dataKey="Logika" stroke="#7C3AED" fill="#E0E7FF" fillOpacity={0.4} />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {patientDetailTab === 'assessment' && (
          <div className="grid grid-cols-4 gap-6 flex-1">
            <div className="col-span-1 bg-white border border-slate-100 rounded-[1.5rem] p-5 shadow-sm space-y-4 h-fit">
              <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Pilih Tanggal Asesmen</span>
              <div className="space-y-2">
                {[
                  { date: 'Sesi Terkini', count: 4 },
                  { date: '25 April 2025', count: 5 },
                  { date: '10 April 2025', count: 3 }
                ].map((item, idx) => (
                  <div 
                    key={idx}
                    onClick={() => setSelectedAssessmentDate(item.date)}
                    className={`p-3.5 border-2 rounded-2xl cursor-pointer transition-all flex items-center justify-between ${
                      selectedAssessmentDate === item.date ? 'border-teal-600 bg-teal-50/40' : 'border-slate-100 hover:border-slate-200 bg-white'
                    }`}
                  >
                    <div>
                      <h4 className="text-xs font-black text-slate-800">{item.date}</h4>
                      <p className="text-[9px] text-slate-400 font-bold mt-1">{item.count} Game</p>
                    </div>
                  </div>
                ))}
              </div>
              <button className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-600 font-bold py-2.5 rounded-xl text-[10px] mt-2">
                Riwayat Lengkap
              </button>
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
                      { label: 'Logika', val: getDynamicScore('puzzleGame', 88), stat: 'Atas Rata-rata', color: 'bg-teal-600' },
                      { label: 'Bahasa', val: getDynamicScore('wordPuzzle', 82), stat: 'Atas Rata-rata', color: 'bg-teal-600' },
                      { label: 'Motorik', val: getDynamicScore('coloringGame', 80), stat: 'Atas Rata-rata', color: 'bg-teal-600' },
                      { label: 'Emosi', val: getDynamicScore('storyBuilderGame', 79), stat: 'Rata-rata', color: 'bg-orange-500' },
                      { label: 'Memori', val: getDynamicScore('memory', 75), stat: 'Rata-rata', color: 'bg-orange-500' },
                      { label: 'Atensi', val: getDynamicScore('numberSequence', 71), stat: 'Perlu Ditingkatkan', color: 'bg-red-500' }
                    ].map((bar, i) => (
                      <div key={i} className="text-[10px] font-bold text-slate-700">
                        <div className="flex justify-between">
                          <span>{bar.label}</span>
                          <span>{bar.val} <span className="text-[8px] font-medium text-slate-400">({bar.stat})</span></span>
                        </div>
                        <div className="w-full bg-slate-100 h-1.5 rounded-full mt-1 overflow-hidden">
                          <div className={`h-full rounded-full ${bar.color}`} style={{ width: `${bar.val}%` }}></div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="col-span-1 pl-4 space-y-3">
                    <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider block">Perkembangan Skor</span>
                    <div className="h-[140px] w-full">
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
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Game yang Dikerjakan</span>
                <div className="grid grid-cols-2 gap-4">
                  {[
                    { title: 'Puzzle Logika', icon: '🧩', score: getDynamicScore('puzzleGame', 85), time: '2m 31s', accuracy: '90%', stat: 'Sangat Baik', statColor: 'text-green-600 bg-green-50' },
                    { title: 'Memori Visual', icon: '👁️', score: getDynamicScore('memory', 78), time: '3m 12s', accuracy: '80%', stat: 'Baik', statColor: 'text-blue-600 bg-blue-50' },
                    { title: 'Math Adventure', icon: '🔢', score: getDynamicScore('numberSequence', 72), time: '4m 05s', accuracy: '75%', stat: 'Baik', statColor: 'text-blue-600 bg-blue-50' },
                    { title: 'Bahasa Seru', icon: '🗣️', score: getDynamicScore('wordPuzzle', 68), time: '3m 40s', accuracy: '70%', stat: 'Cukup', statColor: 'text-orange-600 bg-orange-50' }
                  ].map((card, i) => (
                    <div key={i} className="bg-white border border-slate-100 p-4 rounded-2xl shadow-sm flex items-center justify-between hover:shadow-md transition-shadow">
                      <div className="flex items-center space-x-3">
                        <span className="text-3xl bg-slate-50 p-2.5 rounded-2xl block">{card.icon}</span>
                        <div>
                          <h4 className="text-xs font-black text-slate-800">{card.title}</h4>
                          <div className="flex items-center space-x-2 mt-1.5 text-[9px] text-slate-400 font-bold">
                            <span>Skor: {card.score}/100</span>
                            <span>•</span>
                            <span>{card.time}</span>
                            <span>•</span>
                            <span>{card.accuracy}</span>
                          </div>
                        </div>
                      </div>
                      <span className={`px-2 py-0.5 rounded-lg text-[9px] font-black ${card.statColor}`}>
                        {card.stat}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
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
          
          <div className="bg-slate-50 border border-slate-100 rounded-2xl p-3 text-center">
            <div className="w-14 h-14 rounded-full bg-slate-100 flex items-center justify-center text-2xl mx-auto mb-2 shadow-sm border border-slate-200 overflow-hidden">
              {renderAvatar(patientAvatars[selectedChat?.buyerId], "w-full h-full")}
            </div>
            <h4 className="text-xs font-black text-slate-800 leading-tight">{patientProfile?.name || selectedPatientId || 'Pasien'}</h4>
            <p className="text-[9px] text-slate-400 font-bold mt-0.5">8 tahun 4 bulan</p>
          </div>

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
          
          <button 
            onClick={() => {
              setSelectedPatientId(patientProfile?.name || selectedPatientId || 'Pasien');
              setActiveMenu('patients');
              setPatientDetailTab('overview');
            }}
            className="w-full bg-white hover:bg-slate-50 border border-slate-200 text-teal-600 font-bold py-2 rounded-xl text-[10px] transition-colors shadow-sm"
          >
            Lihat Profil Lengkap
          </button>
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
            
            return (
              <div key={msg.id} className={`flex ${isDoctor ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[75%] p-4 rounded-2xl shadow-sm relative ${
                  isDoctor 
                    ? 'bg-teal-600 text-white rounded-tr-none' 
                    : 'bg-white text-slate-700 rounded-tl-none border border-slate-100'
                }`}>
                  <p className="text-xs leading-relaxed font-bold whitespace-pre-line">{textContent}</p>
                  <span className={`text-[8px] block text-right mt-1.5 font-black ${isDoctor ? 'text-teal-100' : 'text-slate-400'}`}>
                    {msg.timestamp ? (typeof msg.timestamp.toDate === 'function' ? format(msg.timestamp.toDate(), 'HH:mm') : typeof msg.timestamp === 'string' ? format(new Date(msg.timestamp), 'HH:mm') : '') : '09:00'}
                  </span>
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
            <div className="flex items-center justify-center space-x-3 pt-1">
              <button 
                type="button" 
                onClick={() => setShowRatingModal(true)}
                className="px-4 py-2 bg-white border border-slate-200 text-teal-700 rounded-xl text-xs font-bold hover:bg-teal-50 shadow-xs transition-colors flex items-center space-x-1.5"
              >
                <Edit3 size={13} />
                <span>Catatan & Ulasan Kasus</span>
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
                <button type="button" onClick={() => setShowMateriModal(true)} className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50">
                  <FileText size={12} className="text-teal-500" />
                  <span>Kirim Materi</span>
                </button>
                <button type="button" onClick={() => setShowTugasModal(true)} className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50">
                  <Clipboard size={12} className="text-emerald-500" />
                  <span>Beri Tugas</span>
                </button>
                <button type="button" onClick={() => setShowJadwalModal(true)} className="flex items-center space-x-1 px-3 py-1.5 border border-slate-200 rounded-full hover:bg-slate-50">
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
              <span className="text-xs font-black text-slate-800">Rata-rata: <span className="text-teal-600">78</span> <span className="text-[9px] text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">Baik</span></span>
            </div>
            
            <div className="h-[135px] flex items-center justify-center bg-slate-50/50 border border-slate-100 rounded-2xl p-1">
              <ResponsiveContainer width="100%" height="100%">
                <RadarChart cx="50%" cy="50%" outerRadius="72%" data={radarData}>
                  <PolarGrid stroke="#E2E8F0" />
                  <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 6, fontWeight: 'bold' }} />
                  <Radar name="Skor" dataKey="A" stroke="#0D9488" fill="#14B8A6" fillOpacity={0.25} />
                </RadarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="space-y-2.5 border-t border-slate-100 pt-4">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Hasil Game Terkini</span>
            <div className="space-y-1.5 text-xs font-bold text-slate-700">
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-[11px]">🧩 Puzzle Logika</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('puzzleGame', 85)}/100</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-[11px]">👁️ Memori Visual</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('memory', 78)}/100</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-[11px]">🔢 Math Adventure</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('numberSequence', 72)}/100</span>
              </div>
              <div className="flex justify-between items-center py-1">
                <span className="text-[11px]">🗣️ Bahasa Seru</span>
                <span className="text-teal-600 font-black text-[11px]">{getDynamicScore('wordPuzzle', 68)}/100</span>
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
              
              {allPatients.length === 0 ? (
                <div className="bg-white border border-slate-100 p-8 rounded-[1.5rem] shadow-sm text-center text-slate-400">
                  <span className="text-5xl block mb-3">👦</span>
                  <p className="text-xs font-bold">Belum ada pasien terdaftar di database saat ini.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {allPatients.filter(p => p.name.toLowerCase().includes(globalSearch.toLowerCase())).map((patient) => (
                    <div 
                      key={patient.id}
                      onClick={() => { 
                        setActivePatientUid(patient.id);
                        setSelectedPatientId(patient.name); 
                        setPatientDetailTab('overview'); 
                      }}
                      className="bg-white border border-slate-100 p-5 rounded-[1.5rem] shadow-sm hover:shadow-md cursor-pointer transition-all flex items-center space-x-4 border-2 hover:border-teal-500"
                    >
                      {renderAvatar(patient.avatar, "w-12 h-12", "text-xl")}
                      <div>
                        <h4 className="text-xs font-black text-slate-800">{patient.name}</h4>
                        <p className="text-[9px] text-slate-400 mt-1 font-bold">Pasien Real Zikola • Klik untuk detail</p>
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
                  const filteredList = chats.filter(chat => {
                    const isUpcoming = chat.expiresAt ? new Date(chat.expiresAt) > new Date() : true;
                    return jadwalTabFilter === 'upcoming' ? isUpcoming : !isUpcoming;
                  });

                  if (filteredList.length === 0) {
                    return (
                      <div className="text-center py-12 text-slate-400 space-y-2">
                        <span className="text-4xl mb-2 block">📅</span>
                        <p className="text-xs font-bold">
                          {jadwalTabFilter === 'upcoming' 
                            ? 'Belum ada jadwal konsultasi mendatang.' 
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

                  return filteredList.map((chat) => (
                    <div key={'j-' + chat.id} className="border border-slate-100 p-4 rounded-2xl flex items-center justify-between hover:bg-slate-50 transition-colors">
                      <div className="flex items-center space-x-4">
                        <div className="w-12 h-12 bg-teal-50 text-teal-600 rounded-2xl flex flex-col items-center justify-center font-black">
                          <span className="text-sm leading-none">{formatDateSafe(chat.expiresAt || new Date()).split(' ')[0]}</span>
                          <span className="text-[9px] uppercase mt-0.5">{formatDateSafe(chat.expiresAt || new Date()).split(' ')[1]?.substring(0,3) || 'MEI'}</span>
                        </div>
                        <div>
                          <h4 className="text-sm font-black text-slate-800">{patientNames[chat.buyerId] || 'Pasien'}</h4>
                          <div className="flex items-center space-x-2 text-[10px] text-slate-400 font-bold mt-1">
                            <span className="flex items-center"><Calendar size={10} className="mr-1"/> Sesi Online (Chat)</span>
                            <span>•</span>
                            <span>{jadwalTabFilter === 'upcoming' ? '09.00 - 09.45 WIB' : 'Selesai'}</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex space-x-2">
                        <button onClick={() => {
                          setSelectedChat(chat);
                          setActivePatientUid(chat.buyerId);
                          setSelectedPatientId(patientNames[chat.buyerId] || 'Pasien');
                          setActiveMenu('pesan');
                        }} className="px-4 py-2 border border-slate-200 text-teal-600 font-bold text-[10px] rounded-xl hover:bg-teal-50 transition-colors">
                          {jadwalTabFilter === 'upcoming' ? 'Masuk Ruangan' : 'Lihat Rekap Chat'}
                        </button>
                      </div>
                    </div>
                  ));
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
          selectedChat ? (
            <>
              {/* Header Bar */}
              <div className="bg-white p-4 border-b border-slate-100 flex items-center justify-between shadow-sm z-10">
                <div className="flex items-center space-x-3">
                  <button onClick={() => setActiveMenu('dashboard')} className="w-9 h-9 border border-slate-200 rounded-xl flex items-center justify-center text-slate-500 hover:bg-slate-50 bg-white">
                    <ArrowLeft size={18} />
                  </button>
                  <div>
                    <h2 className="text-sm font-black text-slate-800">Konsultasi dengan {patientNames[selectedChat.buyerId] || patientProfile?.name || 'Pasien Zikola'}</h2>
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
                          className="w-full text-left px-3 py-2 text-xs font-bold text-rose-600 hover:bg-rose-50 rounded-xl flex items-center space-x-2"
                        >
                          <X size={14} />
                          <span>Akhiri Sesi Konsultasi</span>
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {renderKonsultasiChatView()}
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-slate-400 bg-white">
              <span className="text-5xl mb-4">💬</span>
              <h3 className="text-base font-black text-slate-700">Pilih Konsultasi</h3>
              <p className="text-xs text-slate-400 mt-1 max-w-xs text-center leading-relaxed">
                Pilih riwayat chat pasien di kolom kiri beranda untuk memulai sesi.
              </p>
            </div>
          )
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
                    const q = query(collection(db, 'chats'), where('buyerId', '==', activePatientUid));
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
                      timestamp: serverTimestamp(), senderType: 'doctor'
                    });
                    
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
                  Usia: {patientProfile?.age || '8'} Tahun • {patientProfile?.gender === 'male' ? 'Laki-laki' : 'Perempuan'}
                </p>
              </div>

              <div className="space-y-3 pt-4 border-t border-slate-100 text-xs">
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Sekolah</span>
                  <span className="text-slate-700 font-black">{patientProfile?.school || '-'}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Hobi Utama</span>
                  <span className="text-slate-700 font-black">{patientProfile?.hobbies || 'Menggambar, Menyusun Puzzle'}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Minat Anak</span>
                  <span className="text-slate-700 font-black">{patientProfile?.interests || 'Seni, Sains'}</span>
                </div>
                <div className="flex justify-between py-1 border-b border-slate-50">
                  <span className="text-slate-400 font-bold">Karakteristik</span>
                  <span className="text-slate-700 font-black">{patientProfile?.personality || 'Tenang, Fokus'}</span>
                </div>
                <div className="flex justify-between py-1">
                  <span className="text-slate-400 font-bold">Gaya Belajar</span>
                  <span className="text-teal-600 font-black">{patientProfile?.learningStyle || 'Visual'}</span>
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
          <div className="bg-slate-100 rounded-3xl w-full max-w-4xl max-h-[95vh] overflow-hidden flex flex-col shadow-2xl">
            <div className="p-4 border-b flex items-center justify-between bg-white">
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
            
            <div className="flex-1 overflow-y-auto p-8 flex justify-center">
              {/* Kertas A4 Mockup */}
              <div className="bg-white w-[210mm] min-h-[297mm] shadow-md border border-slate-200 p-12 text-slate-800 font-sans relative scale-95 origin-top">
                {/* Kop Surat */}
                <div className="border-b-4 border-teal-600 pb-6 mb-6 flex justify-between items-center">
                  <div className="flex items-center space-x-4">
                    <img src={zikolaLogoFull} alt="Logo" className="h-10 object-contain" />
                    <div>
                      <h1 className="text-2xl font-black tracking-tighter text-indigo-900 uppercase">Klinik Zikola</h1>
                      <p className="text-[11px] font-bold text-slate-500 tracking-widest mt-1">PUSAT TUMBUH KEMBANG ANAK & PSIKOLOGI</p>
                      <p className="text-[10px] text-slate-400 mt-0.5">Jl. Jend. Sudirman No. 123, Jakarta 12190 | Telp: (021) 555-0123</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <h2 className="text-[14px] font-black text-slate-800 uppercase">Rekam Medis Elektronik</h2>
                    <p className="text-[11px] text-slate-500 font-medium mt-1">No. RM: <span className="font-bold">ZK-2025-0518-A</span></p>
                    <p className="text-[11px] text-slate-500 font-medium">Tanggal: <span className="font-bold">{formatDateSafe(new Date()).split(",")[0]}</span></p>
                  </div>
                </div>

                {/* Data Pasien & Dokter */}
                <div className="grid grid-cols-2 gap-8 mb-8 text-[11px]">
                  <div className="space-y-2">
                    <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Nama Pasien</span><span className="col-span-2 font-black">: {selectedPatientId || 'Arkan Pratama'}</span></div>
                    <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Usia / Gender</span><span className="col-span-2 font-black">: 8 Tahun / Laki-laki</span></div>
                    <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Nama Orang Tua</span><span className="col-span-2 font-black">: Budi Santoso</span></div>
                  </div>
                  <div className="space-y-2">
                    <div className="grid grid-cols-3"><span className="font-bold text-slate-500">Dokter Pemeriksa</span><span className="col-span-2 font-black">: {doctorProfile?.name || 'dr. Rani'}</span></div>
                    <div className="grid grid-cols-3"><span className="font-bold text-slate-500">SIP / STR</span><span className="col-span-2 font-black">: {doctorProfile?.licenseNumber || 'STR-9876-1234'}</span></div>
                  </div>
                </div>

                {/* Hasil Asesmen Klinis */}
                <div className="mb-8">
                  <h3 className="text-sm font-black text-indigo-900 border-b border-slate-200 pb-2 mb-4 uppercase tracking-widest">A. Hasil Observasi & Asesmen Kognitif</h3>
                  <div className="grid grid-cols-2 gap-8 items-center">
                    <div className="h-48 flex items-center justify-center -ml-8">
                      <ResponsiveContainer width="100%" height="100%">
                        <RadarChart cx="50%" cy="50%" outerRadius="70%" data={radarData}>
                          <PolarGrid stroke="#E2E8F0" />
                          <PolarAngleAxis dataKey="subject" tick={{ fill: '#1E293B', fontSize: 10, fontWeight: 'bold' }} />
                          <Radar dataKey="A" stroke="#0D9488" fill="#0D9488" fillOpacity={0.2} />
                        </RadarChart>
                      </ResponsiveContainer>
                    </div>
                    <div className="space-y-3">
                      <p className="text-[11px] leading-relaxed text-slate-700">
                        Pasien menunjukkan tingkat kemampuan <strong>Logika (85/100)</strong> dan <strong>Visual Spasial</strong> yang sangat baik. Terdapat catatan khusus pada area <strong>Atensi/Fokus (65/100)</strong> yang menurun saat aktivitas melebihi 10 menit berturut-turut.
                      </p>
                      <p className="text-[11px] leading-relaxed text-slate-700">
                        Kemampuan motorik halus sudah sesuai dengan usia perkembangan, terlihat dari kemampuan presisi pada penugasan Puzzle.
                      </p>
                    </div>
                  </div>
                </div>

                {/* Kesimpulan & Diagnosis */}
                <div className="mb-8">
                  <h3 className="text-sm font-black text-indigo-900 border-b border-slate-200 pb-2 mb-4 uppercase tracking-widest">B. Kesimpulan Klinis & Diagnosa Sementara</h3>
                  <div className="bg-slate-50 p-4 rounded-xl border border-slate-200">
                    <p className="text-[12px] font-bold leading-relaxed text-slate-800 whitespace-pre-line">
                      {doctorAiNote ? doctorAiNote : "Tidak ditemukan indikasi keterlambatan kognitif mayor (No Major Cognitive Delay). Terdapat kecenderungan Distraksi Ringan (Mild Inattention) yang wajar di usianya. Memerlukan stimulasi sensori terstruktur untuk meningkatkan regulasi atensi."}
                    </p>
                  </div>
                </div>

                {/* Tanda Tangan */}
                <div className="absolute bottom-16 right-16 text-center">
                  <p className="text-[11px] mb-12">Jakarta, {formatDateSafe(new Date()).split(",")[0]}</p>
                  <p className="text-[11px] font-black underline decoration-2 underline-offset-4">{doctorProfile?.name || 'dr. Rani, M.Psi., Psikolog'}</p>
                  <p className="text-[9px] text-slate-500 mt-2">SIP: {doctorProfile?.licenseNumber || 'STR-001/ZIKOLA/2025'}</p>
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
              <ResponsiveContainer width="100%" height="100%">
                <RadarChart cx="50%" cy="50%" outerRadius="75%" data={radarData}>
                  <PolarGrid stroke="#E2E8F0" />
                  <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 8, fontWeight: 'bold' }} />
                  <Radar name="Skor" dataKey="A" stroke="#0D9488" fill="#14B8A6" fillOpacity={0.25} />
                </RadarChart>
              </ResponsiveContainer>
            </div>

            <div className="space-y-2 border-t border-slate-100 pt-3 text-xs font-bold text-slate-700">
              <div className="flex justify-between py-1 border-b border-slate-50"><span>🧩 Puzzle Logika</span><span className="text-teal-600 font-black">{getDynamicScore('puzzleGame', 85)}/100</span></div>
              <div className="flex justify-between py-1 border-b border-slate-50"><span>👁️ Memori Visual</span><span className="text-teal-600 font-black">{getDynamicScore('memory', 78)}/100</span></div>
              <div className="flex justify-between py-1 border-b border-slate-50"><span>🔢 Math Adventure</span><span className="text-teal-600 font-black">{getDynamicScore('numberSequence', 72)}/100</span></div>
              <div className="flex justify-between py-1"><span>🗣️ Bahasa Seru</span><span className="text-teal-600 font-black">{getDynamicScore('wordPuzzle', 68)}/100</span></div>
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
