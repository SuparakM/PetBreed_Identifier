import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/pet_model.dart';
import '../services/pet_service.dart';
import '../services/db_helper.dart';
import '../utils/breed_age_mapper.dart';
import 'main_screen.dart';

class DetectionResultScreen extends StatefulWidget {
  final String imagePath;
  final List<Map<String, dynamic>> detectedPets;

  const DetectionResultScreen({
    super.key,
    required this.imagePath,
    required this.detectedPets,
  });

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  int currentIndex = 0;
  bool isBreedExpanded = true;

  final Map<String, Color> _labelColors = {};
  final List<Pet?> allPetModels = [];
  final List<String?> ageTipsList = [];

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    if (widget.detectedPets.isNotEmpty) {
      _loadAllPets().then((_) => _loadAllAgeTips());
    }
  }

  // โหลดข้อมูลสัตว์ทุกตัว
  Future<void> _loadAllPets() async {
    allPetModels.clear();

    for (var pet in widget.detectedPets) {
      final label = pet['label'] ?? '';
      final breedName = BreedAgeMapper.mapBreed(label);
      if (breedName.isEmpty) {
        allPetModels.add(null);
      } else {
        final petModel = await PetService.getBreedByName(breedName);
        allPetModels.add(petModel);
      }
    }
    setState(() {});
  }

  // โหลดคำแนะนำช่วงวัยทุกตัว
  Future<void> _loadAllAgeTips() async {
    ageTipsList.clear();
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/lifestage_care.json');
      final jsonData = json.decode(jsonString);

      for (var pet in widget.detectedPets) {
        final label = pet['label'] ?? '';
        final rawAge = pet['ageRange'] ?? '';
        final ageKey = BreedAgeMapper.ageMapping[rawAge] ?? rawAge;
        final typeKey = convertAnimalType(_getAnimalType(label));
        final tips = jsonData[typeKey]?[ageKey]?.toString();
        ageTipsList.add(tips);
      }
    } catch (e) {
      ageTipsList.clear();
    }
    setState(() {});
  }

  String _getAnimalType(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('dog')) return 'dog';
    if (lower.contains('cat')) return 'cat';
    return 'unknown';
  }

  String convertAnimalType(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return 'สุนัข';
      case 'cat':
        return 'แมว';
      default:
        return type;
    }
  }

  // SHARE IMAGE
  Future<void> _shareResult() async {
    try {
      final imageFile = await _screenshotController.capture();
      if (imageFile == null) return;

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/result.png';
      final file = File(filePath);
      await file.writeAsBytes(imageFile);

      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint("แชร์ไม่สำเร็จ: $e");
    }
  }

  Future<void> _saveToHistory() async {
    if (widget.detectedPets.isEmpty) return;

    try {
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);

      final boxedBytes = await _screenshotController.capture();
      if (boxedBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final originalPath = widget.imagePath;
      final boxedPath = '${tempDir.path}/boxed_${now.millisecondsSinceEpoch}.png';
      final boxedFile = File(boxedPath);
      await boxedFile.writeAsBytes(boxedBytes);

      final List<Map<String, dynamic>> breedsInfo = [];
      final List<Map<String, dynamic>> agesInfo = [];
      final List<Map<String, dynamic>> breedDetailsList = [];
      final List<Map<String, dynamic>> ageTipsListJson = [];

      for (int i = 0; i < widget.detectedPets.length; i++) {
        final detection = widget.detectedPets[i];
        final label = detection['label'] ?? '';
        final ageRange = detection['ageRange'] ?? '';
        final breedConfidence = ((detection['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
        final ageConfidence = ((detection['ageConfidence'] ?? 0.0) * 100).toStringAsFixed(1);
        final species = _getAnimalType(label);

        breedsInfo.add({
          'breed': BreedAgeMapper.mapBreed(label),
          'confidence': breedConfidence,
          'species': species,
        });

        agesInfo.add({
          'ageStage': BreedAgeMapper.mapAge(ageRange),
          'confidence': ageConfidence,
        });

        final petModel = (i < allPetModels.length) ? allPetModels[i] : null; 
        if (petModel != null) { breedDetailsList.add(petModel.toJsonMap()); }

        final tips = (i < ageTipsList.length) ? ageTipsList[i] : ''; 
        if (tips != null && tips.isNotEmpty) { ageTipsListJson.add({ 'ageStage': BreedAgeMapper.mapAge(ageRange), 'tips': tips, }); }
      }

      final List<Map<String, dynamic>> boxes = widget.detectedPets.asMap().entries.map((entry) {
        final index = entry.key;
        final detection = entry.value;
        return {
          'x': detection['x'] ?? 0.0,
          'y': detection['y'] ?? 0.0,
          'w': detection['w'] ?? 0.0,
          'h': detection['h'] ?? 0.0,
          'label': detection['label'] ?? '',
          'color': _labelColors[index.toString()]?.toARGB32().toRadixString(16), // สีเป็น hex
          'confidence': detection['confidence'] ?? 0.0,
          'ageRange': detection['ageRange'] ?? '',
          'ageConfidence': detection['ageConfidence'] ?? 0.0,
        };
      }).toList();

      final historyData = {
        'datetime': dateString,
        'originalImage': originalPath,
        'boxedImage': boxedPath,
        'breeds': jsonEncode(breedsInfo),
        'ages': jsonEncode(agesInfo),
        'breedDetails': jsonEncode(breedDetailsList),
        'ageTips': jsonEncode(ageTipsListJson),
        'boxes': jsonEncode(boxes),
      };

      await DBHelper.insertHistory(historyData);

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
          (route) => false,
        );
      });
    } catch (e) {
      debugPrint('บันทึกไม่สำเร็จ: $e');
    }
  }

  Color _colorFromIndex(int index) {
    final key = index.toString();
    if (_labelColors.containsKey(key)) {
      return _labelColors[key]!; // ใช้สีเดิม
    }
    // สุ่มสีครั้งแรก
    final rnd = Random(index + DateTime.now().millisecondsSinceEpoch);
    final color = Color.fromARGB(
      255,
      100 + rnd.nextInt(155),
      100 + rnd.nextInt(155),
      100 + rnd.nextInt(155),
    );
    _labelColors[index.toString()] = color;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.detectedPets.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('ไม่พบข้อมูลสัตว์เลี้ยง')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFA726),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE8426),
        centerTitle: true,
        title: const Text(
          'ผลลัพธ์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResult,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.35,
                            width: double.infinity,
                            child: (widget.imagePath.isNotEmpty &&
                                    File(widget.imagePath).existsSync())
                                ? _buildDetectionPreview()
                                : const Center(child: Text('ไม่มีรูปภาพ')),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _buildTab('สายพันธุ์', isBreedExpanded,
                                    () => setState(() => isBreedExpanded = true)),
                                _buildTab('ช่วงวัย', !isBreedExpanded,
                                    () => setState(() => isBreedExpanded = false)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFCE8426),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.detectedPets.asMap().entries.map((entry) {
                          final index = entry.key;
                          final detection = entry.value;
                          final label = detection['label'] ?? '';
                          final age = detection['ageRange'] ?? '';
                          final breedConfidence =
                              ((detection['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
                          final ageConfidence =
                              ((detection['ageConfidence'] ?? 0.0) * 100).toStringAsFixed(1);

                          final breed = BreedAgeMapper.mapBreed(label);
                          final ageRange = BreedAgeMapper.mapAge(age);
                          final boxColor = _colorFromIndex(index);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: boxColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    isBreedExpanded
                                        ? '$breed ($breedConfidence%)'
                                        : '$ageRange ($ageConfidence%)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: isBreedExpanded
                            ? _buildBreedDetails()
                            : _buildAgeDetails(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveToHistory,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'บันทึกลงประวัติ',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final bytes = File(widget.imagePath).readAsBytesSync();
        final image = img.decodeImage(bytes)!;
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();

        final scaleX = screenWidth / imageWidth;
        final scaleY = screenHeight / imageHeight;
        final scale = min(scaleX, scaleY);

        final displayWidth = imageWidth * scale;
        final displayHeight = imageHeight * scale;

        const innerPadding = 0.0;
        final offsetX = (screenWidth - displayWidth) / 2 + innerPadding;
        final offsetY = (screenHeight - displayHeight) / 2 + innerPadding;
        final adjustedWidth = displayWidth - innerPadding * 2;
        final adjustedHeight = displayHeight - innerPadding * 2;

        return Stack(
          children: [
            Positioned(
              left: offsetX,
              top: offsetY,
              width: displayWidth,
              height: displayHeight,
              child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
            ),
            ...widget.detectedPets.asMap().entries.map((entry) {
              final index = entry.key;
              final detection = entry.value;

              final x = ((detection['x'] as num?)?.toDouble() ?? 0.0) * scale + offsetX;
              final y = ((detection['y'] as num?)?.toDouble() ?? 0.0) * scale + offsetY;
              final w = ((detection['w'] as num?)?.toDouble() ?? 0.0) * scale;
              final h = ((detection['h'] as num?)?.toDouble() ?? 0.0) * scale;

              final breed = detection['label'] ?? '';
              final confidence = ((detection['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
              final ageRange = detection['ageRange'] ?? '';
              final ageConfidence = ((detection['ageConfidence'] ?? 0.0) * 100).toStringAsFixed(1);

              final boxColor = _colorFromIndex(index);

              return Positioned(
                left: x.clamp(offsetX, offsetX + adjustedWidth - w),
                top: y.clamp(offsetY, offsetY + adjustedHeight - h),
                width: min(w, adjustedWidth),
                height: min(h, adjustedHeight),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: boxColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: boxColor.withAlpha(180),
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$breed $confidence%\n$ageRange $ageConfidence%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildTab(String title, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFCE8426) : const Color(0xFFFFA726),
            borderRadius: BorderRadius.only(
              topLeft: title == 'สายพันธุ์' ? const Radius.circular(10) : Radius.zero,
              topRight: title == 'ช่วงวัย' ? const Radius.circular(10) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBreedDetails() {
    if (allPetModels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayedBreeds = <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allPetModels.asMap().entries.map((entry) {
        final index = entry.key;
        final petModel = entry.value;
        final detection = widget.detectedPets[index];
        final label = detection['label'] ?? '';
        final breed = BreedAgeMapper.mapBreed(label);

        if (breed.isEmpty || displayedBreeds.contains(breed)) {
          return const SizedBox.shrink();
        }
        displayedBreeds.add(breed);

        if (petModel == null) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("ไม่พบข้อมูลสำหรับ $breed"),
          );
        }

        // การ์ดหลัก = ชื่อสายพันธุ์
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            title: Text(
              breed,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 89, 57, 45),
              ),
            ),
            children: [
              _buildInnerExpansionTile('ประวัติ', petModel.history),
              _buildInnerExpansionTile('อุปนิสัย', petModel.personality),
              _buildInnerExpansionTile('อายุขัยเฉลี่ย', petModel.lifespan),
              _buildInnerExpansionTile(
                'สิ่งที่ต้องรู้ก่อนรับเลี้ยง',
                null,
                customWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: petModel.careTips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(child: Text(tip, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// ExpansionTile ย่อยด้านใน (หัวข้อย่อยแต่ละอัน)
  Widget _buildInnerExpansionTile(String title, String? content, {Widget? customWidget}) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: customWidget ??
              Text(
                content ?? '',
                style: const TextStyle(fontSize: 16),
              ),
        ),
      ],
    );
  }

  Widget _buildAgeDetails() {
    if (ageTipsList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayedAges = <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.detectedPets.asMap().entries.map((entry) {
        final index = entry.key;
        final detection = entry.value;

        final age = detection['ageRange'] ?? '';
        final ageRange = BreedAgeMapper.mapAge(age);

        // กันข้อมูลซ้ำ เช่น ถ้ามีสัตว์หลายตัวที่ช่วงวัยเดียวกัน
        if (ageRange.isEmpty || displayedAges.contains(ageRange)) {
          return const SizedBox.shrink();
        }
        displayedAges.add(ageRange);

        final tips = (index < ageTipsList.length) ? ageTipsList[index] : '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            title: Text(
              'คำแนะนำการดูแลช่วงวัยของ $ageRange',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 89, 57, 45),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  (tips != null && tips.isNotEmpty) ? tips : 'ไม่พบคำแนะนำสำหรับช่วงวัยนี้',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}