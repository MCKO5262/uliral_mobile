import 'package:flutter/material.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_app/services/api_service.dart'; // ✅ API service-г импортолсон

class Global_provider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ProductModel> products = [];
  List<ProductModel> cartItems = [];
  List<ProductModel> favoriteItems = [];

  int currentIdx = 0;

  Global_provider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToCartChanges();
        _listenToFavoriteChanges();
      } else {
        cartItems.clear();
        favoriteItems.clear();
        notifyListeners();
      }
    });
  }

  void _listenToCartChanges() {
    _firestoreService.getUserCart().listen((cartData) async {
      List<ProductModel> newCartItems = [];
      for (var entry in cartData.entries) {
        final productId = entry.key;
        final quantity = entry.value;

        ProductModel? foundProduct;
        try {
          foundProduct = products.firstWhere((p) => p.id.toString() == productId);
        } catch (e) {
          debugPrint("Product with ID $productId not found in local products list.");
          continue;
        }

        if (foundProduct != null) {
          foundProduct.count = quantity;
          newCartItems.add(foundProduct);
        }
      }
      cartItems = newCartItems;
      notifyListeners();
    });
  }

  void _listenToFavoriteChanges() {
    _firestoreService.getUserFavorites().listen((favoriteProductIds) async {
      List<ProductModel> newFavoriteItems = [];
      for (String productId in favoriteProductIds) {
        ProductModel? foundProduct;
        try {
          foundProduct = products.firstWhere((p) => p.id.toString() == productId);
        } catch (e) {
          debugPrint("Product with ID $productId not found in local products list for favorites.");
          continue;
        }

        if (foundProduct != null) {
          newFavoriteItems.add(foundProduct);
        }
      }
      favoriteItems = newFavoriteItems;
      notifyListeners();
    });
  }

  void setProducts(List<ProductModel> data) {
    products = data;
    notifyListeners();
  }

  void loadProductsFromApi() async {
    final api = ApiService();
    try {
      final data = await api.fetchProducts();
      setProducts(data);
    } catch (e) {
      debugPrint("Алдаа: $e");
    }
  }

  void addCartItems(ProductModel item) async {
    if (cartItems.any((p) => p.id == item.id)) {
      final existingItem = cartItems.firstWhere((p) => p.id == item.id);
      await _firestoreService.addProductToCart(item.id.toString(), existingItem.count + 1);
    } else {
      await _firestoreService.addProductToCart(item.id.toString(), 1);
    }
  }

  void toggleFavorite(ProductModel item) async {
    if (favoriteItems.any((p) => p.id == item.id)) {
      await _firestoreService.removeProductFromFavorites(item.id.toString());
    } else {
      await _firestoreService.addProductToFavorites(item.id.toString());
    }
  }

  bool isFavorite(ProductModel item) {
    return favoriteItems.any((p) => p.id == item.id);
  }

  void changeCurrentIdx(int idx) {
    currentIdx = idx;
    notifyListeners();
  }

  void increaseCount(ProductModel product) async {
    final newCount = (product.count) + 1;
    await _firestoreService.addProductToCart(product.id.toString(), newCount);
  }

  void decreaseCount(ProductModel product) async {
    final newCount = (product.count) - 1;
    if (newCount > 0) {
      await _firestoreService.addProductToCart(product.id.toString(), newCount);
    } else {
      await _firestoreService.removeProductFromCart(product.id.toString());
    }
  }
}
