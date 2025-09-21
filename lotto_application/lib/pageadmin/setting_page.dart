import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // สุ่มเลขล็อตโต้ 100 ชุด
  Future<void> generateLottoNumbers() async {
    Random random = Random();
    List<Map<String, dynamic>> numbersWithId =
        []; // ใช้ List<Map> เพื่อเก็บเลขล็อตโต้พร้อมกับ ID

    for (int i = 1; i <= 100; i++) {
      int firstPart = random.nextInt(9000) + 1000; // 1000-9999
      int secondPart = random.nextInt(100); // 00-99
      String secondPartFormatted = secondPart.toString().padLeft(2, '0');
      String lottoNumber = '$firstPart$secondPartFormatted';

      // ตรวจสอบว่าเลขล็อตโต้ไม่เป็น null หรือว่าง
      if (lottoNumber.isNotEmpty) {
        // สร้างเลขล็อตโต้พร้อมกับ lottoID
        numbersWithId.add({
          'lottoID': i, // lottoID เริ่มจาก 1 ถึง 100
          'number': lottoNumber, // เลขล็อตโต้ที่สุ่มได้
        });
      }
    }

    // ตรวจสอบหาก numbersWithId เป็นว่าง
    if (numbersWithId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ไม่มีเลขล็อตโต้ที่สร้างได้")));
      return;
    }

    bool success = await sendToDatabase(numbersWithId);

    if (success) {
      // แสดง SnackBar แจ้งว่าบันทึกข้อมูลเรียบร้อยแล้ว
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("บันทึกข้อมูลล็อตโต้เรียบร้อยแล้ว")),
      );
    } else {
      // แจ้งข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการบันทึกข้อมูล")),
      );
    }
  }

  // ส่งเลขล็อตโต้ไป API
  Future<bool> sendToDatabase(List<Map<String, dynamic>> numbersWithId) async {
    String apiUrl =
        'http://192.168.100.106:3000/api/lotto/insert'; // ปรับเป็น IP หรือ URL ของคุณ

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'numbers': numbersWithId}), // ส่งข้อมูลเป็น JSON
      );

      if (response.statusCode == 200) {
        print('Numbers successfully sent to the database!');
        return true;
      } else {
        print('Failed to send numbers: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ข้อผิดพลาดจาก API: ${response.body}")),
        );
        return false;
      }
    } catch (e) {
      print('Error sending data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ไม่สามารถเชื่อมต่อกับ API ได้")));
      return false;
    }
  }

  // ฟังก์ชันลบข้อมูลล็อตโต้
  Future<bool> deleteLottoNumbers() async {
    String apiUrl =
        'http://192.168.100.106:3000/api/lotto/delete'; // URL API ลบข้อมูล

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Numbers successfully deleted from the database!');
        return true;
      } else {
        print('Failed to delete numbers: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ข้อผิดพลาดจาก API: ${response.body}")),
        );
        return false;
      }
    } catch (e) {
      print('Error deleting data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ไม่สามารถเชื่อมต่อกับ API ได้")));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 181, 179, 179),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "สร้างชุดตัวเลข",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: generateLottoNumbers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 0, 150, 136),
                        ),
                        child: Text(
                          "สร้าง",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          bool success = await deleteLottoNumbers();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("ลบข้อมูลล็อตโต้เรียบร้อยแล้ว"),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          "ลบข้อมูล",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
