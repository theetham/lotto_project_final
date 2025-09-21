import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LottoAdminPage extends StatefulWidget {
  const LottoAdminPage({super.key});

  @override
  State<LottoAdminPage> createState() => _LottoAdminPageState();
}

class _LottoAdminPageState extends State<LottoAdminPage> {
  List<String> lottoNumbers = [];
  String searchQuery = "";
  Timer? _debounce;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLottoNumbers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

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

        // สมมุติว่าข้อมูลที่ได้มีรูปแบบ [{number: "123456", status: 0}, {...}, ...]
        setState(() {
          lottoNumbers = data
              .map<String>((item) => item['number'].toString())
              .toList();
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
    // กรองตัวเลขตามคำค้นหา
    final filteredNumbers = lottoNumbers
        .where((number) => number.contains(searchQuery))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (query) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();

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
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filteredNumbers.isEmpty)
            const Expanded(child: Center(child: Text("ไม่พบหมายเลขที่ค้นหา")))
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredNumbers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(
                        filteredNumbers[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
