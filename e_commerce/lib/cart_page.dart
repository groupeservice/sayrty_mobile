import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'cart_service.dart';
import 'storage_service.dart';
import 'dart:convert'; // Import needed for base64 decoding
import 'language_provider.dart'; // Importer le fournisseur de langue
import 'traduction.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool loading = true;
  bool test = false;
  Map<String, dynamic>? cart;
  int? userId;
  String? numero;
  String? numerotel;
  int? minimum;
  String? selectedWilaya;
  String? selectedMoughataa;
  TextEditingController phoneController = TextEditingController();

  final List<Map<String, dynamic>> wilayas = [
    {
      'name': 'Nouakchott-Nord',
      'moughataas': ['Teyarett', 'Dar Naim', 'Toujounine']
    },
    {
      'name': 'Nouakchott-Ouest',
      'moughataas': ['Tevragh-Zeina', 'Ksar', 'Sébkha']
    },
    {
      'name': 'Nouakchott-Sud',
      'moughataas': ['Arafat', 'El Mina', 'Riyad']
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchCartData();
    _fetchminorder();
    if (test == false) {
      _numeroo();
      test = true;
    }
  }

  Future<String?> getToken() async {
    final SharedPreferences autht = await SharedPreferences.getInstance();
    return autht.getString('ecom-token');
  }

  Future<void> _fetchminorder() async {
    final String? token = await getToken();
    final response = await http.get(
        Uri.parse('http://192.168.100.11:8080/minOrderValue'),
        headers: <String, String>{
          'Content-Type': 'application/json; ',
          'Authorization': 'Bearer $token',
        });
    if (response.statusCode == 200) {
      final minimum = int.parse(response.body);
      setState(() {
        this.minimum = minimum;
      });
    } else {
      throw Exception('Failed to load minimum order value');
    }
  }
      
  Future<void> _fetchCartData() async {
    final userId = await StorageService().getUserIdd();
    setState(() {
      this.userId = userId;
    });
    if (userId != null) {
      try {
        final data = await CartService().fetchCartData(userId, context);
        setState(() {
          cart = data;
          loading = false;
        });
      } catch (error) {
        setState(() {
          loading = false;
        });
        print('Error fetching cart data: $error');
      }
    } else {
      setState(() {
        loading = false;
      });
      print('User ID is null');
    }
  }

  Future<void> _numeroo() async {
    final numero = await StorageService().getnumero();
    print(
        '____________________________________________________________________________________________');
    print("this.numero");
    print(
        '____________________________________________________________________________________________');
    setState(() {
      this.numero = numero;
    });
    print(
        '____________________________________________________________________________________________');
    print(this.numero);
    print(
        '____________________________________________________________________________________________');
  }

  Future<void> _updateQuantity(int productId, String endpoint) async {
    try {
      final userId = await StorageService().getUserIdd();
      setState(() {
        this.userId = userId;
      });
      await CartService().updateQuantity(userId!, productId, endpoint);
      _fetchCartData();
    } catch (error) {
      print('Error updating quantity: $error');
    }
  }

  Future<void> _removeCartItem(int cartItemId) async {
    try {
      await CartService().removeCartItem(cartItemId);
      _fetchCartData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(translate(
                'remove_from_cart',
                Provider.of<LanguageProvider>(context, listen: false)
                    .selectedLanguage))),
      );
    } catch (error) {
      print('Error removing item: $error');
    }
  }

  Future<void> _placeOrder(Map<String, dynamic> orderData) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      orderData['latitude'] = position.latitude;
      orderData['longitude'] = position.longitude;
      await CartService().placeOrder(orderData);
      setState(() {
        cart = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(translate(
              'order_placed',
              Provider.of<LanguageProvider>(context, listen: false)
                  .selectedLanguage))));
    } catch (error) {
      print('Error placing order: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(translate(
              'order_failed',
              Provider.of<LanguageProvider>(context, listen: false)
                  .selectedLanguage))));
    }
  }

  void _showOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            String selectedLanguage =
                Provider.of<LanguageProvider>(context).selectedLanguage;
            return Directionality(
              textDirection: selectedLanguage == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: AlertDialog(
                title: Text(translate('place_order', selectedLanguage)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: phoneController..text = numero ?? '',
                        decoration: InputDecoration(
                            labelText:
                                translate('phone_number', selectedLanguage)),
                        onChanged: (value) {
                          print('Valeur modifiée : $value');
                          numerotel = value;
                        },
                      ),
                      DropdownButton<String>(
                        hint:
                            Text(translate('select_wilaya', selectedLanguage)),
                        value: selectedWilaya,
                        onChanged: (String? newValue) {
                          numero = numerotel;
                          setState(() {
                            numero = numerotel;
                            selectedWilaya = newValue;
                            selectedMoughataa = null;
                          });
                        },
                        items: wilayas.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> wilaya) {
                          return DropdownMenuItem<String>(
                            value: wilaya['name'],
                            child: Text(
                                translate(wilaya['name'], selectedLanguage)),
                          );
                        }).toList(),
                      ),
                      if (selectedWilaya != null)
                        DropdownButton<String>(
                          hint: Text(
                              translate('select_moughataa', selectedLanguage)),
                          value: selectedMoughataa,
                          onChanged: (String? newValue) {
                            numero = numerotel;
                            setState(() {
                              numero = numerotel;
                              selectedMoughataa = newValue;
                            });
                          },
                          items: wilayas
                              .firstWhere((wilaya) =>
                                  wilaya['name'] ==
                                  selectedWilaya)['moughataas']
                              .map<DropdownMenuItem<String>>(
                                  (String moughataa) {
                            return DropdownMenuItem<String>(
                              value: moughataa,
                              child:
                                  Text(translate(moughataa, selectedLanguage)),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(translate('cancel', selectedLanguage)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (selectedWilaya != null &&
                          selectedMoughataa != null &&
                          phoneController.text.isNotEmpty) {
                        _placeOrder({
                          'userId': userId!,
                          'address': numerotel,
                          'orderDescription': 'Sample Order',
                          'wilaya': selectedMoughataa,
                          'latitude': null,
                          'longitude': null
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  translate('order_placed', selectedLanguage))),
                        );
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(translate(
                                  'fill_all_fields', selectedLanguage))),
                        );
                      }
                    },
                    child: Text(translate('place_order', selectedLanguage)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDialogError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            String selectedLanguage =
                Provider.of<LanguageProvider>(context).selectedLanguage;
            return Directionality(
              textDirection: selectedLanguage == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: AlertDialog(
                title:
                    Text(translate('phrase', selectedLanguage) + "  $minimum"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(translate('cancel', selectedLanguage)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        String selectedLanguage = languageProvider.selectedLanguage;
        TextDirection textDirection =
            (selectedLanguage == 'ar') ? TextDirection.rtl : TextDirection.ltr;

        return Directionality(
          textDirection: textDirection,
          child: Scaffold(
            appBar: AppBar(title: Text(translate('cart', selectedLanguage))),
            body: loading
                ? Center(child: CircularProgressIndicator())
                : cart == null
                    ? Center(
                        child: Text(translate('cart_empty', selectedLanguage)))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: cart!['cartItems'].length,
                              itemBuilder: (context, index) {
                                final item = cart!['cartItems'][index];
                                return ListTile(
                                  leading: item['returnedImg'] != null
                                      ? Image.memory(
                                          base64Decode(item['returnedImg']))
                                      : Icon(Icons.image_not_supported),
                                  title: Text(
                                    item['marque'],
                                    style: TextStyle(
                                      fontFamily: 'YourArabicFontFamily',
                                    ),
                                    textDirection: textDirection,
                                  ),
                                  subtitle: Text(
                                      '${translate('price', selectedLanguage)}: ${item['price']} ' +
                                          translate("Mru", selectedLanguage)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove),
                                        onPressed: () {
                                          if (item['quantity'] == 1) {
                                            _removeCartItem(item['id']);
                                          } else {
                                            _updateQuantity(
                                                item['productId'], 'deduction');
                                          }
                                        },
                                      ),
                                      Text('${item['quantity']}'),
                                      IconButton(
                                        icon: Icon(Icons.add),
                                        onPressed: () => _updateQuantity(
                                            item['productId'], 'addition'),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () =>
                                            _removeCartItem(item['id']),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Column(
                                children: [
                                  Text(
                                      '${translate('total_price', selectedLanguage)}: ${cart!['totalAmount']}'),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: int.parse(cart!['totalAmount']
                                                .toString()) >=
                                            (this.minimum ?? 0)
                                        ? _showOrderDialog
                                        : _showOrderDialogError,
                                    child: Text(translate(
                                        'place_order', selectedLanguage)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }
}
