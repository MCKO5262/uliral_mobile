import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Firebase import

import '../provider/globalProvider.dart';
import 'bags_page.dart';
import 'shop_page.dart';
import 'favorite_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // ✅ Firebase-ээр хэрэглэгчийг шалгах
  List<Widget> get Pages => [
        const ShopPage(),
        BagsPage(),
        const FavoritePage(),
        FirebaseAuth.instance.currentUser != null
            ? const ProfilePage()
            : const LoginPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Consumer<Global_provider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Pages[provider.currentIdx],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: provider.currentIdx,
            onTap: provider.changeCurrentIdx,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shop),
                label: 'Shopping',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_basket),
                label: 'Bag',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
