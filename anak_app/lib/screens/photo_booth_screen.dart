import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoBoothScreen extends StatefulWidget {
  const PhotoBoothScreen({super.key});

  @override
  State<PhotoBoothScreen> createState() => _PhotoBoothScreenState();
}

class _PhotoBoothScreenState extends State<PhotoBoothScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _selectedSticker = 'assets/images/stickers/keren.png';
  
  final List<String> _stickers = [
    'assets/images/stickers/hai.png',
    'assets/images/stickers/keren.png',
    'assets/images/stickers/hebat.png',
    'assets/images/stickers/love_it.png',
    'assets/images/stickers/yeeey.png',
  ];

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Zikola Photo Booth 📸', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_image != null)
                    Image.file(_image!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.grey.shade900,
                      alignment: Alignment.center,
                      child: const Text('Belum ada foto.\nTekan tombol kamera!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                    ),
                  
                  // Draggable Sticker overlay
                  if (_image != null)
                    Positioned(
                      bottom: 50,
                      right: 50,
                      child: Image.asset(_selectedSticker, width: 150),
                    ),
                ],
              ),
            ),
          ),
          
          // Sticker Selection
          Container(
            height: 100,
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stickers.length,
              itemBuilder: (context, index) {
                final sticker = _stickers[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedSticker = sticker),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedSticker == sticker ? Colors.pink : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white24,
                    ),
                    child: Image.asset(sticker, width: 60, height: 60),
                  ),
                );
              },
            ),
          ),
          
          // Camera Button
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _takePhoto,
                  backgroundColor: Colors.pink,
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
