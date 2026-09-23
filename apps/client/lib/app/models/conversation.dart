import '../theme/app_strings.dart';

class Conversation {
  const Conversation({
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.online,
    this.id,
    this.memberIds = const [],
  });

  final String name;
  final String preview;
  final String time;
  final int unread;
  final bool online;
  final String? id;
  final List<String> memberIds;

  factory Conversation.fromApi(Map<String, dynamic> json) {
    final members = (json['members'] as List? ?? const []).cast<Map<String, dynamic>>();
    final names = members.map((member) => (member['displayName'] ?? '').toString()).where((name) => name.isNotEmpty).toList();
    final title = (json['title'] ?? '').toString();
    final last = json['lastMessage'] as Map?;
    return Conversation(
      id: json['id']?.toString(),
      memberIds: members.map((member) => (member['id'] ?? '').toString()).where((id) => id.isNotEmpty).toList(),
      name: title.isNotEmpty ? title : (names.isEmpty ? AppStrings.chatFallback : names.join(', ')),
      preview: (last?['body'] ?? AppStrings.noMessagesYet).toString(),
      time: formatChatTime(last?['createdAt']?.toString()),
      unread: 0,
      online: false,
    );
  }
}

String formatChatTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return '';
  final now = DateTime.now();
  final sameDay = date.year == now.year && date.month == now.month && date.day == now.day;
  if (sameDay) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  final diffDays = now.difference(date).inDays;
  if (diffDays == 1) return 'Dün';
  if (diffDays < 7) return '$diffDays gün önce';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
