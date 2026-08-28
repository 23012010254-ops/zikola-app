import React, { useState } from 'react';

export default function DeleteAccountRequest() {
  const [email, setEmail] = useState('');
  const [reason, setReason] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email.trim()) {
      setSubmitted(true);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 font-sans py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl mx-auto bg-white rounded-3xl p-8 sm:p-12 shadow-sm border border-slate-100">
        <div className="flex items-center space-x-3 mb-6 pb-6 border-b border-slate-100">
          <div className="w-12 h-12 bg-rose-50 text-rose-600 rounded-2xl flex items-center justify-center text-2xl font-bold">
            🗑️
          </div>
          <div>
            <h1 className="text-2xl font-black text-slate-900">Permintaan Penghapusan Akun & Data</h1>
            <p className="text-xs text-slate-500 font-bold mt-1">Zikola Data Deletion Request</p>
          </div>
        </div>

        {submitted ? (
          <div className="p-6 bg-teal-50 border border-teal-100 rounded-2xl text-center space-y-3">
            <span className="text-4xl">✅</span>
            <h3 className="text-base font-black text-teal-900">Permintaan Telah Diterima</h3>
            <p className="text-xs text-teal-700 leading-relaxed">
              Permintaan penghapusan akun untuk <strong>{email}</strong> sedang diproses. Seluruh profil anak, riwayat rekam medis (EMR), hasil tes, dan data login Anda akan dihapus permanen dalam waktu 1x24 jam.
            </p>
            <a href="/" className="inline-block mt-4 text-xs font-bold text-teal-700 underline">
              Kembali ke Beranda
            </a>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-5">
            <p className="text-xs text-slate-600 leading-relaxed">
              Sesuai kebijakan privasi Google Play dan perlindungan data, Anda dapat meminta penghapusan akun serta seluruh data terkait secara permanen. Anda juga dapat melakukan penghapusan instan langsung dari dalam aplikasi mobile Zikola melalui menu <strong>Profil &gt; Hapus Akun</strong>.
            </p>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-700">Email Akun Zikola Terdaftar *</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@email.com"
                required
                className="w-full border border-slate-200 p-3 rounded-xl text-sm outline-none focus:border-teal-500"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-700">Alasan Penghapusan (Opsional)</label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                rows={3}
                placeholder="Berikan masukan singkat untuk perbaikan kami..."
                className="w-full border border-slate-200 p-3 rounded-xl text-xs outline-none focus:border-teal-500 resize-none"
              />
            </div>

            <div className="p-4 bg-amber-50 rounded-2xl border border-amber-100 text-[11px] text-amber-800 space-y-1">
              <p className="font-bold">⚠️ Informasi Penting:</p>
              <p>Penghapusan akun bersifat permanen. Data pencapaian stiker, rapor EMR, dan hasil asesmen anak Anda tidak dapat dipulihkan kembali setelah dihapus.</p>
            </div>

            <button
              type="submit"
              className="w-full py-3.5 bg-rose-600 hover:bg-rose-700 text-white font-black text-sm rounded-xl transition-colors shadow-md"
            >
              Kirim Permintaan Hapus Akun & Data
            </button>
          </form>
        )}

        <div className="mt-8 pt-6 border-t border-slate-100 flex justify-between items-center text-xs text-slate-400">
          <a href="/privacy" className="text-teal-600 font-bold hover:underline">Baca Kebijakan Privasi</a>
          <a href="/" className="text-slate-500 hover:underline">Beranda</a>
        </div>
      </div>
    </div>
  );
}
