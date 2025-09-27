import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const PetBreedApp());
}

class PetBreedApp extends StatelessWidget {
  const PetBreedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetBreed Identifier',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// เปลี่ยนจาก StatelessWidget → StatefulWidget เพื่อให้มี initState()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // รอ 3 วินาทีแล้วไปหน้าข้อมูลสายพันธุ์
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // เช็กก่อนใช้ context
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA726), // สีส้มสดใส
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // กำหนดขนาดตามหน้าจอ
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // รูปภาพสัตว์
                  SizedBox(
                    height: height * 0.3,
                    child: Image.asset(
                      'assets/images/pets.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  Text(
                    'PetBreed Identifier',
                    style: TextStyle(
                      fontSize: width * 0.06, // ปรับขนาดตามหน้าจอ
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: height * 0.05),
                  // โหลดหมุน
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                    strokeWidth: 3.5,
                  ),
                  SizedBox(height: height * 0.02),
                  Text(
                    'เริ่มต้นการใช้งาน...',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}