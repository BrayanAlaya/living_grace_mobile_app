import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class AppSelectField<T> extends StatefulWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.options,
    required this.onChanged,
    this.value,
    this.enabled = true,
  });

  final String label;
  final String placeholder;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final T? value;
  final bool enabled;

  @override
  State<AppSelectField<T>> createState() => _AppSelectFieldState<T>();
}

class _AppSelectFieldState<T> extends State<AppSelectField<T>> {
  bool _open = false;

  String get _display {
    for (final option in widget.options) {
      if (option.value == widget.value) return option.label;
    }
    return widget.placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final hasValue = widget.value != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.label,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: enabled
                  ? () => setState(() => _open = !_open)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 15,
                          color: hasValue ? AppColors.black : AppColors.label,
                        ),
                      ),
                    ),
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.label,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open && enabled) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    for (final option in widget.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              widget.onChanged(option.value);
                              setState(() => _open = false);
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: Center(
                                child: Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
