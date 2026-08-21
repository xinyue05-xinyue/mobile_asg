import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/admin_centre_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_centre.dart';

class CentreFormScreen extends StatefulWidget {
  const CentreFormScreen({super.key, this.centre});

  final DonationCentre? centre;

  @override
  State<CentreFormScreen> createState() => _CentreFormScreenState();
}

class _CentreFormScreenState extends State<CentreFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController addressController;
  late final TextEditingController stateController;
  late final TextEditingController latitudeController;
  late final TextEditingController longitudeController;
  late final TextEditingController hoursController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final centre = widget.centre;
    nameController = TextEditingController(text: centre?.name);
    addressController = TextEditingController(text: centre?.address);
    stateController = TextEditingController(text: centre?.state);
    latitudeController = TextEditingController(
      text: centre?.latitude.toString(),
    );
    longitudeController = TextEditingController(
      text: centre?.longitude.toString(),
    );
    hoursController = TextEditingController(text: centre?.operatingHours);
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    stateController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  String? requiredValue(String? value) {
    return value == null || value.trim().isEmpty ? 'Required field.' : null;
  }

  String? coordinate(String? value, double min, double max) {
    final number = double.tryParse(value ?? '');
    if (number == null || number < min || number > max) {
      return 'Enter a value from $min to $max.';
    }
    return null;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => isSaving = true);
    try {
      final repository = AdminCentreRepository(client);
      final centre = widget.centre;
      final values = (
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        state: stateController.text.trim(),
        latitude: double.parse(latitudeController.text),
        longitude: double.parse(longitudeController.text),
        hours: hoursController.text.trim(),
      );
      if (centre == null) {
        await repository.create(
          name: values.name,
          address: values.address,
          state: values.state,
          latitude: values.latitude,
          longitude: values.longitude,
          operatingHours: values.hours,
        );
      } else {
        await repository.update(
          id: centre.id,
          name: values.name,
          address: values.address,
          state: values.state,
          latitude: values.latitude,
          longitude: values.longitude,
          operatingHours: values.hours,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decimalFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^-?\d*\.?\d*'),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.centre == null ? 'Add centre' : 'Edit centre'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _TextField(
              controller: nameController,
              label: 'Centre name',
              validator: requiredValue,
            ),
            _TextField(
              controller: addressController,
              label: 'Address',
              validator: requiredValue,
            ),
            _TextField(
              controller: stateController,
              label: 'State',
              validator: requiredValue,
            ),
            _TextField(
              controller: latitudeController,
              label: 'Latitude',
              validator: (value) => coordinate(value, -90, 90),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              inputFormatters: [decimalFormatter],
            ),
            _TextField(
              controller: longitudeController,
              label: 'Longitude',
              validator: (value) => coordinate(value, -180, 180),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              inputFormatters: [decimalFormatter],
            ),
            _TextField(controller: hoursController, label: 'Operating hours'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isSaving ? null : save,
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save centre'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
