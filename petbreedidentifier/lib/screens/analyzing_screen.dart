import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'detection_result_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final String imagePath;

  const AnalyzingScreen({super.key, required this.imagePath});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  List<Map<String, dynamic>> _detections = [];
  bool _loading = true;

  late double _imageWidth;
  late double _imageHeight;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
    _analyzeImage();
  }

  // โหลดขนาดภาพจริง
  void _loadImageSize() {
    final file = File(widget.imagePath);
    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes)!;
    _imageWidth = image.width.toDouble();
    _imageHeight = image.height.toDouble();
  }

  Future<void> _analyzeImage() async {
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/analyze');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('files', widget.imagePath));
      request.fields['save_result'] = 'false';

      final streamedResponse = await request.send();
      final respStr = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        _showError("เกิดข้อผิดพลาดจากเซิร์ฟเวอร์");
        return;
      }

      final jsonResp = json.decode(respStr);
      final results = jsonResp['results'] as List;

      if (results.isEmpty || results[0]['detections'] == null) {
        _showError("ไม่พบสัตว์ในภาพ");
        return;
      }

      final detections = <Map<String, dynamic>>[];
      for (var det in results[0]['detections']) {
        final bbox = det['bbox'] as List<dynamic>;
        detections.add({
          "label": det['label'],
          "confidence": det['confidence'],
          "ageRange": det['age_range'],
          "ageConfidence": det['age_confidence'],
          "x": bbox[0],
          "y": bbox[1],
          "w": bbox[2] - bbox[0],
          "h": bbox[3] - bbox[1],
        });
      }

      if (!mounted) return;
      setState(() {
        _detections = detections;
        _loading = false;
      });

      // ไปหน้าผลลัพธ์ทันที
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetectionResultScreen(
            imagePath: widget.imagePath,
            detectedPets: _detections,
          ),
        ),
      );

    } catch (e) {
      _showError("วิเคราะห์ไม่สำเร็จ: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // คำนวณ scale ของ BoxFit.cover
        final scaleX = screenWidth / _imageWidth;
        final scaleY = screenHeight / _imageHeight;
        final scale = scaleX > scaleY ? scaleX : scaleY;

        final displayWidth = _imageWidth * scale;
        final displayHeight = _imageHeight * scale;

        final offsetX = (screenWidth - displayWidth) / 2;
        final offsetY = (screenHeight - displayHeight) / 2;

        return Stack(
          children: [
            // ภาพพื้นหลัง
            Positioned(
              left: offsetX,
              top: offsetY,
              width: displayWidth,
              height: displayHeight,
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),

            if (_loading)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'กำลังวิเคราะห์...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}