import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lotto_application/page/login.dart';

class LottoNumber {
  final int lottoID;
  final String number;
  final bool isWinner;
  final String? type;
  final int prizeAmount;

  LottoNumber({
    required this.lottoID,
    required this.number,
    required this.isWinner,
    this.type,
    required this.prizeAmount,
  });

  factory LottoNumber.fromJson(Map<String, dynamic> json) {
    final String? type = json['type'];
    int amount = 0;
    if (type == "รางวัลที่ 1")
      amount = 6000000;
    else if (type == "รางวัลที่ 2")
      amount = 500000;
    else if (type == "รางวัลที่ 3")
      amount = 100000;
    else if (type == "รางวัลเลขท้าย 3 ตัว")
      amount = 5000;
    else if (type == "รางวัลเลขท้าย 2 ตัว")
      amount = 2000;

    return LottoNumber(
      lottoID: json['lottoID'],
      number: json['number'],
      isWinner: json['isWinner'] ?? false,
      type: type,
      prizeAmount: amount,
    );
  }
}

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

  List<LottoNumber> winningLottoNumbers = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchWinningLotto();
  }

  Future<void> fetchUserData() async {
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

  Future<void> fetchWinningLotto() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.100.106:3000/api/lotto/check-prize?userId=${widget.userId}",
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          final List<dynamic> data = jsonResponse['data'];
          final List<LottoNumber> allNumbers = data
              .map<LottoNumber>((item) => LottoNumber.fromJson(item))
              .toList();

          setState(() {
            winningLottoNumbers = allNumbers
                .where((lotto) => lotto.isWinner)
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching winning lotto: $e");
    }
  }

  Future<void> claimPrize(LottoNumber lotto) async {
    try {
      final response = await http.delete(
        Uri.parse("http://192.168.100.106:3000/api/lotto/claim-prize"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'lottoID': lotto.lottoID,
          'prizeAmount': lotto.prizeAmount,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          setState(() {
            walletAmount += lotto.prizeAmount;
            winningLottoNumbers.remove(lotto); // ลบหมายเลขที่ขึ้นเงินแล้ว
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ขึ้นเงินสำเร็จและลบหมายเลขล็อตโต้แล้ว")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("บัญชีผู้ใช้")),
        body: Center(
          child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("บัญชีผู้ใช้"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("ออกจากระบบสำเร็จ")));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullname,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "เบอร์โทร: $phone",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "บทบาท: $role",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "ยอดเงิน: $walletAmount ฿",
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Winning numbers Section
            const Text(
              "หมายเลขที่ถูกรางวัล",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            winningLottoNumbers.isEmpty
                ? const Text("ยังไม่มีหมายเลขถูกรางวัล", style: TextStyle(fontSize: 16, color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: winningLottoNumbers.length,
                    itemBuilder: (context, index) {
                      final lotto = winningLottoNumbers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.green.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          title: Text(
                            "${lotto.number}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            "ถูกรางวัล: ${lotto.type}\nเงินรางวัล ${lotto.prizeAmount} บาท",
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              claimPrize(lotto); // เรียกฟังก์ชัน claimPrize
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("ขึ้นเงิน"),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}