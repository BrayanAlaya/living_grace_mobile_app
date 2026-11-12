import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/layouts/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_widgets.dart';
import 'attendance_qr.dart';
import 'attendance_widgets.dart';

/// Pantalla para mostrar el QR de asistencia de un ensayo.
class AttendanceQrDisplayPage extends StatefulWidget {
  const AttendanceQrDisplayPage({super.key, required this.qr});

  final AttendanceQr qr;

  @override
  State<AttendanceQrDisplayPage> createState() =>
      _AttendanceQrDisplayPageState();
}

class _AttendanceQrDisplayPageState extends State<AttendanceQrDisplayPage> {
  Timer? _timer;
  late Duration _remaining;

  Rehearsal get _rehearsal => widget.qr.rehearsal;

  bool get _expired => _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.qr.remainingAt(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = widget.qr.remainingAt(DateTime.now());
      setState(() => _remaining = remaining);
      if (remaining == Duration.zero) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: QrImageView(
                              data: widget.qr.payload,
                              version: QrVersions.auto,
                              backgroundColor: AppColors.white,
                              errorStateBuilder: (context, error) =>
                                  const SizedBox.shrink(),
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _expired ? 'Código expirado' : 'Código generado',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RehearsalInfoChip(rehearsal: _rehearsal),
                    const SizedBox(height: 18),
                    Text(
                      'Tolerancia restante: ${formatToleranceRemaining(_remaining)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

