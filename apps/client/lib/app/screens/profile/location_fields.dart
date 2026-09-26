import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/location_data.dart';
import '../../theme/app_theme.dart';
import '../ai/ai_sheet.dart';
import 'location_picker_screen.dart';

/// Profilde ulke/sehir/ilce secimi: tek kart, secim icin ayri ekran acar.
class LocationField extends StatelessWidget {
  const LocationField({super.key, required this.choice, required this.onChanged});

  final LocationChoice choice;
  final ValueChanged<LocationChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final empty = choice.isEmpty;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.of(context).push<LocationChoice>(
            MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: choice)),
          );
          if (result != null) onChanged(result);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(empty ? Icons.public : Icons.place, size: 20, color: AppInk.subtle),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Konum', style: TextStyle(fontSize: 12, color: AppInk.subtle)),
                    const SizedBox(height: 2),
                    Text(
                      empty ? 'Ülke ve şehir seç' : choice.summary,
                      style: TextStyle(
                        fontWeight: empty ? FontWeight.w500 : FontWeight.w700,
                        color: empty ? AppInk.subtle : AppInk.text,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bio alani + yapay zeka buz kirici/duzeltme yardimcisi.
class BioField extends StatelessWidget {
  const BioField({
    super.key,
    required this.controller,
    required this.apiClient,
    this.minLength = 20,
  });

  final TextEditingController controller;
  final ApiClientPort apiClient;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Hakkında', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () => showBioCoachSheet(context, apiClient: apiClient, controller: controller),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Yardım et'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Kendini kısaca tanıt... (en az $minLength karakter)',
            helperText: 'Hakkında alanını doldurman keşfette görünürlüğünü artırır.',
          ),
        ),
      ],
    );
  }
}
