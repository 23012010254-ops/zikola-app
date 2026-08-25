import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Wallet, CreditCard, Smartphone, Clock } from 'lucide-react';

interface PaymentScreenProps {
  navigateTo: (screen: string) => void;
  doctor: any;
}

export default function PaymentScreen({ navigateTo, doctor }: PaymentScreenProps) {
  const [selectedMethod, setSelectedMethod] = useState('gopay');
  const [isProcessing, setIsProcessing] = useState(false);

  if (!doctor) {
    navigateTo('consultation');
    return null;
  }

  const paymentMethods = [
    {
      id: 'dana',
      name: 'DANA',
      icon: '💙',
      description: 'Saldo atau metode pembayaran di app',
      selected: selectedMethod === 'dana'
    },
    {
      id: 'ovo',
      name: 'OVO',
      icon: '💜', 
      description: 'Bayar dari saldo OVO kamu',
      selected: selectedMethod === 'ovo'
    },
    {
      id: 'gopay',
      name: 'Go-Pay',
      icon: '💚',
      description: 'Scan QR Code di Gojek',
      selected: selectedMethod === 'gopay'
    }
  ];

  const virtualAccounts = [
    { id: 'bca', name: 'BCA Virtual Account', icon: '🏦' },
    { id: 'mandiri', name: 'Mandiri Virtual Account', icon: '🏦' },
    { id: 'bni', name: 'BNI Virtual Account', icon: '🏦' },
    { id: 'bri', name: 'BRI Virtual Account', icon: '🏦' }
  ];

  const handlePayment = () => {
    setIsProcessing(true);
    // Simulate payment processing
    setTimeout(() => {
      setIsProcessing(false);
      navigateTo('chat');
    }, 3000);
  };

  if (isProcessing) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white rounded-3xl p-8 shadow-xl text-center max-w-sm mx-4"
        >
          <div className="w-16 h-16 bg-blue-100 rounded-full mx-auto mb-4 flex items-center justify-center">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
            >
              <Clock className="w-8 h-8 text-blue-600" />
            </motion.div>
          </div>
          <h3 className="text-xl font-heading font-bold text-gray-900 mb-2">
            Memproses Pembayaran
          </h3>
          <p className="text-gray-600 font-body">
            Mohon tunggu sebentar...
          </p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white px-6 pt-14 pb-6 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <motion.button
            onClick={() => navigateTo('doctor-detail')}
            className="p-2 rounded-xl bg-gray-100"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="w-6 h-6 text-gray-600" />
          </motion.button>
          <h1 className="text-gray-900 font-heading font-bold text-xl">Metode Pembayaran</h1>
          <div className="w-10" />
        </div>
      </div>

      <div className="p-6 pb-24">
        {/* Payment Summary */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-blue-500 rounded-2xl p-4 mb-6 text-white"
        >
          <div className="flex items-center justify-between mb-3">
            <h3 className="font-heading font-semibold text-base">Total Pembayaran</h3>
            <Wallet className="w-5 h-5" />
          </div>
          <div className="text-3xl font-heading font-bold mb-2">
            Rp {doctor.price.toLocaleString()}
          </div>
          <div className="flex items-center space-x-2 text-blue-100">
            <span className="text-sm font-body">Konsultasi dengan</span>
            <span className="text-sm font-body font-semibold">{doctor.name}</span>
          </div>
        </motion.div>

        {/* Digital Wallets */}
        <div className="mb-6">
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Dompet Digital</h3>
          <div className="space-y-3">
            {paymentMethods.map((method, index) => (
              <motion.button
                key={method.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                onClick={() => setSelectedMethod(method.id)}
                className={`w-full bg-white rounded-2xl p-4 shadow-sm border-2 transition-all ${
                  method.selected 
                    ? 'border-orange-500 bg-orange-50' 
                    : 'border-gray-100 hover:border-gray-200'
                }`}
              >
                <div className="flex items-center space-x-4">
                  <div className="text-2xl">{method.icon}</div>
                  <div className="flex-1 text-left">
                    <h4 className="text-gray-900 font-heading font-semibold text-base">
                      {method.name}
                    </h4>
                    <p className="text-gray-500 font-body text-sm">
                      {method.description}
                    </p>
                  </div>
                  <div className={`w-4 h-4 rounded-full border-2 transition-all ${
                    method.selected
                      ? 'border-orange-500 bg-orange-500'
                      : 'border-gray-300'
                  }`}>
                    {method.selected && (
                      <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5" />
                    )}
                  </div>
                </div>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Virtual Accounts */}
        <div className="mb-6">
          <h3 className="text-gray-900 font-heading font-bold text-lg mb-4">Virtual Account</h3>
          <div className="space-y-3">
            {virtualAccounts.map((va, index) => (
              <motion.button
                key={va.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: (paymentMethods.length + index) * 0.1 }}
                onClick={() => setSelectedMethod(va.id)}
                className={`w-full bg-white rounded-2xl p-4 shadow-sm border-2 transition-all ${
                  selectedMethod === va.id
                    ? 'border-orange-500 bg-orange-50' 
                    : 'border-gray-100 hover:border-gray-200'
                }`}
              >
                <div className="flex items-center space-x-4">
                  <div className="text-2xl">{va.icon}</div>
                  <div className="flex-1 text-left">
                    <h4 className="text-gray-900 font-heading font-semibold text-base">
                      {va.name}
                    </h4>
                  </div>
                  <div className={`w-4 h-4 rounded-full border-2 transition-all ${
                    selectedMethod === va.id
                      ? 'border-orange-500 bg-orange-500'
                      : 'border-gray-300'
                  }`}>
                    {selectedMethod === va.id && (
                      <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5" />
                    )}
                  </div>
                </div>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Payment Details */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-white rounded-2xl p-4 mb-6 shadow-sm"
        >
          <h4 className="text-gray-900 font-heading font-semibold text-base mb-3">
            Rincian Pembayaran
          </h4>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-600 font-body text-sm">Biaya Konsultasi</span>
              <span className="text-gray-900 font-body font-medium text-sm">
                Rp {doctor.price.toLocaleString()}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600 font-body text-sm">Biaya Admin</span>
              <span className="text-gray-900 font-body font-medium text-sm">Rp 2.500</span>
            </div>
            <div className="border-t border-gray-100 pt-2 mt-2">
              <div className="flex justify-between">
                <span className="text-gray-900 font-body font-bold text-base">Total</span>
                <span className="text-gray-900 font-body font-bold text-base">
                  Rp {(doctor.price + 2500).toLocaleString()}
                </span>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Pay Button */}
        <motion.button
          onClick={handlePayment}
          className="w-full btn-orange"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
        >
          Bayar
        </motion.button>
      </div>
    </div>
  );
}