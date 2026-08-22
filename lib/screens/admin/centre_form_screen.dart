import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/admin_centre_repository.dart';
import '../../data/remote/official_centre_repository.dart';
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
  LatLng? selectedLocation;
  final mapController = MapController();
  bool searchingLocation = false;
  Timer? addressDebounce;

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
    if (centre != null) {
      selectedLocation = LatLng(centre.latitude, centre.longitude);
    }
  }

  void selectLocation(LatLng point) {
    setState(() {
      selectedLocation = point;
      latitudeController.text = point.latitude.toStringAsFixed(6);
      longitudeController.text = point.longitude.toStringAsFixed(6);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    stateController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    hoursController.dispose();
    mapController.dispose();
    addressDebounce?.cancel();
    super.dispose();
  }

  void addressChanged(String value) {
    addressDebounce?.cancel();
    if (value.trim().length < 5) return;
    addressDebounce = Timer(const Duration(milliseconds: 900), findAddress);
  }

  Future<void> findAddress() async {
    final query = [
      nameController.text.trim(),
      addressController.text.trim(),
      stateController.text.trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the centre address first.')),
      );
      return;
    }
    setState(() => searchingLocation = true);
    try {
      final result = await OfficialCentreRepository().searchLocation(query);
      if (!mounted) return;
      final point = LatLng(result.latitude, result.longitude);
      selectLocation(point);
      mapController.move(point, 16);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to find location: $error')),
      );
    } finally {
      if (mounted) setState(() => searchingLocation = false);
    }
  }

  String? requiredValue(String? value) {
    return value == null || value.trim().isEmpty ? 'Required field.' : null;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid address and wait for the map to update.',
          ),
        ),
      );
      return;
    }
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
              onChanged: addressChanged,
              onSubmitted: (_) => findAddress(),
            ),
            _TextField(
              controller: stateController,
              label: 'State',
              validator: requiredValue,
            ),
            Text(
              'Centre location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter the address above. The map updates automatically; tap the '
              'map only if the entrance needs a small adjustment.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (searchingLocation)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.location_searching, size: 18),
                const SizedBox(width: 8),
                Text(
                  searchingLocation ? 'Locating address…' : 'Address location',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter:
                        selectedLocation ?? const LatLng(3.139, 101.6869),
                    initialZoom: selectedLocation == null ? 11 : 15,
                    onTap: (_, point) => selectLocation(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_asg',
                    ),
                    if (selectedLocation case final point?)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on,
                              size: 46,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
