import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  late AnimationController _logoController;
  late Animation<double> _logoBounce;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoBounce = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutSine),
    );
  }




  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon masukkan email dan password Anda'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      final success = await authService.login(_emailController.text.trim(), _passwordController.text);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final uid = authService.currentUid;
        if (uid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login berhasil tapi sesi tidak tersedia. Coba lagi.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final appState = Provider.of<AppState>(context, listen: false);
        await appState.setLoggedIn(true, uid: uid);
        
        if (!mounted) return;
        if (appState.needsSurvey) {
          Navigator.pushReplacementNamed(context, '/survey');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau password salah. Silakan coba lagi.'),
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

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      final success = await authService.signInWithGoogle();
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final uid = authService.currentUid;
        if (uid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Google berhasil tapi sesi tidak tersedia. Coba lagi.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final appState = Provider.of<AppState>(context, listen: false);
        await appState.setLoggedIn(true, uid: uid);
        
        if (!mounted) return;
        if (appState.needsSurvey) {
          Navigator.pushReplacementNamed(context, '/survey');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.lastGoogleError ?? 'Login Google dibatalkan atau gagal. Silakan coba lagi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Google login error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 96,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Animated Fallback Logo matching React version
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _logoBounce.value),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 176, // 44 * 4
                        height: 176,
                        margin: const EdgeInsets.symmetric(horizontal: 64),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              'assets/images/anak_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🧠', style: TextStyle(fontSize: 56)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Zikola',
                                    style: AppTheme.heading1.copyWith(
                                      color: AppTheme.red500,
                                      fontSize: 32,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 64),

                    // Login Form Fields
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email atau nomor ponsel',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Masukkan password',
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                activeColor: AppTheme.orange500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(color: AppTheme.gray200, width: 2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Ingat saya', style: AppTheme.bodyText.copyWith(color: AppTheme.gray700)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Lupa password?',
                            style: AppTheme.bodyText.copyWith(color: AppTheme.blue500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    CustomButton(
                      text: 'Masuk',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      variant: CustomButtonVariant.primary,
                    ),
                    
                    const SizedBox(height: 16),

                    // Google Login Button
                    CustomButton(
                      text: 'Atau masuk google',
                      onPressed: _handleGoogleLogin,
                      isLoading: _isLoading,
                      variant: CustomButtonVariant.google,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Center(child: Text('G', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Additional Options (Sign Up)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Belum punya akun? ', style: AppTheme.bodyText.copyWith(color: AppTheme.gray600)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Daftar sekarang',
                            style: AppTheme.bodyText.copyWith(
                              color: AppTheme.orange500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

