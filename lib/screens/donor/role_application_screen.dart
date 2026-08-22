import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/role_request_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/user_role.dart';

class RoleApplicationScreen extends StatefulWidget {
  const RoleApplicationScreen({super.key});

  @override
  State<RoleApplicationScreen> createState() => _RoleApplicationScreenState();
}

class _RoleApplicationScreenState extends State<RoleApplicationScreen> {
  final formKey = GlobalKey<FormState>();
  final organisationController = TextEditingController();
  final positionController = TextEditingController();
  final reasonController = TextEditingController();
  UserRole requestedRole = UserRole.admin;
  final imagePicker = ImagePicker();
  XFile? proofImage;
  bool isSubmitting = false;

  @override
  void dispose() {
    organisationController.dispose();
    positionController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  String? requiredValue(String? value) {
    return value == null || value.trim().isEmpty ? 'Required field.' : null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final selectedProof = proofImage;
    if (selectedProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a proof image.')),
      );
      return;
    }
    final client = SupabaseService.client;
    if (client == null) return;

    setState(() => isSubmitting = true);
    try {
      final proofBytes = await selectedProof.readAsBytes();
      if (proofBytes.lengthInBytes > 5 * 1024 * 1024) {
        throw const FormatException('Proof image must be 5 MB or smaller.');
      }
      await RoleRequestRepository(client).submit(
        requestedRole: requestedRole,
        organisationName: organisationController.text.trim(),
        staffPosition: positionController.text.trim(),
        reason: reasonController.text.trim(),
        proofBytes: proofBytes,
        proofFileName: selectedProof.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted for review.')),
      );
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on StorageException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid image.')),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> pickProofImage() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (image != null && mounted) setState(() => proofImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for staff access')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<UserRole>(
              initialValue: requestedRole,
              decoration: const InputDecoration(labelText: 'Requested role'),
              items: const [UserRole.admin, UserRole.hospital]
                  .map(
                    (role) =>
                        DropdownMenuItem(value: role, child: Text(role.label)),
                  )
                  .toList(),
              onChanged: (role) => setState(() => requestedRole = role!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: organisationController,
              validator: requiredValue,
              decoration: const InputDecoration(
                labelText: 'Organisation or hospital name',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: positionController,
              validator: requiredValue,
              decoration: const InputDecoration(labelText: 'Staff position'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              validator: requiredValue,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reason for requesting access',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : pickProofImage,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                proofImage == null
                    ? 'Upload proof image'
                    : 'Selected: ${proofImage!.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('JPG, PNG, or WebP. Maximum size 5 MB.'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : submit,
              child: isSubmitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}
