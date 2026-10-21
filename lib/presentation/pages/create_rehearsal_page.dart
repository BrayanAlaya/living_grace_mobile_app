import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/layouts/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/rehearsal_draft.dart';
import '../controllers/rehearsal_form_controller.dart';
import '../rehearsal/rehearsal_form_validator.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_select_field.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Formulario de POST /rehearsals, con los campos del contrato.
class CreateRehearsalPage extends StatefulWidget {
  const CreateRehearsalPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onCreated,
    this.validator = const RehearsalFormValidator(),
  });

  final RehearsalFormController controller;
  final VoidCallback onBack;
  final VoidCallback onCreated;
  final RehearsalFormValidator validator;

  @override
  State<CreateRehearsalPage> createState() => _CreateRehearsalPageState();
}

class _CreateRehearsalPageState extends State<CreateRehearsalPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _toleranceController = TextEditingController();
  final _selectedMemberIds = <int>{};
  DateTime? _startAt;
  DateTime? _endAt;
  String? _localMessage;

  RehearsalFormController get _form => widget.controller;

  String get _membersTitle {
    final ministryId = _form.ministryId;
    if (ministryId == null) return 'Miembros';
    for (final ministry in _form.ministries) {
      if (ministry.id == ministryId) return 'Miembros de ${ministry.name}';
    }
    return 'Miembros';
  }

  @override
  void initState() {
    super.initState();
    _form.addListener(_onFormChanged);
    _form.load();
  }

  @override
  void didUpdateWidget(CreateRehearsalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == _form) return;
    oldWidget.controller.removeListener(_onFormChanged);
    _form.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _form.removeListener(_onFormChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _startController.dispose();
    _endController.dispose();
    _toleranceController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!mounted) return;
    setState(() {
      if (_form.ministryId == null) _selectedMemberIds.clear();
    });
  }

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _startAt : _endAt;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null || !mounted) return;

    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _localMessage = null;
      if (start) {
        _startAt = value;
        _startController.text = _formatDateTime(value);
      } else {
        _endAt = value;
        _endController.text = _formatDateTime(value);
      }
    });
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  Future<void> _submit() async {
    final ministryId = _form.ministryId;
    final input = RehearsalFormInput(
      ministryId: ministryId,
      name: _nameController.text,
      startAt: _startAt,
      endAt: _endAt,
      toleranceText: _toleranceController.text,
      memberIds: _selectedMemberIds.toList(),
    );
    final validation = widget.validator.validate(input);
    if (validation != null || ministryId == null) {
      setState(() => _localMessage = validation?.message);
      return;
    }

    final description = _descriptionController.text.trim();
    final created = await _form.submit(
      RehearsalDraft(
        ministryId: ministryId,
        name: _nameController.text.trim(),
        description: description.isEmpty ? null : description,
        startAt: _startAt!,
        endAt: _endAt!,
        toleranceMinutes: widget.validator.toleranceMinutes(
          _toleranceController.text,
        ),
        ministryMemberIds: _selectedMemberIds.toList(),
      ),
    );
    if (!mounted || !created) return;
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final message = _localMessage ?? _form.failure?.message;

    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: Column(
        children: [
          _FormHeader(onBack: widget.onBack),
          Expanded(
            child: _form.loadingMinistries
                ? const Center(
                    child: AppLoadingIndicator(
                      message: 'Cargando ministerios...',
                    ),
                  )
                : _form.ministries.isEmpty && _form.failure != null
                ? _LoadError(
                    message: _form.failure!.message,
                    onRetry: _form.load,
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSelectField<int>(
                          label: 'Ministerio',
                          placeholder: 'Elige un ministerio',
                          value: _form.ministryId,
                          options: [
                            for (final ministry in _form.ministries)
                              AppSelectOption(
                                value: ministry.id,
                                label: ministry.name,
                              ),
                          ],
                          onChanged: (id) {
                            setState(() {
                              _localMessage = null;
                              _selectedMemberIds.clear();
                            });
                            _form.selectMinistry(id);
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _membersTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.label,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MembersCard(
                          loading: _form.loadingMembers,
                          ministrySelected: _form.ministryId != null,
                          members: _form.members,
                          selectedIds: _selectedMemberIds,
                          onToggle: (id) {
                            setState(() {
                              _localMessage = null;
                              if (_selectedMemberIds.contains(id)) {
                                _selectedMemberIds.remove(id);
                              } else {
                                _selectedMemberIds.add(id);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Nombre',
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Descripción',
                          controller: _descriptionController,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Inicio',
                          controller: _startController,
                          readOnly: true,
                          onTap: () => _pickDateTime(start: true),
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.label,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Fin',
                          controller: _endController,
                          readOnly: true,
                          onTap: () => _pickDateTime(start: false),
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.label,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Tolerancia (minutos)',
                          controller: _toleranceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Programar ensayo',
                          isLoading: _form.submitting,
                          onPressed: _form.submitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.onBack});

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
                  'Programar Ensayo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
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

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.loading,
    required this.ministrySelected,
    required this.members,
    required this.selectedIds,
    required this.onToggle,
  });

  final bool loading;
  final bool ministrySelected;
  final List<MinistryMember> members;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (!ministrySelected) {
      return const _Hint('Elige un ministerio para ver sus miembros.');
    }
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: AppLoadingIndicator(message: 'Cargando miembros...'),
      );
    }
    if (members.isEmpty) {
      return const _Hint('Este ministerio no tiene miembros.');
    }

    return Material(
      color: AppColors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            _MemberTile(
              member: members[i],
              selected: selectedIds.contains(members[i].ministryMemberId),
              onTap: () => onToggle(members[i].ministryMemberId),
            ),
            if (i != members.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.inputFill,
              ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final MinistryMember member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final functions = member.functions.join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  if (functions.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      functions,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.label,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.black : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.label,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.link),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
