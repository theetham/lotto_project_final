import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyLottoPage extends StatefulWidget {
  final String userId; // รับ userId จาก HomePage
  final VoidCallback?
  onBalanceUpdated; // ประกาศตัวแปรเก็บฟังก์ชันจากหน้า home_page

  const BuyLottoPage({
    super.key,
    required this.userId,
    this.onBalanceUpdated, //รับค่าและเก็บไว้ในตัวแปร onBalanceUpdated
  });

  @override
  State<BuyLottoPage> createState() => _BuyLottoPageState();
}

class _BuyLottoPageState extends State<BuyLottoPage> {
  List<String> lottoNumbers = []; // List to hold fetched lotto numbers
  late List<bool> selected; // To keep track of selected lotto numbers
  String searchQuery = ""; // For search query
  Timer? _debounce; // Timer for debouncing search
  bool isLoading = false; // To show loading indicator
  String? errorMessage; // To display error messages
  double totalCost = 0; // To keep track of the total cost

  late String userId; // รับ userId จาก HomePage

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // เก็บค่า userId จาก widget
    selected = List.filled(lottoNumbers.length, false);
    fetchLottoNumbers(); // Fetch lotto numbers when the page loads
  }

  // ฟังก์ชันดึงหมายเลขล็อตโต้จาก API
  Future<void> fetchLottoNumbers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.106:3000/api/lotto/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];

        // กรองเฉพาะหมายเลขที่ status = 0
        setState(() {
          lottoNumbers = data
              .where((item) => item['status'] == 0) // กรองเฉพาะที่ status = 0
              .map<String>((item) => item['number'].toString())
              .toList();
          selected = List.filled(
            lottoNumbers.length,
            false,
          ); // รีเซ็ทสถานะการเลือก
          totalCost = 0; // รีเซ็ทยอดเงินเมื่อดึงข้อมูลใหม่
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

  // ฟังก์ชันอัพเดตสถานะและเจ้าของของเลขล็อตโต้ พร้อมกับหักเงินจากบัญชีผู้ใช้
  Future<void> updateLottoOwnerAndBalance(List<String> selectedNumbers) async {
    try {
      // อัพเดตสถานะของเลขล็อตโต้ในฐานข้อมูล
      final response = await http.put(
        Uri.parse('http://192.168.100.106:3000/api/lotto/update-owner'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'selectedNumbers': selectedNumbers,
          'userId': userId, // ส่ง userId ไปพร้อมกับ selectedNumbers
          'status': 1, // เปลี่ยน status เป็น 1 เมื่อซื้อ
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // รีเฟรชข้อมูลล็อตโต้หลังจากอัพเดต
          fetchLottoNumbers();

          // เรียกฟังก์ชันเพื่อลดยอดเงินจากบัญชี
          updateUserBalance(totalCost); // หักเงินจากบัญชีผู้ใช้

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("ซื้อเลขล็อตโต้เรียบร้อย")));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("ไม่สามารถซื้อเลขล็อตโต้ได้")));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการซื้อ")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ไม่สามารถเชื่อมต่อกับ API ได้")));
    }
  }

  // ฟังก์ชันอัพเดตยอดเงินของผู้ใช้หลังจากซื้อ
  Future<void> updateUserBalance(double totalCost) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.100.106:3000/api/user/update-balance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': totalCost, // จำนวนเงินที่ต้องหัก
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // ตรวจสอบว่าฟังก์ชันนี้ไม่เป็น null ก่อน แล้วถึงเรียก onBalanceUpdated จากหน้า home_page
          widget.onBalanceUpdated?.call();
          // การหักเงินสำเร็จ
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("หักเงินจากบัญชีเรียบร้อย")));
        } else {
          // ถ้า API ส่งกลับว่าไม่สำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ไม่สามารถหักเงินจากบัญชีได้")),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการหักเงิน")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ไม่สามารถเชื่อมต่อกับ API ได้")));
    }
  }

  // คำนวณ total cost
  void updateTotalCost() {
    double newTotal = 0;
    for (int i = 0; i < lottoNumbers.length; i++) {
      if (selected[i]) {
        newTotal += 100; // ราคาใบละ 100
      }
    }
    setState(() {
      totalCost = newTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    // กรองหมายเลขล็อตโต้ตามคำค้นหา
    final filteredLottoNumbers = lottoNumbers
        .where((number) => number.contains(searchQuery))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          "เลือกเลขที่ต้องการซื้อ",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (query) {
              // ยกเลิกการดีเบาท์เดิมถ้ามี
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              // ตั้งเวลาใหม่สำหรับดีเบาท์
              _debounce = Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  searchQuery = query; // อัพเดตคำค้นหาหลังจากดีเบาท์
                });
              });
            },
            decoration: InputDecoration(
              labelText: "ค้นหาหมายเลข",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        // แสดงข้อความข้อผิดพลาดถ้ามี
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        // แสดงวงกลมโหลดขณะกำลังดึงข้อมูล
        if (isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        // ถ้าไม่พบผลลัพธ์หลังการกรอง
        else if (filteredLottoNumbers.isEmpty)
          const Expanded(child: Center(child: Text("ไม่พบหมายเลขที่ค้นหา")))
        // แสดงรายการหมายเลขล็อตโต้
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredLottoNumbers.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(
                      filteredLottoNumbers[index],
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: Checkbox(
                      value:
                          selected[lottoNumbers.indexOf(
                            filteredLottoNumbers[index],
                          )],
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          selected[lottoNumbers.indexOf(
                                filteredLottoNumbers[index],
                              )] =
                              value!;
                        });
                        updateTotalCost(); // อัพเดตค่า total cost เมื่อเลือกเลข
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "ยอดรวม: ฿$totalCost", // แสดงยอดรวม
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  // ค้นหาหมายเลขล็อตโต้ที่ถูกเลือก
                  final selectedNumbers = lottoNumbers
                      .where((number) => selected[lottoNumbers.indexOf(number)])
                      .toList();

                  // เรียกฟังก์ชันเพื่ออัพเดตสถานะ
                  if (selectedNumbers.isNotEmpty) {
                    updateLottoOwnerAndBalance(
                      selectedNumbers,
                    ); // ส่ง userId ไปพร้อมกับ selectedNumbers และหักเงิน
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("กรุณาเลือกหมายเลขก่อน")),
                    );
                  }
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text(
                  "ซื้อที่เลือกไว้",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
