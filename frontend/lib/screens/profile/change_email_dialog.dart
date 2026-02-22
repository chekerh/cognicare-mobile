import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../l10n/app_localizations.dart';
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


      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _codeSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.verificationCodeSent),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? AppLocalizations.of(context)!.failedToSendCode);
      }
    } catch (e) {
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterVerificationCode),
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
        throw Exception(error['message'] ?? AppLocalizations.of(context)!.failedToVerifyCode);
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
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_codeSent ? loc.verifyEmailChangeTitle : loc.changeEmail),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _codeSent ? [
              Text(
                loc.enterCodeSentTo(_newEmailController.text),
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _codeController,
                label: loc.verificationCodeLabel,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : _requestEmailChange,
                child: Text(loc.resendCodeButton),
              ),
            ] : [
              CustomTextField(
                controller: _newEmailController,
                label: loc.emailLabel,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.emailRequired;
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return loc.emailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: loc.currentPasswordLabel,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.passwordRequired;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: Text(loc.cancel),
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
              : Text(_codeSent ? loc.verifyButton : loc.sendCodeButton),
        ),
      ],
    );
  }
}
