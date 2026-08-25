import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class ParentalPinScreen extends StatefulWidget {
  final bool isSetup;
  final String? currentPin;

  const ParentalPinScreen({
    super.key,
    this.isSetup = false,
    this.currentPin,
  });

  @override
  State<ParentalPinScreen> createState() => _ParentalPinScreenState();
}

class _ParentalPinScreenState extends State<ParentalPinScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPin = ''; // Used in setup mode for confirmation step
  bool _isConfirmStep = false;
  String? _errorMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (key == 'clear') {
      setState(() {
        _enteredPin = '';
        _errorMessage = null;
      });
      return;
    }

    if (key == 'backspace') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _errorMessage = null;
        });
      }
      return;
    }

    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += key;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _handlePinComplete();
    }
  }

  void _handlePinComplete() {
    if (widget.isSetup) {
      _handleSetupMode();
    } else {
      _handleVerifyMode();
    }
  }

  void _handleSetupMode() {
    if (!_isConfirmStep) {
      // First entry — save and ask to confirm
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirmStep = true;
      });
    } else {
      // Confirm entry
      if (_enteredPin == _firstPin) {
        Navigator.pop(context, _enteredPin);
      } else {
        _triggerError('PIN tidak cocok, ulangi dari awal');
        setState(() {
          _isConfirmStep = false;
          _firstPin = '';
        });
      }
    }
  }

  void _handleVerifyMode() {
    if (widget.currentPin != null && _enteredPin == widget.currentPin) {
      Navigator.pop(context, true);
    } else {
      _triggerError('PIN salah, coba lagi');
    }
  }

  void _triggerError(String message) {
    setState(() {
      _errorMessage = message;
      _enteredPin = '';
    });
    _shakeController.reset();
    _shakeController.forward();
  }

  String get _title {
    if (widget.isSetup) {
      return _isConfirmStep ? 'Konfirmasi PIN' : 'Buat PIN Baru';
    }
    return 'Mode Orang Tua';
  }

  String get _subtitle {
    if (widget.isSetup) {
      return _isConfirmStep
          ? 'Masukkan PIN sekali lagi untuk konfirmasi'
          : 'Buat PIN 4 digit untuk keamanan';
    }
    return 'Masukkan PIN 4 digit untuk mengakses';
  }


  void _showForgotPinDialog() {
    // Generate random adult math question
    final num1 = 12 + (DateTime.now().second % 15);
    final num2 = 6 + (DateTime.now().millisecond % 8);
    final correctAnswer = num1 * num2;
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('Verifikasi Orang Tua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Untuk mereset PIN, selesaikan perhitungan pengaman orang tua berikut:',
              style: TextStyle(fontSize: 13, color: AppTheme.gray600),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$num1 × $num2 = ?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryBlueDark),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: answerController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ketik jawaban...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (int.tryParse(answerController.text.trim()) == correctAnswer) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verifikasi orang tua berhasil! PIN telah direset. Silakan buat PIN baru. ✅'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                // Return 'RESET' token to clear PIN in AppState
                Navigator.pop(context, 'RESET');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jawaban salah. Akses ditolak.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Verifikasi & Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Lock icon
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueLight,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.lock,
                          size: 48,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Nunito',
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // PIN dots with shake animation
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          final double offset =
                              math.sin(_shakeAnimation.value * math.pi * 4) * 12;
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) => _buildPinDot(index)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Error message
                      SizedBox(
                        height: 24,
                        child: _errorMessage != null
                            ? Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.red500,
                                ),
                              )
                            : null,
                      ),

                      const Spacer(),

                      // Number keypad
                      _buildKeypad(),

                      const SizedBox(height: 16),

                      // Forgot PIN link
                      if (!widget.isSetup)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: TextButton(
                            onPressed: _showForgotPinDialog,
                            child: const Text(
                              'Lupa PIN?',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinDot(int index) {
    final bool isFilled = index < _enteredPin.length;
    final bool hasError = _errorMessage != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? (hasError ? AppTheme.red500 : AppTheme.primaryBlue)
            : Colors.transparent,
        border: Border.all(
          color: hasError
              ? AppTheme.red500
              : (isFilled ? AppTheme.primaryBlue : AppTheme.gray300),
          width: 2.5,
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final List<List<String>> keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['clear', '0', 'backspace'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) => _buildKey(key)).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final bool isSpecial = key == 'clear' || key == 'backspace';

    Widget child;
    if (key == 'backspace') {
      child = const Icon(Icons.backspace_outlined,
          size: 24, color: AppTheme.textPrimary);
    } else if (key == 'clear') {
      child = const Text(
        'C',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      );
    } else {
      child = Text(
        key,
        style: const TextStyle(
          fontSize: 28,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      );
    }

    return SizedBox(
      width: 72,
      height: 64,
      child: Material(
        color: isSpecial ? Colors.transparent : AppTheme.gray50,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _onKeyTap(key),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
          child: Center(child: child),
        ),
      ),
    );
  }
}
