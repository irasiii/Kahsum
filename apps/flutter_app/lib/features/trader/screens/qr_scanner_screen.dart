import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _processing = false;
  String? _lastToken;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw == _lastToken) return;

    setState(() {
      _processing = true;
      _lastToken = raw;
    });
    await _scanner.stop();

    bool success = false;
    String? errorMsg;

    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/api/claims/validate',
        data: {'qrToken': raw},
      );
      success = true;
    } on Exception catch (e) {
      errorMsg = e.toString();
    }

    if (mounted) _showResultDialog(success, errorMsg);
  }

  void _showResultDialog(bool success, String? errorMsg) {
    final isAr = context.locale.languageCode == 'ar';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: success ? AppColors.genuineGreen : Colors.red,
          size: 60,
        ),
        title: Text(
          success
              ? 'notificationsRedeemConfirmed'.tr()
              : 'commonError'.tr(),
          textAlign: TextAlign.center,
        ),
        content: Text(
          success
              ? (isAr
                  ? 'تم التحقق من العرض بنجاح'
                  : 'Deal validated successfully')
              : (isAr
                  ? 'رمز QR غير صالح أو منتهي الصلاحية'
                  : 'Invalid or already-redeemed QR code'),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _processing = false;
                _lastToken = null;
              });
              _scanner.start();
            },
            child: Text('commonConfirm'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text('traderScanQr'.tr()),
        actions: [
          IconButton(
            tooltip: isAr ? 'تبديل الفلاش' : 'Toggle flash',
            icon: ValueListenableBuilder(
              valueListenable: _scanner.torchState,
              builder: (_, state, __) => Icon(
                state == TorchState.on ? Icons.flash_on : Icons.flash_off,
              ),
            ),
            onPressed: () => _scanner.toggleTorch(),
          ),
          IconButton(
            tooltip: isAr ? 'تبديل الكاميرا' : 'Flip camera',
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scanner.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera viewfinder
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),

          // Dimmed overlay with scan window
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScanOverlayPainter(),
          ),

          // Scan frame + hint
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAr
                        ? 'وجّه الكاميرا نحو رمز QR الخاص بالعميل'
                        : 'Point camera at the customer\'s QR code',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Processing overlay
          if (_processing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints a semi-transparent overlay leaving a clear square in the center.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black45;
    const cutoutSize = 230.0;
    final left = (size.width - cutoutSize) / 2;
    final top = (size.height - cutoutSize) / 2;
    final cutout =
        Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              cutout, const Radius.circular(16))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
