/// Notificación persistente (`GET /notifications` y eventos `notification.created`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.resourceType,
    this.resourceId,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? resourceType;
  final int? resourceId;

  bool get isRehearsal => resourceType == 'rehearsal' || type.startsWith('REHEARSAL_');
  bool get isCancelledRehearsal => type == NotificationType.rehearsalCancelled;
  bool get isMembershipPending => type == NotificationType.membershipPending;
  bool get isMembershipApproved => type == NotificationType.membershipApproved;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      resourceType: resourceType,
      resourceId: resourceId,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = (json['notification_type'] ?? json['type']) as String? ?? '';
    if (type.isEmpty) {
      throw const FormatException('Notification.type');
    }
    final created = json['created_at'];
    if (created is! String || created.isEmpty) {
      throw const FormatException('Notification.created_at');
    }
    return AppNotification(
      id: _asInt(json['id']),
      type: type,
      title: (json['title'] as String?)?.trim() ?? '',
      message: (json['message'] as String?)?.trim() ?? '',
      resourceType: (json['resource_type'] as String?)?.trim(),
      resourceId: _asIntOrNull(json['resource_id']),
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(created).toLocal(),
    );
  }
}

abstract final class NotificationType {
  static const rehearsalAssigned = 'REHEARSAL_ASSIGNED';
  static const rehearsalUpdated = 'REHEARSAL_UPDATED';
  static const rehearsalCancelled = 'REHEARSAL_CANCELLED';
  static const membershipPending = 'MEMBERSHIP_PENDING';
  static const membershipApproved = 'MEMBERSHIP_APPROVED';
}

class NotificationPage {
  const NotificationPage({
    required this.total,
    required this.limit,
    required this.offset,
    this.items = const [],
  });

  final int total;
  final int limit;
  final int offset;
  final List<AppNotification> items;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List? ?? const [];
    return NotificationPage(
      total: _asInt(json['total'] ?? 0),
      limit: _asInt(json['limit'] ?? 20),
      offset: _asInt(json['offset'] ?? 0),
      items: [
        for (final item in raw)
          if (item is Map)
            AppNotification.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

int _asInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  throw FormatException('Entero inválido: $raw');
}

int? _asIntOrNull(Object? raw) {
  if (raw == null) return null;
  return _asInt(raw);
}
