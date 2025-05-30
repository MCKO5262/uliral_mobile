import 'package:flutter/material.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/services/firestore_service.dart'; // FirestoreService-г импортлох
import 'package:firebase_auth/firebase_auth.dart'; // Хэрэглэгчийн нэвтрэлтийн мэдээллийг ашиглах

class Global_provider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService(); // FirestoreService-ийн instance үүсгэх
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instance үүсгэх

  List<ProductModel> products = [];
  // cartItems болон favoriteItems-г ProductModel биш, зөвхөн ID-гаар хадгалах нь хялбар.
  // Гэхдээ одоогийн бүтцээр нь ProductModel-оор хадгалж, харгалзах бүтээгдэхүүнийг API-аас татаж авах шаардлагатай болно.
  // Одоохондоо таны ProductModel-ээр үргэлжлүүлье.
  List<ProductModel> cartItems = [];
  List<ProductModel> favoriteItems = [];

  // BottomNavigation
  int currentIdx = 0;

  // Firebase Auth state-ийг сонсох listener
  // Хэрэглэгч нэвтрэх, гарах үед сагс болон favorites-г ачаалах/цэвэрлэхэд ашиглана.
  Global_provider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Хэрэглэгч нэвтэрсэн бол сагс болон favorites-г ачаална
        _listenToCartChanges();
        _listenToFavoriteChanges();
      } else {
        // Хэрэглэгч гарсан бол сагс болон favorites-г цэвэрлэнэ
        cartItems.clear();
        favoriteItems.clear();
        notifyListeners();
      }
    });
  }

  // Сагсны өөрчлөлтийг Firebase-ээс сонсох функц
  void _listenToCartChanges() {
    _firestoreService.getUserCart().listen((cartData) async {
      // cartData нь Map<String, int> productId -> quantity хэлбэртэй ирнэ.
      // Бидний ProductModel нь бүтэн мэдээлэлтэй байх ёстой тул,
      // API-аас бүтээгдэхүүний мэдээллийг дахин татах эсвэл local products жагсаалтаас хайх шаардлагатай.

      List<ProductModel> newCartItems = [];
      for (var entry in cartData.entries) {
        final productId = entry.key;
        final quantity = entry.value;

        // Одоогийн products жагсаалтаас бүтээгдэхүүнийг хайна
        ProductModel? foundProduct;
        try {
          foundProduct = products.firstWhere((p) => p.id.toString() == productId);
        } catch (e) {
          // Хэрэв products жагсаалтаас олохгүй бол API-аас дахин татах хэрэгтэй.
          // Одоохондоо энэ хэсгийг орхиё, учир нь та API-аас шууд татдаг болсон.
          // Ирээдүйд нэмж болно:
          // ProductModel? apiProduct = await ApiService().getProductById(productId);
          // if (apiProduct != null) {
          //   foundProduct = apiProduct;
          // }
          debugPrint("Product with ID $productId not found in local products list.");
          continue; // Олдсон бүтээгдэхүүнийг алгасна
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

  // Дуртай бүтээгдэхүүний өөрчлөлтийг Firebase-ээс сонсох функц
  void _listenToFavoriteChanges() {
    _firestoreService.getUserFavorites().listen((favoriteProductIds) async {
      // favoriteProductIds нь List<String> productId хэлбэртэй ирнэ.
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

  // Сагсанд нэмэх/хасах (Firestore-той синхрончлох)
  void addCartItems(ProductModel item) async {
    // Local state-ийг шинэчлэхийн оронд шууд Firestore руу хадгална.
    // Firestore-оос ирэх Stream нь Global_provider-ын cartItems-г шинэчилнэ.
    if (cartItems.any((p) => p.id == item.id)) {
      // Хэрэв сагсанд байгаа бол тоо хэмжээг нэмэгдүүлнэ эсвэл хасна.
      // Энэ нь UI дээрхи "cart" icon-г дарж сагсанд нэмэх үед 1-ээр нэмэгдүүлнэ гэсэн үг.
      // Таны одоогийн addCartItems логик нь remove хийдэг тул үүнийг өөрчлөх хэрэгтэй.
      // Жишээ нь: Хэрэв байгаа бол count-г нь нэмээд, байхгүй бол нэмэх.
      final existingItem = cartItems.firstWhere((p) => p.id == item.id);
      await _firestoreService.addProductToCart(item.id.toString(), existingItem.count! + 1);
    } else {
      // Сагсанд байхгүй бол шинээр нэмнэ. count-г 1-ээр эхлүүлнэ.
      await _firestoreService.addProductToCart(item.id.toString(), 1);
    }
  }

  // ❤️ Дуртай бүтээгдэхүүнийг солих (Firestore-той синхрончлох)
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

  // ➕ Сагсан доторх бүтээгдэхүүний тоог нэмэх (Firestore-той синхрончлох)
  void increaseCount(ProductModel product) async {
    final newCount = (product.count ?? 0) + 1;
    await _firestoreService.addProductToCart(product.id.toString(), newCount);
  }

  // ➖ Сагсан доторх бүтээгдэхүүний тоог хасах (Firestore-той синхрончлох)
  void decreaseCount(ProductModel product) async {
    final newCount = (product.count ?? 0) - 1;
    if (newCount > 0) {
      await _firestoreService.addProductToCart(product.id.toString(), newCount);
    } else {
      await _firestoreService.removeProductFromCart(product.id.toString());
    }
  }
}