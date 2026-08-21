import 'package:flutter/foundation.dart';

import '../../models/donation_centre.dart';
import '../../models/donation_event.dart';
import '../local/preferences_service.dart';
import '../remote/remote_data_repository.dart';
import '../remote/supabase_service.dart';
import 'local_data_repository.dart';

class DataSyncService {
  DataSyncService({
    LocalDataRepository? localRepository,
    PreferencesService? preferences,
  }) : _localRepository = localRepository ?? LocalDataRepository(),
       _preferences = preferences ?? PreferencesService.instance;

  final LocalDataRepository _localRepository;
  final PreferencesService _preferences;

  RemoteDataRepository? get _remoteRepository {
    final client = SupabaseService.client;
    return client == null ? null : RemoteDataRepository(client);
  }

  Future<List<DonationCentre>> loadCentres() async {
    await _localRepository.ensureStarterData();
    final remote = _remoteRepository;
    if (remote != null) {
      try {
        final centres = await remote.getCentres();
        await _localRepository.replaceCentres(centres);
        await _preferences.setLastSyncAt(DateTime.now());
      } on Exception catch (error) {
        debugPrint('Centre sync failed; using cache: $error');
      }
    }
    return _localRepository.getCentres();
  }

  Future<List<DonationEvent>> loadEvents() async {
    await _localRepository.ensureStarterData();
    final remote = _remoteRepository;
    if (remote != null) {
      try {
        final events = await remote.getEvents();
        await _localRepository.replaceEvents(events);
        await _preferences.setLastSyncAt(DateTime.now());
      } on Exception catch (error) {
        debugPrint('Event sync failed; using cache: $error');
      }
    }
    return _localRepository.getEvents();
  }
}
