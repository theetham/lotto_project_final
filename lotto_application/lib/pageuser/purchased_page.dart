import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PurchasedPage extends StatefulWidget {
  final String userId; // รับ userId จากหน้าอื่น

  const PurchasedPage({super.key, required this.userId});

  @override
  State<PurchasedPage> createState() => _PurchasedPageState();
}

class _PurchasedPageState extends State<PurchasedPage> {
  List<String> purchasedLottoNumbers =
      []; // ลิสต์ที่เก็บหมายเลขล็อตโต้ที่ผู้ใช้ซื้อแล้ว
  bool isLoading = false; // ตัวแปรบอกสถานะการโหลดข้อมูล
  String? errorMessage; // ตัวแปรสำหรับเก็บข้อความข้อผิดพลาด

  @override
  void initState() {
    super.initState();
    fetchPurchasedLottoNumbers(); // ดึงข้อมูลหมายเลขล็อตโต้ที่ผู้ใช้ซื้อ
  }

  // ฟังก์ชันดึงข้อมูลหมายเลขล็อตโต้ที่ผู้ใช้ซื้อ
  Future<void> fetchPurchasedLottoNumbers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.100.106:3000/api/lotto/buy_al?userId=${widget.userId}',
        ), // ส่ง userId ผ่าน query parameter
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];

        final userPurchasedLotto = data
            .map<String>((item) => item['number'].toString())
            .toList();

        setState(() {
          purchasedLottoNumbers = userPurchasedLotto;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "เกิดข้อผิดพลาด: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "ไม่สามารถเชื่อมต่อกับ API ได้";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หมายเลขที่ซื้อแล้ว'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              ) // แสดงวงกลมโหลดขณะโหลดข้อมูล
            : errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ) // ข้อความข้อผิดพลาด
            : purchasedLottoNumbers.isEmpty
            ? Center(
                child: Text(
                  'ไม่มีหมายเลขที่ซื้อ, หรือเจ้าของคือ: ${widget.userId}',
                ),
              ) // แสดง userId
            : ListView.builder(
                itemCount: purchasedLottoNumbers.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        purchasedLottoNumbers[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
