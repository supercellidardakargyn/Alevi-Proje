import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';

class AleviLogo extends StatelessWidget {
  const AleviLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: AppColors.burgundy,
            borderRadius: BorderRadius.circular(compact ? 11 : 14),
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 22),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text(
            'Can Meydanı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.burgundyDark,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, this.name = '', this.size = 52, this.online = false, this.avatarUrl});

  final String name;
  final double size;
  final bool online;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final url = Session.resolveAvatar(avatarUrl);
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.creamDark,
          backgroundImage: url == null ? null : NetworkImage(url, headers: Session.authHeaders),
          child: url == null
              ? Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: size * .36,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: size * .25,
              height: size * .25,
              decoration: BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.burgundyDark, AppColors.burgundy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.person_outline, color: AppColors.gold, size: 110),
                ),
                if (Session.resolveAvatar(profile.avatarUrl) != null)
                  Positioned.fill(
                    child: Image.network(
                      Session.resolveAvatar(profile.avatarUrl)!,
                      headers: Session.authHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Positioned(
                  left: 18,
                  bottom: 16,
                  child: Row(
                    children: [
                      Text(
                        profile.age > 0 ? '${profile.name}, ${profile.age}' : profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: AppColors.gold, size: 22),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.city.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 17, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(profile.city, style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                if (profile.city.isNotEmpty) const SizedBox(height: 10),
                if (profile.bio.isNotEmpty) Text(profile.bio, style: const TextStyle(fontSize: 15, height: 1.35)),
                if (profile.bio.isNotEmpty) const SizedBox(height: 14),
                if (profile.interests.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests
                        .map((interest) => Chip(label: Text(interest)))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.gold, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
