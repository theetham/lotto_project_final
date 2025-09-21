import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lotto_application/page/login.dart'; // Import the LoginPage

class Account_admin extends StatefulWidget {
  final int userId; // รับ userId ที่ส่งจาก HomePage_admin

  const Account_admin({super.key, required this.userId});

  @override
  _AccountadminState createState() => _AccountadminState();
}

class _AccountadminState extends State<Account_admin> {
  String fullname = "";
  String phone = "";
  int balance = 0; // ใช้ตัวแปรเป็น int
  String role = ""; // เพิ่มตัวแปรสำหรับ role
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchUserData(); // ดึงข้อมูลเมื่อเริ่มหน้า
  }

  // ฟังก์ชันดึงข้อมูลผู้ใช้จาก API
  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.100.106:3000/api/lotto/customer/${widget.userId}",
        ),
      );

      // เช็คว่าการเชื่อมต่อ API สำเร็จหรือไม่
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("Response Data: $jsonData"); // พิมพ์ข้อมูลทั้งหมดที่ได้รับจาก API

        if (jsonData['success']) {
          setState(() {
            fullname = jsonData['data']['fullname'] ?? "ไม่มีข้อมูล";
            phone = jsonData['data']['phone'] ?? "ไม่มีข้อมูล";

            // ตรวจสอบว่า balance มีค่าเป็นตัวเลขหรือไม่
            var balanceValue = jsonData['data']['balance'];
            if (balanceValue != null) {
              // ถ้า balance เป็นตัวเลขหรือสามารถแปลงเป็นตัวเลขได้
              balance = int.tryParse(balanceValue.toString()) ?? 0;
            } else {
              balance = 0; // ถ้า balance ไม่มีค่า หรือเป็น null
            }

            role =
                jsonData['data']['role'] ??
                "ไม่มีข้อมูล"; // ตรวจสอบว่าได้ค่า role หรือไม่
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = jsonData['message'] ?? "ไม่พบข้อมูลสมาชิก";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "เกิดข้อผิดพลาด: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e";
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันสำหรับออกจากระบบ
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ออกจากระบบ"),
        content: const Text("คุณต้องการออกจากระบบหรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // ปิด dialog
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ), // นำทางไปหน้า LoginPage
                (route) => false, // ลบทุก route ใน stack
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ออกจากระบบสำเร็จ ✅")),
              );
            },
            child: const Text("ออกจากระบบ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("บัญชีผู้ใช้"),
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("บัญชีผู้ใช้"),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: Text(errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("บัญชีผู้ใช้"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout, // เรียกใช้ฟังก์ชันออกจากระบบ
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงยอดเงินที่ดึงจาก API
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 74, 74, 74),
              ),
              child: Text(
                "ยอดเงินในบัญชี: $balance ฿",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            // แสดงชื่อและเบอร์โทรศัพท์
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 2, 84, 177),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fullname, // แสดงชื่อ
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    "เบอร์ $phone", // แสดงเบอร์โทร
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            // แสดง role ด้านบนยอดเงิน
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 2, 84, 177),
              ),
              child: Text(
                "Role: $role", // แสดง role ที่ดึงมาจาก API
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
