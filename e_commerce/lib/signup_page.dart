import 'language_provider.dart';
import 'traduction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'storage_service.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
 bool _acceptedTerms = false;
  Future<void> _signup() async {
    if (_formKey.currentState!.validate()  && _acceptedTerms) {
      final String name = _nameController.text;
      final String phone = _phoneController.text;
      final String password = _passwordController.text;

      final response = await http.post(
        Uri.parse('http://194.163.173.3:8888/sign-up'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': phone, // Utiliser le numéro de téléphone comme email
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('account_created', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage))),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('failed_to_create_account', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage))),
        );
      }
    }
    else if (!_acceptedTerms) { // Afficher un message d'erreur si les conditions ne sont pas acceptées
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('accept_terms', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String selectedLanguage = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
    final TextDirection textDirection = selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('sign_up', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              
              Text(
                translate('create_account', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: translate('full_name', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage),
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        
                      ),
                      textDirection: textDirection ,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: translate('phone_number', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage),
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          FilteringTextInputFormatter.allow(RegExp(r'^[234][0-9]{0,7}')),
                      ],
                      textDirection: textDirection ,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: translate('password', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage),
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      obscureText: true,
                      textDirection: textDirection ,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                  CheckboxListTile(
                      title: Text(translate('accept_terms_and_conditions', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage)),
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signup,
                      child: Text(translate('create_account', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(translate('already_have_account', Provider.of<LanguageProvider>(context, listen: false).selectedLanguage)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
