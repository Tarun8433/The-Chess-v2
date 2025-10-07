import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countryNameController = TextEditingController();
  String _dialCode = '';
  String _phoneNumber = '';
  bool _checkingUser = false;
  bool _userAvailable = false;
  bool _submitting = false;

  Future<void> _checkUserAvailability() async {
    setState(() => _checkingUser = true);
    final available = await AuthService.isUserNameAvailable(_userController.text.trim());
    setState(() {
      _checkingUser = false;
      _userAvailable = available;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final resp = await AuthService.registerUser(
        userName: _userController.text.trim(),
        password: _passwordController.text.trim(),
        mobileNo: _phoneNumber,
        emailAddress: _emailController.text.trim(),
        countryCode: _dialCode.replaceAll('+', ''),
        countryName: _countryNameController.text.trim(),
        userNameUniq: _userController.text.trim(),
      );
      log('Registration response: $resp');
      if (!mounted) return;
      final ok = (resp['Status'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Registration success' : 'Registration failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(color: MyColors.white);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Welcome', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: MyColors.white)),
              const SizedBox(height: 12),
              Text('Please fill the form to register', style: textStyle),
              const SizedBox(height: 24),
              TextFormField(
                controller: _userController,
                style: textStyle,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter username';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _checkingUser ? null : _checkUserAvailability,
                      icon: const Icon(Icons.search),
                      label: Text(_checkingUser
                          ? 'Checking...'
                          : _userAvailable
                              ? 'Available'
                              : 'Check Availability'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _userAvailable ? Colors.green : MyColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: textStyle,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!RegExp(r'^.+@.+\..+$').hasMatch(v.trim())) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              IntlMobileField(
                initialCountryCode: 'IN',
                languageCode: 'en',
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                disableLengthCounter: true,
                onCountryChanged: (country) {
                  _countryNameController.text = country.name ?? '';
                  _dialCode = country.dialCode ?? '';
                },
                onChanged: (mobile) {
                  _phoneNumber = mobile.number;
                  _dialCode = mobile.countryCode ?? _dialCode;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                style: textStyle,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter password';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Submitting...' : 'Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}