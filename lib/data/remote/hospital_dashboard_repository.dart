import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/emergency_request.dart';
import 'emergency_repository.dart';

class HospitalDashboardRepository {
  const HospitalDashboardRepository(this.client);

  final SupabaseClient client;

  Future<HospitalDashboardData> getData() async {
    final requests = await EmergencyRepository(client).getHospitalRequests();
    final requestIds = requests.map((request) => request.id).toList();
    final responseCounts = <String, int>{};
    var completedResponses = 0;

    if (requestIds.isNotEmpty) {
      final rows = await client
          .from('emergency_responses')
          .select('request_id, status')
          .inFilter('request_id', requestIds);
      for (final row in rows) {
        final requestId = row['request_id']! as String;
        responseCounts.update(
          requestId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (row['status'] == 'completed') completedResponses++;
      }
    }

    return HospitalDashboardData(
      requests: requests,
      responseCounts: responseCounts,
      totalResponses: responseCounts.values.fold(
        0,
        (sum, count) => sum + count,
      ),
      completedResponses: completedResponses,
    );
  }
}

class HospitalDashboardData {
  const HospitalDashboardData({
    required this.requests,
    required this.responseCounts,
    required this.totalResponses,
    required this.completedResponses,
  });

  final List<EmergencyRequest> requests;
  final Map<String, int> responseCounts;
  final int totalResponses;
  final int completedResponses;
}
