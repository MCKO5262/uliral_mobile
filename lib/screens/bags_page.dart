import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/provider/globalProvider.dart';

class BagsPage extends StatelessWidget {
  BagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Global_provider>(
      builder: (context, provider, child) {
        double total = provider.cartItems.fold(
          0,
          (sum, item) => sum + (item.price! * item.count!),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
          ),
          body: provider.cartItems.isEmpty
              ? const Center(child: Text('Сагс хоосон байна'))
              : ListView.builder(
                  itemCount: provider.cartItems.length,
                  itemBuilder: (context, index) {
                    final product = provider.cartItems[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Image.network(
                          product.image!,
                          width: 50,
                          height: 50,
                        ),
                        title: Text(product.title!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Үнэ: \$${product.price}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    provider.decreaseCount(product);
                                  },
                                ),
                                Text('${product.count}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    provider.increaseCount(product);
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'Нийт: \$${(product.price! * product.count!).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Нийт дүн: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Захиалга баталгаажуулах логик
                  },
                  child: const Text('Buy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
