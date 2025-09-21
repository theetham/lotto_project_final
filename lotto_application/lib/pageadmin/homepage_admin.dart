import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lotto_application/pageadmin/Account_page.dart';
import 'package:lotto_application/pageadmin/lotto_admin.dart';
import 'package:lotto_application/pageadmin/random_page.dart';
import 'package:lotto_application/pageadmin/setting_page.dart';

class HomePage_admin extends StatefulWidget {
  final String userId; // รับ userId จากหน้าอื่นๆ เช่น LoginPage

  const HomePage_admin({super.key, required this.userId});

  @override
  State<HomePage_admin> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage_admin> {
  int _selectedIndex = 0;
  int walletAmount = 0;
  bool isLoading = true; // Use this to track loading state
  String errorMessage = "";
  late final String userId; // เก็บ userId

  final List<Widget> _pages = [
    const LottoAdminPage(),
    RandomPage(),
    const SettingPage(),
  ];

  final List<String> _pageTitles = ['ชุดตัวเลข', 'สุ่มออกผลรางวัล', 'จัดการ'];

  // ฟังก์ชันเพื่อดึงข้อมูลยอดเงินจาก API
  Future<void> fetchWalletAmount() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.100.106:3000/api/lotto/customer/${widget.userId}",
        ),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success']) {
          setState(() {
            walletAmount = jsonData['data']['balance'] ?? 0;
            isLoading = false; // Set loading to false when data is fetched
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // เก็บค่า userId
    fetchWalletAmount(); // Fetch wallet amount when the page is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading
            ? const Text(
                "กำลังโหลดข้อมูล...",
              ) // Show this if data is still loading
            : Text(_pageTitles[_selectedIndex]), // Dynamically set the title
        backgroundColor: const Color(0xFF009688),
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
                  ) // Show a loading indicator when data is being fetched
                : Row(
                    children: [
                      Text(
                        "$walletAmount ฿", // Display wallet amount if loading is complete
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
                          // Navigate to WalletPage and pass userId
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Account_admin(
                                userId: int.parse(userId),
                              ), // Pass userId to WalletPage
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'ชุดตัวเลข',
            backgroundColor: Colors.teal,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: 'สุ่มออกผลรางวัล',
            backgroundColor: Colors.teal,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'จัดการ',
            backgroundColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}
