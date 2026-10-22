import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../domain/entities/rehearsal_draft.dart';
import '../presentation/controllers/rehearsal_form_controller.dart';
import '../presentation/pages/create_rehearsal_page.dart';
import 'rehearsal.dart';
import 'rehearsal_api.dart';
import 'rehearsal_widgets.dart';

/// Detalle de un ensayo (`GET /rehearsals/{id}`).
class RehearsalDetailPage extends StatefulWidget {
  const RehearsalDetailPage({
    super.key,
    required this.api,
    required this.rehearsalId,
    this.formController,
    this.canManage = false,
    this.onChanged,
  });

  final RehearsalApi api;
  final int rehearsalId;
  final RehearsalFormController? formController;
  final bool canManage;

  /// Avisa a la lista cuando el ensayo se editó o se eliminó.
  final VoidCallback? onChanged;

  @override
  State<RehearsalDetailPage> createState() => _RehearsalDetailPageState();
}

class _RehearsalDetailPageState extends State<RehearsalDetailPage> {
  Rehearsal? _rehearsal;
  bool _loading = true;
  bool _failed = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final rehearsal = await widget.api.fetchDetail(widget.rehearsalId);
      if (!mounted) return;
      setState(() {
        _rehearsal = rehearsal;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      final hadData = _rehearsal != null;
      setState(() {
        _loading = false;
        _failed = !hadData;
      });
      if (hadData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el ensayo.')),
        );
      }
    }
  }

  Future<void> _edit(Rehearsal rehearsal) async {
    final controller = widget.formController;
    if (controller == null || _deleting) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => CreateRehearsalPage(
          controller: controller,
          seed: _seed(rehearsal),
          onBack: () => Navigator.of(routeContext).pop(),
          onCreated: () => Navigator.of(routeContext).pop(true),
        ),
      ),
    );
    if (!mounted || updated != true) return;

    widget.onChanged?.call();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ensayo actualizado.')));
    await _load(refresh: true);
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Eliminar ensayo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text('¿Seguro que quieres eliminar este ensayo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.api.delete(widget.rehearsalId);
      if (!mounted) return;
      widget.onChanged?.call();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el ensayo.')),
      );
    }
  }

  RehearsalFormSeed _seed(Rehearsal rehearsal) {
    return RehearsalFormSeed(
      rehearsalId: rehearsal.id,
      ministryId: rehearsal.ministryId,
      ministryName: rehearsal.ministryName,
      name: rehearsal.name,
      description: rehearsal.description,
      startAt: rehearsal.startAt,
      endAt: rehearsal.endAt,
      toleranceMinutes: rehearsal.toleranceMinutes,
      members: [
        for (final participant in rehearsal.participants)
          MinistryMember(
            ministryMemberId: participant.ministryMemberId,
            firstName: participant.firstName,
            lastName: participant.lastName,
            functions: participant.functions,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rehearsal = _rehearsal;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RehearsalHeader(title: 'Ensayos'),
            Expanded(
              child: _loading && rehearsal == null
                  ? const Center(child: CircularProgressIndicator())
                  : _failed || rehearsal == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No se pudo cargar el ensayo.'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _DetailContent(
                      rehearsal: rehearsal,
                      canManage: widget.canManage,
                      deleting: _deleting,
                      onEdit: widget.formController == null
                          ? null
                          : () => _edit(rehearsal),
                      onDelete: _confirmDelete,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.rehearsal,
    required this.canManage,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final Rehearsal rehearsal;
  final bool canManage;
  final bool deleting;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final day = rehearsal.isToday ? 'Hoy' : formatWeekday(rehearsal.startAt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DatePill(text: '${formatDayMonth(rehearsal.startAt)}, $day'),
        ),
        const SizedBox(height: 16),
        RoundedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rehearsal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${formatTime(rehearsal.startAt)} - ${formatTime(rehearsal.endAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _InfoLine(label: 'Ministerio', value: rehearsal.ministryName),
              _InfoLine(label: 'Lidera', value: rehearsal.leaderName),
              _InfoLine(
                label: 'Propósito',
                value: rehearsal.description ?? 'Sin descripción',
              ),
              _InfoLine(
                label: 'Tolerancia',
                value: '${rehearsal.toleranceMinutes} min',
              ),
              if (rehearsal.participantCount != null)
                _InfoLine(
                  label: 'Participantes',
                  value: '${rehearsal.participantCount}',
                ),
              if (canManage) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: deleting ? null : onDelete,
                        icon: deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          disabledForegroundColor: AppColors.label,
                          side: BorderSide(
                            color: deleting ? AppColors.label : AppColors.error,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: deleting ? null : onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: const Color(0xFFD6D6D6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (rehearsal.showsMembers) ...[
          const SizedBox(height: 24),
          const Text(
            'Miembros',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (rehearsal.participants.isEmpty)
            const Text(
              'Este ensayo no tiene miembros.',
              style: TextStyle(fontSize: 13, color: AppColors.label),
            )
          else
            RoundedCard(
              child: Column(
                children: [
                  for (var i = 0; i < rehearsal.participants.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: AppColors.inputFill,
                      ),
                    _MemberRow(participant: rehearsal.participants[i]),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.participant});

  final RehearsalParticipant participant;

  @override
  Widget build(BuildContext context) {
    final functions = participant.functions.join(' · ');
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.inputFill,
          child: Icon(Icons.person_rounded, size: 18, color: AppColors.label),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participant.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (functions.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  functions,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.label),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Línea "Etiqueta: valor".
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.black),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
