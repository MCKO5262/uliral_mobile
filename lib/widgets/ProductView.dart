import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/screens/product_detail.dart';
import '../models/product_model.dart';
import '../provider/globalProvider.dart';


class ProductViewShop extends StatelessWidget {
  final ProductModel data; // 📦

  const ProductViewShop(this.data, {super.key});

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Product_detail(data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<Global_provider>(context);  
    final isFav = provider.isFavorite(data);                

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onTap(context), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  height: 150.0,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(data.image ?? ''),
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      provider.toggleFavorite(data); // ❤️ дуртайд нэмэх/хасах
                    },
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : const Color.fromARGB(255, 90, 90, 90),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title ?? '',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '₮${data.price?.toStringAsFixed(2) ?? ''}',
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
