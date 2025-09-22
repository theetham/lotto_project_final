import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyLottoPage extends StatefulWidget {
  final String userId; // รับ userId จาก HomePage
  final VoidCallback? onBalanceUpdated; // ฟังก์ชัน callback เมื่อตัวเลข balance อัพเดตแล้ว

  const BuyLottoPage({
    super.key,
    required this.userId,
    this.onBalanceUpdated,
  });

  @override
  State<BuyLottoPage> createState() => _BuyLottoPageState();
}

class _BuyLottoPageState extends State<BuyLottoPage> {
  List<String> lottoNumbers = []; // รายการเลขล็อตโต้ทั้งหมด
  late List<bool> selected; // สถานะเลือกเลขล็อตโต้ (true = เลือก, false = ไม่เลือก)
  String searchQuery = ""; // คำค้นหาเลขล็อตโต้
  Timer? _debounce; // ตัวจับเวลาสำหรับดีเบาท์ (debounce) การค้นหา
  bool isLoading = false; // สถานะโหลดข้อมูล
  String? errorMessage; // เก็บข้อความแสดงข้อผิดพลาด
  double totalCost = 0; // ยอดรวมราคาทั้งหมดที่เลือก

  late String userId; // เก็บ userId ที่รับมาจากหน้า HomePage

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // เก็บค่า userId จาก widget
    selected = List.filled(lottoNumbers.length, false); // สร้าง list สถานะการเลือก (เริ่มต้นไม่เลือก)
    fetchLottoNumbers(); // เรียกดึงข้อมูลเลขล็อตโต้จาก API
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

        // กรองเฉพาะเลขที่ status = 0 (ยังไม่ถูกซื้อ)
        setState(() {
          lottoNumbers = data
              .where((item) => item['status'] == 0)
              .map<String>((item) => item['number'].toString())
              .toList();

          selected = List.filled(lottoNumbers.length, false); // รีเซ็ตสถานะเลือก
          totalCost = 0; // รีเซ็ทยอดรวม
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

  // ฟังก์ชันอัพเดตสถานะเจ้าของเลขล็อตโต้และหักเงินจากบัญชีผู้ใช้
  Future<void> updateLottoOwnerAndBalance(List<String> selectedNumbers) async {
    try {
      // อัพเดตสถานะของเลขล็อตโต้ในฐานข้อมูล
      final response = await http.put(
        Uri.parse('http://192.168.100.106:3000/api/lotto/update-owner'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'selectedNumbers': selectedNumbers,
          'userId': userId,
          'status': 1, // เปลี่ยนสถานะเป็น 1 = ถูกซื้อแล้ว
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          // รีเฟรชข้อมูลล็อตโต้หลังอัพเดต
          fetchLottoNumbers();

          // หักเงินจากบัญชีผู้ใช้
          updateUserBalance(totalCost);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ซื้อเลขล็อตโต้เรียบร้อย")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ไม่สามารถซื้อเลขล็อตโต้ได้")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการซื้อ")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถเชื่อมต่อกับ API ได้")),
      );
    }
  }

  // ฟังก์ชันอัพเดตยอดเงินผู้ใช้หลังซื้อเลข
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
          // เรียก callback ถ้าไม่เป็น null
          widget.onBalanceUpdated?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("หักเงินจากบัญชีเรียบร้อย")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ไม่สามารถหักเงินจากบัญชีได้")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการหักเงิน")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถเชื่อมต่อกับ API ได้")),
      );
    }
  }

  // ฟังก์ชันคำนวณยอดรวมราคาจากเลขที่เลือก
  void updateTotalCost() {
    double newTotal = 0;

    for (int i = 0; i < lottoNumbers.length; i++) {
      if (selected[i]) {
        newTotal += 100; // ราคาเลขแต่ละตัว 100 บาท
      }
    }

    setState(() {
      totalCost = newTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    // กรองหมายเลขล็อตโต้ตามคำค้นหา (searchQuery)
    final filteredLottoNumbers = lottoNumbers
        .where((number) => number.contains(searchQuery))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 16),

        // หัวข้อ
        const Text(
          "เลือกเลขที่ต้องการซื้อ",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),

        // ช่องค้นหาเลขล็อตโต้
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (query) {
              // ยกเลิกดีเบาท์เดิมถ้ามี
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              // ตั้งเวลาดีเบาท์ 500 ms ก่อนอัพเดตคำค้นหา
              _debounce = Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  searchQuery = query;
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

        // ถ้าไม่พบหมายเลขที่ค้นหา
        else if (filteredLottoNumbers.isEmpty)
          const Expanded(child: Center(child: Text("ไม่พบหมายเลขที่ค้นหา")))

        // แสดงรายการหมายเลขล็อตโต้ที่กรองแล้ว
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

                    // Checkbox ให้ผู้ใช้เลือกเลขล็อตโต้
                    trailing: Checkbox(
                      value: selected[lottoNumbers.indexOf(filteredLottoNumbers[index])],
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          selected[lottoNumbers.indexOf(filteredLottoNumbers[index])] = value!;
                        });
                        updateTotalCost(); // อัพเดตยอดรวมเมื่อเลือกเลข
                      },
                    ),
                  ),
                );
              },
            ),
          ),

        // ส่วนแสดงยอดรวมและปุ่มซื้อ
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // แสดงยอดรวมราคา
              Text(
                "ยอดรวม: ฿$totalCost",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // ปุ่มซื้อเลขล็อตโต้ที่เลือกไว้
              ElevatedButton.icon(
                onPressed: () {
                  // หาเลขล็อตโต้ที่ถูกเลือกจริง ๆ
                  final selectedNumbers = lottoNumbers
                      .where((number) => selected[lottoNumbers.indexOf(number)])
                      .toList();

                  // ถ้ามีเลขถูกเลือก
                  if (selectedNumbers.isNotEmpty) {
                    updateLottoOwnerAndBalance(selectedNumbers);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("กรุณาเลือกหมายเลขก่อน")),
                    );
                  }
                },
                icon: const Icon(Icons.shopping_cart), // ไอคอนรถเข็น
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
