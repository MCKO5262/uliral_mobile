import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/services/firestore_service.dart'; // FirestoreService-г импортлох
import 'package:firebase_auth/firebase_auth.dart'; // Хэрэглэгчийн нэвтрэлтийн мэдээллийг ашиглах
import 'package:cloud_firestore/cloud_firestore.dart'; // Энэ мөрийг энд нэмээрэй!


// ignore: camel_case_types
class Product_detail extends StatefulWidget {
  final ProductModel product;
  const Product_detail(this.product, {super.key});

  @override
  State<Product_detail> createState() => _Product_detailState();
}

// ignore: camel_case_types
class _Product_detailState extends State<Product_detail> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  // Хэрэглэгчийн нэрийг авах функц (оноосон нэр байхгүй бол email эсвэл 'Anonymous' ашиглана)
  String _getCurrentUserName() {
    final user = _auth.currentUser;
    if (user != null) {
      return user.displayName ?? user.email ?? 'Anonymous';
    }
    return 'Anonymous';
  }

  // Коммент нэмэх функц
  void _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Коммент хоосон байж болохгүй!')),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Коммент бичихийн тулд нэвтрэх шаардлагатай.')),
      );
      return;
    }

    await _firestoreService.addComment(
      widget.product.id.toString(),
      commentText,
      _getCurrentUserName(),
    );

    _commentController.clear(); // Коммент бичсэний дараа text field-г цэвэрлэх
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Global_provider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.product.title!),
            actions: [
              IconButton(
                icon: Icon(
                  provider.isFavorite(widget.product) ? Icons.favorite : Icons.favorite_border,
                  color: provider.isFavorite(widget.product) ? Colors.red : null,
                ),
                onPressed: () {
                  provider.toggleFavorite(widget.product);
                },
              ),
            ],
          ),
          body: SingleChildScrollView( // Бүх контентийг SingleChildScrollView-д хийж гүйлгэх боломжтой болгох
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    widget.product.image!,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.product.title!,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.product.description!,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Үнэ: \$${widget.product.price}',
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 30),

                // --- Коммент хэсэг ---
                const Text(
                  'Сэтгэгдлүүд',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                // Коммент бичих хэсэг
                if (_auth.currentUser != null) 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Сэтгэгдэл бичих...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addComment,
                          child: const Text('Илгээх'),
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Сэтгэгдэл бичихийн тулд нэвтэрнэ үү.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),

                // Комментуудыг харуулах хэсэг (StreamBuilder ашиглан realtime update авах)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getProductComments(widget.product.id.toString()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Алдаа гарлаа: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Энэ бүтээгдэхүүнд сэтгэгдэл алга байна.'),
                        ),
                      );
                    }

                    final comments = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true, // ListView-г дотор нь байрлуулах
                      physics: const NeverScrollableScrollPhysics(), // ListView-ийн гүйлгэлтийг идэвхгүй болгох
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final timestamp = comment['timestamp'] as Timestamp?;
                        final formattedTime = timestamp != null
                            ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute}'
                            : 'Огноогүй';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment['userName'] ?? 'Нэргүй хэрэглэгч',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(comment['commentText'] ?? ''),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              provider.addCartItems(widget.product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.product.title} сагсанд нэмэгдлээ!')),
              );
            },
            child: const Icon(Icons.shopping_cart),
          ),
        );
      },
    );
  }
}