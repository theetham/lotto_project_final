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
  List<Map<String, dynamic>> numbersWithId = [];

  // สุ่มเลขล็อตโต้
  Future<void> generateLottoNumbers() async {
    Random random = Random();
    List<Map<String, dynamic>> generatedNumbers = [];

    for (int i = 1; i <= 100; i++) {
      int firstPart = random.nextInt(9000) + 1000;
      int secondPart = random.nextInt(100);
      String secondPartFormatted = secondPart.toString().padLeft(2, '0');
      String lottoNumber = '$firstPart$secondPartFormatted';

      if (lottoNumber.isNotEmpty) {
        generatedNumbers.add({
          'lottoID': i,
          'number': lottoNumber,
        });
      }
    }

    if (generatedNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่มีเลขล็อตโต้ที่สร้างได้")),
      );
      return;
    }

    bool success = await sendToDatabase(generatedNumbers);

    if (success) {
      setState(() {
        numbersWithId = generatedNumbers;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("บันทึกข้อมูลล็อตโต้เรียบร้อยแล้ว")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการบันทึกข้อมูล")),
      );
    }
  }

  // ส่งข้อมูลล็อตโต้ไปยัง API
  Future<bool> sendToDatabase(List<Map<String, dynamic>> numbersWithId) async {
    String apiUrl = 'http://192.168.100.106:3000/api/lotto/insert';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'numbers': numbersWithId}),
      );

      if (response.statusCode == 200) {
        print('Numbers successfully sent to the database!');
        return true;
      } else {
        print('Failed to send numbers: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }

  // ลบข้อมูลล็อตโต้
  Future<bool> deleteLottoNumbers() async {
    String apiUrl = 'http://192.168.100.106:3000/api/lotto/delete';

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          numbersWithId.clear();
        });

        return true;
      } else {
        print('Failed to delete numbers: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting data: $e');
      return false;
    }
  }

  // รีเซ็ตตัวเลขล็อตโต้ที่แสดงในแอป
  void resetLottoNumbers() {
    setState(() {
      numbersWithId.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("ข้อมูลล็อตโต้ถูกรีเซ็ตแล้ว")),
    );
  }

  // ✅ รีเซ็ตลูกค้าที่มี role = 'customer'
  Future<void> resetCustomer() async {
    String apiUrl = 'http://192.168.100.106:3000/api/lotto/reset-customer';

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("รีเซ็ตรายชื่อลูกค้าเรียบร้อยแล้ว")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ข้อผิดพลาดจาก API: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถเชื่อมต่อ API ได้")),
      );
    }
  }

  // รีเซ็ททั้งหมด (รวมทั้งการลบข้อมูลล็อตโต้และรีเซ็ตรายชื่อลูกค้า)
  Future<void> resetAll() async {
    // ลบข้อมูลล็อตโต้
    bool deleteSuccess = await deleteLottoNumbers();
    if (deleteSuccess) {
      // รีเซ็ตรายชื่อลูกค้า
      await resetCustomer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถลบข้อมูลล็อตโต้ได้")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            // สร้างเลขล็อตโต้
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
                              SnackBar(content: Text("ลบข้อมูลล็อตโต้เรียบร้อยแล้ว")),
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

            SizedBox(height: 16),

            // ✅ รีเซ็ตลูกค้าที่ role = 'customer'
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
                    "Reset Customer",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: resetCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(
                      "รีเซ็ต",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // ปุ่ม Reset All
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 152, 151, 151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: resetAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text(
                  "Reset All",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
