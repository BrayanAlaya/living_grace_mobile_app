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

/// Formulario de alta y edición de un ensayo.
class CreateRehearsalPage extends StatefulWidget {
  const CreateRehearsalPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onCreated,
    this.seed,
    this.validator = const RehearsalFormValidator(),
  });

  final RehearsalFormController controller;
  final VoidCallback onBack;
  final VoidCallback onCreated;

  /// Si llega, el formulario se rellena y confirma con PATCH.
  final RehearsalFormSeed? seed;
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
  final _knownMembers = <int, MinistryMember>{};
  final _memberMinistryNames = <int, String>{};
  DateTime? _startAt;
  DateTime? _endAt;
  String? _localMessage;
  bool _filledSeed = false;
  bool _ministryApplied = false;

  RehearsalFormController get _form => widget.controller;
  bool get _editing => widget.seed != null;

  List<MinistryMember> get _retainedMembers {
    final currentIds = {
      for (final member in _form.members) member.ministryMemberId,
    };
    return [
      for (final id in _selectedMemberIds)
        if (!currentIds.contains(id)) ?_knownMembers[id],
    ];
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
    final ministryName = _ministryName(_form.ministryId);
    for (final member in _form.members) {
      _knownMembers[member.ministryMemberId] = member;
      if (ministryName != null) {
        _memberMinistryNames[member.ministryMemberId] = ministryName;
      }
    }
    _maybeApplySeed();
    setState(() {});
  }

  void _maybeApplySeed() {
    final seed = widget.seed;
    if (seed == null || _form.loadingMinistries) return;

    if (!_filledSeed) {
      _filledSeed = true;
      _nameController.text = seed.name;
      _descriptionController.text = seed.description ?? '';
      _startAt = seed.startAt;
      _endAt = seed.endAt;
      _startController.text = _formatDateTime(seed.startAt);
      _endController.text = _formatDateTime(seed.endAt);
      _toleranceController.text = '${seed.toleranceMinutes}';
      _selectedMemberIds
        ..clear()
        ..addAll(seed.memberIds);
      for (final member in seed.members) {
        _knownMembers[member.ministryMemberId] = member;
        if (seed.ministryName.isNotEmpty) {
          _memberMinistryNames[member.ministryMemberId] = seed.ministryName;
        }
      }
    }

    final hasMinistry = _form.ministries.any(
      (item) => item.id == seed.ministryId,
    );
    if (_ministryApplied ||
        !hasMinistry ||
        _form.ministryId == seed.ministryId) {
      return;
    }
    _ministryApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _form.ministryId == seed.ministryId) return;
      _form.selectMinistry(seed.ministryId);
    });
  }

  String? _ministryName(int? id) {
    if (id == null) return null;
    for (final ministry in _form.ministries) {
      if (ministry.id == id) return ministry.name;
    }
    return null;
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
    final draft = RehearsalDraft(
      ministryId: ministryId,
      name: _nameController.text.trim(),
      description: description.isEmpty ? null : description,
      startAt: _startAt!,
      endAt: _endAt!,
      toleranceMinutes: widget.validator.toleranceMinutes(
        _toleranceController.text,
      ),
      ministryMemberIds: _selectedMemberIds.toList(),
    );
    final seed = widget.seed;
    final saved = seed == null
        ? await _form.submit(draft)
        : await _form.update(seed.rehearsalId, draft);
    if (!mounted || !saved) return;
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
          _FormHeader(
            title: _editing ? 'Editar ensayo' : 'Programar Ensayo',
            onBack: widget.onBack,
          ),
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
                        const SizedBox(height: 16),
                        AppSelectField<int>(
                          label: 'Filtrar por ministerio',
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
                            setState(() => _localMessage = null);
                            _form.selectMinistry(id);
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Miembros',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.label,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MembersCard(
                          loading: _form.loadingMembers,
                          ministrySelected: _form.ministryId != null,
                          retained: _retainedMembers,
                          members: _form.members,
                          selectedIds: _selectedMemberIds,
                          ministryNameFor: (id) => _memberMinistryNames[id],
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
                          label: _editing
                              ? 'Guardar cambios'
                              : 'Programar ensayo',
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
  const _FormHeader({required this.title, required this.onBack});

  final String title;
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
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
    required this.retained,
    required this.members,
    required this.selectedIds,
    required this.ministryNameFor,
    required this.onToggle,
  });

  final bool loading;
  final bool ministrySelected;
  final List<MinistryMember> retained;
  final List<MinistryMember> members;
  final Set<int> selectedIds;
  final String? Function(int id) ministryNameFor;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final visible = [...retained, ...members];
    final retainedIds = {
      for (final member in retained) member.ministryMemberId,
    };

    if (!ministrySelected && visible.isEmpty) {
      return const _Hint('Elige un ministerio para ver sus miembros.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.isNotEmpty)
          Material(
            color: AppColors.white,
            elevation: 8,
            shadowColor: const Color(0x33000000),
            surfaceTintColor: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _MemberTile(
                    member: visible[i],
                    selected: selectedIds.contains(visible[i].ministryMemberId),
                    ministryName:
                        retainedIds.contains(visible[i].ministryMemberId)
                        ? ministryNameFor(visible[i].ministryMemberId)
                        : null,
                    onTap: () => onToggle(visible[i].ministryMemberId),
                  ),
                  if (i != visible.length - 1)
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
          ),
        if (loading)
          Padding(
            padding: EdgeInsets.only(top: visible.isEmpty ? 0 : 12),
            child: const AppLoadingIndicator(message: 'Cargando miembros...'),
          )
        else if (ministrySelected && members.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: visible.isEmpty ? 0 : 12),
            child: const _Hint('Este ministerio no tiene miembros.'),
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.selected,
    required this.onTap,
    this.ministryName,
  });

  final MinistryMember member;
  final bool selected;
  final String? ministryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (member.functions.isNotEmpty) member.functions.join(' · '),
      if (ministryName != null && ministryName!.isNotEmpty) ministryName!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
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
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
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
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.black,
              checkColor: AppColors.white,
              side: const BorderSide(color: AppColors.label, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
