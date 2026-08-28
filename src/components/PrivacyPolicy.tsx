import React from 'react';

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 font-sans py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-white rounded-3xl p-8 sm:p-12 shadow-sm border border-slate-100">
        <div className="flex items-center space-x-3 mb-8 pb-6 border-b border-slate-100">
          <div className="w-12 h-12 bg-teal-50 text-teal-600 rounded-2xl flex items-center justify-center text-2xl font-bold">
            🛡️
          </div>
          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-slate-900">Kebijakan Privasi Zikola</h1>
            <p className="text-xs text-slate-500 font-bold mt-1">Terakhir diperbarui: 28 Agustus 2026</p>
          </div>
        </div>

        <div className="space-y-6 text-sm text-slate-600 leading-relaxed">
          <section>
            <h2 className="text-base font-black text-slate-900 mb-2">1. Pendahuluan</h2>
            <p>
              Aplikasi <strong>Zikola</strong> ("kami") berkomitmen penuh untuk melindungi privasi dan keamanan data anak serta keluarga Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi pribadi pengguna aplikasi mobile Zikola dan portal web Zikola sesuai dengan ketentuan Google Play Families Policy dan hukum perlindungan data anak (COPPA).
            </p>
          </section>

          <section>
            <h2 className="text-base font-black text-slate-900 mb-2">2. Data yang Kami Kumpulkan</h2>
            <ul className="list-disc pl-5 space-y-1.5 mt-2">
              <li><strong>Data Akun Orang Tua:</strong> Nama, alamat email, dan kredensial login yang digunakan untuk autentikasi via Firebase Auth.</li>
              <li><strong>Profil Anak:</strong> Nama panggilan/inisial, usia/tanggal lahir, jenis kelamin, dan preferensi avatar untuk personalisasi materi stimulasi.</li>
              <li><strong>Data Perkembangan & Asesmen:</strong> Skor pengerjaan mini-game kognitif, linguistik, motorik, stiker pencapaian, dan catatan rekam medis (EMR) yang dibuat bersama dokter.</li>
              <li><strong>Audio / Suara:</strong> Izin mikrofon hanya digunakan saat sesi telekonsultasi langsung dengan dokter spesialis anak atau saat tes fonetik. Kami tidak merekam atau menjual data suara anak kepada pihak ketiga.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base font-black text-slate-900 mb-2">3. Perlindungan Khusus Anak (Google Play Families Policy)</h2>
            <p>
              Zikola dirancang aman untuk anak-anak:
            </p>
            <ul className="list-disc pl-5 space-y-1.5 mt-2">
              <li>Kami <strong>tidak menampilkan iklan pihak ketiga</strong> (No Ads).</li>
              <li>Kami <strong>tidak menggunakan pelacak perilaku (trackers)</strong> lintas aplikasi.</li>
              <li>Seluruh fitur komunikasi eksternal dan telekonsultasi dokter dilindungi oleh <strong>Parental Gate (PIN Orang Tua)</strong>.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base font-black text-slate-900 mb-2">4. Penyimpanan & Keamanan Data</h2>
            <p>
              Seluruh data dienkripsi saat transit menggunakan protokol standar industri (HTTPS/TLS) dan disimpan di infrastruktur cloud Firebase Google yang aman. Data hanya dapat diakses oleh orang tua dan dokter berlisensi yang menangani sesi konsultasi.
            </p>
          </section>

          <section>
            <h2 className="text-base font-black text-slate-900 mb-2">5. Hak Pengguna & Penghapusan Akun (Data Deletion)</h2>
            <p>
              Anda memiliki hak penuh untuk melihat, mengubah, atau menghapus seluruh data akun dan data anak Anda kapan saja. Anda dapat menghapus akun secara langsung di dalam aplikasi melalui menu <em>Profil &gt; Hapus Akun</em> atau melalui halaman web resmi kami di <a href="/delete-account" className="text-teal-600 font-bold underline">Halaman Permintaan Hapus Akun</a>.
            </p>
          </section>

          <section>
            <h2 className="text-base font-black text-slate-900 mb-2">6. Kontak Kami</h2>
            <p>
              Jika Anda memiliki pertanyaan terkait Kebijakan Privasi ini, silakan hubungi tim kami di:
            </p>
            <p className="mt-1 text-slate-800 font-semibold">
              Email: support@zikola-app.com / help.zikola@gmail.com<br />
              Website: https://anak-app.web.app
            </p>
          </section>
        </div>

        <div className="mt-10 pt-6 border-t border-slate-100 flex justify-between items-center text-xs text-slate-400">
          <span>&copy; 2026 Zikola App. Hak Cipta Dilindungi.</span>
          <a href="/" className="text-teal-600 font-bold hover:underline">Kembali ke Beranda</a>
        </div>
      </div>
    </div>
  );
}
