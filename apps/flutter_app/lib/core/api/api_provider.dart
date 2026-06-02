import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://khasm-staging-alb-1581651998.us-east-1.elb.amazonaws.com',
  ));
});
