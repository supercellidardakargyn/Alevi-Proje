import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  final _slides = const [
    (
      icon: Icons.diversity_1_outlined,
      title: 'Bağ kurmanın daha iyi yolu',
      body:
          'Can Meydanı, ortak ilgi alanları ve güvenli sohbetler üzerinden gerçek bağlantılar kurmanı sağlar.',
    ),
    (
      icon: Icons.verified_user_outlined,
      title: 'Güven seninle başlar',
      body:
          '18+ topluluğumuzda profil doğrulama, gizlilik ve kontrol her zaman senin elinde.',
    ),
    (
      icon: Icons.explore_outlined,
      title: 'Kendi ritmini keşfet',
      body:
          'Yeni insanları, toplulukları ve şehir hikâyelerini tek bir yerde keşfet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final artSize = landscape ? 104.0 : 152.0;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AleviLogo(),
                  SizedBox(height: landscape ? 18 : 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(_page),
                      children: [
                        Center(
                          child: Container(
                            width: artSize,
                            height: artSize,
                            decoration: BoxDecoration(
                              color: AppColors.burgundy,
                              borderRadius: BorderRadius.circular(artSize / 3),
                            ),
                            child: Icon(slide.icon,
                                color: AppColors.gold, size: artSize / 2,),
                          ),
                        ),
                        SizedBox(height: landscape ? 18 : 36),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppInk.text,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppInk.subtle,
                              height: 1.45,
                              fontSize: 16,),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: landscape ? 18 : 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: index == _page ? 24 : 7,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? AppColors.burgundy
                              : AppInk.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label:
                        _page == _slides.length - 1 ? 'Başlayalım' : 'Devam et',
                    onPressed: () {
                      if (_page == _slides.length - 1) {
                        widget.onComplete();
                      } else {
                        setState(() => _page++);
                      }
                    },
                    icon: Icons.arrow_forward,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: widget.onComplete,
                      child: const Text('Zaten hesabım var'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
