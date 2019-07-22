import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/products.dart';
import 'package:shop_app/views/edit_product_page.dart';
import 'package:shop_app/views/orders_page.dart';
import 'package:shop_app/views/user_products_page.dart';

import 'helpers/custom_route.dart';
import 'providers/auth.dart';
import 'views/auth-page.dart';
import 'views/cart_page.dart';
import 'views/product_detail_page.dart';
import 'views/products_overview_page.dart';
import 'providers/orders.dart';

import 'providers/cart.dart';
import 'views/splash-page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
          builder: (context, auth, previousProducts) => Products(
            auth.token,
            previousProducts == null ? [] : previousProducts.items,
            auth.userId,
          ),
        ),
        ChangeNotifierProvider.value(
          value: Cart(),
        ),
        ChangeNotifierProxyProvider<Auth, Orders>(
          builder: (context, auth, previousOrders) => Orders(
            auth.token,
            previousOrders == null ? [] : previousOrders.orders,
            auth.userId,
          ),
        ),
      ],
      child: Consumer<Auth>(
          builder: (BuildContext context, Auth auth, Widget child) =>
              MaterialApp(
                title: 'Flutter Demo',
                theme: ThemeData(
                  primarySwatch: Colors.purple,
                  accentColor: Colors.deepOrange,
                  fontFamily: 'Lato',
                  pageTransitionsTheme: PageTransitionsTheme(builders: {
                    TargetPlatform.android: CustomPageTransitionBuilder(),
                    TargetPlatform.iOS: CustomPageTransitionBuilder(),
                  }),
                ),
                home: auth.isAuth
                    ? ProductOverviewPage()
                    : FutureBuilder(
                        future: auth.tryAutoLogin(),
                        builder: (ctx, authResultSnapshot) =>
                            authResultSnapshot.connectionState ==
                                    ConnectionState.waiting
                                ? SplashPage()
                                : AuthPage(),
                      ),
                routes: {
                  ProductDetailPage.nameRoute: (ctx) => ProductDetailPage(),
                  CartPage.routeName: (ctx) => CartPage(),
                  OrdersPage.routeName: (ctx) => OrdersPage(),
                  UserProductsPage.routeName: (ctx) => UserProductsPage(),
                  EditProductPage.routeName: (ctx) => EditProductPage(),
                  AuthPage.routeName: (ctx) => AuthPage(),
                  ProductOverviewPage.routeName: (ctx) => ProductOverviewPage(),
                },
              )),
    );
  }
}
