class Pet {
  final String name;
  final String imageAsset;
  final String history;
  final String personality;
  final String lifespan;
  final List<String> careTips;
  final String animalType;

  Pet({
    required this.name,
    required this.imageAsset,
    required this.history,
    required this.personality,
    required this.lifespan,
    required this.careTips,
    required this.animalType,
  });

  /// สำหรับสร้างจาก JSON ของ assets หรือ backend
  factory Pet.fromJson(Map<String, dynamic> json, {String? animalType}) {
    return Pet(
      name: json['ชื่อสายพันธุ์'] ?? json['label'] ?? 'ไม่ระบุ',
      imageAsset: json['image_asset'] ?? '',
      history: json['ประวัติ'] ?? '',
      personality: json['อุปนิสัย'] ?? '',
      lifespan: json['อายุขัยเฉลี่ย'] ?? '',
      careTips: List<String>.from(json['สิ่งที่ต้องรู้ก่อนเลี้ยง'] ?? []),
      animalType: animalType ?? json['ประเภทสัตว์'] ?? 'ไม่ระบุ',
    );
  }

  // สำหรับบันทึกลง SQLite
  Map<String, dynamic> toJsonMap() {
    return {
      'name': name,
      'imageAsset': imageAsset,
      'history': history,
      'personality': personality,
      'lifespan': lifespan,
      'careTips': careTips, // เก็บเป็น array
      'animalType': animalType,
    };
  }
}