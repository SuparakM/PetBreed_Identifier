import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pet_model.dart';

class BreedDetailScreen extends StatefulWidget {
  final Pet pet;
  const BreedDetailScreen({super.key, required this.pet});

  @override
  State<BreedDetailScreen> createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen> {
  Map<String, String> lifeStages = {};

  @override
  void initState() {
    super.initState();
    loadLifeStages();
  }

  Future<void> loadLifeStages() async {
    final jsonString = await rootBundle.loadString('assets/data/lifestage_care.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final animalLifeStages = jsonMap[widget.pet.animalType]; // เช่น 'สุนัข' หรือ 'แมว'

    if (animalLifeStages != null) {
      setState(() {
        lifeStages = Map<String, String>.from(animalLifeStages);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA726),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE8426),
        title: Text(
          widget.pet.name,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: lifeStages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildImageSection(),
                _buildBreedName(),
                _buildInfoExpansionTiles(),
                _buildLifeStageSection(),
              ],
            ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 270,
        width: double.infinity,
        color: Colors.grey[200],
        child: Image.asset(
          widget.pet.imageAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBreedName() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        widget.pet.name,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoExpansionTiles() {
    return Column(
      children: [
        _buildExpansionTile(
          title: 'ประวัติ',
          content: widget.pet.history,
        ),
        _buildExpansionTile(
          title: 'อุปนิสัย',
          content: widget.pet.personality,
        ),
        _buildExpansionTile(
          title: 'อายุขัยเฉลี่ย',
          content: widget.pet.lifespan,
        ),
        _buildExpansionTile(
          title: 'สิ่งที่ต้องรู้ก่อนเลี้ยง',
          contentWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.pet.careTips.map((tip) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionTile({
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: contentWidget ??
                Text(
                  content ?? '',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.start,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeStageSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text(
          'คำแนะนำการดูแลแต่ละช่วงวัย',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 89, 57, 45),
          ),
        ),
        children: lifeStages.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value,
                  style: const TextStyle(fontSize: 15),
                ),
                const Divider(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}