import React, { useState, useRef } from 'react';
import { db } from '../lib/firebase';
import { doc, setDoc, getDocs, collection, query, where } from 'firebase/firestore';
import {
  ChevronLeft, User, Mail, Lock, Eye, EyeOff, Phone, FileText, Building2,
  Stethoscope, Wallet, Camera, Upload, X, CheckCircle, ArrowRight
} from 'lucide-react';
import zikolaLogoFull from '../assets/zikola_logo_full.jpg';
import zikolaMascot from '../assets/zikola_mascot.png';

interface DoctorRegisterProps {
  initialData?: {
    email?: string;
    name?: string;
    photoUrl?: string;
    googleUid?: string;
  } | null;
  onBack: () => void;
  onRegisterSuccess: (doctorId: string) => void;
}

export default function DoctorRegister({ initialData, onBack, onRegisterSuccess }: DoctorRegisterProps) {
  const [step, setStep] = useState(1);
  const totalSteps = 3;

  // Form Fields (Pre-fill with Google data if available)
  const [fullName, setFullName] = useState(initialData?.name || '');
  const [email, setEmail] = useState(initialData?.email || '');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [licenseNumber, setLicenseNumber] = useState('');
  const [hospital, setHospital] = useState('');
  const [agreedToTerms, setAgreedToTerms] = useState(false);

  // Step 2 Fields
  const [photo, setPhoto] = useState<string>(initialData?.photoUrl || '');
  const [photoPreview, setPhotoPreview] = useState<string>(initialData?.photoUrl || '');
  const [specialty, setSpecialty] = useState('Psikolog Anak'); // Default to psychologist since Zikola is child psychologist portal
  const [securityPin, setSecurityPin] = useState('');
  const [showSecurityPin, setShowSecurityPin] = useState(false);
  const [bio, setBio] = useState('');
  const [price, setPrice] = useState('150000');
  const [available, setAvailable] = useState(true);
  const [gender, setGender] = useState('female');
  const [education, setEducation] = useState('');
  const [experience, setExperience] = useState('3');
  const [practiceLocation, setPracticeLocation] = useState('Daring');

  // UI State
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const fileInputRef = useRef<HTMLInputElement>(null);

  const specialties = [
    'Psikolog Anak',
    'Psikiater Anak',
    'Terapis Wicara',
    'Terapis Okupasi',
    'Dokter Anak',
    'Dokter Umum',
    'Konselor Keluarga'
  ];

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError('Ukuran foto maksimal 2MB');
      setTimeout(() => setError(''), 3000);
      return;
    }
    const reader = new FileReader();
    reader.onloadend = () => {
      const result = reader.result as string;
      setPhotoPreview(result);
      setPhoto(`base64:${result.split(',')[1]}`);
    };
    reader.readAsDataURL(file);
  };

  const removePhoto = () => {
    setPhoto('');
    setPhotoPreview('');
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const hashPassword = async (pwd: string): Promise<string> => {
    const encoder = new TextEncoder();
    const data = encoder.encode(pwd);
    const hash = await crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
  };

  const validateStep1 = (): boolean => {
    const errors: Record<string, string> = {};
    
    if (!fullName.trim()) errors.fullName = 'Nama lengkap wajib diisi';
    
    if (!email.trim()) errors.email = 'Email wajib diisi';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.email = 'Format email tidak valid';
    
    if (!phone.trim()) errors.phone = 'Nomor telepon wajib diisi';
    
    if (!password) errors.password = 'Kata sandi wajib diisi';
    else if (password.length < 8) errors.password = 'Kata sandi minimal 8 karakter';
    
    if (password !== confirmPassword) errors.confirmPassword = 'Konfirmasi kata sandi tidak cocok';
    
    if (!licenseNumber.trim()) errors.licenseNumber = 'Nomor STR / SIP wajib diisi';
    
    if (!agreedToTerms) errors.agreedToTerms = 'Anda harus menyetujui Syarat & Ketentuan';

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const validateStep2 = (): boolean => {
    const errors: Record<string, string> = {};
    if (!photo) errors.photo = 'Foto profil wajib diunggah';
    if (!securityPin) errors.securityPin = 'PIN Keamanan wajib diisi';
    else if (securityPin.length !== 6 || !/^\d+$/.test(securityPin)) errors.securityPin = 'PIN harus 6 digit angka';
    if (!bio.trim()) errors.bio = 'Bio / Deskripsi diri wajib diisi';
    else if (bio.length < 20) errors.bio = 'Bio minimal 20 karakter';
    if (!price) errors.price = 'Biaya konsultasi wajib diisi';
    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleNext = () => {
    setError('');
    if (step === 1 && validateStep1()) {
      setStep(2);
    } else if (step === 2 && validateStep2()) {
      setStep(3);
    }
  };

  const handlePrev = () => {
    setError('');
    setFieldErrors({});
    if (step > 1) setStep(step - 1);
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    setError('');

    try {
      const generatedUsername = fullName.toLowerCase().trim().replace(/[^a-z0-9]/g, '-').replace(/-+/g, '-');
      
      // Check username uniqueness
      const credQuery = query(collection(db, 'doctor_credentials'), where('username', '==', generatedUsername));
      const existing = await getDocs(credQuery);
      if (!existing.empty) {
        setError('Nama lengkap ini sudah terdaftar. Silakan hubungi admin jika ini kesalahan.');
        setIsSubmitting(false);
        setStep(1);
        return;
      }

      const doctorId = `doctor_${Date.now()}`;
      const hashedPwd = await hashPassword(password);

      // Save credentials
      await setDoc(doc(db, 'doctor_credentials', doctorId), {
        username: generatedUsername,
        email: email.toLowerCase().trim(),
        password: hashedPwd,
        securityPin: await hashPassword(securityPin),
        doctorId,
        createdAt: new Date().toISOString(),
      });

      // Save doctor profile
      await setDoc(doc(db, 'doctors', doctorId), {
        name: fullName.trim(),
        specialty: specialty,
        hospital: hospital.trim() || 'Zikola Clinic',
        education: education.trim() || 'S1 Psikologi',
        experience: parseInt(experience) || 3,
        licenseNumber: licenseNumber.trim(),
        practiceLocation: practiceLocation.trim() || 'Daring',
        gender: gender,
        image: photo,
        bio: bio.trim(),
        price: parseInt(price) || 150000,
        available: available,
        email: email.toLowerCase().trim(),
        phone: phone.trim(),
        rating: 5.0,
        ratingCount: 0,
        verified: true,
        registeredAt: new Date().toISOString(),
      });

      onRegisterSuccess(doctorId);
    } catch (err: any) {
      console.error('Registration error:', err);
      setError('Terjadi kesalahan saat mendaftar. Silakan coba lagi.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const renderFieldError = (field: string) => {
    if (!fieldErrors[field]) return null;
    return (
      <p className="text-red-500 text-xs mt-1 ml-1 flex items-center space-x-1">
        <span className="w-1.5 h-1.5 bg-red-500 rounded-full"></span>
        <span>{fieldErrors[field]}</span>
      </p>
    );
  };

  return (
    <div className="min-h-screen bg-white flex items-center justify-center p-4 md:p-8 font-sans">
      <div className="max-w-xl w-full bg-white rounded-2xl shadow-[0_4px_24px_rgba(0,0,0,0.06)] border border-slate-100 p-8 md:p-10 relative">
        
        {/* Top Header Row */}
        <div className="flex items-center justify-between mb-8">
          <button 
            onClick={step > 1 ? handlePrev : onBack} 
            className="w-10 h-10 border border-slate-200 rounded-xl flex items-center justify-center text-slate-500 hover:bg-slate-50 transition-colors"
          >
            <ChevronLeft size={20} />
          </button>
          <p className="text-sm font-medium text-slate-500">
            Sudah punya akun?{' '}
            <button onClick={onBack} className="font-bold text-teal-600 hover:text-teal-800 transition-colors">
              Masuk
            </button>
          </p>
        </div>

        {/* Logo and Headings */}
        <div className="flex flex-col items-center mb-8">
          <img src={zikolaLogoFull} alt="Zikola" className="h-10 object-contain mb-4" />
          <h2 className="text-2xl font-black text-slate-800 tracking-tight">Daftar Akun Psikolog</h2>
          <p className="text-sm text-slate-500 font-medium mt-1">Bergabunglah dengan platform profesional Zikola</p>
        </div>

        {/* Wizard Progress Indicator */}
        <div className="flex items-center justify-between max-w-sm mx-auto mb-10 relative">
          <div className="absolute left-0 right-0 top-1/2 -translate-y-1/2 h-[2px] bg-slate-100 z-0"></div>
          
          {/* Step 1 indicator */}
          <div className="relative z-10 flex flex-col items-center">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 ${
              step >= 1 ? 'bg-teal-600 text-white shadow-md shadow-teal-100' : 'bg-slate-100 text-slate-400'
            }`}>
              1
            </div>
            <span className="text-[10px] font-bold text-slate-500 mt-2">Informasi Akun</span>
          </div>

          {/* Step 2 indicator */}
          <div className="relative z-10 flex flex-col items-center">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 ${
              step >= 2 ? 'bg-teal-600 text-white shadow-md shadow-teal-100' : 'bg-slate-100 text-slate-400'
            }`}>
              2
            </div>
            <span className="text-[10px] font-bold text-slate-500 mt-2">Verifikasi</span>
          </div>

          {/* Step 3 indicator */}
          <div className="relative z-10 flex flex-col items-center">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 ${
              step >= 3 ? 'bg-teal-600 text-white shadow-md shadow-teal-100' : 'bg-slate-100 text-slate-400'
            }`}>
              3
            </div>
            <span className="text-[10px] font-bold text-slate-500 mt-2">Selesai</span>
          </div>
        </div>

        {/* Wizard Form Sections */}
        {step === 1 && (
          <div className="space-y-4 animate-in fade-in duration-300">
            {/* Nama Lengkap */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Nama Lengkap</label>
              <div className="relative group">
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Masukkan nama lengkap Anda"
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <User size={18} />
                </div>
              </div>
              {renderFieldError('fullName')}
            </div>

            {/* Email */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Email</label>
              <div className="relative group">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Masukkan email profesional Anda"
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Mail size={18} />
                </div>
              </div>
              {renderFieldError('email')}
            </div>

            {/* Nomor Telepon */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Nomor Telepon</label>
              <div className="relative group">
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Masukkan nomor telepon"
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Phone size={18} />
                </div>
              </div>
              {renderFieldError('phone')}
            </div>

            {/* Kata Sandi */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Kata Sandi</label>
              <div className="relative group">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Buat kata sandi"
                  className="w-full pl-11 pr-11 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Lock size={18} />
                </div>
                <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400">
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              <p className="text-[10px] text-slate-400 ml-1 font-medium">Minimal 8 karakter dengan kombinasi huruf, angka, dan simbol</p>
              {renderFieldError('password')}
            </div>

            {/* Konfirmasi Kata Sandi */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Konfirmasi Kata Sandi</label>
              <div className="relative group">
                <input
                  type={showConfirmPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Ulangi kata sandi Anda"
                  className="w-full pl-11 pr-11 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Lock size={18} />
                </div>
                <button type="button" onClick={() => setShowConfirmPassword(!showConfirmPassword)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400">
                  {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              {renderFieldError('confirmPassword')}
            </div>

            {/* Nomor STR / SIP */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Nomor STR / SIP</label>
              <div className="relative group">
                <input
                  type="text"
                  value={licenseNumber}
                  onChange={(e) => setLicenseNumber(e.target.value)}
                  placeholder="Masukkan nomor STR atau SIP Anda"
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <FileText size={18} />
                </div>
              </div>
              {renderFieldError('licenseNumber')}
            </div>

            {/* Institusi / Praktek */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Institusi / Praktek <span className="text-slate-400 font-medium">(opsional)</span></label>
              <div className="relative group">
                <input
                  type="text"
                  value={hospital}
                  onChange={(e) => setHospital(e.target.value)}
                  placeholder="Nama institusi atau tempat praktek Anda"
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Building2 size={18} />
                </div>
              </div>
            </div>

            {/* Checkbox Persetujuan */}
            <div className="flex items-start space-x-2 pt-2 ml-1">
              <input
                type="checkbox"
                id="agreedToTerms"
                checked={agreedToTerms}
                onChange={(e) => setAgreedToTerms(e.target.checked)}
                className="w-4 h-4 mt-0.5 text-teal-600 border-slate-300 rounded focus:ring-indigo-500"
              />
              <label htmlFor="agreedToTerms" className="text-xs font-bold text-slate-600 select-none cursor-pointer">
                Saya menyetujui <span className="text-teal-600 hover:underline">Syarat & Ketentuan</span> dan <span className="text-teal-600 hover:underline">Kebijakan Privasi</span>
              </label>
            </div>
            {renderFieldError('agreedToTerms')}

            {/* Button Selanjutnya */}
            <div className="pt-6">
              <button
                type="button"
                onClick={handleNext}
                className="w-full bg-teal-600 hover:bg-teal-700 text-white py-3.5 rounded-xl font-bold text-sm tracking-wide flex items-center justify-center space-x-2 transition-all duration-300 active:scale-[0.98]"
              >
                <span>Selanjutnya</span>
                <ArrowRight size={16} />
              </button>
            </div>
          </div>
        )}

        {step === 2 && (
          <div className="space-y-4 animate-in fade-in duration-300">
            {/* Foto Profil */}
            <div className="space-y-1.5 flex flex-col items-center">
              <label className="text-xs font-bold text-slate-600 mr-auto ml-1">Foto Profil <span className="text-red-500">*</span></label>
              {photoPreview ? (
                <div className="relative group mt-2">
                  <img
                    src={photoPreview}
                    alt="Preview"
                    className="w-32 h-32 rounded-3xl object-cover border-4 border-white shadow-xl"
                  />
                  <button
                    type="button"
                    onClick={removePhoto}
                    className="absolute -top-2 -right-2 w-8 h-8 bg-red-500 text-white rounded-full flex items-center justify-center shadow-lg hover:bg-red-600 transition-all opacity-0 group-hover:opacity-100"
                  >
                    <X size={16} />
                  </button>
                  <div className="absolute inset-0 bg-black/20 rounded-3xl flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all cursor-pointer"
                    onClick={() => fileInputRef.current?.click()}>
                    <Camera size={24} className="text-white" />
                  </div>
                </div>
              ) : (
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className={`w-32 h-32 mt-2 border-2 border-dashed rounded-3xl flex flex-col items-center justify-center transition-all duration-300 cursor-pointer bg-slate-50 hover:bg-teal-50 border-slate-200 hover:border-indigo-400`}
                >
                  <Upload size={28} className="mb-2 text-slate-400" />
                  <span className="text-xs font-bold text-slate-500">Unggah Foto</span>
                  <span className="text-[10px] text-slate-300 mt-0.5">Maks 2MB</span>
                </button>
              )}
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handlePhotoChange}
                className="hidden"
              />
              {renderFieldError('photo')}
            </div>

            {/* Specialty Selection */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Spesialisasi</label>
              <div className="relative">
                <select
                  value={specialty}
                  onChange={(e) => setSpecialty(e.target.value)}
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm appearance-none cursor-pointer focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                >
                  {specialties.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Stethoscope size={18} />
                </div>
              </div>
            </div>

            {/* PIN Keamanan */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">PIN Keamanan (6 Digit)</label>
              <div className="relative group">
                <input
                  type={showSecurityPin ? 'text' : 'password'}
                  maxLength={6}
                  pattern="\d*"
                  value={securityPin}
                  onChange={(e) => setSecurityPin(e.target.value.replace(/\D/g, ''))}
                  placeholder="Buat 6 digit PIN pemulihan sandi"
                  className="w-full pl-11 pr-11 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Lock size={18} />
                </div>
                <button type="button" onClick={() => setShowSecurityPin(!showSecurityPin)} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400">
                  {showSecurityPin ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              {renderFieldError('securityPin')}
            </div>

            {/* Bio */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Bio / Deskripsi Singkat</label>
              <textarea
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                rows={3}
                placeholder="Ceritakan singkat tentang keahlian dan minat klinis Anda..."
                className="w-full p-4 bg-white border border-slate-200 rounded-xl outline-none text-sm resize-none focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
              />
              <div className="flex justify-between items-center ml-1">
                {renderFieldError('bio')}
                <span className={`text-[10px] ml-auto ${bio.length >= 20 ? 'text-green-500' : 'text-slate-300'}`}>{bio.length}/20+</span>
              </div>
            </div>

            {/* Biaya Konsultasi */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-600 ml-1">Biaya Konsultasi (Rp)</label>
              <div className="relative group">
                <input
                  type="number"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="Masukkan biaya per sesi"
                  className="w-full pl-11 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm focus:border-teal-500 focus:ring-1 focus:ring-teal-100 transition-all shadow-sm"
                />
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Wallet size={18} />
                </div>
              </div>
              {price && (
                <p className="text-xs text-slate-400 ml-1">
                  Rp {parseInt(price).toLocaleString('id-ID')} per sesi konsultasi
                </p>
              )}
              {renderFieldError('price')}
            </div>

            {/* Buttons */}
            <div className="grid grid-cols-2 gap-3 pt-6">
              <button
                type="button"
                onClick={handlePrev}
                className="w-full border border-slate-200 hover:bg-slate-50 text-slate-700 py-3 rounded-xl font-bold text-sm transition-all"
              >
                Kembali
              </button>
              <button
                type="button"
                onClick={handleNext}
                className="w-full bg-teal-600 hover:bg-teal-700 text-white py-3 rounded-xl font-bold text-sm transition-all flex items-center justify-center space-x-2"
              >
                <span>Lanjutkan</span>
                <ArrowRight size={16} />
              </button>
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="space-y-6 text-center animate-in fade-in duration-300 py-8">
            <div className="w-20 h-20 bg-emerald-50 text-emerald-500 rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg shadow-emerald-100 animate-bounce">
              <CheckCircle size={48} />
            </div>
            
            <div>
              <h3 className="text-xl font-black text-slate-800">Semua Data Siap!</h3>
              <p className="text-sm text-slate-500 mt-2 max-w-sm mx-auto leading-relaxed">
                Kredensial dan data profil Anda telah tervalidasi dengan lengkap. Klik tombol di bawah untuk menyelesaikan pendaftaran Anda.
              </p>
            </div>

            {error && (
              <div className="bg-red-50 text-red-700 p-4 rounded-2xl text-xs font-bold border border-red-100 max-w-md mx-auto">
                ❌ {error}
              </div>
            )}

            <div className="pt-6 flex flex-col space-y-3">
              <button
                type="button"
                disabled={isSubmitting}
                onClick={handleSubmit}
                className="w-full bg-teal-600 hover:bg-teal-700 text-white py-3.5 rounded-xl font-bold text-sm tracking-wide flex items-center justify-center space-x-2 shadow-lg shadow-teal-100 transition-all duration-300 active:scale-[0.98]"
              >
                {isSubmitting ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <span>Selesaikan Pendaftaran</span>
                )}
              </button>
              
              <button
                type="button"
                onClick={handlePrev}
                disabled={isSubmitting}
                className="w-full text-center text-xs font-bold text-slate-400 hover:text-slate-600 py-2 transition-colors"
              >
                Kembali ke detail profil
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
