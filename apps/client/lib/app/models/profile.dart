import '../theme/app_strings.dart';

class Profile {
  const Profile({
    required this.name,
    this.age = 0,
    this.city = '',
    this.district = '',
    this.bio = '',
    this.interests = const [],
    this.verified = false,
    this.avatarUrl,
    this.photos = const [],
    this.id,
    this.referred = false,
    this.sharedInterests = const [],
    this.sharedEvents = 0,
  });

  final String name;
  final int age;
  final String city;
  final String district;
  final String bio;
  final List<String> interests;
  final bool verified;
  final String? avatarUrl;
  final List<String> photos;
  final String? id;
  final bool referred;
  final List<String> sharedInterests;
  final int sharedEvents;

  factory Profile.fromDiscover(Map<String, dynamic> json) {
    final interests = (json['interests'] as List? ?? const []).map((tag) => tag.toString()).toList();
    final shared = (json['sharedInterests'] as List? ?? const []).map((tag) => tag.toString()).toList();
    final photos = (json['photos'] as List? ?? const []).map((url) => url.toString()).where((url) => url.isNotEmpty).toList();
    return Profile(
      id: json['id']?.toString(),
      name: (json['displayName'] ?? AppStrings.unknownUser).toString(),
      bio: (json['bio'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      photos: photos,
      interests: interests,
      referred: json['referred'] == true,
      sharedInterests: shared,
      sharedEvents: (json['sharedEvents'] as num?)?.toInt() ?? 0,
    );
  }
}
