import 'package:flutter/material.dart';
import 'breed_detail_screen.dart';
import '../services/pet_service.dart';
import '../models/pet_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Pet> allBreeds = [];
  List<Pet> filteredBreeds = [];

  @override
  void initState() {
    super.initState();
    _loadBreeds();
    _searchController.addListener(_filterBreeds);
  }

  Future<void> _loadBreeds() async {
    final breeds = await PetService.getAllBreeds();
    setState(() {
      allBreeds = breeds;
      filteredBreeds = breeds;
    });
  }

  void _filterBreeds() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredBreeds = allBreeds
          .where((breed) => breed.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA726),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE8426),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'ข้อมูลสายพันธุ์',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อสายพันธุ์',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: allBreeds.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredBreeds.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่พบสายพันธุ์',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredBreeds.length,
                        itemBuilder: (context, index) {
                          final breed = filteredBreeds[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage(breed.imageAsset),
                                radius: 20,
                              ),
                              title: Text(
                                breed.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BreedDetailScreen(pet: breed),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}