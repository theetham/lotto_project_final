import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lotto_application/model/request/customer_register_post_req.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullnameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final passCtl = TextEditingController();
  final balanceCtl = TextEditingController();

  //customers is default role//
  String selectedRole = "customer";

  Future<void> registerUser() async {
    final user = CustomerRegisterPostRequest(
      fullname: fullnameCtl.text,
      phone: phoneCtl.text,
      image: "", // อาจจะเป็น path หรือ base64 ถ้ามีรูป
      password: passCtl.text,
      role: selectedRole,
      balance: double.tryParse(balanceCtl.text) ?? 0.0,
    );

    var url = Uri.parse("http://192.168.100.106:3000/register"); // API Node.js
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: customerRegisterPostRequestToJson(user),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data["success"]) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกสำเร็จ ✅")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ผิดพลาด: ${data["message"]}")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ ❌")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text("ลงทะเบียนสมาชิกใหม่")),
    //     body: Padding(
    //       padding: const EdgeInsets.all(16),
    //       child: Column(
    //         children: [
    //           TextField(
    //             controller: fullnameCtl,
    //             decoration: const InputDecoration(hintText: "ชื่อ-สกุล"),
    //           ),
    //           TextField(
    //             controller: phoneCtl,
    //             decoration: const InputDecoration(hintText: "เบอร์โทร"),
    //           ),
    //           TextField(
    //             controller: balanceCtl,
    //             keyboardType: TextInputType.number,
    //             decoration: const InputDecoration(hintText: "จำนวนเงินเริ่มต้น"),
    //           ),
    //           TextField(
    //             controller: passCtl,
    //             obscureText: true,
    //             decoration: const InputDecoration(hintText: "รหัสผ่าน"),
    //           ),

    //           DropdownButtonFormField<String>(
    //             value: selectedRole,
    //             decoration: const InputDecoration(
    //               labelText: "เลือกบทบาท",
    //               border: OutlineInputBorder(),
    //             ),
    //             items: const [
    //               DropdownMenuItem(value: "customer", child: Text("Customer")),
    //               DropdownMenuItem(value: "admin", child: Text("Admin")),
    //             ],
    //             onChanged: (value) {
    //               setState(() {
    //                 selectedRole = value!;
    //               });
    //             },
    //           ),
    //           const SizedBox(height: 20),
    //           ElevatedButton(
    //             onPressed: registerUser,
    //             child: const Text("สมัครสมาชิก"),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัว
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF4EAAA5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Center(
                child: Text(
                  "ลงทะเบียน",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: fullnameCtl,
                    decoration: InputDecoration(
                      hintText: "ชื่อ-สกุล",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneCtl,
                    decoration: InputDecoration(
                      hintText: "เบอร์โทร",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: balanceCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "จำนวนเงิน",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TextField(
                  //   controller: usernameCtl,
                  //   decoration: InputDecoration(
                  //     hintText: "ชื่อผู้ใช้",
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(30),
                  //     ),
                  //     filled: true,
                  //     fillColor: Colors.white,
                  //   ),
                  // ),
                  // const SizedBox(height: 12),
                  TextField(
                    controller: passCtl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "รหัสผ่าน",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "ตัวเลือก : ลูกค้า/ผู้ดูแลระบบ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "customer",
                        child: Text("Customer"),
                      ),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EAAA5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("หากคุณเป็นสมาชิก "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
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
