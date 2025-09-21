import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lotto_application/page/login.dart';

class WalletPage extends StatefulWidget {
  final String userId;

  const WalletPage({super.key, required this.userId});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String fullname = "";
  String phone = "";
  int walletAmount = 0;
  String role = "";
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      // ใช้ IP 10.0.2.2 สำหรับ Android Emulator
      final response = await http.get(Uri.parse("http://192.168.100.106:3000/api/lotto/customer/${widget.userId}"));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success']) {
          setState(() {
            fullname = jsonData['data']['fullname'] ?? "";
            phone = jsonData['data']['phone'] ?? "";
            walletAmount = jsonData['data']['balance'] ?? 0;
            role = jsonData['data']['role'] ?? "";
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("บัญชีผู้ใช้"),
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()), // แสดงตัวโหลด
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("บัญชีผู้ใช้"),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: Text(errorMessage, style: TextStyle(color: Colors.red))), // แสดงข้อความ error
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("บัญชีผู้ใช้"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("ออกจากระบบ"),
                  content: const Text("คุณต้องการออกจากระบบหรือไม่?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ยกเลิก"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
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
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 74, 74, 74),
            ),
            child: Text(
              "ยอดเงินในบัญชี: $walletAmount ฿", // แสดงยอดเงินที่ดึงมาจาก API
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
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
                  fullname.isEmpty ? "กำลังโหลด..." : fullname, // แสดงชื่อผู้ใช้
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  phone.isEmpty ? "กำลังโหลด..." : "เบอร์ $phone", // แสดงเบอร์โทร
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 2, 84, 177),
            ),
            child: Text(
              "Role: $role", // แสดง role ที่ดึงมาจาก API
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
