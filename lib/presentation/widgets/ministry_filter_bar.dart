import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/rehearsal_draft.dart';

class MinistryFilterBar extends StatelessWidget {
  const MinistryFilterBar({
    super.key,
    required this.ministries,
    required this.selectedId,
    required this.onSelected,
    this.includeAll = false,
  });

  final List<MinistryOption> ministries;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    final chips = <({int? id, String label})>[
      if (includeAll) (id: null, label: 'Todos'),
      for (final ministry in ministries) (id: ministry.id, label: ministry.name),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
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
      ),
    );
  }
}

class ListPaginationBar extends StatelessWidget {
  const ListPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.fromIndex,
    required this.toIndex,
    required this.noun,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int totalPages;
  final int total;
  final int fromIndex;
  final int toIndex;
  final String noun;
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
                    total == 0 ? '0 $noun' : '$fromIndex–$toIndex de $total',
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

({int totalPages, int fromIndex, int toIndex}) pageBounds({
  required int total,
  required int page,
  required int pageSize,
}) {
  final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
  final safePage = page.clamp(1, totalPages);
  final fromIndex = total == 0 ? 0 : ((safePage - 1) * pageSize) + 1;
  final end = safePage * pageSize;
  final toIndex = end > total ? total : end;
  return (totalPages: totalPages, fromIndex: fromIndex, toIndex: toIndex);
}
