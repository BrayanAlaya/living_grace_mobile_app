import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'rehearsal.dart';

const Color todayCardColor = Color(0xFFDDF1FA);

/// Botón circular blanco con sombra (flecha, volver).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.black.withValues(alpha: 0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: AppColors.black),
        ),
      ),
    );
  }
}

/// Cabecera de las pantallas de ensayos: volver + título + perfil.
class RehearsalHeader extends StatelessWidget {
  const RehearsalHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.inputFill,
            child: Icon(Icons.person_rounded, color: AppColors.label),
          ),
        ],
      ),
    );
  }
}

/// Barra de búsqueda gris redondeada.
class RehearsalSearchField extends StatelessWidget {
  const RehearsalSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar horarios',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Píldora negra con la fecha ("11 abril").
class DatePill extends StatelessWidget {
  const DatePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Horario (inicio / fin) + línea + nombre del ensayo.
class RehearsalTimeRow extends StatelessWidget {
  const RehearsalTimeRow({super.key, required this.rehearsal});

  final Rehearsal rehearsal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Column(
            children: [
              Text(
                formatTime(rehearsal.startAt),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatTime(rehearsal.endAt),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        Container(width: 1.5, height: 36, color: AppColors.black),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            rehearsal.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta blanca con sombra y esquinas redondeadas.
class RoundedCard extends StatelessWidget {
  const RoundedCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.white,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 4,
      shadowColor: AppColors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: child,
        ),
      ),
    );
  }
}

/// Tarjeta de un ensayo dentro de la lista.
class RehearsalCard extends StatelessWidget {
  const RehearsalCard({
    super.key,
    required this.rehearsal,
    required this.onTap,
  });

  final Rehearsal rehearsal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = rehearsal.isToday;
    return RoundedCard(
      onTap: onTap,
      color: isToday ? todayCardColor : AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DatePill(text: formatDayMonth(rehearsal.startAt)),
              Text(
                isToday ? 'Hoy' : formatWeekday(rehearsal.startAt),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RehearsalTimeRow(rehearsal: rehearsal),
        ],
      ),
    );
  }
}
