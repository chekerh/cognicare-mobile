import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/location_search_field.dart';

class ChangeAddressDialog extends StatefulWidget {
  final String? currentLocation;
  final double? currentLat;
  final double? currentLng;

  const ChangeAddressDialog({
    super.key,
    this.currentLocation,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<ChangeAddressDialog> createState() => _ChangeAddressDialogState();
}

class _ChangeAddressDialogState extends State<ChangeAddressDialog> {
  final _locationController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.currentLocation ?? '';
    _lat = widget.currentLat;
    _lng = widget.currentLng;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.locationRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().updateProfile(
        location: location,
        locationLat: _lat,
        locationLng: _lng,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.changeAddress),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LocationSearchField(
                controller: _locationController,
                onLocationSelected: (GeocodingResult result) {
                  setState(() {
                    _lat = result.latitude;
                    _lng = result.longitude;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAddress,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.save),
        ),
      ],
    );
  }
}
