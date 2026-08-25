import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/child_profile.dart';
import '../theme/app_theme.dart';

class ChildSelectorScreen extends StatefulWidget {
  const ChildSelectorScreen({super.key});

  @override
  State<ChildSelectorScreen> createState() => _ChildSelectorScreenState();
}

class _ChildSelectorScreenState extends State<ChildSelectorScreen> {
  static const int _maxChildren = 5;

  static const List<String> _avatarOptions = [
    '👦', '👧', '🧒', '👶', '🐱', '🐶', '🦊', '🐼', '🐸', '🦄',
  ];

  // Form state
  final _nameController = TextEditingController();
  int _selectedAge = 5;
  String _selectedGender = 'male';
  String _selectedAvatar = '👦';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _switchChild(AppState appState, String childId) async {
    await appState.switchChild(childId);

    final selected = appState.children.firstWhere((c) => c.id == childId, orElse: () => appState.children.first);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Beralih ke ${selected.name}',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddChildSheet(AppState appState) {
    if (appState.children.length >= _maxChildren) {
      _showMaxChildrenWarning();
      return;
    }

    // Reset form
    _nameController.clear();
    _selectedAge = 5;
    _selectedGender = 'male';
    _selectedAvatar = '👦';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddChildBottomSheet(
        nameController: _nameController,
        initialAge: _selectedAge,
        initialGender: _selectedGender,
        initialAvatar: _selectedAvatar,
        avatarOptions: _avatarOptions,
        onSave: (name, age, gender, avatar) {
          _addChild(appState, name, age, gender, avatar);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMaxChildrenWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('⚠️', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Batas Tercapai',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Maksimal 5 profil anak yang dapat ditambahkan. Hapus profil yang tidak digunakan untuk menambah yang baru.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: AppTheme.gray600,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addChild(AppState appState, String name, int age, String gender, String avatar) async {
    final newChild = ChildProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      age: age,
      gender: gender,
      avatar: avatar,
      surveyCompleted: true,
      createdAt: DateTime.now(),
    );

    await appState.addChild(newChild);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name berhasil ditambahkan! 🎉',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final children = appState.children;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Anak',
          style: AppTheme.heading2.copyWith(
            fontSize: 20,
            color: AppTheme.gray900,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${children.length}/$_maxChildren',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: children.length + 1, // +1 for the add card
          itemBuilder: (context, index) {
            if (index < children.length) {
              return _buildChildCard(appState, children[index]);
            }
            return _buildAddCard(appState);
          },
        ),
      ),
    );
  }

  Widget _buildChildCard(AppState appState, ChildProfile child) {
    final bool isActive = child.id == appState.activeChildId;
    final String genderLabel =
        child.gender == 'male' ? 'Laki-laki' : 'Perempuan';

    return GestureDetector(
      onTap: () => _switchChild(appState, child.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.gray200,
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Active checkmark badge
            if (isActive)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            // Card content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryBlueLight
                            : AppTheme.gray100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          child.avatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      child.name,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? AppTheme.primaryBlue
                            : AppTheme.gray800,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Age
                    Text(
                      '${child.age} tahun',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Gender
                    Text(
                      genderLabel,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: child.gender == 'male'
                            ? AppTheme.primaryBlue
                            : AppTheme.primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard(AppState appState) {
    return GestureDetector(
      onTap: () => _showAddChildSheet(appState),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.gray300,
            width: 1.5,
            // Dashed border simulated via custom paint below
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppTheme.gray300,
            borderRadius: 20,
            strokeWidth: 1.5,
            dashWidth: 8,
            dashSpace: 5,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.blue300,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 30,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '+ Tambah Anak',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed border painter for the add-child card
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderRadius != oldDelegate.borderRadius ||
      strokeWidth != oldDelegate.strokeWidth;
}

/// Bottom sheet for adding a new child profile
class _AddChildBottomSheet extends StatefulWidget {
  final TextEditingController nameController;
  final int initialAge;
  final String initialGender;
  final String initialAvatar;
  final List<String> avatarOptions;
  final void Function(String name, int age, String gender, String avatar)
      onSave;

  const _AddChildBottomSheet({
    required this.nameController,
    required this.initialAge,
    required this.initialGender,
    required this.initialAvatar,
    required this.avatarOptions,
    required this.onSave,
  });

  @override
  State<_AddChildBottomSheet> createState() => _AddChildBottomSheetState();
}

class _AddChildBottomSheetState extends State<_AddChildBottomSheet> {
  late int _age;
  late String _gender;
  late String _avatar;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge;
    _gender = widget.initialGender;
    _avatar = widget.initialAvatar;
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        widget.nameController.text.trim(),
        _age,
        _gender,
        _avatar,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Center(
                child: Text(
                  'Tambah Profil Anak',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              const Text(
                'Nama Anak',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.nameController,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan nama anak',
                  hintStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.gray400,
                  ),
                  filled: true,
                  fillColor: AppTheme.gray50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama anak tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Age dropdown
              const Text(
                'Usia',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _age,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.gray500,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: AppTheme.gray800,
                    ),
                    items: List.generate(11, (i) => i + 2).map((age) {
                      return DropdownMenuItem<int>(
                        value: age,
                        child: Text('$age tahun'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _age = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gender selection
              const Text(
                'Jenis Kelamin',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _GenderOption(
                      label: 'Laki-laki',
                      icon: Icons.male_rounded,
                      isSelected: _gender == 'male',
                      color: AppTheme.primaryBlue,
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderOption(
                      label: 'Perempuan',
                      icon: Icons.female_rounded,
                      isSelected: _gender == 'female',
                      color: AppTheme.primaryPink,
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar picker
              const Text(
                'Pilih Avatar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray700,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.avatarOptions.length,
                itemBuilder: (context, index) {
                  final emoji = widget.avatarOptions[index];
                  final isSelected = _avatar == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _avatar = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlueLight
                            : AppTheme.gray50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.gray200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gender option toggle card
class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppTheme.gray50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppTheme.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.gray400, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : AppTheme.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
