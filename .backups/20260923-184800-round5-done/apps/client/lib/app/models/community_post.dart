class CommunityPost {
  const CommunityPost({
    required this.author,
    required this.time,
    required this.title,
    required this.body,
    required this.likes,
    required this.comments,
    required this.category,
    this.communityId,
    this.createdAtIso,
  });

  final String author;
  final String time;
  final String title;
  final String body;
  final int likes;
  final int comments;
  final String category;
  final String? communityId;
  final String? createdAtIso;
}

String relativePostTime(String? iso, String fallback) {
  if (iso == null || iso.isEmpty) return fallback;
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return fallback;
  final minutes = DateTime.now().difference(date).inMinutes;
  if (minutes < 1) return 'şimdi';
  if (minutes < 60) return '$minutes dk';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours sa';
  final days = hours ~/ 24;
  if (days < 7) return '$days gün';
  return fallback;
}
