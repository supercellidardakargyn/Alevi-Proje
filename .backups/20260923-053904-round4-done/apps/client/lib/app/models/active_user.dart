class ActiveUser {
  const ActiveUser({required this.id, required this.displayName, this.avatarUrl});

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory ActiveUser.fromJson(Map<String, dynamic> json) => ActiveUser(
        id: json['id']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? 'Kullanıcı',
        avatarUrl: json['avatarUrl']?.toString(),
      );
}
