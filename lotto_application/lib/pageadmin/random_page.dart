import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RandomPage extends StatefulWidget {
  const RandomPage({super.key});

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> {
  Map<String, List<String>> winners = {};
  bool isLoading = false;

  final String apiBase = "http://192.168.100.106:3000/api/lotto";

  @override
  void initState() {
    super.initState();
    getWinners(); // โหลดผลรางวัลล่าสุดตอนเปิดหน้า
  }

  // ฟังก์ชันสุ่มออกรางวัล
  Future<void> drawNumbers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$apiBase/draw"),
        headers: {"Content-Type": "application/json"},
      );
      final data = json.decode(res.body);

      if (data["success"] == true) {
        await getWinners(); // โหลดผลรางวัลใหม่หลังสุ่ม
      } else {
        debugPrint("API error: ${data["message"]}");
        showSnack("เกิดข้อผิดพลาดในการสุ่มรางวัล");
      }
    } catch (e) {
      debugPrint("Request error: $e");
      showSnack("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้");
    }
    setState(() => isLoading = false);
  }

  // ฟังก์ชันดึงผลรางวัลล่าสุด
  Future<void> getWinners() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$apiBase/winner"));
      final data = json.decode(res.body);

      if (data["success"] == true) {
        setState(() {
          winners = (data["winners"] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          );
        });
      } else {
        debugPrint("API error: ${data["message"]}");
        showSnack("ไม่สามารถโหลดผลรางวัลได้");
      }
    } catch (e) {
      debugPrint("Request error: $e");
      showSnack("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้");
    }
    setState(() => isLoading = false);
  }

  // ฟังก์ชันแสดง SnackBar
  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ระบบออกรางวัล"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: drawNumbers,
              icon: const Icon(Icons.casino),
              label: const Text("สุ่มออกรางวัลใหม่"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const CircularProgressIndicator()
            else if (winners.isEmpty)
              const Text("ยังไม่มีการออกรางวัล", style: TextStyle(fontSize: 16))
            else
              Expanded(
                child: ListView(
                  children: winners.entries.expand((entry) {
                    final prizeKey = entry.key;
                    final numbers = entry.value;
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          labelPrize(prizeKey),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...numbers.map(
                        (num) => Card(
                          color: Colors.teal[100],
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              num,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ];
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันแปลงชื่อรางวัล
  String labelPrize(String key) {
    switch (key) {
      case "1":
        return "รางวัลที่ 1";
      case "2":
        return "รางวัลที่ 2";
      case "3":
        return "รางวัลที่ 3";
      case "last3":
        return "เลขท้าย 3 ตัว";
      case "last2":
        return "เลขท้าย 2 ตัว";
      default:
        return "รางวัล $key";
    }
  }
}
