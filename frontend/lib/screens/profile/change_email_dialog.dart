import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class ChangeEmailDialog extends StatefulWidget {
  const ChangeEmailDialog({super.key});

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _getErrorMessage(dynamic error) {
    String message = error.toString().replaceAll('Exception: ', '');
    // Remove any network error prefixes
    message = message.replaceAll('Network error during ', '');
    message = message.replaceAll('network error: ', '');
    return message;
  }

  Future<void> _requestEmailChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: AppConstants.jwtTokenKey);
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/update-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newEmail': _newEmailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Setting _codeSent to true');
        if (mounted) {
          setState(() {
            _codeSent = true;
            _isLoading = false;
          });
          print('_codeSent is now: $_codeSent');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to new email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send verification code');
      }
    } catch (e) {
      print('Error in _requestEmailChange: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyEmailChange() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: AppConstants.jwtTokenKey);
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/verify-email-change'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': _codeController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building ChangeEmailDialog, _codeSent: $_codeSent, _isLoading: $_isLoading');
    return AlertDialog(
      title: Text(_codeSent ? 'Verify Email Change' : 'Change Email'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _codeSent ? [
              Text(
                'Enter the 6-digit code sent to ${_newEmailController.text}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _codeController,
                label: 'Verification Code',
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : _requestEmailChange,
                child: const Text('Resend Code'),
              ),
            ] : [
              CustomTextField(
                controller: _newEmailController,
                label: 'New Email Address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Current Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : (_codeSent ? _verifyEmailChange : _requestEmailChange),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_codeSent ? 'Verify' : 'Send Code'),
        ),
      ],
    );
  }
}
