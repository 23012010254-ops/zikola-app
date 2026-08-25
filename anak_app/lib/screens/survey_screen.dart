import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
// Note: In a real app we would use Provider/AppState here.
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  String _childGender = '';
  int _childAge = 0;
  Map<String, List<String>> _tempAnswers = {};
  
  String? _avatarBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _surveySteps = [
    {
      'id': 'gender-name',
      'title': 'Apa gender dan siapa nama anak anda?',
      'type': 'gender-name'
    },
    {
      'id': 'age',
      'title': 'Berapa umur anak Anda?',
      'type': 'age-selection'
    },
    {
      'id': 'personality',
      'title': 'Capaian apa yang Anda inginkan terhadap anak Anda?',
      'type': 'multiple-choice',
      'options': [
        'Kemampuan akademik yang baik',
        'Keterampilan sosial dan emosional',
        'Kreativitas dan inovasi',
        'Kepercayaan diri tinggi',
        'Kemampuan problem solving',
        'Komunikasi yang efektif',
        'Kemandirian dalam belajar',
        'Lainnya'
      ]
    },
    {
      'id': 'activities',
      'title': 'Siapa yang sering menggunakan perangkat anak?',
      'type': 'multiple-choice',
      'options': [
        'Anak sendiri',
        'Orang tua',
        'Menggunakan bersama',
        'Pengasuh',
        'Saudara',
        'Lainnya'
      ]
    },
    {
      'id': 'interests1',
      'title': 'Apa harapan Anda kepada anak Anda?',
      'type': 'multiple-choice',
      'options': [
        'Tumbuh menjadi anak yang bahagia',
        'Memiliki kepercayaan diri yang tinggi',
        'Berhasil secara akademik',
        'Memiliki banyak teman dan mudah bergaul',
        'Kreatif dan inovatif dalam berpikir',
        'Mandiri dan bertanggung jawab',
        'Sehat fisik dan mental',
        'Memiliki karakter yang baik'
      ]
    },
    {
      'id': 'interests2',
      'title': 'Kegiatan apa yang paling disukai anak Anda?',
      'type': 'multiple-choice',
      'options': [
        'Menyanyi dan bercerita',
        'Mencari tahu hal baru',
        'Mendengarkan cerita',
        'Bermain dengan teman',
        'Menggambar dan mewarnai',
        'Bermain dengan mainan',
        'Belajar hal baru',
        'Lainnya'
      ]
    },
    {
      'id': 'learning-difficulty',
      'title': 'Apakah Anak Mengalami Kesulitan Dalam Belajar?',
      'type': 'multiple-choice',
      'options': [
        'Tidak ada kesulitan khusus',
        'Kesulitan konsentrasi',
        'Kesulitan memahami instruksi',
        'Kesulitan mengingat informasi',
        'Kesulitan dengan angka/matematika',
        'Kesulitan dengan huruf/membaca',
        'Kesulitan dengan motorik halus',
        'Lainnya'
      ]
    },
    {
      'id': 'learning-method',
      'title': 'Bagaimana metode belajar terbaik untuk anak Anda?',
      'type': 'multiple-choice',
      'options': [
        'Belajar sambil bermain',
        'Menggunakan gambar dan visual',
        'Mendengarkan musik dan lagu',
        'Praktek langsung dengan tangan',
        'Bercerita dan diskusi',
        'Menggunakan teknologi digital',
        'Lainnya'
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().setSurveyInProgress(true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep < _surveySteps.length - 1) {
      setState(() => _currentStep++);
    } else if (!_isSaving) {
      _saveAndNavigate();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveAndNavigate() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final appState = context.read<AppState>();
      
      // Step 1: Set profile fields (awaiting them individually for safety)
      await appState.setChildName(_nameController.text);
      await appState.setChildGender(_childGender);
      await appState.setChildAge(_childAge);
      
      if (_avatarBase64 != null) {
        appState.updateProfile({'avatarBase64': _avatarBase64});
      }
      
      // Step 2: Save survey detailed answers
      appState.updateSurveyData({
        'personality': _tempAnswers['personality'] ?? [],
        'activities': _tempAnswers['activities'] ?? [],
        'interests': [
          ...(_tempAnswers['interests1'] ?? []),
          ...(_tempAnswers['interests2'] ?? []),
        ],
        'learningStyle': _tempAnswers['learning-method'] ?? [],
        'hobbies': _tempAnswers['learning-difficulty'] ?? [],
      });
      
      // Step 3: Compute and save identity string
      await appState.saveIdentityAfterSurvey();
      
      // Optional: identity check
      await appState.checkForDuplicateIdentity();
      
      debugPrint('Survey complete. Identity: ${appState.childProfile.toIdentityString()}');
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'Selamat Datang di Zikola!',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.gray900,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Halo ${_nameController.text}! Profilmu berhasil dibuat. Ayo kita mulai petualangan belajar yang seru!',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.gray500,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Mulai Petualangan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving survey: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e'))
        );
        setState(() => _isSaving = false);
      }
    }
  }
  
  Future<void> _handleLogout() async {
    try {
      final authService = AuthService();
      await authService.logout();
      if (mounted) {
        context.read<AppState>().logout();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  void _handleMultipleAnswer(String questionId, String option) {
    if (_isSaving) return;
    setState(() {
      // Use toList() to create a NEW list instance, ensuring reliable UI updates
      List<String> currentAnswers = List<String>.from(_tempAnswers[questionId] ?? []);
      if (currentAnswers.contains(option)) {
        currentAnswers.remove(option);
      } else {
        currentAnswers.add(option);
      }
      _tempAnswers[questionId] = currentAnswers;
    });
  }

  bool _canProceed() {
    final step = _surveySteps[_currentStep];
    switch (step['id']) {
      case 'gender-name':
        return _nameController.text.trim().isNotEmpty && _childGender.isNotEmpty;
      case 'age':
        return _childAge >= 3;
      default:
        final answers = _tempAnswers[step['id'] as String] ?? [];
        return answers.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepData = _surveySteps[_currentStep];
    final progress = (_currentStep + 1) / _surveySteps.length;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentStep > 0
                          ? GestureDetector(
                              onTap: _handleBack,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.gray100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back, color: AppTheme.gray600),
                              ),
                            )
                          : const SizedBox(width: 40),
                      Text(
                        '${_currentStep + 1} dari ${_surveySteps.length}',
                        style: AppTheme.bodyText.copyWith(color: AppTheme.gray500),
                      ),
                      _currentStep == 0
                          ? GestureDetector(
                              onTap: _handleLogout,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.red500.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.logout, color: AppTheme.red500, size: 20),
                              ),
                            )
                          : const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.gray200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.orange500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepData['title'] as String,
                      style: AppTheme.heading2.copyWith(color: AppTheme.gray900, height: 1.2),
                    ),
                    const SizedBox(height: 32),
                    _buildStepContent(stepData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.gray100)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: _currentStep == _surveySteps.length - 1 ? 'Selesai' : 'Next',
              onPressed: _canProceed() && !_isSaving ? _handleNext : null,
              isLoading: _isSaving,
              icon: _currentStep == _surveySteps.length - 1 ? null : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(Map<String, dynamic> stepData) {
    if (stepData['type'] == 'gender-name') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  shape: BoxShape.circle,
                  image: _avatarBase64 != null 
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(_avatarBase64!)), 
                        fit: BoxFit.cover
                      )
                    : null,
                ),
                child: _avatarBase64 == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 30, color: AppTheme.gray400),
                        SizedBox(height: 4),
                        Text('Foto', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                      ],
                    )
                  : null,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard('male', '👦', 'Laki-laki'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard('female', '👧', 'Perempuan'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Nama Anak',
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600, color: AppTheme.gray700),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _nameController,
            hintText: 'Masukkan nama anak...',
            onChanged: (value) => setState(() {}),
          ),
        ],
      );
    }

    if (stepData['type'] == 'age-selection') {
      final ages = [
        {'label': '3-4 Tahun', 'value': 3},
        {'label': '4-5 Tahun', 'value': 4},
        {'label': '5-6 Tahun', 'value': 5},
        {'label': '6-7 Tahun', 'value': 6},
        {'label': '7-8 Tahun', 'value': 7},
        {'label': '8-9 Tahun', 'value': 8},
        {'label': '9-10 Tahun', 'value': 9},
        {'label': '11-12 Tahun', 'value': 11},
      ];

      return Wrap(
        spacing: 12,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: ages.map((age) {
          final isSelected = _childAge == age['value'];
          return GestureDetector(
            onTap: () => setState(() => _childAge = age['value'] as int),
            child: Container(
              width: (MediaQuery.of(context).size.width - 60) / 2,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.orange50.withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.orange500 : AppTheme.gray200,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  age['label'] as String,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppTheme.orange600 : AppTheme.gray700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (stepData['type'] == 'multiple-choice') {
      final options = stepData['options'] as List<String>;
      final questionId = stepData['id'] as String;
      return Column(
        children: options.map((option) {
          final isSelected = (_tempAnswers[questionId] ?? []).contains(option);
          return GestureDetector(
            onTap: () => _handleMultipleAnswer(questionId, option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.orange50.withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.orange500 : AppTheme.gray200,
                  width: 2,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppTheme.gray900,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.orange500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox();
  }

  Widget _buildGenderCard(String value, String emoji, String label) {
    final isSelected = _childGender == value;
    return GestureDetector(
      onTap: () => setState(() => _childGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.orange50.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.orange500 : AppTheme.gray200,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Add orange50 to AppTheme if missing
extension AppThemeExt on AppTheme {
  static const Color orange50 = Color(0xFFfff7ed);
}
