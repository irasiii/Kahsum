import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_provider.dart';
import '../models/deal.dart';

/// All active deals (home feed).
final allDealsProvider = FutureProvider<List<Deal>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/api/deals');
  final list = response.data!['deals'] as List<dynamic>;
  return list.map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
});

/// Deals within [radius] km of the given coordinates.
final nearbyDealsProvider = FutureProvider.family<List<Deal>,
    ({double lat, double lng, double radius})>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/api/deals/nearby',
    queryParameters: {
      'lat': params.lat.toString(),
      'lng': params.lng.toString(),
      'radius': params.radius.toString(),
    },
  );
  final list = response.data!['deals'] as List<dynamic>;
  return list.map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
});

/// Trader's own deals (all statuses).
final myTraderDealsProvider = FutureProvider<List<Deal>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response =
      await api.get<Map<String, dynamic>>('/api/deals/mine');
  final list = response.data!['deals'] as List<dynamic>;
  return list.map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
});

/// All categories (for deal creation form).
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/api/categories');
  final list = response.data!['categories'] as List<dynamic>;
  return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
});
