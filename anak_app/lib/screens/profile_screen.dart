import 'dart:convert';
import 'package:flutter/material.dart';
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

  final List<String> _avatarOptions = ['👦', '👧', '🧒', '👶', '🐱', '🐶', '🦊', '🐼', '🐸', '🦄'];

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
    final profile = context.watch<AppState>().childProfile;
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
        title: Text('Kustomisasi Profile', style: AppTheme.heading2.copyWith(color: const Color(0xFF1E293B), fontSize: 18)),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                      image: profile.avatarBase64 != null 
                        ? DecorationImage(image: MemoryImage(base64Decode(profile.avatarBase64!)), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: profile.avatarBase64 == null 
                      ? Center(child: Text(profile.avatar, style: const TextStyle(fontSize: 56)))
                      : null,
                  ),
                  const SizedBox(height: 20),
                  Text(profile.name, style: AppTheme.heading1.copyWith(fontSize: 24, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#Warna$favColorLabel',
                      style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Follow Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/follows-screen', arguments: {
                            'title': 'Pengikut',
                            'uids': profile.followers,
                          });
                        },
                        child: _buildStatColumn('Pengikut', profile.followers.length.toString()),
                      ),
                      Container(height: 24, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 24)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/follows-screen', arguments: {
                            'title': 'Mengikuti',
                            'uids': profile.following,
                          });
                        },
                        child: _buildStatColumn('Mengikuti', profile.following.length.toString()),
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
                              color: isSelected ? bgColor.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? bgColor : const Color(0xFFF1F5F9),
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: bgColor.withOpacity(0.2), blurRadius: 8)] : [],
                            ),
                            child: Center(child: Text(avatar, style: const TextStyle(fontSize: 32))),
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
                                color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.02),
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
                      onPressed: () => setState(() => _showCustomization = false),
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
    final bgColor = _parseColor(profile.backgroundColor);
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [bgColor, bgColor.withOpacity(0.8)],
                      ),
                    ),
                    child: Center(child: Text('Profile', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 18))),
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
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 8))],
                            ),
                            child: Column(
                              children: [
                                // Avatar & Edit Name
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        color: bgColor, shape: BoxShape.circle, 
                                        boxShadow: [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                        image: profile.avatarBase64 != null 
                                          ? DecorationImage(image: MemoryImage(base64Decode(profile.avatarBase64!)), fit: BoxFit.cover) 
                                          : null,
                                      ),
                                      child: profile.avatarBase64 == null 
                                        ? Center(child: Text(profile.avatar, style: const TextStyle(fontSize: 32))) 
                                        : null,
                                    ),
                                    Positioned(
                                      bottom: -4, right: -4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _showCustomization = true),
                                        child: Container(
                                          width: 32, height: 32,
                                          decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

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
                                        child: Text(profile.name, style: AppTheme.heading2.copyWith(color: AppTheme.gray900, fontSize: 20)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appState.email ?? '${profile.name.toLowerCase()}@gmail.com',
                                        style: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 12),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Follow Stats
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context, '/follows-screen', arguments: {
                                                'title': 'Pengikut',
                                                'uids': profile.followers,
                                              });
                                            },
                                            child: _buildStatColumn('Pengikut', profile.followers.length.toString()),
                                          ),
                                          Container(height: 24, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 24)),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context, '/follows-screen', arguments: {
                                                'title': 'Mengikuti',
                                                'uids': profile.following,
                                              });
                                            },
                                            child: _buildStatColumn('Mengikuti', profile.following.length.toString()),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 24),

                                // Improved Points Card
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // Premium Blue
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                                        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Total Poin Kamu', style: AppTheme.bodyText.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const Text('💰', style: TextStyle(fontSize: 20)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  AppState.formatCurrency(appState.totalPoints),
                                                  style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 28, letterSpacing: -0.5),
                                                ),
                                              ],
                                            ),
                                          ],
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
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                                          final showcased = profile.showcasedStickers.length > index ? profile.showcasedStickers[index] : '';
                                          
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
                                        BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Background decorations
                                        Positioned(
                                          top: -32, right: -32,
                                          child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle)),
                                        ),
                                        Positioned(
                                          bottom: -24, left: -24,
                                          child: Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle)),
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
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Center(child: Text('🎭', style: TextStyle(fontSize: 20))),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Kepribadian MBTI', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 13)),
                                                      Text(mbti['type'] ?? 'Unknown', style: AppTheme.bodyText.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // Main Content Card
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                                                            color: Colors.white.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
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
                                                              Text(mbti['personality'] ?? '', style: AppTheme.bodyText.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 12)),
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
                                                                            color: Colors.white.withOpacity(0.2),
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                                                      Container(height: 1, color: Colors.white.withOpacity(0.2)),
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
                                                    shadowColor: Colors.black.withOpacity(0.2),
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
                                        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 56,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.palette, color: Colors.white, size: 20),
                                            SizedBox(width: 12),
                                            Text('Kustomisasi Profile', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
                                
                                if (result == true || result is String) {
                                  if (result == 'RESET') {
                                    await appState.setParentalPin('');
                                  } else if (result is String && result.isNotEmpty) {
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor == Colors.transparent ? AppTheme.gray100 : borderColor, width: borderColor == Colors.transparent ? 1 : 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
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
                  Text(title, style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.bodyText.copyWith(color: borderColor != Colors.transparent ? iconColor ?? AppTheme.gray500 : AppTheme.gray500, fontSize: 11)),
                  ]
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.gray400, size: 20),
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(height: 6),
        Text(score, style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
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
    // Group stickers by rarity
    final Map<String, List<String>> groupedStickers = {
      'semua': appState.collectedStickers,
      'mythical': appState.collectedStickers.where((id) => StickerDatabase.getSticker(id)?.rarity == 'mythical').toList(),
      'legendary': appState.collectedStickers.where((id) => ['legend', 'legendary'].contains(StickerDatabase.getSticker(id)?.rarity)).toList(),
      'epic': appState.collectedStickers.where((id) => StickerDatabase.getSticker(id)?.rarity == 'epic').toList(),
      'rare': appState.collectedStickers.where((id) => StickerDatabase.getSticker(id)?.rarity == 'rare').toList(),
      'common': appState.collectedStickers.where((id) => StickerDatabase.getSticker(id)?.rarity == 'common').toList(),
    };

    final List<Map<String, dynamic>> categories = [
      {'id': 'semua', 'label': 'Semua', 'icon': '✨', 'color': AppTheme.primaryBlue},
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
                          color: isSelected ? cat['color'].withOpacity(0.15) : Colors.transparent,
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
              color: color.withOpacity(0.05),
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
    final isMythical = rarity == 'mythical';
    final cardColor = _getRarityColor(rarity);

    return GestureDetector(
      onTap: () {
        appState.setShowcasedSticker(slotIndex, stickerId);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isMythical ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? cardColor : (isMythical ? Colors.transparent : AppTheme.gray100),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            if (isSelected) 
              BoxShadow(color: cardColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            if (isMythical && !isSelected)
              BoxShadow(color: cardColor.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: Stack(
          children: [
            if (isMythical)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [cardColor.withOpacity(0.2), Colors.transparent],
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
                        color: isMythical ? Colors.white : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rarity.toUpperCase(), 
                      style: TextStyle(
                        fontSize: 7, 
                        fontWeight: FontWeight.w900, 
                        color: cardColor,
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
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: AppTheme.heading2.copyWith(fontSize: 18, color: const Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.bodyText.copyWith(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
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

class _ShiningStickerSlotState extends State<ShiningStickerSlot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
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
    final isMythical = rarity == 'mythical';
    final isLegendary = rarity == 'legend' || rarity == 'legendary';
    final isPremium = isMythical || isLegendary || rarity == 'epic';
    final cardHeight = widget.isLarge ? 125.0 : 100.0;
    final emojiSize = widget.isLarge ? 52.0 : 40.0;

    return Expanded(
      flex: widget.isLarge ? 0 : 1,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            double glowVal = _glowAnimation.value;
            
            return Container(
              height: cardHeight,
              width: widget.isLarge ? 90 : null,
              margin: EdgeInsets.only(right: widget.index == 3 ? 0 : 8),
              decoration: BoxDecoration(
                color: info != null ? _getSlotBgColor(rarity) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: info != null
                      ? (isMythical
                          ? Color.lerp(const Color(0xFFEF4444), const Color(0xFFFF6B6B), glowVal)!
                          : _getSlotBorderColor(rarity))
                      : const Color(0xFFE2E8F0),
                  width: isMythical ? 3.0 + 1.5 * glowVal : (isPremium ? 2.0 : 1.5),
                ),
                boxShadow: isPremium && info != null ? [
                  BoxShadow(
                    color: _getRarityColor(rarity).withOpacity(
                      isMythical ? (0.25 + 0.35 * glowVal) : (0.15 + 0.15 * glowVal)
                    ),
                    blurRadius: isMythical ? (12 + 12 * glowVal) : (8 + 6 * glowVal),
                    spreadRadius: isMythical ? (2 + 3 * glowVal) : glowVal,
                  ),
                  if (isMythical)
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1 * glowVal),
                      blurRadius: 20,
                      spreadRadius: 4 * glowVal,
                    ),
                ] : info != null ? [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                ] : [],
              ),
              child: Stack(
                children: [
                  // Shimmer for legendary/mythical
                  if (info != null && (isMythical || isLegendary))
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Transform.translate(
                          offset: Offset(_controller.value * 180 - 90, -80 + _controller.value * 160),
                          child: Transform.rotate(
                            angle: 0.5,
                            child: Container(
                              width: 35,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.2 * glowVal),
                                    (isMythical ? Colors.red : Colors.amber).withOpacity(0.06 * glowVal),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                  // Main content
                  Center(
                    child: info != null 
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(info.emoji, style: TextStyle(fontSize: emojiSize)),
                            const SizedBox(height: 2),
                            Text(
                              info.rarity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: _getRarityColor(rarity).withOpacity(0.7),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Color(0xFFCBD5E1), size: 32),
                            const SizedBox(height: 2),
                            Text('Pilih', style: TextStyle(fontSize: 8, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                          ],
                        ),
                  ),

                  // Mythical sparkle particles
                  if (info != null && isMythical) ...[
                    Positioned(
                      top: 8 + 4 * glowVal, left: 8,
                      child: Text('✦', style: TextStyle(fontSize: 6, color: Colors.red.withOpacity(0.5 * glowVal))),
                    ),
                    Positioned(
                      bottom: 10 - 2 * glowVal, right: 8,
                      child: Text('✦', style: TextStyle(fontSize: 7, color: Colors.amber.withOpacity(0.4 * glowVal))),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getSlotBgColor(String rarity) {
    switch (rarity) {
      case 'mythical': return const Color(0xFFFEF2F2);
      case 'legend':
      case 'legendary': return const Color(0xFFFFFBEB);
      case 'epic': return const Color(0xFFFAF5FF);
      case 'rare': return const Color(0xFFEFF6FF);
      default: return Colors.white;
    }
  }

  Color _getSlotBorderColor(String rarity) {
    switch (rarity) {
      case 'mythical': return const Color(0xFFEF4444);
      case 'legend':
      case 'legendary': return const Color(0xFFF59E0B);
      case 'epic': return const Color(0xFFA855F7);
      case 'rare': return const Color(0xFF3B82F6);
      default: return const Color(0xFFE2E8F0);
    }
  }
}
