import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

import 'product.dart';

class Products with ChangeNotifier {
  final String authToken;
  final String userId;

  Products(this.authToken, this._items, this.userId);

  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((productItem) => productItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((product) => product.id == id);
  }

  Future<void> getProducts([bool filterByUser = false]) async {
      final filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://flutter-udemy-course-72f49.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        return;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data == null) {
        return;
      }
      url = 'https://flutter-udemy-course-72f49.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      data.forEach((productId, productData) {
        loadedProducts.insert(
            0,
            Product(
              description: productData['description'],
              id: productId,
              imageUrl: productData['imageUrl'],
              title: productData['title'],
              price: productData['price'],
              isFavorite: favoriteData == null ? false : favoriteData[productId] ?? false,
            ));
        _items = loadedProducts;
        notifyListeners();
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://flutter-udemy-course-72f49.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'price': product.price,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'creatorId': userId
        }),
      );
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
      );
      _items.insert(0, newProduct); // add at the start of the list
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final productIndex = _items.indexWhere((product) => product.id == id);
    if (productIndex >= 0) {
      final url =
          'https://flutter-udemy-course-72f49.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl,
          }));
      _items[productIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-udemy-course-72f49.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex =
        _items.indexWhere((product) => product.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete this product.');
    }
    existingProduct = null;
  }
}
