import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PurchasedPage extends StatefulWidget {
  final String userId; // รับ userId จากหน้าอื่น

  const PurchasedPage({super.key, required this.userId});

  @override
  State<PurchasedPage> createState() => _PurchasedPageState();
}

class LottoNumber {
  final int lottoID;
  final String number;
  final bool isWinner;
  final String? type; // เพิ่ม type

  LottoNumber({
    required this.lottoID,
    required this.number,
    required this.isWinner,
    this.type,
  });

  factory LottoNumber.fromJson(Map<String, dynamic> json) {
    return LottoNumber(
      lottoID: json['lottoID'],
      number: json['number'],
      isWinner: json['isWinner'] ?? false,
      type: json['type'], // ดึงค่า type จาก API
    );
  }
}

class _PurchasedPageState extends State<PurchasedPage> {
  List<LottoNumber> purchasedLottoNumbers = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPurchasedLottoNumbers();
  }

  Future<void> fetchPurchasedLottoNumbers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.100.106:3000/api/lotto/check-prize?userId=${widget.userId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          final List<LottoNumber> userPurchasedLotto = data
              .map<LottoNumber>((item) => LottoNumber.fromJson(item))
              .toList();

          setState(() {
            purchasedLottoNumbers = userPurchasedLotto;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                "API error: ${jsonResponse['message'] ?? 'Unknown error'}";
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
        errorMessage = "ไม่สามารถเชื่อมต่อกับ API ได้: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : purchasedLottoNumbers.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่มีหมายเลขที่ซื้อ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: purchasedLottoNumbers.length,
                        itemBuilder: (context, index) {
                          final lotto = purchasedLottoNumbers[index];
                          return Card(
                            color: lotto.isWinner
                                ? Colors.green.shade300
                                : Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: lotto.isWinner ? Colors.green.shade600 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              title: Text(
                                lotto.number,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: lotto.isWinner ? FontWeight.bold : FontWeight.normal,
                                  color: lotto.isWinner ? Colors.white : Colors.black,
                                ),
                              ),
                              subtitle: lotto.isWinner
                                  ? Text(
                                      'คุณถูกรางวัล: ${lotto.type}',
                                      style: TextStyle(color: Colors.white70, fontSize: 14),
                                    )
                                  : null,
                              trailing: lotto.isWinner
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
