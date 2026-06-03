import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/deal.dart';
import '../../../providers/deals_provider.dart';

// ---------------------------------------------------------------------------
// Location provider
// ---------------------------------------------------------------------------

final _locationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NearbyMapScreen extends ConsumerWidget {
  const NearbyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(_locationProvider);
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text('dealsNearby'.tr())),
      body: locationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _NoLocation(isAr: isAr),
        data: (position) {
          if (position == null) return _NoLocation(isAr: isAr);
          return _MapView(position: position);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No-location placeholder
// ---------------------------------------------------------------------------

class _NoLocation extends StatelessWidget {
  final bool isAr;
  const _NoLocation({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              isAr
                  ? 'يرجى تفعيل خدمة الموقع لرؤية العروض القريبة'
                  : 'Enable location services to see nearby deals',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Geolocator.openLocationSettings(),
              icon: const Icon(Icons.settings),
              label: Text(isAr ? 'إعدادات الموقع' : 'Location Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map view
// ---------------------------------------------------------------------------

class _MapView extends ConsumerStatefulWidget {
  final Position position;
  const _MapView({required this.position});

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  Deal? _selectedDeal;

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final dealsAsync = ref.watch(nearbyDealsProvider((
      lat: widget.position.latitude,
      lng: widget.position.longitude,
      radius: 25,
    )));

    return dealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text('errorsNetwork'.tr())),
      data: (deals) => _buildMap(context, deals, isAr),
    );
  }

  Widget _buildMap(BuildContext context, List<Deal> deals, bool isAr) {
    final center =
        LatLng(widget.position.latitude, widget.position.longitude);

    final dealMarkers = deals
        .where((d) => d.trader.lat != null && d.trader.lng != null)
        .map(
          (deal) => Marker(
            point: LatLng(deal.trader.lat!, deal.trader.lng!),
            width: 72,
            height: 68,
            child: GestureDetector(
              onTap: () => setState(() => _selectedDeal = deal),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _selectedDeal?.id == deal.id
                          ? AppColors.primary
                          : AppColors.discountBadge,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      '-${deal.discountPct.round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    color: _selectedDeal?.id == deal.id
                        ? AppColors.primary
                        : AppColors.discountBadge,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.5,
            onTap: (_, __) => setState(() => _selectedDeal = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.khasm.app',
            ),
            // User location marker
            MarkerLayer(markers: [
              Marker(
                point: center,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.15),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.person_pin_circle,
                      color: AppColors.primary, size: 26),
                ),
              ),
            ]),
            MarkerLayer(markers: dealMarkers),
          ],
        ),

        // Deal count chip
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                isAr
                    ? '${deals.length} عرض قريب منك'
                    : '${deals.length} deals nearby',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary),
              ),
            ),
          ),
        ),

        // Selected deal bottom sheet
        if (_selectedDeal != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DealPreviewCard(
              deal: _selectedDeal!,
              isAr: isAr,
              onTap: () => context.push('/deal/${_selectedDeal!.id}'),
              onClose: () => setState(() => _selectedDeal = null),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Deal preview card (bottom of map)
// ---------------------------------------------------------------------------

class _DealPreviewCard extends StatelessWidget {
  final Deal deal;
  final bool isAr;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _DealPreviewCard({
    required this.deal,
    required this.isAr,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final title = isAr ? deal.titleAr : deal.titleEn;
    final discountedPrice = deal.originalPrice * (1 - deal.discountPct / 100);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 8,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(deal.trader.businessName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                        Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'SAR ${discountedPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.discountBadge,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${deal.discountPct.round()}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: AppColors.primary),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
