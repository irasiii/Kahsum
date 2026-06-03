import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_provider.dart';
import '../models/claim.dart';

/// All claims belonging to the authenticated consumer.
final myClaimsProvider = FutureProvider<List<Claim>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/api/claims/mine');
  final list = response.data!['claims'] as List<dynamic>;
  return list.map((e) => Claim.fromJson(e as Map<String, dynamic>)).toList();
});
