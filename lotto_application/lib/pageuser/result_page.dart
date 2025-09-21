import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Map<String, List<String>> winners = {};
  bool isLoading = false;

  final String apiBase = "http://192.168.100.106:3000/api/lotto";

  @override
  void initState() {
    super.initState();
    getWinners(); // โหลดผลรางวัลเมื่อเปิดหน้า
  }

  Future<void> getWinners() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$apiBase/winner"));
      final data = json.decode(res.body);

      if (data["success"] == true) {
        setState(() {
          winners = (data["winners"] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          );
        });
      } else {
        showSnack("ไม่สามารถโหลดผลรางวัลได้");
      }
    } catch (e) {
      showSnack("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้");
    }
    setState(() => isLoading = false);
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String labelPrize(String key) {
    switch (key) {
      case "1":
        return "รางวัลที่ 1";
      case "2":
        return "รางวัลที่ 2";
      case "3":
        return "รางวัลที่ 3";
      case "last3":
        return "เลขท้าย 3 ตัว";
      case "last2":
        return "เลขท้าย 2 ตัว";
      default:
        return "รางวัล $key";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ผลการออกรางวัล", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : winners.isEmpty
            ? const Center(
                child: Text("ยังไม่มีผลรางวัล", style: TextStyle(fontSize: 16)),
              )
            : ListView(
                children: winners.entries.expand((entry) {
                  final prizeKey = entry.key;
                  final numbers = entry.value;
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        labelPrize(prizeKey),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...numbers.map(
                      (num) => Card(
                        color: Colors.teal[100],
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            num,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ];
                }).toList(),
              ),
      ),
    );
  }
}
