import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSent = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'Email tidak terdaftar. Periksa kembali email Anda.';
            break;
          case 'invalid-email':
            message = 'Format email tidak valid.';
            break;
          default:
            message = 'Gagal mengirim email reset: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gray700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFEFF6FF), // blue-50
                  child: Icon(Icons.lock_reset, size: 48, color: AppTheme.blue500),
                ),
              ),
              const SizedBox(height: 32),

              // Titles
              Text(
                _isSent ? 'Tautan Terkirim!' : 'Lupa Password?',
                style: AppTheme.heading1.copyWith(color: AppTheme.gray900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _isSent
                    ? 'Kami telah mengirimkan instruksi pemulihan ke email Anda. Silakan periksa kotak masuk atau spam.'
                    : 'Jangan khawatir! Masukkan email Anda yang terdaftar, kami akan mengirimkan tautan untuk mereset password Anda.',
                style: AppTheme.bodyText.copyWith(color: AppTheme.gray600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Form
              if (!_isSent) ...[
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Masukkan email Anda',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Kirim Tautan Reset',
                  onPressed: _handleSendLink,
                  isLoading: _isLoading,
                  variant: CustomButtonVariant.primary,
                ),
              ] else ...[
                CustomButton(
                  text: 'Kembali ke Halaman Masuk',
                  onPressed: () => Navigator.pop(context),
                  variant: CustomButtonVariant.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
