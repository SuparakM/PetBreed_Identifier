import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analyzing_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      await _analyzeAndNavigate(picked);
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null && mounted) {
      await _analyzeAndNavigate(picked);
    }
  }

  Future<void> _analyzeAndNavigate(XFile picked) async {
    // ไปหน้ากำลังวิเคราะห์
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzingScreen(imagePath: picked.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA726),
      body: Stack(
        children: [
          const Center(
            child: Text(
              'กรุณาเลือกรูปภาพหรือถ่ายภาพ',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFFFFA726),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, size: 30),
                    onPressed: _pickFromGallery,
                  ),
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 30), // ปุ่มสลับกล้อง (เว้นที่ไว้)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}