import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For @required if not using null safety

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Хэрэглэгчийн ID-г авах функц
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // --- Сагс (Cart) ---

  // Сагсанд бүтээгдэхүүн нэмэх
  Future<void> addProductToCart(String productId, int quantity) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to add to cart.");
      return;
    }

    // Хэрэглэгчийн сагсны collection-д хандах
    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final docRef = cartRef.doc(productId); // Бүтээгдэхүүн бүрийг өөрийн ID-гаар хадгална

    try {
      await docRef.set({
        'productId': productId,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(), // Серверийн цагийг хадгална
      }, SetOptions(merge: true)); // Хэрэв тухайн бүтээгдэхүүн сагсанд байвал тоо хэмжээг шинэчилнэ
      debugPrint("Product $productId added/updated in cart for user $userId");
    } catch (e) {
      debugPrint("Error adding product to cart: $e");
    }
  }

  // Сагснаас бүтээгдэхүүн хасах
  Future<void> removeProductFromCart(String productId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to remove from cart.");
      return;
    }

    final cartRef = _db.collection('users').doc(userId).collection('cart');
    final docRef = cartRef.doc(productId);

    try {
      await docRef.delete();
      debugPrint("Product $productId removed from cart for user $userId");
    } catch (e) {
      debugPrint("Error removing product from cart: $e");
    }
  }

  // Хэрэглэгчийн сагсыг авах (Stream ашиглан realtime update авах)
  Stream<Map<String, int>> getUserCart() {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to get cart.");
      return Stream.value({}); // Хоосон stream буцаана
    }

    return _db
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      Map<String, int> cartItems = {};
      for (var doc in snapshot.docs) {
        cartItems[doc.id] = doc['quantity'] as int;
      }
      return cartItems;
    });
  }

  // --- Дуртай бүтээгдэхүүн (Favorites) ---

  // Дуртай бүтээгдэхүүнд нэмэх
  Future<void> addProductToFavorites(String productId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to add to favorites.");
      return;
    }

    final favRef = _db.collection('users').doc(userId).collection('favorites');
    final docRef = favRef.doc(productId);

    try {
      await docRef.set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("Product $productId added to favorites for user $userId");
    } catch (e) {
      debugPrint("Error adding product to favorites: $e");
    }
  }

  // Дуртай бүтээгдэхүүнээс хасах
  Future<void> removeProductFromFavorites(String productId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to remove from favorites.");
      return;
    }

    final favRef = _db.collection('users').doc(userId).collection('favorites');
    final docRef = favRef.doc(productId);

    try {
      await docRef.delete();
      debugPrint("Product $productId removed from favorites for user $userId");
    } catch (e) {
      debugPrint("Error removing product from favorites: $e");
    }
  }

  // Хэрэглэгчийн дуртай бүтээгдэхүүнүүдийг авах (Stream ашиглан realtime update авах)
  Stream<List<String>> getUserFavorites() {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to get favorites.");
      return Stream.value([]); // Хоосон stream буцаана
    }

    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // --- Коммент (Comment) ---

  // Коммент нэмэх
  Future<void> addComment(String productId, String commentText, String userName) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      debugPrint("Error: User not logged in to add comment.");
      return;
    }

    try {
      await _db.collection('products').doc(productId).collection('comments').add({
        'userId': userId,
        'userName': userName, // Коммент бичсэн хэрэглэгчийн нэр
        'commentText': commentText,
        'timestamp': FieldValue.serverTimestamp(), // Коммент бичсэн цаг
      });
      debugPrint("Comment added for product $productId by user $userId");
    } catch (e) {
      debugPrint("Error adding comment: $e");
    }
  }

  // Бүтээгдэхүүний комментуудыг унших (Stream ашиглан realtime update авах)
  Stream<List<Map<String, dynamic>>> getProductComments(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('comments')
        .orderBy('timestamp', descending: false) // Цаг хугацаагаар нь эрэмбэлнэ
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}