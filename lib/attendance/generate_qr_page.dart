import 'package:flutter/material.dart';

import '../core/layouts/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../domain/entities/rehearsal_draft.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_widgets.dart';
import 'attendance_qr.dart';
import 'attendance_qr_api.dart';
import 'attendance_qr_display_page.dart';

/// Lista de ensayos del administrador para generar el QR de asistencia.
class GenerateQrPage extends StatefulWidget {
  const GenerateQrPage({
    super.key,
    required this.onBack,
    required this.qrApi,
    this.pageSize = 5,
  });

  final VoidCallback onBack;
  final AttendanceQrApi qrApi;
  final int pageSize;

  @override
  State<GenerateQrPage> createState() => _GenerateQrPageState();
}

class _GenerateQrPageState extends State<GenerateQrPage> {
  late Future<PagedRehearsals> _future;
  int? _ministryId;
  int _page = 1;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PagedRehearsals> _load() {
    return widget.qrApi.listRehearsals(
      ministryId: _ministryId,
      page: _page,
      pageSize: widget.pageSize,
    );
  }

  void _reload() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  void _selectMinistry(int? id) {
    _ministryId = id;
    _page = 1;
    _reload();
  }

  void _goToPage(int page) {
    _page = page;
    _reload();
  }

  Future<void> _onRehearsalTap(Rehearsal rehearsal) async {
    if (_generating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Generar código QR',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '¿Generar el código de asistencia para "${rehearsal.name}" '
            'de ${rehearsal.ministryName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Generar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _generating = true;
    });

    AttendanceQr qr;
    try {
      qr = await widget.qrApi.generate(rehearsal);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _generating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el código QR.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _generating = false;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceQrDisplayPage(qr: qr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: Stack(
        children: [
          Column(
            children: [
              _GenerateQrHeader(onBack: widget.onBack),
              Expanded(
                child: FutureBuilder<PagedRehearsals>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.black,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _Message(
                        text: 'No se pudieron cargar los ensayos.',
                        action: 'Reintentar',
                        onAction: _reload,
                      );
                    }

                    final data = snapshot.data!;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: _MinistryFilter(
                            ministries: data.ministries,
                            selectedId: _ministryId,
                            onSelected: _selectMinistry,
                          ),
                        ),
                        Expanded(
                          child: data.items.isEmpty
                              ? const _Message(
                                  text: 'No hay ensayos para este filtro.',
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    bottomInset + 12,
                                  ),
                                  itemCount: data.items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final rehearsal = data.items[index];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            rehearsal.ministryName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.label,
                                            ),
                                          ),
                                        ),
                                        RehearsalCard(
                                          rehearsal: rehearsal,
                                          onTap: () =>
                                              _onRehearsalTap(rehearsal),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        _PaginationBar(
                          page: data.page,
                          totalPages: data.totalPages,
                          total: data.total,
                          fromIndex: data.fromIndex,
                          toIndex: data.toIndex,
                          onPrevious: data.hasPrevious
                              ? () => _goToPage(data.page - 1)
                              : null,
                          onNext: data.hasNext
                              ? () => _goToPage(data.page + 1)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (_generating)
            const ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _GenerateQrHeader extends StatelessWidget {
  const _GenerateQrHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              Tooltip(
                message: 'Administración',
                child: Material(
                  color: AppColors.inputFill,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Generar Código QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 46),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinistryFilter extends StatelessWidget {
  const _MinistryFilter({
    required this.ministries,
    required this.selectedId,
    required this.onSelected,
  });

  final List<MinistryOption> ministries;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <({int? id, String label})>[
      (id: null, label: 'Todos'),
      for (final ministry in ministries) (id: ministry.id, label: ministry.name),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por ministerio',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.label,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chip = chips[index];
              final selected = chip.id == selectedId;
              return Material(
                key: ValueKey('ministry-${chip.id ?? 'all'}'),
                color: selected ? AppColors.black : AppColors.inputFill,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(chip.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        chip.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.fromIndex,
    required this.toIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int total;
  final int fromIndex;
  final int toIndex;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            _PageButton(
              tooltip: 'Anterior',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Página $page de $totalPages',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 0
                        ? '0 ensayos'
                        : '$fromIndex–$toIndex de $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.label,
                    ),
                  ),
                ],
              ),
            ),
            _PageButton(
              tooltip: 'Siguiente',
              icon: Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? AppColors.black : AppColors.inputFill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: enabled ? AppColors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.label),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}
