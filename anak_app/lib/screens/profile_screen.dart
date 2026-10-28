import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/custom_bottom_nav.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../models/sticker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _showCustomization = false;
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarOptions = [
    'assets/images/stickers/hai.png',
    'assets/images/stickers/keren.png',
    'assets/images/stickers/hebat.png',
    'assets/images/stickers/love_it.png',
    '👦', '👧', '🐱', '🐼', '🦄'
  ];

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'blue', 'color': const Color(0xFF3B82F6), 'label': 'Biru'},
    {'name': 'green', 'color': const Color(0xFF10B981), 'label': 'Hijau'},
    {'name': 'purple', 'color': const Color(0xFF8B5CF6), 'label': 'Ungu'},
    {'name': 'pink', 'color': const Color(0xFFEC4899), 'label': 'Pink'},
    {'name': 'orange', 'color': const Color(0xFFF97316), 'label': 'Oranye'},
    {'name': 'yellow', 'color': const Color(0xFFF59E0B), 'label': 'Kuning'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _handleNameSave(BuildContext context) {
    if (_nameController.text.trim().isNotEmpty) {
      context.read<AppState>().setChildName(_nameController.text.trim());
    }
    setState(() => _isEditing = false);
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (context.mounted) {
          context.read<AppState>().updateProfile({'avatarBase64': base64Encode(bytes)});
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _handleAvatarChange(BuildContext context, String avatar) {
    context.read<AppState>().updateProfile({'avatar': avatar});
  }

  void _handleColorChange(BuildContext context, Map<String, dynamic> colorData) {
    String hex = '#${colorData['color'].value.toRadixString(16).substring(2).toUpperCase()}';
    context.read<AppState>().updateProfile({
      'favoriteColor': colorData['name'],
      'backgroundColor': hex,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustomization) {
      return _buildCustomizationView(context);
    }
    return _buildMainProfileView(context);
  }

  Widget _buildCustomizationView(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.childProfile;
    final bgColor = _parseColor(profile.backgroundColor);
    final favColorLabel = _colorOptions.firstWhere((c) => c['name'] == profile.favoriteColor, orElse: () => _colorOptions[0])['label'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 20),
          ),
          onPressed: () => setState(() => _showCustomization = false),
        ),
        title: Text('Kustomisasi Profil', style: AppTheme.heading2.copyWith(color: const Color(0xFF1E293B), fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Section - Premium Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                      image: profile.avatarBase64 != null 
                        ? DecorationImage(image: MemoryImage(base64Decode(profile.avatarBase64!)), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: profile.avatarBase64 == null 
                      ? Center(
                          child: profile.avatar.startsWith('assets/')
                            ? Image.asset(profile.avatar, width: 80, height: 80)
                            : Text(profile.avatar, style: const TextStyle(fontSize: 56))
                        )
                      : null,
                  ),
                  const SizedBox(height: 20),
                  Text(profile.name, style: AppTheme.heading1.copyWith(fontSize: 24, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#Warna$favColorLabel',
                      style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Gamified Kid Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatPill(
                        label: 'XP Belajar',
                        value: '${appState.totalXP}',
                        icon: '⭐',
                        bgColor: const Color(0xFFEFF6FF),
                        borderColor: const Color(0xFFBFDBFE),
                        textColor: const Color(0xFF1D4ED8),
                      ),
                      _buildStatPill(
                        label: 'Hari Seri',
                        value: '${appState.currentStreak}',
                        icon: '🔥',
                        bgColor: const Color(0xFFFFFBEB),
                        borderColor: const Color(0xFFFDE68A),
                        textColor: const Color(0xFFB45309),
                      ),
                      _buildStatPill(
                        label: 'Level Anak',
                        value: 'Lvl ${appState.currentLevel}',
                        icon: '🌟',
                        bgColor: const Color(0xFFFAF5FF),
                        borderColor: const Color(0xFFE9D5FF),
                        textColor: const Color(0xFF7E22CE),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(context),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text("Ganti Foto Profil"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Avatar Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pilih Avatar', style: AppTheme.heading3.copyWith(fontSize: 16)),
                      Text('${_avatarOptions.length} Opsi', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatarOptions.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatarOptions[index];
                        final isSelected = profile.avatar == avatar;
                        return GestureDetector(
                          onTap: () => _handleAvatarChange(context, avatar),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? bgColor.withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? bgColor : const Color(0xFFF1F5F9),
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: bgColor.withValues(alpha: 0.2), blurRadius: 8)] : [],
                            ),
                            child: Center(
                              child: avatar.startsWith('assets/') 
                                  ? Image.asset(avatar, width: 40, height: 40)
                                  : Text(avatar, style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Color Selection
                  Text('Tema Warna', style: AppTheme.heading3.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final colorItem = _colorOptions[index];
                      final isSelected = profile.favoriteColor == colorItem['name'];
                      final color = colorItem['color'] as Color;
                      return GestureDetector(
                        onTap: () => _handleColorChange(context, colorItem),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? color : const Color(0xFFF1F5F9),
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                colorItem['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? color : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 48),

                  // Save Button Area
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showCustomization = false);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Image.asset('assets/images/stickers/terimakasih.png', width: 40, height: 40),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('Profil berhasil diperbarui!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainProfileView(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.childProfile;
    final mbti = appState.mbtiResult;

    if (_isEditing && _nameController.text != profile.name) {
      // Just make sure controller is in sync if opened
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Header Gradient Backing
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 72),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profil Anak 🧒',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showCustomization = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.palette_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Ubah Tema',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Card
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Avatar & Edit Name
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFBFDBFE), width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                        image: profile.avatarBase64 != null
                                            ? DecorationImage(
                                                image: MemoryImage(base64Decode(profile.avatarBase64!)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: profile.avatarBase64 == null
                                          ? Center(
                                              child: profile.avatar.startsWith('assets/')
                                                  ? ClipOval(
                                                      child: Image.asset(
                                                        profile.avatar,
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Text(
                                                      profile.avatar.isNotEmpty ? profile.avatar : '👦',
                                                      style: const TextStyle(fontSize: 40),
                                                    ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _showCustomization = true),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF97316),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                if (_isEditing)
                                  Column(
                                    children: [
                                      TextField(
                                        controller: _nameController,
                                        textAlign: TextAlign.center,
                                        style: AppTheme.heading2.copyWith(color: AppTheme.gray900),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppTheme.gray50,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _handleNameSave(context),
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                            child: const Text('Simpan'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => setState(() => _isEditing = false),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gray200, foregroundColor: AppTheme.gray600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                            child: const Text('Batal'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _nameController.text = profile.name;
                                          setState(() => _isEditing = true);
                                        },
                                        child: Text(
                                          profile.name,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.3,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        appState.email ?? '${profile.name.toLowerCase()}@gmail.com',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      
                                      // Duolingo-style Stat Trio
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildStatPill(
                                            label: 'XP Belajar',
                                            value: '${appState.totalXP}',
                                            icon: '⭐',
                                            bgColor: const Color(0xFFEFF6FF),
                                            borderColor: const Color(0xFFBFDBFE),
                                            textColor: const Color(0xFF1D4ED8),
                                          ),
                                          _buildStatPill(
                                            label: 'Hari Seri',
                                            value: '${appState.currentStreak}',
                                            icon: '🔥',
                                            bgColor: const Color(0xFFFFFBEB),
                                            borderColor: const Color(0xFFFDE68A),
                                            textColor: const Color(0xFFB45309),
                                          ),
                                          _buildStatPill(
                                            label: 'Level Anak',
                                            value: 'Lvl ${appState.currentLevel}',
                                            icon: '🌟',
                                            bgColor: const Color(0xFFFAF5FF),
                                            borderColor: const Color(0xFFE9D5FF),
                                            textColor: const Color(0xFF7E22CE),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 22),

                                // Celengan Bintang & Poin (Golden Amber Card)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Center(child: Text('💰', style: TextStyle(fontSize: 26))),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Celengan Bintang & Poin',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              AppState.formatCurrency(appState.totalPoints),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.5,
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Text(
                                          'Tukar Hadiah 🎁',
                                          style: TextStyle(
                                            color: Color(0xFFB45309),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // 4-Slot Sticker Showcase
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Pameran Stiker 🏆', style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 15)),
                                          GestureDetector(
                                            onTap: () => Navigator.pushNamed(context, '/stickers'),
                                            child: Text('Koleksi Semua', style: TextStyle(color: AppTheme.blue600, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(4, (index) {
                                          const defaultShowcase = ['eternal-crown', 'celestial-galaxy-dragon', 'hot-streak', 'dragon-emperor'];
                                          final showcased = (profile.showcasedStickers.length > index && profile.showcasedStickers[index].isNotEmpty)
                                              ? profile.showcasedStickers[index]
                                              : (index < defaultShowcase.length ? defaultShowcase[index] : '');
                                          
                                          return ShiningStickerSlot(
                                            stickerId: showcased,
                                            index: index,
                                            onTap: () => _showStickerSelector(context, appState, index),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Pilih 4 stiker favoritmu untuk dipamerkan!',
                                        style: TextStyle(color: AppTheme.gray500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // MBTI Result Card - Enhanced (matching React update)
                                if (mbti != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFF97316)],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Background decorations
                                        Positioned(
                                          top: -32, right: -32,
                                          child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle)),
                                        ),
                                        Positioned(
                                          bottom: -24, left: -24,
                                          child: Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle)),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              // Header
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 40, height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Center(child: Text('🎭', style: TextStyle(fontSize: 20))),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Kepribadian MBTI', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 13)),
                                                      Text(mbti['type'] ?? 'Unknown', style: AppTheme.bodyText.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // Main Content Card
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // Animal emoji large
                                                        Container(
                                                          width: 72, height: 72,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                                                          ),
                                                          child: Center(child: Text(mbti['animalEmoji'] ?? appState.testResults.personality.animalEmoji ?? '🦁', style: const TextStyle(fontSize: 40))),
                                                        ),
                                                        const SizedBox(width: 14),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(mbti['animal'] ?? appState.testResults.personality.animal ?? '', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 16)),
                                                              const SizedBox(height: 4),
                                                              Text(mbti['personality'] ?? '', style: AppTheme.bodyText.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                                                              const SizedBox(height: 8),
                                                              // Trait badges
                                                              Wrap(
                                                                spacing: 6,
                                                                runSpacing: 6,
                                                                children: (mbti['traits'] is List
                                                                    ? (mbti['traits'] as List).take(3).map((t) => t.toString()).toList()
                                                                    : mbti['traits'] is String
                                                                        ? (mbti['traits'] as String).split(',').take(3).toList()
                                                                        : <String>[])
                                                                    .map((trait) => Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.white.withValues(alpha: 0.2),
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                                                          ),
                                                                          child: Text(trait.toString().trim(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                                                                        ))
                                                                    .toList(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Aspect Scores (if personality test completed)
                                                    if (appState.testResults.personality.completed) ...[
                                                      const SizedBox(height: 16),
                                                      Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                                                      const SizedBox(height: 16),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          _buildAspectScore('👥', 'Sosial', _getPersonalityScore(appState, 'socialScore')),
                                                          _buildAspectScore('❤️', 'Emosional', _getPersonalityScore(appState, 'emotionalScore')),
                                                          _buildAspectScore('⭐', 'Karakter', _getPersonalityScore(appState, 'characterScore')),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 14),

                                              // Call to Action
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () => Navigator.pushNamed(context, '/personality-test', arguments: {'showResult': true}),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    foregroundColor: const Color(0xFF9333EA),
                                                    elevation: 4,
                                                    shadowColor: Colors.black.withValues(alpha: 0.2),
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Text('📊', style: TextStyle(fontSize: 16)),
                                                      const SizedBox(width: 8),
                                                      Text('Lihat Analisis Lengkap', style: AppTheme.heading3.copyWith(color: const Color(0xFF9333EA), fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Customization Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => setState(() => _showCustomization = true),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]), // purple-500 to pink-500
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 4))],
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 56,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.palette, color: Colors.white, size: 20),
                                            SizedBox(width: 12),
                                            Text('Kustomisasi Profil', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Menu Items
                          _buildMenuItem(
                            context,
                            icon: Icons.supervised_user_circle_rounded,
                            iconBg: appState.isParentMode ? const Color(0xFFCCFBF1) : const Color(0xFFF0FDFA),
                            iconColor: const Color(0xFF0F766E),
                            title: appState.isParentMode ? 'Mode Orang Tua (Sedang Aktif 🛡️)' : 'Mode Orang Tua 👨‍👩‍👧',
                            subtitle: appState.isParentMode ? 'Klik untuk kembali ke Mode Anak' : 'Akses laporan, rekam medis & kontrol layar',
                            onTap: () async {
                              if (appState.isParentMode) {
                                appState.setParentMode(false);
                              } else {
                                final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
                                final dynamic result = await Navigator.pushNamed(
                                  context, 
                                  '/parental-pin', 
                                  arguments: {
                                    'isSetup': !hasPin,
                                    'currentPin': appState.parentalPin,
                                  }
                                );
                                
                                if (result == true || (result is String && result.length == 4)) {
                                  if (result is String && result.length == 4) {
                                    await appState.setParentalPin(result);
                                  }
                                  appState.setParentMode(true);
                                  await AudioService().playClick();
                                }
                              }
                            },
                            borderColor: appState.isParentMode ? const Color(0xFF0D9488) : Colors.transparent,
                          ),
                          const SizedBox(height: 12),

                          _buildMenuItem(
                            context,
                            icon: AudioService().isMuted ? Icons.volume_off : Icons.volume_up,
                            iconBg: const Color(0xFFDBEAFE), // blue-100
                            iconColor: const Color(0xFF2563EB), // blue-600
                            title: AudioService().isMuted ? 'Suara (Mati)' : 'Suara (Aktif)',
                            subtitle: AudioService().isMuted ? 'Klik untuk aktifkan suara' : 'Klik untuk matikan suara',
                            onTap: () async {
                              await AudioService().toggleMute();
                              (context as Element).markNeedsBuild();
                            },
                            borderColor: AudioService().isMuted ? const Color(0xFF2563EB) : Colors.transparent,
                          ),
                          const SizedBox(height: 12),


                          if (appState.isParentMode) ...[
                            _buildMenuItem(
                              context,
                              icon: Icons.pin_outlined,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFD97706),
                              title: 'Ganti / Reset PIN Orang Tua 🔐',
                              subtitle: 'Ubah kode PIN 4 digit keamanan orang tua',
                              onTap: () async {
                                final dynamic result = await Navigator.pushNamed(
                                  context,
                                  '/parental-pin',
                                  arguments: {
                                    'isSetup': true,
                                    'currentPin': appState.parentalPin,
                                  },
                                );
                                if (result is String && result.length == 4) {
                                  await appState.setParentalPin(result);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN orang tua berhasil diperbarui! 🔐'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            _buildMenuItem(
                              context,
                              icon: Icons.timer_outlined,
                              iconBg: const Color(0xFFFCE7F3), // pink-100
                              iconColor: const Color(0xFFDB2777), // pink-600
                              title: 'Batas Waktu Layar ⏱️',
                              subtitle: 'Atur batas waktu bermain harian anak',
                              onTap: () => Navigator.pushNamed(context, '/screen-time-settings'),
                            ),
                            const SizedBox(height: 12),

                            _buildMenuItem(
                              context,
                              icon: Icons.child_care_rounded,
                              iconBg: const Color(0xFFE0F2FE), // blue-50
                              iconColor: const Color(0xFF0284C7), // blue-600
                              title: 'Kelola Anak 👨‍👩‍👧',
                              subtitle: 'Tambah atau beralih profil anak',
                              onTap: () => Navigator.pushNamed(context, '/child-selector'),
                            ),
                            const SizedBox(height: 12),

                            _buildMenuItem(
                              context,
                              iconText: '⚙️',
                              iconBg: const Color(0xFFDCFCE7), // green-100
                              title: 'Panduan Orang Tua',
                              subtitle: 'Tips dan panduan tumbuh kembang',
                              onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Portal Dokter Zikola (verified doctors only)
                          if (appState.isDoctor) ...[
                            _buildMenuItem(
                              context,
                              icon: Icons.local_hospital_rounded,
                              iconBg: const Color(0xFFF3E8FF), // purple-100
                              iconColor: const Color(0xFF7C3AED), // purple-600
                              title: 'Portal Dokter Zikola 🩺',
                              subtitle: 'Dashboard dokter, kelola pasien & rekam medis',
                              onTap: () => Navigator.pushNamed(context, '/doctor-portal'),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Reset Data Button
                          _buildMenuItem(
                            context,
                            icon: Icons.restart_alt,
                            iconBg: const Color(0xFFFEF3C7), // amber-100
                            iconColor: const Color(0xFFD97706), // amber-600
                            title: 'Reset Data',
                            subtitle: 'Hapus semua data & mulai ulang survey',
                            onTap: () => _showResetConfirmation(context),
                          ),
                          const SizedBox(height: 12),

                          // Kebijakan Privasi (Google Play Compliance)
                          _buildMenuItem(
                            context,
                            icon: Icons.privacy_tip_outlined,
                            iconBg: const Color(0xFFEFF6FF), // blue-50
                            iconColor: const Color(0xFF2563EB), // blue-600
                            title: 'Kebijakan Privasi 🛡️',
                            subtitle: 'Ketentuan privasi & perlindungan data anak',
                            onTap: () async {
                              final Uri url = Uri.parse('https://anak-app.web.app/privacy');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kunjungi https://anak-app.web.app/privacy')),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Hapus Akun & Data (Google Play Policy Mandate)
                          _buildMenuItem(
                            context,
                            icon: Icons.delete_forever_rounded,
                            iconBg: const Color(0xFFFFF1F2), // rose-50
                            iconColor: const Color(0xFFE11D48), // rose-600
                            title: 'Hapus Akun & Data 🗑️',
                            subtitle: 'Hapus akun dan seluruh data secara permanen',
                            onTap: () => _showDeleteAccountConfirmation(context),
                          ),
                          const SizedBox(height: 12),

                          _buildMenuItem(
                            context,
                            icon: Icons.logout,
                            iconBg: const Color(0xFFFEE2E2), // red-100
                            iconColor: const Color(0xFFDC2626), // red-600
                            title: 'Keluar',
                            subtitle: 'Logout dari aplikasi',
                            onTap: () async {
                              await AuthService().logout();
                              if (context.mounted) {
                                Provider.of<AppState>(context, listen: false).logout();
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }
                            },
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required String icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.8),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    IconData? icon,
    String? iconText,
    required Color iconBg,
    Color? iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color borderColor = Colors.transparent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor == Colors.transparent ? const Color(0xFFF1F5F9) : borderColor,
            width: borderColor == Colors.transparent ? 1.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: iconColor, size: 24)
                    : Text(iconText!, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: borderColor != Colors.transparent ? iconColor ?? const Color(0xFF64748B) : const Color(0xFF64748B),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }





  Widget _buildAspectScore(String emoji, String label, String score) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(height: 6),
        Text(score, style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }

  String _getPersonalityScore(AppState appState, String key) {
    final personality = appState.testResults.personality;
    if (!personality.completed || personality.type == null) return '-';
    switch (key) {
      case 'socialScore':
        return personality.socialScore != null ? '${personality.socialScore}%' : '-';
      case 'emotionalScore':
        return personality.emotionalScore != null ? '${personality.emotionalScore}%' : '-';
      case 'characterScore':
        return personality.characterScore != null ? '${personality.characterScore}%' : '-';
      default:
        return '-';
    }
  }


  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Reset Semua Data?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Semua data profil, hasil tes, game, stiker, dan poin akan dihapus permanen. '
          'Anda akan diarahkan ke survey ulang.\n\n'
          'Akun login Anda tetap aman dan tidak dihapus.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.resetAllData();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/survey', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );
  }

  void _showStickerSelector(BuildContext context, AppState appState, int slotIndex) {
    // Include top premium stickers in selector so user can always showcase celestial & mythical
    final allCollected = Set<String>.from(appState.collectedStickers)
      ..addAll(['celestial-galaxy-dragon', 'divine-phoenix-emperor', 'eternal-crown', 'dragon-emperor', 'hot-streak', 'unicorn-magic']);
    final collectedList = allCollected.toList();

    // Group stickers by rarity
    final Map<String, List<String>> groupedStickers = {
      'semua': collectedList,
      'celestial': collectedList.where((id) => StickerDatabase.getSticker(id)?.rarity == 'celestial').toList(),
      'mythical': collectedList.where((id) => StickerDatabase.getSticker(id)?.rarity == 'mythical').toList(),
      'legendary': collectedList.where((id) => ['legend', 'legendary'].contains(StickerDatabase.getSticker(id)?.rarity)).toList(),
      'epic': collectedList.where((id) => StickerDatabase.getSticker(id)?.rarity == 'epic').toList(),
      'rare': collectedList.where((id) => StickerDatabase.getSticker(id)?.rarity == 'rare').toList(),
      'common': collectedList.where((id) => StickerDatabase.getSticker(id)?.rarity == 'common').toList(),
    };

    final List<Map<String, dynamic>> categories = [
      {'id': 'semua', 'label': 'Semua', 'icon': '✨', 'color': AppTheme.primaryBlue},
      {'id': 'celestial', 'label': 'Celestial', 'icon': '🌌', 'color': const Color(0xFF8B5CF6)},
      {'id': 'mythical', 'label': 'Mythical', 'icon': '🐉', 'color': const Color(0xFFEF4444)},
      {'id': 'legendary', 'label': 'Legend', 'icon': '👑', 'color': const Color(0xFFF59E0B)},
      {'id': 'epic', 'label': 'Epic', 'icon': '💎', 'color': const Color(0xFFA855F7)},
      {'id': 'rare', 'label': 'Rare', 'icon': '⭐', 'color': const Color(0xFF3B82F6)},
      {'id': 'common', 'label': 'Common', 'icon': '⚪', 'color': const Color(0xFF94A3B8)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: categories.length,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Koleksi Stiker', style: AppTheme.heading2.copyWith(fontSize: 22, fontWeight: FontWeight.w900)),
                          Text('Pilih stiker untuk dipamerkan', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context), 
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.gray100, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 20, color: AppTheme.gray600)
                      )
                    ),
                  ],
                ),
              ),

              // Tab Bar
              TabBar(
                isScrollable: true,
                indicatorColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                dividerColor: Colors.transparent,
                tabs: categories.map((cat) => Tab(
                  child: Builder(
                    builder: (context) {
                      final isSelected = DefaultTabController.of(context).index == categories.indexOf(cat);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cat['color'].withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cat['color'] : AppTheme.gray200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat['icon'], style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              cat['label'],
                              style: TextStyle(
                                color: isSelected ? cat['color'] : AppTheme.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                )).toList(),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: categories.map((cat) {
                    final stickers = groupedStickers[cat['id']]!;
                    
                    if (stickers.isEmpty && cat['id'] != 'semua') {
                      return _buildEmptyState(cat['label'], cat['icon'], cat['color']);
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: cat['id'] == 'semua' ? stickers.length + 1 : stickers.length,
                      itemBuilder: (context, index) {
                        // Empty Slot option only in "Semua" or at the end
                        if (cat['id'] == 'semua' && index == stickers.length) {
                          return _buildRemoveOption(slotIndex);
                        }
                        
                        final stickerId = stickers[index];
                        return _buildStickerSelectorCard(stickerId, slotIndex, appState);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String label, String icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada stiker $label',
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Teruslah bermain dan selesaikan tes untuk mendapatkan stiker $label!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveOption(int slotIndex) {
    return GestureDetector(
      onTap: () {
        context.read<AppState>().removeShowcasedSticker(slotIndex);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.gray200, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.red50, shape: BoxShape.circle),
              child: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.red500, size: 24),
            ),
            const SizedBox(height: 10),
            Text('Kosongkan', style: TextStyle(fontSize: 11, color: AppTheme.red600, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerSelectorCard(String stickerId, int slotIndex, AppState appState) {
    final info = StickerDatabase.getSticker(stickerId);
    if (info == null) return const SizedBox.shrink();
    
    final isSelected = appState.childProfile.showcasedStickers.contains(stickerId);
    final rarity = info.rarity;
    final isCelestial = rarity == 'celestial';
    final isMythical = rarity == 'mythical';
    final isSpecial = isCelestial || isMythical;
    final cardColor = _getRarityColor(rarity);

    return GestureDetector(
      onTap: () {
        AudioService().playSparkle();
        HapticFeedback.lightImpact();
        appState.setShowcasedSticker(slotIndex, stickerId);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isCelestial 
              ? const Color(0xFF0F172A)
              : (isMythical ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? cardColor : (isSpecial ? Colors.transparent : AppTheme.gray100),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            if (isSelected) 
              BoxShadow(color: cardColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
            if (isCelestial && !isSelected)
              BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1.5),
            if (isMythical && !isSelected)
              BoxShadow(color: cardColor.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: Stack(
          children: [
            if (isCelestial)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0x408B5CF6), Color(0x30EC4899), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              )
            else if (isMythical)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [cardColor.withValues(alpha: 0.2), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'sticker_sel_$stickerId',
                    child: Text(info.emoji, style: const TextStyle(fontSize: 38)),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      info.name, 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w900, 
                        color: isSpecial ? Colors.white : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCelestial
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                          : cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rarity.toUpperCase(), 
                      style: TextStyle(
                        fontSize: 7, 
                        fontWeight: FontWeight.w900, 
                        color: isCelestial ? const Color(0xFFA78BFA) : cardColor,
                        letterSpacing: 0.5,
                      )
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'celestial': return const Color(0xFF8B5CF6);
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }


  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hapus Akun & Data?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tindakan ini bersifat permanen.\n\nSeluruh data profil anak, stiker, riwayat rekam medis (EMR), dan hasil tes akan dihapus secara menyeluruh dari server Zikola sesuai kebijakan privasi Google Play.',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final appState = Provider.of<AppState>(context, listen: false);
              final success = await appState.deleteUserAccount();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Akun dan seluruh data Anda telah berhasil dihapus permanen. ✅'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                }
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Hapus Permanen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class ShiningStickerSlot extends StatefulWidget {
  final String stickerId;
  final int index;
  final VoidCallback onTap;
  final bool isLarge;

  const ShiningStickerSlot({
    super.key,
    required this.stickerId,
    required this.index,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  State<ShiningStickerSlot> createState() => _ShiningStickerSlotState();
}

class _ShiningStickerSlotState extends State<ShiningStickerSlot> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _tapController;
  late Animation<double> _glowAnimation;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Continuous sweeping holographic foil sheen (shining shimmering splendid)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Breathing glow aura bloom
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.65, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Tactile tap squish feedback
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'celestial': return const Color(0xFF8B5CF6);
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.stickerId.isNotEmpty ? StickerDatabase.getSticker(widget.stickerId) : null;
    final rarity = info?.rarity ?? 'none';
    final isCelestial = rarity == 'celestial';
    final isMythical = rarity == 'mythical';
    final isLegendary = rarity == 'legend' || rarity == 'legendary';
    final isEpic = rarity == 'epic';
    final isRare = rarity == 'rare';

    final cardHeight = widget.isLarge ? 134.0 : 116.0;
    final cardWidth = widget.isLarge ? 96.0 : null;
    final emojiSize = widget.isLarge ? 40.0 : 32.0;
    final spriteSize = widget.isLarge ? 84.0 : 66.0;

    Widget cardWidget = AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _shimmerController]),
      builder: (context, child) {
        final glowVal = _glowAnimation.value;
        final shimmerVal = _shimmerController.value;

        // Determine Background Gradient
        Gradient cardBgGradient;
        if (info == null) {
          cardBgGradient = const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        } else if (isCelestial) {
          cardBgGradient = const LinearGradient(
            colors: [
              Color(0xFF09061C),
              Color(0xFF160A30),
              Color(0xFF280B4D),
              Color(0xFF0D0524),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        } else if (isMythical) {
          cardBgGradient = const LinearGradient(
            colors: [
              Color(0xFF260404),
              Color(0xFF48090E),
              Color(0xFF700D15),
              Color(0xFF350606),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        } else if (isLegendary) {
          cardBgGradient = const LinearGradient(
            colors: [
              Color(0xFF1E1502),
              Color(0xFF3B2404),
              Color(0xFF5C3806),
              Color(0xFF281803),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        } else if (isEpic) {
          cardBgGradient = const LinearGradient(
            colors: [
              Color(0xFF190C2B),
              Color(0xFF2E124D),
              Color(0xFF4A1A78),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        } else if (isRare) {
          cardBgGradient = const LinearGradient(
            colors: [
              Color(0xFF091630),
              Color(0xFF122B5C),
              Color(0xFF1A3E85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        } else {
          cardBgGradient = const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }

        // Determine Border
        Border cardBorder;
        if (info == null) {
          cardBorder = Border.all(color: const Color(0xFFCBD5E1), width: 1.5);
        } else if (isCelestial) {
          cardBorder = Border.all(
            color: Color.lerp(const Color(0xFFC084FC), const Color(0xFF38BDF8), glowVal)!,
            width: 2.5 + 0.8 * glowVal,
          );
        } else if (isMythical) {
          cardBorder = Border.all(
            color: Color.lerp(const Color(0xFFEF4444), const Color(0xFFFBBF24), glowVal)!,
            width: 2.5 + 0.8 * glowVal,
          );
        } else if (isLegendary) {
          cardBorder = Border.all(
            color: Color.lerp(const Color(0xFFF59E0B), const Color(0xFFFEF08A), glowVal)!,
            width: 2.2 + 0.6 * glowVal,
          );
        } else if (isEpic) {
          cardBorder = Border.all(color: const Color(0xFFA855F7), width: 1.8);
        } else if (isRare) {
          cardBorder = Border.all(color: const Color(0xFF3B82F6), width: 1.8);
        } else {
          cardBorder = Border.all(color: const Color(0xFFE2E8F0), width: 1.5);
        }

        // Determine Multi-Layer Glowing Box Shadows
        List<BoxShadow> cardShadows = [];
        if (info != null) {
          if (isCelestial) {
            cardShadows = [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: (0.40 + 0.35 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 18 + 14 * glowVal,
                spreadRadius: 2.0 + 3.0 * glowVal,
              ),
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: (0.30 + 0.25 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 28 + 12 * glowVal,
                spreadRadius: 3.0 * glowVal,
              ),
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: (0.20 + 0.20 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 36 + 10 * glowVal,
                spreadRadius: 3.5 * glowVal,
              ),
            ];
          } else if (isMythical) {
            cardShadows = [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: (0.40 + 0.35 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 18 + 12 * glowVal,
                spreadRadius: 2.0 + 2.5 * glowVal,
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: (0.30 + 0.25 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 26 + 10 * glowVal,
                spreadRadius: 3.0 * glowVal,
              ),
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: (0.20 + 0.15 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 32 + 8 * glowVal,
                spreadRadius: 3.0 * glowVal,
              ),
            ];
          } else if (isLegendary) {
            cardShadows = [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: (0.35 + 0.30 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 16 + 10 * glowVal,
                spreadRadius: 2.0 + 2.0 * glowVal,
              ),
              BoxShadow(
                color: const Color(0xFFFBBF24).withValues(alpha: (0.25 + 0.20 * glowVal).clamp(0.0, 1.0)),
                blurRadius: 24 + 8 * glowVal,
                spreadRadius: 2.5 * glowVal,
              ),
            ];
          } else if (isEpic) {
            cardShadows = [
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.25 * glowVal),
                blurRadius: 12 + 6 * glowVal,
                spreadRadius: 1.5,
              ),
            ];
          } else if (isRare) {
            cardShadows = [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.25 * glowVal),
                blurRadius: 10 + 4 * glowVal,
                spreadRadius: 1.2,
              ),
            ];
          } else {
            cardShadows = [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ];
          }
        } else {
          cardShadows = [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ];
        }

        // Shimmer Gradient Colors
        LinearGradient? shimmerGradient;
        if (info != null && (isCelestial || isMythical || isLegendary || isEpic)) {
          if (isCelestial) {
            shimmerGradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.0),
                const Color(0xFF38BDF8).withValues(alpha: 0.35 * glowVal),
                Colors.white.withValues(alpha: 0.75 * glowVal),
                const Color(0xFFEC4899).withValues(alpha: 0.40 * glowVal),
                const Color(0xFFA855F7).withValues(alpha: 0.30 * glowVal),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.40, 0.50, 0.60, 0.75, 1.0],
            );
          } else if (isMythical) {
            shimmerGradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.0),
                const Color(0xFFFBBF24).withValues(alpha: 0.35 * glowVal),
                Colors.white.withValues(alpha: 0.75 * glowVal),
                const Color(0xFFEF4444).withValues(alpha: 0.35 * glowVal),
                const Color(0xFFF59E0B).withValues(alpha: 0.25 * glowVal),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.40, 0.50, 0.60, 0.75, 1.0],
            );
          } else if (isLegendary) {
            shimmerGradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.0),
                const Color(0xFFFDE047).withValues(alpha: 0.35 * glowVal),
                Colors.white.withValues(alpha: 0.70 * glowVal),
                const Color(0xFFF59E0B).withValues(alpha: 0.30 * glowVal),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.42, 0.50, 0.58, 0.75, 1.0],
            );
          } else {
            shimmerGradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.40 * glowVal),
                const Color(0xFFA855F7).withValues(alpha: 0.25 * glowVal),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            );
          }
        }

        return Container(
          height: cardHeight,
          width: cardWidth,
          margin: EdgeInsets.only(right: widget.index == 3 ? 0 : 8),
          decoration: BoxDecoration(
            gradient: cardBgGradient,
            borderRadius: BorderRadius.circular(20),
            border: cardBorder,
            boxShadow: cardShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // 1. Ambient Radial Glow behind the icon
                if (info != null && (isCelestial || isMythical || isLegendary))
                  Center(
                    child: Container(
                      width: spriteSize + 10,
                      height: spriteSize + 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            if (isCelestial) ...[
                              const Color(0xFF8B5CF6).withValues(alpha: 0.45 * glowVal),
                              const Color(0xFFEC4899).withValues(alpha: 0.20 * glowVal),
                              Colors.transparent,
                            ] else if (isMythical) ...[
                              const Color(0xFFEF4444).withValues(alpha: 0.45 * glowVal),
                              const Color(0xFFF59E0B).withValues(alpha: 0.20 * glowVal),
                              Colors.transparent,
                            ] else ...[
                              const Color(0xFFF59E0B).withValues(alpha: 0.40 * glowVal),
                              Colors.transparent,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                // 2. Main Content: Pixel Sprite Animation & Emoji
                Center(
                  child: info != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: spriteSize,
                                height: spriteSize - 8,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Smooth Glowing Aura behind emoji (No chunky pixel-art)
                                    if (isCelestial)
                                      Container(
                                        width: spriteSize * 0.92,
                                        height: spriteSize * 0.92,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFC084FC).withValues(alpha: 0.60 * glowVal),
                                              const Color(0xFF38BDF8).withValues(alpha: 0.35 * glowVal),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (isMythical)
                                      Container(
                                        width: spriteSize * 0.92,
                                        height: spriteSize * 0.92,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFEF4444).withValues(alpha: 0.55 * glowVal),
                                              const Color(0xFFF59E0B).withValues(alpha: 0.30 * glowVal),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (isLegendary)
                                      Container(
                                        width: spriteSize * 0.88,
                                        height: spriteSize * 0.88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFF59E0B).withValues(alpha: 0.50 * glowVal),
                                              const Color(0xFFFDE047).withValues(alpha: 0.25 * glowVal),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Foreground Emoji with crisp 3D shadow
                                    Text(
                                      info.emoji,
                                      style: TextStyle(
                                        fontSize: emojiSize,
                                        shadows: [
                                          if (isCelestial)
                                            Shadow(
                                              color: const Color(0xFFC084FC).withValues(alpha: 0.9),
                                              blurRadius: 16,
                                              offset: const Offset(0, 2),
                                            )
                                          else if (isMythical)
                                            Shadow(
                                              color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                                              blurRadius: 16,
                                              offset: const Offset(0, 2),
                                            )
                                          else if (isLegendary)
                                            Shadow(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                                              blurRadius: 12,
                                              offset: const Offset(0, 2),
                                            )
                                          else
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Bottom Rarity Pill Badge
                              _buildRarityBadge(rarity, glowVal),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: Color(0xFF94A3B8), size: 24),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pilih',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                ),

                // 3. Accent Corner Vector Sparkle Effect (No chunky pixel-art)
                if (info != null && isCelestial)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (0.5 + 0.5 * glowVal).clamp(0.0, 1.0),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFC084FC),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                if (info != null && isMythical)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (0.5 + 0.5 * glowVal).clamp(0.0, 1.0),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFEF4444),
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                // 4. Floating Twinkling Sparkles
                if (info != null && (isCelestial || isMythical || isLegendary)) ...[
                  Positioned(
                    top: 6,
                    left: 6,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (0.40 + 0.60 * glowVal).clamp(0.0, 1.0),
                        child: Text(
                          isCelestial ? '✦' : (isMythical ? '🔥' : '⭐'),
                          style: TextStyle(
                            fontSize: 8,
                            color: isCelestial ? const Color(0xFF38BDF8) : (isMythical ? const Color(0xFFF87171) : const Color(0xFFFDE047)),
                            shadows: [
                              Shadow(
                                color: isCelestial ? const Color(0xFF38BDF8) : (isMythical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 22,
                    right: 6,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (0.35 + 0.65 * glowVal).clamp(0.0, 1.0),
                        child: Text(
                          isCelestial ? '✨' : '✦',
                          style: TextStyle(
                            fontSize: isCelestial ? 9 : 8,
                            color: isCelestial ? const Color(0xFFF472B6) : const Color(0xFFFBBF24),
                            shadows: [
                              Shadow(
                                color: isCelestial ? const Color(0xFFEC4899) : const Color(0xFFF59E0B),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 5. Continuous Sweeping Holographic Foil Shimmer (Shining Shimmering Splendid)
                if (shimmerGradient != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: Offset(
                          -120.0 + shimmerVal * 280.0,
                          -80.0 + shimmerVal * 220.0,
                        ),
                        child: Transform.rotate(
                          angle: math.pi / 4.5,
                          child: Container(
                            width: 44,
                            decoration: BoxDecoration(
                              gradient: shimmerGradient,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    // Add tactile tap feedback & sound
    Widget interactiveCard = GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      onTap: () {
        AudioService().playSparkle();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _tapScaleAnimation,
        child: cardWidget,
      ),
    );

    if (widget.isLarge) {
      return interactiveCard;
    }

    return Expanded(
      child: interactiveCard,
    );
  }

  Widget _buildRarityBadge(String rarity, double glowVal) {
    Widget badgeText(String text, {Color color = Colors.white, double letterSpacing = 0.3}) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: color,
            fontSize: 6.8,
            fontWeight: FontWeight.w900,
            letterSpacing: letterSpacing,
          ),
        ),
      );
    }

    switch (rarity) {
      case 'celestial':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE879F9), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC084FC).withValues(alpha: 0.55),
                blurRadius: 6,
              ),
            ],
          ),
          child: badgeText('✦ CELESTIAL ✦'),
        );
      case 'mythical':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB91C1C), Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE047), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                blurRadius: 6,
              ),
            ],
          ),
          child: badgeText('★ MYTHICAL ★'),
        );
      case 'legend':
      case 'legendary':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB45309), Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE047), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
          child: badgeText('★ LEGEND ★'),
        );
      case 'epic':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFA855F7), width: 0.8),
          ),
          child: badgeText('◆ EPIC ◆', color: const Color(0xFFE9D5FF)),
        );
      case 'rare':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
          ),
          child: badgeText('● RARE ●', color: const Color(0xFFBAE6FD)),
        );
      default:
        return badgeText(rarity.toUpperCase(), color: _getRarityColor(rarity));
    }
  }
}
