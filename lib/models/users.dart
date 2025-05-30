import 'dart:convert';              
import 'package:flutter/services.dart'; 


class UserModel {
  final int id;
  final String username;
  final String password;
  final String email;
  final String phone;
  final String firstname;
  final String lastname;
  final String city;


  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.phone,
    required this.firstname,
    required this.lastname,
    required this.city,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      email: json['email'],
      phone: json['phone'],
      firstname: json['name']['firstname'],
      lastname: json['name']['lastname'],
      city: json['address']['city'],
    );
  }
}

//  Нэвтэрсэнтөлөв
class UserSession {
  static UserModel? currentUser;


  static bool get isLoggedIn => currentUser != null;

  static Future<bool> login(String username, String password) async {

    final String res = await rootBundle.loadString('assets/users.json');
    final List<dynamic> data = jsonDecode(res); // JSON хөрвүүлэх

    // нэр  нууц үг
    for (var item in data) {
      if (item['username'] == username && item['password'] == password) {
        currentUser = UserModel.fromJson(item); 
        return true;
      }
    }

    return false;
  }


  static void logout() {
    currentUser = null; 
  }
}
