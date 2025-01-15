import 'product_list.dart';
import 'package:flutter/material.dart';
import 'product_model.dart';
import 'language_provider.dart';
import 'package:provider/provider.dart';
import 'storage_service.dart';
import 'dart:convert'; // For jsonEncode
import 'package:http/http.dart' as http; // For HTTP requests
import 'traduction.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final StorageService _storageService = StorageService();
  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
  }
    Future<String?> getToken() async {
    final SharedPreferences autht = await SharedPreferences.getInstance();
    return autht.getString('ecom-token');
  }


  Future<void> _checkIfInCart() async {
    final user = await _storageService.getUser();
    if (user != null) {
      final userId = user['userId'];
      final String? token = await getToken();
      final response = await http.get(
        Uri.parse('http://194.163.173.3:8888/api/customer/cart/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> cartData = jsonDecode(response.body);
        final List<dynamic> items = cartData['cartItems'];
        setState(() {
          isInCart = items.any((item) => item['productId'] == widget.product.id);
        });
      }
    }
  }

  Future<void> _addToCart() async {
    final user = await _storageService.getUser();
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      final userId = user['userId'];
      final String? token = await getToken();
      final response = await http.post(
        Uri.parse('http://194.163.173.3:8888/api/customer/cart'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, int>{
          'productId': widget.product.id!,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          isInCart = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('add_to_cartt', Provider.of<LanguageProvider>(context,listen: false).selectedLanguage))),
        );
      } else {
        print('Failed to add to cart: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('sync_pending', Provider.of<LanguageProvider>(context,listen: false).selectedLanguage))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedLanguage = Provider.of<LanguageProvider>(context).selectedLanguage;
    TextDirection textDirection = (selectedLanguage == 'ar') ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translate('product_details', selectedLanguage)),
          leading: IconButton(
          icon: Icon(Icons.arrow_back),
onPressed: () {
  Navigator.pop(context);
  // Pour recharger la page
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => ProductList()),
  );
},

          ), 
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // Large product image
                    Image.memory(
                      widget.product.imageBytes!,
                      fit: BoxFit.cover,
                      height: 200,
                      width: 200,
                    ),
                    SizedBox(height: 10),
                    // Small product images
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.memory(
                          widget.product.imageBytes!,
                          fit: BoxFit.cover,
                          height: 50,
                          width: 50,
                        ),
                       
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Product name
              Text(
                widget.product.name ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // Product price and discount
              Row(
                children: [
                  Text(
                    '${widget.product.price?.toStringAsFixed(2) ?? ''} ${translate('Mru', selectedLanguage)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 10),
               
                    Text(
                      '-${10}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              
              SizedBox(height: 10),
              Text(
                widget.product.description ?? '',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900], 
                    foregroundColor: Colors.white, 
                    minimumSize: Size(double.infinity, 50), 
                  ),
                  onPressed: isInCart ? null : _addToCart, // Disable if already in cart
                  child: Text(
                    isInCart
                        ? translate('in_cart', selectedLanguage)
                        : translate('add_to_cart', selectedLanguage),
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}