import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi semua bidang yang diperlukan'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi tidak cocok'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      final success = await authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final uid = authService.currentUid;
        if (uid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil tapi sesi tidak tersedia. Silakan login manual.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context); // Go back to login
          return;
        }

        final appState = Provider.of<AppState>(context, listen: false);
        // Set the child's name BEFORE setLoggedIn to avoid race condition
        // where _loadUserData might overwrite it with empty profile
        appState.setChildName(_nameController.text.trim());
        await appState.setLoggedIn(true, uid: uid);
        
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/survey');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran gagal. Email mungkin sudah digunakan atau password terlalu lemah.'),
            backgroundColor: Colors.red,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                   Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/anak_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('🧠', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daftar Akun Zikola',
                    style: AppTheme.heading2.copyWith(color: AppTheme.gray900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mari pantau tumbuh kembang si kecil bersama',
                    style: AppTheme.bodyText.copyWith(color: AppTheme.gray500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Form Fields
              CustomTextField(
                controller: _nameController,
                hintText: 'Nama Lengkap Orang Tua',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                hintText: 'Email atau nomor ponsel',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _passwordController,
                hintText: 'Buat password',
                isPassword: true,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Konfirmasi password',
                isPassword: true,
              ),
              const SizedBox(height: 40),

              // Register Button
              CustomButton(
                text: 'Daftar',
                onPressed: _handleRegister,
                isLoading: _isLoading,
                variant: CustomButtonVariant.primary,
              ),
              const SizedBox(height: 32),

              // Login Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ',
                      style: AppTheme.bodyText.copyWith(color: AppTheme.gray600)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Masuk',
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.orange500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
