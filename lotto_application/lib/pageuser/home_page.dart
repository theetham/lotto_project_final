import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'buy_lotto_page.dart';
import 'purchased_page.dart';
import 'result_page.dart';
import 'wallet_page.dart';

class HomePage extends StatefulWidget {
  final String userId; // รับ userId จาก LoginPage

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final String userId;
  int walletAmount = 0; // เพื่อเก็บยอดเงิน
  bool isLoading = true; // ตัวแปรเช็คสถานะการโหลดข้อมูล
  String errorMessage = ""; // ใช้สำหรับเก็บข้อความ error หากเกิดปัญหา

  late List<Widget>
  _pages; // ประกาศ _pages ที่นี่เพื่อให้สามารถเข้าถึงได้ทั่วทั้งคลาส

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // เก็บค่า userId
    fetchWalletAmount();
    // กำหนด _pages หลังจากที่มี userId แล้ว
    _pages = [
      BuyLottoPage(
        userId: userId,
        onBalanceUpdated: // กำหนดฟังก์ชันให้ buy_lotto_page เรียกฟังก์ชัน onBalanceUpdated เมื่อ buy_lotto_page ซื้อหวยเสร็จ
            fetchWalletAmount, //  จากนั้นรีเฟรชยอดเงินผู้ใช้
      ), // ส่ง userId ไปที่ BuyLottoPage
      PurchasedPage(userId: userId),
      ResultPage(),
    ];
  }

  Future<void> fetchWalletAmount() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.100.106:3000/api/lotto/customer/$userId"),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success']) {
          setState(() {
            walletAmount =
                jsonData['data']['balance'] ?? 0; // เก็บยอดเงินที่ดึงมา
            isLoading = false; // เปลี่ยนสถานะการโหลดเป็น false
          });
        } else {
          setState(() {
            errorMessage =
                jsonData['message'] ?? "ไม่พบข้อมูลสมาชิก"; // แสดงข้อความ error
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
        errorMessage =
            "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e"; // แสดงข้อผิดพลาดในการเชื่อมต่อ
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'ซื้อหวย'
              : _selectedIndex == 1
              ? 'หวยที่ซื้อแล้ว'
              : 'ผลล็อตโต้',
        ),
        backgroundColor: Colors.teal,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  ) // แสดงโปรเกรสอินดิเคเตอร์ขณะโหลดข้อมูล
                : Row(
                    children: [
                      Text(
                        "$walletAmount ฿", // แสดงยอดเงิน
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WalletPage(
                                userId: userId, // ส่ง userId ไปที่ WalletPage
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
      body: _pages[_selectedIndex], // ใช้ _pages ที่ประกาศไว้
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'ซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'ซื้อแล้ว',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'ผล'),
        ],
      ),
    );
  }
}
