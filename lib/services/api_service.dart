import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/product_model.dart';

class ApiService {
  Future<List<ProductModel>> fetchProducts() async {
    final url = Uri.parse('https://fakestoreapi.com/products');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return ProductModel.fromList(data);
    } else {
      throw Exception('Failed to load products');
    }
  }
}
