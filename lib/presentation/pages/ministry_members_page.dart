import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/rehearsal_draft.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/failures/rehearsal_failure.dart';
import '../../domain/repositories/rehearsal_repository.dart';
import '../../rehearsals/rehearsal_widgets.dart';
import '../widgets/app_select_field.dart';

/// Listado de miembros por ministerio y cambio de estado.
class MinistryMembersPage extends StatefulWidget {
  const MinistryMembersPage({
    super.key,
    required this.repository,
    required this.onBack,
    this.onResetPassword,
  });

  final RehearsalRepository repository;
  final VoidCallback onBack;
  final Future<({String? temporaryPassword, AuthFailure? failure})> Function(
    int userId,
  )?
  onResetPassword;

  @override
  State<MinistryMembersPage> createState() => _MinistryMembersPageState();
}

class _MinistryMembersPageState extends State<MinistryMembersPage> {
  List<MinistryOption> _ministries = const [];
  List<MinistryMember> _members = const [];
  MembershipStatus _status = MembershipStatus.pending;
  String _nameQuery = '';
  int? _ministryId;
  bool _loadingMinistries = true;
  bool _loadingMembers = false;
  int? _updatingId;
  RehearsalFailure? _failure;

  @override
  void initState() {
    super.initState();
    _loadMinistries();
  }

  Future<void> _loadMinistries() async {
    setState(() {
      _loadingMinistries = true;
      _failure = null;
    });
    final result = await widget.repository.listMinistries();
    if (!mounted) return;
    final ministries = result.ministries ?? const <MinistryOption>[];
    setState(() {
      _loadingMinistries = false;
      _failure = result.failure;
      _ministries = ministries;
      _ministryId = ministries.isEmpty ? null : ministries.first.id;
    });
    if (_ministryId != null) await _loadMembers();
  }

  Future<void> _loadMembers() async {
    final ministryId = _ministryId;
    if (ministryId == null) return;
    final status = _status;
    setState(() {
      _loadingMembers = true;
      _failure = null;
    });
    final result = await widget.repository.listMembers(
      ministryId,
      status: status,
    );
    if (!mounted || ministryId != _ministryId || status != _status) return;
    setState(() {
      _loadingMembers = false;
      _failure = result.failure;
      _members = result.members ?? const [];
    });
  }

  void _selectMinistry(int id) {
    setState(() {
      _ministryId = id;
      _members = const [];
    });
    _loadMembers();
  }

  void _selectStatus(MembershipStatus status) {
    setState(() {
      _status = status;
      _members = const [];
    });
    _loadMembers();
  }

  List<MinistryMember> get _visibleMembers {
    final query = _nameQuery.trim().toLowerCase();
    if (query.isEmpty) return _members;
    return [
      for (final member in _members)
        if (member.fullName.toLowerCase().contains(query)) member,
    ];
  }

  Future<void> _changeStatus(MinistryMember member) async {
    final ministryId = _ministryId;
    if (ministryId == null || _updatingId != null) return;

    final next = await showDialog<MembershipStatus>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Cambiar estado',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Elige el estado de ${member.fullName}.'),
              const SizedBox(height: 8),
              for (final status in MembershipStatus.values)
                ListTile(
                  key: ValueKey('set-membership-${status.apiValue}'),
                  enabled: status != member.status,
                  selected: status == member.status,
                  title: Text(status.label),
                  onTap: status == member.status
                      ? null
                      : () => Navigator.of(dialogContext).pop(status),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
    if (next == null || next == member.status || !mounted) return;

    setState(() => _updatingId = member.ministryMemberId);
    final error = await widget.repository.updateMemberStatus(
      ministryId,
      member.ministryMemberId,
      next,
    );
    if (!mounted) return;
    setState(() => _updatingId = null);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.fullName} quedó como ${next.label.toLowerCase()}.'),
      ),
    );
    await _loadMembers();
  }

  Future<void> _resetPassword(MinistryMember member) async {
    final userId = member.userId;
    final reset = widget.onResetPassword;
    if (userId == null || reset == null || _updatingId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Restablecer contraseña',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '¿Generar una contraseña temporal para ${member.fullName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restablecer'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final result = await reset(userId);
    if (!mounted) return;
    if (result.failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failure!.message)));
      return;
    }
    final password = result.temporaryPassword ?? '';
    var copied = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: const Text(
                'Contraseña temporal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Compártela con ${member.fullName}:'),
                  const SizedBox(height: 12),
                  SelectableText(
                    password,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: password.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: password));
                            setDialogState(() => copied = true);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                    ),
                    icon: Icon(
                      copied ? Icons.check_rounded : Icons.copy_rounded,
                    ),
                    label: Text(
                      copied ? 'Contraseña copiada' : 'Copiar contraseña',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Listo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: Column(
        children: [
          _MembersHeader(onBack: widget.onBack),
          Expanded(
            child: _loadingMinistries
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.black),
                  )
                : _ministries.isEmpty
                ? _Message(
                    text: _failure?.message ??
                        'No hay ministerios para mostrar.',
                    action: 'Reintentar',
                    onAction: _loadMinistries,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSelectField<int>(
                              label: 'Ministerio',
                              placeholder: 'Elige un ministerio',
                              value: _ministryId,
                              options: [
                                for (final ministry in _ministries)
                                  AppSelectOption(
                                    value: ministry.id,
                                    label: ministry.name,
                                  ),
                              ],
                              onChanged: _selectMinistry,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Estado',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.label,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _StatusFilter(
                              selected: _status,
                              onSelected: _selectStatus,
                            ),
                            const SizedBox(height: 16),
                            RehearsalSearchField(
                              hintText: 'Buscar por nombre',
                              onChanged: (value) =>
                                  setState(() => _nameQuery = value),
                            ),
                          ],
                        ),
                      ),
                      if (_failure != null && _members.isEmpty)
                        Expanded(
                          child: _Message(
                            text: _failure!.message,
                            action: 'Reintentar',
                            onAction: _loadMembers,
                          ),
                        )
                      else if (_loadingMembers)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.black,
                            ),
                          ),
                        )
                      else if (_members.isEmpty)
                        const Expanded(
                          child: _Message(
                            text: 'No hay miembros con este estado.',
                          ),
                        )
                      else if (_visibleMembers.isEmpty)
                        const Expanded(
                          child: _Message(
                            text: 'No hay miembros que coincidan con la búsqueda.',
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              12,
                              20,
                              bottomInset + 24,
                            ),
                            itemCount: _visibleMembers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final member = _visibleMembers[index];
                              return _MemberCard(
                                member: member,
                                updating:
                                    _updatingId == member.ministryMemberId,
                                onChangeStatus: () => _changeStatus(member),
                                onResetPassword:
                                    member.userId != null &&
                                        widget.onResetPassword != null
                                    ? () => _resetPassword(member)
                                    : null,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({required this.onBack});

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
                  'Miembros',
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

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selected, required this.onSelected});

  final MembershipStatus selected;
  final ValueChanged<MembershipStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MembershipStatus.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = MembershipStatus.values[index];
          final isSelected = status == selected;
          return Material(
            key: ValueKey('membership-${status.apiValue}'),
            color: isSelected ? AppColors.black : AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(status),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.updating,
    required this.onChangeStatus,
    this.onResetPassword,
  });

  final MinistryMember member;
  final bool updating;
  final VoidCallback onChangeStatus;
  final VoidCallback? onResetPassword;

  @override
  Widget build(BuildContext context) {
    final functions = member.functions.join(' · ');
    return Material(
      color: AppColors.white,
      elevation: 4,
      shadowColor: AppColors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.inputFill,
              child: Icon(Icons.person_rounded, color: AppColors.label),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (functions.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      functions,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.label,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _MembershipChip(status: member.status),
                ],
              ),
            ),
            if (onResetPassword != null) ...[
              IconButton(
                tooltip: 'Restablecer contraseña',
                onPressed: updating ? null : onResetPassword,
                icon: const Icon(Icons.lock_reset_outlined),
              ),
            ],
            const SizedBox(width: 8),
            FilledButton(
              onPressed: updating ? null : onChangeStatus,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: const Color(0xFFD6D6D6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MembershipStatus.pending => AppColors.warning,
      MembershipStatus.active => AppColors.success,
      MembershipStatus.inactive => AppColors.label,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status.label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
