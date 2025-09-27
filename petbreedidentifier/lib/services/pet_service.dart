import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/pet_model.dart';

class PetService {
  /// โหลดข้อมูลสัตว์เลี้ยงจากไฟล์ JSON ใน assets
  static Future<Map<String, List<Pet>>> loadPetsData() async {
    final String jsonString = await rootBundle.loadString('assets/data/pets_data.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    return {
      'dogs': (data['สุนัข'] as List)
          .map((e) => Pet.fromJson(Map<String, dynamic>.from(e), animalType: 'สุนัข'))
          .toList(),
      'cats': (data['แมว'] as List)
          .map((e) => Pet.fromJson(Map<String, dynamic>.from(e), animalType: 'แมว'))
          .toList(),
    };
  }

  /// คืนค่า list ของสายพันธุ์ทั้งหมด
  static Future<List<Pet>> getAllBreeds() async {
    final petsData = await loadPetsData();
    return [...petsData['dogs']!, ...petsData['cats']!];
  }

  /// หา Pet จากชื่อสายพันธุ์
  static Future<Pet?> getBreedByName(String name) async {
    final allBreeds = await getAllBreeds();
    try {
      return allBreeds.firstWhere((breed) => breed.name == name);
    } catch (e) {
      return null; // ถ้าไม่เจอชื่อ
    }
  }
}