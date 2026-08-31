import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../data/remote/admin_centre_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_centre.dart';
import 'centre_form_screen.dart';

class ManageCentresScreen extends StatefulWidget {
  const ManageCentresScreen({super.key});

  @override
  State<ManageCentresScreen> createState() => _ManageCentresScreenState();
}

class _ManageCentresScreenState extends State<ManageCentresScreen> {
  late Future<List<DonationCentre>> centres;

  @override
  void initState() {
    super.initState();
    centres = loadCentres();
  }

  Future<List<DonationCentre>> loadCentres() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return AdminCentreRepository(client).getCentres();
  }

  Future<void> openForm([DonationCentre? centre]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CentreFormScreen(centre: centre)),
    );
    if (changed == true) {
      setState(() {
        centres = loadCentres();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.organisationBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.organisationHeader,
        foregroundColor: Colors.white,
        titleTextStyle: AppTheme.organisationHeaderTitleStyle,
        title: const Text('Manage Event Venues'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openForm,
        backgroundColor: AppTheme.organisation,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add event venue'),
      ),
      body: FutureBuilder<List<DonationCentre>>(
        future: centres,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load centres: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No event venues added yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final centre = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.local_hospital_outlined),
                  title: Text(centre.name),
                  subtitle: Text('${centre.address}\n${centre.state}'),
                  trailing: IconButton(
                    onPressed: () => openForm(centre),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
