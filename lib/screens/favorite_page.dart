import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/screens/product_detail.dart';


class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<Global_provider>(context); 
    final favorites = provider.favoriteItems;               
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Page')),

      body: Column(
        children: [
          Expanded(
            child: favorites.isEmpty
                ? const Center(child: Text('No favorite items.'))

                : ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      ProductModel product = favorites[index];

                      return ListTile(
                        leading: Image.network(product.image ?? ''), 
                        title: Text(product.title ?? ''),           
                        subtitle: Text('₮${product.price?.toStringAsFixed(2) ?? ''}'),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shop, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Product_detail(product),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () {
                                provider.toggleFavorite(product); // ❤️ хасах
                              },
                            ),
                          ],
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
