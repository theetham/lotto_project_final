// To parse this JSON data, do
//
//     final customerRegisterPostRequest = customerRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

CustomerRegisterPostRequest customerRegisterPostRequestFromJson(String str) =>
    CustomerRegisterPostRequest.fromJson(json.decode(str));

String customerRegisterPostRequestToJson(CustomerRegisterPostRequest data) =>
    json.encode(data.toJson());

class CustomerRegisterPostRequest {
  String fullname;
  String phone;
  String image;
  String password;
  String role;
  double balance;

  CustomerRegisterPostRequest({
    required this.fullname,
    required this.phone,
    required this.image,
    required this.password,
    required this.role,
    required this.balance,
  });

  factory CustomerRegisterPostRequest.fromJson(Map<String, dynamic> json) =>
      CustomerRegisterPostRequest(
        fullname: json["fullname"],
        phone: json["phone"],
        image: json["image"],
        password: json["password"],
        role: json["role"],
        balance: (json["balance"] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "fullname": fullname,
    "phone": phone,
    "image": image,
    "password": password,
    "role": role,
    "balance": balance,
  };
}
