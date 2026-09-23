import '../theme/app_strings.dart';

class Profile {  const Profile({
    required this.name,
    this.age = 0,
    this.city = '',
    this.bio = '',
    this.interests = const [],
    this.verified = false,
    this.avatarUrl,
    this.id,
  });

  final String name;
  final int age;
  final String city;
  final String bio;
  final List<String> interests;
  final bool verified;
  final String? avatarUrl;
  final String? id;

  factory Profile.fromDiscover(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString(),
      name: (json['displayName'] ?? AppStrings.unknownUser).toString(),
      bio: (json['bio'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}
