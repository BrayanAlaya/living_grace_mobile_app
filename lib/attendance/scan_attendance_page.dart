import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/layouts/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_widgets.dart';
import 'attendance_qr.dart';
import 'attendance_qr_api.dart';
import 'attendance_widgets.dart';

typedef AttendanceScannerBuilder =
    Widget Function(ValueChanged<String> onCode);

/// Pantalla para que el miembro escanee el QR y marque asistencia.
class ScanAttendancePage extends StatefulWidget {
  const ScanAttendancePage({
    super.key,
    required this.rehearsal,
    required this.api,
    this.scannerBuilder,
  });

  final Rehearsal rehearsal;
  final AttendanceQrApi api;
  final AttendanceScannerBuilder? scannerBuilder;

  @override
  State<ScanAttendancePage> createState() => _ScanAttendancePageState();
}

class _ScanAttendancePageState extends State<ScanAttendancePage> {
  bool _handling = false;

  Future<void> _onCode(String payload) async {
    if (_handling) return;
    _handling = true;
    if (mounted) setState(() {});
    try {
      final checkIn = await widget.api.checkIn(
        rehearsal: widget.rehearsal,
        payload: payload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(checkIn);
    } on AttendanceCheckInException catch (error) {
      if (!mounted) return;
      setState(() => _handling = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _handling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la asistencia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scanner =
        widget.scannerBuilder ??
        (onCode) => _LiveQrScanner(locked: _handling, onCode: onCode);

    return AppLayout(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          const RehearsalHeader(title: 'Registrar'),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Text(
              'Escanea el Código QR\nde ensayo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppColors.black,
              ),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 22, 24, bottomInset + 20),
                child: Column(
                  children: [
                    const Text(
                      'Ubica el QR dentro del marco para escanear',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: Center(
                        child: QrViewfinderFrame(
                          child: scanner(_onCode),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _handling
                          ? 'Registrando asistencia...'
                          : 'Buscando código...',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RehearsalInfoChip(rehearsal: widget.rehearsal),
                    const SizedBox(height: 18),
                    _ToleranceRemaining(rehearsal: widget.rehearsal),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToleranceRemaining extends StatefulWidget {
  const _ToleranceRemaining({required this.rehearsal});

  final Rehearsal rehearsal;

  @override
  State<_ToleranceRemaining> createState() => _ToleranceRemainingState();
}

class _ToleranceRemainingState extends State<_ToleranceRemaining> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _compute();
      setState(() => _remaining = remaining);
      if (remaining == Duration.zero) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _compute() {
    final limit = widget.rehearsal.startAt.add(
      Duration(minutes: widget.rehearsal.toleranceMinutes),
    );
    final remaining = limit.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tolerancia restante: ${formatToleranceRemaining(_remaining)}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LiveQrScanner extends StatefulWidget {
  const _LiveQrScanner({required this.locked, required this.onCode});

  final bool locked;
  final ValueChanged<String> onCode;

  @override
  State<_LiveQrScanner> createState() => _LiveQrScannerState();
}

class _LiveQrScannerState extends State<_LiveQrScanner> {
  late final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _consumed = false;

  @override
  void didUpdateWidget(_LiveQrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !oldWidget.locked) {
      unawaited(_scanner.stop());
    } else if (!widget.locked && oldWidget.locked) {
      _consumed = false;
      unawaited(_restart());
    }
  }

  Future<void> _restart() async {
    try {
      await _scanner.start();
    } catch (_) {
      // Si la cámara no reanuda, el usuario puede volver a entrar.
    }
  }

  @override
  void dispose() {
    unawaited(_scanner.stop());
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (widget.locked || _consumed) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.trim().isEmpty) continue;
      _consumed = true;
      unawaited(_scanner.stop());
      widget.onCode(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black,
      child: MobileScanner(
        controller: _scanner,
        onDetect: _onDetect,
      ),
    );
  }
}
