import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = 'gopay';
  bool isProcessing = false;
  final PaymentService _paymentService = PaymentService();
  final FirestoreService _firestoreService = FirestoreService();

  void _processPayment(Map<String, dynamic> doc) async {
    setState(() => isProcessing = true);
    
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.uid ?? 'guest';
    final doctorId = doc['id'] ?? 'doc_default';
    final doctorName = doc['name'] ?? 'Dokter Zikola';
    final amount = (doc['price'] as int) + 2500; // includes admin fee
    
    final orderId = _paymentService.generateOrderId();

    // Request Snap Transaction via PaymentService
    final result = await _paymentService.createSnapTransaction(
      orderId: orderId,
      amount: amount,
      userId: userId,
      doctorId: doctorId,
      doctorName: doctorName,
      paymentMethod: selectedMethod,
    );

    if (!mounted) return;
    setState(() => isProcessing = false);

    if (result.isSuccess) {
      // Show Midtrans Payment Gateway Dialog Modal
      _showMidtransGatewayModal(
        doc: doc,
        orderId: orderId,
        amount: amount,
        snapToken: result.snapToken ?? 'SNAP-DEMO-TOKEN',
        userId: userId,
        doctorId: doctorId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Gagal memproses transaksi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMidtransGatewayModal({
    required Map<String, dynamic> doc,
    required String orderId,
    required int amount,
    required String snapToken,
    required String userId,
    required String doctorId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder(
          stream: _firestoreService.getPaymentStream(orderId),
          builder: (context, snapshot) {
            final paymentData = snapshot.data?.data() as Map<String, dynamic>?;
            final status = paymentData?['status'] ?? 'pending';
            final isSettled = status == 'settlement' || status == 'success';

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Gateway
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Midtrans',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Gateway',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSettled ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSettled ? Colors.green.shade300 : Colors.amber.shade300,
                          ),
                        ),
                        child: Text(
                          isSettled ? 'BERHASIL' : 'MENUNGGU PEMBAYARAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSettled ? Colors.green.shade700 : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Transaction Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('No. Referensi / Order ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(orderId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Tagihan', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('Rp ${AppState.formatCurrency(amount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instructions based on method
                  Text(
                    'Instruksi Pembayaran (${selectedMethod.toUpperCase()}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedMethod == 'gopay' || selectedMethod == 'ovo'
                              ? Icons.qr_code_scanner
                              : Icons.credit_card,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedMethod == 'gopay' || selectedMethod == 'ovo'
                                ? 'Buka aplikasi eWallet Anda, lalu pindai kode QRIS atau konfirmasi pemotongan saldo $selectedMethod.'
                                : 'Transfer ke Nomor Virtual Account BCA/Mandiri sesuai total tagihan di atas.',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulation Button for Sandbox Testing
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSettled ? Colors.green.shade600 : const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(isSettled ? Icons.check_circle : Icons.payment, color: Colors.white),
                      label: Text(
                        isSettled ? 'Pembayaran Lunas — Masuk Chat' : 'Simulasi Bayar Sekarang (Sandbox Test)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () async {
                        if (!isSettled) {
                          await _paymentService.confirmPaymentSuccess(
                            orderId: orderId,
                            userId: userId,
                            doctorId: doctorId,
                          );
                        }
                        if (mounted) {
                          Navigator.pop(context); // close bottom sheet
                          _showSuccessAndNavigate(doc, orderId);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bayar Nanti', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessAndNavigate(Map<String, dynamic> doc, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Order ID: $orderId', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('Status pembayaran telah dikonfirmasi oleh Midtrans.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pushReplacementNamed(context, '/chat', arguments: doc); // go to chat
                },
                child: const Text('Mulai Konsultasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get doc args safely (using placeholder if null for testing)
    final doc = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {
      'name': 'Dr. Sarah Setiawan, Sp.A',
      'specialty': 'Dokter Anak',
      'price': 150000,
      'image': '👩‍⚕️',
    };

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Card
                    RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.center,
                                  child: _buildAvatar(doc['image'] ?? '👨‍⚕️', size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text(doc['specialty'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Biaya Konsultasi', style: TextStyle(color: Colors.grey.shade600)),
                                Text('Rp ${AppState.formatCurrency(doc['price'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Biaya Admin', style: TextStyle(color: Colors.grey.shade600)),
                                Text('Rp ${AppState.formatCurrency(2500)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Rp ${AppState.formatCurrency(doc['price'] + 2500)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 30-minute consultation info banner
                    RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.indigo.shade50],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Icon(Icons.timer_outlined, color: Color(0xFF2563EB), size: 24)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Durasi Konsultasi: 30 Menit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E40AF))),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sesi dimulai saat pesan pertama dikirim. Timer akan berjalan otomatis.',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    RepaintBoundary(
                      child: Column(
                        children: [
                          _buildPaymentOption('gopay', 'GoPay', 'eWallet', Icons.account_balance_wallet, Colors.green),
                          _buildPaymentOption('ovo', 'OVO', 'eWallet', Icons.account_balance_wallet, Colors.purple),
                          _buildPaymentOption('bca', 'BCA Virtual Account', 'Bank Transfer', Icons.account_balance, Colors.blue),
                          _buildPaymentOption('mandiri', 'Mandiri Virtual Account', 'Bank Transfer', Icons.account_balance, Colors.yellow.shade700),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Pay Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: isProcessing ? null : () => _processPayment(doc),
                  child: isProcessing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Bayar Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String id, String name, String category, IconData icon, Color iconColor) {
    bool isSelected = selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(category, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: 2),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String imageStr, {double size = 40}) {
    if (imageStr.startsWith('base64:')) {
      try {
        final bytes = base64Decode(imageStr.substring(7));
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: size * 2,
            height: size * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size)),
          ),
        );
      } catch (e) {
        return Text('👨‍⚕️', style: TextStyle(fontSize: size));
      }
    }
    return Text(imageStr, style: TextStyle(fontSize: size));
  }
}
